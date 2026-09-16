local _,file=reaper.get_action_context()
local M=dofile(file:match('^(.*[/\\])')..'core.lua')
M.paint()
