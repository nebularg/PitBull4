if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_BattlePet requires PitBull4")
end

local L = PitBull4.L

local PitBull4_BattlePet = PitBull4:NewModule("BattlePet","AceEvent-3.0")

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
	if not unit then return nil end

	if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
		local pet_type = UnitBattlePetType(unit)
		return [[Interface\TargetingFrame\PetBadge-]]..PET_TYPE_SUFFIX[pet_type]
	else
		return nil
	end
end

function PitBull4_BattlePet:GetExampleTexture(frame)
	return [[Interface\TargetingFrame\PetBadge-]]..PET_TYPE_SUFFIX[8]
end
