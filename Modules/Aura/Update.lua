-- Update.lua : Code to collect the auras on a unit, create the 
-- aura frames and set the data to display the auras.

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local PitBull4_Aura = PitBull4:GetModule("Aura")
local L = PitBull4.L
local UnitAura = _G.UnitAura
local math_ceil = _G.math.ceil
local GetTime = _G.GetTime
local unpack = _G.unpack

local function filter_aura_entry()
	-- TODO implement filtering
end

-- Fills an array of arrays with the information about the auras
-- The 'n' field is the size of the array entries.
local function get_aura_list(list, unit, is_buff)
	local filter = is_buff and "HELPFUL" or "HARMFUL"
	local id = 1
	local index = 1

	-- Loop through the auras
	while true do
		local entry = list[index]
		if not entry then
			entry = {} 
			list[index] = entry
		end

		entry[1],entry[2], entry[3], entry[4], entry[5], entry[6],
			entry[7], entry[8], entry[9], entry[10] =
			id, UnitAura(unit, id, filter)

		-- Hack to get around a Blizzard bug.  The Enrage debuff_type
		-- gets set to "" instead of "Enrage" like it should.
		-- Once this is fixed this code should be removed.
		if entry[6] == "" then
			entry[6] = "Enrage"
		end

		if not entry[2] then 
			-- No more auras, break the outer loop
			break
		end

		-- Filter the list if true 
		if not filter_aura_entry(entry) then
			-- Reuse this index position if the aura was
			-- filtered.
			index = index + 1
		end

		id = id + 1

	end

	-- Set the size of the list to the n key.
	-- We can't use #list because we recyle the 
	-- table without clearing it.
	list.n = index - 1

	return list
end

-- constants for building sample auras
local sample_buff_icon   = [[Interface\Icons\Spell_ChargePositive]]
local sample_debuff_icon = [[Interface\Icons\Spell_ChargeNegative]]
local sample_debuff_types = { L['Poison'], L['Magic'], L['Disease'], L['Curse'], L['Enrage'], 'nil' }

-- Fills up to the maximum number of auras with sample auras
local function get_aura_list_sample(list, max, is_buff)
	for i = list.n + 1, max do
		local entry = list[i]
		if not entry then
			entry = {}
			list[i] = entry
		end
	
		-- Create our bogus aura entry
		entry[1]  = 0 -- index 0 means PitBull generated aura
		entry[2]  = is_buff and L["Sample Buff"] or L["Sample Debuff"] -- name
		entry[3]  = "" -- rank
		entry[4]  = is_buff and sample_buff_icon or sample_debuff_icon
		entry[5]  = i -- count set to index to make order show
		entry[6]  = sample_debuff_types[(i-1)% #sample_debuff_types]
		entry[7]  = 0 -- duration
		entry[8]  = 0 -- expiration_time
		entry[9]  = ((i % 2) == 1) and 1 or nil -- is_mine
		entry[10] = nil -- is_stealable
	end
	list.n = max
end

local function sort_aura_list()
	-- TODO implement sorting
end

-- Setups up the aura frame and fill it with the proper data
-- to display the proper aura.
local function set_aura(frame, db, aura_controls, aura, i, is_buff)
	local control = aura_controls[i]

	local id, name, rank, icon, count, debuff_type, duration, expiration_time, is_mine, is_stealable = unpack(aura)

	local who = is_mine and "my" or "other"
	local rule = who .. '_' .. (is_buff and "buffs" or "debuffs")

	if not control then
		control = PitBull4.Controls.MakeAura(frame, is_buff)
		aura_controls[i] = control
	end

	control.id = id
	control.is_mine = is_mine
	control.name = name
	control.debuff_type = debuff_type

	local texture = control.texture
	texture:SetTexture(icon)
	if db.zoom_aura then
		texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	else
		texture:SetTexCoord(0, 1, 0, 1)
	end

	control.count_text:SetText(count > 1 and count or "")

	if db.cooldown[rule] and duration and duration > 0 then
		local cooldown = control.cooldown
		cooldown:Show()
		cooldown:SetCooldown(expiration_time - duration, duration)
	else
		control.cooldown:Hide()
	end

	if db.cooldown_text[rule] and duration and duration > 0 then
		local cooldown_text = control.cooldown_text
		cooldown_text.expiration_time = expiration_time
		cooldown_text:Show()
	else
		control.cooldown_text:Hide()
	end

	if db.border[rule] then
		local border = control.border
		local colors = PitBull4_Aura.db.profile.global.colors
		local is_friend = UnitIsFriend("player", control:GetUnit()) 
		if frame.force_show then
			-- config mode so treat all frames as friendly
			is_friend = true
		end
		border:Show()
		if (is_buff and is_friend) or (not is_buff and not is_friend) then
			border:SetVertexColor(unpack(colors.friend[who]))
		else
			local color = colors.enemy[tostring(debuff_type)]
			if not color then
				-- Use the Other color if there's not
				-- a color for the specific debuff type.
				color = colors.enemy["nil"]
			end
			border:SetVertexColor(unpack(color))
		end
	else
		control.border:Hide()
	end
end
	
-- The table we use for gathering the aura data, filtering
-- and then sorting them.  This table is reused without
-- wiping it ever, so care must be taken to use it in ways
-- that don't break this optimization.
local list = {}

local function update_auras(frame, db, is_buff)
	-- Get the controls table
	local controls
	if is_buff then
		controls = frame.aura_buffs
		if not controls then
			controls = {}
			frame.aura_buffs = controls
		end
	else
		controls = frame.aura_debuffs
		if not controls then
			controls = {}
			frame.aura_debuffs = controls
		end
	end

	local max = is_buff and db.max_buffs or db.max_debuffs

	get_aura_list(list, frame.unit, is_buff)

	-- Fill extra auras if we're in config mode
	if frame.force_show then
		get_aura_list_sample(list, max, is_buff)
	end

	sort_aura_list(list)

	-- Limit the number of displayed buffs here after we
	-- have filtered and sorted to allow the most important
	-- auras to be displayed rather than randomly tossing
	-- some away that may not be our prefered auras
	local buff_count = (list.n > max) and max or list.n

	for i = 1, buff_count do
		set_aura(frame, db, controls, list[i], i, is_buff)
	end

	-- Remove unnecessary aura frames
	for i = buff_count + 1, #controls do
		controls[i] = controls[i]:Delete()
	end
end

-- TODO Configurable formatting
local HOUR_ONELETTER_ABBR = _G.HOUR_ONELETTER_ABBR:gsub("%s", "") -- "%dh"
local MINUTE_ONELETTER_ABBR = _G.MINUTE_ONELETTER_ABBR:gsub("%s", "") -- "%dm"
local function format_time(seconds)
	if seconds >= 3600 then
		return HOUR_ONELETTER_ABBR:format(math_ceil(seconds/3600))
	elseif seconds >= 180 then
		return MINUTE_ONELETTER_ABBR:format(math_ceil(seconds/60))
	elseif seconds > 60 then
		seconds = math_ceil(seconds)
		return ("%d:%d"):format(seconds/60, seconds%60)
	else
		return ("%d"):format(math_ceil(seconds))
	end
end

local function update_cooldown_text(aura)
	local cooldown_text = aura.cooldown_text
	local expiration_time = cooldown_text.expiration_time
	if not expiration_time then return end

	local current_time = GetTime()
	local time_left = expiration_time - current_time
	if time_left >= 1 then
		cooldown_text:SetText(format_time(time_left))
	else
		cooldown_text:SetText("")
	end
end

local function clear_auras(frame, is_buff)
	local controls
	if is_buff then
		controls = frame.aura_buffs
	else
		controls = frame.aura_debuffs
	end

	if not controls then
		return
	end

	for i = 1, #controls do
		controls[i] = controls[i]:Delete()
	end
end

function PitBull4_Aura:ClearAuras(frame)
	clear_auras(frame, true) -- Buffs
	clear_auras(frame, false) -- Debuffs
end

function PitBull4_Aura:UpdateAuras(frame)
	local db = self:GetLayoutDB(frame)

	-- Buffs
	if db.enabled_buffs then
		update_auras(frame, db, true)
	else
		clear_auras(frame, true)
	end

	-- Debuffs
	if db.enabled_debuffs then
		update_auras(frame, db, false)
	else
		clear_auras(frame, false)
	end
end

function PitBull4_Aura:UpdateCooldownTexts()
	for frame in PitBull4:IterateFrames() do
		local aura_buffs = frame.aura_buffs
		if aura_buffs then
			for i = 1, #aura_buffs do
				update_cooldown_text(aura_buffs[i])
			end
		end

		local aura_debuffs = frame.aura_debuffs
		if aura_debuffs then
			for i = 1, #aura_debuffs do
				update_cooldown_text(aura_debuffs[i])
			end
		end
	end
end
				
