local player_class = UnitClassBase("player")
if player_class == "WARRIOR" or player_class == "ROGUE" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_ManaSpark = PitBull4:NewModule("ManaSpark")

PitBull4_ManaSpark:SetModuleType("custom")
PitBull4_ManaSpark:SetName(L["Mana spark"])
PitBull4_ManaSpark:SetDescription(L["Show the spellcasting five-second rule."])
PitBull4_ManaSpark:SetDefaults({})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

timerFrame:SetScript("OnUpdate", function()
	PitBull4_ManaSpark:UpdateForUnitID("player")
end)

local SPELL_POWER_MANA = Enum.PowerType.Mana
local MANA_REGEN_TIME = 5
local INVERSE_MANA_REGEN_TIME = 1 / MANA_REGEN_TIME

local current_mana = 0
local last_spellcast = 0
local last_mana_lost = 0
local spellcast_finish_time = 0

function PitBull4_ManaSpark:OnEnable()
	timerFrame:Show()

	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "player")
	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "player")
	self:RegisterUnitEvent("UNIT_MAXPOWER", nil, "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "UNIT_MAXPOWER", "player")

	current_mana = UnitPower("player", SPELL_POWER_MANA)
end

function PitBull4_ManaSpark:OnDisable()
	timerFrame:Hide()
end

function PitBull4_ManaSpark:UpdateFrame(frame)
	if frame.unit ~= "player" then
		return self:ClearFrame(frame)
	end

	local bar = frame.DruidManaBar
	if not bar then
		bar = frame.PowerBar
		if not bar or UnitPowerType("player") ~= SPELL_POWER_MANA then
			return self:ClearFrame(frame)
		end
	end

	if UnitPower("player", SPELL_POWER_MANA) == UnitPowerMax("player", SPELL_POWER_MANA) then
		return self:ClearFrame(frame)
	end

	local time_since_spellcast = GetTime() - spellcast_finish_time
	if time_since_spellcast > MANA_REGEN_TIME then
		return self:ClearFrame(frame)
	end

	local spark = frame.ManaSpark
	if not spark then
		spark = PitBull4.Controls.MakeFrame(frame.overlay)
		frame.ManaSpark = spark

		local texture = PitBull4.Controls.MakeTexture(spark, "OVERLAY")
		spark.texture = texture
		texture:SetTexture([[Interface\CastingBar\UI-CastingBar-Spark]])
		texture:SetVertexColor(1, 1, 1, 0.6)
		texture:SetBlendMode('ADD')
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
			time_since_spellcast * INVERSE_MANA_REGEN_TIME * (bar:GetWidth() - 1) * (reverse and -1 or 1),
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
			time_since_spellcast * INVERSE_MANA_REGEN_TIME * (bar:GetHeight() - 1) * (reverse and -1 or 1)
		)
	end

	return false
end

function PitBull4_ManaSpark:ClearFrame(frame)
	if not frame.ManaSpark then
		return false
	end

	frame.ManaSpark.texture = frame.ManaSpark.texture:Delete()
	frame.ManaSpark = frame.ManaSpark:Delete()
	return false
end

PitBull4_ManaSpark.OnHide = PitBull4_ManaSpark.ClearFrame

function PitBull4_ManaSpark:UNIT_MAXPOWER(_, unit)
	if unit ~= "player" then return end

	current_mana = UnitPower("player", SPELL_POWER_MANA)
end

function PitBull4_ManaSpark:UNIT_POWER_FREQUENT(_, unit, power_type)
	if unit ~= "player" or power_type ~= "MANA" then return end

	-- the mana spent tick happens right before U_S_S now so we need to record
	-- when mana is spent and compare that to when the last cast ended to know
	-- we should start the timer.
	local new_mana = UnitPower("player", SPELL_POWER_MANA)
	if new_mana < current_mana then
		last_mana_lost = GetTime()
	end
	if last_spellcast > 0 and last_spellcast - last_mana_lost < 0.5 then
		spellcast_finish_time = last_spellcast
		last_spellcast = 0
	end
	current_mana = new_mana
end

function PitBull4_ManaSpark:UNIT_SPELLCAST_SUCCEEDED(_, unit)
	if unit ~= "player" then return end

	last_spellcast = GetTime()
end

PitBull4_ManaSpark:SetLayoutOptionsFunction(function(self) end)
