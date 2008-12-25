-- CONSTANTS ----------------------------------------------------------------
local SINGLETON_CLASSIFICATIONS = {
	"player",
	"pet",
	"pettarget",
	"target",
	"targettarget",
	"targettargettarget",
	"focus",
	"focustarget",
	"focustargettarget",
}
-----------------------------------------------------------------------------

local _G = _G
local PitBull4 = _G.PitBull4
local PitBull4_Utils = PitBull4.Utils

PitBull4.SINGLETON_CLASSIFICATIONS = SINGLETON_CLASSIFICATIONS

local db

if not _G.ClickCastFrames then
	-- for click-to-cast addons
	_G.ClickCastFrames = {}
end

local do_nothing = function() end

local modules = {}

local module_script_hooks = {}

local moduleMeta = { __index={} }
PitBull4.moduleMeta = moduleMeta
local moduleTypes = {}
local moduleTypes_layoutDefaults = {}

--- Add a new module type.
-- @param name name of the module type
-- @param defaults a dictionary of default values that all modules will have that inherit from this module type
-- @usage MyModule:NewModuleType("mytype", { size = 50, verbosity = "lots" })
function PitBull4:NewModuleType(name, defaults)
	moduleTypes[name] = { __index=setmetatable({ moduleType=name }, moduleMeta) }
	moduleTypes_layoutDefaults[name] = defaults
	
	return moduleTypes[name].__index
end

PitBull4:NewModuleType("custom", {})

--- Add a script hook for the unit frames.
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
	module_script_hooks[script][self] = func
end

--- Iterate through all script hooks for a given script
-- @param script name of the script
-- @usage for module, func in PitBull4.IterateFrameScriptHooks("OnEnter") do
--     -- do stuff here
-- end
-- @return iterator that returns module and function
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

	for module, func in PitBull4.IterateFrameScriptHooks(script) do
		func(frame, ...)
	end
end

local function merge(alpha, bravo)
	local x = {}
	for k, v in pairs(alpha) do
		x[k] = v
	end
	for k, v in pairs(bravo) do
		x[k] = v
	end
	return x
end

--- Create a new module
-- @param id an identifier for your module, likely its English name
-- @param name the name of your module, localized
-- @param description the description of your module, localized
-- @param globalDefaults a defaults table for global settings
-- @param layoutDefaults a defaults table for layout-specific settings
-- @param moduleType one of "statusbar", "icon", "custom"
-- @usage local PitBull4_Monkey = PitBull4.NewModule("Monkey", L["Monkey"], L["Does monkey-related things"], {
--     bananas = 5
-- }, {
--     color = { 1, 0.82, 0 }
-- })
-- @return a table which represents your new module
function PitBull4.NewModule(id, name, description, globalDefaults, layoutDefaults, moduleType)
	--@alpha@
	expect(id, 'typeof', 'string')
	expect(id, 'match', '^[A-Za-z]+$')
	expect(name, 'typeof', 'string')
	expect(description, 'typeof', 'string')
	expect(globalDefaults, 'typeof', 'table')
	expect(layoutDefaults, 'typeof', 'table')
	expect(moduleType, 'typeof', 'string')
	expect(moduleType, 'inset', moduleTypes)
	--@end-alpha@
	
	local module = setmetatable({ id = id, name = name, description = description }, moduleTypes[moduleType])
	modules[id] = module
	PitBull4[id] = module
	_G["PitBull4_" .. id] = module
	
	local betterLayoutDefaults = merge(moduleTypes_layoutDefaults[moduleType], layoutDefaults)
	PitBull4.AddModuleDefaults(id, globalDefaults, betterLayoutDefaults)
	
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
	frame = next(set, frame)
	if frame == nil then
		return
	end
	if frame:IsShown() then
		return frame
	end
	return iterate_shown_frames(set, frame)
end

-- iterate through and return only the keys of a table
local function half_next(set, key)
	key = next(set, key)
	if key == nil then
		return nil
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
	--@alpha@
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and iterate_shown_frames or half_next, all_frames
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
	--@alpha@
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and iterate_shown_frames or half_next, wacky_frames
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
	--@alpha@
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and iterate_shown_frames or half_next, non_wacky_frames
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
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	local id = PitBull4.Utils.GetBestUnitID(unitID)
	if not id then
		error(("Bad argument #1 to `IterateFramesForUnitID'. %q is not a valid unitID"):format(tostring(unitID)), 2)
	end
	
	return onlyShown and iterate_shown_frames or half_next, unitID_to_frames[id]
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
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@

	local unitID_to_frames__classification = rawget(unitID_to_frames, classification)
	if not unitID_to_frames__classification then
		return donothing
	end
	
	return onlyShown and iterate_shown_frames or half_next, unitID_to_frames__classification
end

local function layout_iter(layout, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	if frame.layout == layout then
		return frame
	end
	return layout_iter(layout, frame)
end

local function layout_shown_iter(layout, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	if frame.layout == layout and frame:IsShown() then
		return frame
	end
	return layout_iter(layout, frame)
end

--- Iterate over all frames with the given layout
-- @param layout the layout to check
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4.IterateFramesForLayout("Normal") do
--     frame:UpdateLayout()
-- end
-- @usage for frame in PitBull4.IterateFramesForLayout("Normal", true) do
--     frame:UpdateLayout()
-- end
-- @return iterator which returns frames
function PitBull4.IterateFramesForLayout(layout, onlyShown)
	--@alpha@
	expect(layout, 'typeof', 'string')
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and layout_shown_iter or layout_iter, layout
end

--- call :Update() on all frames with the given layout
-- @param layout the layout to check
-- @usage PitBull4.UpdateForLayout("Normal")
function PitBull4.UpdateForLayout(layout)
	for frame in PitBull4.IterateFramesForLayout(layout, true) do
		frame:Update(true, true)
	end
end

local function guid_iter(guid, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	if frame.guid == guid then
		return frame
	end
	return guid_iter(guid, frame)
end

--- Iterate over all frame with the given GUID
-- @param guid the GUID to check
-- @usage for frame in PitBull4.IterateFramesForGUID("0x0000000000071278") do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4.IterateFramesForGUID(guid)
	--@alpha@
	expect(guid, 'typeof', 'string')
	expect(guid, 'match', '^0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$')
	--@end-alpha@
	
	return guid_iter, guid, nil
end

local function enabled_iter(modules, id)
	local id, module = next(modules, id)
	if not id then
		-- we're out of modules
		return nil
	end
	if not module.IsEnabled() then
		-- skip disabled modules
		return enabled_iter(modules, id)
	end
	return id, module
end

--- Return a module given its id
-- @param id the id of the module
-- @usage local module = PitBull4.GetModule("MyModule")
-- @return the module or nil if not found
function PitBull4.GetModule(id)
	--@alpha@
	expect(id, 'typeof', 'string')
	--@end-alpha@
	
	return modules[id]
end

--- Iterate over all modules
-- @param enabledOnly whether to iterate over only enabled modules
-- @usage for id, module in PitBull4.IterateModules() do
--     doSomethingWith(module)
-- end
-- @return iterator which returns the id and module
function PitBull4.IterateModules(enabledOnly)
	--@alpha@
	expect(enabledOnly, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return enabledOnly and enabled_iter or next, modules, nil
end

local function moduleType_iter(moduleType, id)
	local id, module = next(modules, id)
	if not id then
		-- we're out of modules
		return nil
	end
	if module.moduleType ~= moduleType then
		-- wrong type, try again
		return moduleType_iter(moduleType, id)
	end
	return id, module
end

local function moduleType_enabled_iter(moduleType, id)
	local id, module = next(modules, id)
	if not id then
		-- we're out of modules
		return nil
	end
	if module.moduleType ~= moduleType then
		-- wrong type, try again
		return moduleType_enabled_iter(moduleType, id)
	end
	if not module.IsEnabled() then
		-- skip disabled modules
		return moduleType_enabled_iter(moduleType, id)
	end
	return id, module
end

--- Iterate over all modules of a given type
-- @param moduleType one of "statusbar", "icon", "custom"
-- @param enabledOnly whether to iterate over only enabled modules
-- @usage for id, module in PitBull4.IterateModulesOfType("statusbar") do
--     doSomethingWith(module)
-- end
-- @return iterator which returns the id and module
function PitBull4.IterateModulesOfType(moduleType, enabledOnly)
	--@alpha@
	expect(moduleType, 'typeof', 'string')
	expect(moduleType, 'inset', moduleTypes)
	expect(enabledOnly, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return enabledOnly and moduleType_enabled_iter or moduleType_iter, moduleType, nil
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
	
	local frame_name = "PitBull4_Frames_" .. unitID
	local frame = _G["PitBull4_Frames_" .. unitID]
	
	if not frame then
		frame = CreateFrame("Button", "PitBull4_Frames_" .. unitID, UIParent, "SecureUnitButtonTemplate")
		
		all_frames[frame] = true
		_G.ClickCastFrames[frame] = true
		
		frame.is_singleton = true
		
		-- for singletons, its classification is its unitID
		local classification = unitID
		frame.classification = classification
		frame.classificationDB = db.classifications[classification]
		classification_to_frames[classification][frame] = true
		
		local is_wacky = PitBull4.Utils.IsWackyClassification(classification)
		frame.is_wacky = is_wacky;
		(is_wacky and wacky_frames or non_wacky_frames)[frame] = true
		
		frame.unit = unitID
		unitID_to_frames[unitID][frame] = true
		
		frame:SetAttribute("unit", unitID)
	end
	
	RegisterUnitWatch(frame)
	
	PitBull4.ConvertIntoUnitFrame(frame)
	
	frame:SetPoint("CENTER",
		UIParent,
		"CENTER",
		frame.classificationDB.position_x,
		frame.classificationDB.position_y)
	
	frame:RefreshLayout()
	
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
		frame:UpdateGUID(UnitGUID(frame.unit))
	end
end)

local function create_frames()
	create_frames = nil
	
	local db_classifications = db.classifications
	for _, classification in ipairs(SINGLETON_CLASSIFICATIONS) do
		if not db_classifications[classification].hidden then
			PitBull4.MakeSingletonFrame(classification)
		end
	end
end

local function PLAYER_LOGIN(event)
	PitBull4.Utils.RemoveEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
	PLAYER_LOGIN = nil
	
	db = PitBull4.db
	
	create_frames()
end
PitBull4.Utils.AddEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
