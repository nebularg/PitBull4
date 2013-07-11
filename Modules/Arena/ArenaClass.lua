if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local CLASS_ICON_TCOORDS = CLASS_ICON_TCOORDS

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ArenaClass requires PitBull4")
end

local L = PitBull4.L

local PitBull4_ArenaClass = PitBull4:NewModule("ArenaClass", "AceEvent-3.0")

PitBull4_ArenaClass:SetModuleType("indicator")
PitBull4_ArenaClass:SetName(L["Arena class icon"])
PitBull4_ArenaClass:SetDescription(L["Show an icon on the unit frame based on which class it is."])
PitBull4_ArenaClass:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_left",
	position = 1,
})

function PitBull4_ArenaClass:OnEnable()
	self:RegisterEvent("ARENA_PREP_OPPONENT_SPECIALIZATIONS")
end

function PitBull4_ArenaClass:GetTexture(frame)
	local id = frame.unit:match("^arena(%d)$")
	local specId = id and GetArenaOpponentSpec(id)
	if specId > 0 then
		if GetSpecializationInfoByID(specId) then
			return [[Interface\TargetingFrame\UI-Classes-Circles]]
		end
	end

	return [[Interface\ICONS\INV_Misc_QuestionMark]]
end

function PitBull4_ArenaClass:GetExampleTexture(frame)
	return [[Interface\Icons\Ability_Hunter_BeastCall]]
end

function PitBull4_ArenaClass:GetTexCoord(frame, texture)
	local id = frame.unit:match("^arena(%d)$")
	local specId = id and GetArenaOpponentSpec(id)
	if specId > 0 then
		local _, _, _, _, _, _, class = GetSpecializationInfoByID(specId)
		if class then
			return unpack(CLASS_ICON_TCOORDS[strupper(class)])
		end
	end

	return 0, 1, 0, 1
end

function PitBull4_ArenaClass:ARENA_PREP_OPPONENT_SPECIALIZATIONS()
	self:UpdateAll()
end
