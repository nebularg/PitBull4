
if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC and WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then
	return -- ERROR ALL THE THINGS!
end

-- luacheck: globals oRA3 ReloadUI SecureButton_GetModifiedUnit

-- Constants ----------------------------------------------------------------
local _G = _G

local L = LibStub("AceLocale-3.0"):GetLocale("PitBull4")

local wow_classic = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC or nil
local wow_bcc = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC or nil

local SINGLETON_CLASSIFICATIONS = {
	"player",
	"pet",
	"pettarget",
	"target",
	"targettarget",
	"targettargettarget",
	wow_bcc and "focus",
	wow_bcc and "focustarget",
	wow_bcc and "focustargettarget",
}

local UNIT_GROUPS = {
	"party",
	"partytarget",
	"partytargettarget",
	"partypet",
	"partypettarget",
	"partypettargettarget",
	"raid",
	"raidtarget",
	"raidtargettarget",
	"raidpet",
	"raidpettarget",
	"raidpettargettarget",
}

local NORMAL_UNITS = {
	"player",
	"pet",
	"target",
	wow_bcc and "focus",
	-- "mouseover",
}
for i = 1, _G.MAX_PARTY_MEMBERS do
	NORMAL_UNITS[#NORMAL_UNITS+1] = "party" .. i
	NORMAL_UNITS[#NORMAL_UNITS+1] = "partypet" .. i
end
for i = 1, _G.MAX_RAID_MEMBERS do
	NORMAL_UNITS[#NORMAL_UNITS+1] = "raid" .. i
end

do
	local tmp = NORMAL_UNITS
	NORMAL_UNITS = {}
	for i, v in ipairs(tmp) do
		NORMAL_UNITS[v] = true
	end
	tmp = nil
end

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
local DEFAULT_LSM_FONT = "Arial Narrow"
if LibSharedMedia and not LibSharedMedia:IsValid("font", DEFAULT_LSM_FONT) then -- non-Western languages
	DEFAULT_LSM_FONT = LibSharedMedia:GetDefault("font")
end

local CURRENT_CONFIG_VERSION = 6

local DATABASE_DEFAULTS = {
	profile = {
		addon_states_migrated = false,
		lock_movement = false,
		frame_snap = true,
		minimap_icon = {
			hide = false,
			minimapPos = 200,
			radius = 80,
		},
		units = {
			['**'] = {
				enabled = false,
				anchor = "CENTER",
				relative_to = "0", -- UIParent
				relative_point = "CENTER",
				position_x = 0,
				position_y = 0,
				size_x = 1, -- this is a multiplier
				size_y = 1, -- this is a multiplier
				font_multiplier = 1,
				scale = 1,
				layout = L["Normal"],
				horizontal_mirror = false,
				vertical_mirror = false,
				click_through = false,
				tooltip = 'always',
			},
		},
		groups = {
			['**'] = {
				enabled = false,
				sort_method = "INDEX",
				sort_direction = "ASC",
				horizontal_spacing = 30,
				vertical_spacing = 30,
				direction = "down_right",
				units_per_column = _G.MAX_RAID_MEMBERS,
				unit_group = "party",
				include_player = false,
				group_filter = nil,
				group_by = nil,
				use_pet_header = nil,

				anchor = "", -- automatic from growth direction
				relative_to = "0", -- UIParent
				relative_point = "CENTER",
				position_x = 0,
				position_y = 0,
				size_x = 1, -- this is a multiplier
				size_y = 1, -- this is a multiplier
				font_multiplier = 1,
				scale = 1,
				layout = L["Normal"],
				horizontal_mirror = false,
				vertical_mirror = false,
				click_through = false,
				tooltip = 'always',
				exists = false, -- used to force the group to exist even if all values are default

				show_when = {
					solo = false,
					party = true,
					raid = false,
					raid10 = false,
					raid15 = false,
					raid20 = false,
					raid25 = false,
					raid40 = false,
				},
			}
		},
		made_groups = false,
		made_units = false,
		group_anchors_updated = false,
		layouts = {
			['**'] = {
				size_x = 200,
				size_y = 60,
				opacity_min = 0.1,
				opacity_max = 1,
				opacity_smooth = true,
				scale = 1,
				font = DEFAULT_LSM_FONT,
				font_size = 1,
				bar_texture = LibSharedMedia and LibSharedMedia:GetDefault("statusbar") or "Blizzard",
				bar_spacing = 2,
				bar_padding = 2,
				indicator_spacing = 3,
				indicator_size = 15,
				indicator_bar_inside_horizontal_padding = 3,
				indicator_bar_inside_vertical_padding = 3,
				indicator_bar_outside_margin = 3,
				indicator_root_inside_horizontal_padding = 2,
				indicator_root_inside_vertical_padding = 5,
				indicator_root_outside_margin = 5,
				strata = 'MEDIUM',
				level = 1, -- minimum 1, since 0 needs to be available
				exists = false, -- used to force the layout to exist even if all values are default
			},
		},
		colors = {
			class = {}, -- filled in by RAID_CLASS_COLORS
			power = {}, -- filled in by PowerBarColor
			reaction = { -- filled in by FACTION_BAR_COLORS
				civilian = { 48/255, 113/255, 191/255 }
			},
			happiness = {
				happy = { 0, 1, 0 },
				content = { 1, 1, 0 },
				unhappy = { 1, 0, 0 },
			},
			threat = {
				[0] = {0.69, 0.69, 0.69},
				[1] = {1, 1, 0.47},
				[2] = {1, 0.6, 0},
				[3] = {1, 0, 0},
			},
		},
		class_order = {},
	}
}
for class, color in pairs(_G.RAID_CLASS_COLORS) do
	DATABASE_DEFAULTS.profile.colors.class[class] = { color.r, color.g, color.b }
end
for power_token, color in pairs(_G.PowerBarColor) do
	if type(power_token) == "string" then
		if color.r then
			DATABASE_DEFAULTS.profile.colors.power[power_token] = { color.r, color.g, color.b }
		end
	end
end
for reaction, color in pairs(_G.FACTION_BAR_COLORS) do
	DATABASE_DEFAULTS.profile.colors.reaction[reaction] = { color.r, color.g, color.b }
end

local DEFAULT_GROUPS = {
	[L["Party"]] = {
		enabled = true,
		unit_group = "party",
		exists = true,
		anchor = "", -- automatic from growth direction
		relative_to = "0", -- UIParent
		relative_point = "TOPLEFT",
		position_x = 10,
		position_y = -260,
	},
	[L["Party pets"]] = {
		-- enabled = true,
		unit_group = "partypet",
		exists = true,
	},
}

local DEFAULT_UNITS =  {
	[L["Player"]] = {
		enabled = true,
		unit = "player",
		anchor = "TOPLEFT",
		relative_to = "0", -- UIParent
		relative_point = "TOPLEFT",
		position_x = 10,
		position_y = -25,
	},
	[L["Player's pet"]] = {
		enabled = true,
		unit = "pet",
		anchor = "TOP",
		relative_to = "SPlayer",
		relative_point = "BOTTOM",
		position_x = 0,
		position_y = -30,
	},
	[format(L["%s's target"],L["Player's pet"])]= {
		unit = "pettarget"
	},
	[L["Target"]] = {
		enabled = true,
		unit = "target",
		anchor = "TOPLEFT",
		relative_to = "0", -- UIParent
		relative_point = "TOPLEFT",
		position_x = 250,
		position_y = -25,
	},
	[format(L["%s's target"],L["Target"])] = {
		enabled = true,
		unit = "targettarget",
		anchor = "LEFT",
		relative_to = "STarget",
		relative_point = "RIGHT",
		position_x = 0,
		position_y = 0,
	},
	[format(L["%s's target"],format(L["%s's target"],L["Target"]))] = {
		unit = "targettargettarget",
	},
}
if wow_bcc then
	DEFAULT_UNITS[L["Focus"]] = {
		enabled = true,
		unit = "focus",
		anchor = "TOPLEFT",
		relative_to = "0", -- UIParent
		relative_point = "TOPLEFT",
		position_x = 250,
		position_y = -260,
	}
	DEFAULT_UNITS[format(L["%s's target"],L["Focus"])]= {
		unit = "focustarget",
	}
	DEFAULT_UNITS[format(L["%s's target"],format(L["%s's target"],L["Focus"]))] = {
		unit = "focustargettarget",
	}
end

local LOCALIZED_NAMES = {}
do
	for i = 1, 12 do
		local info = C_CreatureInfo.GetClassInfo(i)
		if info then
			LOCALIZED_NAMES[info.classFile] = info.className
		end
	end

	local i = 1
	local info = C_CreatureInfo.GetRaceInfo(i)
	repeat
		if not LOCALIZED_NAMES[info.clientFileString] then
			LOCALIZED_NAMES[info.clientFileString] = info.raceName
		end
		i = i + 1
		info = C_CreatureInfo.GetRaceInfo(i)
	until not info

	-- setmetatable(LOCALIZED_NAMES, { __index = function(self, key)
	-- 	self[key] = key
	-- 	return key
	-- end })
end



-----------------------------------------------------------------------------

local _, PitBull4 = ...
PitBull4 = LibStub("AceAddon-3.0"):NewAddon(PitBull4, "PitBull4", "AceEvent-3.0", "AceTimer-3.0")
_G.PitBull4 = PitBull4

local DEBUG = PitBull4.DEBUG
local expect = PitBull4.expect

PitBull4.version = "@project-version@"
if PitBull4.version:match("@") then
	PitBull4.version = "Development"
end

PitBull4.wow_classic = wow_classic
PitBull4.wow_bcc = wow_bcc

PitBull4.L = L

PitBull4.SINGLETON_CLASSIFICATIONS = SINGLETON_CLASSIFICATIONS
PitBull4.UNIT_GROUPS = UNIT_GROUPS

PitBull4.LOCALIZED_NAMES = LOCALIZED_NAMES

local db

if not _G.ClickCastFrames then
	-- for click-to-cast addons
	_G.ClickCastFrames = {}
end

do
	-- unused tables go in this set
	-- if the garbage collector comes around, they'll be collected properly
	local cache = setmetatable({}, {__mode='k'})

	--- Return a table
	-- @usage local t = PitBull4.new()
	-- @return a blank table
	function PitBull4.new()
		local t = next(cache)
		if t then
			cache[t] = nil
			return t
		end

		return {}
	end

	local wipe = _G.wipe
	--- Delete a table, clearing it and putting it back into the queue
	-- @usage local t = PitBull4.new()
	-- t = del(t)
	-- @return nil
	function PitBull4.del(t)
		if DEBUG then
			expect(t, 'typeof', 'table')
			expect(t, 'not_inset', cache)
		end

		wipe(t)
		cache[t] = true
		return nil
	end
end

local do_nothing = function() end

local new, del = PitBull4.new, PitBull4.del

-- A set of all unit frames
local all_frames = {}
PitBull4.all_frames = all_frames

-- A list of all unit frames
local all_frames_list = {}
PitBull4.all_frames_list = all_frames_list

-- A set of all unit frames with the is_wacky flag set to true
local wacky_frames = {}
PitBull4.wacky_frames = wacky_frames

PitBull4.num_wacky_frames = 0

-- A set of all unit frames with the is_wacky flag set to false
local non_wacky_frames = {}
PitBull4.non_wacky_frames = non_wacky_frames

-- A set of all unit frames with the is_singleton flag set to true
local singleton_frames = {}
PitBull4.singleton_frames = singleton_frames

-- A set of all unit frames with the is_singleton flag set to false
local member_frames = {}
PitBull4.member_frames = member_frames

-- A set of all group headers
local all_headers = {}
PitBull4.all_headers = all_headers

-- metatable that automatically creates keys that return tables on access
local auto_table__mt = {__index = function(self, key)
	if key == nil then
		return nil
	end
	local value = {}
	self[key] = value
	return value
end}

-- A dictionary of UnitID to a set of all unit frames of that UnitID
local unit_id_to_frames = setmetatable({}, auto_table__mt)
PitBull4.unit_id_to_frames = unit_id_to_frames

-- A dictionary of UnitID to a set of all unit frames of that UnitID, plus wacky frames that are the same unit.
local unit_id_to_frames_with_wacky = setmetatable({}, auto_table__mt)
PitBull4.unit_id_to_frames_with_wacky = unit_id_to_frames_with_wacky

-- A dictionary of classification to a set of all unit frames of that classification
local classification_to_frames = setmetatable({}, auto_table__mt)
PitBull4.classification_to_frames = classification_to_frames

-- A dictionary of unit group to a set of all group headers of that unit group
local unit_group_to_headers = setmetatable({}, auto_table__mt)
PitBull4.unit_group_to_headers = unit_group_to_headers

-- A dictionary of super-unit group to a set of all group headers of that super-unit group
local super_unit_group_to_headers = setmetatable({}, auto_table__mt)
PitBull4.super_unit_group_to_headers = super_unit_group_to_headers

local name_to_header = {}
PitBull4.name_to_header = name_to_header

-- A dictionary of UnitID to GUID for non-wacky units
local unit_id_to_guid = {}
PitBull4.unit_id_to_guid = unit_id_to_guid

-- A dictionary of GUID to a set of UnitIDs for non-wacky units
local guid_to_unit_ids = {}
PitBull4.guid_to_unit_ids = guid_to_unit_ids

-- A list of frames that need to be anchored because their relative frame
-- did not exist when we tried to anchor them.  The key is the frame and the
-- value is the relative_to value, see the documentation for Utils.GetRelativeFrame()
-- for the details of the relative_to value.
local frames_to_anchor = {}
PitBull4.frames_to_anchor = frames_to_anchor

local function get_best_unit(guid)
	if not guid then
		return nil
	end

	local guid_to_unit_ids__guid = guid_to_unit_ids[guid]
	if not guid_to_unit_ids__guid then
		return nil
	end

	return (next(guid_to_unit_ids__guid))
end
PitBull4.get_best_unit = get_best_unit

local function refresh_guid(unit,new_guid)
	if not NORMAL_UNITS[unit] then
		return
	end

	local old_guid = unit_id_to_guid[unit]
	if new_guid == old_guid then
		return
	end
	unit_id_to_guid[unit] = new_guid

	if old_guid then
		local guid_to_unit_ids__old_guid = guid_to_unit_ids[old_guid]
		guid_to_unit_ids__old_guid[unit] = nil
		if not next(guid_to_unit_ids__old_guid) then
			guid_to_unit_ids[old_guid] = del(guid_to_unit_ids__old_guid)
		end
	end

	if new_guid then
		local guid_to_unit_ids__new_guid = guid_to_unit_ids[new_guid]
		if not guid_to_unit_ids__new_guid then
			guid_to_unit_ids__new_guid = new()
			guid_to_unit_ids[new_guid] = guid_to_unit_ids__new_guid
		end
		guid_to_unit_ids__new_guid[unit] = true
	end

	for frame in PitBull4:IterateWackyFrames() do
		if frame.best_unit == unit or frame.guid == new_guid then
			frame:UpdateBestUnit()
		end
	end
end

local function refresh_all_guids()
	for unit in pairs(NORMAL_UNITS) do
		local guid = UnitGUID(unit)
		refresh_guid(unit,guid)
	end
end

--- Wrap the given function so that any call to it will be piped through PitBull4:RunOnLeaveCombat.
-- @param func function to call
-- @usage myFunc = PitBull4:OutOfCombatWrapper(func)
-- @usage MyNamespace.MyMethod = PitBull4:OutOfCombatWrapper(MyNamespace.MyMethod)
-- @return the wrapped function
function PitBull4:OutOfCombatWrapper(func)
	if DEBUG then
		expect(func, 'typeof', 'function')
	end

	return function(...)
		return PitBull4:RunOnLeaveCombat(func, ...)
	end
end

-- iterate through a set of frames and return those that are shown
local function iterate_shown_frames(set, frame)
	frame = next(set, frame)
	if frame == nil then
		return
	end
	if frame:IsShown() then
		return frame
	end
	return iterate_shown_frames(set, frame)
end

-- iterate through a set of headers and return those that have a group_db set
local function iterate_used_headers(set, header)
	header = next(set, header)
	if header == nil then
		return
	end
	if header.group_db then
		return header
	end
	return iterate_used_headers(set, header)
end

-- iterate through and return only the keys of a table
local function half_next(set, key)
	key = next(set, key)
	if key == nil then
		return nil
	end
	return key
end

-- iterate through and return only the keys of a table. Once exhausted, recycle the table.
local function half_next_with_del(set, key)
	key = next(set, key)
	if key == nil then
		del(set)
		return nil
	end
	return key
end

--- Iterate over all frames.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param also_hidden also return frames that are hidden
-- @usage for frame in PitBull4:IterateFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFrames(also_hidden)
	if DEBUG then
		expect(also_hidden, 'typeof', 'boolean;nil')
	end

	return not also_hidden and iterate_shown_frames or half_next, all_frames
end

--- Iterate over all wacky frames.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param also_hidden also return frames that are hidden
-- @usage for frame in PitBull4:IterateWackyFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateWackyFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateWackyFrames(also_hidden)
	if DEBUG then
		expect(also_hidden, 'typeof', 'boolean;nil')
	end

	return not also_hidden and iterate_shown_frames or half_next, wacky_frames
end

--- Iterate over all non-wacky frames.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param also_hidden also return frames that are hidden
-- @usage for frame in PitBull4:IterateNonWackyFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateNonWackyFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateNonWackyFrames(also_hidden, only_non_wacky)
	if DEBUG then
		expect(also_hidden, 'typeof', 'boolean;nil')
	end

	return not also_hidden and iterate_shown_frames or half_next, non_wacky_frames
end

--- Iterate over all singleton frames.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param also_hidden also return frames that are hidden
-- @usage for frame in PitBull4:IterateSingletonFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateSingletonFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateSingletonFrames(also_hidden)
	if DEBUG then
		expect(also_hidden, 'typeof', 'boolean;nil')
	end

	return not also_hidden and iterate_shown_frames or half_next, singleton_frames
end

--- Iterate over all member frames.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param also_hidden also return frames that are hidden
-- @usage for frame in PitBull4:IterateNonWackyFrames() do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateNonWackyFrames(true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateMemberFrames(also_hidden)
	if DEBUG then
		expect(also_hidden, 'typeof', 'boolean;nil')
	end

	return not also_hidden and iterate_shown_frames or half_next, member_frames
end

--- Iterate over all frames with the given unit ID
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param unit the UnitID of the unit in question
-- @param also_hidden also return frames that are hidden
-- @param dont_include_wacky don't include wacky frames that are the same unit
-- @usage for frame in PitBull4:IterateFramesForUnitID("player") do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateFramesForUnitID("party1", true) do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateFramesForUnitID("party1", false, true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForUnitID(unit, also_hidden, dont_include_wacky)
	if DEBUG then
		expect(unit, 'typeof', 'string')
		expect(also_hidden, 'typeof', 'boolean;nil')
		expect(dont_include_wacky, 'typeof', 'boolean;nil')
	end

	local id = PitBull4.Utils.GetBestUnitID(unit)
	if not id then
		if DEBUG then
			error(("Bad argument #1 to `IterateFramesForUnitID'. %q is not a valid UnitID"):format(tostring(unit)), 2)
		else
			return function () end
		end
	end

	return not also_hidden and iterate_shown_frames or half_next, (not dont_include_wacky and unit_id_to_frames_with_wacky or unit_id_to_frames)[id]
end

--- Iterate over all shown frames with the given UnitIDs.
-- To iterate over hidden frames as well, pass in true as the last argument.
-- @param ... a tuple of UnitIDs.
-- @usage for frame in PitBull4:IterateFramesForUnitIDs("player", "target", "pet") do
--     somethingAwesome(frame)
-- end
-- @usage for frame in PitBull4:IterateFramesForUnitIDs("player", "target", "pet", true) do
--     somethingAwesome(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForUnitIDs(...)
	local t = new()
	local n = select('#', ...)

	local also_hidden = ((select(n, ...)) == true)
	if also_hidden then
		n = n - 1
	end

	for i = 1, n do
		local unit = (select(i, ...))
		local frames = unit_id_to_frames_with_wacky[unit]

		for frame in pairs(frames) do
			if also_hidden or frame:IsShown() then
				t[frame] = true
			end
		end
	end

	return half_next_with_del, t
end

--- Iterate over all frames with the given classification.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param classification the classification to check
-- @param also_hidden also return frames that are hidden
-- @usage for frame in PitBull4:IterateFramesForClassification("player") do
--     doSomethingWith(frame)
-- end
-- @usage for frame in PitBull4:IterateFramesForClassification("party", true) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForClassification(classification, also_hidden)
	if DEBUG then
		expect(classification, 'typeof', 'string')
		expect(also_hidden, 'typeof', 'boolean;nil')
	end

	local frames = rawget(classification_to_frames, classification)
	if not frames then
		return do_nothing
	end

	return not also_hidden and iterate_shown_frames or half_next, frames
end

local function layout_iter(layout, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	if frame.layout == layout then
		return frame
	end
	return layout_iter(layout, frame)
end

local function layout_shown_iter(layout, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	if frame.layout == layout and frame:IsShown() then
		return frame
	end
	return layout_iter(layout, frame)
end

--- Iterate over all frames with the given layout.
-- This iterates over only shown frames unless also_hidden is passed in.
-- @param layout the layout to check
-- @param also_hidden also return frames that are hidden
-- @usage for frame in PitBull4:IterateFramesForLayout("Normal") do
--     frame:UpdateLayout()
-- end
-- @usage for frame in PitBull4:IterateFramesForLayout("Normal", true) do
--     frame:UpdateLayout()
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForLayout(layout, also_hidden)
	if DEBUG then
		expect(layout, 'typeof', 'string')
		expect(also_hidden, 'typeof', 'boolean;nil')
	end

	return not also_hidden and layout_shown_iter or layout_iter, layout
end

--- call :Update() on all frames with the given layout
-- @param layout the layout to check
-- @usage PitBull4:UpdateForLayout("Normal")
function PitBull4:UpdateForLayout(layout)
	for frame in self:IterateFramesForLayout(layout) do
		frame:Update(true, true)
	end
end

local function guid_iter(guid, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	if frame.guid == guid then
		return frame
	end
	return guid_iter(guid, frame)
end

--- Iterate over all frames with the given GUID
-- @param guid the GUID to check. can be nil, which will cause no frames to return.
-- @usage for frame in PitBull4:IterateFramesForGUID("0x0000000000071278") do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForGUID(guid)
	if DEBUG then
		expect(guid, 'typeof', 'string;nil')
	end

	if not guid then
		return do_nothing
	end

	return guid_iter, guid, nil
end

local function guids_iter(guids, frame)
	frame = next(all_frames, frame)
	if not frame then
		del(guids)
		return nil
	end
	if guids[frame.guid] then
		return frame
	end
	return guids_iter(guids, frame)
end

--- Iterate over all frames with the given GUIDs
-- @param ... the GUIDs to check. Can be nil.
-- @usage for frame in PitBull4:IterateFramesForGUIDs(UnitGUID) do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForGUIDs(...)
	local guids = new()
	for i = 1, select('#', ...) do
		local guid = (select(i, ...))
		if DEBUG then
			expect(guid, 'typeof', 'string;nil')
		end

		if guid then
			guids[guid] = true
		end
	end

	if not next(guids) then
		guids = del(guids)
		return do_nothing
	end

	return guids_iter, guids, nil
end

local function name_iter(state, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	local name,server = state.name, state.server
	if frame.guid and frame.unit then
		local frame_name, frame_server = UnitName(frame.unit)
		if frame_name == name and (not server and server ~= "" or server == frame_server) then
			return frame
		end
	end
	return name_iter(state, frame)
end

local state = {}
--- Iterate over all frames with the given name
-- @param name the name to check. can be nil, which will cause no frames to return.
-- @param server the name of the realm, can be nil, which will cause only the name to be matched.
-- @usage for frame in PitBull4:IterateFramesForName("Someguy") do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForName(name,server)
	if DEBUG then
		expect(name, 'typeof', 'string;nil')
	end

	if not name then
		return do_nothing
	end

	state.name = name
	state.server = server

	return name_iter, state, nil
end

--- Iterate over all headers.
-- @param also_unused also return headers unused by the current profile.
-- @usage for header in PitBull4:IterateHeaders()
--     doSomethingWith(header)
-- end
-- @return iterator which returns headers
function PitBull4:IterateHeaders(also_unused)
	return not also_unused and iterate_used_headers or half_next, all_headers
end

--- Iterate over all headers with the given classification.
-- @param unit_group the unit group to check
-- @usage for header in PitBull4:IterateHeadersForUnitGroup("party")
--     doSomethingWith(header)
-- end
-- @return iterator which returns headers
function PitBull4:IterateHeadersForUnitGroup(unit_group)
	if DEBUG then
		expect(unit_group, 'typeof', 'string')
	end

	local headers = rawget(unit_group_to_headers, unit_group)
	if not headers then
		return do_nothing
	end

	return iterate_shown_frames, headers
end

--- Iterate over all headers with the given super-classification.
-- @param super_unit_group the super-unit group to check. This can be "party" or "raid"
-- @usage for header in PitBull4:IterateHeadersForSuperUnitGroup("party")
--     doSomethingWith(header)
-- end
-- @return iterator which returns headers
function PitBull4:IterateHeadersForSuperUnitGroup(super_unit_group)
	if DEBUG then
		expect(super_unit_group, 'typeof', 'string')
		expect(super_unit_group, 'inset', 'party;raid;boss;arena')
	end

	local headers = rawget(super_unit_group_to_headers, super_unit_group)
	if not headers then
		return do_nothing
	end

	return iterate_shown_frames, headers
end

local function return_same(object, key)
	if key then
		return nil
	else
		return object
	end
end

--- Iterate over all headers with the given name.
-- @param name the name to check
-- @usage for header in PitBull4:IterateHeadersForName("Party pets")
--     doSomethingWith(header)
-- end
-- @return iterator which returns zero or one header
function PitBull4:IterateHeadersForName(name)
	if DEBUG then
		expect(name, 'typeof', 'string')
	end

	return return_same, name_to_header[name]
end

local function header_layout_iter(layout, header)
	header = next(all_headers, header)
	if not header then
		return nil
	end
	if header.layout == layout then
		return header
	end
	return header_layout_iter(layout, header)
end

--- Iterate over all headers with the given layout.
-- @param layout the layout to check
-- @usage for header in PitBull4:IterateHeadersForLayout("Normal") do
--     header:RefreshLayout()
-- end
-- @return iterator which returns headers
function PitBull4:IterateHeadersForLayout(layout, also_hidden)
	if DEBUG then
		expect(layout, 'typeof', 'string')
	end

	return header_layout_iter, layout
end

--- Call a given method on all modules if those modules have the method.
-- This will iterate over disabled modules.
-- @param method_name name of the method
-- @param ... arguments that will pass in to the module
function PitBull4:CallMethodOnModules(method_name, ...)
	for id, module in self:IterateModules() do
		if module[method_name] then
			module[method_name](module, ...)
		end
	end
end

-- Callback for when the main tank list updates from oRA
function PitBull4:OnTanksUpdated()
	for header in PitBull4:IterateHeadersForSuperUnitGroup("raid") do
		local group_db = header.group_db
		if group_db and group_db.group_filter == "MAINTANK" then
			header:RefreshGroup()
		end
	end
end

local upgrade_functions = {
	[1] = function(sv)
		-- Version 1 (version number used for config files without a version tag)
		-- This version is missing the exists key for layouts, groups, and units
		local function make_layout_exist(profile_db, layout)
			local layouts = profile_db.layouts
			if not layouts then
				layouts = {}
				profile_db.layouts = layouts
			end
			local layout_db = layouts[layout]
			if not layout_db then
				layout_db = {}
				layouts[layout] = layout_db
			end
			layout_db.exists = true
		end
		local profiles = sv.profiles
		local namespaces = sv.namespaces
		if not profiles then return true end
		for profile, profile_db in pairs(profiles) do
			local units = profile_db.units
			if units then
				for unit, unit_db in pairs(units) do
					-- Check units for orphaned layouts
					local layout = unit_db.layout or L["Normal"]
					make_layout_exist(profile_db, layout)
				end
			end
			local groups = profile_db.groups
			if groups then
				for group, group_db in pairs(groups) do
					-- Add the exists flag to current groups,
					-- there is no way to recover orphaned groups.
					group_db.exists = true
					-- Check groups for orphaned layouts
					local layout = group_db.layout or L["Normal"]
					make_layout_exist(profile_db, layout)
				end
			end
			if namespaces then
				-- Search our modules config entries for orphaned layouts
				for namespace, namespace_db in pairs(namespaces) do
					if namespace_db and namespace_db.profiles and namespace_db.profiles[profile] and namespace_db.profiles[profile].layouts then
						for layout in pairs(namespace_db.profiles[profile].layouts) do
							make_layout_exist(profile_db, layout)
						end
					end
				end
			end
		end
		return true
	end,
	[2] = function(sv)
		-- Allows creating multiple singleton frames and frame-to-frame anchoring.
		if not sv.profiles then return true end
		-- We don't have AceDB to provide defaults, so do it ourself.
		local group_mt = { __index = function(t, k) return DATABASE_DEFAULTS.profile.groups["**"][k] end }
		local layout_mt = { __index = function(t, k) return DATABASE_DEFAULTS.profile.layouts["**"][k] end }

		local tmp = {}
		for profile, profile_db in pairs(sv.profiles) do
			-- Convert the old units table to the new format.  Prior to this we could
			-- only have one unit frame per unit for singelton frames.  Now we can have
			-- as many as we want.  However, we can't use the unit id as the key now so
			-- migrate the old units to their localized names as keys and set their unit
			-- id as the unit key.
			if profile_db.units and not profile_db.made_units then
				profile_db.made_units = true
				local units = profile_db.units
				-- Copy the units to a tmp table
				for unit, data in pairs(units) do
					tmp[unit] = data
				end
				-- Rebuild the units table with the localized unit names as keys.
				wipe(units)
				for unit, data in pairs(tmp) do
					units[PitBull4.Utils.GetLocalizedClassification(unit)] = data
					data.unit = unit
					if data.enabled == nil then
						-- enabled was default so set it explitly since the default for
						-- some units is disabled now.
						data.enabled = true
					end
				end
				wipe(tmp)
			end

			-- Offsets used to be stored between the center of the screen and the center
			-- of the group frame, while the frames anchor point varied based on the
			-- growth direction of the frame.  So the offset from the actual anchor point
			-- was calculated as needed.  Now we store the the actual offsets and only
			-- recalculate if the anchor point is being determined by the growth direction.
			if not profile_db.group_anchors_updated then -- the anchors branch set this
				local groups = profile_db.groups
				local layouts = profile_db.layouts
				if groups and layouts then
					for group, group_db in pairs(groups) do
						if group_db then
							local layout_db = layouts[group_db.layout]
							if layout_db then
								setmetatable(group_db, group_mt)
								setmetatable(layout_db, layout_mt)
								PitBull4:MigrateGroupAnchorToNewFormat(group_db, layout_db)
								setmetatable(layout_db, nil)
								setmetatable(group_db, nil)
							end
						end
					end
				end
			end
			-- sv cleanup
			profile_db.group_anchors_updated = nil
			profile_db.addon_states_migrated = nil
		end
		sv.global.addon_states_migrated = nil

		return true
	end,
	[3] = function(sv)
		-- Disable groups that are set to filter everything and reset the
		-- group_filter value.
		if not sv.profiles then return true end
		for profile, profile_db in next, sv.profiles do
			if profile_db.groups then
				for group, group_db in next, profile_db.groups do
					if group_db and group_db.group_filter == "" then
						group_db.group_filter = nil
						group_db.enabled = nil
					end
				end
			end
		end
		return true
	end,
	[4] = function(sv)
		-- Remove old frames for classic. sssssh, it's for the best.
		if not sv.profiles then return true end
		-- reset the position of any orphaned frames
		local function reset_pos(f, t)
			if not f then return end
			for _, db in next, f do
				if t[db.relative_to] then
					db.anchor = nil
					db.relative_to = nil
					db.relative_point = nil
					db.position_x = nil
					db.position_y = nil
				end
			end
		end
		for profile, profile_db in next, sv.profiles do
			local removed = {}
			local units = profile_db.units
			if units then
				for unit, unit_db in next, units do
					local id = PitBull4.Utils.GetBestUnitID(unit_db.unit)
					if not PitBull4.Utils.IsSingletonUnitID(id) then
						units[unit] = nil
						removed["S"..unit] = true
					end
				end
			end
			local groups = profile_db.groups
			if groups then
				for group, group_db in next, groups do
					local id = group_db.unit_group
					if not PitBull4.Utils.IsValidClassification(id) then
						groups[group] = nil
						removed["g"..group] = true
						removed["f"..group] = true
					elseif group_db.group_by == "ASSIGNEDROLE" then
						group_db.group_by = nil
					end
				end
			end
			reset_pos(units, removed)
			reset_pos(groups, removed)
		end
		return true
	end,
	[5] = function(sv)
		-- Ok, maybe it wasn't for the best. Add back default focus frames for BCC.
		if wow_classic then return true end
		if not sv.profiles then return true end
		local focus_frames = {
			L["Focus"],
			L["%s's target"]:format(L["Focus"]),
			L["%s's target"]:format(L["%s's target"]:format(L["Focus"])),
		}
		for profile, profile_db in next, sv.profiles do
			if profile_db.made_units then
				for _, name in next, focus_frames do
					if not profile_db.units[name] then
						profile_db.units[name] = CopyTable(DEFAULT_UNITS[name])
					end
				end
			end
		end
		return true
	end,
}

local function check_config_version(sv)
	if not sv then return true end
	local global = sv.global
	if not global then
		global = {}
		sv.global = global
	end
	if not global.config_version then
		-- Existing config without config_version, so set it to 1
		global.config_version = 1
	end

	while (global.config_version < CURRENT_CONFIG_VERSION) do
		if upgrade_functions[global.config_version] then
			if not upgrade_functions[global.config_version](sv) then
				error(format(L["Problem upgrading PitBull4 config_version %d to %d.  Please file a ticket and attach your WTF/Account/$ACCOUNT/SavedVariables/PitBull4.lua file!"],global.config_version,global.config_version + 1))
			end
		end
		global.config_version = global.config_version + 1
	end
end

function PitBull4:OnInitialize()
	local fresh_config = check_config_version(_G["PitBull4DB"])

	db = LibStub("AceDB-3.0"):New("PitBull4DB", DATABASE_DEFAULTS, "Default")
	self.db = db

	if fresh_config then
		db.global.config_version = CURRENT_CONFIG_VERSION
	end

	db.RegisterCallback(self, "OnProfileChanged")
	db.RegisterCallback(self, "OnProfileReset")
	db.RegisterCallback(self, "OnNewProfile")
	db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")

	self.DEFAULT_COLORS = CopyTable(DATABASE_DEFAULTS.profile.colors.power)
	DATABASE_DEFAULTS = nil

	-- ModuleHandling\Module.lua
	self:InitializeModuleDefaults()
	self:RegisterEvent("ADDON_LOADED", "HandleModuleLoad")

	local LibDataBrokerLauncher = LibStub("LibDataBroker-1.1"):NewDataObject("PitBull4", {
		type = "launcher",
		icon = [[Interface\AddOns\PitBull4\pitbull]],
		OnClick = function(frame, button)
			if button == "RightButton" then
				if IsShiftKeyDown() then
					self.db.profile.frame_snap = not self.db.profile.frame_snap
				else
					self.db.profile.lock_movement = not self.db.profile.lock_movement
				end
				LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
			else
				return self.Options.OpenConfig()
			end
		end,
		OnTooltipShow = function(tt)
			tt:AddLine(L["PitBull Unit Frames 4.0"])
			tt:AddLine("|cffffff00" .. L["%s|r to open the options menu"]:format(L["Click"]), 1, 1, 1)
			tt:AddLine("|cffffff00" .. L["%s|r to toggle frame lock"]:format(L["Right-click"]), 1, 1, 1)
			tt:AddLine("|cffffff00" .. L["%s|r to toggle frame snapping"]:format(L["Shift Right-click"]), 1, 1, 1)
		end,
	})

	local LibDBIcon = LibStub("LibDBIcon-1.0", true)
	if LibDBIcon then
		LibDBIcon:Register("PitBull4", LibDataBrokerLauncher, self.db.profile.minimap_icon)
	end

	self:RegisterEvent("PLAYER_ROLES_ASSIGNED", "OnTanksUpdated")
	if oRA3 then
		oRA3.RegisterCallback(self, "OnTanksUpdated")
	end
end

do
	local function find_PitBull4(...)
		for i = 1, select('#', ...) do
			if (select(i, ...)) == "PitBull4" then
				return true
			end
		end
		return false
	end

	local function iter(num_addons, i)
		i = i + 1
		if i > num_addons then
			-- and we're done
			return nil
		end

		-- must be Load-on-demand (obviously)
		if not IsAddOnLoadOnDemand(i) then
			return iter(num_addons, i)
		end

		local name = GetAddOnInfo(i)
		-- must start with PitBull4_
		local module_name = name:match("^PitBull4_(.*)$")
		if not module_name then
			return iter(num_addons, i)
		end

		-- PitBull4 must be in the Dependency list
		if not find_PitBull4(GetAddOnDependencies(i)) then
			return iter(num_addons, i)
		end

		local condition = GetAddOnMetadata(name, "X-PitBull4-Condition")
		if condition then
			local func = loadstring(condition)
			if func then
				-- function created successfully
				local success, ret = pcall(func)
				if success then
					-- function called and returned successfully
					if not ret then
						-- shouldn't load, e.g. DruidManaBar when you're not a druid
						return iter(num_addons, i)
					end
				end
			end
		end

		-- passes all tests
		return i, name, module_name
	end

	--- Return a iterator of addon ID, addon name that are modules that PitBull4 can load.
	-- module_name is the same as name without the "PitBull4_" prefix.
	-- @usage for i, name, module_name in PitBull4:IterateLoadOnDemandModules() do
	--     print(i, name, module_name)
	-- end
	-- @return an iterator which returns id, name, module_name
	function PitBull4:IterateLoadOnDemandModules()
		return iter, GetNumAddOns(), 0
	end
end

local modules_not_loaded = {}
PitBull4.modules_not_loaded = modules_not_loaded

--- Load Load-on-demand modules if they are enabled and exist.
-- @usage PitBull4:LoadModules()
function PitBull4:LoadModules()
	local current_profile = self.db:GetCurrentProfile()
	local sv = self.db.sv
	local sv_namespaces = sv and sv.namespaces
	for i, name, module_name in self:IterateLoadOnDemandModules() do

		local module_sv = sv_namespaces and sv_namespaces[module_name]
		local module_profile_db = module_sv and module_sv.profiles and module_sv.profiles[current_profile]
		local enabled = module_profile_db and module_profile_db.global and module_profile_db.global.enabled

		if enabled == nil then
			-- we have to figure out the default state
			local default_state = GetAddOnMetadata(name, "X-PitBull4-DefaultState")
			enabled = (default_state ~= "disabled")
		end

		local loaded
		if enabled then
			-- print(("Found module '%s', attempting to load."):format(module_name))
			loaded = LoadAddOn(name)
		end

		if not loaded then
			-- print(("Found module '%s', not loaded."):format(module_name))
			modules_not_loaded[module_name] = true
		end
	end
end

--- Load the module with the given id and enable it
function PitBull4:LoadAndEnableModule(id)
	local loaded, reason = LoadAddOn('PitBull4_' .. id)
	if loaded then
		local module = self:GetModule(id)
		assert(module)
		self:EnableModuleAndSaveState(module)
	else
		if reason then
			reason = _G["ADDON_"..reason]
		end
		if not reason then
			reason = UNKNOWN
		end
		DEFAULT_CHAT_FRAME:AddMessage(format(L["%s: Could not load module '%s': %s"],"PitBull4",id,reason))
	end
end

local function merge_onto(base, addition)
	for k, v in pairs(addition) do
		if type(v) == "table" then
			merge_onto(base[k], v)
		else
			base[k] = v
		end
	end
end

function PitBull4:OnProfileChanged()
	self.ClassColors = db.profile.colors.class
	self.PowerColors = db.profile.colors.power
	self.ReactionColors = db.profile.colors.reaction
	self.HappinessColors = db.profile.colors.happiness
	self.ThreatColors = db.profile.colors.threat
	self.ClassOrder = db.profile.class_order
	for i = #self.ClassOrder, 1, -1 do
		local v = self.ClassOrder[i]
		if not tContains(CLASS_SORT_ORDER, v) then
			tremove(self.ClassOrder, i)
		end
	end
	for i = 1, #CLASS_SORT_ORDER do
		local v = CLASS_SORT_ORDER[i]
		if not tContains(self.ClassOrder, v) then
			self.ClassOrder[#self.ClassOrder + 1] = v
		end
	end

	-- Notify modules that the profile has changed.
	for _, module in PitBull4:IterateEnabledModules() do
		if module.OnProfileChanged then
			module:OnProfileChanged()
		end
	end

	if not db.profile.made_groups then
		db.profile.made_groups = true
		for name, data in pairs(DEFAULT_GROUPS) do
			local group_db = db.profile.groups[name]
			merge_onto(group_db, data)
		end
	end

	if not db.profile.made_units then
		db.profile.made_units = true
		for name, data in pairs(DEFAULT_UNITS) do
			local unit_db = db.profile.units[name]
			merge_onto(unit_db, data)
		end
	end

	for header in PitBull4:IterateHeaders(true) do
		local group_db = rawget(db.profile.groups, header.name)
		header.group_db = group_db
		for _, frame in ipairs(header) do
			frame.classification_db = header.group_db
		end
	end
	for frame in PitBull4:IterateSingletonFrames(true) do
		frame.classification_db = db.profile.units[frame.classification]
	end

	for header in PitBull4:IterateHeaders(true) do
		if header.group_db then
			header:RefreshGroup(true)
		end
		header:UpdateShownState()
	end

	for frame in PitBull4:IterateFrames(true) do
		frame:RefreshLayout()
	end

	-- Make sure all frames and groups are made
	for singleton, singleton_db in pairs(db.profile.units) do
		if singleton_db.enabled then
			self:MakeSingletonFrame(singleton)
		else
			for frame in PitBull4:IterateFramesForClassification(singleton, true) do
				frame:Deactivate()
			end
		end
	end
	for group, group_db in pairs(db.profile.groups) do
		if group_db.enabled then
			self:MakeGroupHeader(group)
			for header in PitBull4:IterateHeadersForName(group) do
				header.group_db = group_db
				header:RefreshGroup()
				header:UpdateShownState()
			end
		end
	end

	self:LoadModules()

	-- Enable/Disable modules to match the new profile.
	for _,module in self:IterateModules() do
		if module.db.profile.global.enabled then
			self:EnableModuleAndSaveState(module)
		else
			self:DisableModuleAndSaveState(module)
		end
	end

	self:RecheckConfigMode()

	local LibDBIcon = LibStub("LibDBIcon-1.0", true)
	if LibDBIcon then
		LibDBIcon:Refresh("PitBull4", db.profile.minimap_icon)
	end
end

function PitBull4:OnNewProfile()
	db.profile.layouts[L["Normal"]].exists = true
end

function PitBull4:OnProfileReset()
	self:OnNewProfile()
	self:OnProfileChanged()
end

function PitBull4:LibSharedMedia_Registered(event, mediatype, key)
	-- Notify modules that a new media has been registered
	for _, module in PitBull4:IterateEnabledModules() do
		if module.LibSharedMedia_Registered then
			module:LibSharedMedia_Registered(event, mediatype, key)
		end
	end
end

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

function PitBull4:OnEnable()
	self:ScheduleRepeatingTimer(refresh_all_guids, 15)

	-- register unit change events
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	if wow_bcc then
		self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	end
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UNIT_PET")

	-- register events for core handled bar coloring
	self:RegisterEvent("UNIT_FACTION")
	self:RegisterEvent("UNIT_HAPPINESS", "UNIT_FACTION")

	-- enter/leave combat for :RunOnLeaveCombat
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")

	self:RegisterEvent("GROUP_ROSTER_UPDATE")

	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_LEAVING_WORLD")

	timerFrame:Show()

	-- show initial frames
	self:OnProfileChanged()

	if LibSharedMedia then
		LibSharedMedia.RegisterCallback(self, "LibSharedMedia_Registered")
	end
end

local timer = 0
local wacky_update_rate
local current_wacky_frame
timerFrame:SetScript("OnUpdate",function(self, elapsed)
	local num_wacky_frames = PitBull4.num_wacky_frames
	if num_wacky_frames <= 0 then return end
	wacky_update_rate = 0.15 / num_wacky_frames
	timer = timer + elapsed
	while timer > wacky_update_rate do
		current_wacky_frame = next(wacky_frames, current_wacky_frame)
		if not current_wacky_frame then
			current_wacky_frame = next(wacky_frames, current_wacky_frame)
		end
		local unit = current_wacky_frame.unit
		if unit and current_wacky_frame:IsVisible() then
			current_wacky_frame:UpdateGUID(UnitGUID(unit))
		end
		timer = timer - wacky_update_rate
	end
end)

-- Watch for custom anchors that may not be created until after
-- the frame is created.
local anchor_elapsed = 0
local anchor_timer = CreateFrame("Frame")
anchor_timer:Hide()
anchor_timer:SetScript("OnUpdate",function(self, elapsed)
	anchor_elapsed = anchor_elapsed + elapsed
	if anchor_elapsed >= 0.2 then
		for frame, relative_to in pairs(frames_to_anchor) do
			if relative_to:sub(1,1) == "~" then
				local relative_name = relative_to:sub(2)
				if relative_name and _G[relative_name] then
					frame:RefixSizeAndPosition()
				end
			end
		end
		anchor_elapsed = 0
		if not next(frames_to_anchor) then
			anchor_timer:Hide()
		end
	end
end)
PitBull4.anchor_timer = anchor_timer

--- Iterate over all wacky frames, and call their respective :UpdateGUID methods.
-- @usage PitBull4:CheckWackyFramesForGUIDUpdate()
function PitBull4:CheckWackyFramesForGUIDUpdate()
	for frame in self:IterateWackyFrames() do
		if frame.unit and frame:IsShown() then
			frame:UpdateGUID(UnitGUID(frame.unit))
		end
	end
end

--- Check the GUID of the given UnitID and send that info to all frames for that UnitID
-- @param unit the UnitID to check
-- @param is_pet pass true if calling from UNIT_PET
-- @usage PitBull4:CheckGUIDForUnitID("player")
function PitBull4:CheckGUIDForUnitID(unit, is_pet)
	if not PitBull4.Utils.GetBestUnitID(unit) then
		-- for ids such as npctarget
		return
	end
	local guid = UnitGUID(unit)
	refresh_guid(unit,guid)

	-- If there is no guid then we want to disallow upating the frame
	-- However, if there is a guid we want to pass nil and leave it up
	-- to UpdateGUID()
	local update
	if not guid then
		update = false
	elseif is_pet and UnitLevel(unit) ~= 0 then
		-- force an update for pets if the pet level isn't 0.  We typically
		-- get the guid before other info about the pet is available such
		-- as the level, pet experience, etc and this means we have to force
		-- an update when it becomes available.  This is somewhat ugly but
		-- it's the only way to have pet frames update properly.
		update = true
	end

	-- If the guid is nil we don't want to see hidden frames since
	-- there's nothing to do as UnitFrame:OnHide will have already done this work.
	for frame in self:IterateFramesForUnitID(unit,not not guid) do
		frame:UpdateGUID(guid,update)
	end
end

function PitBull4:PLAYER_FOCUS_CHANGED()
	self:CheckGUIDForUnitID("focus")
	self:CheckGUIDForUnitID("focustarget")
	self:CheckGUIDForUnitID("focustargettarget")
end

function PitBull4:PLAYER_TARGET_CHANGED()
	self:CheckGUIDForUnitID("target")
	self:CheckGUIDForUnitID("targettarget")
	self:CheckGUIDForUnitID("targettargettarget")
end

function PitBull4:UNIT_TARGET(_, unit)
	if unit ~= "player" then
		self:CheckGUIDForUnitID(unit .. "target")
		self:CheckGUIDForUnitID(unit .. "targettarget")
	end
end

function PitBull4:UNIT_PET(_, unit)
	self:CheckGUIDForUnitID(unit .. "pet", true)
	self:CheckGUIDForUnitID(unit .. "pettarget")
	self:CheckGUIDForUnitID(unit .. "pettargettarget")
end

function PitBull4:UNIT_FACTION(_, unit)
	-- On UNIT_FACTION changes update bars to allow coloring changes based on
	-- hostility.
	for frame in self:IterateFramesForUnitID(unit) do
		for _, module in self:IterateModulesOfType("bar","bar_provider") do
			module:Update(frame)
		end
	end
end

local StateHeader = CreateFrame("Frame", nil, nil, "SecureHandlerBaseTemplate")
PitBull4.StateHeader = StateHeader

-- Note please do not use tabs in the code passed to WrapScript, WoW can't display
-- tabs in FontStrings and it makes errors inside the below code look like crap.
StateHeader:WrapScript(StateHeader, "OnAttributeChanged", [[
  if name ~= "new_group" and name ~= "remove_group" and name ~= "state-group" and name ~= "config_mode" and name ~= "forced_state" then return end

  -- Special handling for the new_group and remove_group attributes
  local header
  if name == "new_group" then
    -- value is the name of the new group header to add to our group list
    if not value then return end

    if not groups then
      groups = newtable()
    end

    header = self:GetFrameRef(value)
    groups[value] = header
  elseif name == "remove_group" then
    -- value is the name of the group header to remove from our group list
    if not value or not groups then return end

    header = groups[value]
    if header then
      groups[value] = nil
    end
  end

  if not header and not groups then return end -- Nothing to do

  state = self:GetAttribute("config_mode")
  if not state then
    state = self:GetAttribute("forced_state")
    if not state then
      state = self:GetAttribute("state-group")
    end
  end

  if header then
    -- header is set so this is a single header update
    -- We must check groups[value] here so that we don't try to show
    -- frames that we're removing.
    if state and groups[value] and header:GetAttribute(state) then
      header:Show()
    else
      header:Hide()
      -- Wipe the unit id off the child frames so the hidden frames
      -- are ignored by the unit watch system.
      local children = newtable(header:GetChildren())
      for i=1,#children do
        children[i]:SetAttribute("unit", nil)
      end
    end
  else
    -- No header set so do them all
    for _, header in pairs(groups) do
      if header:GetAttribute(state) then
        header:Show()
      else
        header:Hide()
        -- Wipe the unit id off the child frames so the hidden frames
        -- are ignored by the unit watch system.
        local children = newtable(header:GetChildren())
        for i=1,#children do
          children[i]:SetAttribute("unit", nil)
        end
      end
    end
  end
]])
RegisterStateDriver(StateHeader, "group", "[target=raid26, exists] raid40; [target=raid21, exists] raid25; [target=raid16, exists] raid20; [target=raid11, exists] raid15; [target=raid6, exists] raid10; [group:raid] raid; [group:party] party; solo")

function PitBull4:AddGroupToStateHeader(header)
	local header_name = header:GetName()
	StateHeader:SetFrameRef(header_name, header)
	StateHeader:SetAttribute("new_group",header_name)
end

function PitBull4:RemoveGroupFromStateHeader(header)
	StateHeader:SetAttribute("remove_group",header:GetName())
end

--- Get the current state that the player is in.
-- This will return one of "solo", "party", "raid", "raid10", "raid15", "raid20", "raid25", or "raid40".
-- Setting config mode does override this.
-- @usage local state = PitBull4:GetState()
-- @return the state of the player.
function PitBull4:GetState()
	return PitBull4.config_mode or GetManagedEnvironment(StateHeader).state
end

function PitBull4:PLAYER_LEAVING_WORLD()
	self.leaving_world = true
end


function PitBull4:PLAYER_ENTERING_WORLD()
	self.leaving_world = nil
	refresh_all_guids()
end

function PitBull4:GROUP_ROSTER_UPDATE()
	refresh_all_guids()
end

do
	local in_combat = false
	local in_lockdown = false
	local actions_to_perform = {}
	local pool = setmetatable({}, {__mode='k'})
	function PitBull4:PLAYER_REGEN_ENABLED()
		in_combat = false
		in_lockdown = false
		for i, t in ipairs(actions_to_perform) do
			t.f(unpack(t, 1, t.n))
			actions_to_perform[i] = nil
			wipe(t)
			pool[t] = true
		end
	end
	function PitBull4:PLAYER_REGEN_DISABLED()
		in_combat = true
		self.SingletonUnitFrame:PLAYER_REGEN_DISABLED()
		self.MemberUnitFrame:PLAYER_REGEN_DISABLED()
		if PitBull4.config_mode then
			UIErrorsFrame:AddMessage(L["Disabling PitBull4 config mode, entering combat."], 0.5, 1, 0.5, nil, 1)
			PitBull4:SetConfigMode(nil)
		end
	end
	--- Call a function if out of combat or schedule to run once combat ends.
	-- If current out of combat, the function provided will be called without delay.
	-- @param func function to call
	-- @param ... arguments to pass into func
	-- @usage PitBull4:RunOnLeaveCombat(someSecureFunction)
	-- @usage PitBull4:RunOnLeaveCombat(someSecureFunction, "player")
	-- @usage PitBull4:RunOnLeaveCombat(frame.SetAttribute, frame, "key", "value")
	function PitBull4:RunOnLeaveCombat(func, ...)
		if DEBUG then
			expect(func, 'typeof', 'function')
		end
		if not in_combat then
			-- out of combat, call right away and return
			func(...)
			return
		end
		if not in_lockdown then
			in_lockdown = InCombatLockdown() -- still in PLAYER_REGEN_DISABLED
			if not in_lockdown then
				func(...)
				return
			end
		end
		local t = next(pool) or {}
		pool[t] = nil

		t.f = func
		local n = select('#', ...)
		t.n = n
		for i = 1, n do
			t[i] = select(i, ...)
		end
		actions_to_perform[#actions_to_perform+1] = t
	end
end
