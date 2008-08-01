if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_LeaderIcon requires PitBull4")
end

local L = PitBull4.L

local PitBull4_LeaderIcon = PitBull4:NewModule("LeaderIcon", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_LeaderIcon:SetModuleType("indicator")
PitBull4_LeaderIcon:SetName(L["Leader icon"])
PitBull4_LeaderIcon:SetDescription(L["Show an icon on the unit frame when the unit is the group leader."])
PitBull4_LeaderIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
})

local leader_guid

function PitBull4_LeaderIcon:OnEnable()
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "PARTY_LEADER_CHANGED")
end

function PitBull4_LeaderIcon:GetTexture(frame)
	if frame.guid == leader_guid then
		return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
	else
		return nil
	end
end

function PitBull4_LeaderIcon:GetExampleTexture(frame)
	return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
end

function PitBull4_LeaderIcon:GetTexCoord(frame, texture)
	return 0.1, 0.84, 0.14, 0.88
end
PitBull4_LeaderIcon.GetExampleTexCoord = PitBull4_LeaderIcon.GetTexCoord

local function update_leader_guid()
	local group_size = GetNumGroupMembers()
	if group_size > 0 then
		if UnitIsGroupLeader("player") then
			-- player is the leader
			leader_guid = UnitGUID("player")
		else
			local group_unit_prefix = IsInRaid() and "raid" or "party"
			for i = 1, group_size do
				local unit = group_unit_prefix..i
				if UnitIsGroupLeader(unit) then
					leader_guid = UnitGUID(unit)
					break
				end
			end
		end
	else
		-- not in a raid or a party
		leader_guid = nil
	end
	PitBull4_LeaderIcon:UpdateAll()
end

function PitBull4_LeaderIcon:PARTY_LEADER_CHANGED()
	self:ScheduleTimer(update_leader_guid, 0.1)
end
