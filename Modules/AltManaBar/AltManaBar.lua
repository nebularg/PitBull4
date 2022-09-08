local player_class = UnitClassBase("player")
if player_class ~= "DRUID" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_AltManaBar = PitBull4:NewModule("DruidManaBar")

PitBull4_AltManaBar:SetModuleType("bar")
PitBull4_AltManaBar:SetName(L["Alternate mana bar"])
PitBull4_AltManaBar:SetDescription(L["Show the mana bar for specs that don't use mana as their primary resource."])
PitBull4_AltManaBar.allow_animations = true
PitBull4_AltManaBar:SetDefaults({
	size = 1,
	position = 6,
	hide_if_full = false,
	show_in_forms = true,
})

-- constants
local SPELL_POWER_MANA = 0 -- Enum.PowerType.Mana

-- cached power type for optimization
local power_type = nil

function PitBull4_AltManaBar:OnEnable()
	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "player")
	self:RegisterUnitEvent("UNIT_MAXPOWER", "UNIT_POWER_FREQUENT", "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "UNIT_POWER_FREQUENT", "player")
end

function PitBull4_AltManaBar:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end

	power_type = UnitPowerType("player")
	if power_type == SPELL_POWER_MANA then
		return nil
	end

	if UnitHasVehiclePlayerFrameUI and UnitHasVehiclePlayerFrameUI("player") then
		return nil
	end

	local max = UnitPowerMax("player", SPELL_POWER_MANA)
	if max == 0 then
		return nil
	end

	local percent = UnitPower("player", SPELL_POWER_MANA) / max
	if percent == 1 and self:GetLayoutDB(frame).hide_if_full then
		return nil
	end

	return percent
end

function PitBull4_AltManaBar:GetColor(frame, value)
	return unpack(PitBull4.PowerColors.MANA)
end
PitBull4_AltManaBar.GetExampleColor = PitBull4_AltManaBar.GetColor

function PitBull4_AltManaBar:UNIT_POWER_FREQUENT(event, unit, power_type)
	if unit ~= "player" or ((event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER") and power_type ~= "MANA") then
		return
	end

	local prev_power_type = power_type
	power_type = UnitPowerType("player")
	if power_type ~= SPELL_POWER_MANA or power_type ~= prev_power_type then
		-- We really don't want to iterate all the frames on every mana
		-- update when the bar is already hidden.
		self:UpdateForUnitID("player")
	end
end

PitBull4_AltManaBar:SetLayoutOptionsFunction(function(self)
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
