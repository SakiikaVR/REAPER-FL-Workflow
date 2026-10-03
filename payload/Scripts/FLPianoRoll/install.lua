local dir=reaper.GetResourcePath()..'/Scripts/FLPianoRoll/'
local M=dofile(dir..'core.lua')
local out=assert(io.open(dir..'installation-report.txt','w'))
-- Check the right-drag label against this installed version, restoring immediately.
local ctx='MM_CTX_MIDI_RMOUSE'; local old=reaper.GetMouseModifier(ctx,0)
reaper.SetMouseModifier(ctx,0,'Delete notes/CC immediately (suppress right-click context menu)')
local actual=reaper.GetMouseModifier(ctx,0)
reaper.SetMouseModifier(ctx,0,old)
assert(actual=='10 m','Immediate delete modifier differs: '..actual)
M.restore()
local before={}
for i,b in ipairs(M.bindings) do before[i]=reaper.GetMouseModifier(b[1],b[2]) end
M.enable()
M.restore()
for i,b in ipairs(M.bindings) do assert(before[i]==reaper.GetMouseModifier(b[1],b[2]),'Round-trip failed') end
out:write('PASS: enable/restore round-trip for all bindings\n')
local scripts={'FL Piano Roll - Enable.lua','FL Piano Roll - Restore original mouse settings.lua','FL Piano Roll - Toggle paint mode.lua','FL Piano Roll - Duplicate to right.lua'}
for _,name in ipairs(scripts) do
 for _,section in ipairs({0,32060}) do
  local id=reaper.AddRemoveReaScript(true,section,dir..name,true)
  assert(id~=0,'Registration failed: '..name)
  out:write('Registered '..section..' '..id..' '..name..'\n')
 end
end
M.enable()
if not reaper.MIDIEditor_GetActive() then M.enableLengthMemoryWhenReady() end
M.paint(); assert(reaper.GetMouseModifier('MM_CTX_MIDI_PIANOROLL',0)=='22 m')
M.paint(); assert(reaper.GetMouseModifier('MM_CTX_MIDI_PIANOROLL',0)=='1 m')
out:write('PASS: paint toggle\n')
for _,b in ipairs(M.bindings) do out:write(b[4]..' = '..reaper.GetMouseModifier(b[1],b[2])..'\n') end
out:write('INSTALLED AND ENABLED\nResource: '..reaper.GetResourcePath()..'\n')
out:close()
