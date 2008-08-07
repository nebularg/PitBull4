local _G = _G
local PitBull4 = _G.PitBull4
local PitBull4_Utils = PitBull4.Utils

local db

if not _G.ClickCastFrames then
	-- for click-to-cast addons
	_G.ClickCastFrames = {}
end

local do_nothing = function() end

local modules = {}

local module_script_hooks = {}

local moduleMeta = {}
moduleMeta.__index = {}

--- Add a script hook for the unit frames
-- outside of the standard script hooks, there is also OnPopulate and OnClear.
-- @name Module:AddFrameScriptHook
-- @param script name of the script
-- @param func function to call
-- @usage MyModule:AddFrameScriptHook("OnEnter", function(frame)
--     -- do stuff here
-- end)
function moduleMeta.__index:AddFrameScriptHook(script, func)
	--@alpha@
	expect(script, 'typeof', 'string')
	expect(script, 'match', '^On[A-Z][A-Za-z]+$')
	expect(func, 'typeof', 'function')
	--@end-alpha@
	
	if not module_script_hooks[script] then
		module_script_hooks[script] = {}
	end
	module_script_hooks[script][func] = self
end

--- Iterate through all script hooks for a given script
-- @param script name of the script
-- @usage for func, module in PitBull4.IterateFrameScriptHooks("OnEnter") do
--     -- do stuff here
-- end
-- @return iterator that returns function and module
function PitBull4.IterateFrameScriptHooks(script)
	--@alpha@
	expect(script, 'typeof', 'string')
	expect(script, 'match', '^On[A-Z][A-Za-z]+$')
	--@end-alpha@
	
	if not module_script_hooks[script] then
		return do_nothing
	end
	return next, module_script_hooks[script]
end

--- Run all scriprt hooks for a given script
-- @param script name of the script
-- @param frame current Unit Frame
-- @param ... any arguments to pass in
-- @usage PitBull4.RunFrameScriptHooks(script, ...)
function PitBull4.RunFrameScriptHooks(script, frame, ...)
	--@alpha@
	expect(script, 'typeof', 'string')
	expect(frame, 'typeof', 'frame')
	--@end-alpha@

	for func, module in PitBull4.IterateFrameScriptHooks(script) do
		func(frame, ...)
	end
end

--- Create a new module
-- @param id an identifier for your module, likely its English name
-- @param name the name of your module, localized
-- @param description the description of your module, localized
-- @param globalDefaults a defaults table for global settings
-- @param layoutDefaults a defaults table for layout-specific settings
-- @usage local PitBull4_Monkey = PitBull4.NewModule("Monkey", L["Monkey"], L["Does monkey-related things"], {
--     bananas = 5
-- }, {
--     color = { 1, 0.82, 0 }
-- })
-- @return a table which represents your new module
function PitBull4.NewModule(id, name, description, globalDefaults, layoutDefaults)
	--@alpha@
	expect(id, 'typeof', 'string')
	expect(id, 'match', '^[A-Za-z]+$')
	expect(name, 'typeof', 'string')
	expect(description, 'typeof', 'string')
	expect(globalDefaults, 'typeof', 'table')
	expect(layoutDefaults, 'typeof', 'table')
	--@end-alpha@
	
	local module = setmetatable({ id = id, name = name, description = description }, moduleMeta)
	modules[id] = module
	PitBull4[id] = module
	_G["PitBull4_" .. id] = module
	
	PitBull4.AddModuleDefaults(id, globalDefaults, layoutDefaults)
	
	function module.IsEnabled()
		return not db[id].disabled
	end
	
	return module
end

-- A set of all unit frames
local all_frames = {}

-- A set of all unit frames with the is_wacky flag set to true
local wacky_frames = {}

-- A set of all unit frames with the is_wacky flag set to false
local non_wacky_frames = {}

-- metatabel that automatically creates keys that return tables on access
local autoTable__mt = {__index = function(self, key)
	local value = {}
	self[key] = value
	return value
end}

-- A dictionary of unitID to a set of all unit frames of that unitID
local unitID_to_frames = setmetatable({}, autoTable__mt)

-- A dictionary of classification to a set of all unit frames of that classification
local classification_to_frames = setmetatable({}, autoTable__mt)

-- iterate through a set of frames and return those that are shown
local function iterate_shown_frames(set, frame)
	frame = next(set, key)
	if frame == nil then
		return
	end
	if frame:IsShown() then
		return frame
	end
	return iterate_shown_frames(set, frame)
end

-- iterate through and return only the keys of a table
local function half_pairs(set, key)
	key = next(set, key)
	if key == nil then
		return
	end
	return key
end

--- Iterate over all frames
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4.IterateFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4.IterateFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4.IterateFrames(onlyShown)
	return onlyShown and iterate_shown_frames or half_pairs, all_frames
end

--- Iterate over all wacky frames
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4.IterateWackyFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4.IterateWackyFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4.IterateWackyFrames(onlyShown)
	return onlyShown and iterate_shown_frames or half_pairs, wacky_frames
end

--- Iterate over all non-wacky frames
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4.IterateNonWackyFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4.IterateNonWackyFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4.IterateNonWackyFrames(onlyShown)
	return onlyShown and iterate_shown_frames or half_pairs, non_wacky_frames
end

--- Iterate over all frames with the given unit id
-- @param unitID the UnitID of the unit in question
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4.IterateFramesForUnitID("player") do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4.IterateFramesForUnitID("party1", true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4.IterateFramesForUnitID(unitID, onlyShown)
	--@alpha@
	expect(unitID, 'typeof', 'string')
	--@end-alpha@
	
	local id = PitBull4.Utils.GetBestUnitID(unitID)
	if not id then
		error(("Bad argument #1 to `IterateFramesForUnitID'. %q is not a valid unitID"):format(tostring(unitID)), 2)
	end
	
	return onlyShown and iterate_shown_frames or half_pairs, unitID_to_frames[id]
end

--- Iterate over all frames with the given classification
-- @param classification the classification to check
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4.IterateFramesForClassification("player") do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4.IterateFramesForClassification("party", true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4.IterateFramesForClassification(classification, onlyShown)
	--@alpha@
	expect(classification, 'typeof', 'string')
	--@end-alpha@

	local unitID_to_frames__classification = rawget(unitID_to_frames, classification)
	if not unitID_to_frames__classification then
		return donothing
	end
	
	return onlyShown and iterate_shown_frames or half_pairs, unitID_to_frames__classification
end

--- Make a singleton unit frame.
-- @param unitID the UnitID of the frame in question
-- @usage local frame = PitBull4.MakeSingletonFrame("player")
-- @return the frame in question
function PitBull4.MakeSingletonFrame(unitID)
	--@alpha@
	expect(unitID, 'typeof', 'string')
	--@end-alpha@
	
	local id = PitBull4.Utils.GetBestUnitID(unitID)
	if not PitBull4.Utils.IsSingletonUnitID(id) then
		error(("Bad argument #1 to `MakeSingletonFrame'. %q is not a singleton unitID"):format(tostring(unitID)), 2)
	end
	unitID = id
	
	local frame = CreateFrame("Button", "PitBull4_Frames_" .. unitID, UIParent, "SecureUnitButtonTemplate")
	
	all_frames[frame] = true
	_G.ClickCastFrames[frame] = true
	
	frame.is_singleton = true
	
	-- for singletons, its classification is its unitID
	local classification = unitID
	frame.classification = classification
	frame.classificationDB = db.classifications[classification]
	classification_to_frames[classification][frame] = true
	
	local layout = frame.classificationDB.layout
	frame.layout = layout
	frame.layoutDB = db.layouts[layout]
	
	local is_wacky = PitBull4.Utils.IsWackyClassification(classification)
	frame.is_wacky = is_wacky;
	(is_wacky and wacky_frames or non_wacky_frames)[frame] = true
	
	frame.unitID = unitID
	unitID_to_frames[unitID][frame] = true
	
	frame:SetAttribute("unit", unitID)
	RegisterUnitWatch(frame)
	
	PitBull4.ConvertIntoUnitFrame(frame)
	
	frame:SetWidth(frame.layoutDB.size_x)
	frame:SetHeight(frame.layoutDB.size_y)
	frame:SetPoint("CENTER",
		UIParent,
		"CENTER", 
		frame.classificationDB.position_x,
		frame.classificationDB.position_y)
	
	frame:UpdateGUID(UnitGUID(unitID))
	
	return frame
end

-- check the guid of a unit and send that info to all frames, in case of an update
local function check_frames_for_guid_update(unitID)
	if not PitBull4.Utils.GetBestUnitID(unitID) then
		-- for ids such as npctarget
		return
	end
	local guid = UnitGUID(unitID)
	for frame in PitBull4.IterateFramesForUnitID(unitID) do
		frame:UpdateGUID(guid)
	end
end

for event, func in pairs({
	PLAYER_TARGET_CHANGED = function() check_frames_for_guid_update("target") end,
	PLAYER_FOCUS_CHANGED = function() check_frames_for_guid_update("focus") end,
	UPDATE_MOUSEOVER_UNIT = function() check_frames_for_guid_update("mouseover") end,
	PLAYER_PET_CHANGED = function() check_frames_for_guid_update("pet") end,
	UNIT_TARGET = function(_, unitID) check_frames_for_guid_update(unitID .. "target") end,
	UNIT_PET = function(_, unitID) check_frames_for_guid_update(unitID .. "pet") end,
}) do
	PitBull4.Utils.AddEventListener(event, func)
end

-- update all wacky frames every 0.15 seconds
local nextTime = 0
PitBull4.Utils.AddTimer(function(elapsed, currentTime)
	if nextTime > currentTime then
		return
	end
	nextTime = currentTime + 0.15
	
	for frame in PitBull4.IterateWackyFrames() do
		frame:UpdateGUID(UnitGUID(frame.unitID))
	end
end)

local function create_frames()
	create_frames = nil
	
	local db_classifications = db.classifications
	if not db_classifications.player.hidden then
		PitBull4.MakeSingletonFrame("player")
	end
	if not db_classifications.target.hidden then
		PitBull4.MakeSingletonFrame("target")
	end
end

local function PLAYER_LOGIN(event)
	PitBull4.Utils.RemoveEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
	PLAYER_LOGIN = nil
	
	db = PitBull4.db
	
	create_frames()
end
PitBull4.Utils.AddEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
