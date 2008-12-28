if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_MasterLooterIcon requires PitBull4")
end

local PitBull4_MasterLooterIcon = PitBull4:NewModule("MasterLooterIcon", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_MasterLooterIcon:SetModuleType("icon")
PitBull4_MasterLooterIcon:SetName("Master Looter Icon")
PitBull4_MasterLooterIcon:SetDescription("Show an icon on the unit frame when the unit is the Master Looter.")
PitBull4_MasterLooterIcon:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_left",
	position = 1,
})

function PitBull4_MasterLooterIcon:OnEnable()
	self:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")
end

function PitBull4_MasterLooterIcon:GetTexture(frame)
	local unit = frame.unit
	
	if unit == "player" then
		local _, lootmaster = GetLootMethod()
		if lootmaster ~= 0 then
			return nil
		end
	else
		local raid_num = unit:match("^raid(%d%d?)$")
		if raid_num then
			local loot_master = select(11, GetRaidRosterInfo(raid_num+0))
			if not loot_master then
				return nil
			end
		else
			local party_num = unit:match("^party(%d)$")
			if not party_num then
				return nil
			end
			
			local _, loot_master = GetLootMethod()
			if loot_master ~= (party_num+0) then
				return nil
			end
		end
	end
	
	return [[Interface\GroupFrame\UI-Group-MasterLooter]]
end

function PitBull4_MasterLooterIcon:GetTexCoord(frame, texture)
	return 0.15, 0.9, 0.15, 0.9
end

function PitBull4_MasterLooterIcon:PARTY_LOOT_METHOD_CHANGED()
	self:ScheduleTimer("UpdateAll", 0.1)
end
PitBull4_MasterLooterIcon.PARTY_MEMBERS_CHANGED = PitBull4_MasterLooterIcon.PARTY_LOOT_METHOD_CHANGED
