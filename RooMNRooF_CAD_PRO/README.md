# RooMNRooF CAD PRO ULTIMATE 2.0.0

2D architectural + RCC structural **drafting** suite for AutoCAD 2026 (primary) / 2027 on Windows 11,
tailored to Bangladesh practice (BNBC 2020 / ACI 318-19 / ASCE 7 referenced as project metadata only).

> ⚠️ **Drafting tool only.** It does not perform structural design or verify code compliance. All
> member sizes, covers, reinforcement and loads are project inputs that the responsible engineer must
> verify. BBS/BOQ figures are CAD-derived estimates.

> ⚠️ **Build status: source release.** This repository contains source, data, scripts and configs.
> No DLL or MSI is included. The C# code was **not compiled** and nothing was **run inside AutoCAD** in
> the authoring environment. Build on Windows following `Documentation/06_Build_And_Release.md`.

## Ready-to-install download
`Release/RooMNRooF_CAD_PRO_2.0.0_LISP_Edition.zip`: extract it, run `Install.bat`, start AutoCAD, then type `RNRL-HELP`.
It contains the AutoLISP edition (34 commands, standards, hatches, linetypes, samples). No compiler is needed.
The full C# edition (MSI) has to be compiled on Windows. You can use `Build\BuildRelease.bat` locally, or copy
`ci/roomnroof-release.yml` to `.github/workflows/` so GitHub Actions builds the MSI using Autodesk's `AutoCAD.NET`
NuGet reference assemblies.

## Repository layout
| Path | Content |
|---|---|
| `src/Shared/RooMNRooF.Core` | AutoCAD-independent library (net8.0): units, rebar, BBS, BOQ, schedules, QA, exporters, logging |
| `src/Shared/RooMNRooF.Plugin` | AutoCAD plugin source (commands, services, WPF palette) — compiled per version |
| `src/AutoCAD2026`, `src/AutoCAD2027` | version-specific projects (reference local AutoCAD DLLs) |
| `Tests/RooMNRooF.Core.Tests` | xUnit tests for Core |
| `AutoLISP/` | 15 LISP modules, 34 `RNRL-*` / `RNRPLOT-*` commands (no DLL needed) |
| `Standards/` | JSON standards, `RooMNRooF.lin` (generated) |
| `Hatch/` | custom PAT files |
| `Samples/SampleProject/` | 12 DXF drawings of a 3-storey residence + PNG previews |
| `Bundle/PackageContents.xml` | Autodesk ApplicationPlugins manifest (no registry use) |
| `Installer/` | WiX v6 MSI project |
| `Build/` | `BuildRelease.bat`, `AssembleBundle.ps1`, `VerifyPackage.bat`, `Version.props` |
| `Scripts/` | generators and validators (Python) |
| `Documentation/` | user guide, standards, build/release, test plan, dynamic blocks, verification matrix |

## Quick start
```bat
pip install -r Scripts\requirements.txt
python Scripts\validate_standards.py
Build\BuildRelease.bat
```
In AutoCAD: `NETLOAD` the built DLL (or install the MSI) → `RNR` / `RNRPANEL`.
Without the DLL: `APPLOAD AutoLISP\RNR_Load.lsp` → `RNRL-HELP`.

Regenerate data: `python Scripts/generate_standards.py`, `python Scripts/generate_samples.py`,
`python Scripts/generate_verification_matrix.py`.

## Final status
| Component | Status | Evidence |
|---|---|---|
| Standards JSON (colours 114, layers 87, filters 12, members 55, hatches 20, blocks 29, rebar T8–T32) | VALIDATED OFFLINE | `validate_standards.py` 24/24 PASS |
| PAT hatch files (11 + combined) | VALIDATED OFFLINE (syntax) | `validate_standards.py` PAT check; not loaded in AutoCAD |
| Linetypes `RooMNRooF.lin` | VALIDATED OFFLINE (definitions referenced) | `validate_standards.py` |
| Sample project DXF (12 sheets) | VALIDATED OFFLINE | ezdxf audit 0 errors, standard layers only; PNG previews rendered |
| AutoLISP (15 modules, 34 commands) | STATIC CHECK PASS — not run in AutoCAD | `check_lisp.py` 0 problems |
| Core library C# | SOURCE — syntax OK, NOT compiled | `syntax_check_csharp.py` 0 errors |
| Plugin C# (~70 commands, WPF palette) | SOURCE — syntax + member-name cross-check OK, NOT compiled | tree-sitter check; no .NET SDK / AutoCAD available |
| xUnit tests (37) | WRITTEN — NOT RUN | requires `dotnet test` |
| DWT templates (6) | NOT SHIPPED — generated in AutoCAD by `RNRTEMPLATE` | by design (valid per AutoCAD version) |
| Dynamic block parameters | MANUAL STEP | API limitation, see `09_Dynamic_Block_Manual.md` |
| LISP Edition zip (ready to install) | PACKAGED — manifest XML valid, not tested in AutoCAD | `Scripts/package_lisp_edition.py` |
| Bundle manifest / WiX MSI | CONFIG WRITTEN — NOT BUILT | XML well-formed |
| Build scripts | WRITTEN — NOT EXECUTED | Windows-only |
| AutoCAD 2026/2027 functional testing | NOT DONE | manual checklist in `07_Test_Plan.md` / `VerificationMatrix.xlsx` |

Nothing above is marked VERIFIED because it has not been compiled or run in AutoCAD.
