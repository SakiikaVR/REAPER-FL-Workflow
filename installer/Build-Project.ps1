$ErrorActionPreference = 'Stop'
$root = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$buildDir = Join-Path $root 'dist\eiedit'
$stage = Join-Path $buildDir 'direct-stage'
$outputDir = Join-Path $buildDir 'uncompressed'
$baseProject = Join-Path $PSScriptRoot 'template.pj2'
$outputProject = Join-Path $buildDir 'REAPER-FL-Workflow-Direct-v1.1.6.pj2'
$utf8 = New-Object Text.UTF8Encoding($false)
$stageFull = [IO.Path]::GetFullPath($stage)
$eieditFull = [IO.Path]::GetFullPath($buildDir).TrimEnd('\') + '\'
if (-not $stageFull.StartsWith($eieditFull,[StringComparison]::OrdinalIgnoreCase)) { throw 'Unsafe stage path.' }
if (Test-Path -LiteralPath $stageFull) { Remove-Item -LiteralPath $stageFull -Recurse -Force }
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
New-Item -ItemType Directory -Path $stage -Force | Out-Null
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'logo.ico') -Destination (Join-Path $buildDir 'logo.ico') -Force

function Put-File([string]$Source, [string]$Relative) {
  $target = Join-Path $stage $Relative
  New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
  Copy-Item -LiteralPath $Source -Destination $target -Force
}
function Put-Text([string]$Relative, [string]$Content) {
  $target = Join-Path $stage $Relative
  New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
  $normalized = $Content.TrimStart("`r", "`n") -replace "(?<!`r)`n", "`r`n"
  [IO.File]::WriteAllText($target, $normalized, $utf8)
}

foreach ($base in @('payload\Scripts','payload\UserPlugins','third_party')) {
  foreach ($file in @(Get-ChildItem -LiteralPath (Join-Path $root $base) -Recurse -File)) {
    if ($base -eq 'payload\UserPlugins' -and $file.Name -notin @('reaper_DarkMode_x64.dll','reaper_darkmode.ini','reaper_js_ReaScriptAPI64.dll')) { continue }
    $relative = $file.FullName.Substring($root.Length).TrimStart('\')
    if ($base -eq 'third_party') { $relative = Join-Path 'Docs' $relative }
    else { $relative = $relative.Substring('payload\'.Length) }
    $relative = $relative.Replace([string][char]0x2215, '-')
    Put-File $file.FullName $relative
  }
}
Put-File (Join-Path $root 'LICENSE') 'Docs\LICENSE'
Put-File (Join-Path $root 'THIRD_PARTY_NOTICES.md') 'Docs\THIRD_PARTY_NOTICES.md'

Put-Text 'reaper-kb.ini' @'
SCR 4 32060 RS7d3c_b5464fbb19ba54b9739df80c5618ffc53cd7fb98 "Custom: FL Piano Roll - Duplicate to right.lua" "FLPianoRoll/FL Piano Roll - Duplicate to right.lua"
KEY 9 66 _RS7d3c_b5464fbb19ba54b9739df80c5618ffc53cd7fb98 32060
KEY 255 248 989 0
KEY 255 249 990 0
KEY 255 248 40432 32060
KEY 255 249 40431 32060
'@
Put-Text 'reaper-menu.ini' @'
[Empty TCP area toolbar]
default=8e09af4c19a5dab2
item_0=40701 Insert virtual instrument on new track...

[Main toolbar]
default=7bb33abf03be6cea
item_0=40023 New project...
item_1=40025 Open project...
item_2=40026 Save project
item_3=40021 Project settings...
item_4=40029 Undo
item_5=40030 Redo
item_6=40364 Enable metronome
item_7=42616 Marquee selection
item_8=-1
item_9=40041 Enable auto-crossfade
item_10=1156 Enable item and track media/razor edit grouping
item_11=1162 Toggle ripple editing
item_12=40070 Move envelope points with media items
item_13=40145 Show arrange view grid
item_14=1157 Enable snapping
item_15=1135 Enable locking
item_16=42618 Razor editing
item_17=40214 Insert new MIDI item...
tbf_7=1
tbf_11=1
tbf_16=1
'@
Put-Text 'reaper-extstate.ini' @'
[FTC.GridBox]
theme_settings=t:{ColorThemes/Default_7.0:t:{box_x:n:1208,box_h:n:32,attach_mode:n:2,box_w:n:50,box_y:n:2,attach_x:n:-712,draw_scale:n:1.005,measure_scale:n:1.005}}
is_edit_mode=b:0
'@
Put-Text 'reaper-mouse.ini' @'
[hasimported]
MM_CTX_MIDI_PIANOROLL_CLK=1
MM_CTX_MIDI_PIANOROLL=1
MM_CTX_MIDI_NOTE_CLK=1
MM_CTX_MIDI_NOTE=1
MM_CTX_MIDI_NOTEEDGE=1
MM_CTX_MIDI_RMOUSE=1

[MM_CTX_MIDI_PIANOROLL_CLK]
mm_0=4 m
mm_2=0 m
mm_3=0 m

[MM_CTX_MIDI_PIANOROLL]
mm_0=1 m
mm_2=7 m

[MM_CTX_MIDI_NOTE_CLK]
mm_0=1 m

[MM_CTX_MIDI_NOTE]
mm_0=1 m
mm_1=7 m

[MM_CTX_MIDI_NOTEEDGE]
mm_0=1 m

[MM_CTX_MIDI_RMOUSE]
mm_0=10 m
mm_2=1 m
'@
Put-Text 'Scripts\__startup.lua' @'
do
  local resource = reaper.GetResourcePath()
  local piano_dir = resource .. '/Scripts/FLPianoRoll/'
  if reaper.GetExtState('FLPianoRoll_v1', 'enabled') ~= '1' then
    dofile(piano_dir .. 'install.lua')
  else
    dofile(piano_dir .. 'core.lua').enableLengthMemoryWhenReady()
  end
  local gridbox = resource .. '/Scripts/FTC/Adaptive grid/Gridbox.lua'
  local id = reaper.AddRemoveReaScript(true, 0, gridbox, true)
  if id ~= 0 and reaper.APIExists('JS_Composite_Delay') then
    reaper.Main_OnCommand(id, 0)
  end
end
'@

$encoding = [Text.Encoding]::GetEncoding(932)
$project = [IO.File]::ReadAllText($baseProject, $encoding)
$project = $project.Replace('CreateFileName=REAPER-FL-Workflow-Direct-v1.1.4','CreateFileName=REAPER-FL-Workflow-Direct-v1.1.6')
$project = $project.Replace('SoftName=REAPER FL Workflow Direct v1.1.4','SoftName=REAPER FL Workflow Direct v1.1.6')
$project = $project.Replace('ReleaseVersion=4','ReleaseVersion=6')
$project = $project.Replace('CreateFolder=',"CreateFolder=$outputDir")
$project = $project.Replace('LogoFileName=',"LogoFileName=$(Join-Path $buildDir 'logo.ico')")
$files = @(Get-ChildItem -LiteralPath $stage -Recurse -File | Sort-Object FullName)
$items = New-Object System.Collections.Generic.List[string]
for ($i = 0; $i -lt $files.Count; $i++) {
  $file = $files[$i]
  $relative = $file.FullName.Substring($stage.Length).TrimStart('\')
  $subdir = Split-Path -Path $relative -Parent
  if ($subdir -eq '.') { $subdir = '' }
  $items.Add("$i=1|0|%InstallDir%|$subdir|$($file.FullName)|||0|0|65535||0,0,HKEY_CURRENT_USER,,,,0,,,0,,,,,,,,,,,|||||||||")
}
$section = "[Files]`r`n" + ($items -join "`r`n") + "`r`n`r`n"
$project = [regex]::Replace($project, '(?ms)^\[Files\]\r?\n.*?(?=^\[|\z)', [Text.RegularExpressions.MatchEvaluator]{ param($m) $section })
$layout = [ordered]@{
  mixwnd_vis='1'; mixwnd_dock='0'
  transport_vis='1'; transport_dock='1'; transport_dock_pos='771'
  dockermode0='0'; dockheight='41'
}
$iniTemplate = '0=0|%InstallDir%||test.ini|reaper|transport_dock|1|4095|0,0,0,0,0,0,0,0,0,,,,,,,,,,,,|0,0,HKEY_CURRENT_USER,,,,0,,,0,,,,,,,,,,,|||||||||||'
$iniItems = New-Object System.Collections.Generic.List[string]
$index = 0
foreach ($key in $layout.Keys) {
  $iniItems.Add($iniTemplate.Replace('0=0|',"$index=0|").Replace('test.ini','REAPER.ini').Replace('|transport_dock|1|',"|$key|$($layout[$key])|"))
  $index++
}
$iniSection = "[IniFileItems]`r`n" + ($iniItems -join "`r`n") + "`r`n`r`n"
$project = [regex]::Replace($project, '(?ms)^\[IniFileItems\]\r?\n.*?(?=^\[|\z)', [Text.RegularExpressions.MatchEvaluator]{ param($m) $iniSection })
[IO.File]::WriteAllText($outputProject, $project, $encoding)
"Project: $outputProject"
"Output folder: $outputDir"
"Files: $($files.Count)"
