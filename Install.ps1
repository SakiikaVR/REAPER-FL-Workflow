param(
  [string]$ResourcePath = (Join-Path $env:APPDATA 'REAPER'),
  [switch]$SkipLaunch
)

$ErrorActionPreference = 'Stop'
$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$payload = Join-Path $packageRoot 'payload'
$realResource = Join-Path $env:APPDATA 'REAPER'

function Write-Utf8([string]$Path, [string]$Text) {
  $parent = Split-Path -Parent $Path
  if ($parent) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  [IO.File]::WriteAllText($Path, $Text, (New-Object Text.UTF8Encoding($false)))
}

function Set-IniValue([string]$Path, [string]$Section, [string]$Key, [string]$Value) {
  $text = if (Test-Path -LiteralPath $Path) { [IO.File]::ReadAllText($Path) } else { '' }
  $header = '[' + $Section + ']'
  $sectionPattern = '(?ms)^' + [regex]::Escape($header) + '\r?\n.*?(?=^\[|\z)'
  $match = [regex]::Match($text, $sectionPattern)
  if ($match.Success) {
    $block = $match.Value
    $keyPattern = '(?m)^' + [regex]::Escape($Key) + '=.*$'
    if ([regex]::IsMatch($block, $keyPattern)) {
      $block = [regex]::Replace($block, $keyPattern, $Key + '=' + $Value)
    } else {
      $block = $block.TrimEnd("`r", "`n") + "`r`n" + $Key + '=' + $Value + "`r`n"
    }
    $text = $text.Remove($match.Index, $match.Length).Insert($match.Index, $block)
  } else {
    if ($text.Length -gt 0 -and -not $text.EndsWith("`n")) { $text += "`r`n" }
    $text += $header + "`r`n" + $Key + '=' + $Value + "`r`n"
  }
  Write-Utf8 $Path $text
}

function Set-IniSection([string]$Path, [string]$Section, [string]$Body) {
  $text = if (Test-Path -LiteralPath $Path) { [IO.File]::ReadAllText($Path) } else { '' }
  $block = '[' + $Section + "]`r`n" + $Body.Trim() + "`r`n`r`n"
  $pattern = '(?ms)^\[' + [regex]::Escape($Section) + '\]\r?\n.*?(?=^\[|\z)'
  if ([regex]::IsMatch($text, $pattern)) { $text = [regex]::Replace($text, $pattern, $block, 1) }
  else { $text = $block + $text.TrimStart() }
  Write-Utf8 $Path $text
}

function New-YuGothicTheme([string]$Source, [string]$Target) {
  Copy-Item -LiteralPath $Source -Destination $Target -Force
  Add-Type -AssemblyName System.IO.Compression
  Add-Type -AssemblyName System.IO.Compression.FileSystem
  $zip = [IO.Compression.ZipFile]::Open($Target, [IO.Compression.ZipArchiveMode]::Update)
  try {
    $themeEntry = $zip.Entries | Where-Object { $_.FullName.Trim() -match '\.ReaperTheme$' } | Select-Object -First 1
    if (-not $themeEntry) { throw 'Default theme data was not found.' }
    $entryName = $themeEntry.FullName
    $reader = New-Object IO.StreamReader($themeEntry.Open(), [Text.Encoding]::UTF8, $true)
    $themeText = $reader.ReadToEnd(); $reader.Dispose()
    $fontPattern = '(?m)^((?:lb_font2?|tl_font|trans_font|mi_font|user_font\d+)=)([0-9A-Fa-f]{122})(\r?)$'
    $themeText = [regex]::Replace($themeText, $fontPattern, {
      param($m)
      $hex = $m.Groups[2].Value
      $bytes = New-Object byte[] 61
      for ($i = 0; $i -lt 61; $i++) { $bytes[$i] = [Convert]::ToByte($hex.Substring($i * 2, 2), 16) }
      $bytes[23] = 1
      for ($i = 28; $i -lt 60; $i++) { $bytes[$i] = 0 }
      $face = [Text.Encoding]::ASCII.GetBytes('Yu Gothic UI')
      [Array]::Copy($face, 0, $bytes, 28, $face.Length)
      $sum = 0; for ($i = 0; $i -lt 60; $i++) { $sum = ($sum + $bytes[$i]) -band 255 }
      $bytes[60] = [byte]$sum
      $newHex = -join ($bytes | ForEach-Object { $_.ToString('X2') })
      $m.Groups[1].Value + $newHex + $m.Groups[3].Value
    })
    $themeEntry.Delete()
    $newEntry = $zip.CreateEntry($entryName, [IO.Compression.CompressionLevel]::Optimal)
    $writer = New-Object IO.StreamWriter($newEntry.Open(), (New-Object Text.UTF8Encoding($false)))
    $writer.Write($themeText); $writer.Dispose()

    $imageFolder = [IO.Path]::GetFileNameWithoutExtension($entryName.Trim())
    $gridName = $imageFolder + '/gridbox.ini'
    $oldGrid = $zip.GetEntry($gridName); if ($oldGrid) { $oldGrid.Delete() }
    $grid = $zip.CreateEntry($gridName, [IO.Compression.CompressionLevel]::Optimal)
    $gridWriter = New-Object IO.StreamWriter($grid.Open(), (New-Object Text.UTF8Encoding($false)))
    $gridWriter.Write("box_x=600`nbox_y=4`nbox_w=80`nbox_h=32`nattach_x=-270`nattach_mode=2`nfont_family=Yu Gothic UI`n")
    $gridWriter.Dispose()
  } finally { $zip.Dispose() }
}

if ($ResourcePath -eq $realResource -and (Get-Process reaper -ErrorAction SilentlyContinue)) {
  throw 'REAPERを保存して終了してから、Install.cmdをもう一度実行してください。'
}
if (-not (Test-Path -LiteralPath $ResourcePath)) { throw "REAPER resource path not found: $ResourcePath" }

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $ResourcePath ('ReaperFLWorkflow-Backups\' + $stamp)
$managed = @(
  'reaper-kb.ini','reaper-menu.ini','reaper-mouse.ini','reaper-extstate.ini','REAPER.ini',
  'Scripts\__startup.lua','Scripts\FLPianoRoll','Scripts\FTC\Adaptive grid',
  'UserPlugins\reaper_DarkMode_x64.dll','UserPlugins\reaper_darkmode.ini',
  'UserPlugins\reaper_js_ReaScriptAPI64.dll','UserPlugins\reaper_LINEFont.dll',
  'ColorThemes\Yu Gothic UI.ReaperThemeZip','Data\custom-startup-logo.png'
)
$state = [ordered]@{ version='1.0.0'; installed=(Get-Date).ToString('o'); backup=$backupRoot; files=@() }
foreach ($relative in $managed) {
  $source = Join-Path $ResourcePath $relative
  $exists = Test-Path -LiteralPath $source
  $state.files += [ordered]@{ path=$relative; existed=$exists }
  if ($exists) {
    $destination = Join-Path $backupRoot $relative
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $source -Destination $destination -Recurse -Force
  }
}

Copy-Item -LiteralPath (Join-Path $payload 'Scripts\FLPianoRoll') -Destination (Join-Path $ResourcePath 'Scripts') -Recurse -Force
New-Item -ItemType Directory -Path (Join-Path $ResourcePath 'Scripts\FTC') -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $payload 'Scripts\FTC\Adaptive grid') -Destination (Join-Path $ResourcePath 'Scripts\FTC') -Recurse -Force
New-Item -ItemType Directory -Path (Join-Path $ResourcePath 'UserPlugins'),(Join-Path $ResourcePath 'Data'),(Join-Path $ResourcePath 'ColorThemes') -Force | Out-Null
Copy-Item -Path (Join-Path $payload 'UserPlugins\*') -Destination (Join-Path $ResourcePath 'UserPlugins') -Force
Copy-Item -LiteralPath (Join-Path $payload 'Data\custom-startup-logo.png') -Destination (Join-Path $ResourcePath 'Data\custom-startup-logo.png') -Force

$defaultTheme = Join-Path $ResourcePath 'ColorThemes\Default_7.0.ReaperThemeZip'
if (-not (Test-Path -LiteralPath $defaultTheme)) {
  $installedDefault = Join-Path ${env:ProgramFiles} 'REAPER (x64)\InstallData\ColorThemes\Default_7.0.ReaperThemeZip'
  if (Test-Path -LiteralPath $installedDefault) { $defaultTheme = $installedDefault }
}
$customTheme = Join-Path $ResourcePath 'ColorThemes\Yu Gothic UI.ReaperThemeZip'
if (-not (Test-Path -LiteralPath $defaultTheme)) { throw 'Default_7.0.ReaperThemeZip is required.' }
New-YuGothicTheme $defaultTheme $customTheme

$kbPath = Join-Path $ResourcePath 'reaper-kb.ini'
$kb = @()
if (Test-Path $kbPath) { $kb = @(Get-Content -LiteralPath $kbPath) }
$kb = @($kb | Where-Object { $_ -notmatch '^KEY 255 (248|249) (989|990|40431|40432) (0|32060)(\s|$)' })
$kb += 'KEY 255 248 989 0'
$kb += 'KEY 255 249 990 0'
$kb += 'KEY 255 248 40432 32060'
$kb += 'KEY 255 249 40431 32060'
Write-Utf8 $kbPath (($kb -join "`r`n") + "`r`n")

Set-IniSection (Join-Path $ResourcePath 'reaper-menu.ini') 'Empty TCP area toolbar' @'
default=8e09af4c19a5dab2
item_0=40701 Insert virtual instrument on new track...
'@
Set-IniValue (Join-Path $ResourcePath 'REAPER.ini') 'REAPER' 'splashimage' (Join-Path $ResourcePath 'Data\custom-startup-logo.png')
Set-IniValue (Join-Path $ResourcePath 'REAPER.ini') 'REAPER' 'lastthemefn5' $customTheme
Set-IniValue (Join-Path $ResourcePath 'reaper-extstate.ini') 'FTC.GridBox' 'theme_settings' 't:{ColorThemes/Default_7.0:t:{box_x:n:600,box_y:n:4,box_w:n:80,box_h:n:32,attach_x:n:-270,attach_mode:n:2}}'
Set-IniValue (Join-Path $ResourcePath 'reaper-extstate.ini') 'FTC.GridBox' 'is_edit_mode' 'b:0'

$startupPath = Join-Path $ResourcePath 'Scripts\__startup.lua'
$startup = if (Test-Path $startupPath) { [IO.File]::ReadAllText($startupPath) } else { '' }
$startup = [regex]::Replace($startup, '(?ms)-- BEGIN REAPER FL Workflow.*?-- END REAPER FL Workflow\r?\n?', '')
$startup += @'

-- BEGIN REAPER FL Workflow
do
  local resource = reaper.GetResourcePath()
  local file = resource .. '/Scripts/FTC/Adaptive grid/Gridbox.lua'
  local id = reaper.AddRemoveReaScript(true, 0, file, true)
  if id ~= 0 and reaper.APIExists('JS_Composite_Delay') then reaper.Main_OnCommand(id, 0) end
end
-- END REAPER FL Workflow
'@
Write-Utf8 $startupPath $startup

$statePath = Join-Path $ResourcePath 'ReaperFLWorkflow-install-state.json'
Write-Utf8 $statePath ($state | ConvertTo-Json -Depth 6)

if (-not $SkipLaunch) {
  $reaperExe = Join-Path ${env:ProgramFiles} 'REAPER (x64)\reaper.exe'
  if (-not (Test-Path $reaperExe)) { throw 'reaper.exe was not found.' }
  $installerScript = Join-Path $ResourcePath 'Scripts\FLPianoRoll\install.lua'
  Start-Process -FilePath $reaperExe -ArgumentList '-noactivate', ('"' + $installerScript + '"')
}

Write-Host ''
Write-Host 'REAPER FL Workflow をインストールしました。' -ForegroundColor Green
Write-Host ('バックアップ: ' + $backupRoot)
Write-Host 'REAPER起動後、FL風ピアノロールとGridboxが有効になります。'
