local _G = _G
local PitBull4 = _G.PitBull4

local L = PitBull4.L

local LibBossIDs = LibStub("LibBossIDs-1.0", true)

local DEBUG = PitBull4.DEBUG
local expect = PitBull4.expect

PitBull4.Utils = {}

do
	local target_same_mt = { __index=function(self, key)
		if type(key) ~= "string" then
			return false
		end

		if key:sub(-6) == "target" then
			local value = self[key:sub(1, -7)]
			self[key] = value
			return value
		end

		self[key] = false
		return false
	end }

	local target_same_with_target_mt = { __index=function(self, key)
		if type(key) ~= "string" then
			return false
		end

		if key:sub(-6) == "target" then
			local value = self[key:sub(1, -7)]
			value = value and value .. "target"
			self[key] = value
			return value
		end

		self[key] = false
		return false
	end }

	local better_unit_ids = {
		player = "player",
		pet = "pet",
		vehicle = "pet",
		playerpet = "pet",
		mouseover = "mouseover",
		focus = "focus",
		target = "target",
		playertarget = "target",
		npc = "npc",
	}
	for i = 1, _G.MAX_PARTY_MEMBERS do
		better_unit_ids["party" .. i] = "party" .. i
		better_unit_ids["partypet" .. i] = "partypet" .. i
		better_unit_ids["party" .. i .. "pet"] = "partypet" .. i
	end
	for i = 1, _G.MAX_RAID_MEMBERS do
		better_unit_ids["raid" .. i] = "raid" .. i
		better_unit_ids["raidpet" .. i] = "raidpet" .. i
		better_unit_ids["raid" .. i .. "pet"] = "raidpet" .. i
	end
	-- There's no good constant for this.  We used to use
	-- MAX_ARENA_TEAM_MEMBERS which doesn't make sense and broke
	-- when 5.2 moved it into the PVPUI addon.
	for i = 1, 5 do
		better_unit_ids["arena" .. i] = "arena" .. i
		better_unit_ids["arenapet" .. i] = "arenapet" .. i
		better_unit_ids["arena" .. i .. "pet"] = "arenapet" .. i
	end
	for i = 1, _G.MAX_BOSS_FRAMES do
		better_unit_ids["boss" .. i] = "boss" .. i
	end
	for i = 1, 40 do
		better_unit_ids["nameplate" .. i] = "nameplate" .. i
	end
	setmetatable(better_unit_ids, target_same_with_target_mt)

	--- Return the best UnitID for the UnitID provided
	-- @param unit the known UnitID
	-- @usage PitBull4.Utils.GetBestUnitID("playerpet") == "pet"
	-- @return the best UnitID. If the ID is invalid, it will return false
	function PitBull4.Utils.GetBestUnitID(unit)
		return better_unit_ids[unit]
	end

	local valid_singleton_unit_ids = {
		player = true,
		pet = true,
		mouseover = true,
		focus = true,
		target = true,
	}
	for i = 1, 5 do
		valid_singleton_unit_ids["arena" .. i] = true
		valid_singleton_unit_ids["arenapet" .. i] = true
	end
	for i = 1, _G.MAX_BOSS_FRAMES do
		valid_singleton_unit_ids["boss" .. i] = true
	end
	setmetatable(valid_singleton_unit_ids, target_same_mt)

	--- Return whether the UnitID provided is a singleton
	-- @param unit the UnitID to check
	-- @usage PitBull4.Utils.IsSingletonUnitID("player") == true
	-- @usage PitBull4.Utils.IsSingletonUnitID("party1") == false
	-- @return whether it is a singleton
	function PitBull4.Utils.IsSingletonUnitID(unit)
		return valid_singleton_unit_ids[unit]
	end

	local valid_classifications = {
		player = true,
		pet = true,
		mouseover = true,
		focus = true,
		target = true,
		party = true,
		partypet = true,
		raid = true,
		raidpet = true,
		boss = true,
		arena = true,
		arenapet = true,
		battleground = true,
		battlegroundpet = true,
	}
	setmetatable(valid_classifications, target_same_mt)

	--- Return whether the classification is valid
	-- @param classification the classification to check
	-- @usage PitBull4.Utils.IsValidClassification("player") == true
	-- @usage PitBull4.Utils.IsValidClassification("party") == true
	-- @usage PitBull4.Utils.IsValidClassification("partytarget") == true
	-- @usage PitBull4.Utils.IsValidClassification("partypettarget") == true
	-- @usage PitBull4.Utils.IsValidClassification("party1") == false
	-- @return whether it is a a valid classification
	function PitBull4.Utils.IsValidClassification(unit)
		return valid_classifications[unit]
	end

	local non_wacky_unit_ids = {
		player = true,
		pet = true,
		mouseover = true,
		focus = true,
		target = true,
		party = true,
		partypet = true,
		raid = true,
		raidpet = true,
		boss = true,
		arena = true,
		arenapet = true,
		battleground = true,
		battlegroundpet = true,
	}

	--- Return whether the classification provided is considered "wacky"
	-- @param classification the classification in question
	-- @usage assert(not PitBull4.Utils.IsWackyUnitGroup("player"))
	-- @usage assert(PitBull4.Utils.IsWackyUnitGroup("targettarget"))
	-- @usage assert(PitBull4.Utils.IsWackyUnitGroup("partytarget"))
	-- @return whether it is wacky
	function PitBull4.Utils.IsWackyUnitGroup(classification)
		return not non_wacky_unit_ids[classification]
	end
end

do
	local classifications = {
		player = L["Player"],
		target = L["Target"],
		pet = L["Player's pet"],
		party = L["Party"],
		party_sing = L["Party"],
		partypet = L["Party pets"],
		partypet_sing = L["Party pet"],
		arena = L["Arena"],
		arena_sing = L["Arena"],
		arenapet = L["Arena pets"],
		arenapet_sing = L["Arena pet"],
		raid = L["Raid"],
		raid_sing = L["Raid"],
		raidpet = L["Raid pets"],
		raidpet_sing = L["Raid pet"],
		boss = L["Boss"],
		boss_sing = L["Boss"],
		mouseover = L["Mouse-over"],
		focus = L["Focus"],
		maintank = L["Main tanks"],
		maintank_sing = L["Main tank"],
		mainassist = L["Main assists"],
		mainassist_sing = L["Main assist"]
	}
	setmetatable(classifications, {__index=function(self, group)
		local nonTarget
		local singular = false
		if group:find("target$") then
			nonTarget = group:sub(1, -7)
		elseif group:find("target_sing$") then
			singular = true
			nonTarget = group:sub(1, -12)
		else
			self[group] = group
			return group
		end
		local good
		if group:find("^player") or group:find("^pet") or group:find("^mouseover") or group:find("^target") or group:find("^focus") then
			good = L["%s's target"]:format(self[nonTarget])
		elseif singular then
			good = L["%s target"]:format(self[nonTarget .. "_sing"])
		else
			good = L["%s targets"]:format(self[nonTarget .. "_sing"])
		end
		self[group] = good
		return good
	end})

	--- Return a localized form of the unit classification.
	-- @param classification a unit classification, e.g. "player", "party", "partypet"
	-- @usage PitBull4.Utils.GetLocalizedClassification("player") == "Player"
	-- @usage PitBull4.Utils.GetLocalizedClassification("target") == "Player's target"
	-- @usage PitBull4.Utils.GetLocalizedClassification("partypettarget") == "Party pet targets"
	-- @return a localized string of the unit classification
	function PitBull4.Utils.GetLocalizedClassification(classification)
		if DEBUG then
			expect(classification, 'typeof', 'string')
			expect(classification, 'inset', classifications)
		end

		return classifications[classification]
	end
end

--- Leave a function as-is or if a string is passed in, convert it to a namespace-method function call.
-- @param namespace a table with the method func_name on it
-- @param func_name a function (which would then just return) or a string, which is the name of the method.
-- @usage PitBull4.Utils.ConvertMethodToFunction({}, function(value) return value end)("blah") == "blah"
-- @usage PitBull4.Utils.ConvertMethodToFunction({ method = function(self, value) return value end }, "method")("blah") == "blah"
-- @return a function
function PitBull4.Utils.ConvertMethodToFunction(namespace, func_name)
	if type(func_name) == "function" then
		return func_name
	end

	if DEBUG then
		expect(namespace[func_name], 'typeof', 'function')
	end

	return function(...)
		return namespace[func_name](namespace, ...)
	end
end

--- Return the Mob ID of the given GUID.
-- It doesn't matter if the guid starts with "0x" or not.
-- This will only work for NPCs, not other types of guids, such as players.
-- @usage PitBull4.Utils.GetMobIDFromGuid("0xF13000046514911F") == 1125
-- @usage PitBull4.Utils.GetMobIDFromGuid("F13000046514911F") == 1125
function PitBull4.Utils.GetMobIDFromGuid(guid)
	if DEBUG then
		expect(guid, 'typeof', 'string')
	end

	local _, _, _, _, _, mob_id = strsplit('-', guid)
	return tonumber(mob_id)
end

--- Return the unit classification of the given unit.
-- This acts like UnitClassification(unit), but returns "worldboss" for bosses that match LibBossIDs-1.0
-- @param unit The unit to check the classification of.
-- @return one of "worldboss", "elite", "rareelite", "rare", "normal", "trivial", or "minus"
function PitBull4.Utils.BetterUnitClassification(unit)
		local classification = UnitClassification(unit)

		if not LibBossIDs or classification == "worldboss" or classification == "normal" or classification == "minus" or classification == "trivial" then
			return classification
		end

		local guid = UnitGUID(unit)
		if not guid then
			return classification
		end

		local mob_id = PitBull4.Utils.GetMobIDFromGuid(guid)
		if not mob_id then
			return classification
		end

		if LibBossIDs.BossIDs[mob_id] then
			return "worldboss"
		end

		return classification
end

local function deep_copy(data)
	local t = {}
	for k, v in pairs(data) do
		if type(v) == "table" then
			t[k] = deep_copy(v)
		else
			t[k] = v
		end
	end
	setmetatable(t,getmetatable(data))
	return t
end
PitBull4.Utils.deep_copy = deep_copy

--- Parse the relative_to value and return the frame and the type.
-- The relative_to value contains a single character prefix followed by a suffix
-- identifying how to find the actual frame.  See the actual code for the prefixes.
-- @param relative_to value stored in the db
-- @usage local rel_frame, rel_type = PitBull4.Utils.GetRelativeFrame(group_db.relative_to)
-- @return relative_frame the actual frame if it exists.
-- @return relative_type the prefix code indicating the type of the relative_frame
function PitBull4.Utils.GetRelativeFrame(relative_to)
	local relative_type = relative_to:sub(1,1)
	local relative_name = relative_to:sub(2)

	-- The relative_to field consists a single character prefix followed
	-- by the information needed to calculate the frame name for that prefix.
	-- The prefixes are as follows:
	-- 0 = UIParent (suffix is ignored)
	-- S = Singleton frames, suffix is user defined name for the unit.
	-- g = Group header, suffix is the user defined name for the group.
	-- f = First unit in a group, suffix is the user defined name for the group.
	-- ~ = Custom, suffix is the frame name

	if relative_type == "0" then
		return UIParent, relative_type
	elseif relative_type == "S" then
		return _G["PitBull4_Frames_"..relative_name], relative_type
	elseif relative_type == "g" or relative_type == "f" then
		local group = PitBull4.db.profile.groups[relative_name]
		if not group then return nil, relative_type end
		if group.use_pet_header and group.unit_group:match("pet") then
			return _G["PitBull4_PetGroups_"..relative_name], relative_type
		elseif group.unit_group:match("^party") or group.unit_group:match("^raid") then
			return _G["PitBull4_Groups_"..relative_name], relative_type
		else
			return _G["PitBull4_EnemyGroups_"..relative_name], relative_type
		end
	elseif relative_type == "~" then
		return _G[relative_name], relative_type
	else
		error("PitBull4 found an unknown prefix string on the relative_to setting: "..relative_to)
	end
end
