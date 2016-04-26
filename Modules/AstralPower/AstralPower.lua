if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local player_class = select(2, UnitClass("player"))
if player_class ~= "DRUID" then
	return
end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_AstralPower requires PitBull4")
end

local L = PitBull4.L

local PitBull4_AstralPower = PitBull4:NewModule("AstralPower", "AceEvent-3.0", "AceTimer-3.0")

-- GLOBALS: SPEC_DRUID_BALANCE SPELL_POWER_LUNAR_POWER

PitBull4_AstralPower:SetModuleType("bar")
PitBull4_AstralPower:SetName(L["AstralPower"])
PitBull4_AstralPower:SetDescription(L["Show a bar for AstralPower for balance druids."])
PitBull4_AstralPower:SetDefaults({
	size = 1,
	position = 6,
})

function PitBull4_AstralPower:OnEnable()
	PitBull4_AstralPower:RegisterEvent("UNIT_POWER_FREQUENT")
	PitBull4_AstralPower:RegisterEvent("UNIT_MAXPOWER","UNIT_POWER_FREQUENT")
	PitBull4_AstralPower:RegisterEvent("UNIT_DISPLAYPOWER","UNIT_POWER_FREQUENT")
	PitBull4_AstralPower:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

function PitBull4_AstralPower:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end

	if GetSpecialization() ~= SPEC_DRUID_BALANCE then
		return nil
	end

	local max = UnitPowerMax("player", SPELL_POWER_LUNAR_POWER)
	local percent = 0
	if max ~= 0 then
	  percent = UnitPower("player", SPELL_POWER_LUNAR_POWER) / max
	end

	return percent
end
function PitBull4_AstralPower:GetExampleValue(frame)
	-- just go with what :GetValue gave
	return nil
end

function PitBull4_AstralPower:GetColor(frame, value)
	local color = PitBull4.PowerColors["LUNAR_POWER"]
	return color[1], color[2], color[3]
end
PitBull4_AstralPower.GetExampleColor = PitBull4_AstralPower.GetColor

function PitBull4_AstralPower:UNIT_POWER_FREQUENT(event, unit, power_type)
	if unit ~= "player" or ((event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER") and power_type ~= "LUNAR_POWER") then
		return
	end

	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_AstralPower:PLAYER_SPECIALIZATION_CHANGED(event)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end
