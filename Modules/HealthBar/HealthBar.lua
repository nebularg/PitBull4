if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HealthBar requires PitBull4")
end

local EXAMPLE_VALUE = 0.8

local unpack = _G.unpack
local L = PitBull4.L

local PitBull4_HealthBar = PitBull4:NewModule("HealthBar", "AceEvent-3.0", "AceHook-3.0")

PitBull4_HealthBar:SetModuleType("bar")
PitBull4_HealthBar:SetName(L["Health bar"])
PitBull4_HealthBar:SetDescription(L["Show a bar indicating the unit's health."])
PitBull4_HealthBar.allow_animations = true
PitBull4_HealthBar:SetDefaults({
	position = 1,
	color_by_class = true,
	hostility_color = true,
	hostility_color_npcs = true,
	fast_updates = true,
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

local guids_to_update = {}
local predicted_health = true

function PitBull4_HealthBar:OnEnable()
	timerFrame:Show()
	
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH","UNIT_HEALTH")
	self:RegisterEvent("PLAYER_ALIVE")
	
	self:SecureHook("SetCVar")
	self:SetCVar()

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
	if predicted_health then
		for frame in PitBull4:IterateFrames() do
			if frame.guid and not guids_to_update[frame.guid] then
				local db = PitBull4_HealthBar:GetLayoutDB(frame)
				if db.fast_updates then
					PitBull4_HealthBar:Update(frame)
				end
			end
		end
	end
	wipe(guids_to_update)
end)

function PitBull4_HealthBar:GetValue(frame)
	local max = UnitHealthMax(frame.unit)
	if max == 0 then
		return 0
	end
	return UnitHealth(frame.unit) / max
end

function PitBull4_HealthBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

function PitBull4_HealthBar:GetColor(frame, value)
	local db = self:GetLayoutDB(frame)
	local unit = frame.unit

	if not unit or not UnitIsConnected(unit) then
		local color = self.db.profile.global.colors.disconnected
		return color[1], color[2], color[3], nil, true
	elseif UnitIsDeadOrGhost(unit) then
		local color = self.db.profile.global.colors.dead
		return color[1], color[2], color[3], nil, true
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and not UnitIsTappedByAllThreatList(unit) then
		local color = self.db.profile.global.colors.tapped
		return color[1], color[2], color[3], nil, true
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

function PitBull4_HealthBar:UNIT_HEALTH(event, unit)
	local guid = UnitGUID(unit)
	if guid then
		guids_to_update[guid] = true
	end
end

function PitBull4_HealthBar:PLAYER_ALIVE(event)
	guids_to_update[UnitGUID("player")] = true
end

function PitBull4_HealthBar:SetCVar()
	predicted_health = GetCVarBool("predictedHealth")
end

PitBull4_HealthBar:SetLayoutOptionsFunction(function(self)
	return 'fast_updates', {
		name = L['Fast updates'],
		desc = L['Update the health bar using the games predicted health method.'],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).fast_updates
		end,
		set = function(info,value)
			PitBull4.Options.GetLayoutDB(self).fast_updates = value

			PitBull4.Options.UpdateFrames()
		end
	}
end)

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
		
		local color = self.db.profile.global.colors.disconnected
		color[1], color[2], color[3] = 0.7, 0.7, 0.7
		
		local color = self.db.profile.global.colors.tapped
		color[1], color[2], color[3] = 0.5, 0.5, 0.5
		
		local color = self.db.profile.global.colors.max_health
		color[1], color[2], color[3] = 0, 1, 0
		
		local color = self.db.profile.global.colors.half_health
		color[1], color[2], color[3] = 1, 1, 0
		
		local color = self.db.profile.global.colors.min_health
		color[1], color[2], color[3] = 1, 0, 0
	end
end)
