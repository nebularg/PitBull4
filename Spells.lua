local _G = _G
local PitBull4 = _G.PitBull4

PitBull4.Spells = {}

-- Control spells that share diminishing returns
PitBull4.Spells.dr_spells = {
	-- lol https://wow.gamepedia.com/index.php?title=Diminishing_returns&direction=next&oldid=312955
	-- this was put together from patch notes and checking the mechanic for spells on wowhead /wrists

	-- Disorient/Incapacitate
	[2637] = "disorient", [18657] = "disorient", [18658] = "disorient", -- Hibernate (Druid)
	[3355] = "disorient", [14308] = "disorient", [14309] = "disorient", -- Freezing Trap (Hunter)
	-- [19503] = "disorient", -- Scatter Shot (Hunter)
	[19386] = "disorient", [24132] = "disorient", [24133] = "disorient", -- Wyvern Sting (Hunter)
	[118] = "disorient", [12824] = "disorient", [12825] = "disorient", [12826] = "disorient", [28271] = "disorient", [28272] = "disorient", -- Polymorph (Mage)
	[20066] = "disorient", -- Repentance (Paladin)
	[1776] = "disorient", [1777] = "disorient", [8629] = "disorient", [11285] = "disorient", [11286] = "disorient", -- Gouge (Rogue)
	[6770] = "disorient", [2070] = "disorient", [11297] = "disorient", -- Sap (Rogue)
	[1090] = "disorient", -- Magic Dust (Item)
	-- Fear
	[1513] = "fear", [14326] = "fear", [14327] = "fear", -- Scare Beast (Hunter)
	[8122] = "fear", [8124] = "fear", [10888] = "fear", [10890] = "fear", -- Psychic Scream (Priest)
	[5782] = "fear", [6213] = "fear", [6215] = "fear", -- Fear (Warlock)
	[5484] = "fear", [17928] = "fear", -- Howl of Terror (Warlock)
	[6358] = "fear", -- Seduction (Warlock pet)
	[5246] = "fear", -- Intimidating Shout (Warrior)
	-- Controlled Stun
	[5211] = "stun", [6798] = "stun", [8983] = "stun", -- Bash (Druid)
	[19675] = "stun", -- Feral Charge (Druid)
	[9005] = "stun", [9823] = "stun", [9827] = "stun", -- Pounce (Druid)
	[24394] = "stun", -- Intimidation (Hunter)
	[853] = "stun", [5588] = "stun", [5589] = "stun", [10308] = "stun", -- Hammer of Justice (Paladin)
	[408] = "stun", [8643] = "stun", -- Kidney Shot (Rogue)
	[22703] = "stun", -- Inferno Stun (Warlock pet)
	[7922] = "stun", -- Charge (Warrior)
	[12809] = "stun", -- Concussion Blow (Warrior)
	[20253] = "stun", [20614] = "stun", [20615] = "stun", -- Intercept Stun (Warrior)
	[20549] = "stun", -- War Stomp (Tauren)
	[4068] = "stun", [19769] = "stun", [13808] = "stun", [13237] = "stun", -- Grenades and Mortars (Engineering)
	[4064] = "stun", [4065] = "stun", [4066] = "stun", [4067] = "stun", [4069] = "stun", -- Bombs (Engineering)
	[12421] = "stun", [12543] = "stun", [12562] = "stun", [19784] = "stun", -- Bombs (Engineering)
	[835] = "stun", -- Tidal Charm (Trinket)
	-- Triggered Stun
	-- (removed in 1.9.0)
	-- Root
	[339] = "root", [1062] = "root", [5195] = "root", [5196] = "root", [9852] = "root", [9853] = "root", -- Entangling Roots (Druid)
	[4167] = "root", -- Web (Hunter pet, Spider)
	[122] = "root", [865] = "root", [6131] = "root", [10230] = "root", -- Frost Nova (Mage)
	[8377] = "root", -- Earthgrab Totem (Shaman)
	[8312] = "root", -- Really Sticky Glue (Item)
	-- Triggered Root
	[19970] = "root", [19971] = "root", [19972] = "root", [19973] = "root", [19974] = "root", [19975] = "root", -- Nature's Grasp (Druid)
	-- Snowflakes
	[605] = "charm", -- Mind Control (Priest)
	[13181] = "charm", [26740] = "charm", -- Gnomish Mind Control Cap (Engineering)
	[2094] = "blind", -- Blind (Rogue)
	[1833] = "cheapshot", -- Cheap Shot (Rogue)
	[8056] = "snare", [8058] = "snare", [10472] = "snare", [10473] = "snare", -- Frost Shock (Shaman)
	[710] = "banish", [710] = "banish", -- Banish (Warlock)
}

-- Full list of loss of control spells
PitBull4.Spells.disable_spells = {
	-- Triggered stun
	[16922] = true, -- Improved Starfire (Druid)
	[22570] = true, -- Mangle (Druid)
	[19410] = true, -- Improved Concussive Shot (Hunter)
	[19503] = true, -- Scatter Shot (Hunter)
	[12355] = true, -- Impact (Mage)
	[20170] = true, -- Seal of Justice (Paladin)
	[15269] = true, -- Blackout (Priest)
	[18093] = true, -- Pyroclasm (Warlock)
	[12798] = true, -- Improved Revenge (Warrior)
	[5530] = true,  -- Mace Stun (Mace Specialization)
	-- Silence
	[18469] = true, -- Improved Counterspell (Mage)
	[15487] = true, -- Silence (Priest)
	[18425] = true, -- Improved Kick (Rogue)
	[24259] = true, -- Spell Lock (Warlock)
	[18498] = true, -- Improved Shield Bash (Warrior)
	-- Horrify
	[6789] = true, -- Death Coil (Warlock)
}
for id, cat in next, PitBull4.Spells.dr_spells do
	if cat ~= "root" then
		PitBull4.Spells.disable_spells[id] = true
	end
end

-- Spell channel times
PitBull4.Spells.channel_spells = {
	-- Druid
	[17401] = 10, [17402] = 10, -- Hurricane (no aura)
	[740] = 10, [8918] = 10, [9862] = 10, [9863] = 10, -- Tranquility
	-- Hunter
	[6197] = 60, -- Eagle Eye
	[1002] = 60, -- Eyes of the Beast
	[136] = 5, [3111] = 5, [3661] = 5, [3662] = 5, [13542] = 5, [13543] = 5, [13544] = 5, -- Mend Pet
	[1510] = 6, [14294] = 6, [14295] = 6, -- Volley (no cast bar)
	-- Mage
	[5143] = 3, [5144] = 4, [5145] = 5, [8416] = 5, [8417] = 5, [10211] = 5, [10212] = 5, [25345] = 5, -- Arcane Missiles
	[10] = 8, [6141] = 8, [8427] = 8, [10185] = 8, [10186] = 8, [10187] = 8, -- Blizzard
	[12051] = 8, -- Evocation
	-- Priest
	[605] = 60, [10911] = 60, [10912] = 60, -- Mind Control
	[15407] = 3, [17311] = 3, [17312] = 3, [17313] = 3, [17314] = 3, [18807] = 3, -- Mind Flay
	[2096] = 60, [10909] = 60, -- Mind Vision
	-- Shaman
	[6196] = 60, -- Far Sight
	-- Warlock
	[689] = 5, [699] = 5, [709] = 5, [7651] = 5, [11699] = 5, [11700] = 5, -- Drain Life
	[5138] = 5, [6226] = 5, [11703] = 5, [11704] = 5, -- Drain Mana
	[1120] = 15, [8288] = 15, [8289] = 15, [11675] = 15, -- Drain Soul
	[126] = 45, -- Eye of Kilrogg
	[755] = 10, [3698] = 10, [3699] = 10, [3700] = 10, [11693] = 10, [11694] = 10,  [11695] = 10, -- Health Funnel
	[1949] = 15, [11683] = 15, [11684] = 15, -- Hellfire
	[5740] = 8, [6219] = 8, [11677] = 8, [11678] = 8, -- Rain of Fire
	[18540] = 60,-- Ritual of Doom
	[23598] = 600, -- Ritual of Summoning
	-- Racial
	[10797] = 6, [19296] = 6, [19299] = 6, [19302] = 6, [19303] = 6, [19304] = 6, [19305] = 6, -- Starshards (Night Elf Priest)
	[20577] = 10, [20578] = 10, -- Cannibalize (Undead)
	-- Professions
	[746] = 6, [1159] = 6, [3267] = 7, [3268] = 7, [7926] = 8, [7927] = 8, [23569] = 8, [24412] = 8, [10838] = 8, -- First Aid
	[10839] = 8, [23568] = 8, [24413] = 8, [18608] = 8, [18610] = 8, [23696] = 8, [23567] = 8, [24414] = 8, -- First Aid
	-- [7620] = 30, -- Fishing (no aura)
	[13278] = 4, -- Gnomish Death Ray
}

-- Spell aura durations (filled by Aura)
PitBull4.Spells.spell_durations = {
	-- Items
	[835] = 3, -- Tidal Charm (Trinket)
	[8312] = 10, -- Really Sticky Glue
	[4064] = 1, -- Rough Copper Bomb
	[4065] = 1, -- Large Copper Bomb
	[4066] = 2, -- Small Bronze Bomb
	[4067] = 2, -- Big Bronze Bomb
	[4068] = 3, -- Iron Grenade
	[4069] = 3, -- Big Iron Bomb
	[11196] = 60, -- Recently Bandaged
	[12421] = 2, -- Mithril Frag Bomb
	[12543] = 3, -- Hi-Explosive Bomb
	[12562] = 5, -- The Big One
	[13099] = 10, [13138] = 20, [16566] = 30, -- Net-o-Matic
	[13181] = 20, [26740] = 20, -- Gnomish Mind Control Cap
	[13237] = 3, -- Goblin Mortar
	[13808] = 3, -- M73 Frag Grenade
	[19769] = 3, -- Thorium Grenade
	[19784] = 4, -- Dark Iron Bomb
}
