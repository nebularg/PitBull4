local _, player_class = UnitClass("player")
if player_class ~= "DRUID" and player_class ~= "ROGUE" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_EnergySpark = PitBull4:NewModule("EnergySpark")

PitBull4_EnergySpark:SetModuleType("custom")
PitBull4_EnergySpark:SetName(L["Energy Spark"])
PitBull4_EnergySpark:SetDescription(L["Show the energy regen tick timer."])
PitBull4_EnergySpark:SetDefaults({
	always_show = false,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

timerFrame:SetScript("OnUpdate", function()
	PitBull4_EnergySpark:UpdateForUnitID("player")
end)

local SPELL_POWER_ENERGY = Enum.PowerType.Energy
local ENERGY_REGEN_TIME = 2.0
local INVERSE_ENERGY_REGEN_TIME = 1 / ENERGY_REGEN_TIME
local ENERGY_REGEN_LAG = 0.012

local current_energy = 0
local last_energy_gained = 0
local time_since_regen = 0

function PitBull4_EnergySpark:OnEnable()
	timerFrame:Show()

	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "player")
	self:RegisterUnitEvent("UNIT_MAXPOWER", nil, "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "UNIT_MAXPOWER", "player")

	current_energy = UnitPower("player", SPELL_POWER_ENERGY)
end

function PitBull4_EnergySpark:OnDisable()
	timerFrame:Hide()
end

function PitBull4_EnergySpark:UpdateFrame(frame)
	if frame.unit ~= "player" then
		return self:ClearFrame(frame)
	end

	local bar = frame.PowerBar
	if not bar or UnitPowerType("player") ~= SPELL_POWER_ENERGY then
		return self:ClearFrame(frame)
	end

	if last_energy_gained == 0 then
		return self:ClearFrame(frame)
	end

	local always_show = self:GetLayoutDB(frame).always_show
	if not always_show and current_energy == UnitPowerMax("player", SPELL_POWER_ENERGY) and not InCombatLockdown() then
		return self:ClearFrame(frame)
	end

	local time_since_regen = GetTime() - last_energy_gained
	if time_since_regen > ENERGY_REGEN_TIME then
		last_energy_gained = last_energy_gained + ENERGY_REGEN_TIME + ENERGY_REGEN_LAG
		time_since_regen = 0
	end

	local spark = frame.EnergySpark
	if not spark then
		spark = PitBull4.Controls.MakeFrame(frame.overlay)
		frame.EnergySpark = spark

		local texture = PitBull4.Controls.MakeTexture(spark, "OVERLAY")
		spark.texture = texture
		texture:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
		texture:SetVertexColor(1, 1, 1, 0.6)
		texture:SetBlendMode("ADD")
		texture:SetAllPoints(spark)
	end

	spark:ClearAllPoints()
	local reverse = bar:GetReverse()
	if bar:GetOrientation() == "HORIZONTAL" then
		spark:SetWidth(20)
		spark:SetHeight(bar:GetHeight() * 2)
		spark.texture:SetTexCoord(0, 0, 0, 1, 1, 0, 1, 1)

		spark:SetPoint(
			"CENTER",
			bar,
			not reverse and "LEFT" or "RIGHT",
			time_since_regen * INVERSE_ENERGY_REGEN_TIME * (bar:GetWidth()) * (reverse and -1 or 1),
			0
		)
	else
		spark:SetHeight(20)
		spark:SetWidth(bar:GetWidth() * 2)
		spark.texture:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1)

		spark:SetPoint(
			"CENTER",
			bar,
			not reverse and "BOTTOM" or "TOP",
			0,
			time_since_regen * INVERSE_ENERGY_REGEN_TIME * (bar:GetHeight()) * (reverse and -1 or 1)
		)
	end

	return false
end

function PitBull4_EnergySpark:ClearFrame(frame)
	if not frame.EnergySpark then
		return false
	end

	frame.EnergySpark.texture = frame.EnergySpark.texture:Delete()
	frame.EnergySpark = frame.EnergySpark:Delete()
	return false
end

PitBull4_EnergySpark.OnHide = PitBull4_EnergySpark.ClearFrame

function PitBull4_EnergySpark:UNIT_POWER_FREQUENT(_, unit, power_type)
	if unit ~= "player" or power_type ~= "ENERGY" then return end

	local new_energy = UnitPower("player", SPELL_POWER_ENERGY)
	if new_energy > current_energy then
		last_energy_gained = GetTime()
	end
	current_energy = new_energy
end

function PitBull4_EnergySpark:UNIT_MAXPOWER(_, unit)
	if unit ~= "player" then return end

	current_energy = UnitPower("player", SPELL_POWER_ENERGY)
end

PitBull4_EnergySpark:SetLayoutOptionsFunction(function(self)
	local function disabled(info)
		return not PitBull4.Options.GetLayoutDB(self).enabled
	end

	return 'always_show', {
		type = 'toggle',
		name = L["Show when full"],
		desc = L["Show tick timer while at maximum energy."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).always_show
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).always_show = value
		end,
		disabled = disabled,
	}
end)
