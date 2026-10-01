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

if ($ResourcePath -eq $realResource -and (Get-Process reaper -ErrorAction SilentlyContinue)) {
  throw 'REAPERを保存して終了してから、インストーラーをもう一度実行してください。'
}
if (-not (Test-Path -LiteralPath $ResourcePath)) { throw "REAPER resource path not found: $ResourcePath" }
$statePath = Join-Path $ResourcePath 'ReaperFLWorkflow-install-state.json'
if (Test-Path -LiteralPath $statePath) { throw '既にインストールされています。先にReaperFLWorkflow-Uninstall.cmdまたは旧版のUninstall.cmdを実行してください。' }
if (-not $SkipLaunch) {
  $reaperExe = Join-Path ${env:ProgramFiles} 'REAPER (x64)\reaper.exe'
  if (-not (Test-Path -LiteralPath $reaperExe)) { throw 'reaper.exe was not found.' }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $ResourcePath ('ReaperFLWorkflow-Backups\' + $stamp)
$managed = @(
  'reaper-kb.ini','reaper-menu.ini','reaper-mouse.ini','reaper-extstate.ini','REAPER.ini',
  'Scripts\__startup.lua','Scripts\FLPianoRoll','Scripts\FTC\Adaptive grid',
  'UserPlugins\reaper_DarkMode_x64.dll','UserPlugins\reaper_darkmode.ini',
  'UserPlugins\reaper_js_ReaScriptAPI64.dll','Data\custom-startup-logo.png',
  'ReaperFLWorkflow-Uninstall.cmd','ReaperFLWorkflow-Uninstall.ps1'
)
$state = [ordered]@{ version='1.1.2'; installed=(Get-Date).ToString('o'); backup=$backupRoot; files=@() }
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
New-Item -ItemType Directory -Path (Join-Path $ResourcePath 'UserPlugins'),(Join-Path $ResourcePath 'Data') -Force | Out-Null
foreach ($file in @('reaper_DarkMode_x64.dll','reaper_darkmode.ini','reaper_js_ReaScriptAPI64.dll')) {
  Copy-Item -LiteralPath (Join-Path $payload ('UserPlugins\' + $file)) -Destination (Join-Path $ResourcePath ('UserPlugins\' + $file)) -Force
}
Copy-Item -LiteralPath (Join-Path $payload 'Data\custom-startup-logo.png') -Destination (Join-Path $ResourcePath 'Data\custom-startup-logo.png') -Force
Copy-Item -LiteralPath (Join-Path $packageRoot 'Uninstall.cmd') -Destination (Join-Path $ResourcePath 'ReaperFLWorkflow-Uninstall.cmd') -Force
Copy-Item -LiteralPath (Join-Path $packageRoot 'Uninstall.ps1') -Destination (Join-Path $ResourcePath 'ReaperFLWorkflow-Uninstall.ps1') -Force

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
  if reaper.GetExtState('FLPianoRoll_v1', 'enabled') == '1' then
    local piano = dofile(resource .. '/Scripts/FLPianoRoll/core.lua')
    piano.enableLengthMemoryWhenReady()
  end
end
-- END REAPER FL Workflow
'@
Write-Utf8 $startupPath $startup

Write-Utf8 $statePath ($state | ConvertTo-Json -Depth 6)

if (-not $SkipLaunch) {
  $installerScript = Join-Path $ResourcePath 'Scripts\FLPianoRoll\install.lua'
  Start-Process -FilePath $reaperExe -ArgumentList '-noactivate', ('"' + $installerScript + '"')
}

Write-Host ''
Write-Host 'REAPER FL Workflow をインストールしました。' -ForegroundColor Green
Write-Host ('バックアップ: ' + $backupRoot)
Write-Host 'REAPER起動後、FL風ピアノロールとGridboxが有効になります。'
