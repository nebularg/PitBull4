
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.6

local PitBull4_AltPowerBar = PitBull4:NewModule("AltPowerBar")

PitBull4_AltPowerBar:SetModuleType("bar")
PitBull4_AltPowerBar:SetName(L["Alternate power bar"])
PitBull4_AltPowerBar:SetDescription(L["Show a bar for the alternate power bar as used in some quests and boss encounters."])
PitBull4_AltPowerBar.allow_animations = true
PitBull4_AltPowerBar:SetDefaults({
	position = 3,
})

function PitBull4_AltPowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER_BAR_SHOW")
	self:RegisterEvent("UNIT_POWER_BAR_HIDE", "UNIT_POWER_BAR_SHOW")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateAll")
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER_FREQUENT")
end

function PitBull4_AltPowerBar:GetValue(frame)
	local unit = frame.unit
	local bar_info = GetUnitPowerBarInfo(unit)
	if not bar_info then return end

	local visible = false
	if bar_info.barType then
		if (unit == "player" or unit == "vehicle" or unit == "pet") or not bar_info.hideFromOthers then
			visible = true
		elseif bar_info.showOnRaid and (UnitInRaid(unit) or UnitInParty(unit)) then
			visible = true
		end
	end
	if not visible then return nil end

	local max_power = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
	if max_power == 0 then
		return 0
	end

	local min_power = bar_info.minPower
	local current_power = UnitPower(unit, ALTERNATE_POWER_INDEX)
	if min_power > current_power then
		current_power = min_power
	end
	if max_power < current_power then
		current_power = max_power
	end

	return (current_power - min_power) / (max_power - min_power)
end

function PitBull4_AltPowerBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

function PitBull4_AltPowerBar:GetColor(frame, value)
	return unpack(PitBull4.PowerColors.PB4_ALTERNATE)
end
PitBull4_AltPowerBar.GetExampleColor = PitBull4_AltPowerBar.GetColor

function PitBull4_AltPowerBar:UNIT_POWER_BAR_SHOW(event, unit)
	self:UpdateForUnitID(unit)
end

function PitBull4_AltPowerBar:UNIT_POWER_FREQUENT(event, unit, power_type)
	if power_type ~= "ALTERNATE" then
		return
	end

	self:UpdateForUnitID(unit)
end
