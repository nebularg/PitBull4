
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_BattlePet = PitBull4:NewModule("BattlePet")

PitBull4_BattlePet:SetModuleType("indicator")
PitBull4_BattlePet:SetName(L["Battle pet"])
PitBull4_BattlePet:SetDescription(L["Show an icon for the type of a battle pet."])
PitBull4_BattlePet:SetDefaults({
	attach_to = "root",
	location = "edge_top_right",
	position = 1,
})

function PitBull4_BattlePet:GetTexture(frame)
	local unit = frame.unit
	if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
		local pet_type = UnitBattlePetType(unit)
		return [[Interface\TargetingFrame\PetBadge-]]..PET_TYPE_SUFFIX[pet_type]
	end
end

function PitBull4_BattlePet:GetExampleTexture(frame)
	return [[Interface\TargetingFrame\PetBadge-Beast]]
end
