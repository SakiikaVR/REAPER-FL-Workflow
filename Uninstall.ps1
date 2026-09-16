param([string]$ResourcePath = (Join-Path $env:APPDATA 'REAPER'))
$ErrorActionPreference = 'Stop'
if ($ResourcePath -eq (Join-Path $env:APPDATA 'REAPER') -and (Get-Process reaper -ErrorAction SilentlyContinue)) { throw 'REAPERを保存して終了してから、Uninstall.cmdをもう一度実行してください。' }
$statePath = Join-Path $ResourcePath 'ReaperFLWorkflow-install-state.json'
if (-not (Test-Path $statePath)) { throw 'インストール情報が見つかりません。' }
$state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
$root = [IO.Path]::GetFullPath($ResourcePath).TrimEnd('\') + '\'
foreach ($item in $state.files) {
  $target = [IO.Path]::GetFullPath((Join-Path $ResourcePath $item.path))
  if (-not $target.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe restore path.' }
  if (Test-Path -LiteralPath $target) { Remove-Item -LiteralPath $target -Recurse -Force }
  if ($item.existed) {
    $backup = Join-Path $state.backup $item.path
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Copy-Item -LiteralPath $backup -Destination $target -Recurse -Force
  }
}
Remove-Item -LiteralPath $statePath -Force
Write-Host 'インストール前の設定へ復元しました。' -ForegroundColor Green
