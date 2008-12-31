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

function PitBull4_ThreatBar:GetValue(frame)
    unit = frame.unit 
    
    if unit == "player" or unit == "pet" then
        local _,_,threatpct,_,_ = UnitDetailedThreatSituation(unit, "target");
        
        if threatpct ~= nil then
            threatpct = tonumber(string.format("%.0f", threatpct)) / 100
            return threatpct
        end
    end
    
    return nil
    
end

function PitBull4_ThreatBar:GetColor(frame, value)
    return value, 0, 0
end

function PitBull4_ThreatBar:PLAYER_TARGET_CHANGED()
    self:UpdateAll()
end


PitBull4_ThreatBar.UNIT_THREAT_LIST_UPDATE = PitBull4_ThreatBar.PLAYER_TARGET_CHANGED
PitBull4_ThreatBar.UNIT_THREAT_SITUATION_UPDATE = PitBull4_ThreatBar.PLAYER_TARGET_CHANGED