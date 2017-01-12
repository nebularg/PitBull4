-- Filter.lua : Code to handle Filtering the Auras.

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")

local _, player_class = UnitClass("player")
local player_faction = UnitFactionGroup("player")

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
	DEATHKNIGHT = {},
	DEMONHUNTER = {},
	DRUID = {
		Curse = true,
		Poison = true,
		Magic = IsPlayerSpell(88423),
	},
	HUNTER = {},
	MAGE = {},
	MONK = {
		Poison = true,
		Disease = true,
		Magic = IsPlayerSpell(115450),
	},
	PALADIN = {
		Poison = true,
		Disease = true,
		Magic = IsPlayerSpell(4987),
	},
	PRIEST = {
		Magic = true,
		Disease = IsPlayerSpell(527),
	},
	ROGUE = {},
	SHAMAN = {
		Curse = true,
		Magic = IsPlayerSpell(77130),
	},
	WARLOCK = {
		Magic = true, -- Imp: Singe Magic
	},
	WARRIOR = {},
}
can_dispel.player = can_dispel[player_class]
PitBull4_Aura.can_dispel = can_dispel

-- Setup the data for who can purge what types of auras.
-- purge in this context means remove from enemies.
local can_purge = {
	DEATHKNIGHT = {},
	DEMONHUNTER = {},
	DRUID = {},
	HUNTER = {},
	MAGE = {
		Magic = true,
	},
	MONK = {},
	PALADIN = {},
	PRIEST = {
		Magic = true,
	},
	ROGUE = {},
	SHAMAN = {
		Magic = true,
	},
	WARLOCK = {},
	WARRIOR = {},
}
can_purge.player = can_purge[player_class]
PitBull4_Aura.can_purge = can_purge

-- Rescan specialization spells that can change what we can dispel.
function PitBull4_Aura:PLAYER_TALENT_UPDATE()
	can_dispel.DRUID.Magic = IsPlayerSpell(88423)
	self:GetFilterDB(',3').aura_type_list.Magic = can_dispel.DRUID.Magic

	can_dispel.MONK.Magic = IsPlayerSpell(115450)
	self:GetFilterDB('//3').aura_type_list.Magic = can_dispel.MONK.Magic

	can_dispel.PALADIN.Magic = IsPlayerSpell(4987)
	self:GetFilterDB('/3').aura_type_list.Magic = can_dispel.PALADIN.Magic

	can_dispel.PRIEST.Disease = IsPlayerSpell(527)
	self:GetFilterDB('03').aura_type_list.Disease = can_dispel.PRIEST.Disease

	can_dispel.SHAMAN.Magic = IsPlayerSpell(77130)
	self:GetFilterDB('23').aura_type_list.Magic = can_dispel.SHAMAN.Magic
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
friend_buffs.Human = {}
friend_debuffs.Human = {}
self_buffs.Human = {}
self_debuffs.Human = {}
pet_buffs.Human = {}
enemy_debuffs.Human = {}

-- Dwarf
friend_buffs.Dwarf = {}
friend_debuffs.Dwarf = {}
self_buffs.Dwarf = {
	[65116] = true, -- Stoneform
}
self_debuffs.Dwarf = {}
pet_buffs.Dwarf = {}
enemy_debuffs.Dwarf = {}

-- Night Elf
friend_buffs.NightElf = {}
friend_debuffs.NightElf = {}
self_buffs.NightElf = {
	[58984] = true, -- Shadowmeld
}
self_debuffs.NightElf = {}
pet_buffs.NightElf = {}
enemy_debuffs.NightElf = {}

-- Gnome
friend_buffs.Gnome = {}
friend_debuffs.Gnome = {}
self_buffs.Gnome = {}
self_debuffs.Gnome = {}
pet_buffs.Gnome = {}
enemy_debuffs.Gnome = {}

-- Draenei
friend_buffs.Draenei = {
	[59545]  = true, -- Gift of the Naaru (Death Knight)
	[59543]  = true, -- Gift of the Naaru (Hunter)
	[59548]  = true, -- Gift of the Naaru (Mage)
	[59542]  = true, -- Gift of the Naaru (Paladin)
	[59544]  = true, -- Gift of the Naaru (Priest)
	[59547]  = true, -- Gift of the Naaru (Shaman)
	[28880]  = true, -- Gift of the Naaru (Warrior)
	[121093] = true, -- Gift of the Naaru (Monk)
}
friend_debuffs.Draenei = {}
self_buffs.Draenei = {}
self_debuffs.Draenei = {}
pet_buffs.Draenei = {}
enemy_debuffs.Draenei = {}

-- Worgen
friend_buffs.Worgen = {}
friend_debuffs.Worgen = {}
self_buffs.Worgen = {
	[68992] = true, -- Darkflight
	[87840] = true, -- Running Wild
}
self_debuffs.Worgen = {}
pet_buffs.Worgen = {}
enemy_debuffs.Worgen = {}

-- Orc
friend_buffs.Orc = {}
friend_debuffs.Orc = {}
self_buffs.Orc = {
	[20572] = true, -- Blood Fury (Attack power)
	[33702] = true, -- Blood Fury (Spell power)
	[33697] = true, -- Blood Fury (Both)
}
self_debuffs.Orc = {}
pet_buffs.Orc = {}
enemy_debuffs.Orc = {}

-- Undead
friend_buffs.Scourge = {}
friend_debuffs.Scourge = {}
self_buffs.Scourge = {
	[20578] = true, -- Cannibalize
	[7744]  = true, -- Will of the Forsaken
}
self_debuffs.Scourge = {}
pet_buffs.Scourge = {}
enemy_debuffs.Scourge = {}

-- Tauren
friend_buffs.Tauren = {}
friend_debuffs.Tauren = {}
self_buffs.Tauren = {}
self_debuffs.Tauren = {}
pet_buffs.Tauren = {}
enemy_debuffs.Tauren = {
	[20549] = true, -- War Stomp
}

-- Troll
friend_buffs.Troll = {}
friend_debuffs.Troll = {}
self_buffs.Troll = {
	[26297] = true, -- Berserking
}
self_debuffs.Troll = {}
pet_buffs.Troll = {}
enemy_debuffs.Troll = {}

-- Blood Elf
friend_buffs.BloodElf = {}
friend_debuffs.BloodElf = {}
self_buffs.BloodElf = {}
self_debuffs.BloodElf = {}
pet_buffs.BloodElf = {}
enemy_debuffs.BloodElf = {
	[28730]  = true, -- Arcane Torrent (Mana)
	[50613]  = true, -- Arcane Torrent (Runic power)
	[80483]  = true, -- Arcane Torrent (Focus)
	[25046]  = true, -- Arcane Torrent (Energy)
	[69179]  = true, -- Arcane Torrent (Rage)
	[129597] = true, -- Arcane Torrent (Chi)
	[155145] = true, -- Arcane Torrent (Holy power)
	[202719] = true, -- Arcane Torrent (Fury)
}

-- Goblin
friend_buffs.Goblin = {}
friend_debuffs.Goblin = {}
self_buffs.Goblin = {}
self_debuffs.Goblin = {}
pet_buffs.Goblin = {}
enemy_debuffs.Goblin = {}

-- Pandaren
friend_buffs.Pandaren = {
	[23335] = player_faction == "Horde", -- Silverwing Flag
	[23333] = player_faction == "Alliance", -- Warsong Flag
}
friend_debuffs.Pandaren = {}
self_buffs.Pandaren = {}
self_debuffs.Pandaren = {}
pet_buffs.Pandaren = {}
enemy_debuffs.Pandaren = {
	[107079] = true, -- Quaking Palm
}

-- Faction specific
for _, race in next, {"Human", "Dwarf", "NightElf", "Gnome", "Draenei", "Worgen"} do
	friend_buffs[race][23333] = true -- Warsong Flag
end
for _, race in next, {"Orc", "Scourge", "Tauren", "Troll", "BloodElf", "Goblin"} do
	friend_buffs[race][23335] = true -- Silverwing Flag
end

-- Everyone
local extra_buffs = {
	[34976] = true, -- Netherstorm Flag
}

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
