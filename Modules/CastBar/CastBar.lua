
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.4
local EXAMPLE_ICON = 136222 -- Spell_Shadow_Teleport
local TEMP_ICON = 136235

local PitBull4_CastBar = PitBull4:NewModule("CastBar")

PitBull4_CastBar:SetModuleType("bar")
PitBull4_CastBar:SetName(L["Cast bar"])
PitBull4_CastBar:SetDescription(L["Show a cast bar."])
PitBull4_CastBar:SetDefaults({
	size = 1,
	position = 10,
	show_icon = true,
	auto_hide = false,
	idle_background = false,
},{
	casting_interruptible_color = { 1, 0.7, 0 },
	casting_uninterruptible_color = { 1, 222/255, 144/255},
	casting_complete_color = { 0, 1, 0 },
	casting_failed_color = { 1, 0, 0 },
	channel_interruptible_color = { 0, 0, 1 },
	channel_uninterruptible_color = { 96/255, 180/255, 211/255 },
})

local cast_data = {}
PitBull4_CastBar.cast_data = cast_data

local function safe_compare_temp_icon(icon, temp_icon)
	if icon == nil then
		return false
	end

	local ok, is_temp = pcall(function()
		return icon == temp_icon
	end)
	if ok then
		return is_temp
	end

	return false
end

local function safe_cast_time_seconds(value)
	if value == nil then
		return 0
	end

	local ok, number = pcall(function()
		return value + 0
	end)
	if ok and number then
		return number * 0.001
	end

	return 0
end

local function safe_interruptible(uninterruptible)
	-- Midnight can mark this field as a protected boolean. Do not negate it directly.
	-- Fall back to interruptible when the value is not safely usable.
	if uninterruptible == nil then
		return true
	end

	local ok, interruptible = pcall(function(value)
		if value == true then
			return false
		end
		if value == false then
			return true
		end
		return true
	end, uninterruptible)
	if ok then
		return interruptible
	end

	return true
end

local function safe_cast_id_equal(a, b)
	if a == nil or b == nil then
		return false
	end

	local ok, equal = pcall(function(left, right)
		return left == right
	end, a, b)
	if ok then
		return equal
	end

	return false
end

local SafeGUID = PitBull4.Utils.SafeGUID
local SafeString = PitBull4.Utils.SafeString
local SafeEqual = PitBull4.Utils.SafeEqual

local function SafeUnitToken(unit)
	if type(unit) == "string" and unit ~= "" then
		return unit
	end
	return nil
end

local function GetCastKeyForFrame(frame)
	local best_unit = SafeUnitToken(frame.best_unit)
	local unit = SafeUnitToken(frame.unit)
	if best_unit and unit and unit:find("target", 1, true) == 1 then
		return best_unit .. unit
	end
	return best_unit or unit
end

local timer_frame = CreateFrame("Frame")
timer_frame:Hide()
timer_frame:SetScript("OnUpdate", function() PitBull4_CastBar:FixCastDataAndUpdateAll() end)

local player_guid
function PitBull4_CastBar:OnEnable()
	player_guid = SafeGUID(UnitGUID("player"))

	timer_frame:Show()

	self:RegisterEvent("UNIT_SPELLCAST_START", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_STOP", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTIBLE", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_NOT_INTERRUPTIBLE", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", "UpdateInfo")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP", "UpdateInfo")
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT")
end

function PitBull4_CastBar:OnDisable()
	timer_frame:Hide()
end

function PitBull4_CastBar:FixCastDataAndUpdateAll()
	self:FixCastData()
	self:UpdateAll()
end

local new, del
do
	local pool = setmetatable({}, {__mode='k'})
	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		end

		return {}
	end
	function del(t)
		wipe(t)
		pool[t] = true
	end
end

function PitBull4_CastBar:GetValue(frame)
	local key = GetCastKeyForFrame(frame)
	local data = key and cast_data[key] or nil
	if frame.is_wacky or not data then
		self:UpdateInfo(nil, key or frame.unit)
		data = key and cast_data[key] or nil
	end

	local db = self:GetLayoutDB(frame)
	if not data then
		if db.auto_hide then
			return nil
		end
		return 0, nil, nil
	end

	local icon = db.show_icon and data.icon or nil

	if data.casting then
		local start_time = data.start_time
		return (GetTime() - start_time) / (data.end_time - start_time), nil, icon
	elseif data.channeling then
		local end_time = data.end_time
		return (end_time - GetTime()) / (end_time - data.start_time), nil, icon
	elseif data.fade_out then
		return frame.CastBar and frame.CastBar:GetValue() or 0, nil, icon
	end

	if db.auto_hide then
		return nil
	end
	return 0, nil, icon
end

function PitBull4_CastBar:GetExampleValue(frame)
	local db = self:GetLayoutDB(frame)
	return EXAMPLE_VALUE, nil, db.show_icon and EXAMPLE_ICON or nil
end

function PitBull4_CastBar:GetColor(frame, value)
	local key = GetCastKeyForFrame(frame)
	local data = key and cast_data[key] or nil
	if not data then
		return 0, 0, 0, 0
	end

	if data.casting then
		if data.interruptible then
			local r, g, b = unpack(self.db.profile.global.casting_interruptible_color)
			return r, g, b, 1
		else
			local r, g, b = unpack(self.db.profile.global.casting_uninterruptible_color)
			return r, g, b, 1
		end
	elseif data.channeling then
		if data.interruptible then
			local r, g, b = unpack(self.db.profile.global.channel_interruptible_color)
			return r, g, b, 1
		else
			local r, g, b = unpack(self.db.profile.global.channel_uninterruptible_color)
			return r, g, b, 1
		end
	elseif data.fade_out then
		local alpha, r, g, b
		local stop_time = data.stop_time
		if stop_time then
			alpha = stop_time - GetTime() + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			return 0, 0, 0, 0
		else
			-- Decide which color to use
			if not data.was_channeling then -- Last cast was a normal one...
				if data.failed then
					r, g, b = unpack(self.db.profile.global.casting_failed_color)
				else
					r, g, b = unpack(self.db.profile.global.casting_complete_color)
				end
			else
				if data.interruptible then -- Last cast was a channel...
					r, g, b = unpack(self.db.profile.global.channel_interruptible_color)
				else
					r, g, b = unpack(self.db.profile.global.channel_uninterruptible_color)
				end
			end
			return r, g, b, alpha
		end
	end
	return 0, 0, 0, 0
end

function PitBull4_CastBar:GetBackgroundColor(frame, value)
	local key = GetCastKeyForFrame(frame)
	local data = key and cast_data[key] or nil

	if not data then
		if not self:GetLayoutDB(frame).idle_background then
			return nil, nil, nil, 0
		end
	elseif data.fade_out then
		local alpha
		local stop_time = data.stop_time
		if stop_time then
			alpha = stop_time - GetTime() + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			alpha = 0
		end
		return nil, nil, nil, alpha
	end
end

function PitBull4_CastBar:GetExampleColor(frame, value)
	return 0, 1, 0, 1
end

function PitBull4_CastBar:ClearFramesByGUID(guid)
	for frame in PitBull4:IterateFramesForGUID(guid) do
		self:Update(frame)
	end
end

function PitBull4_CastBar:UpdateInfo(event, unit, event_cast_id)
	local key = SafeUnitToken(unit)
	if not key then
		return
	end
	local data = cast_data[key]
	if not data then
		data = new()
		cast_data[key] = data
	end

	local spell, _, icon, start_time, end_time, _, cast_id, uninterruptible = UnitCastingInfo(unit)
	local channeling = false
	if not spell then
		spell, _, icon, start_time, end_time, _, uninterruptible = UnitChannelInfo(unit)
		channeling = true
	end
	if spell then
		if safe_compare_temp_icon(icon, TEMP_ICON) then
			icon = nil
		end
		data.spell = spell
		data.icon = icon
		data.start_time = safe_cast_time_seconds(start_time)
		data.end_time = safe_cast_time_seconds(end_time)
		data.casting = not channeling
		data.channeling = channeling
		data.interruptible = safe_interruptible(uninterruptible)
		data.fade_out = false
		data.was_channeling = channeling -- persistent state even after interrupted
		data.stop_time = nil
		if event ~= "UNIT_SPELLCAST_INTERRUPTED" then
			-- We can't update the cache of teh cast_id on UNIT_SPELLCAST_INTERRUPTED because
			-- for whatever reason it ends up giving us 0 inside this event.
			data.cast_id = SafeString(cast_id)
		end
		timer_frame:Show()
		return
	end

	if not data.spell then
		cast_data[key] = del(data)
		if not next(cast_data) then
			timer_frame:Hide()
		end
		return
	end

	if safe_cast_id_equal(data.cast_id, SafeString(event_cast_id)) then
		-- The event was for the cast we're currently casting
		if event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then
			data.failed = true
		elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
			-- This is necessary because if the interrupt happens just as the cast finishes
			-- it can look to the client like it failed but the server sends the success
			-- message after.
			data.failed = false
		end
	end

	data.casting = false
	data.channeling = false
	data.fade_out = true
	if not data.stop_time then
		data.stop_time = GetTime()
	end
end

local tmp = {}
function PitBull4_CastBar:FixCastData()
	local frame
	local current_time = GetTime()
	for key, data in pairs(cast_data) do
		tmp[key] = data
	end
	for key, data in pairs(tmp) do
		local found = false
		for frame in PitBull4:IterateFramesForUnitID(key, true) do
			if self:GetLayoutDB(frame).enabled then
				found = true
				if data.casting then
					if current_time > data.end_time and key ~= "player" then
						data.casting = false
						data.fade_out = true
						data.stop_time = current_time
					end
				elseif data.channeling then
					if current_time > data.end_time then
						data.channeling = false
						data.fade_out = true
						data.stop_time = current_time
					end
				elseif data.fade_out then
					local alpha = 0
					local stop_time = data.stop_time
					if stop_time then
						alpha = stop_time - current_time + 1
					end

					if alpha <= 0 then
						cast_data[key] = del(data)
						self:UpdateAll()
					end
				else
					cast_data[key] = del(data)
					self:UpdateAll()
				end
				break
			end
		end
		if not found then
			cast_data[key] = del(data)
		end
	end
	if not next(cast_data) then
		timer_frame:Hide()
	end
	wipe(tmp)
end

function PitBull4_CastBar:INSTANCE_ENCOUNTER_ENGAGE_UNIT()
	for i=1, _G.MAX_BOSS_FRAMES do
		local unit = ("boss%d"):format(i)
		self:UpdateInfo(nil, unit)
	end
end

PitBull4_CastBar:SetLayoutOptionsFunction(function(self)
	return 'auto_hide', {
		name = L["Auto-hide"],
		desc = L["Automatically hide the cast bar when not casting."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).auto_hide
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).auto_hide = value

			PitBull4.Options.UpdateFrames()
		end,
	}, 'show_icon', {
		name = L["Show icon"],
		desc = L["Whether to show the icon that is being cast."],
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).show_icon
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).show_icon = value

			PitBull4.Options.RefreshFrameLayouts()
		end,
	}, 'icon_on_left', {
		name = L["Icon position"],
		desc = L["What side of the bar to show the icon on."],
		type = 'select',
		values = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			local icon_on_left = db.icon_on_left
			local side = db.side
			local reverse = db.reverse

			if not reverse then
				if side == "center" then
					return {
						left = L["Left"],
						right = L["Right"],
					}
				else
					return {
						left = L["Bottom"],
						right = L["Top"],
					}
				end
			else
				if side == "center" then
					return {
						left = L["Right"],
						right = L["Left"],
					}
				else
					return {
						left = L["Top"],
						right = L["Bottom"],
					}
				end
			end
		end,
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).icon_on_left and "left" or "right"
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).icon_on_left = (value == "left")

			PitBull4.Options.RefreshFrameLayouts()
		end,
		hidden = function(info)
			return not PitBull4.Options.GetLayoutDB(self).show_icon
		end
	}, 'idle_background', {
		name = L["Idle background"],
		desc = L["Show background on the cast bar when nothing is being cast."],
		type = 'toggle',
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.idle_background and not db.auto_hide
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).idle_background = value

			PitBull4.Options.RefreshFrameLayouts()
		end,
		disabled = function(info)
			return PitBull4.Options.GetLayoutDB(self).auto_hide
		end,
	}
end)

PitBull4_CastBar:SetColorOptionsFunction(function(self)
	return 'casting', {
		type = 'group',
		name = L["Casting"],
		inline = true,
		args = {
			casting_interruptible_color = {
				type = 'color',
				name = L["Interruptible"],
				desc = L["Sets which color to use on casting bar of casts that are interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.casting_interruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_interruptible_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 1,
			},
			casting_uninterruptible_color = {
				type = 'color',
				name = L["Uninterruptible"],
				desc = L["Sets which color to use on casting bar of casts that are not interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.casting_uninterruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_uninterruptible_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 2,
			},
			casting_complete_color = {
				type = 'color',
				name = L["Complete"],
				desc = L["Sets which color to use on casting bar of casts that completed."],
				get = function(info)
					return unpack(self.db.profile.global.casting_complete_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_complete_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 3,
			},
			casting_failed_color = {
				type = 'color',
				name = L["Failed"],
				desc = L["Sets which color to use on casting bar of casts that failed."],
				get = function(info)
					return unpack(self.db.profile.global.casting_failed_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.casting_failed_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 4,
			},
		},
	}, 'channeling', {
		type = 'group',
		name = L["Channeling"],
		inline = true,
		args = {
			channel_interruptible_color = {
				type = 'color',
				name = L["Interruptible"],
				desc = L["Sets which color to use on casting bar of channeled casts that are interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.channel_interruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.channel_interruptible_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 1,
			},
			channel_uninterruptible_color = {
				type = 'color',
				name = L["Uninterruptible"],
				desc = L["Sets which color to use on casting bar of channeled casts that are not interruptible."],
				get = function(info)
					return unpack(self.db.profile.global.channel_uninterruptible_color)
				end,
				set = function(info, r, g, b)
					self.db.profile.global.channel_uninterruptible_color = { r, g, b }
					self:UpdateAll()
				end,
				order = 2,
			},
		},
	},
	function(info)
		self.db.profile.global.casting_interruptible_color = { 1, 0.7, 0 }
		self.db.profile.global.casting_uninterruptible_color = { 1, 222/255, 144/255 }
		self.db.profile.global.casting_complete_color = { 0, 1, 0 }
		self.db.profile.global.casting_failed_color = { 1, 0, 0 }
		self.db.profile.global.channel_interruptible_color = { 0, 0, 1 }
		self.db.profile.global.channel_uninterruptible_color = { 96/255, 180/255, 211/255 }
	end
end)
