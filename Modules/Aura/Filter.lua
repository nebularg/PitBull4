-- Filter.lua : Code to handle Filtering the Auras.

if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")

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

local function scan_for_known_talent(spellid)
	return IsPlayerSpell(spellid)
end

local function scan_for_known_glyph(spellid)
	for index = 1, NUM_GLYPH_SLOTS do
		local _, _, _, gylph_spellid = GetGlyphSocketInfo(index)
		if gylph_spellid == spellid then
			return true
		end
	end
	return false
end

-- Setup the data for who can dispel what types of auras.
-- dispel in this context means remove from friendly players
local can_dispel = {
	DEATHKNIGHT = {},
	DRUID = {
		Curse = true,
		Poison = true,
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
	DEATHKNIGHT = {
		Magic = scan_for_known_glyph(58631),
	},
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
		Magic = scan_for_known_glyph(58375),
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

	local paladin_magic = scan_for_known_talent(53551)
	can_dispel.PALADIN.Magic = paladin_magic
	self:GetFilterDB('/3').aura_type_list.Magic = paladin_magic

	local deathknight_magic = scan_for_known_glyph(58631)
	can_purge.DEATHKNIGHT.Magic = deathknight_magic
	self:GetFilterDB('+7').aura_type_list.Magic = deathknight_magic

	local warrior_magic = scan_for_known_glyph(58375)
	can_purge.WARRIOR.Magic = warrior_magic
	self:GetFilterDB('47').aura_type_list.Magic = warrior_magic
end

-- Setup the data for which auras belong to whom
local friend_buffs,friend_debuffs,self_buffs,self_debuffs,pet_buffs,enemy_debuffs = {},{},{},{},{},{}

-- DEATHKNIGHT
friend_buffs.DEATHKNIGHT = {
	[57330]  = true, -- Horn of Winter
	[3714]   = true, -- Path of Frost
	[55610]  = true, -- Unholy Aura
}
friend_debuffs.DEATHKNIGHT = {
	[111673] = true, -- Control Undead (pet debuff)
	[97821]  = true, -- Void-Touched
}
self_buffs.DEATHKNIGHT = {
	[48707]  = true, -- Anti-Magic Shell
	[145629] = true, -- Anti-Magic Zone
	[42650]  = true, -- Army of the Dead
	[114851] = true, -- Blood Charge (Blood Tap)
	[49222]  = true, -- Bone Shield
	[119975] = true, -- Conversion
	[81141]  = true, -- Crimson Scourge
	[49028]  = true, -- Dancing Rune Weapon
	[101568] = true, -- Dark Succor
	[96268]  = true, -- Death's Advance
	[115018] = true, -- Desecrated Ground
	[59052]  = true, -- Freezing Fog (Rime)
	[48266]  = true, -- Frost Presence
	[48792]  = true, -- Icebound Fortitude
	[51124]  = true, -- Killing Machine
	[49039]  = true, -- Lichborne
	[51271]  = true, -- Pillar of Frost
	[50421]  = true, -- Scent of Blood
	[91342]  = true, -- Shadow Infusion
	[114868] = true, -- Soul Reaper
	[81340]  = true, -- Sudden Doom
	[55233]  = true, -- Vampiric Blood
	[115989] = true, -- Unholy Blight
	[48265]  = true, -- Unholy Presence
}
self_debuffs.DEATHKNIGHT = {
	[48743]  = true, -- Death Pact
	[116888] = true, -- Purgatory
	[157335] = true, -- Will of the Necropolis
}
pet_buffs.DEATHKNIGHT = {
	[63560]  = true, -- Dark Transformation
	[91342]  = true, -- Shadow Infusion
}
enemy_debuffs.DEATHKNIGHT = {
	[108194] = true, -- Asphyxiate
	[55078]  = true, -- Blood Plague
	[48263]  = true, -- Blood Presence
	[155166] = true, -- Breath of Sindragosa
	[45524]  = true, -- Chains of Ice
	[50435]  = true, -- Chilblains
	[56222]  = true, -- Dark Command
	[77606]  = true, -- Dark Simulacrum
	[43265]  = true, -- Death and Decay
	[156004] = true, -- Defile
	[55095]  = true, -- Frost Fever
	[91800]  = true, -- Gnaw
	[155159] = true, -- Necrotic Plague
	[108200] = true, -- Remorseless Winter
	[47476]  = true, -- Strangulate
	[130735] = true, -- Soul Reaper
	[49206]  = true, -- Summon Gargoyle
}

-- DRUID
friend_buffs.DRUID = {
	[102352] = true, -- Cenarion Ward
	[102342] = true, -- Ironbark
	[17007]  = true, -- Leader of the Pack
	[33763]  = true, -- Lifebloom
	[48504]  = true, -- Living Seed
	[1126]   = true, -- Mark of the Wild
	[24907]  = true, -- Moonkin Aura
	[8936]   = true, -- Regrowth
	[774]    = true, -- Rejuvenation
	[155777] = true, -- Rejuvenation (Germination)
	[77761]  = true, -- Stampeding Roar
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
	[33943]  = true, -- Flight Form
	[22842]  = true, -- Frenzied Regeneration
	[96206]  = true, -- Glyph of Rejuvenation
	[102560] = true, -- Incarnation: Chose of Elune
	[102543] = true, -- Incarnation: King of the Jungle
	[102558] = true, -- Incarnation: Son of Ursoc
	[24858]  = true, -- Moonkin Form
	[16188]  = true, -- Nature's Swiftness
	[69369]  = true, -- Predator's Swiftness
	[5215]   = true, -- Prowl
	[62606]  = true, -- Savage Defense
	[52610]  = true, -- Savage Roar
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
	[33786]  = true, -- Cyclone
	[99]     = true, -- Demoralizing Roar
	[339]    = true, -- Entangling Roots
	[770]    = true, -- Faerie Fire
	[102355] = true, -- Faerie Swarm
	[16979]  = true, -- Feral Charge
	[16914]  = true, -- Hurricane
	[48484]  = true, -- Infected Wounds
	[5422]   = true, -- Lacerate
	[22570]  = true, -- Maim
	[8921]   = true, -- Moonfire
	[1822]   = true, -- Rake
	[1079]   = true, -- Rip
	[2908]   = true, -- Soothe Animal
	[78675]  = true, -- Solar Beam
	[93402]  = true, -- Sunfire
	[77758]  = true, -- Thrash
}

-- HUNTER
friend_buffs.HUNTER = {
	[90355]  = true, -- Ancient Hysteria
	[13159]  = true, -- Aspect of the Pack
	[34477]  = true, -- Misdirection
	[160452] = true, -- Netherwinds
	[53480]  = true, -- Roar of Sacrifice
	[109212] = true, -- Spirit Bond
	[90361]  = true, -- Spirit Mend
	[19506]  = true, -- Trueshot Aura
	-- pet group buffs
	[159988] = true, -- Bark of the Wild
	[97229]  = true, -- Bellowing Roar
	[160017] = true, -- Blessing of Kongs
	[24844]  = true, -- Breath of the Winds
	[128432] = true, -- Cackling Howl
	[50518]  = true, -- Chitinous Armor
	[160045] = true, -- Defensive Quills
	[58604]  = true, -- Double Bite
	[159736] = true, -- Duality
	[90363]  = true, -- Embrace of the Shale Spider
	[135678] = true, -- Energizing Spores
	[126373] = true, -- Fearless Roar
	[24604]  = true, -- Furious Howl
	[173035] = true, -- Grace
	[35290]  = true, -- Indomitable
	[160039] = true, -- Keen Senses
	[160073] = true, -- Plainswalking
	[90364]  = true, -- Qiraji Fortitude
	[93435]  = true, -- Roar of Courage
	[160003] = true, -- Savage Vigor
	[128433] = true, -- Serpent's Cunning
	[160074] = true, -- Speed of the Swarm
	[128997] = true, -- Spirit Beast Blessing
	[34889]  = true, -- Spry Attacks
	[126309] = true, -- Still Water
	[160077] = true, -- Strength of the Earth
	[160052] = true, -- Strength of the Pack
	[160014] = true, -- Sturdiness
	[159735] = true, -- Tenacity
	[90309]  = true, -- Terrifying Roar
	[57386]  = true, -- Wild Strength
}
friend_debuffs.HUNTER = {
	[57724]  = true, -- Sated
	[95809]  = true, -- Insanity
	[160455] = true, -- Fatigued
}
self_buffs.HUNTER = {
	[61648]  = true, -- Aspect of the Beast
	[5118]   = true, -- Aspect of the Cheetah
	[82921]  = true, -- Bombardment
	[51753]  = true, -- Camouflage
	[19263]  = true, -- Deterrence
	[6197]   = true, -- Eagle Eye
	[82692]  = true, -- Focus Fire
	[5384]   = true, -- Feign Death
	[162539] = true, -- Frozen Ammo
	[162536] = true, -- Incendiary Ammo
	[155228] = true, -- Lone Wolf
	[34506]  = true, -- Master Tactician
	[162537] = true, -- Poisoned Ammo
	[6150]   = true, -- Quick Shots
	[3045]   = true, -- Rapid Fire
	[126311] = true, -- Surface Trot
	[34720]  = true, -- Thrill of the Hunt
	[77769]  = true, -- Trap Launcher
}
self_debuffs.HUNTER = {}
pet_buffs.HUNTER = {
	[160011] = true, -- Agile Reflexes
	[19574]  = true, -- Bestial Wrath
	[63896]  = true, -- Bullheaded
	[43317]  = true, -- Dash
	[159953] = true, -- Feast
	[19615]  = true, -- Frenzy
	[90339]  = true, -- Harden Carapace
	[159926] = true, -- Harden Shell
	[53479]  = true, -- Last Stand
	[53271]  = true, -- Master's Call
	[136]    = true, -- Mend Pet
	[159786] = true, -- Molten Hide
	[160044] = true, -- Primal Agility
	[24450]  = true, -- Prowl
	[137798] = true, -- Reflective Armor Plating
	[26064]  = true, -- Shell Shield
	[160063] = true, -- Solid Shield
	[90328]  = true, -- Spirit Walk
	[126311] = true, -- Surface Trot
	[160048] = true, -- Stone Armor
	[160058] = true, -- Thick Hide
	[160007] = true, -- Updraft
}
enemy_debuffs.HUNTER = {
	[131894] = true, -- A Murder of Crows
	[19434]  = true, -- Aimed Shot
	[1462]   = true, -- Beast Lore
	[117526] = true, -- Binding Shot
	[3674]   = true, -- Black Arrow
	[5116]   = true, -- Concussive Shot
	[20736]  = true, -- Distracting Shot
	[64803]  = true, -- Entrapment
	[53301]  = true, -- Explosive Shot
	[13812]  = true, -- Explosive Trap
	[1543]   = true, -- Flare
	[3355]   = true, -- Freezing Trap
	[162546] = true, -- Frozen Ammo
	[13810]  = true, -- Ice Trap
	[121414] = true, -- Glaive Toss
	[1130]   = true, -- Hunter's Mark
	[19577]  = true, -- Intimidation
	[162543] = true, -- Poisoned Ammo
	[118253] = true, -- Serpent Sting
	[1515]   = true, -- Tame Beast
	[19386]  = true, -- Wyvern Sting
	-- pet
	[50433]  = true, -- Ankle Crack
	[24423]  = true, -- Bloody Screech
	[93433]  = true, -- Burrow Attack
	[159936] = true, -- Deadly Bite
	[160060] = true, -- Deadly Sting
	[92380]  = true, -- Froststorm Breath
	[54644]  = true, -- Frost Breath
	[2649]   = true, -- Growl
	[160018] = true, -- Gruesome Bite
	[54680]  = true, -- Monstrous Bite
	[160065] = true, -- Tendon Rip
	[35346]  = true, -- Warp Time
	[160067] = true, -- Web Spray
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
	[57761]  = true, -- Brain Freeze
	[12051]  = true, -- Evocation
	[157913] = true, -- Evanesce
	[44544]  = true, -- Fingers of Frost
	[7302]   = true, -- Frost Armor
	[110960] = true, -- Greater Invisibility
	[48108]  = true, -- Hot Streak/Pyroblast!
	[11426]  = true, -- Ice Barrier
	[45438]  = true, -- Ice Block
	[108839] = true, -- Ice Floes
	[111264] = true, -- Ice Ward
	[12472]  = true, -- Icy Veins
	[157610] = true, -- Improved Blink
	[157633] = true, -- Improved Scorch
	[116267] = true, -- Incanter's Flow
	[66]     = true, -- Invisibility
	[6117]   = true, -- Mage Armor
	[55342]  = true, -- Mirror Image
	[30482]  = true, -- Molten Armor
	[12043]  = true, -- Presence of Mind
	[46989]  = true, -- Rapid Teleportation (Glyph of)
	[163299] = true, -- Rune of Power
}
self_debuffs.MAGE = {
	[41425]  = true, -- Hypothermia
	[36032]  = true, -- Arcane Charge
	[87023]  = true, -- Cauterize
	[87024]  = true, -- Cauterized
}
pet_buffs.MAGE = {}
enemy_debuffs.MAGE = {
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
	[102051] = true, -- Frostjaw
	[84714]  = true, -- Frozen Orb
	[7302]   = true, -- Ice Armor
	[157997]  = true, -- Ice Nova
	[3261]   = true, -- Ignite
	[114923] = true, -- Nether Tempest
	[44457]  = true, -- Living Bomb
	[118]    = true, -- Polymorph
	[11366]  = true, -- Pyroblast
	[31589]  = true, -- Slow
}

-- PALADIN
friend_buffs.PALADIN = {
	[53563]  = true, -- Beacon of Light
	[157007] = true, -- Beacon of Insight
	[20217]  = true, -- Blessing of Kings
	[19740]  = true, -- Blessing of Might
	[31821]  = true, -- Devotion Aura
	[114163] = true, -- Eternal Flame
	[54957]  = true, -- Glyph of Flash of Light
	[1044]   = true, -- Hand of Freedom
	[1022]   = true, -- Hand of Protection
	[114039] = true, -- Hand of Purity
	[6940]   = true, -- Hand of Sacrifice
	[1038]   = true, -- Hand of Salvation
	[105809] = true, -- Holy Avenger
	[86273]  = true, -- Illuminated Healing
	[20925]  = true, -- Sacred Shield
	[157128] = true, -- Saved by the Light
	[152262] = true, -- Seraphim
	[114917] = true, -- Stay of Execution
}
friend_debuffs.PALADIN = {
	[25771]  = true, -- Forbearance
	[157131] = true, -- Recently Saved by the Light
}
self_buffs.PALADIN = {
	[31850]  = true, -- Ardent Defender
	[31842]  = true, -- Avenging Wrath (Holy)
	[31884]  = true, -- Avenging Wrath (Retribution)
	[114637] = true, -- Bastion of Glory
	[121183] = true, -- Contemplation
	[88819]  = true, -- Daybreak
	[498]    = true, -- Divine Protection
	[90174]  = true, -- Divine Purpose
	[642]    = true, -- Divine Shield
	[156989] = true, -- Empowered Seals - Liadrin's Righteousness
	[156990] = true, -- Empowered Seals - Maraad's Truth
	[156987] = true, -- Empowered Seals - Turalyon's Justice
	[156988] = true, -- Empowered Seals - Uther's Insight
	[157048] = true, -- Final Verdict
	[121027] = true, -- Glyph of Double Jeopardy
	[115522] = true, -- Glyph of Word of Glory
	[115668] = true, -- Glyph of Templar's Verdict
	[85416]  = true, -- Grand Crusader
	[86659]  = true, -- Guardian of the Ancient Kings
	[54149]  = true, -- Infusion of Light
	[114695] = true, -- Pursuit of Justice
	[62124]  = true, -- Reckoning
	[25780]  = true, -- Righteous Fury
	[105361] = true, -- Seal of Command
	[20164]  = true, -- Seal of Justice
	[20165]  = true, -- Seal of Insight
	[20154]  = true, -- Seal of Righteousness
	[31801]  = true, -- Seal of Truth
	[114250] = true, -- Selfless Healer
	[132403] = true, -- Shield of the Righteous
	[85499]  = true, -- Speed of Light
}
self_debuffs.PALADIN = {}
pet_buffs.PALADIN = {}
enemy_debuffs.PALADIN = {
	[114919] = true, -- Arcing Light (Light's Hammer)
	[31935]  = true, -- Avenger's Shield
	[105421] = true, -- Blinding Light
	[31803]  = true, -- Censure (Seal of Truth)
	[26573]  = true, -- Consecration
	[63529]  = true, -- Dazed - Avenger's Shield
	[2812]   = true, -- Denounce
	[114916] = true, -- Execution Sentence
	[105593] = true, -- Fist of Justice
	[853]    = true, -- Hammer of Justice
	[119072] = true, -- Holy Wrath
	[20066]  = true, -- Repentance
	[10326]  = true, -- Turn Evil
}

-- PRIEST
friend_buffs.PRIEST = {
	[121557] = true, -- Angelic Feather
	[152118] = true, -- Clarity of Will
	[47753]  = true, -- Divine Aegis
	[64843]  = true, -- Divine Hymn
	[77489]  = true, -- Echo of Light
	[157146] = true, -- Enhanced Leap of Faith
	[6346]   = true, -- Fear Ward
	[47788]  = true, -- Guardian Spirit
	[1706]   = true, -- Levitate
	[7001]   = true, -- Lightwell Renew
	[49868]  = true, -- Mind Quickening
	[81782]  = true, -- Power Word: Barrier
	[21562]  = true, -- Power Word: Fortitude
	[17]     = true, -- Power Word: Shield
	[123258] = true, -- Power Word: Shield (Divine Insight)
	[21562]  = true, -- Prayer of Fortitude
	[33206]  = true, -- Pain Suppression
	[41635]  = true, -- Prayer of Mending
	[123262] = true, -- Prayer of Mending (Divine Insight)
	[139]    = true, -- Renew
}
friend_debuffs.PRIEST = {
	[2096]   = true, -- Mind Vision
	[6788]   = true, -- Weakened Soul
}
self_buffs.PRIEST = {
	[114214] = true, -- Angelic Bulwark
	[81700]  = true, -- Archangel
	[65081]  = true, -- Body and Soul
	[59889]  = true, -- Borrowed Time
	[81209]  = true, -- Chakra: Chastise
	[81206]  = true, -- Chakra: Sanctuary
	[81208]  = true, -- Chakra: Serenity
	[47585]  = true, -- Dispersion
	[123266] = true, -- Divine Insight (Holy)
	[123267] = true, -- Divine Insight (Discipline)
	[605]    = true, -- Dominate Mind
	[81661]  = true, -- Evangelism
	[586]    = true, -- Fade
	[81292]  = true, -- Glyph of Mind Spike
	[159628] = true, -- Glyph of Shadow Magic
	[132573] = true, -- Insanity
	[2096]   = true, -- Mind Vision
	[114239] = true, -- Phantasm
	[10060]  = true, -- Power Infusion
	[123254] = true, -- Twist of Fate
	[63735]  = true, -- Serendipity
	[15473]  = true, -- Shadowform
	[124430] = true, -- Shadowy Insight
	[112833] = true, -- Spectral Guise
	[27827]  = true, -- Spirit of Redemption
	[109964] = true, -- Spirit Shell
	[87160]  = true, -- Surge of Darkness
	[114255] = true, -- Surge of Light
	[15286]  = true, -- Vampiric Embrace
	[155362] = true, -- Word of Mending
}
self_debuffs.PRIEST = {
	[114216] = true, -- Angelic Bulwark
	[155274] = true, -- Saving Grace
}
pet_buffs.PRIEST = {}
enemy_debuffs.PRIEST = {
	[2944]   = true, -- Devouring Plague
	[605]    = true, -- Dominate Mind
	[87194]  = true, -- Glyph of Mind Blast
	[14914]  = true, -- Holy Fire
	[88625]  = true, -- Holy Word: Chastise
	[15407]  = true, -- Mind Flay
	[49821]  = true, -- Mind Sear
	[2096]   = true, -- Mind Vision
	[129250] = true, -- Power Word: Solace
	[64044]  = true, -- Psychic Horror
	[8122]   = true, -- Psychic Scream
	[9484]   = true, -- Shackle Undead
	[589]    = true, -- Shadow Word: Pain
	[15487]  = true, -- Silence
	[15286]  = true, -- Vampiric Embrace
	[34914]  = true, -- Vampiric Touch
	[155361] = true, -- Void Entropy
	[114404] = true, -- Void Tendril
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
	[51713]  = true, -- Shadow Dance
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
	[91023]  = true, -- Find Weakness
	[703]    = true, -- Garrote
	[1330]   = true, -- Garrote - Silence
	[1776]   = true, -- Gouge
	[16511]  = true, -- Hemorrhage
	[408]    = true, -- Kidney Shot
	[84617]  = true, -- Revealing Strike
	[1943]   = true, -- Rupture
	[6770]   = true, -- Sap
	[79140]  = true, -- Vendetta
	[8679]   = true, -- Wound Poison
}

-- SHAMAN
friend_buffs.SHAMAN = {
	[2825]   = player_faction == "Horde", -- Bloodlust
	[974]    = true, -- Earth Shield
	[4057]   = true, -- Fire Resistance
	[4077]   = true, -- Frost Resistance
	[116956] = true, -- Grace of Air
	[8178]   = true, -- Grounding Totem Effect
	[73920]  = true, -- Healing Rain
	[119523] = true, -- Healing Stream Totem (Glyph of Healing Stream Totem)
	[32182]  = player_faction == "Alliance", -- Heroism
	[61295]  = true, -- Riptide
	[546]    = true, -- Water Walking
	[27621]  = true, -- Windfury Totem
}
friend_debuffs.SHAMAN = {
	[57723]  = player_faction == "Alliance", -- Exhaustion
	[57724]  = player_faction == "Horde", -- Sated
}
self_buffs.SHAMAN = {
	[114051] = true, -- Ascendance
	[118522] = true, -- Elemental Blast
	[16166]  = true, -- Elemental Mastery
	[6196]   = true, -- Far Sight
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
	[58875]  = true, -- Spirit Walk
	[73685]  = true, -- Unleash Life
}
self_debuffs.SHAMAN = {}
pet_buffs.SHAMAN = {
	[58875]  = true, -- Spirit Walk
}
enemy_debuffs.SHAMAN = {
	[3600]   = true, -- Earthbind
	[8377]   = true, -- Earthgrab
	[61882]  = true, -- Earthquake
	[8050]   = true, -- Flame Shock
	[63685]  = true, -- Freeze (Frozen Power)
	[8056]   = true, -- Frost Shock
	[17364]  = true, -- Stormstrike
	[51490]  = true, -- Thunderstorm
	[51514]  = true, -- Hex
}

-- WARLOCK
friend_buffs.WARLOCK = {
	[166928] = true, -- Blood Pact
	[109773] = true, -- Dark Intent
	[1098]   = true, -- Enslave Demon
	[134]    = true, -- Fire Shield
	[20707]  = true, -- Soulstone
	[5697]   = true, -- Unending Breath
}
friend_debuffs.WARLOCK = {}
self_buffs.WARLOCK = {
	[117828] = true, -- Backdraft
	[111397] = true, -- Blood Horror
	[111400] = true, -- Burning Rush
	[110913] = true, -- Dark Bargain
	[108359] = true, -- Dark Regeneration
	[113858] = true, -- Dark Soul: Instability
	[113861] = true, -- Dark Soul: Knowledge
	[113860] = true, -- Dark Soul: Misery
	[157695] = true, -- Demonbolt
	[88448]  = true, -- Demonic Rebirth
	[171982] = true, -- Demonic Synergy
	[126]    = true, -- Eye of Kilrogg
	[108683] = true, -- Fire and Brimstone
	[120451] = true, -- Flames of Xoroth
	[108503] = true, -- Grimoire of Sacrifice
	[755]    = true, -- Health Funnel
	[6262]   = true, -- Healthstone (Glyph of)
	[1949]   = true, -- Hellfire
	[104025] = true, -- Immolation Aura
	[137587] = true, -- Kil'jaeden's Cunning
	[1454]   = true, -- Life Tap (Glyph of)
	[108508] = true, -- Mannoroth's Fury
	[103958] = true, -- Metamorphosis
	[122355] = true, -- Molten Core
	[108416] = true, -- Sacrificial Pact
	[17941]  = true, -- Shadow Trance
	[74434]  = true, -- Soulburn
	[79438]  = true, -- Soulburn: Demonic Circle
	[86211]  = true, -- Soul Swap
	[101976] = true, -- Soul Harvest
	[104773] = true, -- Unending Resolve
}
self_debuffs.WARLOCK = {
	[110914] = true, -- Dark Bargain
}
pet_buffs.WARLOCK = {
	[23257]  = true, -- Demonic Frenzy
	[171982] = true, -- Demonic Synergy
	[89751]  = true, -- Felstorm (Felguard)
	[7870]   = true, -- Lesser Invisibility (Succubus)
	[30151]  = true, -- Pursuit (Felguard)
	[22987]  = true, -- Ritual Enslavement (Doomguard)
	[17767]  = true, -- Shadow Bulwark/Consume Shadows (Voidwalker)
	[115232] = true, -- Shadow Shield
}
enemy_debuffs.WARLOCK = {
	[85387]  = true, -- Aftermath
	[980]    = true, -- Agony
	[89766]  = true, -- Axe Toss (Felguard)
	[710]    = true, -- Banish
	[137143] = true, -- Blood Horror
	[124915] = true, -- Chaos Wave
	[17962]  = true, -- Conflagrate
	[172]    = true, -- Corruption
	[980]    = true, -- Curse of Agony
	[6789]   = true, -- Mortal Coil
	[603]    = true, -- Doom
	[689]    = true, -- Drain Life
	[103103] = true, -- Drain Soul
	[5782]   = true, -- Fear
	[48181]  = true, -- Haunt
	[80240]  = true, -- Havoc
	[5484]   = true, -- Howl of Terror
	[348]    = true, -- Immolate
	[1122]   = true, -- Inferno
	[22703]  = true, -- Internal Awakening
	[5740]   = true, -- Rain of Fire
	[6358]   = true, -- Seduction (Succubus)
	[27243]  = true, -- Seed of Corruption
	[47960]  = true, -- Hand of Gul'dan
	[29341]  = true, -- Shadowburn
	[30283]  = true, -- Shadowfury
	[6726]   = true, -- Silence
	[6360]   = true, -- Soothing Kiss
	[17735]  = true, -- Suffering (Voidwalker)
	[54049]  = true, -- Shadow Bite
	[30108]  = true, -- Unstable Affliction
}

-- WARRIOR
friend_buffs.WARRIOR = {
	[6673]   = true, -- Battle Shout
	[469]    = true, -- Commanding Shout
	[3411]   = true, -- Intervene
	[114029] = true, -- Safeguard
	[97463]  = true, -- Rallying Cry
	[114030] = true, -- Vigilance
}
friend_debuffs.WARRIOR = {}
self_buffs.WARRIOR = {
	[107574] = true, -- Avatar
	[2457]   = true, -- Battle Stance
	[18499]  = true, -- Berserker Rage
	[46924]  = true, -- Bladestorm
	[12292]  = true, -- Bloodbath
	[46916]  = true, -- Bloodsurge
	[71]     = true, -- Defensive Stance
	[125565] = true, -- Demoralizing Shout
	[118038] = true, -- Die by the Sword
	[12880]  = true, -- Enrage
	[55694]  = true, -- Enraged Regeneration
	[156291] = true, -- Gladiator Stance
	[133278] = true, -- Heroic Leap (Glyph of)
	[12975]  = true, -- Last Stand
	[114028] = true, -- Mass Spell Reflect
	[85739]  = true, -- Meat Cleaver
	[114192] = true, -- Mocking Banner
	[12294]  = true, -- Mortal Strike (Glyph of)
	[131116] = true, -- Raging Blow
	[115317] = true, -- Raging Wind
	[1719]   = true, -- Recklessness
	[125667] = true, -- Second Wind
	[112048] = true, -- Shield Barrier
	[2565]   = true, -- Shield Block
	[169667] = true, -- Shield Charge
	[871]    = true, -- Shield Wall
	[23920]  = true, -- Spell Reflection
	[52437]  = true, -- Sudden Death
	[12328]  = true, -- Sweeping Strikes
	[152277] = true, -- Ravager
	[122510] = true, -- Ultimatum
	[169686] = true, -- Unyielding Strikes
}
self_debuffs.WARRIOR = {
	[1464]   = true, -- Slam
}
pet_buffs.WARRIOR = {}
enemy_debuffs.WARRIOR = {
	[113344] = true, -- Bloodbath
	[105771] = true, -- Charge
	[86346]  = true, -- Colossus Smash
	[1604]   = true, -- Dazed
	[115768] = true, -- Deep Wounds
	[1160]   = true, -- Demoralizing Shout
	[118895] = true, -- Dragon Roar
	[1715]   = true, -- Hamstring
	[5246]   = true, -- Intimidating Shout
	[115804] = true, -- Mortal Wounds
	[12323]  = true, -- Piercing Howl
	[64382]  = true, -- Shattering Throw
	[132168] = true, -- Shockwave
	[176289] = true, -- Siegebreaker
	[18498]  = true, -- Silenced - Gag Order
	[129923] = true, -- Sluggish (Glyph of Hindering Strikes)
	[107570] = true, -- Storm Bolt
	[355]    = true, -- Taunt
	[6343]   = true, -- Thunder Clap
	[772]    = true, -- Rend
	[7922]   = true, -- Warbringer
}

-- MONK
-- TODO: Glyph of Crackling Jade Lightning
-- TODO: Transcendence
friend_buffs.MONK = {
	[132120] = true, -- Enveloping Mist
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
	[116768] = true, -- Combo Breaker: Blackout Kick
	[118864] = true, -- Combo Breaker: Tiger Palm
	[122278] = true, -- Dampen Harm
	[121125] = true, -- Death Note
	[122783] = true, -- Diffuse Magic
	[115308] = true, -- Elusive Brew
	[115288] = true, -- Energizing Brew
	[120954] = true, -- Fortifying Brew
	[115295] = true, -- Guard
	[124273] = true, -- Heavy Stagger
	[124275] = true, -- Light Stagger
	[115867] = true, -- Mana Tea
	[124274] = true, -- Moderate Stagger
	[119085] = true, -- Momentum
	[124968] = true, -- Retreat (Glyph of)
	[127722] = true, -- Serpent's Zeal
	[115307] = true, -- Shuffle (Brewmaster Training)
	[116705] = true, -- Spear Hand Strike
	[107270] = true, -- Spinning Crane Kick
	[124255] = true, -- Stagger
	[116680] = true, -- Thunder Focus Tea
	[116740] = true, -- Tigereye Brew
	[125359] = true, -- Tiger Power
	[120273] = true, -- Tiger Strikes
	[125174] = true, -- Touch of Karma
	[118674] = true, -- Vital Mists
	[125883] = true, -- Zen Flight
	[126896] = true, -- Zen Pilgrimage: Return

}
self_debuffs.MONK = {}
pet_buffs.MONK = {}
enemy_debuffs.MONK = {
	[128531] = true, -- Blackout Kick (Combat Conditioning)
	[115181] = true, -- Breath of Fire
	[119392] = true, -- Charging Ox Wax
	[117952] = true, -- Crackling Jade Lightning
	[123996] = true, -- Crackling Tiger Lighting (Invoke Xuen, the White Tiger)
	[116095] = true, -- Disable
	[115180] = true, -- Dizzying Haze (Keg Smash)
	[117418] = true, -- Fists of Fury
	[123586] = true, -- Flying Serpent Kick
	[119381] = true, -- Leg Sweep
	[118585] = true, -- Leer of the Ox
	[115804] = true, -- Mortal Wounds (Rising Sun Kick)
	[115078] = true, -- Paralysis
	[115546] = true, -- Provoke
	[130320] = true, -- Rising Sun Kick
	[116847] = true, -- Rushing Jade Wind
	[122470] = true, -- Touch of Karma
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
