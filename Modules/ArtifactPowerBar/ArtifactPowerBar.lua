
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.3

local PitBull4_ArtifactPowerBar = PitBull4:NewModule("ArtifactPowerBar")

PitBull4_ArtifactPowerBar:SetModuleType("bar")
PitBull4_ArtifactPowerBar:SetName(L["Artifact power bar"])
PitBull4_ArtifactPowerBar:SetDescription(L["Show an artifact power bar."])
PitBull4_ArtifactPowerBar:SetDefaults({
	size = 1,
	position = 8,
})

function PitBull4_ArtifactPowerBar:OnEnable()
	self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "AZERITE_ITEM_EXPERIENCE_CHANGED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED", "AZERITE_ITEM_EXPERIENCE_CHANGED")
end

function PitBull4_ArtifactPowerBar:AZERITE_ITEM_EXPERIENCE_CHANGED()
	self:UpdateForUnitID("player")
end

function PitBull4_ArtifactPowerBar:GetValue(frame)
	if frame.unit ~= "player" then
		return
	end

	if not C_AzeriteItem.HasActiveAzeriteItem() then
		return
	end

	if C_AzeriteItem.IsAzeriteItemAtMaxLevel() then
		return
	end

	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
	if not azeriteItemLocation or not azeriteItemLocation:IsEquipmentSlot() then
		return
	end

	local value, max = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
	if value then
		return value / max
	end
end
function PitBull4_ArtifactPowerBar:GetExampleValue(frame)
	if frame and frame.unit ~= "player" then
		return nil
	end
	return EXAMPLE_VALUE
end

function PitBull4_ArtifactPowerBar:GetColor(frame, value)
	return .901, .8, .601
end
