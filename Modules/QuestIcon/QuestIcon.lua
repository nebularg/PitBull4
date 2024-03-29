
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_QuestIcon = PitBull4:NewModule("QuestIcon")

PitBull4_QuestIcon:SetModuleType("indicator")
PitBull4_QuestIcon:SetName(L["Quest icon"])
PitBull4_QuestIcon:SetDescription(L["Show an icon based on whether or not the unit is a quest boss."])
PitBull4_QuestIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_right",
	position = 1,
})

function PitBull4_QuestIcon:OnEnable()
	self:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
end

function PitBull4_QuestIcon:UNIT_CLASSIFICATION_CHANGED(event, unit)
	self:UpdateForUnitID(unit)
end

function PitBull4_QuestIcon:GetTexture(frame)
	if UnitIsQuestBoss(frame.unit) then
		return [[Interface\TargetingFrame\PortraitQuestBadge]]
	end
end

function PitBull4_QuestIcon:GetExampleTexture(frame)
	return [[Interface\TargetingFrame\PortraitQuestBadge]]
end
