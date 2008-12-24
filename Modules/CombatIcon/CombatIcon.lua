if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_CombatIcon requires PitBull4")
end

local PitBull4_CombatIcon = PitBull4.NewModule("CombatIcon", "Combat Icon", "Show an icon based on whether or not the unit is in combat.", {}, {
}, "icon")

function PitBull4_CombatIcon.GetTexture(frame)
	-- if UnitAffectingCombat(frame.unit) then
		return [[Interface\CharacterFrame\UI-StateIcon]], 0.57, 0.90, 0.08, 0.41
	-- else
	-- 	return nil
	-- end
end

PitBull4_CombatIcon:SetTextureFunction('GetTexture')
