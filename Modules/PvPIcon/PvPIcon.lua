
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_PvPIcon = PitBull4:NewModule("PvPIcon", "AceEvent-3.0")

PitBull4_PvPIcon:SetModuleType("indicator")
PitBull4_PvPIcon:SetName(L["PvP icon"])
PitBull4_PvPIcon:SetDescription(L["Show an icon on the unit frame when the unit is in PvP mode."])
PitBull4_PvPIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_right",
	position = 1,
})

local INDICATOR_SIZE = 15

local FRIENDLY_CLASSIFICATIONS = {
	player = true,
	pet = true,
	party = true,
	partypet = true,
	raid = true,
	raidpet = true,
	targettarget = true,
	bosstarget = true,
}

local OPPOSITE_PLAYER_FACTION = {
	["Horde"] = "Alliance",
	["Alliance"] = "Horde",
	["FFA"] = "FFA",
}

local TEX_COORDS = {
	[ [[Interface\TargetingFrame\UI-PVP-FFA]] ] = {0.05, 0.605, 0.015, 0.57},
	[ [[Interface\TargetingFrame\UI-PVP-Horde]] ] = {0.08, 0.58, 0.045, 0.545},
	[ [[Interface\TargetingFrame\UI-PVP-Alliance]] ] = {0.07, 0.58, 0.06, 0.57},
}

local PRESTIGE_TEX_COORDS = {
	[ [[Interface\TargetingFrame\UI-PVP-FFA]] ] = {0.0517578, 0.100586, 0.763672, 0.865234}, -- honorsystem-portrait-neutral
	[ [[Interface\TargetingFrame\UI-PVP-Horde]] ] = {0.000976562, 0.0498047, 0.869141, 0.970703}, -- honorsystem-portrait-horde
	[ [[Interface\TargetingFrame\UI-PVP-Alliance]] ] = {0.000976562, 0.0498047, 0.763672, 0.865234}, -- honorsystem-portrait-alliance
}

function PitBull4_PvPIcon:OnEnable()
	self:RegisterEvent("UPDATE_FACTION")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "UPDATE_FACTION")
	self:RegisterEvent("UNIT_FACTION", "UPDATE_FACTION")
end

function PitBull4_PvPIcon:GetTexture(frame)
	local unit = frame.unit

	if UnitIsPVPFreeForAll(unit) then
		return [[Interface\TargetingFrame\UI-PVP-FFA]]
	end

	local faction = UnitFactionGroup(unit)
	if not faction or faction == "Neutral" then
		return nil
	end

	if not UnitIsPVP(unit) then
		return nil
	end

	-- Handle "Mercenary Mode" added in 6.2.2. This is only used for PlayerFrame
	-- so I'm assumming other units don't require this check.
	if unit == "player" and UnitIsMercenary(unit) then
		faction = OPPOSITE_PLAYER_FACTION[faction]
	end
	return [[Interface\TargetingFrame\UI-PVP-]] .. faction
end

function PitBull4_PvPIcon:GetExampleTexture(frame)
	local classification = frame.is_singleton and frame.unit or frame.header.unit_group
	if classification == "focus" then
		return [[Interface\TargetingFrame\UI-PVP-FFA]]
	end

	local player_faction = UnitFactionGroup("player")
	if not player_faction or player_faction == "Neutral" then
		player_faction = "FFA"
	end

	if FRIENDLY_CLASSIFICATIONS[classification] or (frame.guid and frame.unit and UnitIsFriend("player", frame.unit)) then
		return [[Interface\TargetingFrame\UI-PVP-]] .. player_faction
	end
	return [[Interface\TargetingFrame\UI-PVP-]] .. OPPOSITE_PLAYER_FACTION[player_faction]
end

function PitBull4_PvPIcon:UPDATE_FACTION(event, unit)
	if not unit then
		unit = "player"
	end
	self:UpdateForUnitID(unit)
	local unit_pet = PitBull4.Utils.GetBestUnitID(unit .. "pet")
	if unit_pet then
		self:UpdateForUnitID(unit_pet)
	end
end

function PitBull4_PvPIcon:GetTexCoord(frame, texture)
	local tex_coord = TEX_COORDS[texture]
	return tex_coord[1], tex_coord[2], tex_coord[3], tex_coord[4]
end
PitBull4_PvPIcon.GetExampleTexCoord = PitBull4_PvPIcon.GetTexCoord
