#!/usr/bin/env python3
"""
Builds the READY-TO-INSTALL "LISP Edition" package (no compilation needed):

  Release/RooMNRooF_CAD_PRO_2.0.0_LISP_Edition.zip
    RooMNRooF.bundle/            Autodesk ApplicationPlugins bundle (AutoLISP + standards + hatches + samples)
    Install.bat / Uninstall.bat  per-user install into %APPDATA%\\Autodesk\\ApplicationPlugins (no registry)
    README_INSTALL.txt

The full C# edition (RNR* commands, palette, MSI) needs compilation on Windows - see
Documentation/06_Build_And_Release.md or ci/roomnroof-release.yml.
"""
import os
import shutil
import zipfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
VER = open(os.path.join(ROOT, "VERSION.txt")).read().strip()
OUT = os.path.join(ROOT, "Release")
STAGE = os.path.join(OUT, "stage")
NAME = f"RooMNRooF_CAD_PRO_{VER}_LISP_Edition"

MANIFEST = f"""<?xml version="1.0" encoding="utf-8"?>
<!-- RooMNRooF CAD PRO ULTIMATE {VER} - LISP Edition bundle. No registry entries are written. -->
<ApplicationPackage SchemaVersion="1.0" AutodeskProduct="AutoCAD" ProductType="Application"
    Name="RooMNRooF CAD PRO ULTIMATE (LISP Edition)"
    Description="2D architectural / RCC drafting standards (drafting tool only - not engineering design or code verification)."
    AppVersion="{VER}" FriendlyVersion="{VER}" SupportedLocales="Enu" AppNameSpace="com.roomnroof.cadpro.lisp"
    Author="RooMNRooF" ProductCode="{{8A3C51D2-4E6F-4B19-A7C0-3D2E9F1B6C45}}"
    UpgradeCode="{{5B7E2A90-1C3D-4F8E-9A62-E0D4C7B3A118}}">
  <CompanyDetails Name="RooMNRooF" />
  <RuntimeRequirements OS="Win64" Platform="AutoCAD" SeriesMin="R24.0" />
  <Components Description="AutoLISP commands">
    <RuntimeRequirements OS="Win64" Platform="AutoCAD" SeriesMin="R24.0"
        SupportPath="./Contents/AutoLISP;./Contents/Hatch;./Contents/Standards" />
    <ComponentEntry AppName="RooMNRooF.LISP" Version="{VER}" ModuleName="./Contents/AutoLISP/RNR_Load.lsp"
        AppDescription="RooMNRooF RNRL-* commands" LoadOnAutoCADStartup="True" PerDocument="True" />
  </Components>
</ApplicationPackage>
"""

INSTALL = r"""@echo off
REM RooMNRooF CAD PRO ULTIMATE - LISP Edition installer (per user, no admin, no registry).
setlocal
set SRC=%~dp0RooMNRooF.bundle
set DST=%APPDATA%\Autodesk\ApplicationPlugins\RooMNRooF.bundle
echo RooMNRooF CAD PRO ULTIMATE - LISP Edition __VER__
echo.
echo This is a DRAFTING tool. It does not design structures or verify code compliance.
echo All design values are project inputs to be checked by the responsible engineer.
echo.
if not exist "%SRC%\PackageContents.xml" ( echo ERROR: run Install.bat from the extracted zip folder. & pause & exit /b 1 )
tasklist /FI "IMAGENAME eq acad.exe" | find /I "acad.exe" >nul && ( echo Please close AutoCAD first, then run Install.bat again. & pause & exit /b 1 )
if exist "%DST%" (
  choice /M "An existing RooMNRooF.bundle was found. Replace it"
  if errorlevel 2 ( echo Cancelled. & pause & exit /b 1 )
  rmdir /S /Q "%DST%"
)
xcopy "%SRC%" "%DST%\" /E /I /Y /Q >nul || ( echo Copy failed. & pause & exit /b 1 )
echo.
echo Installed to: %DST%
echo Start AutoCAD. If a security prompt appears for RNR_Load.lsp choose "Always Load".
echo Then type RNRL-SELFTEST to verify, and RNRL-HELP for the command list.
pause
"""

UNINSTALL = r"""@echo off
REM Removes only the RooMNRooF bundle folder. Your drawings are not touched.
set DST=%APPDATA%\Autodesk\ApplicationPlugins\RooMNRooF.bundle
if not exist "%DST%" ( echo RooMNRooF.bundle is not installed for this user. & pause & exit /b 0 )
choice /M "Remove %DST%"
if errorlevel 2 exit /b 1
rmdir /S /Q "%DST%" && echo Removed.
pause
"""

README = f"""RooMNRooF CAD PRO ULTIMATE {VER} - LISP Edition
=================================================

INSTALL
  1. Close AutoCAD.
  2. Extract this zip, double-click Install.bat.
  3. Start AutoCAD (2021 or newer, 64-bit). Choose "Always Load" if AutoCAD asks about RNR_Load.lsp
     (or add %APPDATA%\\Autodesk\\ApplicationPlugins to Options > Files > Trusted Locations).
  4. Type RNRL-SELFTEST (expect 0 FAIL), then RNRL-HELP.
     Full checklist: Contents\\Documentation\\10_Install_And_Verify.md

  Manual alternative: APPLOAD  ->  RooMNRooF.bundle\\Contents\\AutoLISP\\RNR_Load.lsp

UNINSTALL
  Run Uninstall.bat (removes only the bundle folder).

COMMANDS (36)
  Layers/standards: RNRL-LAYERS RNRL-ARCH RNRL-STRUCT RNRL-CIVIL RNRL-ANNO RNRL-RCC RNRL-LA RNRL-THAW
                    RNRL-COLORS RNRL-COLORAPPLY RNRL-BYLAYER RNRL-UNITS RNRL-STYLES
  Drafting:         RNRL-GRID RNRL-WALL RNRL-DOOR RNRL-WINDOW RNRL-ROOM RNRL-COLUMN RNRL-BEAM RNRL-FOOTING
  Rebar/hatch:      RNRL-REBAR RNRL-BARWT RNRL-HATCH
  Blocks/annotation:RNRL-BLOCKS RNRL-INSERT RNRL-BLOCKLIST RNRL-TAG RNRL-LEVEL RNRL-NORTH
  QA/plot:          RNRL-QA RNRPLOT-BW RNRPLOT-COLOR RNRPLOT-GRAY   Help: RNRL-HELP  Check: RNRL-SELFTEST

INCLUDED
  Contents\\AutoLISP   15 LISP modules
  Contents\\Hatch      custom PAT hatch patterns (on the support path after install)
  Contents\\Standards  JSON standards + RooMNRooF.lin
  Contents\\Blocks     RNR_Blocks.dxf - 29-block library (also built into the LISP code)
  Contents\\Samples    12 sample DXF drawings (3-storey residence)
  Contents\\Documentation

NOT INCLUDED IN THIS EDITION
  The C# plugin (RNR* commands, WPF palette, BBS/BOQ Excel export, DWT generator, MSI). It must be
  compiled on Windows: see Documentation\\06_Build_And_Release.md in the source repository.

STATUS / DISCLAIMER
  The LISP code passed static checks (brackets, reserved symbols, duplicates) but has NOT yet been
  run inside AutoCAD by the author. Please report any command-line errors.
  This is a drafting tool. It does not perform structural design or verify BNBC 2020 / ACI 318-19 /
  ASCE 7 compliance. Sample member sizes/reinforcement are placeholders. BBS/BOQ are estimates.
"""


def crlf(s):
    return s.replace("\r\n", "\n").replace("\n", "\r\n")


def main():
    shutil.rmtree(OUT, ignore_errors=True)
    b = os.path.join(STAGE, NAME, "RooMNRooF.bundle")
    c = os.path.join(b, "Contents")
    os.makedirs(c)
    with open(os.path.join(b, "PackageContents.xml"), "w", encoding="utf-8", newline="") as f:
        f.write(crlf(MANIFEST))
    shutil.copytree(os.path.join(ROOT, "AutoLISP"), os.path.join(c, "AutoLISP"))
    shutil.copytree(os.path.join(ROOT, "Hatch"), os.path.join(c, "Hatch"))
    shutil.copytree(os.path.join(ROOT, "Standards"), os.path.join(c, "Standards"))
    shutil.copytree(os.path.join(ROOT, "Samples"), os.path.join(c, "Samples"))
    shutil.copytree(os.path.join(ROOT, "Blocks"), os.path.join(c, "Blocks"))
    shutil.copytree(os.path.join(ROOT, "Documentation"), os.path.join(c, "Documentation"))
    # AutoCAD expects CRLF-friendly text; LISP/PAT/LIN files are ASCII
    for d, _, fs in os.walk(c):
        for fn in fs:
            if fn.lower().endswith((".lsp", ".pat", ".lin")):
                p = os.path.join(d, fn)
                t = open(p, encoding="utf-8").read()
                open(p, "w", encoding="utf-8", newline="").write(crlf(t))
    top = os.path.join(STAGE, NAME)
    for fn, txt in (("Install.bat", INSTALL.replace("__VER__", VER)), ("Uninstall.bat", UNINSTALL),
                    ("README_INSTALL.txt", README)):
        open(os.path.join(top, fn), "w", encoding="utf-8", newline="").write(crlf(txt))
    zp = os.path.join(OUT, NAME + ".zip")
    with zipfile.ZipFile(zp, "w", zipfile.ZIP_DEFLATED) as z:
        for d, _, fs in os.walk(top):
            for fn in sorted(fs):
                p = os.path.join(d, fn)
                z.write(p, os.path.relpath(p, STAGE))
    shutil.rmtree(STAGE)
    print("wrote", os.path.relpath(zp, ROOT), os.path.getsize(zp) // 1024, "KB")


if __name__ == "__main__":
    main()
