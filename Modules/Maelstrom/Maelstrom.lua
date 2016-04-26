if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local player_class = select(2, UnitClass("player"))
if player_class ~= "SHAMAN" then
	return
end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Maelstrom requires PitBull4")
end

local L = PitBull4.L

local PitBull4_Maelstrom = PitBull4:NewModule("Maelstrom", "AceEvent-3.0", "AceTimer-3.0")

-- GLOBALS: SPEC_SHAMAN_ENHANCEMENT SPEC_SHAMAN_ELEMENTAL SPELL_POWER_MAELSTROM

PitBull4_Maelstrom:SetModuleType("bar")
PitBull4_Maelstrom:SetName(L["Maelstrom"])
PitBull4_Maelstrom:SetDescription(L["Show a bar for Maelstrom for enhancement and elemental shamans."])
PitBull4_Maelstrom:SetDefaults({
	size = 1,
	position = 6,
})

function PitBull4_Maelstrom:OnEnable()
	PitBull4_Maelstrom:RegisterEvent("UNIT_POWER_FREQUENT")
	PitBull4_Maelstrom:RegisterEvent("UNIT_MAXPOWER","UNIT_POWER_FREQUENT")
	PitBull4_Maelstrom:RegisterEvent("UNIT_DISPLAYPOWER","UNIT_POWER_FREQUENT")
	PitBull4_Maelstrom:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
end

function PitBull4_Maelstrom:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end

	if GetSpecialization() ~= SPEC_SHAMAN_ENHANCEMENT or SPEC_SHAMAN_ELEMENTAL then
		return nil
	end

	local max = UnitPowerMax("player", SPELL_POWER_MAELSTROM)
	local percent = 0
	if max ~= 0 then
	  percent = UnitPower("player", SPELL_POWER_MAELSTROM) / max
	end

	return percent
end
function PitBull4_Maelstrom:GetExampleValue(frame)
	-- just go with what :GetValue gave
	return nil
end

function PitBull4_Maelstrom:GetColor(frame, value)
	local color = PitBull4.PowerColors["MAELSTROM"]
	return color[1], color[2], color[3]
end
PitBull4_Maelstrom.GetExampleColor = PitBull4_Maelstrom.GetColor

function PitBull4_Maelstrom:UNIT_POWER_FREQUENT(event, unit, power_type)
	if unit ~= "player" or ((event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER") and power_type ~= "MAELSTROM") then
		return
	end

	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_Maelstrom:PLAYER_SPECIALIZATION_CHANGED(event)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end
