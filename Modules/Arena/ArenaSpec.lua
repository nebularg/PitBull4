if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ArenaSpec requires PitBull4")
end

local L = PitBull4.L

local PitBull4_ArenaSpec = PitBull4:NewModule("ArenaSpec", "AceEvent-3.0")

PitBull4_ArenaSpec:SetModuleType("indicator")
PitBull4_ArenaSpec:SetName(L["Arena spec icon"])
PitBull4_ArenaSpec:SetDescription(L["Show an icon on the unit frame based on which specialization it is."])
PitBull4_ArenaSpec:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_left",
	position = 2,
})

function PitBull4_ArenaSpec:OnEnable()
	self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
end

function PitBull4_ArenaSpec:GetSpec(unit)
end

function PitBull4_ArenaSpec:GetTexture(frame)
	local id = frame.unit:match("^arena(%d)$")
	local specId = id and GetArenaOpponentSpec(id)
	if specId > 0 then
		local _, _, _, specIcon = GetSpecializationInfoByID(specId)
		return specIcon
	end
end

function PitBull4_ArenaSpec:GetExampleTexture(frame)
	return [[Interface\ICONS\INV_Misc_QuestionMark]]
end

function PitBull4_ArenaSpec:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	self:UpdateAll()
end
