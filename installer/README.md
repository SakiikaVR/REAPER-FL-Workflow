# EXE installer source

The published Windows installer is built with Easy Installer 2 (`eiedit.exe`). The EXE copies 34 files into `%APPDATA%\REAPER` and uses the installer's native INI feature for seven layout settings. It does not run CMD or PowerShell after installation.

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\Build-Project.ps1` from the repository root.
2. Open `dist\eiedit\REAPER-FL-Workflow-Direct-v1.1.4.pj2` in Easy Installer 2.
3. Create the EXE from the **処理** menu.

`template.pj2` contains the EInstall configuration. The build script stages the files, fills in absolute source paths required by EInstall, and writes the ready-to-build project under ignored `dist\eiedit`. The icon in the published v1.1.4 EXE was set in the editor; the reusable template uses the default installer icon. Neither changes REAPER's startup logo.
