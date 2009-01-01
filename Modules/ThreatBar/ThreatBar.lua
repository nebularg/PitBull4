if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ThreatBar requires PitBull4")
end

local PitBull4_ThreatBar = PitBull4:NewModule("ThreatBar", "AceEvent-3.0")

PitBull4_ThreatBar:SetModuleType("status_bar")
PitBull4_ThreatBar:SetName("Threat Bar")
PitBull4_ThreatBar:SetDescription("Show a threat bar.")
PitBull4_ThreatBar:SetDefaults({
	size = 1,
	position = 5,
})

function PitBull4_ThreatBar:OnEnable()
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_THREAT_LIST_UPDATE")
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE")
end

local ACCEPTABLE_CLASSIFICATIONS = {
	player = true,
	pet = true,
	party = true,
	raid = true,
	partypet = true,
	raidpet = true,
}

function PitBull4_ThreatBar:GetValue(frame)
	if not ACCEPTABLE_CLASSIFICATIONS[frame.classification] then
		return nil
	end
	unit = frame.unit
    
	local _,_,threatpct = UnitDetailedThreatSituation(unit, "target")
       
	if not threatpct then
		return nil
	end
    
	return threatpct / 100
end

function PitBull4_ThreatBar:GetColor(frame, value)
	local _, status = UnitDetailedThreatSituation(frame.unit, "target")
	
	return GetThreatStatusColor(status)
end

function PitBull4_ThreatBar:PLAYER_TARGET_CHANGED()
	self:UpdateAll()
end

PitBull4_ThreatBar.UNIT_THREAT_LIST_UPDATE = PitBull4_ThreatBar.PLAYER_TARGET_CHANGED
PitBull4_ThreatBar.UNIT_THREAT_SITUATION_UPDATE = PitBull4_ThreatBar.PLAYER_TARGET_CHANGED