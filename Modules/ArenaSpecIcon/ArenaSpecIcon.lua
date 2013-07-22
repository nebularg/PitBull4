if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ArenaSpecIcon requires PitBull4")
end

local L = PitBull4.L

local PitBull4_ArenaSpecIcon = PitBull4:NewModule("ArenaSpec", "AceEvent-3.0")

PitBull4_ArenaSpecIcon:SetModuleType("indicator")
PitBull4_ArenaSpecIcon:SetName(L["Arena spec icon"])
PitBull4_ArenaSpecIcon:SetDescription(L["Show an icon on the unit frame based on which specialization it is."])
PitBull4_ArenaSpecIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_right",
	position = 1,
})

function PitBull4_ArenaSpecIcon:OnEnable()
	self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
end

function PitBull4_ArenaSpecIcon:GetTexture(frame)
	local id = frame.unit:match("^arena(%d)$")
	local spec = id and GetArenaOpponentSpec(id) or 0
	if spec > 0 then
		local _, _, _, icon = GetSpecializationInfoByID(spec)
		return icon
	end
end

function PitBull4_ArenaSpecIcon:GetExampleTexture(frame)
	local spec = GetSpecialization()
	local icon = spec and select(4, GetSpecializationInfo(spec))

	return icon or [[Interface\ICONS\INV_Misc_QuestionMark]]
end

function PitBull4_ArenaSpecIcon:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	self:UpdateAll()
end
