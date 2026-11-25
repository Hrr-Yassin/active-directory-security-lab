#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-LabControlCatalog {
    Import-PowerShellDataFile (Join-Path $PSScriptRoot 'Lab.Controls.psd1')
}

function Assert-LabFactMap {
    param($Facts, [string[]]$ExpectedKeys)

    if ($Facts -isnot [System.Collections.IDictionary] -or $Facts.Count -ne $ExpectedKeys.Count) {
        throw 'Unexpected shape for measured facts.'
    }
    foreach ($key in $ExpectedKeys) {
        if ($key -notin $Facts.Keys) { throw "Missing expected measurement $key." }
        $value = $Facts[$key]
        if (($value -isnot [int] -and $value -isnot [long]) -or $value -lt -1 -or $value -gt [int]::MaxValue) {
            throw "Measurement $key must be an integer in the supported range."
        }
    }
}

function Get-LabFactStatus {
    param([System.Collections.IDictionary]$Facts, [hashtable]$Rules)

    foreach ($key in $Rules.Keys) {
        if ($Rules[$key] -notmatch '^(-eq|-ge|-le):(-?\d+)$') { throw "Invalid acceptance rule for $key." }
        $comparison = $Matches[1]
        $target = [int]$Matches[2]
        $value = $Facts[$key]
        $passed = switch ($comparison) {
            '-eq' { $value -eq $target }
            '-ge' { $value -ge $target }
            '-le' { $value -le $target }
        }
        if (-not $passed) { return 'Fail' }
    }
    'Pass'
}

function Write-LabNewFile {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
    $target = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
    $directory = [IO.Path]::GetDirectoryName($target)
    $null = [IO.Directory]::CreateDirectory($directory)
    $temporary = Join-Path $directory ('.idlab-' + [guid]::NewGuid().ToString('N'))
    try {
        [IO.File]::WriteAllText($temporary, $Text, [Text.UTF8Encoding]::new($false))
        [IO.File]::Move($temporary, $target)
    } finally {
        [IO.File]::Delete($temporary)
    }
    $target
}

Export-ModuleMember -Function Get-LabControlCatalog, Assert-LabFactMap, Get-LabFactStatus, Write-LabNewFile
