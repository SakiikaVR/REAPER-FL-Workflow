-- Duplicate piano-roll notes like FL Studio's Ctrl+B.
local editor = reaper.MIDIEditor_GetActive()
if not editor then return end
local take = reaper.MIDIEditor_GetTake(editor)
if not take or not reaper.TakeIsMIDI(take) then return end

local _, note_count = reaper.MIDI_CountEvts(take)
local notes, selected_count = {}, 0
for i = 0, note_count - 1 do
  local ok, selected, muted, start_pos, end_pos, channel, pitch, velocity = reaper.MIDI_GetNote(take, i)
  if ok then
    notes[#notes + 1] = {
      index = i, selected = selected, muted = muted, start_pos = start_pos,
      end_pos = end_pos, channel = channel, pitch = pitch, velocity = velocity
    }
    if selected then selected_count = selected_count + 1 end
  end
end
if #notes == 0 then return end

local first, last = math.huge, -math.huge
local copied = {}
for _, note in ipairs(notes) do
  if selected_count == 0 or note.selected then
    copied[#copied + 1] = note
    first = math.min(first, note.start_pos)
    last = math.max(last, note.end_pos)
  end
end

local interval = last - first
local time_start, time_end = reaper.GetSet_LoopTimeRange2(0, false, false, 0, 0, false)
if time_end > time_start then
  interval = reaper.MIDI_GetPPQPosFromProjTime(take, time_end)
           - reaper.MIDI_GetPPQPosFromProjTime(take, time_start)
end
if interval <= 0 then return end

local item = reaper.GetMediaItemTake_Item(take)
local item_end = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
               + reaper.GetMediaItemInfo_Value(item, 'D_LENGTH')
local required_end = reaper.MIDI_GetProjTimeFromPPQPos(take, last + interval)
reaper.Undo_BeginBlock2(0)
reaper.MIDI_DisableSort(take)
for _, note in ipairs(copied) do
  reaper.MIDI_SetNote(take, note.index, false, nil, nil, nil, nil, nil, nil, true)
  reaper.MIDI_InsertNote(take, true, note.muted,
    note.start_pos + interval, note.end_pos + interval,
    note.channel, note.pitch, note.velocity, true)
end
reaper.MIDI_Sort(take)
if required_end > item_end + 0.000001 then
  local item_start = reaper.GetMediaItemInfo_Value(item, 'D_POSITION')
  reaper.MIDI_SetItemExtents(item,
    reaper.TimeMap2_timeToQN(0, item_start),
    reaper.TimeMap2_timeToQN(0, required_end))
end
reaper.MIDI_RefreshEditors(take)
reaper.Undo_EndBlock2(0, 'FL Piano Roll: duplicate notes to right', -1)
