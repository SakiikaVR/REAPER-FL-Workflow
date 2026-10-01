local _,file=reaper.get_action_context()
local M=dofile(file:match('^(.*[/\\])')..'core.lua')
M.enable()
if not reaper.MIDIEditor_GetActive() then M.enableLengthMemoryWhenReady() end
