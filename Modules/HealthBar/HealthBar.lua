local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.8
local LIVE_FALLBACK_VALUE = 1

local CreateFrame = _G.CreateFrame
local UnitHealth = _G.UnitHealth
local UnitHealthMax = _G.UnitHealthMax
local UnitHealthPercent = _G.UnitHealthPercent
local UnitIsConnected = _G.UnitIsConnected
local UnitIsDeadOrGhost = _G.UnitIsDeadOrGhost
local UnitIsTapDenied = _G.UnitIsTapDenied
local next = _G.next
local pcall = _G.pcall
local securecallfunction = _G.securecallfunction
local tonumber = _G.tonumber
local tostring = _G.tostring
local type = _G.type
local unpack = _G.unpack or table.unpack
local wipe = _G.wipe or table.wipe
local format = string.format

local PitBull4_HealthBar = PitBull4:NewModule("HealthBar")

PitBull4_HealthBar:SetModuleType("bar")
PitBull4_HealthBar:SetName(L["Health bar"])
PitBull4_HealthBar:SetDescription(L["Show a bar indicating the unit's health."])
PitBull4_HealthBar.allow_animations = true
PitBull4_HealthBar:SetDefaults({
    position = 1,
    color_by_class = true,
    hostility_color = true,
    hostility_color_npcs = true,
}, {
    colors = {
        dead = { 0.6, 0.6, 0.6 },
        disconnected = { 0.7, 0.7, 0.7 },
        tapped = { 0.5, 0.5, 0.5 },
        max_health = { 0, 1, 0 },
        half_health = { 1, 1, 0 },
        min_health = { 1, 0, 0 },
    }
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

local units_to_update = {}

local function safe_boolean(value, default)
    if value == nil then
        return default
    end

    if type(value) == "boolean" then
        return value
    end

    local ok, text = pcall(tostring, value)
    if not ok or type(text) ~= "string" then
        return default
    end

    if text == "true" then
        return true
    elseif text == "false" then
        return false
    end

    return default
end

local function call_unit_boolean(unit, func, default)
    if not unit or type(func) ~= "function" then
        return default
    end

    if securecallfunction then
        return safe_boolean(securecallfunction(func, unit), default)
    end

    local ok, result = pcall(func, unit)
    if not ok then
        return default
    end

    return safe_boolean(result, default)
end

local function is_unit_dead_or_ghost(unit)
    return call_unit_boolean(unit, UnitIsDeadOrGhost, false)
end

local function is_unit_connected(unit)
    return call_unit_boolean(unit, UnitIsConnected, true)
end

local function is_unit_tap_denied(unit)
    return call_unit_boolean(unit, UnitIsTapDenied, false)
end

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

local function clamp_zero_to_one(value)
    local numeric = safe_plain_number(value)
    if numeric == nil or numeric ~= numeric then
        return nil
    end

    if numeric < 0 then
        return 0
    elseif numeric > 1 then
        return 1
    end

    return numeric
end

local function normalize_percent_value(raw_percent)
    local numeric = safe_plain_number(raw_percent)
    if numeric == nil then
        return nil
    end

    return clamp_zero_to_one(numeric * 0.01)
end

local function normalize_ratio_value(raw_current, raw_maximum)
    local current = safe_plain_number(raw_current)
    local maximum = safe_plain_number(raw_maximum)
    if current == nil or maximum == nil or maximum <= 0 then
        return nil
    end

    return clamp_zero_to_one(current / maximum)
end

local function get_normalized_health_percent(unit)
    if type(UnitHealthPercent) ~= "function" then
        return nil
    end

    if securecallfunction then
        return securecallfunction(function()
            return normalize_percent_value(UnitHealthPercent(unit))
        end)
    end

    local ok, normalized = pcall(function()
        return normalize_percent_value(UnitHealthPercent(unit))
    end)
    if ok then
        return normalized
    end

    return nil
end

local function get_normalized_health_ratio(unit)
    if securecallfunction then
        return securecallfunction(function()
            return normalize_ratio_value(UnitHealth(unit), UnitHealthMax(unit))
        end)
    end

    local ok, normalized = pcall(function()
        return normalize_ratio_value(UnitHealth(unit), UnitHealthMax(unit))
    end)
    if ok then
        return normalized
    end

    return nil
end

local function queue_unit_update(unit)
    if not unit then
        return
    end

    units_to_update[unit] = true
    timerFrame:Show()
end

function PitBull4_HealthBar:OnEnable()
    self:RegisterEvent("UNIT_HEALTH")
    if not PitBull4.wow_retail then
        self:RegisterEvent("UNIT_HEALTH_FREQUENT", "UNIT_HEALTH")
    end
    self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
    self:RegisterEvent("UNIT_CONNECTION", "UNIT_HEALTH")
    self:RegisterEvent("UNIT_FLAGS", "UNIT_HEALTH")
    self:RegisterEvent("PLAYER_ALIVE", "PLAYER_STATE_CHANGED")
    self:RegisterEvent("PLAYER_DEAD", "PLAYER_STATE_CHANGED")
    self:RegisterEvent("PLAYER_UNGHOST", "PLAYER_STATE_CHANGED")
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "PLAYER_STATE_CHANGED")

    self:UpdateAll()
end

function PitBull4_HealthBar:OnDisable()
    timerFrame:Hide()
    wipe(units_to_update)
end

timerFrame:SetScript("OnUpdate", function(self)
    self:Hide()

    if not next(units_to_update) then
        return
    end

    for frame in PitBull4:IterateFrames() do
        local unit = frame.best_unit or frame.unit
        if unit and units_to_update[unit] then
            PitBull4_HealthBar:Update(frame)
        end
    end

    wipe(units_to_update)
end)

local function get_health_value(unit)
    if not unit then
        return nil
    end

    if is_unit_dead_or_ghost(unit) then
        return LIVE_FALLBACK_VALUE
    end

    local normalized = get_normalized_health_percent(unit)
    if normalized ~= nil then
        return normalized
    end

    normalized = get_normalized_health_ratio(unit)
    if normalized ~= nil then
        return normalized
    end

    return LIVE_FALLBACK_VALUE
end

function PitBull4_HealthBar:GetValue(frame)
    local unit = frame.best_unit or frame.unit

    if PitBull4:IsInConfigMode() then
        return EXAMPLE_VALUE
    end

    if PitBull4.HasRestrictedUnitData and PitBull4:HasRestrictedUnitData() then
        if frame.force_show then
            return EXAMPLE_VALUE
        end

        return nil
    end

    return get_health_value(unit)
end

function PitBull4_HealthBar:GetRawValue(frame)
    local unit = frame.best_unit or frame.unit
    if not unit then
        return nil, nil
    end

    if is_unit_dead_or_ghost(unit) then
        return nil, nil
    end

    return UnitHealth(unit), UnitHealthMax(unit)
end

function PitBull4_HealthBar:GetExampleValue()
    return EXAMPLE_VALUE
end

function PitBull4_HealthBar:GetColor(frame, value)
    if PitBull4:IsInConfigMode() or (PitBull4.HasRestrictedUnitData and PitBull4:HasRestrictedUnitData()) then
        return self:GetExampleColor(frame, value)
    end

    local unit = frame.best_unit or frame.unit
    local colors = self.db.profile.global.colors

    if not unit or not is_unit_connected(unit) then
        local color = colors.disconnected
        return color[1], color[2], color[3], nil, true
    elseif is_unit_dead_or_ghost(unit) then
        local color = colors.dead
        return color[1], color[2], color[3], nil, true
    elseif is_unit_tap_denied(unit) then
        local color = colors.tapped
        return color[1], color[2], color[3], nil, true
    end

    local normalized = clamp_zero_to_one(value) or LIVE_FALLBACK_VALUE

    local high_r, high_g, high_b
    local low_r, low_g, low_b
    local gradient_value

    if normalized < 0.5 then
        high_r, high_g, high_b = unpack(colors.half_health)
        low_r, low_g, low_b = unpack(colors.min_health)
        gradient_value = normalized * 2
    else
        high_r, high_g, high_b = unpack(colors.max_health)
        low_r, low_g, low_b = unpack(colors.half_health)
        gradient_value = normalized * 2 - 1
    end

    local inverse_value = 1 - gradient_value

    return
        low_r * inverse_value + high_r * gradient_value,
        low_g * inverse_value + high_g * gradient_value,
        low_b * inverse_value + high_b * gradient_value
end

function PitBull4_HealthBar:GetExampleColor()
    return unpack(self.db.profile.global.colors.disconnected)
end

function PitBull4_HealthBar:UNIT_HEALTH(_, unit)
    if not unit then
        return
    end

    self:UpdateForUnitID(unit)
    queue_unit_update(unit)
end

function PitBull4_HealthBar:PLAYER_STATE_CHANGED()
    self:UpdateForUnitID("player")
    queue_unit_update("player")
end

PitBull4_HealthBar:SetColorOptionsFunction(function(self)
    local function get(info)
        return unpack(self.db.profile.global.colors[info[#info]])
    end

    local function set(info, r, g, b)
        local color = self.db.profile.global.colors[info[#info]]
        color[1], color[2], color[3] = r, g, b
    end

    return "dead", {
        type = "color",
        name = L["Dead"],
        get = get,
        set = set,
    },
    "disconnected", {
        type = "color",
        name = L["Disconnected"],
        get = get,
        set = set,
    },
    "tapped", {
        type = "color",
        name = L["Tapped"],
        get = get,
        set = set,
    },
    "max_health", {
        type = "color",
        name = L["Full health"],
        get = get,
        set = set,
    },
    "half_health", {
        type = "color",
        name = L["Half health"],
        get = get,
        set = set,
    },
    "min_health", {
        type = "color",
        name = L["Empty health"],
        get = get,
        set = set,
    },
    function()
        local color = self.db.profile.global.colors.dead
        color[1], color[2], color[3] = 0.6, 0.6, 0.6

        color = self.db.profile.global.colors.disconnected
        color[1], color[2], color[3] = 0.7, 0.7, 0.7

        color = self.db.profile.global.colors.tapped
        color[1], color[2], color[3] = 0.5, 0.5, 0.5

        color = self.db.profile.global.colors.max_health
        color[1], color[2], color[3] = 0, 1, 0

        color = self.db.profile.global.colors.half_health
        color[1], color[2], color[3] = 1, 1, 0

        color = self.db.profile.global.colors.min_health
        color[1], color[2], color[3] = 1, 0, 0
    end
end)
