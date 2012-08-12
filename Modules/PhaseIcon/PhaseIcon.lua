if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_PhaseIcon requires PitBull4")
end

local L = PitBull4.L

local PitBull4_PhaseIcon = PitBull4:NewModule("PhaseIcon", "AceEvent-3.0")

PitBull4_PhaseIcon:SetModuleType("indicator")
PitBull4_PhaseIcon:SetName(L["Phase icon"])
PitBull4_PhaseIcon:SetDescription(L["Show an icon on the unit frame if the unit is out of phase with you."])
PitBull4_PhaseIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
})

function PitBull4_PhaseIcon:OnEnable()
	self:RegisterEvent("UNIT_PHASE")
	self:RegisterEvent("PARTY_MEMBER_ENABLE")
	self:RegisterEvent("PARTY_MEMBER_DISABLE","PARTY_MEMBER_ENABLE")
end


function PitBull4_PhaseIcon:GetTexture(frame)
	local unit = frame.unit
	-- Note the UnitInPhase function doesn't work for pets.
	if not unit or not UnitIsPlayer(unit) or UnitInPhase(unit) or not UnitExists(unit) then
		return nil
	end
	
	return [[Interface\TargetingFrame\UI-PhasingIcon]]
end

function PitBull4_PhaseIcon:GetExampleTexture(frame)
	return [[Interface\TargetingFrame\UI-PhasingIcon]]
end

function PitBull4_PhaseIcon:UNIT_PHASE(event, unit)
	-- UNIT_PHASE fires for some units at different points than for others. 
	-- So we update by GUID rather than by unit id to increase accuracy
	self:UpdateForGUID(UnitGUID(unit))
end

function PitBull4_PhaseIcon:PARTY_MEMBER_ENABLE(event, unit)
	self:UpdateAll()
end
