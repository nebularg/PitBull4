if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass("player")) ~= "DRUID" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_DruidManaBar requires PitBull4")
end

local L = PitBull4.L

local PitBull4_DruidManaBar = PitBull4:NewModule("DruidManaBar", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_DruidManaBar:SetModuleType("status_bar")
PitBull4_DruidManaBar:SetName(L["Druid mana bar"])
PitBull4_DruidManaBar:SetDescription(L["Show the mana bar when a druid is in cat or bear form."])
PitBull4_DruidManaBar:SetDefaults({
	size = 1,
	position = 6,
})

-- constants
local MANA_TYPE = 0

function PitBull4_DruidManaBar:OnEnable()
	PitBull4_DruidManaBar:RegisterEvent("UNIT_MANA")
	PitBull4_DruidManaBar:RegisterEvent("UNIT_DISPLAYPOWER")
	PitBull4_DruidManaBar:RegisterEvent("UNIT_MAXMANA")
end

function PitBull4_DruidManaBar:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end
    
	if UnitPowerType("player") == MANA_TYPE then
		return nil
	end
	
	return UnitPower("player", MANA_TYPE) / UnitPowerMax("player", MANA_TYPE)
end

function PitBull4_DruidManaBar:GetColor(frame, value)
	local color = PowerBarColor[MANA_TYPE]
	return color.r, color.g, color.b
end

function PitBull4_DruidManaBar:UNIT_MANA(event, unit)
	if unit ~= "player" then
		return
	end
	
	self:UpdateForUnitID("player")
end

PitBull4_DruidManaBar.UNIT_MAXMANA = PitBull4_DruidManaBar.UNIT_MANA
PitBull4_DruidManaBar.UNIT_DISPLAYPOWER = PitBull4_DruidManaBar.UNIT_MANA
