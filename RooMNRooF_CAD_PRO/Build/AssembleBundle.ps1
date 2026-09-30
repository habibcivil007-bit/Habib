# Assembles Build\out\RooMNRooF.bundle from build outputs + resources.
param([string]$Versions = "2026 2027", [string]$Configuration = "Release")
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$out = Join-Path $root "Build\out\RooMNRooF.bundle"
if (Test-Path $out) { Remove-Item $out -Recurse -Force }   # only our own build output folder
$c = Join-Path $out "Contents"
New-Item -ItemType Directory -Force -Path $c | Out-Null
Copy-Item (Join-Path $root "Bundle\PackageContents.xml") $out
foreach ($v in ($Versions -split '\s+' | Where-Object { $_ })) {
    $bin = Join-Path $root "Build\bin\AutoCAD$v\$Configuration"
    if (-not (Test-Path (Join-Path $bin "RooMNRooF.CAD.dll"))) { throw "Missing build output for AutoCAD $v in $bin" }
    $dst = Join-Path $c "Win64\$v"
    New-Item -ItemType Directory -Force -Path $dst | Out-Null
    # never ship AutoCAD's own assemblies
    Get-ChildItem $bin -File | Where-Object { $_.Name -notmatch '^(ac|Ac|AdWindows)' } | Copy-Item -Destination $dst
}
foreach ($d in "Standards","Hatch","AutoLISP","Templates","Blocks","Samples","Documentation") {
    $src = Join-Path $root $d
    if (Test-Path $src) { Copy-Item $src (Join-Path $c $d) -Recurse -Exclude "previews" }
}
Copy-Item (Join-Path $root "VERSION.txt") $c
Write-Host "Bundle assembled: $out"
