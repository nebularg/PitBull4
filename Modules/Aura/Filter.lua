-- Filter.lua : Code to handle Filtering the Auras.

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")

local _, player_class = UnitClass("player")

--- Return the DB dictionary for the specified filter.
-- Filter Types should use this to get their db.
-- @param filter the name of the filter
-- @usage local db = PitBull4_Aura:GetFilterDB("myfilter")
-- @return the DB dictionrary for the specified filter or nil
function PitBull4_Aura:GetFilterDB(filter)
	return self.db.profile.global.filters[filter]
end

-- Setup the data for who can dispel what types of auras.
-- dispel in this context means remove from friendly players
local can_dispel = {
	DRUID = {},
	HUNTER = {},
	MAGE = {},
	PALADIN = {},
	PRIEST = {},
	ROGUE = {},
	SHAMAN = {},
	WARLOCK = {},
	WARRIOR = {},
}
can_dispel.player = can_dispel[player_class]
PitBull4_Aura.can_dispel = can_dispel

-- Setup the data for who can purge what types of auras.
-- purge in this context means remove from enemies.
local can_purge = {
	DRUID = {},
	HUNTER = {},
	MAGE = {},
	PALADIN = {},
	PRIEST = {},
	ROGUE = {},
	SHAMAN = {},
	WARLOCK = {},
	WARRIOR = {},
}
can_purge.player = can_purge[player_class]
PitBull4_Aura.can_purge = can_purge

-- Rescan specialization spells that can change what we can dispel and purge.
function PitBull4_Aura:PLAYER_TALENT_UPDATE()
	can_dispel.DRUID.Curse = IsPlayerSpell(2782)
	self:GetFilterDB(',3').aura_type_list.Curse = can_dispel.DRUID.Curse
	can_dispel.DRUID.Poison = IsPlayerSpell(2893) or IsPlayerSpell(8946)
	self:GetFilterDB(',3').aura_type_list.Poison = can_dispel.DRUID.Poison

	can_dispel.MAGE.Curse = IsPlayerSpell(475)
	self:GetFilterDB('.3').aura_type_list.Curse = can_dispel.MAGE.Curse

	can_dispel.PALADIN.Magic = IsPlayerSpell(4987)
	self:GetFilterDB('/3').aura_type_list.Magic = can_dispel.PALADIN.Magic
	can_dispel.PALADIN.Disease = IsPlayerSpell(1152) or IsPlayerSpell(4987)
	self:GetFilterDB('/3').aura_type_list.Disease = can_dispel.PALADIN.Disease
	can_dispel.PALADIN.Poison = can_dispel.PALADIN.Disease
	self:GetFilterDB('/3').aura_type_list.Poison = can_dispel.PALADIN.Poison

	can_dispel.PRIEST.Magic = IsPlayerSpell(527) or IsPlayerSpell(988)
	self:GetFilterDB('03').aura_type_list.Magic = can_dispel.PRIEST.Magic
	can_dispel.PRIEST.Disease = IsPlayerSpell(528)
	self:GetFilterDB('03').aura_type_list.Disease = can_dispel.PRIEST.Disease

	can_dispel.SHAMAN.Magic = IsPlayerSpell(77130)
	self:GetFilterDB('23').aura_type_list.Magic = can_dispel.SHAMAN.Magic
	can_dispel.SHAMAN.Disease = IsPlayerSpell(2870) -- or IsPlayerSpell(8170) -- Totem
	self:GetFilterDB('23').aura_type_list.Disease = can_dispel.SHAMAN.Disease
	can_dispel.SHAMAN.Poison = IsPlayerSpell(526) -- or IsPlayerSpell(8166) -- Totem
	self:GetFilterDB('23').aura_type_list.Poison = can_dispel.SHAMAN.Poison

	can_purge.SHAMAN.Magic = IsPlayerSpell(370) or IsPlayerSpell(8012)
	self:GetFilterDB('27').aura_type_list.Magic = can_purge.SHAMAN.Magic

	can_purge.WARLOCK.Magic = IsSpellKnown(19505, true) or IsSpellKnown(19731, true) or IsSpellKnown(19734, true) or IsSpellKnown(19736, true)
	self:GetFilterDB('37').aura_type_list.Magic = can_purge.WARLOCK.Magic
end

-- Setup the data for which auras belong to whom
local friend_buffs,friend_debuffs,self_buffs,self_debuffs,pet_buffs,enemy_debuffs = {},{},{},{},{},{}
for _, class in next, CLASS_SORT_ORDER do
	friend_buffs[class] = {}
	friend_debuffs[class] = {}
	self_buffs[class] = {}
	self_debuffs[class] = {}
	pet_buffs[class] = {}
	enemy_debuffs[class] = {}
end

-- Build the class filters
do
	-- some shenanigans to only load LPS if the module is enabled (for nolib installs)
	local LibPlayerSpells = LibStub("LibPlayerSpells-1.0", true)
	if LibPlayerSpells then
		local AURA = LibPlayerSpells.constants.AURA
		local INVERT_AURA = LibPlayerSpells.constants.INVERT_AURA
		local HELPFUL = LibPlayerSpells.constants.HELPFUL
		local HARMFUL = LibPlayerSpells.constants.HARMFUL
		local PERSONAL = LibPlayerSpells.constants.PERSONAL
		local PET = LibPlayerSpells.constants.PET
		local TARGETING = LibPlayerSpells.masks.TARGETING

		for _, class in next, CLASS_SORT_ORDER do
			for spell, flags in next, LibPlayerSpells.__categories[class] do
				if bit.band(flags, AURA) ~= 0 then
					local target = bit.band(flags, TARGETING)
					local inverted = bit.band(flags, INVERT_AURA) ~= 0 -- friend debuff

					if target == HELPFUL and not inverted then
						friend_buffs[class][spell] = true
					elseif (target == HELPFUL or target == PET) and inverted then
						friend_debuffs[class][spell] = true
					elseif target == PERSONAL and not inverted then
						self_buffs[class][spell] = true
					elseif target == PERSONAL and inverted then
						self_debuffs[class][spell] = true
					elseif target == PET and not inverted then
						pet_buffs[class][spell] = true
					elseif target == HARMFUL then
						enemy_debuffs[class][spell] = true
					end
				end
			end
		end
	end
end

-- Human
friend_buffs.Human = {
	[23333] = true -- Warsong Flag
}
friend_debuffs.Human = {}
self_buffs.Human = {}
self_debuffs.Human = {}
pet_buffs.Human = {}
enemy_debuffs.Human = {}

-- Dwarf
friend_buffs.Dwarf = {
	[23333] = true -- Warsong Flag
}
friend_debuffs.Dwarf = {}
self_buffs.Dwarf = {
	[20594] = true, -- Stoneform
}
self_debuffs.Dwarf = {}
pet_buffs.Dwarf = {}
enemy_debuffs.Dwarf = {}

-- Night Elf
friend_buffs.NightElf = {
	[23333] = true -- Warsong Flag
}
friend_debuffs.NightElf = {}
self_buffs.NightElf = {
	[20580] = true, -- Shadowmeld
}
self_debuffs.NightElf = {}
pet_buffs.NightElf = {}
enemy_debuffs.NightElf = {}

-- Gnome
friend_buffs.Gnome = {
	[23333] = true -- Warsong Flag
}
friend_debuffs.Gnome = {}
self_buffs.Gnome = {}
self_debuffs.Gnome = {}
pet_buffs.Gnome = {}
enemy_debuffs.Gnome = {}


-- Orc
friend_buffs.Orc = {
	[23335] = true -- Silverwing Flag
}
friend_debuffs.Orc = {}
self_buffs.Orc = {
	[20572] = true, -- Blood Fury (Attack power)
}
self_debuffs.Orc = {}
pet_buffs.Orc = {}
enemy_debuffs.Orc = {}

-- Undead
friend_buffs.Scourge = {
	[23335] = true -- Silverwing Flag
}
friend_debuffs.Scourge = {}
self_buffs.Scourge = {
	[20577] = true, -- Cannibalize
	[7744]  = true, -- Will of the Forsaken
}
self_debuffs.Scourge = {}
pet_buffs.Scourge = {}
enemy_debuffs.Scourge = {}

-- Tauren
friend_buffs.Tauren = {
	[23335] = true -- Silverwing Flag
}
friend_debuffs.Tauren = {}
self_buffs.Tauren = {}
self_debuffs.Tauren = {}
pet_buffs.Tauren = {}
enemy_debuffs.Tauren = {
	[20549] = true, -- War Stomp
}

-- Troll
friend_buffs.Troll = {
	[23335] = true -- Silverwing Flag
}
friend_debuffs.Troll = {}
self_buffs.Troll = {
	[26297] = true, -- Berserking
}
self_debuffs.Troll = {}
pet_buffs.Troll = {}
enemy_debuffs.Troll = {}


-- Everyone
local extra_buffs = {}

local function turn(t, shallow)
	local tmp = {}
	local function turn(entry) -- luacheck: ignore
		for id, v in next, entry do
			local spell = GetSpellInfo(id)
			if not spell then
				DEFAULT_CHAT_FRAME:AddMessage(string.format("PitBull4_Aura: Unknown spell ID: %s", id))
			else
				tmp[spell] = v
			end
		end
		wipe(entry)
		for spell, v in next, tmp do
			entry[spell] = v
		end
	end
	if shallow then
		turn(t)
		return
	end
	for k in next, t do
		local entry = t[k]
		wipe(tmp)
		turn(entry)
	end
end
turn(friend_buffs)
turn(friend_debuffs)
turn(self_buffs)
turn(self_debuffs)
turn(pet_buffs)
turn(enemy_debuffs)
turn(extra_buffs, true)

PitBull4_Aura.friend_buffs = friend_buffs
PitBull4_Aura.friend_debuffs = friend_debuffs
PitBull4_Aura.self_buffs = self_buffs
PitBull4_Aura.self_debuffs = self_debuffs
PitBull4_Aura.pet_buffs = pet_buffs
PitBull4_Aura.enemy_debuffs = enemy_debuffs
PitBull4_Aura.extra_buffs = extra_buffs

function PitBull4_Aura:FilterEntry(name, entry, frame)
	if not name or name == "" then return true end
	local filter = self:GetFilterDB(name)
	if not filter then return true end
	local filter_func = self.filter_types[filter.filter_type].filter_func
	return filter_func(name, entry, frame)
end


PitBull4_Aura.OnProfileChanged_funcs[#PitBull4_Aura.OnProfileChanged_funcs+1] =
function(self)
	-- Fix name lists containing spell ids (issue in 27703b7)
	for _, filter in next, PitBull4_Aura.db.profile.global.filters do
		if filter.name_list then
			local name_list = filter.name_list
			for id, v in next, name_list do
				if type(id) == "number" then
					name_list[id] = nil
					local spell = GetSpellInfo(id)
					if spell then
						name_list[spell] = v
					end
				end
			end
		end
	end
end
