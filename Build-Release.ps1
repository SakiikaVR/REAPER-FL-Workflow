param([string]$Version = '1.1.2')
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'stage'
$distFull = [IO.Path]::GetFullPath($dist).TrimEnd('\') + '\'
$stageFull = [IO.Path]::GetFullPath($stage)
if (-not $stageFull.StartsWith($distFull,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe build path.' }
if (Test-Path -LiteralPath $stageFull) { Remove-Item -LiteralPath $stageFull -Recurse -Force }
New-Item -ItemType Directory -Path $dist,$stage -Force | Out-Null

foreach ($file in @('Install.cmd','Install.ps1','Uninstall.cmd','Uninstall.ps1','README.md','LICENSE','THIRD_PARTY_NOTICES.md')) {
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

$archive = Join-Path $dist ("REAPER-FL-Workflow-v$Version.zip")
if (Test-Path -LiteralPath $archive) { Remove-Item -LiteralPath $archive -Force }
Compress-Archive -Path (Join-Path $stage '*') -DestinationPath $archive -CompressionLevel Optimal
$hash = (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
($hash + '  ' + [IO.Path]::GetFileName($archive)) | Set-Content -LiteralPath (Join-Path $dist 'SHA256SUMS.txt') -Encoding Ascii
Write-Output $hash
