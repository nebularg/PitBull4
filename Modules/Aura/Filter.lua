-- Filter.lua : Code to handle Filtering the Auras.

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")

local spells = PitBull4.Spells.spell_durations

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
friend_buffs.DRUID = {
	[2893] = 8, -- Abolish Poison
	[22812] = 15, -- Barkskin
	[21849] = true, -- Gift of the Wild (60m)
	[29166] = 20, -- Innervate
	[24932] = true, -- Leader of the Pack
	[1126] = true , -- Mark of the Wild (30m)
	[24907] = true, -- Moonkin Aura
	[16810] = 45, [16811] = 45, [16812] = 45, [16813] = 45, [17329] = 45, -- Nature's Grasp
	[8936] = 21, [8938] = 21, [8939] = 21, [8940] = 21, [8941] = 21, [9750] = 21, [9856] = 21, [9857] = 21, [9858] = 21, -- Regrowth
	[774] = 12, [1058] = 12, [1430] = 12, [2090] = 12, [2091] = 12, [3627] = 12, [8910] = 12, [9839] = 12, [9840] = 12, [9841] = 12, [25299] = 12, -- Rejuvenation
	[467] = 600, [782] = 600, [1075] = 600, [8914] = 600, [9756] = 600,	[9756] = 600, -- Thorns
}
friend_debuffs.DRUID = {}
self_buffs.DRUID = {
	[1066] = true, -- Aquatic Form
	[5487] = true, -- Bear Form
	[9634] = true, -- Dire Bear Form
	[768] = true, -- Cat Form
	[16870] = 15, -- Clearcasting
	[1850] = 15, [9821] = 15, -- Dash
	[5229] = 10, -- Enrage
	[22842] = 10, [22895] = 10, [22896] = 10, -- Frenzied Regeneration
	[24858] = true, -- Moonkin Form
	[17116] = true, -- Nature's Swiftness
	[5215] = true, -- Prowl
	[5217] = 6, [6793] = 6, [9845] = 6, [9846] = 6, -- Tiger's Fury
	[740] = 10, [8918] = 10, [9862] = 10, [9863] = 10, -- Tranquility
	[783] = true, -- Travel Form
}
self_debuffs.DRUID = {}
pet_buffs.DRUID = {}
enemy_debuffs.DRUID = {
	[5211] = 2, [6798] = 3, [8983] = 4, -- Bash
	[5209] = 6, -- Challenging Roar
	[99] = 30, [1735] = 30, [9490] = 30, [9747] = 30, [9898] = 30, -- Demoralizing Roar
	[339] = 12, [1062] = 15, [5195] = 18, [5196] = 21, [9852] = 24, [9853] = 27, -- Entangling Roots
	[770] = 40, [778] = 40, [9749] = 40, [9907] = 40, -- Faerie Fire
	[17390] = 40, [17391] = 40, [17392] = 40, -- Faerie Fire (Feral)
	[19675] = 4, -- Feral Charge
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
friend_buffs.HUNTER = {
	[20043] = true, -- Aspect of the Wild
	[13159] = true, -- Aspect of the Pack
	[19506] = true, -- Trueshot Aura (30m)
}
friend_debuffs.HUNTER = {}
self_buffs.HUNTER = {
	[13161] = true, -- Aspect of the Beast
	[5118] = true, -- Aspect of the Cheetah
	[13165] = true, -- Aspect of the Hawk
	[13163] = true, -- Aspect of the Monkey
	[19263] = 10, -- Deterrence
	[6197] = true, -- Eagle Eye
	[1002] = 60, -- Eyes of the Beast
	[5384] = 360, -- Feign Death
	[24604] = 10, [24605] = 10, [24603] = 10, [24597] = 10, -- Furious Howl (Wolf pet)
	[3045] = 15, -- Rapid Fire
	[1494] = true, -- Track Beasts
	[19878] = true, -- Track Demons
	[19879] = true, -- Track Dragonkin
	[19880] = true, -- Track Elementals
	[19882] = true, -- Track Giants
	[19885] = true, -- Track Hidden
	[19883] = true, -- Track Humanoids
	[19884] = true, -- Track Undead
	[19579] = true, -- Spirit Bond
}
self_debuffs.HUNTER = {}
pet_buffs.HUNTER = {
	[1462] = 30, -- Beast Lore
	[19574] = 18, -- Bestial Wrath
	[23099] = 15, [23109] = 15, [23110] = 15, -- Dash
	[23145] = 15, [23147] = 15, [23148] = 15, -- Dive
	[1002] = 60, -- Eyes of the Beast
	[1539] = 20, -- Feed Pet
	[19615] = 8, -- Frenzy
	[136] = 5, [3111] = 5, [3661] = 5, [3662] = 5, [13542] = 5, [13543] = 5, [13544] = 5, -- Mend Pet
	[24450] = true, -- Prowl (Cat pet)
	[26064] = 12, -- Shell Shield (Turtle pet)
	[19579] = true, -- Spirit Bond
}
enemy_debuffs.HUNTER = {
	[1462] = 30, -- Beast Lore
	[25999] = 1, [26177] = 1, [26178] = 1, [26179] = 1, [26201] = 1, [27685] = 1, -- Boar Charge (Boar pet)
	[5116] = 4, -- Concussion Shot
	[19306] = 5, [20909] = 5, [20910] = 5, -- Counterattack
	[19185] = 5, -- Entrapment
	[13812] = 20, [14314] = 20, [14315] = 20, -- Explosive Trap
	[3355] = 10, [14308] = 15, [14309] = 20, -- Freezing Trap
	[13810] = 30, -- Frost Trap
	[1130] = 120, [14323] = 120, [14324] = 120, [14325] = 120, -- Hunter's Mark
	[13797] = 15, [14298] = 15, [14299] = 15, [14300] = 15, [14301] = 15, -- Immolation Trap
	[19410] = 3, -- Improved Concussion Shot
	[19229] = 5, -- Improved Wing Clip
	[24394] = 3, -- Intimidation
	[1513] = 10, [14326] = 15, [14327] = 20, -- Scare Beast
	[19503] = 4, -- Scatter Shot
	[24423] = 4, [24577] = 4, [24578] = 4, [24579] = 4, -- Screech (Bat pet)
	[24640] = 10, [24583] = 10, [24586] = 10, [24587] = 10, -- Scorpid Poison (Scorpid pet)
	[3043] = 20, [14275] = 20, [14276] = 20, [14277] = 20, -- Scorpid Sting
	[1978] = 15, [13549] = 15, [13550] = 15, [13551] = 15, [13552] = 15, [13553] = 15, [13554] = 15, [13555] = 15, [25295] = 15, -- Serpent Sting
	[1515] = 20, -- Tame Beast
	[3034] = 8, [14279] = 8, [14280] = 8, -- Viper Sting
	[2974] = 10, [14267] = 10, [14268] = 10, -- Wing Clip
	[19386] = 12, [24132] = 12, [24133] = 12, -- Wyvern Sting (Sleep)
	[24131] = 12, [24134] = 12, [24135] = 12, -- Wyvern Sting (Damage)
}

-- Mage
friend_buffs.MAGE = {
	[1008] = 600, [8455] = 600, [10169] = 600, [10170] = 600, -- Amplify Magic
	[23028] = true, -- Arcane Brilliance (60m)
	[1459] = true, -- Arcane Intellect (30m)
	[2855] = 120, -- Detect Magic
	[604] = 600, [8450] = 600, [8451] = 600, [10173] = 600, [10174] = 600, -- Dampen Magic
	[130] = 30, -- Slow Fall
}
friend_debuffs.MAGE = {}
self_buffs.MAGE = {
	[12042] = 15, -- Arcane Power
	[5143] = true, [7268] = true, -- Arcane Missiles
	[10] = 8, -- Blizzard
	[12536] = 15, -- Clearcasting
	[28682] = true, -- Combustion
	[12051] = 8, -- Evocation
	[543] = 30, [8457] = 30, [8458] = 30, [10223] = 30, [10225] = 30, -- Fire Ward
	[6143] = 30, [8461] = 30, [8462] = 30, [10177] = 30, [28609] = 30, -- Frost Ward
	[11426] = 60, [13031] = 60, [13032] = 60, [13033] = 60, -- Ice Barrier
	[11958] = 10, -- Ice Block
	[6117] = true, -- Mage Armor (30m)
	[1463] = 60, [8494] = 60, [8495] = 60, [10191] = 60, [10192] = 60, [10193] = 60, -- Mana Shield
	[12043] = 16, -- Presence of Mind
}
self_debuffs.MAGE = {}
pet_buffs.MAGE = {}
enemy_debuffs.MAGE = {
	[11113] = 6, [13018] = 6, [13019] = 6, [13020] = 6, [13021] = 6, -- Blast Wave
	[6136] = 5, -- Chilled (Frost Armor)
	[12484] = 1.5, [12485] = 1.5, [12486] = 1.5, -- Chilled (Improved Blizzard)
	[120] = 8, [8492] = 8, [10159] = 8, [10160] = 8, [10161] = 8, -- Cone of Cold
	[18469] = 4, -- Counterspell - Silence (Improved Counterspell)
	[2855] = 120, -- Detect Magic
	[22959] = 30, -- Fire Vulnerability
	[133] = 4, [143] = 6, [145] = 6, [3140] = 8, [8400] = 8, [8401] = 8, [8402] = 8, [10148] = 8, [10149] = 8, [10150] = 8, [10151] = 8, [25306] = 8, -- Fireball
	[2120] = 8, [2121] = 8, [8422] = 8, [8423] = 8, [10215] = 8, [10216] = 8, -- Flamestrike
	[122] = 8, [865] = 8, [6131] = 8, [10230] = 8, -- Frost Nova
	[12494] = 5, -- Frostbite
	[116] = 5, [205] = 6, [837] = 6, [7322] = 7, [8406] = 7, [8407] = 8, [8408] = 8, [10179] = 9, [10180] = 9, [10181] = 9, [25304] = 9, -- Frostbolt
	[12654] = 4, -- Ignite
	[12355] = 2, -- Impact
	[118] = 20, [12824] = 30, [12825] = 40, [12826] = 50, [28270] = 50, [28271] = 50, [28272] = 50, -- Polymorph
	[11366] = 12, [12505] = 12, [12522] = 12, [12523] = 12, [12524] = 12, [12525] = 12, [12526] = 12, [18809] = 12, -- Pyroblast
	[12579] = 15, -- Winter's Chill
}

-- Paladin
friend_buffs.PALADIN = {
	[1044] = 10, -- Blessing of Freedom
	[19977] = 300, [19978] = 300, [19979 ] = 300, -- Blessing of Light
	[20217] = 300, -- Blessing of Kings
	[19740] = 300, [19834] = 300, [19835] = 300, [19836] = 300, [19837] = 300, [19838] = 300, [25291] = 300, -- Blessing of Might
	[1022] = 6, [5599] = 8, [10278] = 10, -- Blessing of Protection
	[6940] = 10, [20729] = 10, -- Blessing of Sacrifice
	[20911] = 300, [20912] = 300, [20913] = 300, -- Blessing of Sanctuary
	[1038] = 300, -- Blessing of Salvation
	[19742] = 300, [19850] = 300, [19852] = 300, [19853] = 300, [19854] = 300, [25290] = 300, -- Blessing of Wisdom
	[19746] = true, -- Concentration Aura
	[465] = true, -- Devotion Aura
	[19891] = true, -- Fire Resistance Aura
	[19888] = true, -- Frost Resistance Aura
	[25890] = 900, -- Greater Blessing of Light
	[25898] = 900, -- Greater Blessing of Kings
	[25782] = 900, [25916] = 900, -- Greater Blessing of Might
	[25899] = 900, -- Greater Blessing of Sanctuary
	[25895] = 900, -- Greater Blessing of Salvation
	[25894] = 900, [25918] = 900, -- Greater Blessing of Wisdom
	[20233] = 120, [20236] = 120, -- Improved Lay on Hands
	[7294] = true, -- Retribution Aura
	[19876] = true, -- Shadow Resistance Aura
}
friend_debuffs.PALADIN = {
	[25771] = 60, -- Forbearance
}
self_buffs.PALADIN = {
	[19753] = 180, -- Divine Intervention
	[20216] = true, -- Divine Favor
	[498] = 6, [5573] = 8, -- Divine Protection
	[642] = 10, [1020] = 12, -- Divine Shield
	[20925] = 10, [20927] = 10, [20928] = 10, -- Holy Shield
	[20128] = 10, -- Redoubt
	[25780] = true, -- Righteous Fury
	[20375] = 30, [20915] = 30, [20918] = 30, [20919] = 30, [20920] = 30, -- Seal of Command
	[20164] = 30, -- Seal of Justice
	[20165] = 30, [20347] = 30, [20348] = 30, [20349] = 30, -- Seal of Light
	[21084] = 30, [20287] = 30, [20288] = 30, [20289] = 30, [20290] = 30, [20291] = 30, [20292] = 30, [20293] = 30, -- Seal of Righteousness
	[20162] = 30, [20305] = 30, [20306] = 30, [20307] = 30, [20308] = 30, [21082] = 30, -- Seal of the Crusader
	[20166] = 30, [20356] = 30, [20357] = 30, -- Seal of Wisdom
	[23214] = true, -- Summon Charger
	[13819] = true, -- Summon Warhorse
}
self_debuffs.PALADIN = {}
pet_buffs.PALADIN = {}
enemy_debuffs.PALADIN = {
	[26573] = 8, [20116] = 8, [20922] = 8, [20923] = 8, [20924] = 8, -- Consecration
	[853] = 3, [5588] = 4, [5589] = 5, [10308] = 6, -- Hammer of Justice
	[20185] = 10, [20344] = 10, [20345] = 10, [20346] = 10, -- Judgement of Light
	[20184] = 10, -- Judgement of Justice
	[21183] = 10, [20188] = 10, [20300] = 10, [20301] = 10, [20302] = 10, [20303] = 10, -- Judgement of the Crusader
	[20186] = 10, [20354] = 10, [20355] = 10, -- Judgement of Wisdom
	[20066] = 6, -- Repentance
	[2878] = 10, [5627] = 15, [5627] = 20, -- Turn Undead
	[20050] = 8, -- Vengeance
	[67] = 10, -- Vindication
}

-- Priest
friend_buffs.PRIEST = {
	[552] = 20, -- Abolish Disease
	[14752] = true, -- Divine Spirit (30m)
	[6346] = 600, -- Fear Ward (Dwarf)
	[14893] = 15, [15357] = 15, [15359] = 15, -- Inspiration
	[1706] = 120, -- Levitate
	[7001] = 10, [27873] = 10, [27874] = 10, -- Lightwell Renew
	[605] = true, -- Mind Control
	[2096] = 60, [10909] = 60, -- Mind Vision
	[10060] = 15, -- Power Infusion
	[1243] = true, -- Power Word: Fortitude (30m)
	[17] = 30, [592] = 30, [600] = 30, [3747] = 30, [6065] = 30, [6066] = 30, [10898] = 30, [10899] = 30, [10900] = 30, [10901] = 30, -- Power Word: Shield
	[21562] = true, -- Prayer of Fortitude (60m)
	[27683] = true, -- Prayer of Shadow Protection (20m)
	[27681] = true, -- Prayer of Spirit (60m)
	[139] = 15, [6074] = 15, [6075] = 15, [6076] = 15, [6077] = 15, [6078] = 15, [10927] = 15, [10928] = 15, [10929] = 15, [25315] = 15, -- Renew
	[10958] = 600, -- Shadow Protection
}
friend_debuffs.PRIEST = {
	[6788] = 15, -- Weakened Soul
}
self_buffs.PRIEST = {
	[27813] = 6, [27817] = 6, [27818] = 6, -- Blessed Recovery
	[2651] = 15, [19289] = 15, [19291] = 15, [19292] = 15, [19293] = 15, -- Elune's Grace (Night Elf)
	[586] = 10, [9578] = 10, [9579] = 10, [9592] = 10, [10941] = 10, [10942] = 10, -- Fade
	[13896] = 15, [19271] = 15, [19273] = 15, [19274] = 15, [19275] = 15, -- Feedback (Human)
	[14743] = 6, [27828] = 6, -- Focused Casting
	[588] = 600, [7128] = 600, [602] = 600, [1006] = 600, [1006] = 600, [10952] = 600, -- Inner Fire
	[14751] = true, -- Inner Focus
	[15473] = true, -- Shadow Form
	[18137] = 600, [19308] = 600, [19309] = 600, [19310] = 600, [19311] = 600, [19312] = 600, -- Shadowguard (Troll)
	[27827] = 10, -- Spirit of Redemption
	[15271] = 15, -- Spirit Tap
	[2652] = 600, [19261] = 600, [19262] = 600, [19264] = 600, [19265] = 600, [19266] = 600, -- Touch of Weakness (Undead)
}
self_debuffs.PRIEST = {}
pet_buffs.PRIEST = {}
enemy_debuffs.PRIEST = {
	[15269] = 3, -- Blackout
	[2944] = 24, [19276] = 24, [19277] = 24, [19278] = 24, [19279] = 24, [19280] = 24, -- Devouring Plague (Undead)
	[9035] = 120, [19281] = 120, [19282] = 120, [19283] = 120, [19284] = 120, [19285] = 120, -- Hex of Weakness (Troll)
	[14914] = 10, [15261] = 10, [15262] = 10, [15263] = 10, [15264] = 10, [15265] = 10, [15266] = 10, [15267] = 10, -- Holy Fire
	[605] = 60, [10911] = 60, [10912] = 60, -- Mind Control
	[15407] = 3, [17311] = 3, [17312] = 3, [17313] = 3, [17314] = 3, [18807] = 3, -- Mind Flay
	[453] = 15, [8192] = 15, [10953] = 15, -- Mind Soothe
	[2096] = true, -- Mind Vision
	[8122] = 8, [8124] = 8, [10888] = 8, [10890] = 8, -- Psychic Scream
	[9484] = 30, [9485] = 40, [10955] = 50, -- Shackle Undead
	[15258] = 15, -- Shadow Vulnerability
	[589] = 8, [594] = 8, [970] = 8, [992] = 8, [2767] = 8, [10892] = 8, [10893] = 8, [10894] = 8, -- Shadow Word: Pain
	[15487] = 5, -- Silence
	[10797] = 6, [19296] = 6, [19299] = 6, [19302] = 6, [19303] = 6, [19304] = 6, [19305] = 6, -- Starshards (Night Elf)
	[15286] = 60, -- Vampiric Embrace
}

-- Rogue
friend_buffs.ROGUE = {}
friend_debuffs.ROGUE = {}
self_buffs.ROGUE = {
	[13750] = 15, -- Adrenaline Rush
	[13877] = 15, -- Blade Flurry
	[14177] = true, -- Cold Blood
	[2836] = true, -- Detect Traps
	[5277] = 15, -- Evasion
	[14278] = 7, -- Ghostly Strike
	[14143] = 20, -- Remorseless
	[5171] = true, -- Slice and Dice (6+3*combo points)
	[2983] = 15, [8696] = 15, [11305] = 15, -- Sprint
	[1784] = true, -- Stealth
	[11327] = 10, [11329] = 10, -- Vanish
}
self_debuffs.ROGUE = {}
pet_buffs.ROGUE = {}
enemy_debuffs.ROGUE = {
	[2094] = 10, -- Blind
	[1833] = 4, -- Cheap Shot
	[3409] = 12, [11201] = 12, -- Crippling Poison
	[2818] = 12, [2819] = 12, [11353] = 12, [11354] = 12, [25349] = 12, -- Deadly Poison
	[8647] = 30, [8649] = 30, [8650] = 30, [11197] = 30, [11198] = 30, -- Expose Armor
	[703] = 18, [8631] = 18, [8632] = 18, [8633] = 18, [11289] = 18, [11290] = 18, -- Garrote
	[1776] = 4, [1777] = 4, [8629] = 4, [11285] = 4, [11286] = 4, -- Gouge
	[16511] = 15, [17347] = 15, [17348] = 15, -- Hemorrhage
	[18425] = 2, -- Kick - Silenced (Improved Kick)
	[408] = 5, [8643] = 6, -- Kidney Shot (0/1+combo points)
	[5530] = 3, -- Mace Stun Effect (Mace Specialization)
	[5760] = 10, [8692] = 12, [11398] = 14, -- Mind-numbing Poison
	[14251] = 6, -- Riposte
	[1943] = 16, [8639] = 16, [8640] = 16, [11273] = 16, [11274] = 16, [11275] = 16, -- Rupture (6+2*combo points)
	[6770] = 25, [2070] = 35, [11297] = 45, -- Sap
	[13218] = 15, [13222] = 15, [13223] = 15, [13224] = 15, -- Wound Poison
}

-- Shaman
friend_buffs.SHAMAN = {
	[6177] = 15, [16236] = 15, [16237] = 15, -- Ancestral Fortitude
	[8185] = true, -- Fire Resistance Totem
	[8182] = true, -- Frost Resistance Totem
	[8836] = true, -- Grace of Air Totem
	[29203] = 15, -- Healing Way
	[5672] = true, -- Healing Stream Totem
	[324] = 600, [325] = 600, [905] = 600, [945] = 600, [8134] = 600, [10431] = 600, [10432] = 600, -- Lightning Shield
	[5677] = true, -- Mana Spring Totem
	[16191] = true, -- Mana Tide Totem
	[10596] = true, -- Nature Resistance Totem
	[6495] = true, -- Sentry Totem
	[8072] = true, -- Stoneskin Totem
	[8076] = true, -- Strength of Earth Totem
	[25909] = true, -- Tranquil Air Totem
	[131] = 600, -- Water Breathing
	[546] = 600, -- Water Walking
	[15108] = true, -- Windwall Totem
}
friend_debuffs.SHAMAN = {}
self_buffs.SHAMAN = {
	[16246] = 15, -- Clearcasting
	[30165] = 10, [29177] = 10, [29178] = 10, -- Elemental Devastation
	[16166] = true, -- Elemental Mastery
	[6196] = 60, -- Far Sight
	[29063] = 6, -- Focused Casting
	[16257] = 15, [16277] = 15, [16278] = 15, [16279] = 15, [16280] = 15, -- Flurry
	[2645] = true, -- Ghost Wolf
	[16188] = true, -- Nature's Swiftness
}
self_debuffs.SHAMAN = {}
pet_buffs.SHAMAN = {}
enemy_debuffs.SHAMAN = {
	[3600] = true, -- Earthbind
	[8056] = 8, [8058] = 8, [10472] = 8, [10473] = 8, -- Frost Shock
	[8034] = 8, [8037] = 8, [10458] = 8, [16352] = 8, [16353] = 8, -- Frostbrand Attack
	[8050] = 12, [8052] = 12, [8053] = 12, [10447] = 12, [10448] = 12, [29228] = 12, -- Flame Shock
	[17364] = 12, -- Stormstrike
}

-- Warlock
friend_buffs.WARLOCK = {
	[132] = 600, [2970] = 600, [11743] = 600, -- Detect Invisibility
	[1098] = 300, [11725] = 300, [11726] = 300, -- Enslave Demon
	[2947] = 180, [8316] = 180, [8317] = 180, [11770] = 180, [11771] = 180, -- Fire Shield (Imp)
	[19480] = true, -- Paranoia
	[20707] = true, -- Soulstone Resurrection (30m)
	[19478] = 60, [19655] = 60, [19656] = 60, [19660] = 60, -- Tainted Blood (Felhunter)
	[5697] = 600, -- Unending Breath
}
friend_debuffs.WARLOCK = {}
self_buffs.WARLOCK = {
	[18288] = 30, -- Amplify Curse
	[18789] = true, -- Burning Wish (Demonic Sacrifice) (30m)
	[706] = true, -- Demon Armor (30m)
	[687] = true, -- Demon Skin (30m)
	[126] = 45, -- Eye of Kilrogg
	[18708] = 15, -- Fel Domination
	[18792] = true, -- Fel Energy (Demonic Sacrifice) (30m)
	[18790] = true, -- Fel Stamina (Demonic Sacrifice) (30m)
	[755] = 10, [3698] = 10, [3699] = 10, [3700] = 10, [11693] = 10, [11694] = 10, [11695] = 10, -- Health Funnel
	[1949] = 15, [11683] = 15, [11684] = 15, -- Hellfire
	[23841] = true, -- Master Demonologist
	[5740] = 8, [6219] = 8, [11677] = 8, [11678] = 8, -- Rain of Fire
	[7812] = 30, [19438] = 30, [19440] = 30, [19441] = 30, [19442] = 30, [19443] = 30, -- Sacrifice (Voidwalker)
	[17941] = 10, -- Shadow Trance (Nightfall)
	[6229] = 30, [11739] = 30, [11740] = 30, [28610] = 30, -- Shadow Ward
	[128] = 60, [17729] = 60, -- Spellstone
	[25228] = true, -- Soul Link
	[18371] = 10, -- Soul Siphon (Improved Drain Soul)
	[5784] = true, -- Summon Felsteed
	[23161] = true, -- Summon Dreadsteed
	[18791] = true, -- Touch of Shadow (Demonic Sacrifice) (30m)
}
self_debuffs.WARLOCK = {}
pet_buffs.WARLOCK = {
	[6307] = true, -- Blood Pact (Imp)
	[17767] = 10, [17850] = 10, [17851] = 10, [17852] = 10, [17853] = 10, [17854] = 10, -- Consume Shadows (Voidwalker)
	[2947] = true, -- Fire Shield (Imp)
	[755] = true, -- Health Funnel
	[7870] = 300, -- Lesser Invisibility (Succubus)
	[23841] = true, -- Master Demonologist
	[4511] = true, -- Phase Shift
	[25228] = true, -- Soul Link
}
enemy_debuffs.WARLOCK = {
	[18118] = 5, -- Aftermath
	[710] = 20, [18647] = 30, -- Banish
	[172] = 12, [6222] = 15, [6223] = 18, [7648] = 18, [11671] = 18, [11672] = 18, [25311] = 18, -- Corruption
	[980] = 24, [1014] = 24, [6217] = 24, [11711] = 24, [11712] = 24, [11713] = 24, -- Curse of Agony
	[603] = 60, -- Curse of Doom
	[1490] = 300, [11721] = 300, [11722] = 300, -- Curse of Elements
	[18223] = 12, -- Curse of Exhaustion
	[704] = 300, [7658] = 300, [7659] = 300, [11717] = 300, -- Curse of Recklessness
	[17862] = 300, [17937] = 300, -- Curse of Shadows
	[1714] = 30, [11719] = 30, -- Curse of Tongues
	[702] = 120, [1108] = 120, [6205] = 120, [7646] = 120, [11707] = 120, [11708] = 120, -- Curse of Weakness
	[6789] = 3, [17925] = 3, [17926] = 3, -- Death Coil
	[689] = 5, [699] = 5, [709] = 5, [7651] = 5, [11699] = 5, [11700] = 5, -- Drain Life
	[5138] = 5, [6226] = 5, [11703] = 5, [11704] = 5, -- Drain Mana
	[1120] = 15, [8288] = 15, [8289] = 15, [11675] = 15, -- Drain Soul
	[5782] = 10, [6213] = 15, [6215] = 20, -- Fear
	[5484] = 10, [17928] = 15, -- Howl of Terror
	[348] = 15, [707] = 15, [1094] = 15, [2941] = 15, [11665] = 15, [11667] = 15, [11668] = 15, [25309] = 15, -- Immolate
	[18093] = 3, -- Pyroclasm
	[6358] = 15, -- Seduction (Succubus)
	[17877] = 5, [18867] = 5, [18868] = 5, [18869] = 5, [18870] = 5, [18871] = 5, -- Shadowburn
	[18265] = 30, [18879] = 30, [18880] = 30, [18881] = 30, -- Siphon Life
	[24259] = 3, -- Spell Lock
	[17794] = 12, [17798] = 12, [17797] = 12, [17799] = 12, [17800] = 12, -- Shadow Vulnerability
}

-- Warrior
friend_buffs.WARRIOR = {
	[5242] = 120, [6192] = 120, [6673] = 120, [11549] = 120, [11550] = 120, [11551] = 120, [25289] = 120, -- Battle Shout
}
friend_debuffs.WARRIOR = {}
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
	[5246] = 8, [20511] = 8, -- Intimidating Shout
	[12705] = 6, -- Long Daze (Improved Pummel)
	[5530] = 3, -- Mace Stun Effect
	[694] = 6, [7400] = 6, [7402] = 6, [20559] = 6, [20560] = 6, -- Mocking Blow
	[12294] = 10, [21551] = 10, [21552] = 10, [21553] = 10, -- Mortal Strike
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
self_buffs.Human = {
	[13896] = true, -- Feedback (Priest)
}
self_debuffs.Human = {}
pet_buffs.Human = {}
enemy_debuffs.Human = {}

-- Dwarf
friend_buffs.Dwarf = {
	[6346] = true, -- Fear Ward
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
	[2651] = true, -- Elune's Grace (Priest)
	[20580] = true, -- Shadowmeld
}
self_debuffs.NightElf = {}
pet_buffs.NightElf = {}
enemy_debuffs.NightElf = {
	[10797] = true, -- Starshards (Priest)
}

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
	[2944] = true, -- Devouring Plague (Priest)
	[2652] = true, -- Touch of Weakness (Priest)
	[7744] = 5, -- Will of the Forsaken
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
	[18137] = true, -- Shadowguard (Priest)
}
self_debuffs.Troll = {}
pet_buffs.Troll = {}
enemy_debuffs.Troll = {
	[9035] = true, -- Hex of Weakness (Priest)
}


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
				if v ~= true then
					spells[id] = v
				end
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
