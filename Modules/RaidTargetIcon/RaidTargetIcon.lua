local _G = _G

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local GetRaidTargetIndex = _G.GetRaidTargetIndex
local UnitExists = _G.UnitExists
local scrub = _G.scrub
local scrubsecretvalues = _G.scrubsecretvalues
local issecretvalue = _G.issecretvalue

local MAX_RAID_TARGET_ICONS = 8
local RAID_TARGET_ICON_BASE_TEXTURE = [[Interface\TargetingFrame\UI-RaidTargetingIcon_]]

local RAID_TARGET_ICON_TEXTURES = {
    [1] = RAID_TARGET_ICON_BASE_TEXTURE .. "1",
    [2] = RAID_TARGET_ICON_BASE_TEXTURE .. "2",
    [3] = RAID_TARGET_ICON_BASE_TEXTURE .. "3",
    [4] = RAID_TARGET_ICON_BASE_TEXTURE .. "4",
    [5] = RAID_TARGET_ICON_BASE_TEXTURE .. "5",
    [6] = RAID_TARGET_ICON_BASE_TEXTURE .. "6",
    [7] = RAID_TARGET_ICON_BASE_TEXTURE .. "7",
    [8] = RAID_TARGET_ICON_BASE_TEXTURE .. "8",
}

local PitBull4_RaidTargetIcon = PitBull4:NewModule("RaidTargetIcon")

PitBull4_RaidTargetIcon:SetModuleType("indicator")
PitBull4_RaidTargetIcon:SetName(L["Raid target icon"])
PitBull4_RaidTargetIcon:SetDescription(L["Show an icon on the unit frame based on which Raid Target it is."])
PitBull4_RaidTargetIcon:SetDefaults({
    attach_to = "root",
    location = "edge_top",
    position = 1,
    [1] = true, -- Star
    [2] = true, -- Circle
    [3] = true, -- Diamond
    [4] = true, -- Triangle
    [5] = true, -- Moon
    [6] = true, -- Square
    [7] = true, -- Cross
    [8] = true, -- Skull
})

local function IsSecretValue(value)
    if issecretvalue then
        return issecretvalue(value)
    end

    return false
end

local function ScrubSecretValue(value)
    if scrub then
        return scrub(value)
    end

    if scrubsecretvalues then
        return scrubsecretvalues(value)
    end

    if IsSecretValue(value) then
        return nil
    end

    return value
end

local function IsValidRaidTargetIndex(index)
    return type(index) == "number" and index >= 1 and index <= MAX_RAID_TARGET_ICONS
end

local function GetPublicRaidTargetIndex(unit)
    if not GetRaidTargetIndex or not unit then
        return nil
    end

    if UnitExists and not UnitExists(unit) then
        return nil
    end

    local index = GetRaidTargetIndex(unit)

    -- Midnight-safe handling:
    -- GetRaidTargetIndex has SecretReturns. Do not use a secret result for:
    -- table keys, string concatenation, comparisons, texture paths, or texcoords.
    index = ScrubSecretValue(index)

    if not IsValidRaidTargetIndex(index) then
        return nil
    end

    return index
end

local function LayoutAllowsRaidTargetIcon(module, frame, index)
    local db = module:GetLayoutDB(frame)
    return db and db[index]
end

function PitBull4_RaidTargetIcon:OnEnable()
    self:RegisterEvent("RAID_TARGET_UPDATE")
    self:RegisterEvent("GROUP_ROSTER_UPDATE")
end

function PitBull4_RaidTargetIcon:GetTexture(frame)
    local unit = frame and frame.unit
    local index = GetPublicRaidTargetIndex(unit)

    if not index then
        return nil
    end

    if not LayoutAllowsRaidTargetIcon(self, frame, index) then
        return nil
    end

    return RAID_TARGET_ICON_TEXTURES[index]
end

function PitBull4_RaidTargetIcon:GetExampleTexture(frame)
    local unit = frame.unit or frame:GetName() or ""

    local index = unit:match(".*(%d+)")
    if index then
        index = index + 0
    else
        index = 0
    end

    index = index + #unit + (unit:byte() or 0)
    index = (index % MAX_RAID_TARGET_ICONS) + 1

    if not LayoutAllowsRaidTargetIcon(self, frame, index) then
        return nil
    end

    return RAID_TARGET_ICON_TEXTURES[index]
end

function PitBull4_RaidTargetIcon:RAID_TARGET_UPDATE()
    self:UpdateAll()
end

function PitBull4_RaidTargetIcon:GROUP_ROSTER_UPDATE()
    self:ScheduleTimer("UpdateAll", 0.1)
end

PitBull4_RaidTargetIcon:SetLayoutOptionsFunction(function(self)
    local function get(info)
        return PitBull4.Options.GetLayoutDB(self)[info[#info] + 0]
    end

    local function set(info, value)
        PitBull4.Options.GetLayoutDB(self)[info[#info] + 0] = value
        PitBull4.Options.UpdateFrames()
    end

    return '1', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:0:64:0:64|t |cfffff200]] .. RAID_TARGET_1,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }, '2', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:64:128:0:64|t |cfff99100]] .. RAID_TARGET_2,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }, '3', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:128:192:0:64|t |cffd338e5]] .. RAID_TARGET_3,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }, '4', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:192:256:0:64|t |cff0af200]] .. RAID_TARGET_4,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }, '5', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:0:64:64:128|t |cffb2d1df]] .. RAID_TARGET_5,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }, '6', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:64:128:64:128|t |cff00b5ff]] .. RAID_TARGET_6,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }, '7', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:128:192:64:128|t |cffff3d2a]] .. RAID_TARGET_7,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }, '8', {
        type = 'toggle',
        name = [[|TInterface\TargetingFrame\UI-RaidTargetingIcons:0:0:0:0:256:256:192:256:64:128|t |cfff9f9f9]] .. RAID_TARGET_8,
        desc = L["Show this raid target icon for this layout."],
        get = get,
        set = set,
    }
end)