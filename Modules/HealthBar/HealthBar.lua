local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.8

local unpack = _G.unpack

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
	color_health_as_raid_marker = false,
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


local RAID_MARKER_COLORS = {
	[1] = { 1.0, 1.0, 0.0 },     -- Star (Yellow)
	[2] = { 1.0, 0.6, 0.0 },     -- Circle (Orange)
	[3] = { 0.8, 0.2, 1.0 },     -- Diamond (Purple)
	[4] = { 0.2, 1.0, 0.2 },     -- Triangle (Green)
	[5] = { 0.7, 0.7, 0.7 },     -- Moon (Silver/White)
	[6] = { 0.2, 0.4, 1.0 },     -- Square (Blue)
	[7] = { 1.0, 0.2, 0.2 },     -- Cross (Red)
	[8] = { 0.9, 0.9, 0.9 },     -- Skull (White/Gray)
}

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

local guids_to_update = {}
local player_guid

function PitBull4_HealthBar:OnEnable()
	player_guid = UnitGUID("player")

	timerFrame:Show()

	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
	self:RegisterEvent("UNIT_CONNECTION", "UNIT_HEALTH")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("RAID_TARGET_UPDATE")

	self:UpdateAll()
end

function PitBull4_HealthBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	for guid in pairs(guids_to_update) do
		for frame in PitBull4:IterateFramesForGUID(guid) do
			PitBull4_HealthBar:Update(frame)
		end
	end
	wipe(guids_to_update)
end)

function PitBull4_HealthBar:GetValue(frame)
	local unit = frame.unit
	local max = UnitHealthMax(unit)
	if max == 0 then
		return 0
	end
	local hp = UnitHealth(unit)
	if hp == 1 and UnitIsGhost(unit) then
		return 0
	end
	return hp / max
end

function PitBull4_HealthBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

function PitBull4_HealthBar:GetColor(frame, value)
	local unit = frame.unit
	local layout_db = self:GetLayoutDB(frame)

	if not unit or not UnitIsConnected(unit) then
		local color = self.db.profile.global.colors.disconnected
		return color[1], color[2], color[3], nil, true
	elseif UnitIsDeadOrGhost(unit) then
		local color = self.db.profile.global.colors.dead
		return color[1], color[2], color[3], nil, true
	elseif UnitIsTapDenied(unit) then
		local color = self.db.profile.global.colors.tapped
		return color[1], color[2], color[3], nil, true
	end


	if layout_db.color_health_as_raid_marker then
		local raidTargetIndex = GetRaidTargetIndex(unit)
		if raidTargetIndex and RAID_MARKER_COLORS[raidTargetIndex] then
			local color = RAID_MARKER_COLORS[raidTargetIndex]
			return color[1], color[2], color[3], nil, true
		end
	end

	local high_r, high_g, high_b
	local low_r, low_g, low_b
	local colors = self.db.profile.global.colors
	local normalized_value
	if value < 0.5 then
		high_r, high_g, high_b = unpack(colors.half_health)
		low_r, low_g, low_b = unpack(colors.min_health)
		normalized_value = value * 2
	else
		high_r, high_g, high_b = unpack(colors.max_health)
		low_r, low_g, low_b = unpack(colors.half_health)
		normalized_value = value * 2 - 1
	end

	local inverse_value = 1 - normalized_value

	return
		low_r * inverse_value + high_r * normalized_value,
		low_g * inverse_value + high_g * normalized_value,
		low_b * inverse_value + high_b * normalized_value
end

function PitBull4_HealthBar:GetExampleColor(frame, value)
	return unpack(self.db.profile.global.colors.disconnected)
end

function PitBull4_HealthBar:UNIT_HEALTH(_, unit)
	local guid = unit and UnitGUID(unit)
	if guid then
		guids_to_update[guid] = true
	end
end

function PitBull4_HealthBar:RAID_TARGET_UPDATE()

	for frame in PitBull4:IterateFrames() do
		if frame.unit then
			self:Update(frame)
		end
	end
end

function PitBull4_HealthBar:PLAYER_ALIVE()
	guids_to_update[player_guid] = true
end

PitBull4_HealthBar:SetColorOptionsFunction(function(self)
	local function get(info)
		return unpack(self.db.profile.global.colors[info[#info]])
	end
	local function set(info, r, g, b)
		local color = self.db.profile.global.colors[info[#info]]
		color[1], color[2], color[3] = r, g, b
	end
	return 'dead', {
		type = 'color',
		name = L["Dead"],
		get = get,
		set = set,
	},
	'disconnected', {
		type = 'color',
		name = L["Disconnected"],
		get = get,
		set = set,
	},
	'tapped', {
		type = 'color',
		name = L["Tapped"],
		get = get,
		set = set,
	},
	'max_health', {
		type = 'color',
		name = L["Full health"],
		get = get,
		set = set,
	},
	'half_health', {
		type = 'color',
		name = L["Half health"],
		get = get,
		set = set,
	},
	'min_health', {
		type = 'color',
		name = L["Empty health"],
		get = get,
		set = set,
	},
	function(info)
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


PitBull4_HealthBar:SetLayoutOptionsFunction(function(self)
	return 'color_health_as_raid_marker', {
		type = 'toggle',
		name = L["Color Health as Raid Marker"] or "Color Health as Raid Marker",
		desc = L["Color the health bar based on the unit's raid target marker instead of health percentage"] or "Color the health bar based on the unit's raid target marker instead of health percentage",
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).color_health_as_raid_marker
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).color_health_as_raid_marker = value
			
			for frame in PitBull4:IterateFrames() do
				if frame.unit then
					self:Update(frame)
				end
			end
		end,
		order = 100,
	}
end)