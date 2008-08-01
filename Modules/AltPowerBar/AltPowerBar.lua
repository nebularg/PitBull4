if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_AltPowerBar requires PitBull4")
end

local EXAMPLE_VALUE = 0.6

local L = PitBull4.L

local PitBull4_AltPowerBar = PitBull4:NewModule("AltPowerBar", "AceEvent-3.0")

PitBull4_AltPowerBar:SetModuleType("bar")
PitBull4_AltPowerBar:SetName(L["Alternate power bar"])
PitBull4_AltPowerBar:SetDescription(L["Show a bar for the alternate power bar as used in some quests and boss encounters."])
PitBull4_AltPowerBar:SetDefaults({
	position = 3,
})

function PitBull4_AltPowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER_BAR_SHOW")
	self:RegisterEvent("UNIT_POWER_BAR_HIDE", "UNIT_POWER_BAR_SHOW")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_POWER")
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER")
	
end

function PitBull4_AltPowerBar:GetValue(frame)	
	local unit = frame.unit
	local bar_type, min_power, _, _, _, hide_from_others, show_on_raid = UnitAlternatePowerInfo(unit)
	local visible = false
	if bar_type then
		if (unit == "player" or unit == "vehicle" or unit == "pet") or not hide_from_others then
			visible = true
		elseif show_on_raid and (UnitInRaid(unit) or UnitInParty(unit)) then
			visible = true
		end
	end
	if not visible then return nil end

	local max_power = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
	if max_power == 0 then
		return 0
	end
	
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

function PitBull4_AltPowerBar:PLAYER_ENTERING_WORLD(event)
	self:UpdateAll()
end

function PitBull4_AltPowerBar:UNIT_POWER(event, unit, power_type)
	if power_type ~= "ALTERNATE" then return end
	self:UpdateForUnitID(unit)
end

