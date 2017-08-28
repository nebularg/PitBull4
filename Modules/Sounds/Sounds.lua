
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Sounds = PitBull4:NewModule("Sounds", "AceEvent-3.0")

PitBull4_Sounds:SetModuleType("custom")
PitBull4_Sounds:SetName(L["Sounds"])
PitBull4_Sounds:SetDescription(L["Play certain sounds when various unit-based events occur."])
PitBull4_Sounds:SetDefaults()

function PitBull4_Sounds:OnEnable()
	self:RegisterEvent("UNIT_FACTION")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:CheckPvP()
end

function PitBull4_Sounds:UNIT_FACTION(event, unit)
	if unit == "player" then
		self:CheckPvP()
	end
end

local last_pvp = false
function PitBull4_Sounds:CheckPvP()
	local pvp = not not (UnitIsPVPFreeForAll("player") or UnitIsPVP("player"))
	if pvp and not last_pvp then
		PlaySound(SOUNDKIT.IG_PVP_UPDATE)
	end
	last_pvp = pvp
end

function PitBull4_Sounds:PLAYER_unit_CHANGED(unit)
	if UnitExists(unit) then
		if UnitIsEnemy("player", unit) then
			PlaySound(SOUNDKIT.IG_CREATURE_AGGRO_SELECT)
		elseif UnitIsFriend("player", unit) then
			PlaySound(SOUNDKIT.IG_CHARACTER_NPC_SELECT)
		else
			PlaySound(SOUNDKIT.IG_CREATURE_NEUTRAL_SELECT)
		end
	else
		PlaySound(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT)
	end
end

function PitBull4_Sounds:PLAYER_FOCUS_CHANGED()
	self:PLAYER_unit_CHANGED("focus")
end

function PitBull4_Sounds:PLAYER_TARGET_CHANGED()
	self:PLAYER_unit_CHANGED("target")
end
