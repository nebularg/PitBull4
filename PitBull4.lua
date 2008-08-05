local _G = _G
local PitBull4 = _G.PitBull4
local PitBull4_Utils = PitBull4.Utils

local db
local defaults = {
	classifications = {
		['*'] = {
			
		}
	},
}

local do_nothing = function() end

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
	local id = PitBull4.Utils.GetBestUnitID(unitID)
	if not id then
		error(("Bad argument #1 to `MakeSingletonFrame'. %q is not a valid unitID"):format(tostring(unitID)), 2)
	end
	if not PitBull4.Utils.IsSingletonUnitID(id) then
		error(("Bad argument #1 to `MakeSingletonFrame'. %q is not a singleton unitID"):format(tostring(unitID)), 2)
	end
	unitID = id
	
	local frame = CreateFrame("Button", "PitBull4_Frames_" .. unitID, UIParent, "SecureUnitButtonTemplate")
	
	all_frames[frame] = true
	
	frame.is_singleton = true
	
	-- for singletons, its classification is its unitID
	local classification = unitID
	frame.classification = classification
	frame.classificationDB = db.classifications[frame.classification]
	classification_to_frames[classification][frame] = true
	
	local is_wacky = PitBull4.Utils.IsWackyClassification(classification)
	frame.is_wacky = is_wacky;
	(is_wacky and wacky_frames or non_wacky_frames)[frame] = true
	
	frame.unitID = unitID
	unitID_to_frames[unitID][frame] = true
	
	PitBull4.ConvertIntoUnitFrame(frame)
	
	frame:UpdateGUID(UnitGUID(unitID))
	
	return frame
end

-- check the guid of a unit and send that info to all frames, in case of an update
local function check_frames_for_guid_update(unitID)
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

local add_defaults
do
	-- metatable cache
	local cache = {}
	
	-- make the metatable which creates a new table on access
	local function make_default_table_mt(value)
		if cache[value] then
			return cache[value]
		end
		local mt = {}
		cache[value] = mt
		function mt:__index(key)
			local t = {}
			self[key] = t
			add_defaults(t, value)
			return t
		end
		return mt
	end
	
	-- make the metatable which returns a simple value on access
	local function make_default_value_mt(value)
		if cache[value] then
			return cache[value]
		end
		local mt = {}
		cache[value] = mt
		function mt:__index(key)
			self[key] = value
			return value
		end
		return mt
	end
	
	-- add a default table structure to a database table
	local function add_default_table(database, key, value)
		if key == '*' then
			setmetatable(database, make_default_table_mt(value))
			return
		end
		
		if type(database[key]) ~= "table" then
			-- make sure that the database table structure matches
			database[key] = {}
		end
		add_defaults(database[key], value) -- handle sub-tables
	end
	
	-- add a specific value (or table structure) to a database table
	local function add_default_value(database, key, value)
		if type(value) == "table" then -- make sure the table structure is consistent
			add_default_table(database, key, value)
			return
		end
		
		if key == '*' then -- all keys
			setmetatable(database, make_default_value_mt(value))
			return
		end
		
		if database[key] == nil then -- if it's nil, then go for what the defaults say
			database[key] = value
		end
	end

	-- add default values to a database table
	function add_defaults(database, defaults)
		for k, v in pairs(defaults) do -- loop through each default value and add it to the database
			add_default_value(database, k, v)
		end
	end
end

-- set the db table and populate it with the defaults
local function handle_db()
	handle_db = nil
	
	db = _G.PitBull4DB
	if type(db) ~= "table" then
		db = { version = 0 }
		_G.PitBull4DB = db
	end
	local version = db.version
	db.version = nil
	
	add_defaults(db, defaults)
	
	PitBull4.db = db
end

local function ADDON_LOADED(event, name)
	if name ~= "PitBull4" then
		return
	end
	PitBull4.Utils.RemoveEventListener("ADDON_LOADED", ADDON_LOADED)
	ADDON_LOADED = nil
	
	handle_db()
end
PitBull4.Utils.AddEventListener("ADDON_LOADED", ADDON_LOADED)

PitBull4.Utils.AddEventListener("PLAYER_LOGOUT", function()
	local remove_defaults
	
	local function remove_default_table(database, key, value)
		remove_defaults(database[key], value)
		
		if next(database[key]) == nil then
			-- if the table's empty, nil out the table
			database[key] = nil
		end
	end
	
	local function remove_default_value(database, key, value, star_default)
		if value == nil then
			value = star_default
		end
		
		if type(database[key]) ~= type(value) then
			-- vastly different, cut out early
			return
		end
		
		if type(value) == "table" then
			-- handle the table case
			remove_default_table(database, key, value)
			return
		end
		
		if database[key] == value then
			-- simple equality, nil out
			database[key] = nil
		end
	end
	
	-- remove any unnecessary values from the database
	-- this is useful in case the defaults change (so that unchanged values are updated)
	-- it is also useful because the stored SV looks a lot smaller cause it has only
	-- the useful information
	function remove_defaults(database, defaults)
		for k, v in pairs(database) do
			-- loop through each default and remove from the database
			remove_default_value(database, k, defaults[k], defaults['*'])
		end
	end
	remove_defaults(db, defaults)
	
	db.version = 0
end)
