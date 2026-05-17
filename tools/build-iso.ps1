# build-iso.ps1 — Relic OS ISO Builder (stub)
#
# STATUS: NOT YET IMPLEMENTED
# This script will eventually:
#   1. Read edited source files from src/relic/
#   2. Merge them with the TempleOS baseline in src/templeos/
#   3. Recompress modified .HC files using a host-side .Z compressor
#   4. Pack everything into a RedSea bootable ISO
#   5. Write the result to build/RelicOS.iso
#
# See: research/redsea-format.md (once it exists) for the ISO format spec.

Write-Host "build-iso.ps1: Not yet implemented." -ForegroundColor Yellow
Write-Host "This tool will build a bootable Relic OS ISO from source." -ForegroundColor Yellow
Write-Host "For now, build the ISO inside the TempleOS VM using:" -ForegroundColor Cyan
Write-Host '  #include "C:/Misc/DoDistro.HC.Z";' -ForegroundColor Cyan
