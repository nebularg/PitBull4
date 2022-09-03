-- Filter.lua : Code to handle Filtering the Auras.

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")

local wow_bcc = PitBull4.wow_bcc

local _, player_class = UnitClass("player")

--- Return the DB dictionary for the specified filter.
-- Filter Types should use this to get their db.
-- @param filter the name of the filter
-- @usage local db = PitBull4_Aura:GetFilterDB("myfilter")
-- @return the DB dictionary for the specified filter or nil
function PitBull4_Aura:GetFilterDB(filter)
	return self.db.profile.global.filters[filter]
end

-- Setup the data for who can dispel what types of auras.
-- dispel in this context means remove from friendly players
local can_dispel = {
	DEATHKNIGHT = {},
	DEMONHUNTER = {},
	DRUID = {},
	HUNTER = {},
	MAGE = {},
	MONK = {},
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
	DEATHKNIGHT = {},
	DEMONHUNTER = {},
	DRUID = {},
	HUNTER = {},
	MAGE = {},
	MONK = {},
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
	[2893] = true, -- Abolish Poison
	[22812] = true, -- Barkskin
	[21849] = true, -- Gift of the Wild (60m)
	[29166] = true, -- Innervate
	[24932] = true, -- Leader of the Pack
	[33763] = wow_bcc, -- Lifebloom
	[1126] = true , -- Mark of the Wild (30m)
	[24907] = true, -- Moonkin Aura
	[16810] = true, -- Nature's Grasp
	[8936] = true, -- Regrowth
	[774] = true, -- Rejuvenation
	[33891] = wow_bcc, -- Tree of Life
	[467] = true, -- Thorns
}
friend_debuffs.DRUID = {}
self_buffs.DRUID = {
	[1066] = true, -- Aquatic Form
	[5487] = true, -- Bear Form
	[9634] = true, -- Dire Bear Form
	[768] = true, -- Cat Form
	[16870] = true, -- Clearcasting
	[1850] = true, -- Dash
	[5229] = true, -- Enrage
	[33943] = wow_bcc, -- Flight Form
	[22842] = true, -- Frenzied Regeneration
	[24858] = true, -- Moonkin Form
	[16886] = true, -- Nature's Grace
	[17116] = true, -- Nature's Swiftness
	[5215] = true, -- Prowl
	[40120] = wow_bcc, -- Swift Flight Form
	[5217] = true, -- Tiger's Fury
	[740] = true, -- Tranquility
	[783] = true, -- Travel Form
}
self_debuffs.DRUID = {}
pet_buffs.DRUID = {}
enemy_debuffs.DRUID = {
	[5211] = true, -- Bash
	[5209] = true, -- Challenging Roar
	[33786] = wow_bcc, -- Cyclone
	[99] = true, -- Demoralizing Roar
	[339] = true, -- Entangling Roots
	[770] = true, -- Faerie Fire
	[17390] = true, -- Faerie Fire (Feral)
	[19675] = true, -- Feral Charge
	[6795] = true, -- Growl
	[2637] = true, -- Hibernate
	[17401] = true, -- Hurricane
	[5570] = true, -- Insect Swarm
	[33745] = wow_bcc, -- Lacerate
	[33876] = wow_bcc, -- Mangle (Cat)
	[33878] = wow_bcc, -- Mangle (Bear)
	[8921] = true, -- Moonfire
	[9005] = true, -- Pounce
	[9007] = true, -- Pounce Bleed
	[1822] = true, -- Rake
	[1079] = true, -- Rip
	[2908] = true, -- Soothe Animal
	[16922] = true, -- Starfire Stun
}

-- Hunter
friend_buffs.HUNTER = {
	[20043] = true, -- Aspect of the Wild
	[13159] = true, -- Aspect of the Pack
	[34477] = wow_bcc, -- Misdirection
	[19506] = true, -- Trueshot Aura (30m)
}
friend_debuffs.HUNTER = {}
self_buffs.HUNTER = {
	[13161] = true, -- Aspect of the Beast
	[5118] = true, -- Aspect of the Cheetah
	[13165] = true, -- Aspect of the Hawk
	[13163] = true, -- Aspect of the Monkey
	[34074] = wow_bcc, -- Aspect of the Viper
	[19263] = true, -- Deterrence
	[6197] = true, -- Eagle Eye
	[1002] = true, -- Eyes of the Beast
	[5384] = true, -- Feign Death
	[24604] = true, -- Furious Howl (Wolf pet)
	[3045] = true, -- Rapid Fire
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
	[1462] = true, -- Beast Lore
	[19574] = true, -- Bestial Wrath
	[23099] = true, -- Dash
	[23145] = true, -- Dive
	[1002] = true, -- Eyes of the Beast
	[1539] = true, -- Feed Pet
	[19615] = true, -- Frenzy
	[136] = true, -- Mend Pet
	[24450] = true, -- Prowl (Cat pet)
	[26064] = true, -- Shell Shield (Turtle pet)
	[19579] = true, -- Spirit Bond
}
enemy_debuffs.HUNTER = {
	[1462] = true, -- Beast Lore
	[25999] = true, -- Boar Charge (Boar pet)
	[5116] = true, -- Concussion Shot
	[19306] = true, -- Counterattack
	[19185] = true, -- Entrapment
	[1543] = true, -- Flare
	[13812] = true, -- Explosive Trap
	[3355] = true, -- Freezing Trap
	[13810] = true, -- Frost Trap
	[1130] = true, -- Hunter's Mark
	[13797] = true, -- Immolation Trap
	[19410] = true, -- Improved Concussion Shot
	[19229] = true, -- Improved Wing Clip
	[24394] = true, -- Intimidation
	[1513] = true, -- Scare Beast
	[19503] = true, -- Scatter Shot
	[24423] = true, -- Screech (Bat pet)
	[24640] = true, -- Scorpid Poison (Scorpid pet)
	[3043] = true, -- Scorpid Sting
	[1978] = true, -- Serpent Sting
	[34490] = wow_bcc, -- Silencing Shot
	[1515] = true, -- Tame Beast
	[3034] = true, -- Viper Sting
	[2974] = true, -- Wing Clip
	[19386] = true, -- Wyvern Sting (Sleep)
	[24131] = true, -- Wyvern Sting (Damage)
}

-- Mage
friend_buffs.MAGE = {
	[1008] = true, -- Amplify Magic
	[23028] = true, -- Arcane Brilliance (60m)
	[1459] = true, -- Arcane Intellect (30m)
	[604] = true, -- Dampen Magic
	[2855] = true, -- Detect Magic
	[130] = true, -- Slow Fall
}
friend_debuffs.MAGE = {}
self_buffs.MAGE = {
	[30451] = wow_bcc, -- Arcane Blast
	[12042] = true, -- Arcane Power
	[5143] = true, [7268] = true, -- Arcane Missiles
	[10] = true, -- Blizzard
	[12536] = true, -- Clearcasting
	[28682] = true, -- Combustion
	[12051] = true, -- Evocation
	[543] = true, -- Fire Ward
	[168] = true, -- Frost Armor (30m)
	[6143] = true, -- Frost Ward
	[7302] = true, -- Ice Armor (30m)
	[11426] = true, -- Ice Barrier
	[11958] = true, -- Ice Block
	[66] = true, -- Invisibility
	[6117] = true, -- Mage Armor (30m)
	[1463] = true, -- Mana Shield
	[30482] = wow_bcc, -- Molten Armor (30m)
	[12043] = true, -- Presence of Mind
}
self_debuffs.MAGE = {}
pet_buffs.MAGE = {}
enemy_debuffs.MAGE = {
	[11113] = true, -- Blast Wave
	[6136] = true, -- Chilled (Frost Armor)
	[12484] = true, -- Chilled (Improved Blizzard)
	[120] = true, -- Cone of Cold
	[18469] = true, -- Counterspell - Silence (Improved Counterspell)
	[2855] = true, -- Detect Magic
	[31661] = wow_bcc, -- Dragon's Breath
	[22959] = true, -- Fire Vulnerability
	[133] = true, -- Fireball
	[2120] = true, -- Flamestrike
	[122] = true, -- Frost Nova
	[12494] = true, -- Frostbite
	[116] = true, -- Frostbolt
	[12654] = true, -- Ignite
	[12355] = true, -- Impact
	[118] = true, -- Polymorph
	[11366] = true, -- Pyroblast
	[31589] = wow_bcc, -- Slow
	[12579] = true, -- Winter's Chill
}

-- Paladin
friend_buffs.PALADIN = {
	[1044] = true, -- Blessing of Freedom
	[19977] = true, -- Blessing of Light
	[20217] = true, -- Blessing of Kings
	[19740] = true, -- Blessing of Might
	[1022] = true, -- Blessing of Protection
	[6940] = true, -- Blessing of Sacrifice
	[20911] = true, -- Blessing of Sanctuary
	[1038] = true, -- Blessing of Salvation
	[19742] = true, -- Blessing of Wisdom
	[19746] = true, -- Concentration Aura
	[465] = true, -- Devotion Aura
	[32223] = wow_bcc, -- Crusader Aura
	[19891] = true, -- Fire Resistance Aura
	[19888] = true, -- Frost Resistance Aura
	[25890] = true, -- Greater Blessing of Light
	[25898] = true, -- Greater Blessing of Kings
	[25782] = true, -- Greater Blessing of Might
	[25899] = true, -- Greater Blessing of Sanctuary
	[25895] = true, -- Greater Blessing of Salvation
	[25894] = true, -- Greater Blessing of Wisdom
	[20233] = true, -- Improved Lay on Hands
	[7294] = true, -- Retribution Aura
	[19876] = true, -- Shadow Resistance Aura
}
friend_debuffs.PALADIN = {
	[25771] = true, -- Forbearance
}
self_buffs.PALADIN = {
	[31884] = wow_bcc, -- Avenging Wrath
	[19753] = true, -- Divine Intervention
	[20216] = true, -- Divine Favor
	[31842] = wow_bcc, -- Divine Illumination
	[498] = true, -- Divine Protection
	[642] = true, -- Divine Shield
	[20925] = true, -- Holy Shield
	[31834] = wow_bcc, -- Light's Grace
	[20128] = true, -- Redoubt
	[25780] = true, -- Righteous Fury
	[31892] = wow_bcc, -- Seal of Blood (Blood Elf)
	[20375] = true, -- Seal of Command
	[348704] = wow_bcc, -- Seal of Corruption (Blood Elf)
	[20164] = true, -- Seal of Justice
	[20165] = true, -- Seal of Light
	[21084] = true, -- Seal of Righteousness
	[20162] = true, -- Seal of the Crusader
	[348700] = wow_bcc, -- Seal of the Martyr (Draenei, Dwarf, Human)
	[20166] = true, -- Seal of Wisdom
	[31801] = wow_bcc, -- Seal of Vengenance (Draenei, Dwarf, Human)
	[23214] = true, -- Summon Charger
	[13819] = true, -- Summon Warhorse
}
self_debuffs.PALADIN = {}
pet_buffs.PALADIN = {}
enemy_debuffs.PALADIN = {
	[31935] = wow_bcc, -- Avenger's Shield
	[356110] = wow_bcc, -- Blood Corruption
	[26573] = true, -- Consecration
	[853] = true, -- Hammer of Justice
	[20185] = true, -- Judgement of Light
	[20184] = true, -- Judgement of Justice
	[21183] = true, -- Judgement of the Crusader
	[20186] = true, -- Judgement of Wisdom
	[20066] = true, -- Repentance
	[31790] = wow_bcc, -- Righteous Defense
	[2878] = true, -- Turn Undead
	[20050] = true, -- Vengeance
	[67] = true, -- Vindication
}

-- Priest
friend_buffs.PRIEST = {
	[552] = true, -- Abolish Disease
	[14752] = true, -- Divine Spirit (30m)
	[6346] = true, -- Fear Ward (Dwarf)
	[14893] = true, -- Inspiration
	[1706] = true, -- Levitate
	[7001] = true, -- Lightwell Renew
	[605] = true, -- Mind Control
	[2096] = true, -- Mind Vision
	[33206] = wow_bcc, -- Pain Suppression
	[10060] = true, -- Power Infusion
	[1243] = true, -- Power Word: Fortitude (30m)
	[17] = true, -- Power Word: Shield
	[21562] = true, -- Prayer of Fortitude (60m)
	[41635] = wow_bcc, -- Prayer of Mending
	[27683] = true, -- Prayer of Shadow Protection (20m)
	[27681] = true, -- Prayer of Spirit (60m)
	[139] = true, -- Renew
	[10958] = true, -- Shadow Protection
	[32548] = wow_bcc, -- Symbol of Hope
}
friend_debuffs.PRIEST = {
	[6788] = true, -- Weakened Soul
}
self_buffs.PRIEST = {
	[27813] = true, -- Blessed Recovery
	[34754] = wow_bcc, -- Clearcasting
	[2651] = true, -- Elune's Grace (Night Elf)
	[586] = true, -- Fade
	[13896] = true, -- Feedback (Human)
	[14743] = true, -- Focused Casting
	[45237] = wow_bcc, -- Focused Will
	[588] = true, -- Inner Fire
	[14751] = true, -- Inner Focus
	[15473] = true, -- Shadow Form
	[18137] = true, -- Shadowguard (Troll)
	[27827] = true, -- Spirit of Redemption
	[15271] = true, -- Spirit Tap
	[33151] = wow_bcc, -- Surge of Light
	[2652] = true, -- Touch of Weakness (Undead)
}
self_debuffs.PRIEST = {}
pet_buffs.PRIEST = {}
enemy_debuffs.PRIEST = {
	[15269] = true, -- Blackout
	[44041] = wow_bcc, -- Chastise
	[2944] = true, -- Devouring Plague (Undead)
	[9035] = true, -- Hex of Weakness (Troll)
	[14914] = true, -- Holy Fire
	[605] = true, -- Mind Control
	[15407] = true, -- Mind Flay
	[453] = true, -- Mind Soothe
	[2096] = true, -- Mind Vision
	[33196] = wow_bcc, -- Misery
	[8122] = true, -- Psychic Scream
	[9484] = true, -- Shackle Undead
	[15258] = true, -- Shadow Vulnerability
	[589] = true, -- Shadow Word: Pain
	[15487] = true, -- Silence
	[10797] = true, -- Starshards (Night Elf)
	[15286] = true, -- Vampiric Embrace
	[34914] = wow_bcc, -- Vampiric Touch
}

-- Rogue
friend_buffs.ROGUE = {}
friend_debuffs.ROGUE = {}
self_buffs.ROGUE = {
	[13750] = true, -- Adrenaline Rush
	[13877] = true, -- Blade Flurry
	[45182] = wow_bcc, -- Cheating Death
	[31224] = wow_bcc, -- Cloak of Shadows
	[14177] = true, -- Cold Blood
	[2836] = true, -- Detect Traps
	[5277] = true, -- Evasion
	[14278] = true, -- Ghostly Strike
	[31665] = wow_bcc, -- Master of Sublety
	[14143] = true, -- Remorseless
	[36554] = wow_bcc, -- Shadowstep
	[5171] = true, -- Slice and Dice (6+3*combo points)
	[2983] = true, -- Sprint
	[1784] = true, -- Stealth
	[11327] = true, -- Vanish
}
self_debuffs.ROGUE = {}
pet_buffs.ROGUE = {}
enemy_debuffs.ROGUE = {
	[2094] = true, -- Blind
	[1833] = true, -- Cheap Shot
	[3409] = true, -- Crippling Poison
	[31125] = wow_bcc, -- Dazed
	[2818] = true, -- Deadly Poison
	[8647] = true, -- Expose Armor
	[31234] = wow_bcc, -- Find Weakness
	[703] = true, -- Garrote
	[1776] = true, -- Gouge
	[16511] = true, -- Hemorrhage
	[18425] = true, -- Kick - Silenced (Improved Kick)
	[408] = true, -- Kidney Shot (0/1+combo points)
	[5530] = true, -- Mace Stun Effect (Mace Specialization)
	[5760] = true, -- Mind-numbing Poison
	[14251] = true, -- Riposte
	[1943] = true, -- Rupture (6+2*combo points)
	[6770] = true, -- Sap
	[13218] = true, -- Wound Poison
}

-- Shaman
friend_buffs.SHAMAN = {
	[16177] = true, -- Ancestral Fortitude
	[2825] = wow_bcc, -- Bloodlust (Horde)
	[974] = wow_bcc, -- Earth Shield
	[8185] = true, -- Fire Resistance Totem
	[8182] = true, -- Frost Resistance Totem
	[8836] = true, -- Grace of Air Totem
	[29203] = true, -- Healing Way
	[5672] = true, -- Healing Stream Totem
	[32182] = wow_bcc, -- Heroism
	[5677] = true, -- Mana Spring Totem
	[16191] = true, -- Mana Tide Totem
	[10596] = true, -- Nature Resistance Totem
	[6495] = true, -- Sentry Totem
	[8072] = true, -- Stoneskin Totem
	[8076] = true, -- Strength of Earth Totem
	[30708] = wow_bcc, -- Totem of Wrath
	[25909] = true, -- Tranquil Air Totem
	[131] = true, -- Water Breathing
	[546] = true, -- Water Walking
	[15108] = true, -- Windwall Totem
	[2895] = wow_bcc, -- Wrath of Air Totem
}
friend_debuffs.SHAMAN = {}
self_buffs.SHAMAN = {
	[16246] = true, -- Clearcasting
	[30165] = true, -- Elemental Devastation
	[16166] = true, -- Elemental Mastery
	[6196] = true, -- Far Sight
	[43339] = wow_bcc, -- Focused
	[29063] = true, -- Focused Casting
	[16257] = true, -- Flurry
	[2645] = true, -- Ghost Wolf
	[324] = true, -- Lightning Shield
	[16188] = true, -- Nature's Swiftness
	[30823] = wow_bcc, -- Shamanistic Rage
	[24398] = wow_bcc, -- Water Shield
}
self_debuffs.SHAMAN = {}
pet_buffs.SHAMAN = {}
enemy_debuffs.SHAMAN = {
	[3600] = true, -- Earthbind
	[8056] = true, -- Frost Shock
	[8034] = true, -- Frostbrand Attack
	[8050] = true, -- Flame Shock
	[17364] = true, -- Stormstrike
}

-- Warlock
friend_buffs.WARLOCK = {
	[132] = true, -- Detect Invisibility
	[1098] = true, -- Enslave Demon
	[2947] = true, -- Fire Shield (Imp)
	[19480] = true, -- Paranoia
	[20707] = true, -- Soulstone Resurrection (30m)
	[19478] = true, -- Tainted Blood (Felhunter)
	[5697] = true, -- Unending Breath
}
friend_debuffs.WARLOCK = {}
self_buffs.WARLOCK = {
	[18288] = true, -- Amplify Curse
	[34936] = wow_bcc, -- Backlash
	[18789] = true, -- Burning Wish (Demonic Sacrifice) (30m)
	[706] = true, -- Demon Armor (30m)
	[687] = true, -- Demon Skin (30m)
	[126] = true, -- Eye of Kilrogg
	[28176] = wow_bcc, -- Fel Armor (30m)
	[18708] = true, -- Fel Domination
	[18792] = true, -- Fel Energy (Demonic Sacrifice) (30m)
	[18790] = true, -- Fel Stamina (Demonic Sacrifice) (30m)
	[755] = true, -- Health Funnel
	[1949] = true, -- Hellfire
	[23841] = true, -- Master Demonologist
	[30300] = wow_bcc, -- Nether Protection
	[5740] = true, -- Rain of Fire
	[7812] = true, -- Sacrifice (Voidwalker)
	[17941] = true, -- Shadow Trance (Nightfall)
	[6229] = true, -- Shadow Ward
	[128] = true, -- Spellstone
	[25228] = true, -- Soul Link
	[18371] = true, -- Soul Siphon (Improved Drain Soul)
	[5784] = true, -- Summon Felsteed
	[23161] = true, -- Summon Dreadsteed
	[18791] = true, -- Touch of Shadow (Demonic Sacrifice) (30m)
}
self_debuffs.WARLOCK = {}
pet_buffs.WARLOCK = {
	[6307] = true, -- Blood Pact (Imp)
	[17767] = true, -- Consume Shadows (Voidwalker)
	[2947] = true, -- Fire Shield (Imp)
	[755] = true, -- Health Funnel
	[7870] = true, -- Lesser Invisibility (Succubus)
	[23841] = true, -- Master Demonologist
	[4511] = true, -- Phase Shift
	[25228] = true, -- Soul Link
}
enemy_debuffs.WARLOCK = {
	[18118] = true, -- Aftermath
	[710] = true, -- Banish
	[172] = true, -- Corruption
	[980] = true, -- Curse of Agony
	[603] = true, -- Curse of Doom
	[1490] = true, -- Curse of Elements
	[18223] = true, -- Curse of Exhaustion
	[704] = true, -- Curse of Recklessness
	[17862] = true, -- Curse of Shadows
	[1714] = true, -- Curse of Tongues
	[702] = true, -- Curse of Weakness
	[6789] = true, -- Death Coil
	[689] = true, -- Drain Life
	[5138] = true, -- Drain Mana
	[1120] = true, -- Drain Soul
	[5782] = true, -- Fear
	[5484] = true, -- Howl of Terror
	[348] = true, -- Immolate
	[18093] = true, -- Pyroclasm
	[6358] = true, -- Seduction (Succubus)
	[17877] = true, -- Shadowburn
	[27243] = wow_bcc, -- Seed of Corruption
	[18265] = true, -- Siphon Life
	[24259] = true, -- Spell Lock
	[32386] = wow_bcc, -- Shadow Embrace
	[17794] = true, -- Shadow Vulnerability
	[30283] = wow_bcc, -- Shadowfury
	[30108] = wow_bcc, -- Unstable Affliction
}

-- Warrior
friend_buffs.WARRIOR = {
	[5242] = true, -- Battle Shout
	[469] = wow_bcc, -- Commanding Shout
	[3411] = wow_bcc, -- Intervene
}
friend_debuffs.WARRIOR = {}
self_buffs.WARRIOR = {
	[18499] = true, -- Berserker Rage
	[23885] = true, -- Bloodthirst
	[29131] = true, -- Blood Rage
	[12328] = true, -- Death Wish
	[12880] = true, -- Enrage
	[12966] = true, -- Flurry
	[12976] = true, -- Last Stand
	[30029] = wow_bcc, -- Rampage
	[1719] = true, -- Recklessness
	[20230] = true, -- Retaliation
	[29841] = wow_bcc, -- Second Wind
	[2565] = true, -- Shield Block
	[871] = true, -- Shield Wall
	[12292] = true, -- Sweeping Strikes
}
self_debuffs.WARRIOR = {}
pet_buffs.WARRIOR = {}
enemy_debuffs.WARRIOR = {
	[1161] = true, -- Challenging Shout
	[7922] = true, -- Charge Stun
	[12809] = true, -- Concussion Blow
	[12721] = true, -- Deep Wounds
	[1160] = true, -- Demoralizing Shout
	[30016] = wow_bcc, -- Devastate
	[676] = true, -- Disarm
	[1715] = true, -- Hamstring
	[23694] = true, -- Improved Hamstring
	[20253] = true, -- Intercept Stun
	[5246] = true, -- Intimidating Shout
	[12705] = true, -- Long Daze (Improved Pummel)
	[5530] = true, -- Mace Stun Effect
	[694] = true, -- Mocking Blow
	[12294] = true, -- Mortal Strike
	[12323] = true, -- Piercing Howl
	[772] = true, -- Rend
	[12798] = true, -- Revenge Stun
	[18498] = true, -- Shield Bash - Silenced
	[7386] = true, -- Sunder Armor
	[355] = true, -- Taunt
	[6343] = true, -- Thunder Clap
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

if wow_bcc then
	-- Draenei
	friend_buffs.Draenei = {
		[28880] = true, -- Gift of the Naaru
	}
	friend_debuffs.Draenei = {
		[23333] = true -- Warsong Flag
	}
	self_buffs.Draenei = {}
	self_debuffs.Draenei = {}
	pet_buffs.Draenei = {}
	enemy_debuffs.Draenei = {}
end

-- -- Worgen
-- friend_buffs.Worgen = {
-- 	[23333] = true -- Warsong Flag
-- }
-- friend_debuffs.Worgen = {}
-- self_buffs.Worgen = {
-- 	[68992] = true, -- Darkflight
-- 	[87840] = true, -- Running Wild
-- }
-- self_debuffs.Worgen = {}
-- pet_buffs.Worgen = {}
-- enemy_debuffs.Worgen = {}

-- -- Dark Iron Dwarf
-- friend_buffs.DarkIronDwarf = {
-- 	[23333] = true -- Warsong Flag
-- }
-- friend_debuffs.DarkIronDwarf = {}
-- self_buffs.DarkIronDwarf = {
-- 	[273104] = true, -- Fireblood
-- }
-- self_debuffs.DarkIronDwarf = {}
-- pet_buffs.DarkIronDwarf = {}
-- enemy_debuffs.DarkIronDwarf = {}

-- -- Lightforged Draenei
-- friend_buffs.LightforgedDraenei = {
-- 	[23333] = true -- Warsong Flag
-- }
-- friend_debuffs.LightforgedDraenei = {}
-- self_buffs.LightforgedDraenei = {}
-- self_debuffs.LightforgedDraenei = {}
-- pet_buffs.LightforgedDraenei = {}
-- enemy_debuffs.LightforgedDraenei = {}

-- -- Void Elf
-- friend_buffs.VoidElf = {
-- 	[23333] = true -- Warsong Flag
-- }
-- friend_debuffs.VoidElf = {}
-- self_buffs.VoidElf = {
-- 	[256948] = true, -- Spatial Rift
-- }
-- self_debuffs.VoidElf = {}
-- pet_buffs.VoidElf = {}
-- enemy_debuffs.VoidElf = {}

-- -- Kul Tiran Human
-- friend_buffs.KulTiranHuman = {
-- 	[23333] = true -- Warsong Flag
-- }
-- friend_debuffs.KulTiranHuman = {}
-- self_buffs.KulTiranHuman = {}
-- self_debuffs.KulTiranHuman = {}
-- pet_buffs.KulTiranHuman = {}
-- enemy_debuffs.KulTiranHuman = {}

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
	[20578] = true, -- Cannibalize
	[2944] = true, -- Devouring Plague (Priest)
	[2652] = true, -- Touch of Weakness (Priest)
	[7744] = true, -- Will of the Forsaken
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
	[26635] = true, -- Berserking
	[18137] = true, -- Shadowguard (Priest)
}
self_debuffs.Troll = {}
pet_buffs.Troll = {}
enemy_debuffs.Troll = {
	[9035] = true, -- Hex of Weakness (Priest)
}

-- Blood Elf
if wow_bcc then
	friend_buffs.BloodElf = {
		[23335] = true -- Silverwing Flag
	}
	friend_debuffs.BloodElf = {}
	self_buffs.BloodElf = {}
	self_debuffs.BloodElf = {}
	pet_buffs.BloodElf = {}
	enemy_debuffs.BloodElf = {
		[28730] = true, -- Arcane Torrent
	}
end

-- -- Goblin
-- friend_buffs.Goblin = {
-- 	[23335] = true -- Silverwing Flag
-- }
-- friend_debuffs.Goblin = {}
-- self_buffs.Goblin = {}
-- self_debuffs.Goblin = {}
-- pet_buffs.Goblin = {}
-- enemy_debuffs.Goblin = {}

-- -- Mag'har Orc
-- friend_buffs.MagharOrc = {
-- 	[23335] = true -- Silverwing Flag
-- }
-- friend_debuffs.MagharOrc = {}
-- self_buffs.MagharOrc = {
-- 	-- Ancestral Call
-- 	[274739] = true, -- Rictus of the Laughing Skull
-- 	[274740] = true, -- Zeal of the Burning Blade
-- 	[274741] = true, -- Ferocity of the Frostwolf
-- 	[274742] = true, -- Might of the Blackrock
-- }
-- self_debuffs.MagharOrc = {}
-- pet_buffs.MagharOrc = {}
-- enemy_debuffs.MagharOrc = {}

-- -- Highmountain Tauren
-- friend_buffs.HighmountainTauren = {
-- 	[23335] = true -- Silverwing Flag
-- }
-- friend_debuffs.HighmountainTauren = {}
-- self_buffs.HighmountainTauren = {}
-- self_debuffs.HighmountainTauren = {}
-- pet_buffs.HighmountainTauren = {}
-- enemy_debuffs.HighmountainTauren = {
-- 	[255723] = true, -- Bull Rush
-- }

-- -- Nightborne
-- friend_buffs.Nightborne = {
-- 	[23335] = true -- Silverwing Flag
-- }
-- friend_debuffs.Nightborne = {}
-- self_buffs.Nightborne = {}
-- self_debuffs.Nightborne = {}
-- pet_buffs.Nightborne = {}
-- enemy_debuffs.Nightborne = {
-- 	[260369] = true, -- Arcane Pulse
-- }

-- -- Zandalari Troll
-- friend_buffs.ZandalariTroll = {
-- 	[23335] = true -- Silverwing Flag
-- }
-- friend_debuffs.ZandalariTroll = {}
-- self_buffs.ZandalariTroll = {}
-- self_debuffs.ZandalariTroll = {}
-- pet_buffs.ZandalariTroll = {}
-- enemy_debuffs.ZandalariTroll = {}

-- -- Pandaren
-- friend_buffs.Pandaren = {
-- 	[23335] = UnitFactionGroup("player") == "Horde", -- Silverwing Flag
-- 	[23333] = UnitFactionGroup("player") == "Alliance", -- Warsong Flag
-- }
-- friend_debuffs.Pandaren = {}
-- self_buffs.Pandaren = {}
-- self_debuffs.Pandaren = {}
-- pet_buffs.Pandaren = {}
-- enemy_debuffs.Pandaren = {
-- 	[107079] = true, -- Quaking Palm
-- }

-- Everyone
local extra_buffs = {
	[34976] = wow_bcc, -- Netherstorm Flag
}

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
