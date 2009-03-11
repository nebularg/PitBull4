if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_PowerBar requires PitBull4")
end

local L = PitBull4.L

local PitBull4_PowerBar = PitBull4:NewModule("PowerBar", "AceEvent-3.0")

PitBull4_PowerBar:SetModuleType("bar")
PitBull4_PowerBar:SetName(L["Power bar"])
PitBull4_PowerBar:SetDescription(L["Show a mana, rage, energy, or runic power bar."])
PitBull4_PowerBar:SetDefaults({
	position = 2,
	hide_no_mana = false,
	hide_no_power = false,
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
	return 0.6
end

function PitBull4_PowerBar:GetColor(frame, value)
	local power_token = frame.guid and select(2, UnitPowerType(frame.unit)) or "MANA"
	local color = PitBull4.PowerColors[power_token]
	if color then
		return color[1], color[2], color[3]
	end
end
function PitBull4_PowerBar:GetExampleColor(frame)
	return unpack(PitBull4.PowerColors.MANA)
end

function PitBull4_PowerBar:UNIT_MANA(event, unit)
	PitBull4_PowerBar:UpdateForUnitID(unit)
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
	}
end)
