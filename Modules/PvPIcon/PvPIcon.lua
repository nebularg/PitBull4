
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local wow_cata = PitBull4.wow_cata

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

function PitBull4_PvPIcon:OnEnable()
	self:RegisterEvent("UPDATE_FACTION")
	self:RegisterEvent("UNIT_FACTION", "UPDATE_FACTION")
	self:RegisterEvent("PLAYER_FLAGS_CHANGED", "UPDATE_FACTION")
	if not wow_cata then
		self:RegisterEvent("HONOR_LEVEL_UPDATE")
	end
end

function PitBull4_PvPIcon:GetTexture(frame)
	local unit = frame.unit
	local show_prestige = self:GetLayoutDB(frame).show_prestige

	local faction = UnitFactionGroup(unit)
	if UnitIsPVPFreeForAll(unit) then
		if not wow_cata then
			local honorLevel = UnitHonorLevel(unit)
			local honorRewardInfo = C_PvP.GetHonorRewardInfo(honorLevel)
			if honorRewardInfo and show_prestige then
				-- self.prestigePortrait:SetAtlas("honorsystem-portrait-neutral", false)
				return honorRewardInfo.badgeFileDataID
			end
		end
		return [[Interface\TargetingFrame\UI-PVP-FFA]]
	elseif faction and faction ~= "Neutral" and UnitIsPVP(unit) then
		if not wow_cata then
			-- Handle "Mercenary Mode" for player
			if unit == "player" and UnitIsMercenary(unit) then
				faction = OPPOSITE_PLAYER_FACTION[faction]
			end
			local honorLevel = UnitHonorLevel(unit)
			local honorRewardInfo = C_PvP.GetHonorRewardInfo(honorLevel)
			if honorRewardInfo and show_prestige then
				-- self.prestigePortrait:SetAtlas("honorsystem-portrait-"..faction, false)
				return honorRewardInfo.badgeFileDataID
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
