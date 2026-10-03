# ZIP installer source

The v1.1.5 release changes the packaging of the v1.1.4 workflow files. Its ZIP contains an uncompressed Easy Installer 2 output: `INSTALL.EXE`, `INSTALL.DAT`, `logo.ico`, and `Files/`. Keep these together after extraction. The installer copies 34 files to `%APPDATA%\REAPER` and updates seven layout values with EInstall's native INI feature. It does not run CMD or PowerShell after installation.

1. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\Build-Project.ps1` from the repository root.
2. Open `dist\eiedit\REAPER-FL-Workflow-Direct-v1.1.4.pj2` in Easy Installer 2 and build it from the **処理** menu. The output should appear in `dist\eiedit\uncompressed`.
3. Run `powershell -NoProfile -ExecutionPolicy Bypass -File .\installer\Package-Uncompressed.ps1` to create `dist\eiedit\REAPER-FL-Workflow-Direct-v1.1.5.zip`. The packaging script checks the 34 output files against the staged payload before creating the ZIP.

`template.pj2` is an editor-saved project configured for uncompressed output. `Build-Project.ps1` fills in the absolute source paths required by EInstall and copies the icon from `installer/logo.ico`. Neither changes REAPER's startup logo or font.
