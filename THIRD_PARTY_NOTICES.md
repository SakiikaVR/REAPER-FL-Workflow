# Third-party notices

The release package contains these unmodified third-party components.

| Component | Version/source | License | Included files |
|---|---|---|---|
| [ReaperDarkMode](https://github.com/RobKor77/ReaperDarkMode) | v1.1.0 | MIT | `reaper_DarkMode_x64.dll`, `reaper_darkmode.ini` |
| [Reaper-Tools / Gridbox](https://github.com/iliaspoulakis/Reaper-Tools) | master snapshot | MIT | `payload/Scripts/FTC/Adaptive grid/` |
| [js_ReaScriptAPI](https://github.com/juliansader/ReaExtensions) | v1.310 | MIT | `reaper_js_ReaScriptAPI64.dll` |

License texts are stored in [`third_party/`](third_party/).

REAPER and its default themes are not redistributed. The installer does not change the selected theme or font settings.

The [Phroneris Japanese language pack](https://github.com/Phroneris/ReaperJPN-Phroneris) is not included or downloaded because its repository does not state a license. README instructions only link to its upstream release.

## Provenance verification

- ReaperDarkMode: v1.1.0, commit `2d90f3a4427c5567924eb5c32311957009b9cb81`; the bundled DLL is byte-for-byte identical to the official release asset (SHA-256 `d21a9a8a4b1ed5f138afb2d6881a25db128f835d3fffeb9e2ec2564d8863a636`).
- Reaper-Tools / Gridbox: commit `2ddfacaa0c3fd49928ffe6aea411cb31cadcc442`; all 16 bundled Lua files match the upstream Git blobs.
- js_ReaScriptAPI: v1.310 from commit `2100b96d99b8621f6145a0f02000036c23b3d938`; bundled DLL Git blob `93d6c2e3df091125c97eb741a9e50e9f054b396a` matches upstream.
- The installer and FLPianoRoll scripts are original work in this repository.
- The startup image is an original geometric design created for this repository. It does not reuse the earlier user-supplied screenshot.

REAPER is a product of Cockos Incorporated. FL Studio is a product of Image-Line. Their names are used only to describe compatibility and workflow behavior. This project is not affiliated with or endorsed by Cockos or Image-Line.
