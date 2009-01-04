if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HealthBar requires PitBull4")
end

local L = PitBull4.L

local PitBull4_HealthBar = PitBull4:NewModule("HealthBar", "AceEvent-3.0")

PitBull4_HealthBar:SetModuleType("status_bar")
PitBull4_HealthBar:SetName(L["Health bar"])
PitBull4_HealthBar:SetDescription(L["Show a bar indicating the unit's health."])
PitBull4_HealthBar:SetDefaults({
	position = 1,
	color_by_class = true,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

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
	if self:GetLayoutDB(frame).color_by_class then
		local _, class = UnitClass(frame.unit)
		local t = RAID_CLASS_COLORS[class]
		if t then
			return t.r, t.g, t.b
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
	}
end)
