-- ScriptEnv.lua: Utility functions for use in Lua scripts for LuaTexts.

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_LuaTexts = PitBull4:GetModule("LuaTexts")

-- luacheck: globals Enum AzeriteUtil

-- The ScriptEnv table serves as the environment that the scripts run
-- under LuaTexts run under.  The functions included in it are accessible
-- to this scripts as though they were local functions to it.  Functions
-- that they call will not have access to these functions.
local ScriptEnv = setmetatable({}, {__index = _G})
PitBull4_LuaTexts.ScriptEnv = ScriptEnv

local mouseover_check_cache = PitBull4_LuaTexts.mouseover_check_cache
local spell_cast_cache = PitBull4_LuaTexts.spell_cast_cache
local power_cache = PitBull4_LuaTexts.power_cache
local hp_cache = PitBull4_LuaTexts.hp_cache
local cast_data = PitBull4_LuaTexts.cast_data
local to_update = PitBull4_LuaTexts.to_update
local afk_cache = PitBull4_LuaTexts.afk_cache
local dnd_cache = PitBull4_LuaTexts.dnd_cache
local offline_cache = PitBull4_LuaTexts.offline_cache
local dead_cache = PitBull4_LuaTexts.dead_cache
local offline_times = PitBull4_LuaTexts.offline_times
local afk_times = PitBull4_LuaTexts.afk_times
local dnd = PitBull4_LuaTexts.dnd
local dead_times = PitBull4_LuaTexts.dead_times


-- The following functions exist to provide a method to help people moving
-- from LibDogTag.  They implement the functionality that exists in some of
-- the tags in LibDogTag.  Tags that are identical to Blizzard API calls are
-- not included and you should use the API call.  Some of them do not implement
-- all of the features of the relevent tag in LibDogTag.  People interested in
-- contributing new functions should open a ticket on the PitBull4 project as
-- a patch to the LuaTexts module.  In general tags that are simplistic work
-- on other tags should be generalized (e.g. Percent instead of PercentHP and PercentMP)
-- or should simply not exist.  A major design goal is to avoid inefficient code.
-- Functions which encourage inefficient code design will not be accepted.

-- A number of these functions are borrowed or adapted from the code implmenting
-- similar tags in DogTag.  Permission to do so granted by ckknight.

local UnitToLocale = {player = L["Player"], target = L["Target"], pet = L["%s's pet"]:format(L["Player"]), focus = L["Focus"], mouseover = L["Mouse-over"]}
setmetatable(UnitToLocale, {__index=function(self, unit)
	if unit:find("pet$") then
		local nonPet = unit:sub(1, -4)
		self[unit] = L["%s's pet"]:format(self[nonPet])
		return self[unit]
	elseif not unit:find("target$") then
		if unit:find("^party%d$") then
			local num = unit:match("^party(%d)$")
			self[unit] = L["Party member #%d"]:format(num)
			return self[unit]
		elseif unit:find("^arena%d$") then
			local num = unit:match("^arena(%d)$")
			self[unit] = L["Arena enemy #%d"]:format(num)
			return self[unit]
		elseif unit:find("^boss%d$") then
			local num = unit:match("^boss(%d)$")
			self[unit] = L["Boss #%d"]:format(num)
			return self[unit]
		elseif unit:find("^raid%d%d?$") then
			local num = unit:match("^raid(%d%d?)$")
			self[unit] = L["Raid member #%d"]:format(num)
			return self[unit]
		elseif unit:find("^partypet%d$") then
			local num = unit:match("^partypet(%d)$")
			self[unit] = UnitToLocale["party" .. num .. "pet"]
			return self[unit]
		elseif unit:find("^arenapet%d$") then
			local num = unit:match("^arenapet(%d)$")
			self[unit] = UnitToLocale["arena" .. num .. "pet"]
			return self[unit]
		elseif unit:find("^raidpet%d%d?$") then
			local num = unit:match("^raidpet(%d%d?)$")
			self[unit] = UnitToLocale["raid" .. num .. "pet"]
			return self[unit]
		end
		self[unit] = unit
		return unit
	end
	local nonTarget = unit:sub(1, -7)
	self[unit] = L["%s's target"]:format(self[nonTarget])
	return self[unit]
end})

local function VehicleName(unit)
	local name = UnitName(unit:gsub("vehicle", "pet")) or UnitName(unit) or L["Vehicle"]
	local owner_unit = unit:gsub("vehicle", "")
	if owner_unit == "" then
		owner_unit = "player"
	end
	local owner = UnitName(owner_unit)
	if owner then
		return L["%s's %s"]:format(owner, name)
	end
	return name
end
ScriptEnv.VehicleName = VehicleName

local function Name(unit, show_server)
	if unit ~= "player" and not UnitExists(unit) and not ShowBossFrameWhenUninteractable(unit) then
		return UnitToLocale[unit]
	else
		if unit:match("%d*pet%d*$") then
			local vehicle = unit:gsub("pet", "vehicle")
			if UnitIsUnit(unit, vehicle) then
				return VehicleName(vehicle)
			end
		elseif unit:match("%d*vehicle%d*$") then
			return VehicleName(unit)
		end
	end
	local name, server = UnitName(unit)
	if show_server and server and server ~= "" then
		name = FULL_PLAYER_NAME:format(name, server)
	end
	return name
end
ScriptEnv.Name = Name

local L_DAY_ONELETTER_ABBR    = DAY_ONELETTER_ABBR:gsub("%s*%%d%s*", "")
local L_HOUR_ONELETTER_ABBR   = HOUR_ONELETTER_ABBR:gsub("%s*%%d%s*", "")
local L_MINUTE_ONELETTER_ABBR = MINUTE_ONELETTER_ABBR:gsub("%s*%%d%s*", "")
local L_SECOND_ONELETTER_ABBR = SECOND_ONELETTER_ABBR:gsub("%s*%%d%s*", "")
local L_DAYS_ABBR = DAYS_ABBR:gsub("%s*%%d%s*","")
local L_HOURS_ABBR = HOURS_ABBR:gsub("%s*%%d%s*","")
local L_MINUTES_ABBR = MINUTES_ABBR:gsub("%s*%%d%s*","")
local L_SECONDS_ABBR = SECONDS_ABBR:gsub("%s*%%d%s*","")
local L_HUGE = "%s***"

local t = {}
local function FormatDuration(number, format)
	local negative = ""
	if number < 0 then
		number = -number
		negative = "-"
	end

	if not format then
		format = "c"
	else
		format = format:sub(1, 1):lower()
	end

	if format == "e" then
		if number == math.huge then
			return L_HUGE:format(negative)
		end

		t[#t+1] = negative

		number = math.floor(number + 0.5)

		local first = true

		if number >= 60*60*24 then
			local days = math.floor(number / (60*60*24))
			number = number % (60*60*24)
			t[#t+1] = ("%.0f"):format(days)
			t[#t+1] = " "
			t[#t+1] = L_DAYS_ABBR
			first = false
		end

		if number >= 60*60 then
			local hours = math.floor(number / (60*60))
			number = number % (60*60)
			if not first then
				t[#t+1] = " "
			else
				first = false
			end
			t[#t+1] = hours
			t[#t+1] = " "
			t[#t+1] = L_HOURS_ABBR
		end

		if number >= 60 then
			local minutes = math.floor(number / 60)
			number = number % 60
			if not first then
				t[#t+1] = " "
			else
				first = false
			end
			t[#t+1] = minutes
			t[#t+1] = " "
			t[#t+1] = L_MINUTES_ABBR
		end

		if number >= 1 or first then
			local seconds = number
			if not first then
				t[#t+1] = " "
			else
				first = false
			end
			t[#t+1] = seconds
			t[#t+1] = " "
			t[#t+1] = L_SECONDS_ABBR
		end
		local s = table.concat(t)
		wipe(t)
		return s
	elseif format == "f" then
		if number == math.huge then
			return L_HUGE:format(negative)
		elseif number >= 60*60*24 then
			return ("%s%.0f%s %02d%s %02d%s %02d%s"):format(negative, math.floor(number/86400), L_DAY_ONELETTER_ABBR, number/3600 % 24, L_HOUR_ONELETTER_ABBR, number/60 % 60, L_MINUTE_ONELETTER_ABBR, number % 60, L_SECOND_ONELETTER_ABBR)
		elseif number >= 60*60 then
			return ("%s%d%s %02d%s %02d%s"):format(negative, number/3600, L_HOUR_ONELETTER_ABBR, number/60 % 60, L_MINUTE_ONELETTER_ABBR, number % 60, L_SECOND_ONELETTER_ABBR)
		elseif number >= 60 then
			return ("%s%d%s %02d%s"):format(negative, number/60, L_MINUTE_ONELETTER_ABBR, number % 60, L_SECOND_ONELETTER_ABBR)
		else
			return ("%s%d%s"):format(negative, number, L_SECOND_ONELETTER_ABBR)
		end
	elseif format == "s" then
		if number == math.huge then
			return L_HUGE:format(negative)
		elseif number >= 2*60*60*24 then
			return ("%s%.1f %s"):format(negative, number/86400, L_DAYS_ABBR)
		elseif number >= 2*60*60 then
			return ("%s%.1f %s"):format(negative, number/3600, L_HOURS_ABBR)
		elseif number >= 2*60 then
			return ("%s%.1f %s"):format(negative, number/60, L_MINUTES_ABBR)
		elseif number >= 3 then
			return ("%s%.0f %s"):format(negative, number, L_SECONDS_ABBR)
		else
			return ("%s%.1f %s"):format(negative, number, L_SECONDS_ABBR)
		end
	else
		if number == math.huge then
			return ("%s**%d **:**:**"):format(negative, L_DAY_ONELETTER_ABBR)
		elseif number >= 60*60*24 then
			return ("%s%.0f%s %d:%02d:%02d"):format(negative, math.floor(number/86400), L_DAY_ONELETTER_ABBR, number/3600 % 24, number/60 % 60, number % 60)
		elseif number >= 60*60 then
			return ("%s%d:%02d:%02d"):format(negative, number/3600, number/60 % 60, number % 60)
		else
			return ("%s%d:%02d"):format(negative, number/60 % 60, number % 60)
		end
	end
end
ScriptEnv.FormatDuration = FormatDuration

-- Depends upon the local t = {} above FormatDuration
local LARGE_NUMBER_SEPERATOR, DECIMAL_SEPERATOR = LARGE_NUMBER_SEPERATOR, DECIMAL_SEPERATOR
local function SeparateDigits(number, thousands, decimal)
	local symbol
	if type(number) == "string" then
		local value
		value, symbol = number:match("^([-%d.]+)(.*)")
		if not value then
			return number
		end
		number = tonumber(value)
	end
	local int = math.abs(math.floor(number))
	local rest = tostring(number):match("^[-%d.]+%.(%d+)") -- fuck off precision errors
	if number < 0 then
		t[#t+1] = "-"
	end
	if int < 1000 then
		t[#t+1] = int
	else
		local digits = math.log10(int)
		local segments = math.floor(digits / 3)
		t[#t+1] = math.floor(int / 1000^segments)
		for i = segments-1, 0, -1 do
			t[#t+1] = thousands or LARGE_NUMBER_SEPERATOR
			t[#t+1] = ("%03d"):format(math.floor(int / 1000^i) % 1000)
		end
	end
	if rest then
		t[#t+1] = decimal or DECIMAL_SEPERATOR
		t[#t+1] = rest
	end
	if symbol then
		t[#t+1] = symbol
	end
	local s = table.concat(t)
	wipe(t)
	return s
end
ScriptEnv.SeparateDigits = SeparateDigits

local function Angle(value)
	if not value or value == "" then
		return "", "", ""
	end
	return "<", value, ">"
end
ScriptEnv.Angle = Angle

local function Paren(value)
	if not value or value == "" then
		return "", "", ""
	end
	return "(", value, ")"
end
ScriptEnv.Paren = Paren

local function UpdateIn(seconds)
	local font_string = ScriptEnv.font_string
	local current_timer = to_update[font_string]
	if not current_timer or current_timer > seconds then
		to_update[font_string] = seconds
	end
end
ScriptEnv.UpdateIn = UpdateIn

local function IsAFK(unit)
	afk_cache[ScriptEnv.font_string] = true
	return not not afk_times[UnitGUID(unit)]
end
ScriptEnv.IsAFK = IsAFK

local function AFKDuration(unit)
	local afk = afk_times[UnitGUID(unit)]
	afk_cache[ScriptEnv.font_string] = true
	if afk then
		UpdateIn(0.25)
		return GetTime() - afk
	end
end
ScriptEnv.AFKDuration = AFKDuration

local function AFK(unit)
	local afk = AFKDuration(unit)
	if afk then
		return ("%s (%s)"):format(_G.AFK, FormatDuration(afk))
	end
end
ScriptEnv.AFK = AFK

local function IsDND(unit)
	dnd_cache[ScriptEnv.font_string] = true
	return not not dnd[UnitGUID(unit)]
end
ScriptEnv.IsDND = IsDND

local function DND(unit)
	dnd_cache[ScriptEnv.font_string] = true
	if dnd[UnitGUID(unit)] then
		return _G.DND
	end
end
ScriptEnv.DND = DND

local HOSTILE_REACTION = 2
local NEUTRAL_REACTION = 4
local FRIENDLY_REACTION = 5

local function HostileColor(unit)
	local r, g, b
	if not unit then
		r, g, b = unpack(PitBull4.ReactionColors.unknown)
	else
		if UnitIsPlayer(unit) or UnitPlayerControlled(unit) then
			if UnitCanAttack(unit, "player") then
				-- they can attack me
				if UnitCanAttack("player", unit) then
					-- and I can attack them
					r, g, b = unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
				else
					-- but I can't attack them
					r, g, b = unpack(PitBull4.ReactionColors.civilian)
				end
			elseif UnitCanAttack("player", unit) then
				-- they can't attack me, but I can attack them
				r, g, b = unpack(PitBull4.ReactionColors[NEUTRAL_REACTION])
			elseif UnitIsPVP(unit) then
				-- on my team
				r, g, b = unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
			else
				-- either enemy or friend, no violance
				r, g, b = unpack(PitBull4.ReactionColors.civilian)
			end
		elseif UnitIsTapDenied(unit) or UnitIsDead(unit) then
			r, g, b = unpack(PitBull4.ReactionColors.tapped)
		else
			local reaction = UnitReaction(unit, "player")
			if reaction then
				if reaction >= 5 then
					r, g, b = unpack(PitBull4.ReactionColors[FRIENDLY_REACTION])
				elseif reaction == 4 then
					r, g, b = unpack(PitBull4.ReactionColors[NEUTRAL_REACTION])
				else
					r, g, b = unpack(PitBull4.ReactionColors[HOSTILE_REACTION])
				end
			else
				r, g, b = unpack(PitBull4.ReactionColors.unknown)
			end
		end
	end
	return r * 255, g * 255, b * 255
end
ScriptEnv.HostileColor = HostileColor

local function ClassColor(unit)
	local class = UnitClassBase(unit)
	local color = PitBull4.ClassColors[class] or PitBull4.ClassColors.UNKNOWN
	return color[1] * 255, color[2] * 255, color[3] * 255
end
ScriptEnv.ClassColor = ClassColor

local function Level(unit)
	if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
		return UnitBattlePetLevel(unit)
	end
	local level = UnitLevel(unit)
	if level <= 0 then
		level = "??"
	end
	return level
end
ScriptEnv.Level = Level

local function DifficultyColor(unit)
	local level = Level(unit)
	if level == "??" then
		level = 99
	end
	local color = GetQuestDifficultyColor(level)
	return color.r * 255, color.g * 255, color.b * 255
end
ScriptEnv.DifficultyColor = DifficultyColor

local function AggroColor(unit)
	local r, g, b = UnitSelectionColor(unit)
	return r * 255, g * 255, b * 255
end
ScriptEnv.AggroColor = AggroColor

local classification_lookup = {
	rare = L["Rare"],
	rareelite = L["Rare-Elite"],
	elite = L["Elite"],
	worldboss = L["Boss"],
	minus = L["Minus"],
	trivial = L["Trivial"],
}

local function Classification(unit)
	return classification_lookup[PitBull4.Utils.BetterUnitClassification(unit)]
end
ScriptEnv.Classification = Classification

local ShortClassification_abbrev = {
	[L["Rare"]] = L["Rare_short"],
	[L["Rare-Elite"]] = L["Rare-Elite_short"],
	[L["Elite"]] = L["Elite_short"],
	[L["Boss"]] = L["Boss_short"],
	[L["Minus"]] = L["Minus_short"],
	[L["Trivial"]] = L["Trivial_short"],
}

local function ShortClassification(arg)
	local short = ShortClassification_abbrev[arg]
	if not short and PitBull4.Utils.GetBestUnitID(arg) then
		-- If it's empty then maybe arg is a unit
		short = ShortClassification_abbrev[Classification(arg)]
	end
	return short
end
ScriptEnv.ShortClassification = ShortClassification

local function Class(unit)
	if UnitIsPlayer(unit) then
		return UnitClass(unit) or UNKNOWN
	else
		local _, classId = UnitClassBase(unit)
		local classInfo = classId and C_CreatureInfo.GetClassInfo(classId)
		return classInfo and classInfo.className or UNKNOWN
	end
end
ScriptEnv.Class = Class

local ShortClass_abbrev = {
	DEATHKNIGHT = L["Death Knight_short"],
	DEMONHUNTER = L["Demon Hunter_short"],
	DRUID = L["Druid_short"],
	EVOKER = L["Evoker_short"],
	HUNTER = L["Hunter_short"],
	MAGE = L["Mage_short"],
	MONK = L["Monk_short"],
	PALADIN = L["Paladin_short"],
	PRIEST = L["Priest_short"],
	ROGUE = L["Rogue_short"],
	SHAMAN = L["Shaman_short"],
	WARLOCK = L["Warlock_short"],
	WARRIOR = L["Warrior_short"],
}

local function ShortClass(arg)
	local short = ShortClass_abbrev[arg]
	if not short and PitBull4.Utils.GetBestUnitID(arg) then
		-- If it's empty then maybe arg is a unit
		if UnitIsPlayer(arg) then
			local class = UnitClassBase(arg)
			short = ShortClass_abbrev[class]
		else
			local _, classId = UnitClassBase(arg)
			local classInfo = classId and C_CreatureInfo.GetClassInfo(classId)
			if classInfo then
				short = ShortClass_abbrev[classInfo.classFile]
			end
		end
	end
	return short
end
ScriptEnv.ShortClass = ShortClass

local function Creature(unit)
	if UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit) then
		return _G["BATTLE_PET_NAME_"..UnitBattlePetType(unit)].." "..TOOLTIP_BATTLE_PET
	end
	return UnitCreatureFamily(unit) or UnitCreatureType(unit) or UNKNOWN
end
ScriptEnv.Creature = Creature

local function SmartRace(unit)
	if UnitIsPlayer(unit) then
		local race = UnitRace(unit)
		return race or UNKNOWN
	end
	return Creature(unit)
end
ScriptEnv.SmartRace = SmartRace

local ShortRace_abbrev = {
	BloodElf = L["Blood Elf_short"],
	Draenei = L["Draenei_short"],
	Dwarf = L["Dwarf_short"],
	Gnome = L["Gnome_short"],
	Goblin = L["Goblin_short"],
	Human = L["Human_short"],
	NightElf = L["Night Elf_short"],
	Orc = L["Orc_short"],
	Pandaren = L["Pandaren_short"],
	Tauren = L["Tauren_short"],
	Troll = L["Troll_short"],
	Undead = L["Undead_short"],
	Worgen = L["Worgen_short"],
	DarkIronDwarf = L["Dark Iron Dwarf_short"],
	HighmountainTauren = L["Highmountain Tauren_short"],
	KulTiranHuman = L["Kul Tiran Human_short"],
	LightforgedDraenei = L["Lightforged Draenei_short"],
	MagharOrc = L["Mag'har Orc_short"],
	Nightborne = L["Nightborne_short"],
	VoidElf = L["Void Elf_short"],
	ZandalariTroll = L["Zandalari Troll_short"],
	Vulpera = L["Vulpera_short"],
	Mechagnome = L["Mechagnome_short"],
	Dracthyr = L["Dracthyr_short"],
}

local function ShortRace(arg)
	local short = ShortRace_abbrev[arg]
	if not short and PitBull4.Utils.GetBestUnitID(arg) then
		-- If it's empty then maybe arg is a unit
		local _, race = UnitRace(arg)
		short = ShortRace_abbrev[race]
	end
	return short
end
ScriptEnv.ShortRace = ShortRace

local function IsPet(unit)
	return not UnitIsPlayer(unit) and (UnitPlayerControlled(unit) or UnitPlayerOrPetInRaid(unit))
end
ScriptEnv.IsPet = IsPet

local function OfflineDuration(unit)
	local offline = offline_times[UnitGUID(unit)]
	offline_cache[ScriptEnv.font_string] = true
	if offline then
		UpdateIn(0.25)
		return GetTime() - offline
	end
end
ScriptEnv.OfflineDuration = OfflineDuration

local function Offline(unit)
	local offline = OfflineDuration(unit)
	if offline then
		return ("%s (%s)"):format(_G.PLAYER_OFFLINE, FormatDuration(offline))
	end
end
ScriptEnv.Offline = Offline

local function IsOffline(unit)
	offline_cache[ScriptEnv.font_string] = true
	return not not offline_times[UnitGUID(unit)]
end
ScriptEnv.IsOffline = IsOffline

local function DeadDuration(unit)
	local dead_time = dead_times[UnitGUID(unit)]
	dead_cache[ScriptEnv.font_string] = true
	if dead_time then
		UpdateIn(0.25)
		return GetTime() - dead_time
	end
end
ScriptEnv.DeadDuration = DeadDuration

local function Dead(unit)
	local dead_time = DeadDuration(unit)
	local dead_type = (UnitIsGhost(unit) and L["Ghost"]) or (UnitIsDead(unit) and L["Dead"])
	if dead_time and dead_type then
		return ("%s (%s)"):format(dead_type, FormatDuration(dead_time))
	elseif dead_type then
		return dead_type
	end
end
ScriptEnv.Dead = Dead

local MOONKIN_FORM = GetSpellInfo(24858)
local TRAVEL_FORM = GetSpellInfo(783)
local TREE_OF_LIFE = GetSpellInfo(33891)

local function DruidForm(unit)
	local class = UnitClassBase(unit)
	if class == "DRUID" then
		local power = UnitPowerType(unit)
		if power == 1 then
			return L["Bear"]
		elseif power == 3 then
			return L["Cat"]
		else
			local i = 1
			repeat
				local name = UnitAura(unit, i, "HELPFUL")
				if name then
					if name == MOONKIN_FORM then
						return L["Moonkin"]
					elseif name == TRAVEL_FORM then
						return L["Travel"]
					elseif name == TREE_OF_LIFE then
						return L["Tree"]
					end
				end
				i = i + 1
			until not name
		end
	end
end
ScriptEnv.DruidForm = DruidForm

local function Status(unit)
	return Offline(unit) or (UnitIsFeignDeath(unit) and L["Feigned Death"]) or Dead(unit)
end
ScriptEnv.Status = Status

local function HP(unit, no_fast)
	local hp = UnitHealth(unit)
	if not no_fast then
		hp_cache[ScriptEnv.font_string] = true
	end
	if hp == 1 and UnitIsGhost(unit) then
		return 0
	end
	return hp
end
ScriptEnv.HP = HP

-- Just use the Blizzard API no change needed
-- only reason this is here is for symmetry,
-- it feels weird to have HP (which we need
-- to avoid the hp = 1 while dead crap), but
-- not have MaxHP
local MaxHP = UnitHealthMax
ScriptEnv.MaxHP = MaxHP

local function Power(unit, power_type)
	local power = UnitPower(unit, power_type)

	-- Detect mana texts for player and pet units, cache the power
	-- and mark the font_strings for faster updating.  Allows
	-- smoothing updating of PowerBars.
	local guid = UnitGUID(unit)
	if power_type == nil or UnitPowerType(unit) == power_type then
		if guid == ScriptEnv.player_guid then
			ScriptEnv.player_power = power
		  power_cache[ScriptEnv.font_string] = true
		elseif guid == UnitGUID("pet") then
			ScriptEnv.pet_power = power
			power_cache[ScriptEnv.font_string] = true
		end
	end

	return power
end
ScriptEnv.Power = Power

-- More symmetry
local MaxPower = UnitPowerMax
ScriptEnv.MaxPower = MaxPower

local function Round(number, digits)
	local mantissa = 10^(digits or 0)
	local norm = number * mantissa + 0.5
	local norm_floor = math.floor(norm)
	if norm == norm_floor and (norm_floor % 2) == 1 then
		return (norm_floor - 1) / mantissa
	end
	return norm_floor / mantissa
end
ScriptEnv.Round = Round

local Short, Shorter, VeryShort
local locale = GetLocale()
if locale == "zhCN" or locale == "zhTW" or locale == "koKR" then
	local FIRST_NUMBER_CAP_NO_SPACE = FIRST_NUMBER_CAP_NO_SPACE
	local SECOND_NUMBER_CAP_NO_SPACE = SECOND_NUMBER_CAP_NO_SPACE

	function Short(value, format)
		if type(value) == "number" then
			local v = math.abs(value)
			local fmt
			if v >= 100000000000 then
				fmt = "%.0f" .. SECOND_NUMBER_CAP_NO_SPACE
				value = value / 100000000
			elseif v >= 10000000000 then
				fmt = "%.1f" .. SECOND_NUMBER_CAP_NO_SPACE
				value = value / 100000000
			elseif v >= 100000000 then
				fmt = "%.2f" .. SECOND_NUMBER_CAP_NO_SPACE
				value = value / 100000000
			elseif v >= 10000000 then
				fmt = "%.0f" .. FIRST_NUMBER_CAP_NO_SPACE
				value = value / 10000
			elseif v >= 1000000 then
				fmt = "%.1f" .. FIRST_NUMBER_CAP_NO_SPACE
				value = value / 10000
			elseif v >= 10000 then
				fmt = "%.2f" .. FIRST_NUMBER_CAP_NO_SPACE
				value = value / 10000
			else
				fmt = "%.0f"
			end
			if format then
				return fmt:format(value)
			end
			return fmt, value
		end
		local a, b = value:match("^(%d+)/(%d+)")
		if a then
			local fmt_a, fmt_b
			fmt_b, b = Short(tonumber(b))
			fmt_a, a = Short(tonumber(a))
			local fmt = ("%s/%s"):format(fmt_a, fmt_b)
			if format then
				return fmt:format(a, b)
			end
			return fmt, a, b
		end
		return value
	end

	function Shorter(value, format)
		if type(value) == "number" then
			local v = math.abs(value)
			if v < 10000 and v >= 1000 then
				local fmt = "%.1f" .. FIRST_NUMBER_CAP_NO_SPACE
				if format then
					return fmt:format(value)
				end
				return fmt, value
			end
		else
			local a, b = value:match("^(%d+)/(%d+)")
			if a then
				local fmt_a, fmt_b
				fmt_b, b = Shorter(tonumber(b))
				fmt_a, a = Shorter(tonumber(a))
				local fmt = ("%s/%s"):format(fmt_a, fmt_b)
				if format then
					return fmt:format(a, b)
				end
				return fmt, a, b
			end
		end
		return Short(value, format)
	end

	function VeryShort(value, format)
		if type(value) == "number" then
			local v = abs(value)
			local fmt
			if v >= 100000000 then
				fmt = "%.0f" .. SECOND_NUMBER_CAP_NO_SPACE
				value = value / 100000000
			elseif v >= 10000 then
				fmt = "%.0f" .. FIRST_NUMBER_CAP_NO_SPACE
				value = value / 10000
			else
				fmt = "%.0f"
			end
			if format then
				return fmt:format(value)
			end
			return fmt, value
		end
		local a, b = value:match("^(%d+)/(%d+)")
		if a then
			local fmt_a, fmt_b
			fmt_b, b = VeryShort(tonumber(b))
			fmt_a, a = VeryShort(tonumber(a))
			local fmt = ("%s/%s"):format(fmt_a, fmt_b)
			if format then
				return fmt:format(a, b)
			end
			return fmt, a, b
		end
		return value
	end
else
	local BILLION_NUMBER = 10^9
	-- Use the correct symbol for long scale number locales
	if locale == "frFR" or locale == "esMX" or locale == "esES" then
		BILLION_NUMBER = 10^12
	end

	function Short(value, format)
		if type(value) == "number" then
			local v = abs(value)
			local fmt
			if v >= BILLION_NUMBER then
				fmt = "%.1fb"
				value = value / BILLION_NUMBER
			elseif v >= 1000000000 then
				fmt = "%.0fm"
				value = value / 1000000
			elseif v >= 10000000 then
				fmt = "%.1fm"
				value = value / 1000000
			elseif v >= 1000000 then
				fmt = "%.2fm"
				value = value / 1000000
			elseif v >= 100000 then
				fmt = "%.0fk"
				value = value / 1000
			elseif v >= 10000 then
				fmt = "%.1fk"
				value = value / 1000
			else
				fmt = "%.0f"
			end
			if format then
				return fmt:format(value)
			end
			return fmt, value
		end
		local a, b = value:match("^(%d+)/(%d+)")
		if a then
			local fmt_a, fmt_b
			fmt_b, b = Short(tonumber(b))
			fmt_a, a = Short(tonumber(a))
			local fmt = ("%s/%s"):format(fmt_a, fmt_b)
			if format then
				return fmt:format(a, b)
			end
			return fmt, a, b
		end
		return value
	end

	function Shorter(value, format)
		if type(value) == "number" then
			local v = math.abs(value)
			if v < 10000 and v >= 1000 then
				local fmt = "%.1fk"
				if format then
					return fmt:format(value)
				end
				return fmt, value
			end
		else
			local a, b = value:match("^(%d+)/(%d+)")
			if a then
				local fmt_a, fmt_b
				fmt_b, b = Shorter(tonumber(b))
				fmt_a, a = Shorter(tonumber(a))
				local fmt = ("%s/%s"):format(fmt_a, fmt_b)
				if format then
					return fmt:format(a, b)
				end
				return fmt, a, b
			end
		end
		return Short(value, format)
	end

	function VeryShort(value, format)
		if type(value) == "number" then
			local v = abs(value)
			local fmt
			if v >= BILLION_NUMBER then
				fmt = "%.0fb"
				value = value / BILLION_NUMBER
			elseif v >= 1000000 then
				fmt = "%.0fm"
				value = value / 1000000
			elseif v >= 1000 then
				fmt = "%.0fk"
				value = value / 1000
			else
				fmt = "%.0f"
			end
			if format then
				return fmt:format(value)
			end
			return fmt, value
		end
		local a, b = value:match("^(%d+)/(%d+)")
		if a then
			local fmt_a, fmt_b
			fmt_b, b = VeryShort(tonumber(b))
			fmt_a, a = VeryShort(tonumber(a))
			local fmt = ("%s/%s"):format(fmt_a, fmt_b)
			if format then
				return fmt:format(a, b)
			end
			return fmt, a, b
		end
		return value
	end
end
ScriptEnv.Short = Short
ScriptEnv.Shorter = Shorter
ScriptEnv.VeryShort = VeryShort

local function IsMouseOver()
	local font_string = ScriptEnv.font_string
	local frame = font_string.frame
	mouseover_check_cache[font_string] = frame
	return PitBull4_LuaTexts.mouseover == frame
end
ScriptEnv.IsMouseOver = IsMouseOver

local function Combos()
	if UnitHasVehicleUI("player") then
		return GetComboPoints("vehicle")
	end
	return UnitPower("player", Enum.PowerType.ComboPoints)
end
ScriptEnv.Combos = Combos

local function ComboSymbols(symbol)
	return string.rep(symbol or "@", Combos())
end
ScriptEnv.ComboSymbols = ComboSymbols

local function Percent(x, y)
	if y ~= 0 then
		return Round(x / y * 100, 1)
	end
	return 0
end
ScriptEnv.Percent = Percent

local function XP(unit)
	if unit == "player" then
		return UnitXP(unit)
	elseif unit == "pet" or unit == "playerpet" then
		return GetPetExperience()
	end
	return 0
end
ScriptEnv.XP = XP

local function MaxXP(unit)
	if unit == "player" then
		return UnitXPMax(unit)
	elseif unit == "pet" or unit == "playerpet" then
		local _, max = GetPetExperience()
		return max
	end
	return 0
end
ScriptEnv.MaxXP = MaxXP

local function RestXP(unit)
	if unit == "player" then
		return GetXPExhaustion() or 0
	end
	return 0
end
ScriptEnv.RestXP = RestXP

-- Pre-Dragonflight API wrapper for old texts
local function GetFriendshipReputation(id)
	local info = C_GossipInfo.GetFriendshipReputation(id)
	if info.friendshipFactionID > 0 then
		return info.friendshipFactionID, info.standing, info.maxRep, info.name, info.text, info.texture, info.reaction, info.reactionThreshold, info.nextThreshold
	end
end
ScriptEnv.GetFriendshipReputation = GetFriendshipReputation

local function WatchedFactionInfo()
	local name, reaction, min, max, value, faction_id = GetWatchedFactionInfo()
	if not name then
		return nil
	end

	local rep_info = C_GossipInfo.GetFriendshipReputation(faction_id)
	local friendship_id = rep_info.friendshipFactionID

	if C_Reputation.IsFactionParagon(faction_id) then
		local paragon_value, threshold, _, has_reward = C_Reputation.GetFactionParagonInfo(faction_id)
		min, max = 0, threshold
		value = paragon_value % threshold
		if has_reward then
			value = value + threshold
		end
	elseif C_Reputation.IsMajorFaction(faction_id) then
		local faction_info = C_MajorFactions.GetMajorFactionData(faction_id)
		min, max = 0, faction_info.renownLevelThreshold
	elseif friendship_id > 0 then
		if rep_info.nextThreshold then
			min, max, value = rep_info.reactionThreshold, rep_info.nextThreshold, rep_info.standing
		else -- max, show full amount?
			min, max, value = 0, rep_info.standing, rep_info.standing
		end
	end

	-- Normalize values
	max = max - min
	value = value - min
	min = 0
	return name, reaction, min, max, value, faction_id
end
ScriptEnv.WatchedFactionInfo = WatchedFactionInfo

local function ArtifactPower()
	local azeriteItemLocation = C_AzeriteItem.FindActiveAzeriteItem()
	if azeriteItemLocation then
		-- api can error if the active item is in your bank
		if azeriteItemLocation.bagID and (azeriteItemLocation.bagID < 0 or azeriteItemLocation.bagID > NUM_BAG_SLOTS) then
			return 0, 1, 0, -1
		end
		local artifactXP, totalLevelXP = C_AzeriteItem.GetAzeriteItemXPInfo(azeriteItemLocation)
		local numPoints = AzeriteUtil.GetEquippedItemsUnselectedPowersCount()
		local level = C_AzeriteItem.GetPowerLevel(azeriteItemLocation)
		return artifactXP, totalLevelXP, numPoints, level
	end
	return 0, 0, 0, 0
end
ScriptEnv.ArtifactPower = ArtifactPower

local function ThreatPair(unit)
	if UnitIsFriend("player", unit) then
		if UnitExists("target") then
			return unit, "target"
		end
	else
		return "player", unit
	end
end
ScriptEnv.ThreatPair = ThreatPair

local function ThreatStatusColor(status)
	local r, g, b = GetThreatStatusColor(status)
	return r * 255, g * 255, b * 255
end
ScriptEnv.ThreatStatusColor = ThreatStatusColor

local function CastData(unit)
	spell_cast_cache[ScriptEnv.font_string] = true
	return cast_data[UnitGUID(unit)]
end
ScriptEnv.CastData = CastData

local function Alpha(number)
	if number > 1 then
		number = 1
	elseif number < 0 then
		number = 0
	end
	PitBull4_LuaTexts.alpha = number
end
ScriptEnv.Alpha = Alpha

local function Outline()
	PitBull4_LuaTexts.outline = "OUTLINE"
end
ScriptEnv.Outline = Outline

local function ThickOutline()
	PitBull4_LuaTexts.outline = "OUTLINE, THICKOUTLINE"
end
ScriptEnv.ThickOutline = ThickOutline

local function WordWrap()
	PitBull4_LuaTexts.word_wrap = true
end
ScriptEnv.WordWrap = WordWrap

local function abbreviate(text)
	local b = text:byte(1)
	if b <= 127 then
		return text:sub(1, 1)
	elseif b <= 223 then
		return text:sub(1, 2)
	elseif b <= 239 then
		return text:sub(1, 3)
	else
		return text:sub(1, 4)
	end
end
local function Abbreviate(value)
	if value:find(" ") then
		return value:gsub(" *([^ ]+) *", abbreviate)
	end
	return value
end
ScriptEnv.Abbreviate = Abbreviate

local function PVPDuration(unit)
	if unit and not UnitIsUnit(unit,"player") then return end
  if IsPVPTimerRunning() then
		UpdateIn(0.25)
		return GetPVPTimer() / 1000
	end
end
ScriptEnv.PVPDuration = PVPDuration

local function HPColor(cur, max)
	local perc = 0
	if max ~= 0 then
		perc = cur / max
	end
	local r1, g1, b1
	local r2, g2, b2
	if perc <= 0.5 then
		perc = perc * 2
		r1, g1, b1 = 1, 0, 0  -- TODO: Let these be configurable?
		r2, g2, b2 = 1, 1, 0
	else
		perc = perc * 2 - 1
		r1, g1, b1 = 1, 1, 0
		r2, g2, b2 = 0, 1, 0
	end
	local r, g, b = r1 + (r2 - r1)*perc, g1 + (g2 - g1)*perc, b1 + (b2 - b1)*perc
	if r < 0 then
		r = 0
	elseif r > 1 then
		r = 1
	end
	if g < 0 then
		g = 0
	elseif g > 1 then
		g = 1
	end
	if b < 0 then
		b = 0
	elseif b > 1 then
		b = 1
	end
	return r * 255, g * 255, b * 255
end
ScriptEnv.HPColor = HPColor

local power_type_to_string = {
	[Enum.PowerType.Mana] = "MANA",
	[Enum.PowerType.Rage] = "RAGE",
	[Enum.PowerType.Focus] = "FOCUS",
	[Enum.PowerType.Energy] = "ENERGY",
	[Enum.PowerType.ComboPoints] = "COMBO_POINTS",
	[Enum.PowerType.Runes] = "RUNES",
	[Enum.PowerType.RunicPower] = "RUNIC_POWER",
	[Enum.PowerType.SoulShards] = "SOUL_SHARDS",
	[Enum.PowerType.LunarPower] = "LUNAR_POWER",
	[Enum.PowerType.HolyPower] = "HOLY_POWER",
	[Enum.PowerType.Maelstrom] = "MAELSTROM",
	[Enum.PowerType.Chi] = "CHI",
	[Enum.PowerType.Insanity] = "INSANITY",
	[Enum.PowerType.ArcaneCharges] = "ARCANE_CHARGES",
	[Enum.PowerType.Fury] = "FURY",
	[Enum.PowerType.Pain] = "PAIN",
}
local function PowerColor(power_type)
	if type(power_type) == "number" then
		power_type = power_type_to_string[power_type]
	end
	local color = PitBull4.PowerColors[power_type]
	if not color then
		return 178.5, 178.5, 178.5
	end
	return color[1] * 255, color[2] * 255, color[3] * 255
end
ScriptEnv.PowerColor = PowerColor

local function ReputationColor(reaction)
  local color = PitBull4.ReactionColors[reaction]
	if color then
		return color[1] * 255, color[2] * 255, color[3] * 255
	end
end
ScriptEnv.ReputationColor = ReputationColor

local function ConfigMode()
	local font_string = ScriptEnv.font_string
	local frame = font_string.frame
	if frame.force_show then
		return ("{%s}"):format(font_string.luatexts_name)
	end
end
ScriptEnv.ConfigMode = ConfigMode
