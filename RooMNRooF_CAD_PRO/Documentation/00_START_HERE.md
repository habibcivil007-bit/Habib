# START HERE: Download, Build, Install and Verify

This guide covers the whole process, from downloading the project to confirming that it works in AutoCAD.
You can go through it in order. Anything marked **Expected** is what you should see if the step worked.

> **Honest status:** the AutoLISP edition is packaged and ready to install. The C# edition (full plugin and MSI)
> has **never been compiled**, so your first build will probably report some errors. That is normal: copy the
> errors (see section 9) and they will be fixed. Nothing has been tested inside AutoCAD yet, and your test run is the first.

---

## 0. Choose your path

| Path | You get | Time | Needs |
|---|---|---|---|
| **A: LISP Edition** (no build) | 36 `RNRL-*` commands, 29 blocks, templates, hatches, samples | 5 min | AutoCAD only |
| **B: Build on your PC** | full C# plugin (~70 `RNR*` commands, palette, Excel BBS/BOQ) + MSI | 30–60 min | .NET 8 SDK, Python, Git |
| **C: Build on GitHub** (cloud) | same as B, and nothing to install on your PC | 15 min | GitHub account |

Start with **A**, which is useful right away. Then do **B** or **C** for the full edition.

---

## 1. Download

**Option 1: ZIP (no Git needed)**
1. Open <https://github.com/habibcivil007-bit/Habib/archive/refs/heads/arena/01a0f2be-habib.zip>
2. Save the file, right-click it, choose **Extract All**, and extract to `C:\RNR\` (a short path avoids Windows path-length problems).
3. The project is now in `C:\RNR\Habib-arena-01a0f2be-habib\RooMNRooF_CAD_PRO\`.
   The rest of this guide calls that folder **`<PROJECT>`**.

**Option 2: Git**
```bat
cd C:\RNR
git clone -b arena/01a0f2be-habib https://github.com/habibcivil007-bit/Habib.git
cd Habib\RooMNRooF_CAD_PRO
```

**Check:** `<PROJECT>` contains `AutoLISP`, `Build`, `Documentation`, `Release`, `src`, `Standards`, and `RooMNRooF.sln`.

---

## 2. Path A: Install the LISP Edition (no build)

1. Close AutoCAD.
2. Open `<PROJECT>\Release\`, right-click `RooMNRooF_CAD_PRO_2.0.0_LISP_Edition.zip`, and choose **Extract All**.
3. In the extracted folder, double-click **`Install.bat`**.
   **Expected:** `Installed to: C:\Users\<you>\AppData\Roaming\Autodesk\ApplicationPlugins\RooMNRooF.bundle`
4. Start AutoCAD. If a security dialog asks about `RNR_Load.lsp`, click **Always Load**.
   **Expected** on the command line: `[RNR] RooMNRooF AutoLISP 2.0.0 loaded. Type RNRL-HELP ...`
   - If you don't see it: run `APPLOAD` and load
     `%APPDATA%\Autodesk\ApplicationPlugins\RooMNRooF.bundle\Contents\AutoLISP\RNR_Load.lsp`.
5. Continue with **section 7** (verification).

---

## 3. Path B: Build on your PC. Step 1: install the tools (one time)

Open **Windows Terminal / Command Prompt as a normal user** and run:

```bat
winget install Microsoft.DotNet.SDK.8
winget install Python.Python.3.12
winget install Git.Git
```
Close the terminal and open a new one so the PATH updates take effect. Then check the tools:

```bat
dotnet --list-sdks
python --version
git --version
```
**Expected:** a line starting with `8.0.`, `Python 3.12.x`, and a git version.

> AutoCAD **does not** have to be installed to *compile*. If it isn't, the projects automatically use
> Autodesk's official **AutoCAD.NET** NuGet reference assemblies. You do need AutoCAD to *test*.

If `winget` is missing, download the installers instead:
- .NET 8 SDK (x64): <https://dotnet.microsoft.com/download/dotnet/8.0>
- Python 3.12: <https://www.python.org/downloads/> (tick **Add python.exe to PATH**)
- Git (optional): <https://git-scm.com/download/win>

---

## 4. Path B, step 2: run the offline checks (2 min)

```bat
cd /d <PROJECT>
pip install -r Scripts\requirements.txt
python Scripts\validate_standards.py
python Scripts\check_lisp.py
python Scripts\syntax_check_csharp.py
```
**Expected:**
- `24/24 checks passed`
- `17 LISP files, 36 commands, 0 problem(s)`
- `36 C# files parsed, 0 with syntax errors` (or more files if code was added)

If any of these fail, stop and report the output (section 9).

---

## 5. Path B, step 3: build

### 5.1 One command (recommended)
```bat
cd /d <PROJECT>
Build\BuildRelease.bat 2026
```
The pipeline has 7 steps, and each prints `[n/7]`:

| Step | What it does | Expected |
|---|---|---|
| 1/7 | regenerate standards JSON | `Wrote ...` lines |
| 2/7 | validation (Python + LISP) | `24/24 checks passed`, `0 problem(s)` |
| 3/7 | `dotnet test` (Core unit tests) | `Passed!  - Failed: 0, Passed: 37` |
| 4/7 | compile the AutoCAD 2026 plugin | `Build succeeded.  0 Error(s)` |
| 5/7 | assemble `Build\out\RooMNRooF.bundle` | `Bundle assembled: ...` |
| 6/7 | `VerifyPackage.bat` | every line `PASS`, then `PACKAGE VERIFICATION PASSED` |
| 7/7 | build the MSI (WiX v6, downloaded by NuGet) | `Build succeeded.` |

End result: `RELEASE PIPELINE COMPLETED for: 2026`

`Build\BuildRelease.bat` with no argument also tries 2027. If the 2027 build fails (for example because
the AutoCAD 2027 NuGet package isn't published yet), you get a WARNING and the pipeline continues with 2026 only.

### 5.2 Individual commands (useful when fixing errors)
```bat
dotnet test  Tests\RooMNRooF.Core.Tests\RooMNRooF.Core.Tests.csproj -c Release
dotnet build src\AutoCAD2026\RooMNRooF.CAD.2026.csproj -c Release
dotnet build src\AutoCAD2026\RooMNRooF.CAD.2026.csproj -c Release -p:UseAcadNuGet=true      REM force NuGet refs
dotnet build src\AutoCAD2026\RooMNRooF.CAD.2026.csproj -c Release -p:AcadDir="D:\Autodesk\AutoCAD 2026"  REM custom install path
powershell -ExecutionPolicy Bypass -File Build\AssembleBundle.ps1 -Versions "2026"
Build\VerifyPackage.bat
dotnet build Installer\RooMNRooF.Installer.wixproj -c Release
```

### 5.3 Where the outputs are
| File | Path |
|---|---|
| Plugin DLL | `Build\bin\AutoCAD2026\Release\RooMNRooF.CAD.dll` (+ `RooMNRooF.Core.dll`) |
| Bundle folder | `Build\out\RooMNRooF.bundle\` |
| MSI installer | `Build\out\msi\RooMNRooF_CAD_PRO_ULTIMATE_2.0.0_x64.msi` |

---

## 6. Path C: Build on GitHub (cloud, nothing to install locally)

1. Sign in to GitHub and open <https://github.com/habibcivil007-bit/Habib/tree/arena/01a0f2be-habib>.
2. Click **Add file → Create new file** and type the name: `.github/workflows/roomnroof-release.yml`
3. Open `RooMNRooF_CAD_PRO/ci/roomnroof-release.yml` in another tab, click **Raw**, copy everything,
   paste it into the new file, and click **Commit changes**. Commit to branch `arena/01a0f2be-habib`.
4. Open the **Actions** tab and click the run **RooMNRooF CAD PRO - build installer**. The run takes about 5–10 minutes.
5. **Green check:** scroll down to **Artifacts** and download `RooMNRooF_CAD_PRO_ULTIMATE_2.0.0`.
   It contains the `.msi` and `RooMNRooF.bundle.zip`.
   **Red X:** click the failed step, copy the red error lines, and report them (section 9).
6. To rebuild later, go to **Actions → the workflow → Run workflow**.

---

## 7. Install the full edition

> Remove the LISP Edition first (both use the folder `RooMNRooF.bundle`): run its `Uninstall.bat`.

Choose one of these:
- **MSI (all users):** double-click the `.msi` and accept the prompts. It installs to
  `C:\ProgramData\Autodesk\ApplicationPlugins\RooMNRooF.bundle`.
- **Per user, no admin rights:** run `Build\InstallBundleForCurrentUser.bat`.
- **Developer test without installing:** start AutoCAD, run `NETLOAD`, and pick `Build\bin\AutoCAD2026\Release\RooMNRooF.CAD.dll`.

Start AutoCAD 2026.
**Expected:** a RooMNRooF load message. Typing `RNR` shows the command menu, and `RNRPANEL` opens the palette.

---

## 8. Verify in AutoCAD

### 8.1 Automatic checks (1 min)
| Command | Expected |
|---|---|
| `RNRL-SELFTEST` | `7 PASS, 0 FAIL`, `Commands defined: 36/36` |
| `RNR` (full edition only) | command menu appears, no error |

### 8.2 LISP Edition functional test (about 20 min)
Start a new drawing from `acadiso.dwt`:

| # | Command | Action | Expected |
|---|---|---|---|
| 1 | `RNRL-UNITS` | mm | `INSUNITS` = 4 |
| 2 | `RNRL-LAYERS` | ALL | about 87 layers such as A-WALL and S-COL, with TrueColor |
| 3 | `RNRL-STYLES` | | RNR_* text styles and RNR_ARCH/RNR_STRUCT dimension styles |
| 4 | `RNRL-GRID` | 3×3 bays | grid lines on S-GRID with bubbles |
| 5 | `RNRL-COLUMN` | pick grid points | column rectangles on S-COL |
| 6 | `RNRL-BEAM` | pick 2 points | beam on S-BEAM with a label |
| 7 | `RNRL-FOOTING` | pick column | footing on S-FTG |
| 8 | `RNRL-WALL` | pick points | 250 mm double wall on A-WALL |
| 9 | `RNRL-DOOR` / `RNRL-WINDOW` | pick on wall | on A-DOOR / A-WINDOW |
| 10 | `RNRL-ROOM` | click inside room | name and area on A-ROOM |
| 11 | `RNRL-HATCH` | RCC / Brick | hatch drawn with no "ANSI31 used" warning |
| 12 | `RNRL-BARWT` | T16, 10 m | **15.78 kg** |
| 13 | `RNRL-BLOCKS` | | `29 of 29 RNR blocks available` |
| 14 | `RNRL-INSERT` | RNR_TOILET | toilet inserted on A-FIXTURE |
| 15 | `RNRL-LEVEL`, `RNRL-TAG`, `RNRL-NORTH` | place | on the ANNO-* layers |
| 16 | `RNRL-QA` | create layer `TEST` first | report lists `TEST` as non-standard |
| 17 | `RNRPLOT-BW` | from a layout | PDF all black, line thicknesses kept |
| 18 | open `Contents\Samples\SampleProject\*.dxf`, then `AUDIT` | each file | 0 errors |
| 19 | open `Contents\Templates\RNR_ARCHITECTURAL_Starter.dxf` | | A1 layout, title block, 1:100 viewport |
| 20 | in that file `SAVEAS`, choose *.dwt* | | your own template created |

### 8.3 Full edition functional test
| # | Command | Expected |
|---|---|---|
| 1 | `RNRSTANDARD` | layers, styles, linetypes and hatches loaded; no errors |
| 2 | `RNRGRID`, `RNRCOLUMN`, `RNRBEAM`, `RNRSLAB`, `RNRFOOTING` | objects on the correct S-* layers |
| 3 | `RNRWALL`, `RNRDOOR`, `RNRWINDOW`, `RNRROOM`, `RNRSTAIR` | correct A-* layers; room area tag |
| 4 | `RNRMATLIB` → `RNRMATAPPLY`, `RNRMATLEGEND` | hatch applied; legend table |
| 5 | `RNRREBAR`, `RNRBBS` | CSV, XLSX and JSON files that open in Excel; weight = d²/162.2 × length |
| 6 | `RNRSCHEDULE`, `RNRBOQ` | AutoCAD table; CSV/XLSX export |
| 7 | `RNRTITLE A1`, `RNRLAYOUT` | layout with title block |
| 8 | `RNRPLOTCOLOR` / `RNRPLOTBW` / `RNRPLOTGRAY` | 3 PDFs |
| 9 | `RNRQA` | non-standard items reported as FAIL, never a false PASS |
| 10 | `RNRPREVIEW` → `RNRCLEAN` → answer **No** | **nothing is deleted** |
| 11 | `RNRTEMPLATE` ALL | `.dwt` files created in the bundle `Templates` folder |
| 12 | `RNRLOG` | opens `%APPDATA%\RooMNRooF\Logs`; the log has no `ERROR` lines |

### 8.4 Uninstall check
- MSI: **Settings → Apps → RooMNRooF CAD PRO ULTIMATE → Uninstall**. The folder under `C:\ProgramData\...` disappears.
- LISP / per-user: run `Uninstall.bat`.
- Restart AutoCAD. The RNR message should no longer appear.

### 8.5 Record the results
Open `<PROJECT>\Documentation\VerificationMatrix.xlsx` and fill in **Result / Tester / Date** for each row.
In the **Release gates** sheet, change a gate from `NOT RUN` to `PASS` only if you actually saw it pass.

---

## 9. When something fails: what to send

1. **Build errors:** copy the lines containing `error CS....` (file, line and message) from the terminal or the GitHub Actions log.
   Only the first 20–30 errors are needed, because later errors often follow from the earlier ones.
2. **AutoCAD errors:** press **F2**, copy the command-line text around the error, and include the command you typed.
3. **Log:** `%APPDATA%\RooMNRooF\Logs\RooMNRooF.log` (full edition).
4. Paste all of it into the chat and say which step number it came from.

## 10. Troubleshooting

| Problem | Fix |
|---|---|
| `dotnet` not recognised | open a new terminal after installing the SDK, or reinstall the .NET 8 SDK x64 |
| `NU1101: Unable to find package AutoCAD.NET` | check your internet connection or proxy. For 2027, the package may not exist yet: build `2026` only |
| `error CS0246 ... Autodesk` | the reference assemblies were not found. Add `-p:UseAcadNuGet=true` or `-p:AcadDir=...` |
| `NETLOAD`: "Cannot load assembly" | right-click the DLL → Properties → **Unblock** (files downloaded as a ZIP are blocked by Windows) |
| AutoCAD doesn't auto-load the bundle | check that the folder name ends in `.bundle` and that `PackageContents.xml` is directly inside it. Run `APPAUTOLOAD` = 14 |
| Security prompt every time | Options → Files → **Trusted Locations** → add the bundle `Contents` folder |
| `RNR_RCC.pat not on support path` | reinstall, or add `...\RooMNRooF.bundle\Contents\Hatch` to the Support File Search Path |
| Plugin loads in 2026 but not 2027 | check `(getvar "ACADVER")` in 2027 and update `SeriesMin/SeriesMax` in `Bundle\PackageContents.xml` |
| MSI step fails | the bundle is still usable: install it with `Build\InstallBundleForCurrentUser.bat` |

---

**Reminder:** RooMNRooF CAD PRO is a drafting tool. It does not perform structural design or check compliance
with BNBC 2020, ACI 318-19 or ASCE 7. Sizes and reinforcement shown in the samples are placeholders.
