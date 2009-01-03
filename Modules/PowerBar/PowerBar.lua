if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_PowerBar requires PitBull4")
end

local PitBull4_PowerBar = PitBull4:NewModule("PowerBar", "AceEvent-3.0")

PitBull4_PowerBar:SetModuleType("status_bar")
PitBull4_PowerBar:SetName("Power Bar")
PitBull4_PowerBar:SetDescription("Show a mana, rage, energy, or runic mana bar.")
PitBull4_PowerBar:SetDefaults({
	position = 2,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

local PLAYER_GUID
function PitBull4_PowerBar:OnEnable()
	PLAYER_GUID = UnitGUID("player")
	timerFrame:Show()
	
	PitBull4_PowerBar:RegisterEvent("UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_MAXMANA", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_RAGE", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_MAXRAGE", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_FOCUS", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_MAXFOCUS", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_ENERGY", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_MAXENERGY", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_RUNIC_POWER", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_MAXRUNIC_POWER", "UNIT_MANA")
	PitBull4_PowerBar:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_MANA")
end

function PitBull4_PowerBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	for frame in PitBull4:IterateFramesForGUIDs(PLAYER_GUID, UnitGUID("pet")) do
		PitBull4_PowerBar:Update(frame)
	end
end)

function PitBull4_PowerBar:GetValue(frame)
	return UnitMana(frame.unit) / UnitManaMax(frame.unit)
end

function PitBull4_PowerBar:GetExampleValue(frame)
	return 0.6
end

function PitBull4_PowerBar:GetColor(frame, value)
	local powerType = UnitPowerType(frame.unit)
	local color = PowerBarColor[powerType]
	if color then
		return color.r, color.g, color.b
	end
end

function PitBull4_PowerBar:UNIT_MANA(event, unit)
	PitBull4_PowerBar:UpdateForUnitID(unit)
end
