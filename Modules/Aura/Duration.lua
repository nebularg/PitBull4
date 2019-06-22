local PitBull4 = _G.PitBull4
local PitBull4_Aura = PitBull4:GetModule("Aura")
local PitBull4_AuraDuration = PitBull4_Aura:NewModule("AuraDuration", "AceEvent-3.0")

local bit_band = bit.band

local spells = PitBull4.Spells.spell_durations
local dr_spells = PitBull4.Spells.dr_spells

local player_guid = UnitGUID("player")
local _, player_class = UnitClass("player")

local new, del do
	local pool = {}

	local auto_table__mt = {
		__index = function(t, k)
			t[k] = new()
			return t[k]
		end,
	}

	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
		else
			t = setmetatable({}, auto_table__mt)
		end
		return t
	end

	function del(t)
		for k,v in next, t do
			if type(v) == "table" then
				del(v)
			end
			t[k] = nil
		end
		pool[t] = true
		return nil
	end
end

local function get(t, ...)
	for i=1, select("#", ...) do
		local key = select(i, ...)
		t = rawget(t, key)
		if t == nil then
			return nil
		end
	end
	return t
end

local auras = new()
PitBull4_AuraDuration.auras = auras

local diminished_returns = new()
PitBull4_AuraDuration.diminished_returns = diminished_returns

-- DR is 15 seconds, but the server only checks every 5 seconds, so it can reset any time between 15 and 20 seconds.
local DR_RESET_TIME = 18

-- Categories that have DR in PvE
local dr_pve_categories = {
	stun = true,
	-- blind = true,
	cheapshot = true,
	-- kidneyshot - true,
}

-- This uses the logic provided by Shadowed in DRData-1.0 (it's his fault if it doesn't work right!)
-- DR is applied when the debuff fades
local function add_dr(dst_guid, spell_id, is_player)
	local cat = dr_spells[spell_id]
	if not cat then return end
	if not is_player and not dr_pve_categories[cat] then return end

	local entry = diminished_returns[dst_guid][cat]
	entry[1] = GetTime() + DR_RESET_TIME
	local diminished = get(entry, 2) or 1
	if diminished == 1 then
		entry[2] = 0.5
	elseif diminished == 0.5 then
		entry[2] = 0.25
	else
		entry[2] = 0
	end
end

-- DR reset time is checked when the debuff is gained
local function get_dr(dst_guid, spell_id, is_player)
	local cat = dr_spells[spell_id]
	if cat and (is_player or dr_pve_categories[cat]) then
		local entry = diminished_returns[dst_guid][cat]
		if get(entry, 1) and entry[1] <= GetTime() then
			wipe(entry)
		end
		return get(entry, 2) or 1
	end
	return 1
end

local talent_mods = {
	DRUID = {
		{ -- Brutal Impact (Feral)
			talents = {16940, 16941},
			spells = {
				5211, 6798, 8983, -- Bash
				9005, 9823, 9827, -- Pounce
			},
			mod = 0.5,
		},
	},
	HUNTER = {
		{ -- Clever Traps (Survival)
			talents = {19239, 19245},
			spells = {
				3355, 14308, 14309, -- Freezing Trap
				13810, -- Frost Trap
			},
			mod = 0.15,
			percent = true,
		},
	},
	MAGE = {
		{ -- Permafrost (Frost)
			talents = {11175, 12569, 12571},
			spells = {
				6136, -- Chilled (Frost Armor)
				12484, 12485, 12486, -- Chilled (Improved Blizzard)
				120, 8492, 10159, 10160, 10161, -- Cone of Cold
				116, 205, 837, 7322, 8406, 8407, 8408, 10179, 10180, 10181, 25304, -- Frostbolt
			},
			mod = 1,
		},
	},
	PALADIN = {
		{ -- Lasting Judgement (Holy)
			talents = {20359, 20360, 20361},
			spells = {
				20185, 20344, 20345, 20346, -- Judgement of Light
				20186, 20354, 20355, -- Judgement of Wisdom
			},
			mod = 10,
		},
		{ -- Guardian's Favor (Protection)
			talents = {20174, 20175},
			spells = {1044}, -- Blessing of Freedom
			mod = 3,
		},
	},
	PRIEST = {
		{ -- Improved Shadow Word: Pain (Shadow)
			talents = {15275, 15317},
			spells = {589, 594, 970, 992, 2767, 10892, 10893, 10894}, -- Shadow Word: Pain
			mod = 3,
		},
	},
	ROGUE = {
		{ -- Improved Gouge (Combat)
			talents = {13741, 13793, 13792},
			spells = {1776, 1777, 8629, 11285, 11286}, -- Gouge
			mod = 0.5,
		},
	},
	WARLOCK = {
		{ -- Improved Succubus (Demonology)
			talents = {18754, 18755, 18756},
			spells = {
				6358, -- Seduction
				-- 7870, -- Lesser Invisibility
				-- 6360, 7813, 11784, 11785, -- Soothing Kiss
			},
			mod = 0.1,
			percent = true,
		},
	},
	WARRIOR = {
		{ -- Booming Voice (Fury)
			talents = {12321, 12835, 12836, 12837, 12838},
			spells = {
				5242, 6192, 6673, 11549, 11550, 11551, 25289, -- Battle Shout
				1160, 6190, 11554, 11555, 11556, -- Demoralizing Shout
			},
			mod = 0.1,
			percent = true,
		},
		{ -- Improved Disarm (Protection)
			talents = {12313, 12804, 12807},
			spells = {676}, -- Disarm
			mod = 1,
		},
	},
}
talent_mods = talent_mods[player_class]

local combo_point_spells = {
	-- Kidney Shot
	[408] = true, [8643] = true,
	-- Rupture
	[1943] = true, [8639] = true, [8640] = true, [11273] = true, [11274] = true, [11275] = true,
}

local duration_mods = {}

local function get_mod(src_guid, spell_id)
	if src_guid ~= player_guid then
		return 0
	end
	if combo_point_spells[spell_id] then
		-- these are the full duration so we need to subtract the default 5cp duration
		local duration = spells[spell_id]
		local combo_points = UnitPower("player", 14)
		if spell_id == 408 then
			-- Kidney Shot (Rank 1)
			return -duration + combo_points
		elseif spell_id == 8643 then
			-- Kidney Shot (Rank 2)
			return -duration + 1 + combo_points
		else
			-- Rupture
			return -duration + 6 + combo_points * 2
		end
	end
	return duration_mods[spell_id] or 0
end

local is_player = bit.bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_PLAYER)
local is_group = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)

local event_list = {
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_APPLIED_DOSE = true,
	SPELL_AURA_REFRESH = true,
	SPELL_AURA_REMOVED = true,
}

local function combat_log_handler()
	local _, event, _, src_guid, _, src_flags, _, dst_guid, _, dst_flags, _, spell_id = CombatLogGetCurrentEventInfo()

	if dst_guid == player_guid then
		return
	end

	if event == "UNIT_DIED" then
		if get(auras, dst_guid) then
			auras[dst_guid] = del(auras[dst_guid])
		end
		if get(diminished_returns, dst_guid) then
			diminished_returns[dst_guid] = del(diminished_returns[dst_guid])
		end
		return
	end

	if event_list[event] and spells[spell_id] then -- and bit_band(src_flags, is_group) > 0
		if event == "SPELL_AURA_REMOVED" or event == "SPELL_AURA_REFRESH" then
			add_dr(dst_guid, spell_id, bit_band(dst_flags, is_player) > 0)
		end

		if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED_DOSE" then
			local duration = (spells[spell_id] + get_mod(src_guid, spell_id)) * get_dr(dst_guid, spell_id)
			local expiration = GetTime() + duration
			local entry = auras[dst_guid][spell_id][src_guid]
			entry[1] = duration
			entry[2] = expiration
		elseif event == "SPELL_AURA_REMOVED" then
			auras[dst_guid][spell_id][src_guid] = del(auras[dst_guid][spell_id][src_guid])
		end
	end
end

function PitBull4_AuraDuration:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("CHARACTER_POINTS_CHANGED")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", combat_log_handler)

	self:CHARACTER_POINTS_CHANGED()
end

function PitBull4_AuraDuration:OnDisable()
	self:PLAYER_ENTERING_WORLD()
end

function PitBull4_AuraDuration:CHARACTER_POINTS_CHANGED(_, change)
	if not talent_mods then return end

	for _, info in next, talent_mods do
		local rank = 0
		for i = 1, #info.talents do
			if not IsPlayerSpell(info.talents[i]) then
				break
			end
			rank = i
		end
		for i = 1, #info.spells do
			local spell_id = info.spells[i]
			local mod = rank * info.mod
			if mod > 0 then
				if info.percent then
					mod = spells[spell_id] * mod
				end
				duration_mods[spell_id] = mod
			else
				duration_mods[spell_id] = nil
			end
		end
	end
end

function PitBull4_AuraDuration:PLAYER_ENTERING_WORLD()
	-- tidy up
	local purge = not IsInGroup()
	for guid in next, auras do
		if purge or guid:sub(1, 6) ~= "Player" then
			auras[guid] = del(auras[guid])
		end
	end
	for guid in next, diminished_returns do
		diminished_returns[guid] = del(diminished_returns[guid])
	end
end


local tmp = {}
function PitBull4_Aura:GetDuration(src_guid, dst_guid, spell_id, aura_list, aura_index)
	if spells[spell_id] then
		if src_guid then
			local entry = get(auras, dst_guid, spell_id, src_guid)
			if entry then
				if entry[2] > GetTime() then
					return entry[1], entry[2]
				end
				auras[dst_guid][spell_id][src_guid] = del(entry)
			end
		else
			-- The aura has no caster, assign it one of the expirations we have
			local casters = get(auras, dst_guid, spell_id)
			if casters then
				wipe(tmp)
				local t = GetTime()
				-- Build an indexed table of the caster guids and sort by expiration
				for guid, entry in next, casters do
					if entry[2] > t then
						tmp[#tmp+1] = guid
					else
						auras[dst_guid][spell_id][guid] = del(entry)
					end
				end
				sort(tmp, function(a, b) return casters[a][2] > casters[b][2] end)

				-- Find which instance of the aura is being updated
				local index = 0
				for i=1, #aura_list do
					if aura_list[i].spell_id == spell_id or i == aura_index then -- (the data hasn't been updated yet so always count our aura)
						index = index + 1
					end
					if i == aura_index then break	end
				end

				-- Pick the caster to go with the aura
				if 1 <= index and index <= #tmp then
					local guid = tmp[index]
					return casters[guid][1], casters[guid][2]
				end
			end
		end
	end
	return 0, 0
end
