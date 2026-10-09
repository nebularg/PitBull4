local _G = _G

local player_class = UnitClassBase("player")
if player_class ~= "DRUID" and player_class ~= "PRIEST" and player_class ~= "SHAMAN" then
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
    show_in_forms = player_class == "DRUID",
})

local EnumPowerType = _G.Enum and _G.Enum.PowerType or nil
local SPELL_POWER_MANA = EnumPowerType and EnumPowerType.Mana or 0
local SPELL_POWER_RAGE = EnumPowerType and EnumPowerType.Rage or 1
local SPELL_POWER_ENERGY = EnumPowerType and EnumPowerType.Energy or 3
local SPELL_POWER_LUNAR_POWER = EnumPowerType and (EnumPowerType.LunarPower or EnumPowerType.Eclipse) or 8

local DISPLAY_INFO = _G.ALT_POWER_BAR_PAIR_DISPLAY_INFO and _G.ALT_POWER_BAR_PAIR_DISPLAY_INFO[player_class] or {}

local UnitPowerType = _G.UnitPowerType
local UnitPower = _G.UnitPower
local UnitPowerMax = _G.UnitPowerMax
local UnitHasVehiclePlayerFrameUI = _G.UnitHasVehiclePlayerFrameUI
local unpack = _G.unpack or table.unpack
local tonumber = _G.tonumber
local type = _G.type
local pcall = _G.pcall
local format = string.format

local function safe_plain_number(value)
    if value == nil then
        return nil
    end

    local value_type = type(value)
    if value_type == "number" then
        local ok, numeric_string = pcall(format, "%.17g", value)
        if not ok or type(numeric_string) ~= "string" then
            return nil
        end
        return tonumber(numeric_string)
    elseif value_type == "string" then
        local parsed = tonumber(value)
        if parsed == nil then
            return nil
        end
        local ok, numeric_string = pcall(format, "%.17g", parsed)
        if not ok or type(numeric_string) ~= "string" then
            return nil
        end
        return tonumber(numeric_string)
    end

    return nil
end

local function refresh_units(self)
    self:UpdateForUnitID("player")
    self:UpdateForUnitID("vehicle")
end

local function should_show_alt_mana(self, frame, unit, primary_power)
    if primary_power == SPELL_POWER_MANA then
        return false
    end

    if UnitHasVehiclePlayerFrameUI and UnitHasVehiclePlayerFrameUI("player") then
        return false
    end

    if DISPLAY_INFO[primary_power] then
        return true
    end

    if player_class ~= "DRUID" then
        return false
    end

    if not self:GetLayoutDB(frame).show_in_forms then
        return false
    end

    return primary_power == SPELL_POWER_ENERGY
        or primary_power == SPELL_POWER_RAGE
        or primary_power == SPELL_POWER_LUNAR_POWER
end

function PitBull4_AltManaBar:OnEnable()
    self:RegisterEvent("UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT")
    self:RegisterEvent("UNIT_POWER_FREQUENT")
    self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER_FREQUENT")
    self:RegisterEvent("UNIT_DISPLAYPOWER", "RefreshEvent")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "RefreshEvent")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "RefreshEvent")
    self:RegisterEvent("UPDATE_SHAPESHIFT_FORMS", "RefreshEvent")
    self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
    self:RegisterEvent("PLAYER_ALIVE", "RefreshEvent")
    self:RegisterEvent("PLAYER_UNGHOST", "RefreshEvent")
end

function PitBull4_AltManaBar:RefreshEvent()
    refresh_units(self)
end

function PitBull4_AltManaBar:PLAYER_SPECIALIZATION_CHANGED(event, unit)
    if unit and unit ~= "player" then
        return
    end

    refresh_units(self)
end

function PitBull4_AltManaBar:GetExampleValue(frame)
    return 0.55
end

function PitBull4_AltManaBar:GetValue(frame)
    local unit = frame.best_unit or frame.unit
    if unit ~= "player" then
        return nil
    end

    if PitBull4.IsInConfigMode and PitBull4:IsInConfigMode() then
        return self:GetExampleValue(frame)
    end

    if PitBull4.HasRestrictedUnitData and PitBull4:HasRestrictedUnitData() then
        return nil
    end

    if PitBull4.world_ready == false then
        return nil
    end

    local primary_power = UnitPowerType(unit)
    if not should_show_alt_mana(self, frame, unit, primary_power) then
        return nil
    end

    local max_mana = safe_plain_number(UnitPowerMax(unit, SPELL_POWER_MANA))
    if not max_mana or max_mana <= 0 then
        return nil
    end

    local current_mana = safe_plain_number(UnitPower(unit, SPELL_POWER_MANA))
    if current_mana == nil then
        return nil
    end

    local value = current_mana / max_mana
    if value ~= value then
        return nil
    end

    if value < 0 then
        value = 0
    elseif value > 1 then
        value = 1
    end

    if value == 1 and self:GetLayoutDB(frame).hide_if_full then
        return nil
    end

    return value
end

function PitBull4_AltManaBar:GetRawValue(frame)
    local unit = frame.best_unit or frame.unit
    if unit ~= "player" then
        return nil, nil
    end

    if PitBull4.world_ready == false then
        return nil, nil
    end

    local primary_power = UnitPowerType(unit)
    if not should_show_alt_mana(self, frame, unit, primary_power) then
        return nil, nil
    end

    return UnitPower(unit, SPELL_POWER_MANA), UnitPowerMax(unit, SPELL_POWER_MANA)
end

function PitBull4_AltManaBar:GetColor(frame, value)
    return unpack(PitBull4.PowerColors.MANA)
end
PitBull4_AltManaBar.GetExampleColor = PitBull4_AltManaBar.GetColor

function PitBull4_AltManaBar:UNIT_POWER_FREQUENT(event, unit, power_type)
    if type(unit) ~= "string" then
        return
    end

    if unit ~= "player" and unit ~= "vehicle" then
        return
    end

    if (event == "UNIT_POWER_UPDATE" or event == "UNIT_POWER_FREQUENT" or event == "UNIT_MAXPOWER")
        and power_type and power_type ~= "MANA" then
        return
    end

    refresh_units(self)
end

PitBull4_AltManaBar:SetLayoutOptionsFunction(function(self)
    return "hide_if_full", {
        name = L["Hide if full"],
        desc = L["Hide when at 100% mana."],
        type = "toggle",
        get = function(info)
            return PitBull4.Options.GetLayoutDB(self).hide_if_full
        end,
        set = function(info, value)
            PitBull4.Options.GetLayoutDB(self).hide_if_full = value
            PitBull4.Options.UpdateFrames()
        end,
    },
    "show_in_forms", {
        name = L["Show while shifted"],
        desc = L["Show in all shapeshift forms."],
        type = "toggle",
        get = function(info)
            return PitBull4.Options.GetLayoutDB(self).show_in_forms
        end,
        set = function(info, value)
            PitBull4.Options.GetLayoutDB(self).show_in_forms = value
            PitBull4.Options.UpdateFrames()
        end,
        hidden = function()
            return player_class ~= "DRUID"
        end,
    }
end)