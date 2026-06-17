
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.6
local PowerBarColor = _G.PowerBarColor
local securecallfunction = _G.securecallfunction

local PitBull4_PowerBar = PitBull4:NewModule("PowerBar")

PitBull4_PowerBar:SetModuleType("bar")
PitBull4_PowerBar:SetName(L["Power bar"])
PitBull4_PowerBar:SetDescription(L["Show a bar for your primary resource."])
PitBull4_PowerBar.allow_animations = true
PitBull4_PowerBar:SetDefaults({
	position = 2,
	hide_no_mana = false,
	hide_no_power = false,
	use_atlas = false,
})

local units_to_update = {}
local type_to_token = {
	"MANA", "RAGE", "FOCUS", "ENERGY", "CHI",
	"RUNES", "RUNIC_POWER", "SOUL_SHARDS", "LUNAR_POWER",
	"HOLY_POWER", "MAELSTROM", "INSANITY", "FURY", "PAIN"
}
local power_bar_atlas = {}
for power_token, info in next, PowerBarColor do
	if info.atlas then
		power_bar_atlas[power_token] = info.atlas
	end
end

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

local function to_safe_number(value)
	if value == nil then
		return nil
	end
	local ok_string, string_value = pcall(tostring, value)
	if not ok_string or type(string_value) ~= "string" then
		return nil
	end
	return tonumber(string_value)
end

function PitBull4_PowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("UNIT_POWER_BAR_SHOW", "UNIT_DISPLAYPOWER")
	self:RegisterEvent("UNIT_POWER_BAR_HIDE", "UNIT_DISPLAYPOWER")

	timerFrame:Show()
end

function PitBull4_PowerBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	if next(units_to_update) then
		for frame in PitBull4:IterateFrames() do
			local unit = frame.best_unit or frame.unit
			if unit and units_to_update[unit] then
				PitBull4_PowerBar:Update(frame)
			end
		end
		wipe(units_to_update)
	end
end)

local function get_power_value(unit, hide_no_mana, hide_no_power)
	local ok, result = pcall(function()
		local max = to_safe_number(UnitPowerMax(unit))
		local power_type = UnitPowerType(unit)

		if hide_no_mana and power_type ~= 0 then
			return nil
		elseif hide_no_power and (not max or max <= 0) then
			return nil
		end

		if not max then
			return nil
		end
		if max == 0 then
			return 0
		end

		local current = to_safe_number(UnitPower(unit))
		if not current then
			return nil
		end
		local value = current / max
		if value < 0 then
			return 0
		elseif value > 1 then
			return 1
		end
		return value
	end)
	if ok then
		return result
	end
	return nil
end

function PitBull4_PowerBar:GetValue(frame)
	if PitBull4:IsInConfigMode() then
		return EXAMPLE_VALUE
	end

	if PitBull4.HasRestrictedUnitData and PitBull4:HasRestrictedUnitData() then
		if frame.force_show then
			return EXAMPLE_VALUE
		end
		return nil
	end

	local unit = frame.best_unit or frame.unit
	local layout_db = self:GetLayoutDB(frame)
	return get_power_value(unit, layout_db.hide_no_mana, layout_db.hide_no_power)
end

function PitBull4_PowerBar:GetRawValue(frame)
	local unit = frame.best_unit or frame.unit
	if not unit then
		return nil, nil
	end
	local power_type = UnitPowerType(unit)
	if self:GetLayoutDB(frame).hide_no_mana and power_type ~= 0 then
		return nil, nil
	end
	return UnitPower(unit, power_type), UnitPowerMax(unit, power_type)
end

function PitBull4_PowerBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

local function get_unit_power_type(unit)
	return UnitPowerType(unit)
end

function PitBull4_PowerBar:GetColor(frame, value)
	if PitBull4:IsInConfigMode() or (PitBull4.HasRestrictedUnitData and PitBull4:HasRestrictedUnitData()) then
		return self:GetExampleColor(frame)
	end

	local unit = frame.best_unit or frame.unit
	local power_type, power_token, r, g, b
	if securecallfunction then
		power_type, power_token, r, g, b = securecallfunction(get_unit_power_type, unit)
	else
		power_type, power_token, r, g, b = get_unit_power_type(unit)
	end
	local color = PitBull4.PowerColors[power_token]

	if not color then
		if not r then
			color = PitBull4.PowerColors[type_to_token[power_type]] or PitBull4.PowerColors.MANA
			r, g, b = color[1], color[2], color[3]
		end
	else
		r, g, b = color[1], color[2], color[3]
	end

	return r, g, b, nil, nil, self:GetLayoutDB(frame).use_atlas and power_bar_atlas[power_token]
end
function PitBull4_PowerBar:GetExampleColor(frame)
	return unpack(PitBull4.PowerColors.MANA)
end

function PitBull4_PowerBar:UNIT_POWER_FREQUENT(event, unit, power_type)
	if not unit then return end
	self:UpdateForUnitID(unit)
	local _, power_token = UnitPowerType(unit)
	-- fix units that have a special power type but update as ENERGY
	if not PowerBarColor[power_token] then
		power_token = "ENERGY"
	end
	if power_token == power_type then
		units_to_update[unit] = true
	end
end

function PitBull4_PowerBar:PLAYER_ENTERING_WORLD()
	self:UpdateAll()
end

function PitBull4_PowerBar:UNIT_DISPLAYPOWER(event, unit)
	if type(unit) ~= "string" then
		return
	end
	self:UpdateForUnitID(unit)
	units_to_update[unit] = true
end

PitBull4_PowerBar:SetLayoutOptionsFunction(function(self)
	local function get(info)
		return PitBull4.Options.GetLayoutDB(self)[info[#info]]
	end
	local function set(info, value)
		PitBull4.Options.GetLayoutDB(self)[info[#info]] = value
		PitBull4.Options.UpdateFrames()
	end

	return 'hide_no_mana', {
		name = L["Hide non-mana"],
		desc = L["Hides the power bar if the unit's current power is not mana."],
		type = "toggle",
		get = get,
		set = set,
	}, 'hide_no_power', {
		name = L["Hide non-power"],
		desc = L["Hides the power bar if the unit has no power."],
		type = "toggle",
		get = get,
		set = set,
	}, 'use_atlas', {
		name = L["Use power texture"],
		desc = L["Use the provided power-specific texture if available instead of the set texture."],
		type = "toggle",
		get = get,
		set = set,
	}
end)
