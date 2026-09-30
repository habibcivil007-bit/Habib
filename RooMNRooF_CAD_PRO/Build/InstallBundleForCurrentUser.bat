@echo off
REM Manual (no-MSI) install: copies the assembled bundle to the per-user ApplicationPlugins folder.
REM Does not touch the registry. Close AutoCAD first.
set SRC=%~dp0out\RooMNRooF.bundle
set DST=%APPDATA%\Autodesk\ApplicationPlugins\RooMNRooF.bundle
if not exist "%SRC%\PackageContents.xml" ( echo Build the bundle first: Build\BuildRelease.bat & exit /b 1 )
if exist "%DST%" (
  choice /M "RooMNRooF.bundle already exists at %DST%. Replace it"
  if errorlevel 2 exit /b 1
  rmdir /S /Q "%DST%"
)
xcopy "%SRC%" "%DST%\" /E /I /Y >nul && echo Installed to %DST%
