
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.6

local PitBull4_ThreatBar = PitBull4:NewModule("ThreatBar", "AceEvent-3.0")

PitBull4_ThreatBar:SetModuleType("bar")
PitBull4_ThreatBar:SetName(L["Threat bar"])
PitBull4_ThreatBar:SetDescription(L["Show a threat bar."])
PitBull4_ThreatBar:SetDefaults({
	size = 1,
	position = 5,
	show_solo = false,
})

function PitBull4_ThreatBar:OnEnable()
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateAll")
	self:RegisterEvent("UNIT_THREAT_LIST_UPDATE", "UpdateAll")
	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", "UpdateAll")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterEvent("UNIT_PET")

	self:GROUP_ROSTER_UPDATE()
end

local player_in_group = false

local ACCEPTABLE_CLASSIFICATIONS = {
	player = true,
	pet = true,
	party = true,
	raid = true,
	partypet = true,
	raidpet = true,
}

local function check_classification(frame)
	local classification = frame.is_singleton and frame.unit or frame.header.unit_group
	return ACCEPTABLE_CLASSIFICATIONS[classification]
end

function PitBull4_ThreatBar:GROUP_ROSTER_UPDATE()
	player_in_group = UnitExists("pet") or IsInGroup()

	self:UpdateAll()
end

function PitBull4_ThreatBar:UNIT_PET(_, unit)
	if unit == "player" then
		self:GROUP_ROSTER_UPDATE()
	end
end

function PitBull4_ThreatBar:GetValue(frame)
	if not check_classification(frame) or (not self:GetLayoutDB(frame).show_solo and not player_in_group) then
		return nil
	end

	local _, _, scaled_percent = UnitDetailedThreatSituation(frame.unit, "target")
	if not scaled_percent then
		return nil
	end
	return scaled_percent / 100
end
function PitBull4_ThreatBar:GetExampleValue(frame)
	if frame and not check_classification(frame) then
		return nil
	end
	return EXAMPLE_VALUE
end

function PitBull4_ThreatBar:GetColor(frame, value)
	if frame.guid then
		local _, status = UnitDetailedThreatSituation(frame.unit, "target")
		return GetThreatStatusColor(status)
	end
	return GetThreatStatusColor(0)
end
function PitBull4_ThreatBar:GetExampleColor(frame, value)
	return GetThreatStatusColor(0)
end

PitBull4_ThreatBar:SetLayoutOptionsFunction(function(self)
	return "show_solo", {
		name = L["Show when solo"],
		desc = L["Show the threat bar even if you not in a group."],
		type = "toggle",
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).show_solo
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).show_solo = value
			PitBull4.Options.UpdateFrames()
		end,
	}
end)
