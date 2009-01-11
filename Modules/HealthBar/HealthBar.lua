if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HealthBar requires PitBull4")
end

local unpack = _G.unpack
local L = PitBull4.L

local PitBull4_HealthBar = PitBull4:NewModule("HealthBar", "AceEvent-3.0")

PitBull4_HealthBar:SetModuleType("status_bar")
PitBull4_HealthBar:SetName(L["Health bar"])
PitBull4_HealthBar:SetDescription(L["Show a bar indicating the unit's health."])
PitBull4_HealthBar:SetDefaults({
	position = 1,
	color_by_class = true,
	hostility_color = true,
	hostility_color_npcs = true
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

local color_constants = {
	unknown = { 0.8, 0.8, 0.8 },
	hostile = { 226/255, 45/255, 75/255 },
	neutral = { 1, 1, 34/255 },
	friendly = { 0.2, 0.8, 0.15 },
	civilian = { 48/255, 113/255, 191/255 },
	dead = { 0.6, 0.6, 0.6 },
	disconnected = { 0.7, 0.7, 0.7 },
	tapped = { 0.5, 0.5, 0.5 }
}

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
		return unpack(color_constants.disconnected)
	elseif UnitIsDeadOrGhost(unit) then
		return unpack(color_constants.dead)
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		return unpack(color_constants.tapped)
	elseif UnitIsPlayer(unit) then
		if db.color_by_class and unit then
			local _, class = UnitClass(unit)
			local t = RAID_CLASS_COLORS[class]
			if t then
				return t.r, t.g, t.b
			end
		elseif db.hostility_color then
			if UnitCanAttack(unit, "player") then
				-- they can attack me
				if UnitCanAttack("player", unit) then
					-- and I can attack them
					return unpack(color_constants.hostile)
				else
					-- but I can't attack them
					return unpack(color_constants.civilian)
				end
			elseif UnitCanAttack("player", unit) then
				-- they can't attack me, but I can attack them
				return unpack(color_constants.neutral)
			elseif UnitIsFriend("player", unit) then
				-- on my team
				return unpack(color_constants.friendly)
			else
				-- either enemy or friend, no violence
				return unpack(color_constants.civilian)
			end
		end
	elseif db.hostility_color_npcs then
		local reaction = UnitReaction(unit, "player")
		if reaction then
			if reaction >= 5 then
				return unpack(color_constants.friendly)
			elseif reaction == 4 then
				return unpack(color_constants.neutral)
			else
				return unpack(color_constants.hostile)
			end
		else
			return unpack(color_constants.unknown)
		end
	end
	if value < 0.5 then
		return
			1,
			value * 2,
			0
	else
		return
			(1 - value) * 2,
			1,
			0
	end
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
		desc = L["Color the health bar by hostility for NPCs.  Note that color by class takes precedence over this."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).hostility_color_npcs
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).hostility_colori_npcs = value

			PitBull4.Options.UpdateFrames()
		end,
	}
end)
