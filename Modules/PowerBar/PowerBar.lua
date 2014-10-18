if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

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
PitBull4_PowerBar.allow_animations = true
PitBull4_PowerBar:SetDefaults({
	position = 2,
	hide_no_mana = false,
	hide_no_power = false,
})

local guids_to_update = {}

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

function PitBull4_PowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER", "UNIT_POWER_FREQUENT")

	timerFrame:Show()
end

function PitBull4_PowerBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	if next(guids_to_update) then
		for frame in PitBull4:IterateFrames() do
			if guids_to_update[frame.guid] then
				PitBull4_PowerBar:Update(frame)
			end
		end
		wipe(guids_to_update)
	end
end)

function PitBull4_PowerBar:GetValue(frame)	
	local unit = frame.unit
	local layout_db = self:GetLayoutDB(frame)
	local max = UnitPowerMax(unit)

	if layout_db.hide_no_mana and UnitPowerType(unit) ~= 0 then
		return nil
	elseif layout_db.hide_no_power and max <= 0 then
		return nil
	end

	if max == 0 then
		return 0
	end

	return UnitPower(unit) / max
end

function PitBull4_PowerBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

function PitBull4_PowerBar:GetColor(frame, value)
	local db = self:GetLayoutDB(frame)
	
	local _, power_token = UnitPowerType(frame.unit)
	if not power_token then
		power_token = "MANA"
	end
	if power_token == "POWER_TYPE_RED_POWER" then
		-- Apparently they couldn't just reuse the existing
		-- RAGE type they had to make a new one, just map it
		-- becuase providing two colors that are both red and 
		-- translate to Red in the UI is dumb.
		power_token = "RAGE"
	end
	local color = PitBull4.PowerColors[power_token]
	
	if color then
		return color[1], color[2], color[3]
	end
end
function PitBull4_PowerBar:GetExampleColor(frame)
	return unpack(PitBull4.PowerColors.MANA)
end

function PitBull4_PowerBar:UNIT_POWER_FREQUENT(event, unit)
	local guid = UnitGUID(unit)
	if guid then
		guids_to_update[guid] = true
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
	}
end)
