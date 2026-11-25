#Requires -Version 5.1
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$CaptureDirectory,
    [Parameter(Mandatory)][string]$OutputPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot 'Lab.Evidence.psm1')
$catalog = Get-LabControlCatalog
$roles = @('DC', 'Workstation')
$phases = @('Before', 'After')
$captures = @{}

function ConvertTo-FactMap {
    param($Value)
    if ($null -eq $Value -or $Value -isnot [pscustomobject]) { throw 'Invalid capture object.' }
    $map = @{}
    foreach ($property in $Value.PSObject.Properties) {
        $map.Add($property.Name, $property.Value)
    }
    $map
}

function Assert-CaptureShape {
    param([hashtable]$Data, [string[]]$Names)
    if ($Data.Count -ne $Names.Count) { throw 'Unexpected capture fields.' }
    foreach ($name in $Names) {
        if (-not $Data.ContainsKey($name)) { throw "Required capture field $name is absent." }
    }
}

$first = $null
foreach ($phase in $phases) {
    foreach ($role in $roles) {
        $key = "$phase-$role"
        $path = Join-Path $CaptureDirectory "$key.json"
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $fullPath = (Resolve-Path -LiteralPath $path).ProviderPath
        $bytes = [IO.File]::ReadAllBytes($fullPath)
        $data = ConvertTo-FactMap ([Text.Encoding]::UTF8.GetString($bytes) | ConvertFrom-Json)
        Assert-CaptureShape $data @('Schema', 'Phase', 'Role', 'RunId', 'Revision', 'CapturedUtc', 'MachineId', 'Measurements', 'Inventory')
        $guidFormat = '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        if ($data.Schema -ne $catalog.SchemaVersion -or $data.Phase -ne $phase -or $data.Role -ne $role -or
            $data.RunId -isnot [string] -or $data.MachineId -isnot [string] -or $data.Revision -isnot [string] -or
            $data.RunId -notmatch $guidFormat -or $data.MachineId -notmatch $guidFormat -or
            $data.Revision -notmatch '^[0-9a-f]{7,40}$') {
            throw "Invalid provenance for $key."
        }
        # PowerShell 7.5 can parse an ISO JSON string as DateTime automatically.
        $timestamp = if ($data.CapturedUtc -is [datetime]) {
            $data.CapturedUtc
        } elseif ($data.CapturedUtc -is [string] -and $data.CapturedUtc -match 'Z$') {
            [datetime]::ParseExact($data.CapturedUtc, 'o', [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
        } else {
            throw "Invalid UTC capture time for $key."
        }
        if ($timestamp.Kind -ne [DateTimeKind]::Utc) { throw "Expected UTC capture time for $key." }
        $scope = @($catalog.Controls | Where-Object { $_.Rules.ContainsKey($role) })
        $measurements = ConvertTo-FactMap $data.Measurements
        Assert-CaptureShape $measurements @($scope.Id)
        foreach ($control in $scope) {
            $value = $measurements[$control.Id]
            if ($null -eq $value) { continue }
            $facts = ConvertTo-FactMap $value
            Assert-LabFactMap $facts @($control.Rules[$role].Keys)
            $measurements[$control.Id] = $facts
        }
        $inventory = ConvertTo-FactMap $data.Inventory
        Assert-LabFactMap $inventory $catalog.Inventory[$role]
        $data.Measurements = $measurements
        $data.Inventory = $inventory
        $data.CapturedUtc = $timestamp
        $sha256 = [Security.Cryptography.SHA256]::Create()
        try {
            $data.Digest = [BitConverter]::ToString($sha256.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant()
        } finally {
            $sha256.Dispose()
        }
        if ($first -and ($data.RunId -ne $first.RunId -or $data.Revision -ne $first.Revision)) {
            throw 'Only combine captures from the same run and script revision.'
        }
        $captures[$key] = $data
        if (-not $first) { $first = $data }
    }
}
if (-not $first) { throw 'There are no real assessment captures in this directory.' }

foreach ($role in $roles) {
    $before = $captures["Before-$role"]
    $after = $captures["After-$role"]
    if ($before -and $after -and ($before.MachineId -ne $after.MachineId -or $before.CapturedUtc -ge $after.CapturedUtc)) {
        throw "The $role pair differs by installation or has an invalid capture order."
    }
}
foreach ($phase in $phases) {
    $dc = $captures["$phase-DC"]
    $workstation = $captures["$phase-Workstation"]
    if ($dc -and $workstation -and $dc.MachineId -eq $workstation.MachineId) {
        throw 'The DC and workstation captures must come from distinct installations.'
    }
}

function Get-PhaseStatus {
    param([hashtable]$Control, [string]$Phase)
    $results = foreach ($role in $roles) {
        if (-not $Control.Rules.ContainsKey($role)) { continue }
        $capture = $captures["$Phase-$role"]
        if (-not $capture -or $null -eq $capture.Measurements[$Control.Id]) {
            'Unmeasured'
        } else {
            Get-LabFactStatus $capture.Measurements[$Control.Id] $Control.Rules[$role]
        }
    }
    if ('Unmeasured' -in $results) { return 'Unmeasured' }
    if ('Fail' -in $results) { return 'Fail' }
    'Pass'
}

function Format-CaptureMeasurement {
    param([hashtable]$Control, [string]$Phase)
    $entries = foreach ($role in $roles) {
        if (-not $Control.Rules.ContainsKey($role)) { continue }
        $capture = $captures["$Phase-$role"]
        if (-not $capture -or $null -eq $capture.Measurements[$Control.Id]) {
            "$role missing"
        } else {
            $map = $capture.Measurements[$Control.Id]
            $pairs = foreach ($key in $map.Keys | Sort-Object) { "$key=$($map[$key])" }
            "$role ($($pairs -join ', '))"
        }
    }
    $entries -join ' / '
}

$score = @{
    Before = @{ Pass = 0; Fail = 0; Unmeasured = 0 }
    After = @{ Pass = 0; Fail = 0; Unmeasured = 0 }
}
$paired = 0
$pairedBefore = 0
$pairedAfter = 0
$improved = 0
$regressed = 0
$rows = foreach ($control in $catalog.Controls) {
    $before = Get-PhaseStatus $control Before
    $after = Get-PhaseStatus $control After
    $score.Before[$before]++
    $score.After[$after]++
    if ($before -ne 'Unmeasured' -and $after -ne 'Unmeasured') {
        $paired++
        if ($before -eq 'Pass') { $pairedBefore++ }
        if ($after -eq 'Pass') { $pairedAfter++ }
        if ($before -eq 'Fail' -and $after -eq 'Pass') { $improved++ }
        if ($before -eq 'Pass' -and $after -eq 'Fail') { $regressed++ }
    }
    "| $($control.Id) $($control.Title) | $before | $(Format-CaptureMeasurement $control Before) | $after | $(Format-CaptureMeasurement $control After) |"
}

$lines = @(
    '# IdentityLab configuration assessment'
    ''
    "Script revision **$($first.Revision)**"
    ''
    '| Phase | Pass | Fail | Unmeasured |'
    '| --- | --- | --- | --- |'
    "| Before | $($score.Before.Pass) | $($score.Before.Fail) | $($score.Before.Unmeasured) |"
    "| After | $($score.After.Pass) | $($score.After.Fail) | $($score.After.Unmeasured) |"
    ''
)
if ($paired) {
    $lines += "Among the $paired controls measured for both phases, $pairedBefore passed before and $pairedAfter passed after. $improved improved and $regressed regressed."
} else {
    $lines += 'A posture comparison is pending paired measurements.'
}
$lines += @(
    ''
    '## Control observations'
    ''
    'A value of -1 marks an absent explicit value where the probe reads a policy registry key. Probe errors and missing roles are Unmeasured. A Windows default may still provide protection when an explicit policy value is absent.'
    ''
    '| Control | Before | Before observations | After | After observations |'
    '| --- | --- | --- | --- | --- |'
)
$lines += $rows
$lines += @('', '## Capture timestamps and hashes', '', '| Source capture | UTC | SHA-256 |', '| --- | --- | --- |')
foreach ($key in $captures.Keys | Sort-Object) {
    $capture = $captures[$key]
    $lines += "| $key | $($capture.CapturedUtc.ToString('o')) | $($capture.Digest) |"
}
$lines += @('', '## Configuration inventory', '', '| Role and signal | Before | After |', '| --- | --- | --- |')
foreach ($role in $roles) {
    foreach ($name in $catalog.Inventory[$role] | Sort-Object) {
        $before = if ($captures["Before-$role"]) { $captures["Before-$role"].Inventory[$name] } else { 'Unavailable' }
        $after = if ($captures["After-$role"]) { $captures["After-$role"].Inventory[$name] } else { 'Unavailable' }
        $lines += "| $role $name | $before | $after |"
    }
}
$lines += @('', 'The comparison measures adherence to the lab baseline. Review health, authorization tests, and event evidence with the configuration results.')
Write-LabNewFile -Path $OutputPath -Text (($lines -join [Environment]::NewLine) + [Environment]::NewLine)
