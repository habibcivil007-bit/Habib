@echo off
REM Verifies the assembled bundle is complete and version-consistent. Exit 1 on any failure.
setlocal EnableDelayedExpansion
set ROOT=%~dp0..
set B=%ROOT%\Build\out\RooMNRooF.bundle
set ERR=0
for %%F in (PackageContents.xml Contents\VERSION.txt Contents\AutoLISP\RNR_Load.lsp Contents\Standards\RNR_Layers.json Contents\Standards\RooMNRooF.lin Contents\Hatch\RooMNRooF.pat) do (
  if not exist "%B%\%%F" ( echo FAIL missing %%F & set ERR=1 ) else ( echo PASS %%F )
)
set FOUND=0
for %%V in (2026 2027) do if exist "%B%\Contents\Win64\%%V\RooMNRooF.CAD.dll" ( echo PASS Win64\%%V\RooMNRooF.CAD.dll & set FOUND=1 )
if "%FOUND%"=="0" ( echo FAIL no plugin DLL in bundle & set ERR=1 )
set /p VER=<"%ROOT%\VERSION.txt"
findstr /C:"AppVersion=\"%VER%\"" "%B%\PackageContents.xml" >nul || ( echo FAIL PackageContents AppVersion != %VER% & set ERR=1 )
findstr /C:"<Version>%VER%</Version>" "%ROOT%\Build\Version.props" >nul || ( echo FAIL Version.props != %VER% & set ERR=1 )
if exist "%B%\Contents\Win64\2026\acdbmgd.dll" ( echo FAIL AutoCAD assembly copied into bundle & set ERR=1 )
if "%ERR%"=="1" ( echo PACKAGE VERIFICATION FAILED & exit /b 1 )
echo PACKAGE VERIFICATION PASSED
exit /b 0
