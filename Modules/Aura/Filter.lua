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
	if player_class == "DRUID" then
		can_dispel.DRUID.Curse = IsPlayerSpell(2782) -- Remove Curse
		self:GetFilterDB(',3').aura_type_list.Curse = can_dispel.DRUID.Curse
		can_dispel.DRUID.Poison = IsPlayerSpell(2893) or IsPlayerSpell(8946) -- Cure Poison, Abolish Poison
		self:GetFilterDB(',3').aura_type_list.Poison = can_dispel.DRUID.Poison

	elseif player_class == "HUNTER" then
		can_purge.HUNTER.Enrage = IsPlayerSpell(19801) -- Tranuilizing Shot
		self:GetFilterDB('-7').aura_type_list.Enrage = can_purge.HUNTER.Enrage

	elseif player_class == "MAGE" then
		can_dispel.MAGE.Curse = IsPlayerSpell(475) -- Remove Lesser Curse
		self:GetFilterDB('.3').aura_type_list.Curse = can_dispel.MAGE.Curse

	elseif player_class == "PALADIN" then
		can_dispel.PALADIN.Magic = IsPlayerSpell(4987) -- Cleanse
		self:GetFilterDB('/3').aura_type_list.Magic = can_dispel.PALADIN.Magic
		can_dispel.PALADIN.Disease = IsPlayerSpell(1152) or IsPlayerSpell(4987) -- Purify
		self:GetFilterDB('/3').aura_type_list.Disease = can_dispel.PALADIN.Disease
		can_dispel.PALADIN.Poison = can_dispel.PALADIN.Disease
		self:GetFilterDB('/3').aura_type_list.Poison = can_dispel.PALADIN.Poison

	elseif player_class == "PRIEST" then
		can_dispel.PRIEST.Magic = IsPlayerSpell(527) or IsPlayerSpell(988) -- Dispel Magic
		self:GetFilterDB('03').aura_type_list.Magic = can_dispel.PRIEST.Magic
		can_dispel.PRIEST.Disease = IsPlayerSpell(528) or IsPlayerSpell(552) -- Cure Disease, Abolish Disease
		self:GetFilterDB('03').aura_type_list.Disease = can_dispel.PRIEST.Disease

	elseif player_class == "SHAMAN" then
		can_dispel.SHAMAN.Disease = IsPlayerSpell(2870) -- or IsPlayerSpell(8170) -- Cure Disease, Disease Cleansing Totem
		self:GetFilterDB('23').aura_type_list.Disease = can_dispel.SHAMAN.Disease
		can_dispel.SHAMAN.Poison = IsPlayerSpell(526) -- or IsPlayerSpell(8166) -- Cure Poison, Poison Cleansing Totem
		self:GetFilterDB('23').aura_type_list.Poison = can_dispel.SHAMAN.Poison

		can_purge.SHAMAN.Magic = IsPlayerSpell(370) or IsPlayerSpell(8012) -- Purge
		self:GetFilterDB('27').aura_type_list.Magic = can_purge.SHAMAN.Magic

	elseif player_class == "WARLOCK" then
		can_purge.WARLOCK.Magic = IsSpellKnown(19505, true) or IsSpellKnown(19731, true) or IsSpellKnown(19734, true) or IsSpellKnown(19736, true) -- Devour Magic
		self:GetFilterDB('37').aura_type_list.Magic = can_purge.WARLOCK.Magic

	elseif player_class == "WARRIOR" then
		can_purge.WARRIOR.Magic = IsPlayerSpell(23922) or IsPlayerSpell(23923) or IsPlayerSpell(23924) or IsPlayerSpell(23925) -- Shield Slam
		self:GetFilterDB('47').aura_type_list.Magic = can_purge.WARRIOR.Magic

	end
end

-- Setup the data for which auras belong to whom
local friend_buffs,friend_debuffs,self_buffs,self_debuffs,pet_buffs,enemy_debuffs = {},{},{},{},{},{}

-- Druid
friend_buffs.DRUID = {}
friend_buffs.DRUID = {
	[2893] = 8, -- Abolish Poison
	[22812] = 15, -- Barkskin
	[21849] = true, [21850] = true, -- Gift of the Wild
	[29166] = 20, -- Innervate
	[1126] = true, [5232] = true, [6756] = true, [5234] = true, [8907] = true, [9884] = true, [9885] = true, -- Mark of the Wild
	[16810] = 45, [16811] = 45, [16812] = 45, [16813] = 45, [17329] = 45, -- Nature's Grasp
	[8936] = 21, [8938] = 21, [8939] = 21, [8940] = 21, [8941] = 21, [9750] = 21, [9856] = 21, [9857] = 21, [9858] = 21, -- Regrowth
	[774] = 12, [1058] = 12, [1430] = 12, [2090] = 12, [2091] = 12, [3627] = 12, [8910] = 12, [9839] = 12, [9840] = 12, [9841] = 12, [25299] = 12, -- Rejuvenation
	[467] = 600, [782] = 600, [1075] = 600, [8914] = 600, [9756] = 600,	[9756] = 600, -- Thorns
}
friend_debuffs.DRUID = {}
self_buffs.DRUID = {}
self_buffs.DRUID = {
	[1066] = true, -- Aquatic Form
	[5487] = true, [9634] = true, -- Bear Form
	[768] = true, -- Cat Form
	[1850] = 15, [9821] = 15, -- Dash
	[5229] = 10, -- Enrage
	[22842] = 10, [22895] = 10, [22896] = 10, -- Frenzied Regeneration
	[5215] = true, [6783] = true, [9913] = true, -- Prowl
	[5217] = 6, [6793] = 6, [9845] = 6, [9846] = 6, -- Tiger's Fury
	[740] = 10, [8918] = 10, [9862] = 10, [9863] = 10, -- Tranquility
	[783] = true, -- Travel Form
}
self_debuffs.DRUID = {}
pet_buffs.DRUID = {}
enemy_debuffs.DRUID = {}
enemy_debuffs.DRUID = {
	[5211] = 2, [6798] = 3, [8983] = 4, -- Bash
	[5209] = 6, -- Challenging Roar
	[99] = 30, [1735] = 30, [9490] = 30, [9747] = 30, [9898] = 30, -- Demoralizing Roar
	[339] = 12, [1062] = 15, [5195] = 18, [5196] = 21, [9852] = 24, [9853] = 27, -- Entangling Roots
	[770] = 40, [778] = 40, [9749] = 40, [9907] = 40, -- Faerie Fire
	[17390] = 40, [17391] = 40, [17392] = 40, -- Faerie Fire (Feral)
	[6795] = 3, -- Growl
	[2637] = 20, [18657] = 30, [18658] = 40, -- Hibernate
	[17401] = 10, [17402] = 10, -- Hurricane
	[5570] = 12, [24974] = 12, [24975] = 12, [24976] = 12, [24977] = 12, -- Insect Swarm
	[8921] = 9, [8924] = 12, [8925] = 12, [8926] = 12, [8927] = 12, [8928] = 12, [8929] = 12, [9833] = 12, [9834] = 12, [9835] = 12, -- Moonfire
	[9005] = 2, [9823] = 2, [9827] = 2, -- Pounce
	[9007] = 18, [9824] = 18, [9826] = 18, -- Pounce Bleed
	[1822] = 9, [1823] = 9, [1824] = 9, [9904] = 9, -- Rake
	[1079] = 12, [9492] = 12, [9493] = 12, [9752] = 12, [9894] = 12, [9896] = 12, -- Rip
	[2908] = 15, [8955] = 15, [9901] = 15, -- Soothe Animal
	[16922] = 3, -- Starfire Stun
}

-- Hunter
friend_buffs.HUNTER = {}
friend_debuffs.HUNTER = {}
self_buffs.HUNTER = {}
self_debuffs.HUNTER = {}
pet_buffs.HUNTER = {}
enemy_debuffs.HUNTER = {}

-- Mage
friend_buffs.MAGE = {}
friend_debuffs.MAGE = {}
self_buffs.MAGE = {}
self_debuffs.MAGE = {}
pet_buffs.MAGE = {}
enemy_debuffs.MAGE = {}

-- Paladin
friend_buffs.PALADIN = {}
friend_debuffs.PALADIN = {}
self_buffs.PALADIN = {}
self_debuffs.PALADIN = {}
pet_buffs.PALADIN = {}
enemy_debuffs.PALADIN = {}

-- Priest
friend_buffs.PRIEST = {}
friend_debuffs.PRIEST = {}
self_buffs.PRIEST = {}
self_debuffs.PRIEST = {}
pet_buffs.PRIEST = {}
enemy_debuffs.PRIEST = {}

-- Rogue
friend_buffs.ROGUE = {}
friend_debuffs.ROGUE = {}
self_buffs.ROGUE = {}
self_debuffs.ROGUE = {}
pet_buffs.ROGUE = {}
enemy_debuffs.ROGUE = {}

-- Shaman
friend_buffs.SHAMAN = {}
friend_debuffs.SHAMAN = {}
self_buffs.SHAMAN = {}
self_debuffs.SHAMAN = {}
pet_buffs.SHAMAN = {}
enemy_debuffs.SHAMAN = {}

-- Warlock
friend_buffs.WARLOCK = {}
friend_debuffs.WARLOCK = {}
self_buffs.WARLOCK = {}
self_debuffs.WARLOCK = {}
pet_buffs.WARLOCK = {}
enemy_debuffs.WARLOCK = {}

-- Warrior
friend_buffs.WARRIOR = {}
friend_buffs.WARRIOR = {
	[5242] = 120, [6192] = 120, [6673] = 120, [11549] = 120, [11550] = 120, [11551] = 120, [25289] = 120, -- Battle Shout
}
friend_debuffs.WARRIOR = {}
self_buffs.WARRIOR = {}
self_buffs.WARRIOR = {
	[18499] = 10, -- Berserker Rage
	[23885] = 8, 	[23886] = 8, 	[23887] = 8, 	[23888] = 8, -- Bloodthirst
	[29131] = 10, -- Blood Rage
	[12328] = 30, -- Death Wish
	[12880] = 12, [14201] = 12, [14202] = 12, [14203] = 12, [14204] = 12, -- Enrage
	[12966] = 15, [12967] = 15, [12968] = 15, [12969] = 15, [12970] = 15, -- Flurry
	[12976] = 20, -- Last Stand
	[1719] = 15, -- Recklessness
	[20230] = 15, -- Retaliation
	[2565] = 6, -- Shield Block
	[871] = 10, -- Shield Wall
	[12292] = 10, -- Sweeping Strikes
}
self_debuffs.WARRIOR = {}
pet_buffs.WARRIOR = {}
enemy_debuffs.WARRIOR = {}
enemy_debuffs.WARRIOR = {
	[1161] = 6, -- Challenging Shout
	[7922] = 1, -- Charge Stun
	[12809] = 5, -- Concussion Blow
	[12721] = 12, -- Deep Wounds
	[1160] = 30, [6190] = 30, [11554] = 30, [11555] = 30, [11556] = 30, -- Demoralizing Shout
	[676] = 10, -- Disarm
	[1715] = 15, [7372] = 15, [7373] = 15, -- Hamstring
	[23694] = 5, -- Improved Hamstring
	[20253] = 3, [20614] = 3, [20615] = 3, -- Intercept Stun
	[5246] = 8, -- Intimidating Shout
	[12705] = 6, -- Long Daze (Improved Pummel)
	[5530] = 3, -- Mace Stun Effect
	[694] = 6, [7400] = 6, [7402] = 6, [20559] = 6, [20560] = 6, -- Mocking Blow
	[12294] = 10, -- Mortal Strike
	[12323] = 6, -- Piercing Howl
	[772] = 9, [6546] = 12, [6547] = 15, [6548] = 18, [11572] = 21, [11573] = 21, [11574] = 21, -- Rend
	[12798] = 3, -- Revenge Stun
	[18498] = 3, -- Shield Bash - Silenced
	[7386] = 30, [7405] = 30, [8380] = 30, [11596] = 30, [11597] = 30, -- Sunder Armor
	[355] = 3, -- Taunt
	[6343] = 10, [8198] = 14, [8204] = 18, [8205] = 22, [11580] = 26, [11581] = 30, -- Thunder Clap
}

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
	[20594] = 8, -- Stoneform
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
	[20572] = 25, -- Blood Fury (Attack power)
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
	[20578] = 10, -- Cannibalize
	[7744]  = 5, -- Will of the Forsaken
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
	[20549] = 2, -- War Stomp
}

-- Troll
friend_buffs.Troll = {
	[23335] = true -- Silverwing Flag
}
friend_debuffs.Troll = {}
self_buffs.Troll = {
	[26635] = 10, -- Berserking
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
				tmp[spell] = v and true
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
