
local MAJOR, MINOR = "LibUnitEvent-1.0", 1
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

lib.frames = lib.frames or {}
local frames = lib.frames

lib.events = lib.events or {}
local events = lib.events

lib.embeds = lib.embeds or {}

local validUnits = {
	player = true,
	pet = true,
	vehicle = true,
	focus = true,
}
for i=1,4 do
	validUnits["party"..i] = true
	validUnits["partypet"..i] = true
end
for i=1,40 do
	validUnits["raid"..i] = true
	validUnits["raidpet"..i] = true
end
for i=1,5 do
	validUnits["arena"..i] = true
end
for i=1,5 do
	validUnits["boss"..i] = true
end
for i=1,40 do
	validUnits["nameplate"..i] = true
end

local function normalize(unit)
	if type(unit) == "string" then
		unit = string.lower(unit)
		unit = unit:gsub("^(.-)(%d+)pet", "%1pet%2")
	end
	return unit
end

function lib.OnEvent(self, event, unit, ...)
	local used = nil
	for module, unitEvents in next, events do
		local func = unitEvents[event] and unitEvents[event][unit]
		if func then
			used = true
			if type(func) == "function" then
				func(event, unit, ...)
			else
				module[func](module, event, unit, ...)
			end
		end
	end
	if not used then
		self:UnregisterEvent(event)
	end
end

--- Register a callback for a unit event for the specified units.
-- @string event The event to register
-- @param func The callback function to call when the event is triggered (funcref or method, defaults to a method with the event name)
-- @string ... Unit ids to register
-- @usage MyAddon:RegisterUnitEvent("UNIT_HEALTH_FREQUENT", "UpdateHealth", "player")
-- @usage MyAddon:RegisterUnitEvent("UNIT_POWER_UPDATE", nil, "player", "vehicle")
function lib:RegisterUnitEvent(event, func, ...)
	if not func then func = event end
	if type(event) ~= "string" then
		error("Usage: RegisterUnitEvent(event, method, unit...): 'event' - string expected.", 2)
	end
	if type(func) ~= "string" and type(func) ~= "function" then
		error("Usage: RegisterUnitEvent(\"event\", \"method\"): 'method' - string or function expected.", 2)
	end
	if type(func) == "string" and (type(self) ~="table" or not self[func]) then
		error("Usage: RegisterUnitEvent(event, method, unit...): 'method' - method '"..tostring(func).."' not found on self.", 2)
	end
	if select("#", ...) == 0 then
		error("Usage: RegisterUnitEvent(event, method, unit...): 'unit' - string expected.", 2)
	end

	if not events[self] then events[self] = {} end
	if not events[self][event] then events[self][event] = {} end
	for i = 1, select("#", ...) do
		local unit = normalize(select(i, ...))
		if not validUnits[unit] then
			error("Usage: RegisterUnitEvent(event, method, unit...): 'unit' - unit '"..tostring(unit).."' invalid.", 2)
		end
		local frame = frames[unit]
		if not frame then
			frame = CreateFrame("Frame")
			frame:SetScript("OnEvent", lib.OnEvent)
			frame[unit] = frame
		end
		events[self][event][unit] = func
		frame:RegisterUnitEvent(event, unit)
	end
end

--- Unregister a unit event.
-- @string event The event to unregister
-- @string ... Unit ids to register
-- @usage MyAddon:UnregisterUnitEvent("UNIT_POWER_UPDATE", "player", "vehicle")
function lib:UnregisterUnitEvent(event, ...)
	if type(event) ~= "string" then
		error("Usage: UnregisterUnitEvent(event, unit...): 'event' - string expected.", 2)
	end
	if select("#", ...) == 0 then
		error("Usage: UnregisterUnitEvent(event, unit...): 'unit' - string expected.", 2)
	end

	local units = events[self] and events[self][event]
	if not units then return end

	for i = 1, select("#", ...) do
		local unit = normalize(select(i, ...))
		if not validUnits[unit] then
			error("Usage: UnregisterUnitEvent(event, unit...): 'unit' - unit '"..tostring(unit).."' invalid.", 2)
		end
		units[unit] = nil
		-- Events remain registered on a frame until the event fires and has no target
	end

	-- Cleanup
	if not next(units) then
		events[self][event] = nil
		if not next(events[self]) then
			events[self] = nil
		end
	end
end

--- Unregister all unit events
function lib:UnregisterAllUnitEvents()
	for event, units in next, events[self] do
		for unit in next, units do
			self:UnregisterUnitEvent(event, unit)
		end
	end
end

-- Handle embedding
local mixins = {
	"RegisterUnitEvent",
	"UnregisterUnitEvent",
	"UnregisterAllUnitEvents",
}

function lib:Embed(target)
	for k, v in next, mixins do
		target[v] = self[v]
	end
	self.embeds[target] = true
	return target
end

function lib:OnEmbedDisable(target)
	target:UnregisterAllUnitEvents()
end
