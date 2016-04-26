if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local player_class = select(2, UnitClass("player"))
if player_class ~= "PRIEST" then
	return
end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Insanity requires PitBull4")
end

local L = PitBull4.L

local PitBull4_Insanity = PitBull4:NewModule("Insanity", "AceEvent-3.0", "AceTimer-3.0")

-- GLOBALS: SPEC_PRIEST_SHADOW SPELL_POWER_INSANITY

PitBull4_Insanity:SetModuleType("bar")
PitBull4_Insanity:SetName(L["Insanity"])
PitBull4_Insanity:SetDescription(L["Show a bar for Insanity for shadow priests."])
PitBull4_Insanity:SetDefaults({
	size = 1,
	position = 6,
})

function PitBull4_Insanity:OnEnable()
	PitBull4_Insanity:RegisterEvent("UNIT_POWER_FREQUENT")
	PitBull4_Insanity:RegisterEvent("UNIT_MAXPOWER","UNIT_POWER_FREQUENT")
	PitBull4_Insanity:RegisterEvent("UNIT_DISPLAYPOWER","UNIT_POWER_FREQUENT")
	PitBull4_Insanity:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

function PitBull4_Insanity:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end

	if GetSpecialization() ~= SPEC_PRIEST_SHADOW then
		return nil
	end

	local max = UnitPowerMax("player", SPELL_POWER_INSANITY)
	local percent = 0
	if max ~= 0 then
	  percent = UnitPower("player", SPELL_POWER_INSANITY) / max
	end

	return percent
end
function PitBull4_Insanity:GetExampleValue(frame)
	-- just go with what :GetValue gave
	return nil
end

function PitBull4_Insanity:GetColor(frame, value)
	local color = PitBull4.PowerColors["INSANITY"]
	return color[1], color[2], color[3]
end
PitBull4_Insanity.GetExampleColor = PitBull4_Insanity.GetColor

function PitBull4_Insanity:UNIT_POWER_FREQUENT(event, unit, power_type)
	if unit ~= "player" or ((event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER") and power_type ~= "INSANITY") then
		return
	end

	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_Insanity:PLAYER_SPECIALIZATION_CHANGED(event)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end
