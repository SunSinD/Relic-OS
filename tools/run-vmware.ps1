# run-vmware.ps1 — Launch VMware with Relic OS ISO (stub)
#
# STATUS: NOT YET IMPLEMENTED
# This script will eventually:
#   1. Find build/RelicOS.iso (produced by build-iso.ps1)
#   2. Attach it to the correct VMware VM as the CD/DVD boot image
#   3. Start the VM and boot from the ISO
#
# Requires: VMware Workstation and the VM .vmx path configured below.

$vmxPath   = "CONFIGURE_ME\TempleOS.vmx"   # <-- set this to your .vmx file
$isoPath   = "$PSScriptRoot\..\build\RelicOS.iso"

Write-Host "run-vmware.ps1: Not yet implemented." -ForegroundColor Yellow
Write-Host "Set `$vmxPath` to your VMware .vmx file path to enable this script." -ForegroundColor Yellow
Write-Host ""
Write-Host "For now, attach the ISO manually in VMware Workstation:" -ForegroundColor Cyan
Write-Host "  VM Settings -> CD/DVD -> Use ISO image file -> select the ISO" -ForegroundColor Cyan
