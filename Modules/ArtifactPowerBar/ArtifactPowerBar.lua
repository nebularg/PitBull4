if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ArtifactPowerBar requires PitBull4")
end

local EXAMPLE_VALUE = 0.3

local L = PitBull4.L

local PitBull4_ArtifactPowerBar = PitBull4:NewModule("ArtifactPowerBar", "AceEvent-3.0")

PitBull4_ArtifactPowerBar:SetModuleType("bar")
PitBull4_ArtifactPowerBar:SetName(L["Artifact power bar"])
PitBull4_ArtifactPowerBar:SetDescription(L["Show an artifact power bar."])
PitBull4_ArtifactPowerBar:SetDefaults({
	size = 1,
	position = 8,
})

local C_ArtifactUI = _G.C_ArtifactUI

local function GetArtifactXP()
	local _, _, _, _, artifactXP, pointsSpent = C_ArtifactUI.GetEquippedArtifactInfo()
	local xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent)
	while artifactXP >= xpForNextPoint and xpForNextPoint > 0 do
		artifactXP = artifactXP - xpForNextPoint
		pointsSpent = pointsSpent + 1
		xpForNextPoint = C_ArtifactUI.GetCostForPointAtRank(pointsSpent)
	end
	return artifactXP, xpForNextPoint
end

function PitBull4_ArtifactPowerBar:OnEnable()
	self:RegisterEvent("ARTIFACT_XP_UPDATE")
	self:RegisterEvent("UNIT_INVENTORY_CHANGED") -- handle (un)equip
end

function PitBull4_ArtifactPowerBar:ARTIFACT_XP_UPDATE()
	self:UpdateForUnitID("player")
end

function PitBull4_ArtifactPowerBar:UNIT_INVENTORY_CHANGED(_, unit)
	if unit == "player" then
		self:UpdateForUnitID(unit)
	end
end

function PitBull4_ArtifactPowerBar:GetValue(frame)
	if frame.unit ~= "player" then
		return
	end

	if not HasArtifactEquipped() then
		return
	end

	local value, max = GetArtifactXP()
	return value / max
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
