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

local PitBull4 = LibStub("AceAddon-3.0"):NewAddon("PitBull4", "AceEvent-3.0", "AceTimer-3.0")
_G.PitBull4 = PitBull4

PitBull4.SINGLETON_CLASSIFICATIONS = SINGLETON_CLASSIFICATIONS

local db

if not _G.ClickCastFrames then
	-- for click-to-cast addons
	_G.ClickCastFrames = {}
end

local do_nothing = function() end

do
	-- unused tables go in this set
	-- if the garbage collector comes around, they'll be collected properly
	local cache = setmetatable({}, {__mode='k'})
	
	--- Return a table
	-- @usage local t = PitBull4.new()
	-- @return a blank table
	function PitBull4.new()
		local t = next(cache)
		if t then
			cache[t] = nil
			return t
		end
		
		return {}
	end
	
	local wipe = _G.wipe
	
	--- Delete a table, clearing it and putting it back into the queue
	-- @usage local t = PitBull4.new()
	-- t = del(t)
	-- @return nil
	function PitBull4.del(t)
		wipe(t)
		cache[t] = true
		return nil
	end
end

local new, del = PitBull4.new, PitBull4.del

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
	moduleTypes[name] = {}
	moduleTypes_layoutDefaults[name] = defaults
	
	return moduleTypes[name]
end

PitBull4:NewModuleType("custom", {})

local Module = {}
PitBull4:SetDefaultModulePrototype(Module)

--- Add a script hook for the unit frames.
-- outside of the standard script hooks, there is also OnPopulate and OnClear.
-- @name Module:AddFrameScriptHook
-- @param script name of the script
-- @param func function to call or method on the module to call
-- @usage MyModule:AddFrameScriptHook("OnEnter", function(frame)
--     -- do stuff here
-- end)
function Module:AddFrameScriptHook(script, method)
	--@alpha@
	expect(script, 'typeof', 'string')
	expect(script, 'match', '^On[A-Z][A-Za-z]+$')
	expect(method, 'typeof', 'function;string;nil')
	--@end-alpha@
	
	if not method then
		method = script
	end
	
	if not module_script_hooks[script] then
		module_script_hooks[script] = {}
	end
	module_script_hooks[script][self] = PitBull4.Utils.ConvertMethodToFunction(self, method)
end

--- Iterate through all script hooks for a given script
-- @param script name of the script
-- @usage for module, func in PitBull4:IterateFrameScriptHooks("OnEnter") do
--     -- do stuff here
-- end
-- @return iterator that returns module and function
function PitBull4:IterateFrameScriptHooks(script)
	--@alpha@
	expect(script, 'typeof', 'string')
	expect(script, 'match', '^On[A-Z][A-Za-z]+$')
	--@end-alpha@
	
	if not module_script_hooks[script] then
		return do_nothing
	end
	return next, module_script_hooks[script]
end

--- Run all script hooks for a given script
-- @param script name of the script
-- @param frame current Unit Frame
-- @param ... any arguments to pass in
-- @usage PitBull4:RunFrameScriptHooks(script, ...)
function PitBull4:RunFrameScriptHooks(script, frame, ...)
	--@alpha@
	expect(script, 'typeof', 'string')
	expect(frame, 'typeof', 'frame')
	--@end-alpha@

	for module, func in PitBull4:IterateFrameScriptHooks(script) do
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

function PitBull4:OnModuleCreated(module)
	module.id = module.moduleName
	self[module.moduleName] = module
end

--- Set the localized name of the module.
-- @param name the localized name of the module, with proper spacing, and in Title Case.
-- @usage MyModule:SetName("My Module")
function Module:SetName(name)
	--@alpha@
	expect(name, 'typeof', 'string')
	--@end-alpha@
	
	self.name = name
end

--- Set the localized description of the module.
-- @param description the localized description of the module, as a full sentence, including a period at the end.
-- @usage MyModule:SetDescription("This does a lot of things.")
function Module:SetDescription(description)
	--@alpha@
	expect(description, 'typeof', 'string')
	--@end-alpha@
	
	self.description = description
end

--- Set the module type of the module.
-- This should be called right after creating the module.
-- @param type one of "custom", "statusbar", or "icon"
-- @usage MyModule:SetModuleType("statusbar")
function Module:SetModuleType(type)
	--@alpha@
	expect(type, 'typeof', 'string')
	expect(type, 'inset', moduleTypes)
	--@end-alpha@
	
	self.moduleType = type
	
	for k, v in pairs(moduleTypes[type]) do
		self[k] = v
	end
end

local module_layoutDefaults = {}
local module_globalDefaults = {}

local function FixDBForModule(module, layoutDefaults, globalDefaults)
	module.db = db:RegisterNamespace(module.id, {
		profile = {
			layouts = {
				['*'] = layoutDefaults,
			},
			global = globalDefaults
		}
	})
end

--- Set the module's database defaults.
-- This will cause module.db to be set.
-- @param layoutDefaults defaults on a per-layout basis. can be nil.
-- @param globalDefaults defaults on a per-profile basis. can be nil.
-- @usage MyModule:SetDefaults({ color = { 1, 0, 0, 1 } })
-- @usage MyModule:SetDefaults({ color = { 1, 0, 0, 1 } }, {})
function Module:SetDefaults(layoutDefaults, globalDefaults)
	--@alpha@
	expect(layoutDefaults, 'typeof', 'table;nil')
	expect(globalDefaults, 'typeof', 'table;nil')
	expect(self.moduleType, 'typeof', 'string')
	--@end-alpha@
	
	local better_defaults = merge(moduleTypes_layoutDefaults[self.moduleType], layoutDefaults or {})
	
	if not db then
		-- full addon not loaded yet
		module_layoutDefaults[self] = better_defaults
		module_globalDefaults[self] = globalDefaults
	else
		FixDBForModule(self, better_defaults, globalDefaults)
	end
end

--- Get the database table for the given layout relating to the current module.
-- @param layout either the frame currently being worked on or the name of the layout.
-- @usage local color = MyModule:GetLayoutDB(frame).color
-- @return the database table
function Module:GetLayoutDB(layout)
	--@alpha@
	expect(layout, 'typeof', 'string;table;frame')
	if type(layout) == "table" then
		expect(layout.layout, 'typeof', 'string')
	end
	--@end-alpha@
	
	if type(layout) == "table" then
		-- we're dealing with a unit frame that has the layout key on it.
		layout = layout.layout
	end
	
	return self.db.profile.layouts[layout]
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

-- iterate through and return only the keys of a table. Once exhausted, recycle the table.
local function half_next_with_del(set, key)
	key = next(set, key)
	if key == nil then
		del(set)
		return nil
	end
	return key
end

--- Iterate over all frames
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4:IterateFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFrames(onlyShown)
	--@alpha@
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and iterate_shown_frames or half_next, all_frames
end

--- Iterate over all wacky frames
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4:IterateWackyFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateWackyFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateWackyFrames(onlyShown)
	--@alpha@
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and iterate_shown_frames or half_next, wacky_frames
end

--- Iterate over all non-wacky frames
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4:IterateNonWackyFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateNonWackyFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateNonWackyFrames(onlyShown)
	--@alpha@
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and iterate_shown_frames or half_next, non_wacky_frames
end

--- Iterate over all frames with the given unit ID
-- @param unitID the UnitID of the unit in question
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4:IterateFramesForUnitID("player") do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateFramesForUnitID("party1", true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForUnitID(unitID, onlyShown)
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

--- Iterate over all shown frames with the given unit IDs
-- @paramr ... a tuple of unitIDs.
-- @usage for frame in PitBull4:IterateFramesForUnitIDs("player", "target", "pet") do
--     somethingAwesome(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForUnitIDs(...)
	local t = new()
	for i = 1, select('#', ...) do
		local unitID = (select(i, ...))
		local frames = unitID_to_frames[unitID]
		
		for frame in pairs(frames) do
			if frame:IsShown() then
				t[frame] = true
			end
		end
	end
	
	return half_next_with_del, t
end

--- Iterate over all frames with the given classification
-- @param classification the classification to check
-- @param onlyShown only return frames that are shown
-- @usage for frame in PitBull4:IterateFramesForClassification("player") do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateFramesForClassification("party", true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForClassification(classification, onlyShown)
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
-- @usage for frame in PitBull4:IterateFramesForLayout("Normal") do
--     frame:UpdateLayout()
-- end
-- @usage for frame in PitBull4:IterateFramesForLayout("Normal", true) do
--     frame:UpdateLayout()
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForLayout(layout, onlyShown)
	--@alpha@
	expect(layout, 'typeof', 'string')
	expect(onlyShown, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return onlyShown and layout_shown_iter or layout_iter, layout
end

--- call :Update() on all frames with the given layout
-- @param layout the layout to check
-- @usage PitBull4:UpdateForLayout("Normal")
function PitBull4:UpdateForLayout(layout)
	for frame in PitBull4:IterateFramesForLayout(layout, true) do
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
-- @usage for frame in PitBull4:IterateFramesForGUID("0x0000000000071278") do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForGUID(guid)
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
	if not module:IsEnabled() then
		-- skip disabled modules
		return enabled_iter(modules, id)
	end
	return id, module
end

--- Iterate over all enabled modules
-- @usage for id, module in PitBull4:IterateEnabledModules() do
--     doSomethingWith(module)
-- end
-- @return iterator which returns the id and module
function PitBull4:IterateEnabledModules()
	return enabled_iter, self.modules, nil
end

local function moduleType_iter(moduleType, id)
	local id, module = next(PitBull4.modules, id)
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
	local id, module = next(PitBull4.modules, id)
	if not id then
		-- we're out of modules
		return nil
	end
	if module.moduleType ~= moduleType then
		-- wrong type, try again
		return moduleType_enabled_iter(moduleType, id)
	end
	if not module:IsEnabled() then
		-- skip disabled modules
		return moduleType_enabled_iter(moduleType, id)
	end
	return id, module
end

--- Iterate over all modules of a given type
-- @param moduleType one of "statusbar", "icon", "custom"
-- @param enabledOnly whether to iterate over only enabled modules
-- @usage for id, module in PitBull4:IterateModulesOfType("statusbar") do
--     doSomethingWith(module)
-- end
-- @return iterator which returns the id and module
function PitBull4:IterateModulesOfType(moduleType, enabledOnly)
	--@alpha@
	expect(moduleType, 'typeof', 'string')
	expect(moduleType, 'inset', moduleTypes)
	expect(enabledOnly, 'typeof', 'boolean;nil')
	--@end-alpha@
	
	return enabledOnly and moduleType_enabled_iter or moduleType_iter, moduleType, nil
end

--- Make a singleton unit frame.
-- @param unitID the UnitID of the frame in question
-- @usage local frame = PitBull4:MakeSingletonFrame("player")
-- @return the frame in question
function PitBull4:MakeSingletonFrame(unitID)
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
		frame.classificationDB = db.profile.classifications[classification]
		classification_to_frames[classification][frame] = true
		
		local is_wacky = PitBull4.Utils.IsWackyClassification(classification)
		frame.is_wacky = is_wacky;
		(is_wacky and wacky_frames or non_wacky_frames)[frame] = true
		
		frame.unit = unitID
		unitID_to_frames[unitID][frame] = true
		
		frame:SetAttribute("unit", unitID)
	end
	
	RegisterUnitWatch(frame)
	
	PitBull4:ConvertIntoUnitFrame(frame)
	
	frame:SetPoint("CENTER",
		UIParent,
		"CENTER",
		frame.classificationDB.position_x,
		frame.classificationDB.position_y)
	
	frame:RefreshLayout()
	
	frame:UpdateGUID(UnitGUID(unitID))
	
	return frame
end

function PitBull4:OnEnable()
	self:ScheduleRepeatingTimer("CheckWackyFramesForGUIDUpdate", 0.15)
	
	-- register unit change events
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_PET_CHANGED")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UNIT_PET")
	
	-- enter/leave combat for :RunOnLeaveCombat
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	
	db = LibStub("AceDB-3.0"):New("PitBull4DB", {
		profile = {
			classifications = {
				['**'] = {
					hidden = false,
					position_x = 0,
					position_y = 0,
					layout = "Normal",
					horizontalMirror = false,
					verticalMirror = false,
				},
			},
			layouts = {
				['**'] = {
					size_x = 300,
					size_y = 100,
				},
				Normal = {}
			},
		}
	}, 'global')
	self.db = db
	
	for module, layoutDefaults in pairs(module_layoutDefaults) do
		FixDBForModule(module, layoutDefaults, module_globalDefaults[module])
	end
	-- no longer need these
	module_layoutDefaults = nil
	module_globalDefaults = nil
	
	-- show initial frames
	local db_classifications = db.profile.classifications
	for _, classification in ipairs(SINGLETON_CLASSIFICATIONS) do
		if not db_classifications[classification].hidden then
			PitBull4:MakeSingletonFrame(classification)
		end
	end
end

--- Iterate over all wacky frames, and call their respective :UpdateGUID methods.
-- @usage PitBull4:CheckWackyFramesForGUIDUpdate()
function PitBull4:CheckWackyFramesForGUIDUpdate()
	for frame in self:IterateWackyFrames() do
		frame:UpdateGUID(UnitGUID(frame.unit))
	end
end

--- Check the GUID of the given unitID and send that info to all frames for that unit ID
-- @param unitID the unitID to check
-- @usage PitBull4:CheckGUIDForUnitID("player")
function PitBull4:CheckGUIDForUnitID(unitID)
	if not PitBull4.Utils.GetBestUnitID(unitID) then
		-- for ids such as npctarget
		return
	end
	local guid = UnitGUID(unitID)
	for frame in self:IterateFramesForUnitID(unitID) do
		frame:UpdateGUID(guid)
	end
end

function PitBull4:PLAYER_TARGET_CHANGED() self:CheckGUIDForUnitID("target") end
function PitBull4:PLAYER_FOCUS_CHANGED() self:CheckGUIDForUnitID("focus") end
function PitBull4:UPDATE_MOUSEOVER_UNIT() self:CheckGUIDForUnitID("mouseover") end
function PitBull4:PLAYER_PET_CHANGED() self:CheckGUIDForUnitID("pet") end
function PitBull4:UNIT_TARGET(_, unitID) self:CheckGUIDForUnitID(unitID .. "target") end
function PitBull4:UNIT_PET(_, unitID) self:CheckGUIDForUnitID(unitID .. "pet") end

do
	local inCombat = false
	local actionsToPerform = {}
	local pool = {}
	function PitBull4:PLAYER_REGEN_ENABLED()
		inCombat = false
		for i, t in ipairs(actionsToPerform) do
			t[1](unpack(t, 2, t.n+1))
			for k in pairs(t) do
				t[k] = nil
			end
			actionsToPerform[i] = nil
			pool[t] = true
		end
	end
	function PitBull4:PLAYER_REGEN_DISABLED()
		inCombat = true
	end
	--- Call a function if out of combat or schedule to run once combat ends
	-- You can also pass in a table (or frame), method, and arguments
	-- @param func function to call
	-- @param ... arguments to pass into func
	-- @usage PitBull4:RunOnLeaveCombat(someSecureFunction)
	-- @usage PitBull4:RunOnLeaveCombat(someSecureFunction, "player")
	-- @usage PitBull4:RunOnLeaveCombat(frame.SetAttribute, frame, "key", "value")
	-- @usage PitBull4:RunOnLeaveCombat(frame, 'SetAttribute', "key", "value")
	function PitBull4:RunOnLeaveCombat(func, ...)
		if type(func) == "table" then
			return self:RunOnLeaveCombat(func[(...)], func, select(2, ...))
		end
		if not inCombat then
			func(...)
			return
		end
		local t = next(pool) or {}
		pool[t] = nil
		
		t[1] = func
		local n = select('#', ...)
		t.n = n
		for i = 1, n do
			t[i+1] = select(i, ...)
		end
	end
end

