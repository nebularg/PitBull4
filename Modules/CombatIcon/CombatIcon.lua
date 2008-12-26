if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_CombatIcon requires PitBull4")
end

local PitBull4_CombatIcon = PitBull4:NewModule("CombatIcon", "AceTimer-3.0")

PitBull4_CombatIcon:SetModuleType("icon")
PitBull4_CombatIcon:SetName("Combat Icon")
PitBull4_CombatIcon:SetDescription("Show an icon based on whether or not the unit is in combat.")
PitBull4_CombatIcon:SetDefaults({
	attachTo = "root",
	location = "edge_bottom_left",
	position = 1,
})

function PitBull4_CombatIcon:OnEnable()
	self:ScheduleRepeatingTimer("UpdateAll", 0.1)
end

function PitBull4_CombatIcon:GetTexture(frame)
	if UnitAffectingCombat(frame.unit) then
		return [[Interface\CharacterFrame\UI-StateIcon]], 0.57, 0.90, 0.08, 0.41
	else
		return nil
	end
end

