# Install & Verify: step by step

Write the result of every step in the Result column of `Documentation/VerificationMatrix.xlsx`. If a step fails,
copy the text from the AutoCAD command line (F2) and report it.

## Part A: LISP Edition (ready-to-install zip)

### A1. Install
1. Close AutoCAD.
2. Right-click `RooMNRooF_CAD_PRO_2.0.0_LISP_Edition.zip`, choose **Extract All**, then open the extracted folder.
3. Double-click **Install.bat**. It should print `Installed to: C:\Users\<you>\AppData\Roaming\Autodesk\ApplicationPlugins\RooMNRooF.bundle`.
4. Start AutoCAD. If a *Security - Unsigned Executable File* dialog appears, choose **Always Load**.
5. The command line should show: `[RNR] RooMNRooF AutoLISP 2.0.0 loaded.`
   If it doesn't: run `APPLOAD`, browse to `%APPDATA%\Autodesk\ApplicationPlugins\RooMNRooF.bundle\Contents\AutoLISP\RNR_Load.lsp`, and click Load.

### A2. Automatic check
Run `RNRL-SELFTEST`. The expected result is **7 PASS, 0 FAIL** and `Commands defined: 36/36`.

### A3. Functional checks (new drawing from acadiso.dwt)
| # | Command | What you do | Expected result |
|---|---|---|---|
| 1 | `RNRL-UNITS` | choose mm | `UNITS` shows millimetres; INSUNITS = 4 |
| 2 | `RNRL-LAYERS` | ALL | about 87 layers such as A-WALL, S-COL, ANNO-GRID with TrueColor, linetype and lineweight |
| 3 | `RNRL-STYLES` | | text styles RNR_* and dim styles RNR_ARCH/RNR_STRUCT exist |
| 4 | `RNRL-GRID` | 3 bays in each direction | grid lines on S-GRID, bubbles A, B, C… and 1, 2, 3… |
| 5 | `RNRL-COLUMN` | pick grid points | 300×450 rectangles on S-COL with marks |
| 6 | `RNRL-BEAM` | pick 2 columns | double lines on S-BEAM with a label |
| 7 | `RNRL-FOOTING` | pick a column | footing outline on S-FTG |
| 8 | `RNRL-WALL` | pick points | 250 mm double-line wall on A-WALL |
| 9 | `RNRL-DOOR` / `RNRL-WINDOW` | pick on the wall | door leaf and arc on A-DOOR; window lines on A-WINDOW |
| 10 | `RNRL-ROOM` | click inside a closed room | name and area tag on A-ROOM |
| 11 | `RNRL-HATCH` | choose RCC or Brick, pick inside | hatch on the hatch layer; no "ANSI31 used" warning |
| 12 | `RNRL-REBAR` / `RNRL-BARWT` | T16, 10 m | 1.578 kg/m, which gives 15.78 kg |
| 13 | `RNRL-LEVEL`, `RNRL-TAG`, `RNRL-NORTH` | place | symbols on the ANNO-* layers |
| 14 | `RNRL-BLOCKS`, then `RNRL-INSERT` RNR_TOILET, `RNRL-BLOCKLIST` | | `29 of 29 RNR blocks available`; toilet inserted on A-FIXTURE; list printed |
| 15 | `RNRL-COLORS`, `RNRL-COLORAPPLY`, `RNRL-BYLAYER` | select objects | colours change; BYLAYER resets them |
| 16 | `RNRL-LA`, `RNRL-THAW` | | layer controls behave as described in the prompt |
| 17 | `RNRL-ARCH` / `RNRL-STRUCT` / `RNRL-CIVIL` / `RNRL-ANNO` / `RNRL-RCC` | | only that discipline's layers are created or isolated |
| 18 | `RNRL-QA` | first on this drawing, then after creating layer `TEST` | the report lists `TEST` as non-standard |
| 19 | `RNRPLOT-BW` / `-GRAY` / `-COLOR` | from a layout | PDF created; BW prints everything black with lineweights kept |
| 20 | Open `Contents\Samples\SampleProject\*.dxf`, then run `AUDIT` | | 0 errors in each of the 12 files |

### A4. Uninstall check
Close AutoCAD and run `Uninstall.bat`. The bundle folder is removed and AutoCAD starts without the RNR message.

## Part B: Full C# Edition (MSI), build first

### B1. Build it in the cloud (no software needed on your PC)
1. On GitHub, open the repo and branch `arena/01a0f2be-habib`, then **Add file → Create new file**.
2. Name it `.github/workflows/roomnroof-release.yml` and paste the content of `RooMNRooF_CAD_PRO/ci/roomnroof-release.yml`. Commit it.
3. Go to the **Actions** tab, open *RooMNRooF CAD PRO - build installer*, and wait for it to finish.
4. If it succeeds, download the artifact, which contains the `.msi` and `RooMNRooF.bundle.zip`.
   If it fails, copy the red error lines. The first compile will probably need fixes.

### B2. Build it on your own PC instead
Install the [.NET 8 SDK](https://dotnet.microsoft.com/download/dotnet/8.0) and Python 3.12, then run:
```bat
cd RooMNRooF_CAD_PRO
pip install -r Scripts\requirements.txt
Build\BuildRelease.bat 2026
```
Output: `Build\out\msi\*.msi`.

### B3. Install and verify
1. First uninstall the LISP Edition (`Uninstall.bat`); both use the folder name `RooMNRooF.bundle`.
2. Run the MSI and restart AutoCAD. Run `RNR`; the command menu should appear.
3. Run `NETLOAD` only when testing an unpackaged DLL.
4. Work through `Documentation/07_Test_Plan.md` items 1-12: RNRSTANDARD, RNRGRID, members, RNRBBS (open the CSV/XLSX in Excel),
   RNRSCHEDULE, RNRBOQ, RNRTITLE, RNRPLOTBW, RNRQA, RNRPREVIEW → RNRCLEAN → answer **No** (nothing is deleted), RNRTEMPLATE ALL.
5. Check the log at `%APPDATA%\RooMNRooF\Logs\RooMNRooF.log`; it should contain no `ERROR` lines.
6. Uninstall through **Settings → Apps**. The folder `C:\ProgramData\Autodesk\ApplicationPlugins\RooMNRooF.bundle` is removed.

## Offline checks (any PC with Python)
```bat
python Scripts\validate_standards.py     REM expected 24/24 PASS
python Scripts\check_lisp.py             REM expected 0 problems
```
