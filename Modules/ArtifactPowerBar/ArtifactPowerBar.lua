
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.3

local PitBull4_ArtifactPowerBar = PitBull4:NewModule("ArtifactPowerBar", "AceEvent-3.0")

PitBull4_ArtifactPowerBar:SetModuleType("bar")
PitBull4_ArtifactPowerBar:SetName(L["Artifact power bar"])
PitBull4_ArtifactPowerBar:SetDescription(L["Show an artifact power bar."])
PitBull4_ArtifactPowerBar:SetDefaults({
	size = 1,
	position = 8,
})

local function GetArtifactXP()
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
	if azeriteItemLocation then
		-- default UI shows an empty bar if the azerite item is in your bank (api can error)
		-- if azeriteItemLocation.bagID and (azeriteItemLocation.bagID < 0 or azeriteItemLocation.bagID > NUM_BAG_SLOTS) then
		-- 	return 0, 1
		-- end

		-- hide if not equipped
		if not azeriteItemLocation:IsEquipmentSlot() then
			return
		end

		return C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
	end
end

function PitBull4_ArtifactPowerBar:OnEnable()
	self:RegisterEvent("AZERITE_ITEM_EXPERIENCE_CHANGED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "AZERITE_ITEM_EXPERIENCE_CHANGED")
	-- self:RegisterEvent("BAG_UPDATE_DELAYED", "AZERITE_ITEM_EXPERIENCE_CHANGED")
	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED") -- handle (un)equip
end

function PitBull4_ArtifactPowerBar:AZERITE_ITEM_EXPERIENCE_CHANGED()
	self:UpdateForUnitID("player")
end

function PitBull4_ArtifactPowerBar:PLAYER_EQUIPMENT_CHANGED(_, slot)
	if slot == 2 then -- neck
		self:UpdateForUnitID("player")
	end
end

function PitBull4_ArtifactPowerBar:GetValue(frame)
	if frame.unit ~= "player" then
		return
	end

	local value, max = GetArtifactXP()
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
