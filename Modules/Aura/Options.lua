-- Options.lua : Options config

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local PitBull4_Aura= PitBull4:GetModule("Aura")
local L = PitBull4.L
local can_dispel = PitBull4_Aura.can_dispel
local friend_buffs = PitBull4_Aura.friend_buffs
local friend_debuffs = PitBull4_Aura.friend_debuffs
local self_buffs = PitBull4_Aura.self_buffs
local self_debuffs = PitBull4_Aura.self_debuffs
local pet_buffs = PitBull4_Aura.pet_buffs
local enemy_debuffs = PitBull4_Aura.enemy_debuffs
local extra_buffs = PitBull4_Aura.extra_buffs

local color_defaults = {
	friend = {
		my = {0, 1, 0, 1},
		other = {1, 0, 0, 1},
	},
	weapon = {
		weapon = {1, 0, 0, 1},
		quality_color = true,
	},
	enemy = {
		Poison = {0, 1, 0, 1},
		Magic = {0, 0, 1, 1},
		Disease = {.55, .15, 0, 1},
		Curse = {5, 0, 5, 1},
		Enrage = {1, .55, 0, 1},
		["nil"] = {1, 0, 0, 1},
	},
}

PitBull4_Aura:SetDefaults({
	-- Layout defaults
	enabled_buffs = true,
	enabled_debuffs = true,
	enabled_weapons = true,
	buff_size = 16,
	debuff_size = 16,
	--  TODO: max_buffs and max_debuffs are set low
	--  by default since this is for all frames
	--  until we have pre-defined layouts for frames.
	max_buffs = 6,
	max_debuffs = 6,
	zoom_aura = false,
	cooldown = {
		my_buffs = true,
		my_debuffs = true,
		other_buffs = true,
		other_debuffs = true,
		weapon_buffs = true,
	},
	cooldown_text = {
		my_buffs = false,
		my_debuffs = false,
		other_buffs = false,
		other_debuffs = false,
		weapon_buffs = false,
	},
	border = {
		my_buffs = true,
		my_debuffs = true,
		other_buffs = true,
		other_debuffs = true,
		weapon_buffs = true,
	},
	layout = {
		buff = {
			size = 16,
			my_size = 16,
			size_to_fit = true,
			anchor = "BOTTOMLEFT",
			side = "BOTTOM",
			offset_x = 0,
			offset_y = 0,
			width_type = "percent",
			width = 100,
			width_percent = 0.50,
			growth = "right_down",
			sort = true,
			reverse = false,
			row_spacing = 0,
			col_spacing = 0,
			new_row_size = false,
			filter = "",
		},
		debuff = {
			size = 16,
			my_size = 16,
			size_to_fit = true,
			anchor = "BOTTOMRIGHT",
			side = "BOTTOM",
			offset_x = 0,
			offset_y = 0,
			width_type = "percent",
			width = 100,
			width_percent = 0.50,
			growth = "left_down",
			sort = true,
			reverse = false,
			col_spacing = 0,
			row_spacing = 0,
			new_row_size = false,
			filter = "",
		},
	},
},
{
	-- Global defaults
	colors = color_defaults,
	guess_weapon_enchant_icon = true,
	filters = {
		-- default filters are indexed by two character codes.
		-- The first character follows the following format:
		-- ! Master Filters
		-- # Intermediate Filters
		-- % Race map filters
		-- & Class map filters
		-- + DeathKnight
		-- , Druid
		-- - Hunter
		-- . Mage
		-- / Paladin
		-- 0 Priest
		-- 1 Rogue
		-- 2 Shaman
		-- 3 Warlock
		-- 4 Warrior
		-- 5 Human
		-- 6 Dwarf
		-- 7 Night Elf
		-- 8 Gnome
		-- 9 Draenei
		-- : Orc
		-- ; Undead
		-- < Taruen
		-- = Troll
		-- > Blood Elf
		-- @ Simple filters
		--
		-- The 2nd character places it within the proper order
		-- under those major categories.  That said the follow
		-- are generally true
		-- 0 self buffs
		-- 1 pet buffs
		-- 2 friend buffs
		-- 3 can dispel
		-- 4 self buffs
		-- 5 friend debuffs
		-- 6 enemy debuffs
		--
		-- This is necessary to get the sort order proper for the
		-- drop down boxes while using a value that is not localized
		['@I'] = {
			display_name = L['True'],
			filter_type = 'True',
			disabled = true,
			built_in = true,
		},
		['@J'] = {
			display_name = L['False'],
			filter_type = 'False',
			disabled = true,
			built_in = true,
		},
		['@A'] = {
			display_name = L['Buff'],
			filter_type = 'Buff',
			buff = true,
			disabled = true,
			built_in = true,
		},
		['@B'] = {
			display_name = L['Debuff'],
			filter_type = 'Buff',
			buff = false,
			disabled = true,
			built_in = true,
		},
		['@C'] = {
			display_name = L['Weapon buff'],
			filter_type = 'Weapon Enchant',
			weapon = true,
			disabled = true,
			built_in = true,
		},
		['@D'] = {
			display_name = L['Friend'],
			filter_type = 'Unit',
			unit_operator = 'friend',
			disabled = true,
			built_in = true,
		},
		['@E'] = {
			display_name = L['Enemy'],
			filter_type = 'Unit',
			unit_operator = 'enemy',
			disabled = true,
			built_in = true,
		},
		['@F'] = {
			display_name = L['Pet'],
			filter_type = 'Unit',
			unit_operator = '==',
			unit = 'pet',
			disabled = true,
			built_in = true,
		},
		['@G'] = {
			display_name = L['Player'],
			filter_type = 'Unit',
			unit_operator = '==',
			unit = 'player',
			disabled = true,
			built_in = true,
		},
		['@H'] = {
			display_name = L['Mine'],
			filter_type = 'Mine',
			mine = true,
			disabled = true,
			built_in = true,
		},
		[',3'] = {
			display_name = L['Druid can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['DRUID'],
			built_in = true,
		},
		['-3'] = {
			display_name = L['Hunter can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['HUNTER'],
			built_in = true,
		},
		['.3'] = {
			display_name = L['Mage can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['MAGE'],
			built_in = true,
		},
		['/3'] = {
			display_name = L['Paladin can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['PALADIN'],
			built_in = true,
		},
		['03'] = {
			display_name = L['Priest can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['PRIEST'],
			built_in = true,
		},
		['13'] = {
			display_name = L['Rogue can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['ROGUE'],
			built_in = true,
		},
		['23'] = {
			display_name = L['Shaman can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['SHAMAN'],
			built_in = true,
		},
		['33'] = {
			display_name = L['Warlock can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['WARLOCK'],
			built_in = true,
		},
		['43'] = {
			display_name = L['Warrior can dispel'],
			filter_type = 'Aura Type',
			whitelist = true,
			aura_type_list = can_dispel['WARRIOR'],
			built_in = true,
		},
		['+0'] = {
			display_name = L['Death Knight self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.DEATHKNIGHT,
			built_in = true,
		},
		[',0'] = {
			display_name = L['Druid self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.DRUID,
			built_in = true,
		},
		['-0'] = {
			display_name = L['Hunter self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.HUNTER,
			built_in = true,
		},
		['.0'] = {
			display_name = L['Mage self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.MAGE,
			built_in = true,
		},
		['/0'] = {
			display_name = L['Paladin self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.PALADIN,
			built_in = true,
		},
		['00'] = {
			display_name = L['Priest self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.PRIEST,
			built_in = true,
		},
		['10'] = {
			display_name = L['Rogue self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.ROGUE,
			built_in = true,
		},
		['20'] = {
			display_name = L['Shaman self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.SHAMAN,
			built_in = true,
		},
		['30'] = {
			display_name = L['Warlock self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.WARLOCK,
			built_in = true,
		},
		['40'] = {
			display_name = L['Warrior self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.WARRIOR,
			built_in = true,
		},
		['+1'] = {
			display_name = L['Death Knight pet buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = pet_buffs.DEATHKNIGHT,
			built_in = true,
		},
		['-1'] = {
			display_name = L['Hunter pet buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = pet_buffs.HUNTER,
			built_in = true,
		},
		['31'] = {
			display_name = L['Warlock pet buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = pet_buffs.WARLOCK,
			built_in = true,
		},
		['+2'] = {
			display_name = L['Death Knight friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.DEATHKNIGHT,
			built_in = true,
		},
		[',2'] = {
			display_name = L['Druid friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.DRUID,
			built_in = true,
		},
		['-2'] = {
			display_name = L['Hunter friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.HUNTER,
			built_in = true,
		},
		['.2'] = {
			display_name = L['Mage friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.MAGE,
			built_in = true,
		},
		['/2'] = {
			display_name = L['Paladin friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.PALADIN,
			built_in = true,
		},
		['02'] = {
			display_name = L['Priest friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.PRIEST,
			built_in = true,
		},
		['12'] = {
			display_name = L['Rogue friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.ROGUE,
			built_in = true,
		},
		['22'] = {
			display_name = L['Shaman friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.SHAMAN,
			built_in = true,
		},
		['32'] = {
			display_name = L['Warlock friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.WARLOCK,
			built_in = true,
		},
		['42'] = {
			display_name = L['Warrior friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.WARRIOR,
			built_in = true,
		},
		['+6'] = {
			display_name = L['Death Knight enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.DEATHKNIGHT,
			built_in = true,
		},
		[',6'] = {
			display_name = L['Druid enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.DRUID,
			built_in = true,
		},
		['-6'] = {
			display_name = L['Hunter enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.HUNTER,
			built_in = true,
		},
		['.6'] = {
			display_name = L['Mage enemey debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.MAGE,
			built_in = true,
		},
		['/6'] = {
			display_name = L['Paladin enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.PALADIN,
			built_in = true,
		},
		['06'] = {
			display_name = L['Priest enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.PRIEST,
			built_in = true,
		},
		['16'] = {
			display_name = L['Rogue enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.ROGUE,
			built_in = true,
		},
		['26'] = {
			display_name = L['Shaman enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.SHAMAN,
			built_in = true,
		},
		['36'] = {
			display_name = L['Warlock enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.WARLOCK,
			built_in = true,
		},
		['46'] = {
			display_name = L['Warrior enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.WARRIOR,
			built_in = true,
		},
		['/5'] = {
			display_name = L['Paladin friend debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_debuffs.PALADIN,
			built_in = true,
		},
		['05'] = {
			display_name = L['Priest friend debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_debuffs.PRIEST,
			built_in = true,
		},
		['25'] = {
			display_name = L['Shaman friend debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_debuffs.SHAMAN,
			built_in = true,
		},
		['60'] = {
			display_name = L['Dwarf self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.Dwarf,
			built_in = true,
		},
		['70'] = {
			display_name = L['Night Elf self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.NightElf,
			built_in = true,
		},
		[':0'] = {
			display_name = L['Orc self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.Orc,
			built_in = true,
		},
		[';0'] = {
			display_name = L['Undead self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.Scourge,
			built_in = true,
		},
		['=0'] = {
			display_name = L['Troll self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.Troll,
			built_in = true,
		},
		['>0'] = {
			display_name = L['Blood Elf self buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_buffs.BloodElf,
			built_in = true,
		},
		['52'] = {
			display_name = L['Human friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Human,
			built_in = true,
		},
		['62'] = {
			display_name = L['Dwarf friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Dwarf,
			built_in = true,
		},
		['72'] = {
			display_name = L['Night Elf friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.NightElf,
			built_in = true,
		},
		['82'] = {
			display_name = L['Gnome friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Gnome,
			built_in = true,
		},
		['92'] = {
			display_name = L['Draenei friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Draenei,
			built_in = true,
		},
		[':2'] = {
			display_name = L['Orc friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Orc,
			built_in = true,
		},
		[';2'] = {
			display_name = L['Undead friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Scourge,
			built_in = true,
		},
		['<2'] = {
			display_name = L['Tauren friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Tauren,
			built_in = true,
		},
		['=2'] = {
			display_name = L['Troll friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.Troll,
			built_in = true,
		},
		['>2'] = {
			display_name = L['Blood Elf friend buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = friend_buffs.BloodElf,
			built_in = true,
		},
		['<6'] = {
			display_name = L['Taruen enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.Tauren,
			built_in = true,
		},
		['>6'] = {
			display_name = L['Blood Elf enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = enemy_debuffs.BloodElf,
			built_in = true,
		},
		[':4'] = {
			display_name = L['Orc self debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_debuffs.Orc,
			built_in = true,
		},
		['.4'] = {
			display_name = L['Mage self debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_debuffs.MAGE,
			built_in = true,
		},
		['04'] = {
			display_name = L['Priest self debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_debuffs.PRIEST,
			built_in = true,
		},
		['44'] = {
			display_name = L['Warrior self debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = self_debuffs.WARRIOR,
			built_in = true,
		},
		['&D'] = {
			display_name = L['My class can dispel'],
			filter_type = 'Map',
			map_type = 'class',
			map = {
				['DEATHKNIGHT'] = '@J',
				['DRUID'] = ',3',
				['HUNTER'] = '-3',
				['MAGE'] = '.3',
				['PALADIN'] = '/3',
				['PRIEST'] = '03',
				['ROGUE'] = '13',
				['SHAMAN'] = '23',
				['WARLOCK'] = '33',
				['WARRIOR'] = '43',
			},
			built_in = true,
		},
		['&A'] = {
			display_name = L['My class self buffs'],
			filter_type = 'Map',
			map_type = 'class',
			map = {
				['DEATHKNIGHT'] = '+0',
				['DRUID'] = ',0',
				['HUNTER'] = '-0',
				['MAGE'] = '.0',
				['PALADIN'] = '/0',
				['PRIEST'] = '00',
				['ROGUE'] = '10',
				['SHAMAN'] = '20',
				['WARLOCK'] = '30',
				['WARRIOR'] = '40',
			},
			built_in = true,
		},
		['&B'] = {
			display_name = L['My class pet buffs'],
			filter_type = 'Map',
			map_type = 'class',
			map = {
				['DEATHKNIGHT'] = '+1',
				['DRUID'] = '@J',
				['HUNTER'] = '-1',
				['MAGE'] = '@J',
				['PALADIN'] = '@J',
				['PRIEST'] = '@J',
				['ROGUE'] = '@J',
				['SHAMAN'] = '@J',
				['WARLOCK'] = '31',
				['WARRIOR'] = '@J',
			},
			built_in = true,
		},
		['&C'] = {
			display_name = L['My class friend buffs'],
			filter_type = 'Map',
			map_type = 'class',
			map = {
				['DEATHKNIGHT'] = '+2',
				['DRUID'] = ',2',
				['HUNTER'] = '-2',
				['MAGE'] = '.2',
				['PALADIN'] = '/2',
				['PRIEST'] = '02',
				['ROGUE'] = '12',
				['SHAMAN'] = '22',
				['WARLOCK'] = '32',
				['WARRIOR'] = '42',
			},
			built_in = true,
		},
		['&G'] = {
			display_name = L['My class enemy debuffs'],
			filter_type = 'Map',
			map_type = 'class',
			map = {
				['DEATHKNIGHT'] = '+6',
				['DRUID'] = ',6',
				['HUNTER'] = '-6',
				['MAGE'] = '.6',
				['PALADIN'] = '/6',
				['PRIEST'] = '06',
				['ROGUE'] = '16',
				['SHAMAN'] = '26',
				['WARLOCK'] = '36',
				['WARRIOR'] = '46',
			},
			built_in = true,
		},
		['&F'] = {
			display_name = L['My class friend debuffs'],
			filter_type = 'Map',
			map_type = 'class',
			map = {
				['DEATHKNIGHT'] = '@J',
				['DRUID'] = '@J',
				['HUNTER'] = '@J',
				['MAGE'] = '@J',
				['PALADIN'] = '/5',
				['PRIEST'] = '05',
				['ROGUE'] = '@J',
				['SHAMAN'] = '25',
				['WARLOCK'] = '@J',
				['WARRIOR'] = '@J',
			},
			built_in = true,
		},
		['&E'] = {
			display_name = L['My class self debuffs'],
			filter_type = 'Map',
			map_type == 'class',
			map = {
				['DEATHKNIGHT'] = '@J',
				['DRUID'] = '@J',
				['HUNTER'] = '@J',
				['MAGE'] = '.4',
				['PALADIN'] = '@J',
				['PRIEST'] = '04',
				['ROGUE'] = '@J',
				['SHAMAN'] = '@J',
				['WARLOCK'] = '@J',
				['WARRIOR'] = '44',

			},
			built_in = true,
		},
		['%A'] = {
			display_name = L['My race self buffs'],
			filter_type = 'Map',
			map_type = 'race',
			map = {
				['Human'] = '@J',
				['Dwarf'] = '60',
				['NightElf'] = '70',
				['Gnome'] = '@J',
				['Draenei'] = '@J',
				['Orc'] = ':0',
				['Scourge'] = ';0',
				['Tauren'] = '@J',
				['Troll'] = '=0',
				['BloodElf'] = '>0',
			},
			built_in = true,
		},
		['%B'] = {
			display_name = L['My race friend buffs'],
			filter_type = 'Map',
			map_type = 'race',
			map = {
				['Human'] = '52',
				['Dwarf'] = '62',
				['NightElf'] = '72',
				['Gnome'] = '82',
				['Draenei'] = '92',
				['Orc'] = ':2',
				['Scourge'] = ';2',
				['Tauren'] = '<2',
				['Troll'] = '=2',
				['BloodElf'] = '>2',
			},
			built_in = true,
		},
		['%D'] = {
			display_name = L['My race enemy debuffs'],
			filter_type = 'Map',
			map_type = 'race',
			map = {
				['Human'] = '@J',
				['Dwarf'] = '@J',
				['NightElf'] = '@J',
				['Gnome'] = '@J',
				['Draenei'] = '@J',
				['Orc'] = '@J',
				['Scourge'] = '@J',
				['Tauren'] = '<6',
				['Troll'] = '@J',
				['BloodElf'] = '>6',
			},
			built_in = true,
		},
		['%C'] = {
			display_name = L['My race self debuffs'],
			filter_type = 'Map',
			map_type = 'race',
			map = {
				['Human'] = '@J',
				['Dwarf'] = '@J',
				['NightElf'] = '@J',
				['Gnome'] = '@J',
				['Draenei'] = '@J',
				['Orc'] = ':4',
				['Scourge'] = '@J',
				['Tauren'] = '@J',
				['Troll'] = '@J',
				['BloodElf'] = '@J',
			},
			built_in = true,
		},
		['*A'] = {
			display_name = L['Extra buffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = extra_buffs,
			built_in = true,
		},
		['*B'] = {
			display_name = L['Extra friend debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = {},
			built_in = true,
		},
		['*C'] = {
			display_name = L['Extra enemy debuffs'],
			filter_type = 'Name',
			whitelist = true,
			name_list = {},
			built_in = true,
		},
		['#A'] = {
			display_name = L['All self buffs'],
			filter_type = 'Meta',
			filters = {'&A','%A','@C'},
			operators = {'|','|'},
			built_in = true,
		},
		['#C'] = {
			display_name = L['All self debuffs'],
			filter_type = 'Meta',
			filters = {'&E','%C'},
			operators = {'|'},
			built_in = true,
		},
		['#B'] = {
			display_name = L['All friend buffs'],
			filter_type = 'Meta',
			filters =  {'&C','%B','*A'},
			operators = {'|','|'},
			built_in = true,
		},
		['#D'] = {
			display_name = L['All friend debuffs'],
			filter_type = 'Meta',
			filters = {'&F','&D','*B'},
			operators = {'|','|'},
			built_in = true,
		},
		['#E'] = {
			display_name = L['All enemy debuffs'],
			filter_type = 'Meta',
			filters = {'&G','%D','*C'},
			operators = {'|','|'},
			built_in = true,
		},
		['!B'] = {
			display_name = L['Default buffs'],
			filter_type = 'Meta',
			filters = {'@G','#A','@F','&B','@D','#B','@E'},
			operators = {'&','|','&','|','&','|'},
			built_in = true,
			display_when = "buff",
		},
		['!C'] = {
			display_name = L['Default buffs, mine'],
			filter_type = 'Meta',
			filters = {'@H','!B','@E'},
			operators = {'&','|'},
			built_in = true,
			display_when = "buff",
		},
		['!D'] = {
			display_name = L['Default debuffs'],
			filter_type = 'Meta',
			filters = {'@G','#C','@D','#D','#E'},
			operators = {'&','|','&','|'},
			built_in = true,
			display_when = "debuff",
		},
		['!E'] = {
			display_name = L['Default debuffs, mine'],
			filter_type = 'Meta',
			filters = {'@H','!D','&D'},
			operators = {'&','|'},
			built_in = true,
			display_when = "debuff",
		},
	},
})

-- tables of options for the selection options

local anchor_values = {
	TOPLEFT_TOP        = L['Top-left on top'],
	TOPRIGHT_TOP       = L['Top-right on top'],
	TOPLEFT_LEFT       = L['Top-left on left'],
	TOPRIGHT_RIGHT     = L['Top-right on right'],
	BOTTOMLEFT_BOTTOM  = L['Bottom-left on bottom'],
	BOTTOMRIGHT_BOTTOM = L['Bottom-right on bottom'],
	BOTTOMLEFT_LEFT    = L['Bottom-left on left'],
	BOTTOMRIGHT_RIGHT  = L['Bottom-right on right'],
}

local growth_values = {
	left_up    = L["Left then up"],
	left_down  = L["Left then down"],
	right_up   = L["Right then up"],
	right_down = L["Right then down"],
	up_left    = L["Up then left"],
	up_right   = L["Up then right"],
	down_left  = L["Down then left"],
	down_right = L["Down then right"],
}

local width_type_values = {
	percent = L['Percentage of side'],
	fixed   = L['Fixed size'],
}

local show_when_values = {
	my_buffs = L['My own buffs'],
	my_debuffs = L['My own debuffs'],
	other_buffs = L["Others' buffs"],
	other_debuffs = L["Others' debuffs"],
	weapon_buffs = L["Weapon buffs"],
}

-- table to decide if the width option is actuually
-- representing width or height
local is_height = {
	down_right = true,
	down_left  = true,
	up_right   = true,
	up_left    = true,
}

PitBull4_Aura:SetColorOptionsFunction(function(self)
	local function get(info)
		local group = info[#info - 1]
		local id = info[#info]
		return unpack(self.db.profile.global.colors[group][id])
	end
	local function set(info, r, g, b, a)
		local group = info[#info - 1]
		local id = info[#info]
		self.db.profile.global.colors[group][id] = {r, g, b, a}
		self:UpdateAll()
	end
	return 'friend', {
		type = 'group',
		name = L['Friendly auras'],
		inline = true,
		args = {
			my = {
				type = 'color',
				name = L['Own'],
				desc = L['Color for own buffs.'],
				get = get,
				set = set,
				order = 0,
			},
			other = {
				type = 'color',
				name = L['Others'],
				desc = L["Color of others' buffs."],
				get = get,
				set = set,
				order = 1,
			},
		},
	},
	'weapon', {
		type = 'group',
		name = L['Weapon auras'],
		inline = true,
		args = {
			weapon = {
				type = 'color',
				name = L['Weapon enchants'],
				desc = L['Color for temporary weapon enchants.'],
				get = get,
				set = set,
				disabled = function(info)
					return self.db.profile.global.colors.weapon.quality_color
				end,
				order = 3,
			},
			quality_color = {
				type = 'toggle',
				name = L['Color by quality'],
				desc = L['Color temporary weapon enchants by weapon quality.'],
				get = function(info)
					return self.db.profile.global.colors.weapon.quality_color
				end,
				set = function(info, value)
					self.db.profile.global.colors.weapon.quality_color = value
					self:UpdateAll()
				end,
			},
		},

	},
	'enemy', {
		type = 'group',
		name = L['Unfriendly auras'],
		inline = true,
		args = {
			Poison = {
				type = 'color',
				name = L['Poison'],
				desc = L["Color for poison."],
				get = get,
				set = set,
				order = 0,
			},
			Magic = {
				type = 'color',
				name = L['Magic'],
				desc = L["Color for magic."],
				get = get,
				set = set,
				order = 1,
			},
			Disease = {
				type = 'color',
				name = L['Disease'],
				desc = L["Color for disease."],
				get = get,
				set = set,
				order = 2,
			},
			Curse = {
				type = 'color',
				name = L['Curse'],
				desc = L["Color for curse."],
				get = get,
				set = set,
				order = 3,
			},
			Enrage = {
				type = 'color',
				name = L['Enrage'],
				desc = L["Color for enrage."],
				get = get,
				set = set,
				order = 4,
			},
			["nil"] = {
				type = 'color',
				name = L['Other'],
				desc = L["Color for other auras without a type."],
				get = get,
				set = set,
				order = 5,
			},
		},
	}, function(info)
		-- reset_default_colors
		local db = self.db.profile.global.colors
		for group,group_table in pairs(color_defaults) do
			for color,color_value in pairs(group_table) do
				if type(color_value) == "table" then
					for i = 1, #color_value do
						db[group][color][i] = color_value[i]
					end
				else
					db[group][color] = color_value
				end
			end
		end
	end
end)


PitBull4_Aura:SetGlobalOptionsFunction(function(self)
	return 'guess_weapon_enchant_icon', {
		type = 'toggle',
		name = L['Use spell icon'],
		desc = L['Use the spell icon for the weapon enchant rather than the icon for the weapon.'],
		get = function(info)
			return self.db.profile.global.guess_weapon_enchant_icon
		end,
		set = function(info, value)
			self.db.profile.global.guess_weapon_enchant_icon = value
			self:UpdateWeaponEnchants(true)
		end,
	}, 'filter_editor', {
		type = 'group',
		childGroups = 'tab',
		name = L['Aura filter editor'],
		desc = L['Configure the filters for the aura modules.'],
		args = PitBull4_Aura:GetFilterEditor(),
	}
end)

PitBull4_Aura:SetLayoutOptionsFunction(function(self)

	-- Functions for use in the options
	local function get(info)
		local id = info[#info]
		return PitBull4.Options.GetLayoutDB(self)[id]
	end
	local function set(info, value)
		local id = info[#info]
		PitBull4.Options.GetLayoutDB(self)[id] = value
		PitBull4.Options.UpdateFrames()
	end
	local function get_multi(info, key)
		local id = info[#info]
		return PitBull4.Options.GetLayoutDB(self)[id][key]
	end
	local function set_multi(info, key, value)
		local id = info[#info]
		PitBull4.Options.GetLayoutDB(self)[id][key] = value
		PitBull4.Options.UpdateFrames()
	end
	local function get_layout(info)
		local id = info[#info]
		local group = info[#info - 1]
		return PitBull4.Options.GetLayoutDB(self).layout[group][id]
	end
	local function set_layout(info, value)
		local id = info[#info]
		local group = info[#info - 1]
		PitBull4.Options.GetLayoutDB(self).layout[group][id] = value
		PitBull4.Options.UpdateFrames()
	end
	local function get_layout_filter(info)
		local id = info[#info]
		return PitBull4.Options.GetLayoutDB(self).layout[id].filter
	end
	local function set_layout_filter(info, value)
		local id = info[#info]
		PitBull4.Options.GetLayoutDB(self).layout[id].filter = value
		PitBull4.Options.UpdateFrames()
	end
	local function get_layout_filter_values(info)
		local t = {}
		local filters = PitBull4_Aura.db.profile.global.filters
		t[""] = L["None"]
		for k,v in pairs(filters) do
			local display_when = v.display_when
			local group = info[#info]
			if display_when == "both" or display_when == group then
				t[k] = v.display_name or k
			end
		end
		return t
	end
	local function get_layout_anchor(info)
		local group = info[#info - 1]
		local db = PitBull4.Options.GetLayoutDB(self).layout[group]
		return db.anchor .. "_" .. db.side
	end
	local function set_layout_anchor(info, value)
		local group = info[#info - 1]
		local db = PitBull4.Options.GetLayoutDB(self).layout[group]
		db.anchor, db.side = string.match(value, "(.*)_(.*)")
		PitBull4.Options.UpdateFrames()
	end
	local function is_aura_disabled(info)
		return not PitBull4.Options.GetLayoutDB(self).enabled
	end

	-- Layout configuration.  It's used for both buffs and debuffs
	local layout = {
		type = 'group',
		name = function(info)
			local group = info[#info]
			if group == 'buff' then
				return L['Buff layout']
			else
				return L['Debuff layout']
			end
		end,
		args = {
			size = {
				type = 'range',
				name = L['Icon size'],
				desc = L['Set size of the aura icons.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				min = 4,
				max = 48,
				step = 1,
				order = 0,
			},
			my_size = {
				type = 'range',
				name = L['Icon size for my auras'],
				desc = L['Set size of icons of auras cast by me.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				min = 4,
				max = 48,
				step = 1,
				order = 1,
			},
			size_to_fit = {
				type = 'toggle',
				name = L['Size to fit'],
				desc = L['Size auras to use up as much of the space available as possible.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				order = 2,
			},
			break_1 = {
				type = 'header',
				name = '',
				order = 10,
			},
			anchor = {
				-- Anchor option actually sets 2 values, we do the split here so we don't have to do it in a more time sensitive place
				type = 'select',
				name = L['Start at'],
				desc = L['Set the corner and side to start auras from.'],
				get = get_layout_anchor,
				set = set_layout_anchor,
				disabled = is_aura_disabled,
				values = anchor_values,
				order = 11,
			},
			growth = {
				type = 'select',
				name = L['Growth direction'],
				desc = L['Direction that the auras will grow.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				values = growth_values,
				order = 12,
			},
			break_2 = {
				type = 'header',
				name = '',
				order = 20,
			},
			offset_x = {
				type = 'range',
				name = L['Horizontal offset'],
				desc = L['Number of pixels to offset the auras from the start point horizontally.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				min = -200,
				max = 200,
				step = 1,
				bigStep = 5,
				order = 21,
			},
			offset_y = {
				type = 'range',
				name = L['Vertical offset'],
				desc = L['Number of pixels to offset the auras from the start point vertically.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				min = -200,
				max = 200,
				step = 1,
				bigStep = 5,
				order = 22,
			},
			break_3 = {
				type = 'header',
				name = '',
				order = 30,
			},
			sort = {
				type = 'toggle',
				name = L['Sort'],
				desc = L['Sort auras by type and alphabetically, preferring your own auras first.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				order = 31,
			},
			reverse = {
				type = 'toggle',
				name = L['Reverse'],
				desc = L['Reverse order in which auras are displayed.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				order = 32,
			},
			break_4 = {
				type = 'header',
				name = '',
				order = 40,
			},
			width_type = {
				type = 'select',
				name = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Height type']
					else
						return L['Width type']
					end
				end,
				desc = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Select how to configure the height setting.']
					else
						return L['Select how to configure the width setting.']
					end
				end,
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				values = width_type_values,
				order = 41,
			},
			width = {
				type = 'range',
				name = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Height']
					else
						return L['Width']
					end
				end,
				desc = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Set how tall the auras will be allowed to grow in pixels.']
					else
						return L['Set how wide the auras will be allowed to grow in pixels.']
					end
				end,
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				hidden = function(info)
					local group = info[#info - 1]
					return PitBull4.Options.GetLayoutDB(self).layout[group].width_type ~= "fixed"
				end,
				min = 20,
				max = 400,
				step = 1,
				bigStep = 5,
				order = 42,
			},
			width_percent = {
				type = 'range',
				name = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Height']
					else
						return L['Width']
					end
				end,
				desc = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Set how tall the auras will be allowed to grow as a percentage of the height of the frame they are attached to.']
					else
						return L['Set how wide the auras will be allowed to grow as a percentage of the width of the frame they are attached to.']
					end
				end,
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				hidden = function(info)
					local group = info[#info - 1]
					return PitBull4.Options.GetLayoutDB(self).layout[group].width_type ~= "percent"
				end,
				min = 0.01,
				max = 1.0,
				step = 0.01,
				isPercent = true,
				order = 42,
			},
			break_5 = {
				type = 'header',
				name = '',
				order = 50,
			},
			row_spacing = {
				type = 'range',
				name = L['Row spacing'],
				desc = L['Set the number of pixels between each row of auras.'],
				get = get_layout,
				set = set_layout,
				disabled = is_arua_disabled,
				min = 0,
				max = 10,
				step = 1,
				order = 51,
			},
			col_spacing = {
				type = 'range',
				name = L['Column spacing'],
				desc = L['Set the number of pixels between each column of auras.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				min = 0,
				max = 10,
				step = 1,
				order = 52,
			},
			new_row_size = {
				type = 'toggle',
				name = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['New column on resize']
					else
						return L['New row on resize']
					end
				end,
				desc = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Start a new column whenever the size of the aura changes.']
					else
						return L['Start a new row whenever the size of the aura changes.']
					end
				end,
				get = get_layout,
				set = set_layout,
				order = 53,
			},
		},
	}
	return 	true, 'display', {
		type = 'group',
		name = 'Display',
		args = {
			enabled_buffs = {
				type = 'toggle',
				name = L['Buffs'],
				desc = L['Enable display of buffs.'],
				get = get,
				set = set,
				disabled = is_aura_disabled,
				order = 0,
			},
			enabled_weapons = {
				type = 'toggle',
				name = L['Weapon enchants'],
				desc = L['Enable display of temporary weapon enchants.'],
				get = function(info)
					local db = PitBull4.Options.GetLayoutDB(self)
					return db.enabled_buffs and db.enabled_weapons
				end,
				set = set,
				disabled = function(info)
					return is_aura_disabled(info) or not PitBull4.Options.GetLayoutDB(self).enabled_buffs
				end,
				order = 1,
			},
			enabled_debuffs = {
				type = 'toggle',
				name = L['Debuffs'],
				desc = L['Enable display of debuffs.'],
				get = get,
				set = set,
				disabled = is_aura_disabled,
				order = 2,
			},
			max = {
				type = 'group',
				name = L['Limit number of displayed auras.'],
				inline = true,
				order = 3,
				args = {
					max_buffs = {
						type = 'range',
						name = L['Buffs'],
						desc = L['Set the maximum number of buffs to display.'],
						get = get,
						set = set,
						disabled = is_aura_disabled,
						min = 1,
						max = 80,
						step = 1,
						order = 0,
					},
					max_debuffs = {
						type = 'range',
						name = L['Debuffs'],
						desc = L['Set the maximum number of debuffs to display.'],
						get = get,
						set = set,
						disabled = is_aura_disabled,
						min = 1,
						max = 80,
						step = 1,
						order = 1,
					},
				},
			},
			border = {
				type = 'multiselect',
				name = L['Border'],
				desc = L['Set when the border shows.'],
				values = show_when_values,
				get = get_multi,
				set = set_multi,
				disabled = is_aura_disabled,
				order = 5,
			},
			cooldown = {
				type = 'multiselect',
				name = L['Time remaining spiral'],
				desc = L['Set when the time remaining spiral shows.'],
				values = show_when_values,
				get = get_multi,
				set = set_multi,
				disabled = is_aura_disabled,
				order = 6,
			},
			cooldown_text = {
				type = 'multiselect',
				name = L['Time remaining text'],
				desc = L['Set when the time remaining text shows.'],
				values = show_when_values,
				get = get_multi,
				set = set_multi,
				disabled = is_aura_disabled,
				order = 7,
			},
			zoom_aura = {
				type = 'toggle',
				name = L['Zoom icon'],
				desc = L['Zoom in on aura icons slightly.'],
				get = get,
				set = set,
				disabled = is_aura_disabled,
				order = 8,
			},
		},
	},
	'buff', layout,
	'debuff', layout,
	'filters', {
		type = 'group',
		name = L['Filters'],
		desc = L['Select the filters to be used to limit the auras that are displayed.'],
		args = {
			buff = {
				type = 'select',
				name = L['Buff'],
				desc = L['Set the aura filter to filter the buff auras.'],
				get = get_layout_filter,
				set = set_layout_filter,
				values = get_layout_filter_values,
				disabled = is_aura_disabled,
				order = 1,
			},
			debuff = {
				type = 'select',
				name = L['Debuff'],
				desc = L['Set the aura filter to filter the debuff auras.'],
				get = get_layout_filter,
				set = set_layout_filter,
				values = get_layout_filter_values,
				disabled = is_aura_disabled,
				order = 2,
			},
		},
	}
end)
