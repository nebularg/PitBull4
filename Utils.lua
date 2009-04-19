local _G = _G
local PitBull4 = _G.PitBull4

local L = PitBull4.L

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
	for i = 1, MAX_PARTY_MEMBERS do
		better_unit_ids["party" .. i] = "party" .. i
		better_unit_ids["partypet" .. i] = "partypet" .. i
		better_unit_ids["party" .. i .. "pet"] = "partypet" .. i
	end
	for i = 1, MAX_RAID_MEMBERS do
		better_unit_ids["raid" .. i] = "raid" .. i
		better_unit_ids["raidpet" .. i] = "raidpet" .. i
		better_unit_ids["raid" .. i .. "pet"] = "raidpet" .. i
	end
	for i = 1, MAX_ARENA_TEAM_MEMBERS do
		better_unit_ids["arena" .. i] = "arena" .. i
		better_unit_ids["arenapet" .. i] = "arenapet" .. i
		better_unit_ids["arena" .. i .. "pet"] = "arenapet" .. i
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
		raid = L["Raid"],
		raid_sing = L["Raid"],
		raidpet = L["Raid pets"],
		raidpet_sing = L["Raid pet"],
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
		--@alpha@
		expect(classification, 'typeof', 'string')
		expect(classification, 'inset', classifications)
		--@end-alpha@
		
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
	
	--@alpha@
	expect(namespace[func_name], 'typeof', 'function')
	--@end-alpha@
	
	return function(...)
		return namespace[func_name](namespace, ...)
	end
end
