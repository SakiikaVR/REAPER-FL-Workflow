param(
  [string]$SourceDirectory = (Join-Path $PSScriptRoot '..\dist\eiedit\uncompressed'),
  [string]$OutputFile = (Join-Path $PSScriptRoot '..\dist\eiedit\REAPER-FL-Workflow-Direct-v1.1.5.zip')
)
$ErrorActionPreference = 'Stop'
$source = [IO.Path]::GetFullPath($SourceDirectory)
$output = [IO.Path]::GetFullPath($OutputFile)
$stage = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\dist\eiedit\direct-stage'))

foreach ($name in @('INSTALL.EXE', 'INSTALL.DAT', 'logo.ico')) {
  if (-not (Test-Path -LiteralPath (Join-Path $source $name) -PathType Leaf)) {
    throw "Missing installer file: $name"
  }
}
if (-not (Test-Path -LiteralPath (Join-Path $source 'Files') -PathType Container)) {
  throw 'Missing Files directory.'
}
$rootFiles = @(Get-ChildItem -LiteralPath $source -File | Sort-Object Name | ForEach-Object Name)
if (($rootFiles -join '|') -ne 'INSTALL.DAT|INSTALL.EXE|logo.ico') {
  throw "Unexpected files in installer root: $($rootFiles -join ', ')."
}
$rootDirectories = @(Get-ChildItem -LiteralPath $source -Directory | ForEach-Object Name)
if (($rootDirectories -join '|') -ne 'Files') { throw 'Unexpected directories in installer root.' }
$payload = @(Get-ChildItem -LiteralPath (Join-Path $source 'Files') -Recurse -File)
$staged = @(Get-ChildItem -LiteralPath $stage -Recurse -File)
if ($payload.Count -ne $staged.Count -or $payload.Count -ne 34) {
  throw "Unexpected payload count: output=$($payload.Count), staged=$($staged.Count)."
}
foreach ($file in $staged) {
  $relative = $file.FullName.Substring($stage.Length).TrimStart('\')
  $installed = Join-Path (Join-Path $source 'Files') $relative
  if (-not (Test-Path -LiteralPath $installed -PathType Leaf)) { throw "Missing payload: $relative" }
  $expected = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
  $actual = (Get-FileHash -LiteralPath $installed -Algorithm SHA256).Hash
  if ($expected -ne $actual) { throw "Payload differs: $relative" }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
New-Item -ItemType Directory -Path (Split-Path -Parent $output) -Force | Out-Null
if (Test-Path -LiteralPath $output) { Remove-Item -LiteralPath $output -Force }
$archive = [IO.Compression.ZipFile]::Open($output, [IO.Compression.ZipArchiveMode]::Create)
try {
  foreach ($file in @(Get-ChildItem -LiteralPath $source -Recurse -File | Sort-Object FullName)) {
    $relative = $file.FullName.Substring($source.Length).TrimStart('\').Replace([char]92, [char]47)
    [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $relative, [IO.Compression.CompressionLevel]::Optimal)
  }
} finally { $archive.Dispose() }
[IO.Compression.ZipFile]::OpenRead($output).Dispose()
Get-Item -LiteralPath $output | Select-Object FullName, Length
Get-FileHash -LiteralPath $output -Algorithm SHA256 | Select-Object Hash
