#!/usr/bin/env bash
set -eu

uri=qemu:///system
storage=${1:-/var/lib/libvirt/images}

printf '%s\n' 'Host capacity'
free -h
printf 'Logical CPUs %s\n' "$(nproc)"
df -h "$storage"
test -r /dev/kvm || printf '%s\n' 'KVM is unavailable in this execution context.'

printf '\n%s\n' 'Current IPv4 routes'
ip -4 route show table all

printf '\n%s\n' 'Registered guests and networks'
virsh --readonly --connect "$uri" list --all
virsh --readonly --connect "$uri" net-list --all

printf '\n%s\n' 'Media pools'
virsh --readonly --connect "$uri" pool-list --all
