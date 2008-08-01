local _G = _G
local PitBull4 = {}
_G.PitBull4 = PitBull4

PitBull4.Utils = {}

do
	local frame = CreateFrame("Frame", nil, UIParent)
	
	local timers = {}
	--- Add a function that will fire every frame.
	-- @param func the function to call
	-- @usage PitBull4.Utils.AddTimer(function(elapsed, currentTime)
	--     -- do something here
	-- end)
	function PitBull4.Utils.AddTimer(func)
		timers[func] = true
	end
	
	--- Remove a function from firing every frame.
	-- @param func the function that has been already registered
	-- @usage local function func(elapsed, currentTime) ... end
	-- PitBull4.Utils.AddTimer(func)
	-- PitBull4.Utils.RemoveTimer(func)
	-- @usage local function func(elapsed, currentTime)
	--     PitBull4.Utils.RemoveTimer(func)
	-- end
	-- PitBull4.Utils.AddTimer(func)
	function PitBull4.Utils.RemoveTimer(func)
		timers[func] = nil
	end
	
	local tmp = {}
	function PitBull4.Utils.OnUpdate(this, elapsed)
		local currentTime = GetTime()
		for func in pairs(timers) do
			tmp[func] = true
		end
		for func in pairs(tmp) do
			if timers[func] then
				func(elapsed, currentTime)
			end
			tmp[func] = nil
		end
	end
	
	local events = {}
	--- Cause a function to be called when an event is fired.
	-- Functions are fired in the event they are registered
	-- @param event the event that fires
	-- @param func the function to call
	-- @usage PitBull4.Utils.AddEventListener("PLAYER_LOGIN", function(event, ...)
	--     -- do something here
	-- end)
	function PitBull4.Utils.AddEventListener(event, func)
		if not events[event] then
			frame:RegisterEvent(event)
			events[event] = {}
		end
		table.insert(events[event], func)
	end
	
	--- Remove a function from being called on an event
	-- @param event the event that fires
	-- @param func the function that was registered
	-- @usage local function PLAYER_LOGIN(event, ...) end
	-- PitBull4.Utils.AddEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
	-- PitBull4.Utils.RemoveEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
	-- @usage local function PLAYER_LOGIN(event, ...)
	--     PitBull4.Utils.RemoveEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
	-- end
	-- PitBull4.Utils.AddEventListener("PLAYER_LOGIN", PLAYER_LOGIN)
	function PitBull4.Utils.RemoveEventListener(event, func)
		local events_event = events[event]
		if events_event then
			for i = #events_event, 1, -1 do
				local v = events_event[i]
				if v == func then
					table.remove(events_event, i)
				end
			end
			if not events_event[1] then
				frame:UnregisterEvent(event)
				events[event] = nil
			end
		end
	end
	
	local tmps = {}
	function PitBull4.Utils.OnEvent(this, event, ...)
		local events_event = events[event]
		local tmp = next(tmps) or {}
		tmps[tmp] = nil
		for i, func in ipairs(events_event) do
			tmp[i] = func
		end
		for i = 1, #tmp do
			local func = tmp[i]
			tmp[i] = nil
			func(event, ...)
		end
		tmps[tmp] = true
	end
	frame:SetScript("OnEvent", PitBull4.Utils.OnEvent)
	
	local function f(event, name)
		if name ~= "PitBull4" then
			return
		end
		PitBull4.Utils.RemoveEventListener("ADDON_LOADED", f)
		f = nil
		frame:SetScript("OnUpdate", function()
			frame:SetScript("OnUpdate", PitBull4.Utils.OnUpdate)
		end)
	end
	PitBull4.Utils.AddEventListener("ADDON_LOADED", f)
end

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
	local inCombat = false
	local actionsToPerform = {}
	local pool = {}
	PitBull4.Utils.AddEventHandler("PLAYER_REGEN_ENABLED", function()
		inCombat = false
		for i, t in ipairs(actionsToPerform) do
			t[1](unpack(t, 2, t.n+1))
			for k in pairs(t) do
				t[k] = nil
			end
			actionsToPerform[i] = nil
			pool[t] = true
		end
	end)
	PitBull4.Utils.AddEventHandler("PLAYER_REGEN_DISABLED", function()
		inCombat = true
	end)
	--- Call a function if out of combat or schedule to run once combat ends
	-- You can also pass in a table (or frame), method, and arguments
	-- @param func function to call
	-- @param ... arguments to pass into func
	-- @usage PitBull4.Utils.RunOnLeaveCombat(someSecureFunction)
	-- @usage PitBull4.Utils.RunOnLeaveCombat(someSecureFunction, "player")
	-- @usage PitBull4.Utils.RunOnLeaveCombat(frame.SetAttribute, frame, "key", "value")
	-- @usage PitBull4.Utils.RunOnLeaveCombat(frame, 'SetAttribute', "key", "value")
	function PitBull4.Utils.RunOnLeaveCombat(func, ...)
		if type(func) == "table" then
			return PitBull4.Utils.RunOnLeaveCombat(func[(...)], func, select(2, ...))
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
