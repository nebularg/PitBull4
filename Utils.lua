local _G = _G
local PitBull4 = _G.PitBull4

PitBull4.Utils = {}

--@alpha@
do
	local function ptostring(value)
		if type(value) == "string" then
			return ("%q"):format(value)
		end
		return tostring(value)
	end

	local conditions = {}
	local function helper(alpha, ...)
		for i = 1, select('#', ...) do
			if alpha == select(i, ...) then
				return true
			end
		end
		return false
	end
	conditions['inset'] = function(alpha, bravo)
		if type(bravo) == "table" then
			return bravo[alpha] ~= nil
		end
		return helper(alpha, (";"):split(bravo))
	end
	conditions['typeof'] = function(alpha, bravo)
		local type_alpha = type(alpha)
		if type_alpha == "table" and type(rawget(alpha, 0)) == "userdata" and type(alpha.IsObjectType) == "function" then
			type_alpha = 'frame'
		end
		return conditions['inset'](type_alpha, bravo)
	end
	conditions['frametype'] = function(alpha, bravo)
		if type(bravo) ~= "string" then
			error(("Bad argument #3 to `expect'. Expected %q, got %q"):format("string", type(bravo)), 3)
		end
		return type(alpha) == "table" and type(rawget(alpha, 0)) == "userdata" and type(alpha.IsObjectType) == "function" and alpha:IsObjectType(bravo)
	end
	conditions['match'] = function(alpha, bravo)
		if type(alpha) ~= "string" then
			error(("Bad argument #1 to `expect'. Expected %q, got %q"):format("string", type(alpha)), 3)
		end
		if type(bravo) ~= "string" then
			error(("Bad argument #3 to `expect'. Expected %q, got %q"):format("string", type(bravo)), 3)
		end
		return alpha:match(bravo)
	end
	conditions['=='] = function(alpha, bravo)
		return alpha == bravo
	end
	conditions['~='] = function(alpha, bravo)
		return alpha ~= bravo
	end
	conditions['>'] = function(alpha, bravo)
		return type(alpha) == type(bravo) and alpha > bravo
	end
	conditions['>='] = function(alpha, bravo)
		return type(alpha) == type(bravo) and alpha >= bravo
	end
	conditions['<'] = function(alpha, bravo)
		return type(alpha) == type(bravo) and alpha < bravo
	end
	conditions['<='] = function(alpha, bravo)
		return type(alpha) == type(bravo) and alpha <= bravo
	end

	function _G.expect(alpha, condition, bravo)
		if not conditions[condition] then
			error(("Unknown condition %s"):format(ptostring(condition)), 2)
		end
		if not conditions[condition](alpha, bravo) then
			error(("Expectation failed: %s %s %s"):format(ptostring(alpha), condition, ptostring(bravo)), 2)
		end
	end
end
--@end-alpha@

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
	
	local better_unitIDs = {
		player = "player",
		pet = "pet",
		vehicle = "pet",
		playerpet = "pet",
		mouseover = "mouseover",
		focus = "focus",
		target = "target",
		playertarget = "target",
	}
	for i = 1, 4 do
		better_unitIDs["party" .. i] = "party" .. i
		better_unitIDs["partypet" .. i] = "partypet" .. i
		better_unitIDs["party" .. i .. "pet"] = "partypet" .. i
	end
	for i = 1, 40 do
		better_unitIDs["raid" .. i] = "raid" .. i
		better_unitIDs["raidpet" .. i] = "raidpet" .. i
		better_unitIDs["raid" .. i .. "pet"] = "raidpet" .. i
	end
	setmetatable(better_unitIDs, target_same_with_target_mt)
	
	--- Return the best unitID for the unitID provided
	-- @param unitID the known unitID
	-- @usage assert(PitBull4.Utils.GetBestUnitID("playerpet") == "pet")
	-- @return the best unitID. If the ID is invalid, it will return false
	function PitBull4.Utils.GetBestUnitID(unitID)
		return better_unitIDs[unitID]
	end
	
	local valid_singleton_unitIDs = {
		player = true,
		pet = true,
		mouseover = true,
		focus = true,
		target = true,
	}
	setmetatable(valid_singleton_unitIDs, target_same_mt)
	
	--- Return whether the unitID provided is a singleton
	-- @param unitID the unitID to check
	-- @usage assert(PitBull4.Utils.IsSingletonUnitID("player"))
	-- @usage assert(not PitBull4.Utils.IsSingletonUnitID("party1"))
	-- @return whether it is a singleton
	function PitBull4.Utils.IsSingletonUnitID(unitID)
		return valid_singleton_unitIDs[unitID]
	end
	
	local non_wacky_unitIDs = {
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
	-- @usage assert(not PitBull4.Utils.IsWackyClassification("player"))
	-- @usage assert(PitBull4.Utils.IsWackyClassification("targettarget"))
	-- @return whether it is wacky
	function PitBull4.Utils.IsWackyClassification(classification)
		return not non_wacky_unitIDs[classification]
	end
end

do
	local classifications = {player = "Player", target = "Target", pet = "Player's pet", party = "Party", party_sing = "Party", partypet = "Party pets", partypet_sing = "Party pet", raid = "Raid", raid_sing = "Raid", raidpet = "Raid pets", raidpet_sing = "Raid pet", mouseover = "Mouse-over", focus = "Focus", maintank = "Main tanks", maintank_sing = "Main tank", mainassist = "Main assists", mainassist_sing = "Main assist"}
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
			good = ("%s's target"):format(self[nonTarget])
		elseif singular then
			good = ("%s target"):format(self[nonTarget .. "_sing"])
		else
			good = ("%s targets"):format(self[nonTarget .. "_sing"])
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
