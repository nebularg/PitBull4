if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_PowerBar requires PitBull4")
end

local PitBull4_PowerBar = PitBull4.NewModule("PowerBar", "Power Bar", "Show a mana, rage, energy, or runic mana bar", {}, {
	position = 2,
}, "statusbar")

function PitBull4_PowerBar.GetValue(frame)
	return UnitMana(frame.unit) / UnitManaMax(frame.unit)
end

function PitBull4_PowerBar.GetColor(frame)
	local powerType = UnitPowerType(frame.unit)
	local color = PowerBarColor[powerType]
	if color then
		return color.r, color.g, color.b
	end
end

PitBull4_PowerBar:SetValueFunction('GetValue')
PitBull4_PowerBar:SetColorFunction('GetColor')

function PitBull4_PowerBar.UNIT_MANA(event, unit)
	PitBull4_PowerBar:UpdateForUnitID(unit)
end

PitBull4.Utils.AddEventListener("UNIT_MANA", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_MAXMANA", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_RAGE", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_MAXRAGE", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_FOCUS", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_MAXFOCUS", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_ENERGY", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_MAXENERGY", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_RUNIC_POWER", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_MAXRUNIC_POWER", PitBull4_PowerBar.UNIT_MANA)
PitBull4.Utils.AddEventListener("UNIT_DISPLAYPOWER", PitBull4_PowerBar.UNIT_MANA)
