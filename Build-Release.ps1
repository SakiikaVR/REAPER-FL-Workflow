param([string]$Version = '1.1.0')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'stage'
$source = Join-Path $dist 'iexpress'
$distFull = [IO.Path]::GetFullPath($dist).TrimEnd('\') + '\'
foreach ($path in @($stage,$source)) {
  $resolved = [IO.Path]::GetFullPath($path)
  if (-not $resolved.StartsWith($distFull,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe build path.' }
  if (Test-Path -LiteralPath $resolved) { Remove-Item -LiteralPath $resolved -Recurse -Force }
}
New-Item -ItemType Directory -Path $dist,$stage,$source -Force | Out-Null

foreach ($file in @('Install.ps1','Uninstall.ps1','Uninstall.cmd','LICENSE','THIRD_PARTY_NOTICES.md')) {
  Copy-Item -LiteralPath (Join-Path $root $file) -Destination $stage -Force
}
foreach ($folder in @('payload\Scripts','payload\Data','third_party')) {
  $destination = Join-Path $stage $folder
  New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
  Copy-Item -LiteralPath (Join-Path $root $folder) -Destination $destination -Recurse -Force
}
$plugins = Join-Path $stage 'payload\UserPlugins'
New-Item -ItemType Directory -Path $plugins -Force | Out-Null
foreach ($file in @('reaper_DarkMode_x64.dll','reaper_darkmode.ini','reaper_js_ReaScriptAPI64.dll')) {
  Copy-Item -LiteralPath (Join-Path $root ('payload\UserPlugins\' + $file)) -Destination $plugins -Force
}
$archive = Join-Path $source 'package.zip'
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -CompressionLevel Optimal
Copy-Item -LiteralPath (Join-Path $root 'RunInstaller.ps1') -Destination $source -Force

$target = Join-Path $dist ("REAPER-FL-Workflow-v$Version.exe")
$sed = Join-Path $dist 'package.sed'
if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Force }
$sourcePath = $source.TrimEnd('\') + '\'
@"
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=1
HideExtractAnimation=0
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=
DisplayLicense=
FinishMessage=
TargetName=$target
FriendlyName=REAPER FL Workflow $Version
AppLaunched=powershell.exe -NoProfile -ExecutionPolicy Bypass -File RunInstaller.ps1
PostInstallCmd=<None>
AdminQuietInstCmd=
UserQuietInstCmd=
SourceFiles=SourceFiles
[SourceFiles]
SourceFiles0=$sourcePath
[SourceFiles0]
%FILE0%=
%FILE1%=
[Strings]
FILE0="RunInstaller.ps1"
FILE1="package.zip"
"@ | Set-Content -LiteralPath $sed -Encoding Ascii
& "$env:WINDIR\System32\iexpress.exe" /N /Q $sed
for ($i = 0; $i -lt 100 -and -not (Test-Path -LiteralPath $target); $i++) { Start-Sleep -Milliseconds 100 }
if (-not (Test-Path -LiteralPath $target)) { throw 'IExpress build failed.' }
$hash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant()
($hash + '  ' + [IO.Path]::GetFileName($target)) | Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS.txt') -Encoding Ascii
Write-Output $hash
