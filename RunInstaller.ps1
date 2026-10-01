$ErrorActionPreference = 'Stop'
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('ReaperFLWorkflow-' + [guid]::NewGuid().ToString('N'))
try {
  Expand-Archive -LiteralPath (Join-Path $PSScriptRoot 'package.zip') -DestinationPath $temporary
  & (Join-Path $temporary 'Install.ps1')
} catch {
  Write-Host $_ -ForegroundColor Red
  Read-Host 'Enterキーを押して閉じてください' | Out-Null
  exit 1
} finally {
  if (Test-Path -LiteralPath $temporary) { Remove-Item -LiteralPath $temporary -Recurse -Force }
}
