# Build & Release (Windows 11 x64)

> Status: the build scripts below were **written but not executed** in the authoring environment
> (no .NET SDK / AutoCAD available there). First real build must be done on Windows.

## Prerequisites
| Tool | Version | Notes |
|---|---|---|
| Windows 11 x64 | 22H2+ | |
| AutoCAD | 2026 (primary) and/or 2027 | provides `accoremgd.dll`, `acdbmgd.dll`, `acmgd.dll` |
| .NET SDK | 8.0.x | AutoCAD 2025+ plugins target `net8.0-windows` |
| Python | 3.10+ | `pip install -r Scripts\requirements.txt` |
| WiX | v6 SDK (restored automatically by NuGet) | only for the MSI |

## Steps
```bat
git clone <repo> && cd RooMNRooF_CAD_PRO
pip install -r Scripts\requirements.txt
Build\BuildRelease.bat            REM all installed AutoCAD versions
Build\BuildRelease.bat 2026       REM only 2026
```
Non-default AutoCAD path: `dotnet build src\AutoCAD2026\RooMNRooF.CAD.2026.csproj -c Release /p:AcadDir="D:\Autodesk\AutoCAD 2026"`.

Pipeline: generate standards → validate (Python + LISP) → `dotnet test` → build plugin(s) →
`AssembleBundle.ps1` → `VerifyPackage.bat` → MSI (`Build\out\msi\`).

## Output layout
```
Build\out\RooMNRooF.bundle\
  PackageContents.xml
  Contents\Win64\2026\RooMNRooF.CAD.dll, RooMNRooF.Core.dll
  Contents\Win64\2027\...
  Contents\Standards, Hatch, AutoLISP, Templates, Samples, Documentation
```
The plugin finds resources by walking up from its DLL folder to the first folder containing `Standards`.

## Install
* MSI: installs to `%ProgramData%\Autodesk\ApplicationPlugins\RooMNRooF.bundle` (no registry writes).
* Manual: `Build\InstallBundleForCurrentUser.bat` (asks before replacing an existing bundle).
* Dev: `NETLOAD` → `Build\bin\AutoCAD2026\Release\RooMNRooF.CAD.dll`.

## Before tagging a release
1. Confirm the AutoCAD 2027 series string (`(getvar "ACADVER")`) and update `SeriesMin/Max` in
   `Bundle/PackageContents.xml` and `AcadRelease` in the 2027 csproj if it differs from `R26.0`.
2. Bump `VERSION.txt`, `Build/Version.props`, `PackageContents.xml`, `Product.wxs` together
   (`VerifyPackage.bat` checks the first three).
3. Run the release gates in `VerificationMatrix.xlsx` (sheet *Release gates*); record real results.
4. Run `RNRTEMPLATE ALL` in AutoCAD to produce the 6 DWT files into `Templates\` before assembling.
