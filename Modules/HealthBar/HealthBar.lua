if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HealthBar requires PitBull4")
end

local unpack = _G.unpack
local L = PitBull4.L

local PitBull4_HealthBar = PitBull4:NewModule("HealthBar", "AceEvent-3.0")

PitBull4_HealthBar:SetModuleType("bar")
PitBull4_HealthBar:SetName(L["Health bar"])
PitBull4_HealthBar:SetDescription(L["Show a bar indicating the unit's health."])
PitBull4_HealthBar:SetDefaults({
	position = 1,
	color_by_class = true,
	hostility_color = true,
	hostility_color_npcs = true
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

local HOSTILE_REACTION = 2
local NEUTRAL_REACTION = 4
local FRIENDLY_REACTION = 5

local PLAYER_GUID
function PitBull4_HealthBar:OnEnable()
	PLAYER_GUID = UnitGUID("player")
	timerFrame:Show()
	
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
	
	self:UpdateAll()
end

function PitBull4_HealthBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	for frame in PitBull4:IterateFramesForGUIDs(PLAYER_GUID, UnitGUID("pet")) do
		PitBull4_HealthBar:Update(frame)
	end
end)

function PitBull4_HealthBar:GetValue(frame)
	return UnitHealth(frame.unit) / UnitHealthMax(frame.unit)
end

function PitBull4_HealthBar:GetExampleValue(frame)
	return 0.8
end

function PitBull4_HealthBar:GetColor(frame, value)
	local db = self:GetLayoutDB(frame)
	local unit = frame.unit
	if not UnitIsConnected(unit) then
		return unpack(self.db.profile.global.colors.disconnected)
	elseif UnitIsDeadOrGhost(unit) then
		return unpack(self.db.profile.global.colors.dead)
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		return unpack(self.db.profile.global.colors.tapped)
	elseif UnitIsPlayer(unit) then
		if db.color_by_class and unit then
			local _, class = UnitClass(unit)
			local t = PitBull4.ClassColors[class]
			if t then
				return t[1], t[2], t[3]
			end
		elseif db.hostility_color then
			if UnitCanAttack(unit, "player") then
				-- they can attack me
				if UnitCanAttack("player", unit) then
					-- and I can attack them
					return unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
				else
					-- but I can't attack them
					return unpack(PitBull4.ReactionColors.civilian)
				end
			elseif UnitCanAttack("player", unit) then
				-- they can't attack me, but I can attack them
				return unpack(PitBull4.ReactionColors[NEUTRAL_REACTION])
			elseif UnitIsFriend("player", unit) then
				-- on my team
				return unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
			else
				-- either enemy or friend, no violence
				return unpack(PitBull4.ReactionColors.civilian)
			end
		end
	elseif db.hostility_color_npcs then
		local reaction = UnitReaction(unit, "player")
		if reaction then
			if reaction >= 5 then
				return unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
			elseif reaction == 4 then
				return unpack(PitBull4.ReactionColors[NEUTRAL_REACTION])
			else
				return unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
			end
		else
			if UnitIsFriend("player", unit) then
				return unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
			elseif UnitIsEnemy("player", unit) then
				return unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
			else
				return nil
			end
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

function PitBull4_HealthBar:UNIT_HEALTH(event, unit)
	self:UpdateForUnitID(unit)
end

PitBull4_HealthBar:SetLayoutOptionsFunction(function(self)
	return 'color_by_class', {
		name = L["Color by class"],
		desc = L["Color the health bar by unit class"],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).color_by_class
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).color_by_class = value
			
			PitBull4.Options.UpdateFrames()
		end
	}, 'hostility_color', {
		name = L["Color by hostility"],
		desc = L["Color the health bar by hostility.  Note that color by class takes precedence over this."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).hostility_color
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).hostility_color = value

			PitBull4.Options.UpdateFrames()
		end,
	}, 'hostility_color_npcs', {
		name = L["Color NPCs by hostility"],
		desc = L["Color the health bar by hostility for NPCs."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).hostility_color_npcs
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).hostility_color_npcs = value

			PitBull4.Options.UpdateFrames()
		end,
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
