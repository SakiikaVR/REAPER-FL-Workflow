-- FL-like mouse workflow for REAPER 7.x. No extension dependencies.
local M = {}
M.namespace='FLPianoRoll_v1'
M.bindings={
 {'MM_CTX_MIDI_PIANOROLL_CLK',0,'4 m','Left click: insert note'},
 {'MM_CTX_MIDI_PIANOROLL_CLK',2,'0','Ctrl click: no insertion'},
 {'MM_CTX_MIDI_PIANOROLL_CLK',3,'0','Ctrl+Shift click: no insertion'},
 {'MM_CTX_MIDI_PIANOROLL',0,'1 m','Left drag: insert and extend'},
 {'MM_CTX_MIDI_PIANOROLL',2,'7 m','Ctrl drag: marquee selection'},
 {'MM_CTX_MIDI_NOTE_CLK',0,'1 m','Left click note: select'},
 {'MM_CTX_MIDI_NOTE',0,'1 m','Left drag note: move'},
 {'MM_CTX_MIDI_NOTE',1,'7 m','Shift drag note: copy'},
 {'MM_CTX_MIDI_NOTEEDGE',0,'1 m','Left drag edge: resize'},
 {'MM_CTX_MIDI_RMOUSE',0,'10 m','Right click/drag: immediate delete notes/CC'},
 {'MM_CTX_MIDI_RMOUSE',2,'1 m','Ctrl right drag: marquee notes/CC'}
}
local function key(b) return b[1]..':'..b[2] end
local LENGTH_MEMORY_COMMAND=40479 -- Drawing or selecting a note sets the new note length
function M.enableLengthMemory()
 local editor=reaper.MIDIEditor_GetActive()
 if not editor then return false end
 local state=reaper.GetToggleCommandStateEx(32060,LENGTH_MEMORY_COMMAND)
 if state<0 then return false end
 if reaper.GetExtState(M.namespace,'length_memory_saved')~='1' then
  reaper.SetExtState(M.namespace,'length_memory_original',tostring(state),true)
  reaper.SetExtState(M.namespace,'length_memory_saved','1',true)
 end
 if state~=1 then reaper.MIDIEditor_OnCommand(editor,LENGTH_MEMORY_COMMAND) end
 return reaper.GetToggleCommandStateEx(32060,LENGTH_MEMORY_COMMAND)==1
end
function M.restoreLengthMemory()
 local editor=reaper.MIDIEditor_GetActive()
 if not editor or reaper.GetExtState(M.namespace,'length_memory_saved')~='1' then return end
 local original=tonumber(reaper.GetExtState(M.namespace,'length_memory_original'))
 local current=reaper.GetToggleCommandStateEx(32060,LENGTH_MEMORY_COMMAND)
 if original and current>=0 and current~=original then reaper.MIDIEditor_OnCommand(editor,LENGTH_MEMORY_COMMAND) end
end
function M.enable()
 if reaper.GetExtState(M.namespace,'saved')~='1' then
  for _,b in ipairs(M.bindings) do reaper.SetExtState(M.namespace,key(b),reaper.GetMouseModifier(b[1],b[2]),true) end
  reaper.SetExtState(M.namespace,'saved','1',true)
 end
 for _,b in ipairs(M.bindings) do
  reaper.SetMouseModifier(b[1],b[2],b[3])
  assert(reaper.GetMouseModifier(b[1],b[2])==b[3],'Binding failed: '..b[4])
 end
 reaper.SetExtState(M.namespace,'enabled','1',true)
 M.enableLengthMemory()
end
function M.restore()
 if reaper.GetExtState(M.namespace,'saved')~='1' then return end
 for _,b in ipairs(M.bindings) do
  local old=reaper.GetExtState(M.namespace,key(b))
  reaper.SetMouseModifier(b[1],b[2],old)
  assert(reaper.GetMouseModifier(b[1],b[2])==old,'Restore failed: '..b[4])
 end
 reaper.SetExtState(M.namespace,'enabled','0',true)
 M.restoreLengthMemory()
 -- Retain the original backup for repeatable restoration.
end
function M.paint()
 if reaper.GetExtState(M.namespace,'enabled')~='1' then M.enable() end
 local ctx='MM_CTX_MIDI_PIANOROLL'
 local nextvalue=reaper.GetMouseModifier(ctx,0)=='22 m' and '1 m' or '22 m'
 reaper.SetMouseModifier(ctx,0,nextvalue)
end
return M
