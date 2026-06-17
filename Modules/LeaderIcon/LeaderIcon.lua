
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_LeaderIcon = PitBull4:NewModule("LeaderIcon")

PitBull4_LeaderIcon:SetModuleType("indicator")
PitBull4_LeaderIcon:SetName(L["Leader icon"])
PitBull4_LeaderIcon:SetDescription(L["Show an icon on the unit frame when the unit is the group leader."])
PitBull4_LeaderIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
})

local function get_frame_unit(frame)
	return frame.best_unit or frame.unit
end

function PitBull4_LeaderIcon:OnEnable()
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED")
end

function PitBull4_LeaderIcon:GetTexture(frame)
	local unit = get_frame_unit(frame)
	if unit and UnitExists(unit) and UnitIsGroupLeader(unit) then
		return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
	end
end

function PitBull4_LeaderIcon:GetExampleTexture(frame)
	return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
end

function PitBull4_LeaderIcon:GetTexCoord(frame, texture)
	return 0.1, 0.84, 0.14, 0.88
end
PitBull4_LeaderIcon.GetExampleTexCoord = PitBull4_LeaderIcon.GetTexCoord

function PitBull4_LeaderIcon:PARTY_LEADER_CHANGED()
	self:ScheduleTimer(function()
		PitBull4_LeaderIcon:UpdateAll()
	end, 0.1)
end
