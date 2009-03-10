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

function PitBull4_LeaderIcon:OnEnable()
	self:RegisterEvent("PARTY_LEADER_CHANGED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
end

function PitBull4_LeaderIcon:GetTexture(frame)
	local unit = frame.unit
	
	if unit == "player" then
		if not IsPartyLeader() then
			return nil
		end
	else
		local raid_num = unit:match("^raid(%d%d?)$")
		if raid_num then
			local _, rank = GetRaidRosterInfo(raid_num+0)
			if rank ~= 2 then
				return nil
			end
		else
			local party_num = unit:match("^party(%d)$")
			if not party_num or (party_num+0) ~= GetPartyLeaderIndex() then
				return nil
			end
		end
	end
	
	return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
end

function PitBull4_LeaderIcon:GetExampleTexture(frame)
	local unit = frame.unit
	if unit then
		if unit == "player" or unit:match("^raid(%d%d?)$") or unit:match("^party(%d)$") then
			return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
		end
		return nil
	end
	local classification = frame.classification
	if classification == "player" or classification == "raid" or classification == "party" then
		return [[Interface\GroupFrame\UI-Group-LeaderIcon]]
	end
	return nil
end

function PitBull4_LeaderIcon:GetTexCoord(frame, texture)
	return 0.1, 0.84, 0.14, 0.88
end
PitBull4_LeaderIcon.GetExampleTexCoord = PitBull4_LeaderIcon.GetTexCoord

function PitBull4_LeaderIcon:PARTY_LEADER_CHANGED()
	self:ScheduleTimer("UpdateAll", 0.1)
end
PitBull4_LeaderIcon.PARTY_MEMBERS_CHANGED = PitBull4_LeaderIcon.PARTY_LEADER_CHANGED
