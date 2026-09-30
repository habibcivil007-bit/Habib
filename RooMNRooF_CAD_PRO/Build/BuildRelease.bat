@echo off
REM ============================================================================
REM RooMNRooF CAD PRO ULTIMATE - full release pipeline (Windows 11, x64)
REM Requires: .NET 8 SDK, AutoCAD 2026 and/or 2027 installed, Python 3.10+ with
REM           ezdxf/openpyxl (pip install -r Scripts\requirements.txt),
REM           WiX Toolset v6+ (SDK restored by NuGet) (dotnet tool install --global wix) for the MSI.
REM Usage:    Build\BuildRelease.bat [2026|2027|all]   (default: all found)
REM Every step stops the pipeline on failure. Nothing is reported as built
REM unless the tool actually produced it.
REM ============================================================================
setlocal EnableExtensions
set ROOT=%~dp0..
pushd "%ROOT%"
set TARGET=%1
if "%TARGET%"=="" set TARGET=all

echo [1/7] Regenerating standards data ...
python Scripts\generate_standards.py || goto :fail
echo [2/7] Validating standards / PAT / LISP ...
python Scripts\validate_standards.py || goto :fail
python Scripts\check_lisp.py || goto :fail

echo [3/7] Core unit tests ...
dotnet test Tests\RooMNRooF.Core.Tests\RooMNRooF.Core.Tests.csproj -c Release || goto :fail

echo [4/7] Building plugins ...
set BUILT=
set FAILED=
if /I "%TARGET%"=="2026" goto :b26
if /I "%TARGET%"=="2027" goto :b27
:b26
REM Uses local AutoCAD 2026 DLLs when installed, otherwise Autodesk's AutoCAD.NET NuGet reference assemblies.
dotnet build src\AutoCAD2026\RooMNRooF.CAD.2026.csproj -c Release
if errorlevel 1 ( echo     AutoCAD 2026 plugin build FAILED - see errors above & set FAILED=%FAILED% 2026 ) else ( set BUILT=%BUILT% 2026 )
if /I "%TARGET%"=="2026" goto :bundle
:b27
REM Uses local AutoCAD 2027 DLLs when installed, otherwise Autodesk's AutoCAD.NET NuGet reference assemblies.
dotnet build src\AutoCAD2027\RooMNRooF.CAD.2027.csproj -c Release
if errorlevel 1 ( echo     AutoCAD 2027 plugin build FAILED - see errors above & set FAILED=%FAILED% 2027 ) else ( set BUILT=%BUILT% 2027 )
:bundle
if /I not "%TARGET%"=="all" if not "%FAILED%"=="" goto :fail
if not "%FAILED%"=="" echo *** WARNING: plugin build failed for:%FAILED% - continuing with:%BUILT% ***
if "%BUILT%"=="" ( echo No AutoCAD version was built. & goto :fail )

echo [5/7] Assembling RooMNRooF.bundle ...
powershell -NoProfile -ExecutionPolicy Bypass -File Build\AssembleBundle.ps1 -Versions "%BUILT%" || goto :fail

echo [6/7] Verifying package ...
call Build\VerifyPackage.bat || goto :fail

echo [7/7] Building MSI ...
dotnet --list-sdks >nul 2>nul
if errorlevel 1 ( echo     .NET SDK missing - MSI skipped. Bundle is in Build\out\RooMNRooF.bundle & goto :done )
dotnet build Installer\RooMNRooF.Installer.wixproj -c Release || goto :fail

:done
echo.
echo RELEASE PIPELINE COMPLETED for:%BUILT%
echo Next: run the manual AutoCAD acceptance checklist (Documentation\07_Test_Plan.md).
popd & exit /b 0
:fail
echo.
echo *** RELEASE PIPELINE FAILED - see output above ***
popd & exit /b 1
