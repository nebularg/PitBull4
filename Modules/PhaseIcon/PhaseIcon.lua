
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_PhaseIcon = PitBull4:NewModule("PhaseIcon")

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
	self:RegisterEvent("PARTY_MEMBER_DISABLE", "PARTY_MEMBER_ENABLE")
end


function PitBull4_PhaseIcon:GetTexture(frame)
	local unit = frame.unit
	if not unit then return end

	if not unit or not UnitExists(unit) or not UnitIsConnected(unit) then
		return nil
	end

	-- Note the UnitInPhase function doesn't work for pets.
	if not UnitIsPlayer(unit) then
		if unit == "pet" then
			unit = "player"
		elseif unit:sub(-3) == "pet" then
			unit = unit:gsub("pet$", "")
		else
			return nil
		end
	end

	if UnitInPhase(unit) then
		return nil
	end

	return [[Interface\TargetingFrame\UI-PhasingIcon]]
end

function PitBull4_PhaseIcon:GetExampleTexture(frame)
	return [[Interface\TargetingFrame\UI-PhasingIcon]]
end

function PitBull4_PhaseIcon:UNIT_PHASE(_, unit)
	-- UNIT_PHASE fires for some units at different points than for others.
	-- So we update by GUID rather than by unit id to increase accuracy
	self:UpdateForGUID(UnitGUID(unit))
end

function PitBull4_PhaseIcon:PARTY_MEMBER_ENABLE(_, unit)
	self:UpdateAll()
end
