if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass("player")) ~= "DRUID" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_DruidManaBar requires PitBull4")
end

local L = PitBull4.L

local PitBull4_DruidManaBar = PitBull4:NewModule("DruidManaBar", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_DruidManaBar:SetModuleType("bar")
PitBull4_DruidManaBar:SetName(L["Druid mana bar"])
PitBull4_DruidManaBar:SetDescription(L["Show the mana bar when a druid is in cat or bear form."])
PitBull4_DruidManaBar:SetDefaults({
	size = 1,
	position = 6,
	hide_if_full = false,
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
	
	local percent = UnitPower("player", MANA_TYPE) / UnitPowerMax("player", MANA_TYPE)

	if percent == 1 and self:GetLayoutDB(frame).hide_if_full then
		return nil
	end

	return percent
end
function PitBull4_DruidManaBar:GetExampleValue(frame)
	-- just go with what :GetValue gave
	return nil
end

function PitBull4_DruidManaBar:GetColor(frame, value)
	local color = PitBull4.PowerColors["MANA"]
	return color[1], color[2], color[3]
end
PitBull4_DruidManaBar.GetExampleColor = PitBull4_DruidManaBar.GetColor

function PitBull4_DruidManaBar:UNIT_MANA(event, unit)
	if unit ~= "player" then
		return
	end
	
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

PitBull4_DruidManaBar.UNIT_MAXMANA = PitBull4_DruidManaBar.UNIT_MANA
PitBull4_DruidManaBar.UNIT_DISPLAYPOWER = PitBull4_DruidManaBar.UNIT_MANA

PitBull4_DruidManaBar:SetLayoutOptionsFunction(function(self)
	return 'hide_if_full', {
		name = L["Hide if full"],
		desc = L["Hide when at 100% mana."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).hide_if_full
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).hide_if_full = value
			
			PitBull4.Options.UpdateFrames()
		end,
	}
end)
