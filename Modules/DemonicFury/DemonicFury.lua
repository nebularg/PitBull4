if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local player_class = select(2, UnitClass("player"))
if player_class ~= "WARLOCK" then
	return
end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_DemonicFury requires PitBull4")
end

local L = PitBull4.L

local PitBull4_DemonicFury = PitBull4:NewModule("DemonicFury", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_DemonicFury:SetModuleType("bar")
PitBull4_DemonicFury:SetName(L["Demonic fury"])
PitBull4_DemonicFury:SetDescription(L["Show a bar for demonic fury for demonology warlocks."])
PitBull4_DemonicFury:SetDefaults({
	size = 1,
	position = 6,
})

function PitBull4_DemonicFury:OnEnable()
	PitBull4_DemonicFury:RegisterEvent("UNIT_POWER_FREQUENT")
	PitBull4_DemonicFury:RegisterEvent("UNIT_MAXPOWER","UNIT_POWER_FREQUENT")
	PitBull4_DemonicFury:RegisterEvent("UNIT_DISPLAYPOWER","UNIT_POWER_FREQUENT")
	PitBull4_DemonicFury:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

function PitBull4_DemonicFury:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end
 
	if GetSpecialization() ~= SPEC_WARLOCK_DEMONOLOGY then
		return nil
	end

	local max = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)
	local percent = 0
	if max ~= 0 then
	  percent = UnitPower("player", SPELL_POWER_DEMONIC_FURY) / max
	end

	return percent
end
function PitBull4_DemonicFury:GetExampleValue(frame)
	-- just go with what :GetValue gave
	return nil
end

function PitBull4_DemonicFury:GetColor(frame, value)
	local color = PitBull4.PowerColors["DEMONIC_FURY"]
	return color[1], color[2], color[3]
end
PitBull4_DemonicFury.GetExampleColor = PitBull4_DemonicFury.GetColor

function PitBull4_DemonicFury:UNIT_POWER_FREQUENT(event, unit, power_type)
	if unit ~= "player" or ((event == "UNIT_POWER" or event == "UNIT_MAXPOWER") and power_type ~= "DEMONIC_FURY") then
		return
	end

	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_DemonicFury:PLAYER_SPECIALIZATION_CHANGED(event)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end
