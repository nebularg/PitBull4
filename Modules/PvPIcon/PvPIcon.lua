
local _G = _G

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local C_PvP = _G.C_PvP
local C_Secrets = _G.C_Secrets

local UnitFactionGroup = _G.UnitFactionGroup
local UnitHonorLevel = _G.UnitHonorLevel
local UnitIsFriend = _G.UnitIsFriend
local UnitIsMercenary = _G.UnitIsMercenary
local UnitIsPVP = _G.UnitIsPVP
local UnitIsPVPFreeForAll = _G.UnitIsPVPFreeForAll
local scrub = _G.scrub
local scrubsecretvalues = _G.scrubsecretvalues
local issecretvalue = _G.issecretvalue

local ShouldUnitIdentityBeSecret = C_Secrets and C_Secrets.ShouldUnitIdentityBeSecret

local PitBull4_PvPIcon = PitBull4:NewModule("PvPIcon")

PitBull4_PvPIcon:SetModuleType("indicator")
PitBull4_PvPIcon:SetName(L["PvP icon"])
PitBull4_PvPIcon:SetDescription(L["Show an icon on the unit frame when the unit is in PvP mode."])
PitBull4_PvPIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_right",
	position = 1,
	show_prestige = false,
})

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

local function scrub_secret_value(value)
	if scrub then
		return scrub(value)
	end

	if scrubsecretvalues then
		return scrubsecretvalues(value)
	end

	if issecretvalue and issecretvalue(value) then
		return nil
	end

	return value
end

local function is_public_true(value)
	value = scrub_secret_value(value)
	return type(value) == "boolean" and value
end

local function is_unit_identity_secret(unit)
	return ShouldUnitIdentityBeSecret and is_public_true(ShouldUnitIdentityBeSecret(unit)) or false
end

local function get_public_honor_badge(unit)
	if not UnitHonorLevel or not C_PvP or not C_PvP.GetHonorRewardInfo then
		return nil
	end

	local honor_level = scrub_secret_value(UnitHonorLevel(unit))
	if type(honor_level) ~= "number" then
		return nil
	end

	local honor_reward_info = C_PvP.GetHonorRewardInfo(honor_level)
	return honor_reward_info and honor_reward_info.badgeFileDataID or nil
end

function PitBull4_PvPIcon:OnEnable()
	self:RegisterEvent("UPDATE_FACTION")
	self:RegisterEvent("UNIT_FACTION", "UPDATE_FACTION")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "UPDATE_FACTION")
	if ClassicExpansionAtLeast(LE_EXPANSION_LEGION) then
		self:RegisterEvent("HONOR_LEVEL_UPDATE")
	end
end

function PitBull4_PvPIcon:GetTexture(frame)
	local unit = frame.unit
	local show_prestige = self:GetLayoutDB(frame).show_prestige
	if is_unit_identity_secret(unit) then
		return nil
	end

	local faction = scrub_secret_value(UnitFactionGroup(unit))
	if is_public_true(UnitIsPVPFreeForAll(unit)) then
		if show_prestige and ClassicExpansionAtLeast(LE_EXPANSION_LEGION) then -- XXX Legion added the prestige system, BfA simplified it (and added C_PvP.GetHonorRewardInfo)
			local honor_badge = get_public_honor_badge(unit)
			if honor_badge then
				return honor_badge
			end
		end
		return [[Interface\TargetingFrame\UI-PVP-FFA]]
	elseif type(faction) == "string" and faction ~= "Neutral" and is_public_true(UnitIsPVP(unit)) then
		if ClassicExpansionAtLeast(LE_EXPANSION_LEGION) then
			-- Handle "Mercenary Mode" for player
			if unit == "player" and is_public_true(UnitIsMercenary(unit)) then
				faction = OPPOSITE_PLAYER_FACTION[faction] or faction
			end
			if show_prestige then
				local honor_badge = get_public_honor_badge(unit)
				if honor_badge then
					return honor_badge
				end
			end
		end
		return [[Interface\TargetingFrame\UI-PVP-]] .. faction
	end
	return nil
end

function PitBull4_PvPIcon:GetExampleTexture(frame)
	local classification = frame.is_singleton and frame.unit or frame.header.unit_group
	if classification == "focus" then
		return [[Interface\TargetingFrame\UI-PVP-FFA]]
	end

	local player_faction = scrub_secret_value(UnitFactionGroup("player"))
	if type(player_faction) ~= "string" or player_faction == "Neutral" then
		player_faction = "FFA"
	end

	local is_friendly = FRIENDLY_CLASSIFICATIONS[classification] == true
	if not is_friendly and frame.unit then
		is_friendly = is_public_true(UnitIsFriend("player", frame.unit))
	end
	if is_friendly then
		return [[Interface\TargetingFrame\UI-PVP-]] .. player_faction
	end
	return [[Interface\TargetingFrame\UI-PVP-]] .. (OPPOSITE_PLAYER_FACTION[player_faction] or "FFA")
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

function PitBull4_PvPIcon:HONOR_LEVEL_UPDATE()
	self:UpdateForUnitID("player")
end

function PitBull4_PvPIcon:GetTexCoord(frame, texture)
	local tex_coord = TEX_COORDS[texture]
	if tex_coord then
		return tex_coord[1], tex_coord[2], tex_coord[3], tex_coord[4]
	end
	return 0, 1, 0, 1
end
PitBull4_PvPIcon.GetExampleTexCoord = PitBull4_PvPIcon.GetTexCoord

PitBull4_PvPIcon:SetLayoutOptionsFunction(function(self)
	local function get(info)
		return PitBull4.Options.GetLayoutDB(self)[info[#info]]
	end
	local function set(info, value)
		PitBull4.Options.GetLayoutDB(self)[info[#info]] = value
		PitBull4.Options.UpdateFrames()
	end
	return "show_prestige", {
		type = "toggle",
		name = L["Show honor level icon"],
		get = get,
		set = set,
	}
end)
