local PitBull4 = _G.PitBull4
local PitBull4_Aura = PitBull4:GetModule("Aura")
local module = PitBull4_Aura:NewModule("AuraDuration", "AceEvent-3.0")

local bit_band = bit.band
local player_guid = UnitGUID("player")

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
local diminished_returns = new()

-- DR is 15 seconds, but the server only checks every 5 seconds, so it can reset any time between 15 and 20 seconds.
local DR_RESET_TIME = 18

-- Categories that have DR in PvE
local dr_pve_categories = {
	stun = true,
	-- blind = true,
	cheapshot = true,
	-- kidneyshot - true,
}

local spells = PitBull4.Spells.spell_durations
local dr_spells = PitBull4.Spells.dr_spells

-- This uses the logic provided by Shadowed in DRData-1.0 (it's his fault if it doesn't work right!)
-- DR is applied when the debuff fades
local function add_dr(dst_guid, spell_id, is_player)
	local cat = dr_spells[spell_id]
	if not cat then return end
	if not is_player and not dr_pve_categories[cat] then return end

	local entry = diminished_returns[dst_guid][cat]
	entry[0] = GetTime() + DR_RESET_TIME
	local diminished = get(entry, 1) or 1
	if diminished == 1 then
		entry[1] = 0.5
	elseif diminished == 0.5 then
		entry[1] = 0.25
	else
		entry[1] = 0
	end
end

-- DR reset time is checked when the debuff is gained
local function get_dr(dst_guid, spell_id, is_player)
	local cat = dr_spells[spell_id]
	if cat and (is_player or dr_pve_categories[cat]) then
		local entry = diminished_returns[dst_guid][cat]
		if get(entry, 0) and entry[0] <= GetTime() then
			wipe(entry)
		end
		return get(entry, 1) or 1
	end
	return 1
end

local is_player = bit.bor(COMBATLOG_OBJECT_TYPE_PLAYER, COMBATLOG_OBJECT_CONTROL_PLAYER)
local is_group = bit.bor(COMBATLOG_OBJECT_AFFILIATION_MINE, COMBATLOG_OBJECT_AFFILIATION_PARTY, COMBATLOG_OBJECT_AFFILIATION_RAID)

local event_list = {
	SPELL_AURA_APPLIED = true,
	SPELL_AURA_APPLIED_DOSE = true,
	SPELL_AURA_REFRESH = true,
	SPELL_AURA_REMOVED = true,
}

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self)
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

	if event_list[event] and spells[spell_id] and bit_band(src_flags, is_group) > 0 then
		if event == "SPELL_AURA_REMOVED" or event == "SPELL_AURA_REFRESH" then
			add_dr(dst_guid, spell_id, bit_band(dst_flags, is_player) > 0)
		end

		if event == "SPELL_AURA_APPLIED" or event == "SPELL_AURA_REFRESH" or event == "SPELL_AURA_APPLIED_DOSE" then
			local duration = spells[spell_id] * get_dr(dst_guid, spell_id)
			local expiration = GetTime() + duration
			local entry = auras[dst_guid][spell_id][src_guid]
			entry[1] = duration
			entry[2] = expiration
		elseif event == "SPELL_AURA_REMOVED" then
			auras[dst_guid][spell_id][src_guid] = del(auras[dst_guid][spell_id][src_guid])
		end
	end
end)

function module:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
end

function module:OnDisable()
	frame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:PLAYER_ENTERING_WORLD()
end

function module:PLAYER_ENTERING_WORLD()
	-- tidy up
	local purge = not IsInGroup()
	for guid in next, auras do
		if purge or not guid:match("^Player") then
			auras[guid] = del(auras[guid])
		end
	end
	for guid in next, diminished_returns do
		diminished_returns[guid] = del(diminished_returns[guid])
	end
end

function PitBull4_Aura:GetDuration(src_guid, dst_guid, spell_id)
	if spells[spell_id] then
		local entry = get(auras, dst_guid, spell_id, src_guid)
		if entry then
			return entry[1], entry[2]
		end
	end
	return 0, 0
end
