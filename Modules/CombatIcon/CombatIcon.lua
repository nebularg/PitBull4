
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_CombatIcon = PitBull4:NewModule("CombatIcon")

PitBull4_CombatIcon:SetModuleType("indicator")
PitBull4_CombatIcon:SetName(L["Combat icon"])
PitBull4_CombatIcon:SetDescription(L["Show an icon based on whether or not the unit is in combat."])
PitBull4_CombatIcon:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_left",
	position = 1,
})

function PitBull4_CombatIcon:OnEnable()
	self:ScheduleRepeatingTimer("UpdateAll", 0.1)
end

function PitBull4_CombatIcon:GetTexture(frame)
	if UnitAffectingCombat(frame.unit) then
		return [[Interface\CharacterFrame\UI-StateIcon]]
	else
		return nil
	end
end

function PitBull4_CombatIcon:GetExampleTexture(frame)
	return [[Interface\CharacterFrame\UI-StateIcon]]
end

function PitBull4_CombatIcon:GetTexCoord(frame, texture)
	return 0.57, 0.90, 0.08, 0.41
end
PitBull4_CombatIcon.GetExampleTexCoord = PitBull4_CombatIcon.GetTexCoord
