if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_PowerBar requires PitBull4")
end

local EXAMPLE_VALUE = 0.6

local L = PitBull4.L

local PitBull4_PowerBar = PitBull4:NewModule("PowerBar", "AceEvent-3.0")

PitBull4_PowerBar:SetModuleType("bar")
PitBull4_PowerBar:SetName(L["Power bar"])
PitBull4_PowerBar:SetDescription(L["Show a mana, rage, energy, or runic power bar."])
PitBull4_PowerBar:SetDefaults({
	position = 2,
	hide_no_mana = false,
	hide_no_power = false,
	color_by_class = false,
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
	PitBull4_PowerBar:RegisterEvent("CVAR_UPDATE")
	PitBull4_PowerBar:RegisterEvent("VARIABLES_LOADED", "CVAR_UPDATE")
end

function PitBull4_PowerBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	for frame in PitBull4:IterateFramesForGUIDs(PLAYER_GUID, UnitGUID("pet")) do
		if not frame.is_wacky then
			PitBull4_PowerBar:Update(frame)
		end
	end
end)

function PitBull4_PowerBar:GetValue(frame)	
	local unit = frame.unit
	local layout_db = self:GetLayoutDB(frame)

	if layout_db.hide_no_mana and UnitPowerType(unit) ~= 0 then
		return nil
	elseif layout_db.hide_no_power and UnitPowerMax(unit) <= 0 then
		return nil
	end
	return UnitPower(unit) / UnitPowerMax(unit)
end

function PitBull4_PowerBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

function PitBull4_PowerBar:GetColor(frame, value)
	local db = self:GetLayoutDB(frame)
	
	local color
	if db.color_by_class then
		local _, class = UnitClass(frame.unit)
		color = PitBull4.ClassColors[class]
	else
		local _, power_token = UnitPowerType(frame.unit)
		if not power_token then
			power_token = "MANA"
		end
		color = PitBull4.PowerColors[power_token]
	end
	
	if color then
		return color[1], color[2], color[3]
	end
end
function PitBull4_PowerBar:GetExampleColor(frame)
	local db = self:GetLayoutDB(frame)
	
	if db.color_by_class then
		return unpack(PitBull4.ClassColors.MAGE)
	else
		return unpack(PitBull4.PowerColors.MANA)
	end
end

function PitBull4_PowerBar:UNIT_MANA(event, unit)
	PitBull4_PowerBar:UpdateForUnitID(unit)
end

function PitBull4_PowerBar:CVAR_UPDATE()
	if GetCVarBool("predictedPower") then
		timerFrame:Show()
	else
		timerFrame:Hide()
	end
end

PitBull4_PowerBar:SetLayoutOptionsFunction(function(self)
	return 'hide_no_mana', {
		name = L['Hide non-mana'],
		desc = L["Hides the power bar if the unit's current power is not mana."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).hide_no_mana
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).hide_no_mana = value

			PitBull4.Options.UpdateFrames()
		end,
	}, 'hide_no_power', {
		name = L['Hide non-power'],
		desc = L['Hides the power bar if the unit has no power.'],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).hide_no_power
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).hide_no_power = value

			PitBull4.Options.UpdateFrames()
		end,
	}, 'color_by_class', {
		name = L["Color by class"],
		desc = L["Color the power bar by unit class"],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).color_by_class
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).color_by_class = value
			
			PitBull4.Options.UpdateFrames()
		end
	}
end)
