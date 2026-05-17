# extract-redsea.ps1 — Unpack a TempleOS RedSea ISO (stub)
#
# STATUS: NOT YET IMPLEMENTED
# This script will eventually:
#   1. Take a RedSea ISO file as input
#   2. Parse the RedSea filesystem layout
#   3. Extract all files into src/templeos/
#   4. Decompress .HC.Z files using a TempleOS-compatible decompressor
#
# References:
#   - src/templeos/Downloads/Linux/TOSZ.CPP  (TempleOS compression source)
#   - research/redsea-format.md              (once documented)

param(
    [string]$IsoPath = "C:\Users\SunSD\Downloads\TempleOS.ISO"
)

Write-Host "extract-redsea.ps1: Not yet implemented." -ForegroundColor Yellow
Write-Host "Input ISO would be: $IsoPath" -ForegroundColor Yellow
Write-Host ""
Write-Host "The repo already contains a manually extracted baseline at:" -ForegroundColor Cyan
Write-Host "  src/templeos/" -ForegroundColor Cyan
