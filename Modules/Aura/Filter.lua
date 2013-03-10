-- Filter.lua : Code to handle Filtering the Auras.

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")
local mop_520 = select(4, GetBuildInfo()) >= 50200

local GetNumSpecializations = GetNumSpecializations

local _,player_class = UnitClass('player')
local player_faction = UnitFactionGroup('player')

--- Return the DB dictionary for the specified filter.
-- Filter Types should use this to get their db.
-- @param filter the name of the filter
-- @usage local db = PitBull4_Aura:GetFilterDB("myfilter")
-- @return the DB dictionrary for the specified filter or nil
function PitBull4_Aura:GetFilterDB(filter)
	return self.db.profile.global.filters[filter]
end

-- Return true if the talent matching the name of the spell given by
-- spellid has at least one point spent in it or false otherwise
local function scan_for_known_talent(spellid)
	return IsPlayerSpell(spellid)	
end

-- Setup the data for who can dispel what types of auras.
-- dispel in this context means remove from friendly players
local can_dispel = {
	DEATHKNIGHT = {},
	DRUID = {
		Curse = scan_for_known_talent(88423),
		Poison = scan_for_known_talent(88423),
		Magic = scan_for_known_talent(88423),
	},
	HUNTER = {},
	MAGE = {
		Curse = true,
	},
	PALADIN = {
		Magic = scan_for_known_talent(53551),
		Poison = true,
		Disease = true,
	},
	PRIEST = {
		Magic = true,
		Disease = scan_for_known_talent(527),
	},
	ROGUE = {},
	SHAMAN = {
		Curse = true,
		Magic = scan_for_known_talent(77130),
	},
	WARLOCK = {},
	WARRIOR = {},
	MONK = {
		Poison = true,
		Disease = true,
		Magic = scan_for_known_talent(115451)
	},
}
can_dispel.player = can_dispel[player_class]
PitBull4_Aura.can_dispel = can_dispel

-- Setup the data for who can purge what types of auras.
-- purge in this context means remove from enemies.
local can_purge = {
	DEATHKNIGHT = {},
	DRUID = {
		Enrage = true,
	},
	HUNTER = {
		Magic = true,
		Enrage = true,
	},
	MAGE = {
		Magic = true,
	},
	PALADIN = {},
	PRIEST = {
		Magic = true,
	},
	ROGUE = {
		Enrage = true,
	},
	SHAMAN = {
		Magic = true,
	},
	WARLOCK = {
		Magic = true,
	},
	WARRIOR = {
		Magic = true,
	},
	MONK = {},
}
can_purge.player = can_purge[player_class]
PitBull4_Aura.can_purge = can_purge

-- Handle PLAYER_TALENT_UPDATE event .
-- Rescan the talents for the relevent talents that change
-- what we can dispel.
function PitBull4_Aura:PLAYER_TALENT_UPDATE(event)
	local monk_magic = scan_for_known_talent(115451)
	can_dispel.MONK.Magic = monk_magic
	self:GetFilterDB('//3').aura_type_list.Magic = monk_magic

	local shaman_magic = scan_for_known_talent(77130)
	can_dispel.SHAMAN.Magic = shaman_magic 
	self:GetFilterDB('23').aura_type_list.Magic = shaman_magic

	local druid_magic = scan_for_known_talent(88423)
	can_dispel.DRUID.Magic = druid_magic
	self:GetFilterDB(',3').aura_type_list.Magic = druid_magic
	can_dispel.DRUID.Curse = druid_magic
	can_dispel.DRUID.Poison = druid_magic
	self:GetFilterDB(',3').aura_type_list.Curse = druid_magic
	self:GetFilterDB(',3').aura_type_list.Poison = druid_magic

	local paladin_magic = scan_for_known_talent(53551)
	can_dispel.PALADIN.Magic = paladin_magic
	self:GetFilterDB('/3').aura_type_list.Magic = paladin_magic
end

-- Setup the data for which auras belong to whom
local friend_buffs,friend_debuffs,self_buffs,self_debuffs,pet_buffs,enemy_debuffs = {},{},{},{},{},{}

-- DEATHKNIGHT
friend_buffs.DEATHKNIGHT = {
	[57330]  = true, -- Horn of Winter
	[49016]  = true, -- Hysteria
	[3714]   = true, -- Path of Frost
	[55610]  = true, -- Unholy Aura
	[49016]  = true, -- Unholy Frenzy
}
friend_debuffs.DEATHKNIGHT = {}
self_buffs.DEATHKNIGHT = {
	[48707]  = true, -- Anti-Magic Shell
	[42650]  = true, -- Army of the Dead
	[49222]  = true, -- Bone Shield
	[81141]  = true, -- Crimson Scourge
	[49028]  = true, -- Dancing Rune Weapon
	[59052]  = true, -- Freezing Fog (Rime)
	[48266]  = true, -- Frost Presence
	[48792]  = true, -- Icebound Fortitude
	[51124]  = true, -- Killing Machine
	[49039]  = true, -- Lichborne
	[51271]  = true, -- Pillar of Frost
	[50421]  = true, -- Scent of Blood
	[81340]  = true, -- Sudden Doom
	[49206]  = true, -- Summon Gargoyle (TODO: Is this an enemy debuff or self buff?)
	[55233]  = true, -- Vampiric Blood
	[93099]  = true, -- Vengeance
	[51271]  = true, -- Unbreakable Armor
	[48265]  = true, -- Unholy Presence
}
self_debuffs.DEATHKNIGHT = {}
pet_buffs.DEATHKNIGHT = {
	[63560]  = true, -- Dark Transformation
	[91342]  = true, -- Shadow Infusion
	[19705]  = true, -- Well Fed
}
enemy_debuffs.DEATHKNIGHT = {
	[55078]  = true, -- Blood Plague
	[48263]  = true, -- Blood Presence
	[45524]  = true, -- Chains of Ice
	[111673] = true, -- Control Undead (TODO: Check where this really applies, could show on friendly pet as well)
	[56222]  = true, -- Dark Command
	[77606]  = true, -- Dark Simulacrum
	[43265]  = true, -- Death and Decay
	[55095]  = true, -- Frost Fever
	[73975]  = true, -- Necrotic Strike
	[81326]  = true, -- Physical Vulnerability (from Brittle Bones and Ebon Plaguebringer)
	[108200]  = true, -- Remorseless Winter
	[47476]  = true, -- Strangulate
	[130735] = true, -- Soul Reaper (TODO: Find the 50% haste buff associated with this)
	[49206]  = true, -- Summon Gargoyle
	[115798] = true, -- Weakened Blows (from Scarlet Fever)
}

-- DRUID
friend_buffs.DRUID = {
	[102352] = true, -- Cenarion Ward
	[29166]  = true, -- Innervate
	[102342] = true, -- Ironbark
	[17007]  = true, -- Leader of the Pack
	[33763]  = true, -- Lifebloom
	[48504]  = true, -- Living Seed
	[1126]   = true, -- Mark of the Wild
	[24907]  = true, -- Moonkin Aura
	[8936]   = true, -- Regrowth
	[774]    = true, -- Rejuvenation
	[77761]  = true, -- Stampeding Roar
	[110309] = true, -- Symbiosis
	[740]    = true, -- Tranquility
	[5420]   = true, -- Tree of Life TODO:Check this
	[48438]  = true, -- Wild Growth
}
friend_debuffs.DRUID = {}
self_buffs.DRUID = {
	[1066]   = true, -- Aquatic Form
	[127663] = true, -- Astral Communion
	[22812]  = true, -- Barkskin
	[50334]  = true, -- Berserk
	[5487]   = true, -- Bear Form
	[768]    = true, -- Cat Form
	[112071] = true, -- Celestial Alignment
	[16870]  = true, -- Clearcasting
	[1850]   = true, -- Dash
	[48517]  = true, -- Eclipse (Solar)
	[48518]  = true, -- Eclipse (Lunar)
	[5229]   = true, -- Enrage
	[33943]  = true, -- Flight Form
	[22842]  = true, -- Frenzied Regeneration
	[96206]  = true, -- Glyph of Rejuvenation
	[102560] = true, -- Incarnation: Chose of Elune
	[102543] = true, -- Incarnation: King of the Jungle
	[102558] = true, -- Incarnation: Son of Ursoc
	[81192]  = true, -- Lunar Shower
	[106922] = true, -- Might of Ursoc
	[24858]  = true, -- Moonkin Form
	[16689]  = true, -- Nature's Grasp
	[16188]  = true, -- Nature's Swiftness
	[48391]  = true, -- Owlkin Frenzy
	[69369]  = true, -- Predator's Swiftness
	[5215]   = true, -- Prowl
	[62606]  = true, -- Savage Defense
	[52610]	 = true, -- Savage Roar
	[93400]  = true, -- Shooting Stars
	[48505]  = true, -- Starfall
	[61336]  = true, -- Survival Instincts
	[40120]  = true, -- Swift Flight Form
	[5217]   = true, -- Tiger's Fury
	[135286] = true, -- Tooth and Claw
	[5225]   = true, -- Track Humanoids
	[783]    = true, -- Travel Form
}
self_debuffs.DRUID = {}
pet_buffs.DRUID = {}
enemy_debuffs.DRUID = {
	[106996] = true, -- Astral Storm
	[5211]   = true, -- Bash
	[102795] = true, -- Bear Hug
	[33786]  = true, -- Cyclone
	[99]     = true, -- Demoralizing Roar
	[339]    = true, -- Entangling Roots
	[770]    = true, -- Faerie Fire
	[102355] = true, -- Faerie Swarm
	[16979]  = true, -- Feral Charge
	[2637]   = true, -- Hibernate
	[16914]  = true, -- Hurricane
	[48484]  = true, -- Infected Wounds
	[5570]   = true, -- Insect Swarm
	[5422]   = true, -- Lacerate
	[22570]  = true, -- Maim
	[8921]   = true, -- Moonfire
	[9005]   = true, -- Pounce
	[1822]   = true, -- Rake
	[1079]   = true, -- Rip
	[80964]  = true, -- Skull Bash
	[2908]   = true, -- Soothe Animal
	[78675]  = true, -- Solar Beam
	[93402]  = true, -- Sunfire
	[77758]  = true, -- Thrash
	[113746] = true, -- Weakened Armor (Faerie Fire)
	[115798] = true, -- Weakened Blows (Thrash)
}

-- HUNTER
friend_buffs.HUNTER = {
	[90355]  = true, -- Ancient Hysteria
	[13159]  = true, -- Aspect of the Pack
	[97229]  = true, -- Bellowing Roar
	[128432] = true, -- Cackling Howl
	[90363]  = true, -- Embrace of the Shale Spider
	[126373] = true, -- Fearless Roar
	[24604]  = true, -- Furious Howl
	[34477]  = true, -- Misdirection
	[93435]  = true, -- Roar of Courage
	[128433] = true, -- Serpent's Swiftness
	[128997] = true, -- Spirit Beast Blessing
	[109212] = true, -- Spirit Bond
	[90361]  = true, -- Spirit Mend
	[90309]  = true, -- Terrifying Roar
	[19506]  = true, -- Trueshot Aura
	[57669]  = true, -- Replenishment
	[90364]  = true, -- Qiraji Fortitude
	[126309] = true, -- Still Water
}
friend_debuffs.HUNTER = {
	[57724]  = true, -- Sated
}
self_buffs.HUNTER = {
	[61648]  = true, -- Aspect of the Beast
	[5118]   = true, -- Aspect of the Cheetah
	[13165]  = true, -- Aspect of the Hawk
	[82921]  = true, -- Bombardment
	[51753]  = true, -- Camouflage
	[19263]  = true, -- Deterrence
	[6197]   = true, -- Eagle Eye
	[82692]  = true, -- Focus Fire
	[5384]   = true, -- Feign Death
	[56453]  = true, -- Lock and Load
	[34506]  = true, -- Master Tactician
	[6150]   = true, -- Quick Shots
	[3045]   = true, -- Rapid Fire
	[82925]  = true, -- Ready, Set, Aim... (Master Marksman)
	[126311] = true, -- Surface Trot
	[34471]  = true, -- The Beast Within
}
self_debuffs.HUNTER = {}
pet_buffs.HUNTER = {
	[19574]  = true, -- Bestial Wrath
	[3385]   = true, -- Boar Charge
	[1850]   = true, -- Dash
	[23145]  = true, -- Dive
	[1539]   = true, -- Feed Pet Effect
	[19615]  = true, -- Frenzy
	[3149]   = true, -- Furious Howl
	[90339]  = true, -- Harden Carapace
	[54216]  = true, -- Master's Call
	[136]    = true, -- Mend Pet
	[5215]   = true, -- Prowl
	[26064]  = true, -- Shell Shield
	[126311] = true, -- Surface Trot
	[32920]  = true, -- Warp
	[19705]  = true, -- Well Fed
}
enemy_debuffs.HUNTER = {
	[55749]  = true, -- Acid Spit
	[19434]  = true, -- Aimed Shot
	[50433]  = true, -- Ankle Crack
	[90337]  = true, -- Bad Manner
	[1462]   = true, -- Beast Lore
	[3674]   = true, -- Black Arrow
	[3385]   = true, -- Boar Charge
	[93433]  = true, -- Burrow Attack
	[50541]  = true, -- Clench
	[35101]  = true, -- Concussive Barrage
	[5116]   = true, -- Concussive Shot
	[3408]   = true, -- Crippling Poison
	[2818]   = true, -- Deadly Poison
	[50256]  = true, -- Demoralizing Roar
	[24423]  = true, -- Demoralizing Screech
	[20736]  = true, -- Distracting Shot
	[19184]  = true, -- Entrapment
	[53301]  = true, -- Explosive Shot
	[13812]  = true, -- Explosive Trap Effect
	[7140]   = true, -- Expose Weakness
	[34889]  = true, -- Fire Breath
	[1543]   = true, -- Flare
	[3355]   = true, -- Freezing Trap Effect
	[92380]  = true, -- Froststorm Breath
	[54644]  = true, -- Frost Breath
	[13810]  = true, -- Frost Trap Aura
	[35290]  = true, -- Gore
	[121414] = true, -- Glaive Toss
	[6795]   = true, -- Growl
	[1130]   = true, -- Hunter's Mark
	[19577]  = true, -- Intimidation
	[58604]  = true, -- Lava Breath
	[24844]  = true, -- Lightning Breath
	[90327]  = true, -- Lock Jaw
	[126246] = true, -- Lullaby
	[5760]   = true, -- Mind-numbing Poison
	[54680]  = true, -- Monstrous Bite
	[50479]  = true, -- Nether Shock
	[126355] = true, -- Paralyzing Quill
	[126423] = true, -- Petrifying Gaze
	[63468]  = true, -- Piercing Shots
	[50245]  = true, -- Pin
	[32093]  = true, -- Poison Spit
	[26090]  = true, -- Pumel
	[50518]  = true, -- Ravage
	[1513]   = true, -- Scare Beast
	[19503]  = true, -- Scatter Shot
	[6411]   = true, -- Scorpid Poison
	[24423]  = true, -- Screech
	[1978]   = true, -- Serpent Sting
	[91644]  = true, -- Snatch
	[50519]  = true, -- Sonic Blast
	[50274]  = true, -- Spore Cloud
	[34490]  = true, -- Silencing Shot
	[57386]  = true, -- Stampede
	[56626]  = true, -- Sting
	[90314]  = true, -- Tailspin
	[1515]   = true, -- Tame Beast
	[35346]  = true, -- Time Warp
	[126402] = true, -- Trample
	[54706]  = true, -- Venom Web Spray
	[113746] = true, -- Weakened Armor (Dust Cloud/Tear Armor)
	[4167]   = true, -- Web
	[96201]  = true, -- Web Wrap
	[82654]  = true, -- Widow Venom
	[19386]  = true, -- Wyvern Sting
}

-- MAGE
friend_buffs.MAGE = {
	[1459]   = true, -- Arcane Brilliance 
	[61316]  = true, -- Dalaran Brilliance
	[130]    = true, -- Slow Fall
	[80353]  = true, -- Time Warp
}
friend_debuffs.MAGE = {
	[80354]  = true, -- Temporal Displacement
}
self_buffs.MAGE = {
	[110909] = true, -- Alter Time
	[12042]  = true, -- Arcane Power
	[108843] = true, -- Blazing Speed
	[1953]   = true, -- Blink
	[57761]  = true, -- Brain Freeze
	[12051]  = true, -- Evocation
	[44544]  = true, -- Fingers of Frost
	[7302]   = true, -- Frost Armor
	[48108]  = true, -- Hot Streak/Pyroblast!
	[7302]   = true, -- Ice Armor
	[11426]  = true, -- Ice Barrier
	[45438]  = true, -- Ice Block
	[12472]  = true, -- Icy Veins
	[116267] = true, -- Incanter's Absorption
	[66]     = true, -- Invisibility
	[6117]   = true, -- Mage Armor
	[1463]   = true, -- Mana Shield
	[55342]  = true, -- Mirror Image
	[30482]  = true, -- Molten Armor
	[12043]  = true, -- Presence of Mind
	[46989]  = true, -- Rapid Teleportation (Glyph of)
	[77769]  = true, -- Trap Launcher
}
self_debuffs.MAGE = {
	[10833]  = true, -- Arcane Blast
	[41425]  = true, -- Hypothermia
	[36032]  = true, -- Arcane Charge
}
pet_buffs.MAGE = {}
enemy_debuffs.MAGE = {
	[11113]	 = true, -- Blast Wave
	[10]     = true, -- Blizzard
	[6136]   = true, -- Chilled (Frost Armor)
	[11129]  = true, -- Combustion
	[120]    = true, -- Cone of Cold
	[44572]  = true, -- Deep Freeze
	[31661]  = true, -- Dragon's Breath
	[133]    = true, -- Fireball
	[2120]   = true, -- Flamestrike
	[113092] = true, -- Frost Bomb
	[122]    = true, -- Frost Nova
	[116]    = true, -- Frostbolt
	[44614]  = true, -- Frostfire Bolt
	[84714]  = true, -- Frozen Orb
	[7302]   = true, -- Ice Armor
	[3261]   = true, -- Ignite
	[114923] = true, -- Nether Tempest
	[55021]  = true, -- Silenced - Improved Counterspell
	[44457]  = true, -- Living Bomb
	[118]    = true, -- Polymorph
	[11366]  = true, -- Pyroblast
	[31589]  = true, -- Slow
}

-- PALADIN
friend_buffs.PALADIN = {
	[53563]  = true, -- Beacon of Light
	[20217]  = true, -- Blessing of Kings
	[19740]  = true, -- Blessing of Might
	[31821]	 = true, -- Devotion Aura (mop)/Aura Mastery (cata)
	[114163] = true, -- Eternal Flame
	[121027] = true, -- Glyph of Double Jeopardy
	[54957]  = true, -- Glyph of Flash of Light
	[1044]   = true, -- Hand of Freedom
	[1022]   = true, -- Hand of Protection
	[6940]   = true, -- Hand of Sacrifice
	[1038]   = true, -- Hand of Salvation
	[86273]  = true, -- Illuminated Healing
	[114917] = true, -- Stay of Execution
}
friend_debuffs.PALADIN = {
	[25771]  = true, -- Forbearance
}
self_buffs.PALADIN = {
	[31850]  = true, -- Ardent Defender
	[31884]  = true, -- Avenging Wrath
	[114637] = true, -- Bastion of Glory
	[121183] = true, -- Contemplation
	[88819]  = true, -- Daybreak
	[31842]  = true, -- Divine Favor
	[31842]  = true, -- Divine Illumination
	[54428]	 = true, -- Divine Plea
	[498]    = true, -- Divine Protection
	[90174]  = true, -- Divine Purpose
	[642]    = true, -- Divine Shield
	[32223]  = true, -- Heart of the Crusader
	[85416]  = true, -- Grand Crusader
	[86698]  = true, -- Guardian of Ancient Kings
	[9800]   = true, -- Holy Shield
	[54149]	 = true, -- Infusion of Light
	[84963]  = true, -- Inquisition
	[53657]	 = true, -- Judgements of the Pure
	[86678]  = true, -- Light of the Ancient Kings
	[62124]	 = true, -- Reckoning
	[25780]  = true, -- Righteous Fury
	[105361] = true, -- Seal of Command
	[20164]  = true, -- Seal of Justice
	[20165]  = true, -- Seal of Insight
	[20154]  = true, -- Seal of Righteousness
	[31801]  = true, -- Seal of Truth 
	[132403] = true, -- Shield of the Righteous
	[85499]  = true, -- Speed of Light
	[23214]  = true, -- Summon Charger
	[13819]  = true, -- Summon Warhorse
	[76691]  = true, -- Vengeance
}
self_debuffs.PALADIN = {}
pet_buffs.PALADIN = {}
enemy_debuffs.PALADIN = {
	[31935]  = true, -- Avenger's Shield
	[105421] = true, -- Blinding Light
	[31803]  = true, -- Dot, from Seal of Truth (Censure)
	[26573]  = true, -- Consecration
	[2812]   = true, -- Denounce (MoP) / Holy Wrath (Cata)
	[114916] = true, -- Execution Sentence
	[853]    = true, -- Hammer of Justice
	[119072] = true, -- Holy Wrath
	[81326]  = true, -- Physical Vulnerability (Judgements of the Bold)
	[20066]  = true, -- Repentance
	[25]     = true, -- Stun, from Seal of Justice
	[10326]  = true, -- Turn Evil
	[26017]  = true, -- Vindication
	[115798] = true, -- Weakened Blows (Hammer of the Righteous)
}


-- PRIEST
friend_buffs.PRIEST = {
	[47753]	 = true, -- Divine Aegis
	[64843]  = true, -- Divine Hymn
	[6346]   = true, -- Fear Ward
	[77613]	 = true, -- Grace
	[47788]	 = true, -- Guardian Spirit
	[64901]  = true, -- Hymn of Hope
	[1706]   = true, -- Levitate
	[7001]	 = true, -- Lightwell Renew
	[49868]  = true, -- Mind Quickening (Shadowform Aura)
	[10060]  = true, -- Power Infusion
	[81782]  = true, -- Power Word: Barrier
	[21562]  = true, -- Power Word: Fortitude
	[17]     = true, -- Power Word: Shield
	[21562]  = true, -- Prayer of Fortitude
	[33206]  = true, -- Pain Suppression
	[33076]  = true, -- Prayer of Mending
	[139]    = true, -- Renew
 }
friend_debuffs.PRIEST = {
	[2096]   = true, -- Mind Vision
	[6788]   = true, -- Weakened Soul
}
self_buffs.PRIEST = {
	[81700]  = true, -- Archangel
	[59889]	 = true, -- Borrowed Time
	[81209]  = true, -- Chakra: Chastise
	[81206]  = true, -- Chakra: Sanctuary
	[81208]  = true, -- Chakra: Serenity
	[87153]  = true, -- Dark Archangel
	[47585]  = true, -- Dispersion
	[81661]  = true, -- Evangelism
	[586]    = true, -- Fade
	[81292]  = true, -- Glyph of Mind Spike
	[588]    = true, -- Inner Fire
	[89485]  = true, -- Inner Focus
	[73413]  = true, -- Inner Will
	[2096]   = true, -- Mind Vision
	[114239] = true, -- Phantasm
	[15473]  = true, -- Shadowform
	[27827]  = true, -- Spirit of Redemption
	[109964] = true, -- Spirit Shell
	[87160]  = true, -- Surge of Darkness
	[114255] = true, -- Surge of Light
}
self_debuffs.PRIEST = {}
pet_buffs.PRIEST = {}
enemy_debuffs.PRIEST = {
	[2944]   = true, -- Devouring Plague
	[87194]  = true, -- Glyph of Mind Blast
	[14914]  = true, -- Holy Fire
	[88625]  = true, -- Holy Word: Chastise
	[605]    = true, -- Mind Control
	[15407]  = true, -- Mind Flay
	[49821]	 = true, -- Mind Sear
	[2096]   = true, -- Mind Vision
	[64044]  = true, -- Psychic Horror
	[8122]   = true, -- Psychic Scream
	[9484]   = true, -- Shackle Undead
	[589]    = true, -- Shadow Word: Pain
	[15487]  = true, -- Silence
	[15286]  = true, -- Vampiric Embrace
	[34914]  = true, -- Vampiric Touch
}

-- ROGUE
friend_buffs.ROGUE = {
	[115834] = true, -- Shroud of Concealment
	[113742] = true, -- Swiftblade's Cunning
	[57934]  = true, -- Tricks of the Trade
}
friend_debuffs.ROGUE = {}
self_buffs.ROGUE = {
	[13750]  = true, -- Adrenaline Rush
	[13877]  = true, -- Blade Flurry
	[121153] = true, -- Blindside
	[31224]  = true, -- Cloak of Shadows
	[56814]  = true, -- Detection
	[32645]  = true, -- Envenom
	[5277]   = true, -- Evasion
	[1966]   = true, -- Feint
	[51690]  = true, -- Killing Spree
	[73651]  = true, -- Recuperate
	[121471] = true, -- Shadow Blades
	[51713]  = true, -- Shadow Dance
	[114842] = true, -- Shadow Walk
	[36554]  = true, -- Shadowstep
	[114018] = true, -- Shround of Concealment
	[5171]   = true, -- Slice and Dice
	[76577]  = true, -- Smoke Bomb
	[2983]   = true, -- Sprint
	[1784]   = true, -- Stealth
	[1856]   = true, -- Vanish
}
self_debuffs.ROGUE = {}
pet_buffs.ROGUE = {}
enemy_debuffs.ROGUE = {
	[2094]   = true, -- Blind
	[1833]   = true, -- Cheap Shot
	[3408]   = true, -- Crippling Poison
	[2823]   = true, -- Deadly Poison
	[26679]  = true, -- Deadly Throw
	[51722]  = true, -- Dismantle
	[8647]   = true, -- Expose Armor
	[91023]  = true, -- Find Weakness
	[703]    = true, -- Garrote
	[1330]   = true, -- Garrote - Silence
	[1776]   = true, -- Gouge
	[16511]  = true, -- Hemorrhage
	[408]    = true, -- Kidney Shot
	[93068]  = true, -- Master Poisoner
	[5760]   = true, -- Mind-numbing Poison
	[84617]  = true, -- Revealing Strike
	[1943]   = true, -- Rupture
	[6770]   = true, -- Sap
	[79140]  = true, -- Vendetta
	[113746] = true, -- Weakened Armor (Expose Armor)
	[8679]   = true, -- Wound Poison
}

-- SHAMAN
friend_buffs.SHAMAN = {
	[105284] = true, -- Ancesteral Vigor (Purification)
	[2825]   = player_faction == "Horde", -- Bloodlust
	[77747]  = true, -- Burning Wrath/Totemic Wrath
	[974]    = true, -- Earth Shield
	[51945]  = true, -- Earthliving
	[51470]  = true, -- Elemental Oath
	[4057]   = true, -- Fire Resistance
	[4077]   = true, -- Frost Resistance
	[116956] = true, -- Grace of Air
	[8178]   = true, -- Grounding Totem Effect
	[73920]  = true, -- Healing Rain
	[119523] = true, -- Healing Stream Totem (Glyph of Healing Stream Totem)
	[32182]  = player_faction == "Alliance", -- Heroism
	[16191]  = true, -- Mana Tide
	[4081]   = true, -- Nature Resistance
	[61295]  = true, -- Riptide

	[120676] = true, -- Stormlash Totem
	[30809]  = true, -- Unleashed Rage
	[546]    = true, -- Water Walking
	[27621]  = true, -- Windfury Totem
}
friend_debuffs.SHAMAN = {
	[57723]  = player_faction == "Alliance", -- Exhaustion
	[57724]  = player_faction == "Horde", -- Sated
}
self_buffs.SHAMAN = {
	[114051] = true, -- Ascendance
	[16246]  = true, -- Clearcasting
	[118522] = true, -- Elemental Blast
	[16166]  = true, -- Elemental Mastery
	[6196]   = true, -- Far Sight
	[16278]  = true, -- Flurry
	[2645]   = true, -- Ghost Wolf
	[324]    = true, -- Lightning Shield
	[53817]  = true, -- Maelstrom Weapon
	[16188]  = true, -- Nature's Swiftness
	[30823]  = true, -- Shamanistic Rage
	[98007]  = true, -- Spirit Link Totem 
	[115356] = true, -- Stormblast
	[53390]  = true, -- Tidal Waves
	[52127]  = true, -- Water Shield
	[79206]  = true, -- Spiritwalker's Grace
	[58875]	 = true, -- Spirit Walk
	[73685]  = true, -- Unleash Life
}
self_debuffs.SHAMAN = {}
pet_buffs.SHAMAN = {
	[58875]	 = true, -- Spirit Walk
}
enemy_debuffs.SHAMAN = {
	[76780]  = true, -- Bind Elemental
	[3600]   = true, -- Earthbind
	[8377]   = true, -- Earthgrab
	[61882]  = true, -- Earthquake
	[8050]   = true, -- Flame Shock
	[63685]  = true, -- Freeze (Frozen Power)
	[8056]   = true, -- Frost Shock
	[8034]   = true, -- Frostbrand Attack
	[17364]  = true, -- Stormstrike
	[51490]  = true, -- Thunderstorm
	[51514]	 = true, -- Hex
	[115798] = true, -- Weakened Blows (Earth Shock)
}

-- WARLOCK
friend_buffs.WARLOCK = {
	[6307]   = not mop_520 or nil, -- Blood Pact
	[109773] = true, -- Dark Intent
	[1098]   = true, -- Enslave Demon
	[134]    = true, -- Fire Shield
	[20707]  = true, -- Soulstone
	[5697]   = true, -- Unending Breath
	[57669]  = true, -- Replenishment
}
friend_debuffs.WARLOCK = {}
self_buffs.WARLOCK = {
	[116202] = true, -- Aura of the Elements
	[116198] = true, -- Aura of Enfeeblement
	[117828] = true, -- Backdraft
	[34936]  = true, -- Backlash
	[114168] = true, -- Dark Apotheosis
	[113858] = true, -- Dark Soul: Instability
	[113861] = true, -- Dark Soul: Knowledge
	[113860] = true, -- Dark Soul: Misery
	[88448]  = true, -- Demonic Rebirth
	[126]    = true, -- Eye of Kilrogg
	[108683] = true, -- Fire and Brimstone
	[120451] = true, -- Flames of Xoroth
	[755]    = true, -- Health Funnel
	[1949]   = true, -- Hellfire
	[104025] = true, -- Immolation Aura
	[1454]   = true, -- Life Tap (Glyph of)
	[103958] = true, -- Metamorphosis
	[122355] = true, -- Molten Core
	[1050]   = true, -- Sacrifice
	[17941]  = true, -- Shadow Trance
	[74434]  = true, -- Soulburn
	[79438]  = true, -- Soulburn: Demonic Circle
	[86211]  = true, -- Soul Swap
	[101976] = true, -- Soul Harvest
	[6229]   = true, -- Twilight Ward/Shadow Ward
	[104773] = true, -- Unending Resolve
}
self_debuffs.WARLOCK = {}
pet_buffs.WARLOCK = {
	[23257]  = true, -- Demonic Frenzy
	[89751]  = true, -- Felstorm (Felguard)
	[7870]   = true, -- Lesser Invisibility (Succubus)
	[115556] = true, -- Master Demonologist
	[30151]  = true, -- Pursuit (Felguard)
	[22987]  = true, -- Ritual Enslavement (Doomguard)
	[17767]  = true, -- Shadow Bulwark/Consume Shadows (Voidwalker)
	[115232] = true, -- Shadow Shield
	[19705]  = true, -- Well Fed
}
enemy_debuffs.WARLOCK = {
	[85387]  = true, -- Aftermath
	[980]    = true, -- Agony
	[89766]  = true, -- Axe Toss (Felguard)
	[710]    = true, -- Banish
	[124915] = true, -- Chaos Wave
	[17962]  = true, -- Conflagrate
	[172]    = true, -- Corruption
	[89]     = true, -- Cripple
	[980]    = true, -- Curse of Agony
	[109466] = true, -- Curse of Enfeeblement
	[18223]  = true, -- Curse of Exhaustion
	[1490]   = true, -- Curse of the Elements
	[6789]   = true, -- Death Coil
	[118093] = true, -- Disarm (Voidwalker)
	[603]    = true, -- Doom
	[689]    = true, -- Drain Life
	[1120]   = true, -- Drain Soul
	[5782]   = true, -- Fear
	[48181]  = true, -- Haunt
	[80240]  = true, -- Havoc
	[5484]   = true, -- Howl of Terror
	[348]    = true, -- Immolate
	[1122]   = true, -- Inferno
	[22703]  = true, -- Internal Awakening
	[103103] = true, -- Malefic Grasp
	[60947]  = true, -- Nightmare
	[5740]   = true, -- Rain of Fire
	[6358]   = true, -- Seduction (Succubus)
	[27243]  = true, -- Seed of Corruption
	[17877]  = true, -- Shadowburn
	[47960]  = true, -- Shadowflame
	[30283]  = true, -- Shadowfury
	[63311]  = true, -- Shadowsnare
	[6726]   = true, -- Silence
	[6360]   = true, -- Soothing Kiss
	[24259]  = true, -- Spell Lock (Felhunter)
	[17735]  = true, -- Suffering (Voidwalker)
	[54049]  = true, -- Shadow Bite
	[30108]  = true, -- Unstable Affliction
}

-- WARRIOR
friend_buffs.WARRIOR = {
	[6673]   = true, -- Battle Shout
	[469]    = true, -- Commanding Shout
	[3411]   = true, -- Intervene
	[97463]  = true, -- Rallying Cry
	[114207] = true, -- Skull Banner TODO: Verify
}
friend_debuffs.WARRIOR = {}
self_buffs.WARRIOR = {
	[18499]  = true, -- Berserker Rage
	[85730]  = not mop_520 or nil, -- Deadly Calm
	[118038] = true, -- Die by the Sword
	[12880]  = true, -- Enrage
	[55694]	 = true, -- Enraged Regeneration
	[12968]  = true, -- Flurry
	[115945] = true, -- Glyph of Hamstring
	[115940] = not mop_520 or nil, -- Glyph of Overpower
	[12975]  = true, -- Last Stand
	[85739]  = true, -- Meat Cleaver
	[58281]  = true, -- Mighty Victory (Glyph of)
	[114192] = true, -- Mocking Banner TODO: Verify
	[9347]   = true, -- Mortal Strike (Glyph of)
	[115317] = true, -- Raging Wind
	[8285]   = true, -- Rampage
	[1719]   = true, -- Recklessness
	[15604]  = true, -- Second Wind
	[112048] = true, -- Shield Barrier
	[2565]   = true, -- Shield Block
	[871]    = true, -- Shield Wall
	[23920]  = true, -- Spell Reflection
	[12328]  = true, -- Sweeping Strikes
	-- T4, Tank, 2/4 piece bonus
	[37514]  = true, -- Blade Turning
	[6572]   = true, -- Revenge
	-- T5, Tank, 2/4 piece bonus
	[37525]  = true, -- Battle Rush
	[37523]  = true, -- Reinforced Shield
	-- T5, DPS, 2 piece bonus
	[7384]   = true, -- Overpower
	[40729]  = true, -- Heightened Reflexes
	[61571]  = true, -- Spirits of the Lost
	[46916]  = true, -- Slam!
	[122510] = true, -- Ultimatum
}
self_debuffs.WARRIOR = {
	[12292]  = true, -- Death Wish
}
pet_buffs.WARRIOR = {}
enemy_debuffs.WARRIOR = {
	[23690]  = true, -- Bloodcurdling Shout (Glyph of)
	[7922]   = true, -- Charge Stun
	[86346]  = true, -- Colossus Smash
	[1604]   = true, -- Dazed
	[115768] = true, -- Deep Wounds (Blood and Thunder)
	[114203] = true, -- Demoralizing Banner TODO: Verify
	[1160]   = true, -- Demoralizing Shout
	[676]    = true, -- Disarm
	[1715]   = true, -- Hamstring
	[58407]  = true, -- Hindering Strikes (Glyph of) TODO: Verify
	[5246]   = true, -- Intimidating Shout
	[115804] = true, -- Mortal Wounds (Mortal Strike/Wild Strike)
	[81326]  = true, -- Physical Vulnerability (Colossus Smash)
	[10576]  = true, -- Piercing Howl
	[64382]  = true, -- Shattering Throw
	[18498]  = true, -- Shield Bash - Silenced
	[18498]  = true, -- Silenced - Gag Order
	[355]    = true, -- Taunt
	[105771] = true, -- Warbringer
	[113746] = true, -- Weakened Armor (Sunder Armor/Devastate)
	[115798] = true, -- Weakened Blows (Thunder Clap)
}

-- MONK
-- TODO: Glyph of Crackling Jade Lightning
-- TODO: Transcendence
friend_buffs.MONK = {
	[115213] = true, -- Avert Harm
	[132120] = true, -- Enveloping Mist
	[118604] = true, -- Guard
	[119611] = true, -- Renewing Mist
	[115921] = true, -- Legacy of the Emperor
	[116781] = true, -- Legacy of the White Tiger
	[116849] = true, -- Life Cocoon
	[115175] = true, -- Soothing Mist
	[116841] = true, -- Tiger's Lust
	[124081] = true, -- Zen Sphere
}
friend_debuffs.MONK= {}
self_buffs.MONK = {
	[126050] = true, -- Adaptation
	[116768] = true, -- Combo Breaker: Blackout Kick
	[118864] = true, -- Combo Breaker: Tiger Palm
	[122278] = true, -- Dampen Harm
	[121125] = true, -- Death Note
	[122465] = true, -- Dematerialize
	[122783] = true, -- Diffuse Magic
	[115308] = true, -- Elusive Brew
	[115288] = true, -- Energizing Brew
	[120954] = true, -- Fortifying Brew
	[117431] = true, -- Grapple Weapon
	[115295] = true, -- Guard
	[124458] = true, -- Healing Sphere
	[124273] = true, -- Heavy Stagger
	[124275] = true, -- Light Stagger
	[115867] = true, -- Mana Tea
	[124274] = true, -- Moderate Stagger
	[119085] = true, -- Momentum
	[118636] = true, -- Power Guard (Brewmaster Training)
	[124968] = true, -- Retreat (Glyph of)
	[127722] = true, -- Serpent's Zeal
	[115307] = true, -- Shuffle (Brewmaster Training)
	[116033] = true, -- Sparring
	[116705] = true, -- Spear Hand Strike
	[107270] = true, -- Spinning Crane Kick
	[123407] = true, -- Spinning Fire Blossom
	[124255] = true, -- Stagger
	[116680] = true, -- Thunder Focus Tea
	[116740] = true, -- Tigereye Brew
	[125359] = true, -- Tiger Power
	[120273] = true, -- Tiger Strikes
	[125174] = true, -- Touch of Karma
	[120267] = true, -- Vengeance
	[118674] = true, -- Vital Mists
	[125883] = true, -- Zen Flight
	[131523] = true, -- Zen Meditation
	[126896] = true, -- Zen Pilgrimage: Return

}
self_debuffs.MONK = {}
pet_buffs.MONK = {}
enemy_debuffs.MONK = {
	[128531] = true, -- Blackout Kick (Combat Conditioning)
	[115181] = true, -- Breath of Fire
	[119392] = true, -- Charging Ox Wax
	[126451] = true, -- Clash
	[117952] = true, -- Crackling Jade Lightning
	[123996] = true, -- Crackling Tiger Lighting (Invoke Xuen, the White Tiger)
	[116095] = true, -- Disable
	[115180] = true, -- Dizzying Haze (Keg Smash)
	[117418] = true, -- Fists of Fury
	[123586] = true, -- Flying Serpent Kick
	[117368] = true, -- Grapple Weapon
	[119381] = true, -- Leg Sweep
	[118585] = true, -- Leer of the Ox
	[115804] = true, -- Mortal Wounds (Rising Sun Kick)
	[115078] = true, -- Paralysis
	[115546] = true, -- Provoke
	[130320] = true, -- Rising Sun Kick
	[116847] = true, -- Rushing Jade Wind
	[122470] = true, -- Touch of Karma
	[115798] = true, -- Weakened Blows (Keg Smash)
}

-- Human
friend_buffs.Human = {
	[23333]  = true, -- Warsong Flag
}
friend_debuffs.Human = {}
self_buffs.Human = {}
self_debuffs.Human = {}
pet_buffs.Human = {}
enemy_debuffs.Human = {}

-- Dwarf
friend_buffs.Dwarf = {
	[23333]  = true, -- Warsong Flag
}
friend_debuffs.Dwarf = {}
self_buffs.Dwarf = {
	[7020]   = true, -- Stoneform
}
self_debuffs.Dwarf = {}
pet_buffs.Dwarf = {}
enemy_debuffs.Dwarf = {}

-- NightElf
friend_buffs.NightElf = {
	[23333]  = true, -- Warsong Flag
}
friend_debuffs.NightElf = {}
self_buffs.NightElf = {
	[58984]  = true, -- Shadowmeld
}
self_debuffs.NightElf = {}
pet_buffs.NightElf = {}
enemy_debuffs.NightElf = {}

-- Gnome
friend_buffs.Gnome = {
	[23333]  = true, -- Warsong Flag
}
friend_debuffs.Gnome = {}
self_buffs.Gnome = {}
self_debuffs.Gnome = {}
pet_buffs.Gnome = {}
enemy_debuffs.Gnome = {}

-- Draenei
friend_buffs.Draenei = {
	[28880]  = true, -- Gift of the Naaru
	[23333]  = true, -- Warsong Flag
}
friend_debuffs.Draenei = {}
self_buffs.Draenei = {}
self_debuffs.Draenei = {}
pet_buffs.Draenei = {}
enemy_debuffs.Draenei = {}

-- Orc
friend_buffs.Orc = {
	[23335]  = true, -- Silverwing Flag
}
friend_debuffs.Orc = {}
self_buffs.Orc = {
	[20572]  = true, -- Blood Fury
}
self_debuffs.Orc = {
	[20572]  = true, -- Blood Fury
}
pet_buffs.Orc = {}
enemy_debuffs.Orc = {}

-- Scourge
friend_buffs.Scourge = {
	[23335]  = true, -- Silverwing Flag
}
friend_debuffs.Scourge = {}
self_buffs.Scourge = {
	[20577]  = true, -- Cannibalize
	[7744]   = true, -- Will of the Forsaken
}
self_debuffs.Scourge = {}
pet_buffs.Scourge = {}
enemy_debuffs.Scourge = {}

-- Tauren
friend_buffs.Tauren = {
	[23335]  = true, -- Silverwing Flag
}
friend_debuffs.Tauren = {}
self_buffs.Tauren = {}
self_debuffs.Tauren = {}
pet_buffs.Tauren = {}
enemy_debuffs.Tauren = {
	[45]     = true, -- War Stomp
}

-- Troll
friend_buffs.Troll = {
	[23335]  = true, -- Silverwing Flag
}
friend_debuffs.Troll = {}
self_buffs.Troll = {
	[26297]  = true, -- Berserking
}
self_debuffs.Troll = {}
pet_buffs.Troll = {}
enemy_debuffs.Troll = {}

-- BloodElf
friend_buffs.BloodElf = {
	[23335]  = true, -- Silverwing Flag
}
friend_debuffs.BloodElf = {}
self_buffs.BloodElf = {}
self_debuffs.BloodElf = {}
pet_buffs.BloodElf = {}
enemy_debuffs.BloodElf = {
	[25046]  = true, -- Arcane Torrent
}

-- Goblin
friend_buffs.Goblin = {
	[23335]  = true, -- Silverwing Flag
}
friend_debuffs.Goblin = {}
self_buffs.Goblin = {}
self_debuffs.Goblin = {}
pet_buffs.Goblin = {}
enemy_debuffs.Goblin = {}

-- Worgen
friend_buffs.Worgen = {
	[23333]  = true, -- Warsong Flag
}
friend_debuffs.Worgen = {}
self_buffs.Worgen = {
	[68992]  = true, -- Darkflight
	[87840]  = true, -- Running Wild
}
self_debuffs.Worgen = {}
pet_buffs.Worgen = {}
enemy_debuffs.Worgen = {}

-- Pandaren
friend_buffs.Pandaren = {
	[23335]  = player_faction == "Horde", -- Silverwing Flag
	[23333]  = player_faction == "Alliance", -- Warsong Flag
}
friend_debuffs.Pandaren = {}
self_buffs.Pandaren = {}
self_debuffs.Pandaren = {}
pet_buffs.Pandaren = {}
enemy_debuffs.Pandaren = {
	[107079] = true, -- Quaking Palm
}

-- Everyone
local extra_buffs = {
	[34976]  = true, -- Netherstorm Flag
}

local function turn(t, shallow)
	local tmp = {}
	local function turn(entry)
		for id,v in pairs(entry) do
			local spell = GetSpellInfo(id)
			if not spell then
				DEFAULT_CHAT_FRAME:AddMessage(string.format("PitBull4_Aura: Unknown spell ID: %d",id))
			else
				tmp[spell] = v
			end
		end
		wipe(entry)
		for spell,v in pairs(tmp) do
			entry[spell] = v
		end
	end
	if shallow then
		turn(t)
		return
	end
	for k in pairs(t) do
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
