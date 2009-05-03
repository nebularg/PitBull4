-- Constants ----------------------------------------------------------------
--@debug@
LibStub("AceLocale-3.0"):NewLocale("PitBull4", "enUS", true, true)
--@end-debug@
local L = LibStub("AceLocale-3.0"):GetLocale("PitBull4")

local SINGLETON_CLASSIFICATIONS = {
	"player",
	"pet",
	"pettarget",
	"target",
	"targettarget",
	"targettargettarget",
	"focus",
	"focustarget",
	"focustargettarget",
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
	"focus",
	-- "mouseover",
}
for i = 1, MAX_PARTY_MEMBERS do
	NORMAL_UNITS[#NORMAL_UNITS+1] = "party" .. i
	NORMAL_UNITS[#NORMAL_UNITS+1] = "partypet" .. i
end
for i = 1, MAX_RAID_MEMBERS do
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
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

local DEFAULT_LSM_FONT = "Arial Narrow"
if LibSharedMedia then
	if not LibSharedMedia:IsValid("font", DEFAULT_LSM_FONT) then
		-- non-Western languages
		
		DEFAULT_LSM_FONT = LibSharedMedia:GetDefault("font")
	end
end

local DATABASE_DEFAULTS = {
	profile = {
		lock_movement = false,
		minimap_icon = {
			hide = false,
			minimapPos = 200,
			radius = 80,
		},
		units = {
			['**'] = {
				enabled = false,
				position_x = 0,
				position_y = 0,
				size_x = 1, -- this is a multiplier
				size_y = 1, -- this is a multiplier
				scale = 1,
				layout = L["Normal"],
				horizontal_mirror = false,
				vertical_mirror = false,
				click_through = false,
			},
			player = { enabled = true },
			pet = { enabled = true },
			pettarget = { enabled = true },
			target = { enabled = true },
			targettarget = { enabled = true },
			targettargettarget = { enabled = true },
			focus = { enabled = true },
			focustarget = { enabled = true },
			focustargettarget = { enabled = true },
		},
		groups = {
			['**'] = {
				enabled = false,
				sort_method = "INDEX",
				sort_direction = "ASC",
				horizontal_spacing = 30,
				vertical_spacing = 30,
				direction = "down_right",
				units_per_column = MAX_RAID_MEMBERS,
				unit_group = "party",
				include_player = false,
				group_filter = nil,
				group_by = nil,
				
				position_x = 0,
				position_y = 0,
				size_x = 1, -- this is a multiplier
				size_y = 1, -- this is a multiplier
				scale = 1,
				layout = L["Normal"],
				horizontal_mirror = false,
				vertical_mirror = false,
				click_through = false,
				
				show_when = {
					solo = false,
					party = true,
					raid10 = false,
					raid25 = false,
					raid40 = false,
				},
			}
		},
		made_groups = false,
		layouts = {
			['**'] = {
				size_x = 200,
				size_y = 60,
				opacity_min = 0.1,
				opacity_max = 1,
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
			},
		},
		colors = {
			class = {}, -- filled in by RAID_CLASS_COLORS
			power = {}, -- filled in by PowerBarColor
			reaction = { -- filled in by FACTION_BAR_COLORS
				civilian = { 48/255, 113/255, 191/255 }
			},
		}
	}
}
for class, color in pairs(RAID_CLASS_COLORS) do
	DATABASE_DEFAULTS.profile.colors.class[class] = { color.r, color.g, color.b }
end
for power_token, color in pairs(PowerBarColor) do
	if type(power_token) == "string" then
		DATABASE_DEFAULTS.profile.colors.power[power_token] = { color.r, color.g, color.b }
	end
end
for reaction, color in pairs(FACTION_BAR_COLORS) do
	DATABASE_DEFAULTS.profile.colors.reaction[reaction] = { color.r, color.g, color.b }
end

local UNITFRAME_STRATA = "MEDIUM"
local UNITFRAME_LEVEL = 1 -- minimum 1, since 0 needs to be available

local DEFAULT_GROUPS = {
	[L["Party"]] = {
		enabled = true,
		unit_group = "party",
	},
	[L["Party pets"]] = {
		enabled = true,
		unit_group = "partypet",
	},
}
-----------------------------------------------------------------------------

local _G = _G

local PitBull4 = LibStub("AceAddon-3.0"):NewAddon("PitBull4", "AceEvent-3.0", "AceTimer-3.0")
_G.PitBull4 = PitBull4

PitBull4.DEBUG = _G.PitBull4_DEBUG or false
_G.PitBull4_DEBUG = nil
local DEBUG = PitBull4.DEBUG

PitBull4.L = L

PitBull4.SINGLETON_CLASSIFICATIONS = SINGLETON_CLASSIFICATIONS
PitBull4.UNIT_GROUPS = UNIT_GROUPS
PitBull4.UNITFRAME_STRATA = UNITFRAME_STRATA
PitBull4.UNITFRAME_LEVEL = UNITFRAME_LEVEL

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

local function refresh_guid(unit)
	if not NORMAL_UNITS[unit] then
		return
	end
	
	local new_guid = UnitGUID(unit)
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
		if frame.best_unit == unit then
			frame:UpdateBestUnit()
		end
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
		error(("Bad argument #1 to `IterateFramesForUnitID'. %q is not a valid UnitID"):format(tostring(unit)), 2)
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
		if guid then
			expect(guid, 'match', '^0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$')
		end
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
			if guid then
				expect(guid, 'match', '^0x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$')
			end
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

local function name_iter(name, frame)
	frame = next(all_frames, frame)
	if not frame then
		return nil
	end
	if frame.guid and frame.unit and UnitName(frame.unit) == name then
		return frame
	end
	return name_iter(name, frame)
end

--- Iterate over all frames with the given name
-- @param name the name to check. can be nil, which will cause no frames to return.
-- @usage for frame in PitBull4:IterateFramesForName("Someguy") do
--     doSomethingWith(frame)
-- end
-- @return iterator which returns frames
function PitBull4:IterateFramesForName(name)
	if DEBUG then
		expect(name, 'typeof', 'string;nil')
	end

	if not name then
		return do_nothing
	end

	return name_iter, name, nil
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
	
	return not also_hidden and iterate_shown_frames or half_next, headers
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
		expect(super_unit_group, 'inset', 'party;raid')
	end
	
	local headers = rawget(super_unit_group_to_headers, super_unit_group)
	if not headers then
		return do_nothing
	end
	
	return not also_hidden and iterate_shown_frames or half_next, headers
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

-- Callback for when the main tank list updates from oRA or CTRA
local function main_tank_update()
	for header in PitBull4:IterateHeadersForSuperUnitGroup("raid") do
		local group_db = header.group_db
		if group_db and group_db.group_filter == "MAINTANK" then
			header:RefreshGroup()
		end
	end
end

function PitBull4:OnInitialize()
	db = LibStub("AceDB-3.0"):New("PitBull4DB", DATABASE_DEFAULTS, 'Default')
	DATABASE_DEFAULTS = nil
	self.db = db
	
	db.RegisterCallback(self, "OnProfileChanged")
	
	-- used for run-once-only initialization
	self:RegisterEvent("ADDON_LOADED")
	self:ADDON_LOADED()
	
	LoadAddOn("LibDataBroker-1.1")
	LoadAddOn("LibDBIcon-1.0")
end

function PitBull4:ADDON_LOADED()
	local LibDataBroker = LibStub("LibDataBroker-1.1", true)
	if LibDataBroker and not PitBull4.LibDataBrokerLauncher then
		PitBull4.LibDataBrokerLauncher = LibDataBroker:NewDataObject("PitBull4", {
			type = "launcher",
			icon = [[Interface\AddOns\PitBull4\pitbull]],
			OnClick = function(clickedframe, button)
				if button == "RightButton" then 
					PitBull4.db.profile.lock_movement = not PitBull4.db.profile.lock_movement
					LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
				else 
					return PitBull4.Options.OpenConfig() 
				end
			end,
			OnTooltipShow = function(tt)
				tt:AddLine(L["PitBull Unit Frames 4.0"])
				tt:AddLine("|cffffff00" .. L["%s|r to open the options menu"]:format(L["Click"]), 1, 1, 1)
				tt:AddLine("|cffffff00" .. L["%s|r to toggle frame lock"]:format(L["Right-click"]), 1, 1, 1)
			end,
		})
	end
	local LibDBIcon = LibDataBroker and LibStub("LibDBIcon-1.0", true)
	if not LibDBIcon then
		return
	end
	self:UnregisterEvent("ADDON_LOADED")
	
	if LibDBIcon and not IsAddOnLoaded("Broker2FuBar") then
		LibDBIcon:Register("PitBull4", PitBull4.LibDataBrokerLauncher, PitBull4.db.profile.minimap_icon)
	end

	if _G.CT_RAOptions_UpdateMTs then
		hooksecurefunc("CT_RAOptions_UpdateMTs",main_tank_update)
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
	self.ClassColors = PitBull4.db.profile.colors.class
	self.PowerColors = PitBull4.db.profile.colors.power
	self.ReactionColors = PitBull4.db.profile.colors.reaction
	
	-- Notify modules that the profile has changed.
	for _, module in PitBull4:IterateEnabledModules() do
		if module.OnProfileChanged then
			module:OnProfileChanged()
		end
	end

	local db = self.db
	
	if not db.profile.made_groups then
		db.profile.made_groups = true
		for name, data in pairs(DEFAULT_GROUPS) do
			local group_db = db.profile.groups[name]
			merge_onto(group_db, data)
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
	
	for frame in PitBull4:IterateFrames(true) do
		frame:RefreshLayout()
	end

	local state = self:GetState()
	for header in PitBull4:IterateHeaders(true) do
		if header.group_db then
			header:RefreshGroup(true)
		end
		header:UpdateShownState(state)
	end

	-- Make sure all frames and groups are made
	for unit, unit_db in pairs(db.profile.units) do
		if unit_db.enabled then
			self:MakeSingletonFrame(unit)
		else
			for frame in PitBull4:IterateFramesForClassification(unit, true) do
				frame:Deactivate()
			end
		end
	end
	for group, group_db in pairs(db.profile.groups) do
		if group_db.enabled then
			self:MakeGroupHeader(group)
		end
	end
	
	self:RecheckConfigMode()
	
	if not IsAddOnLoaded("Broker2FuBar") then
		LibStub("LibDBIcon-1.0"):Refresh("PitBull4", db.profile.minimap_icon)
	end
end

function PitBull4:OnEnable()
	self:ScheduleRepeatingTimer("CheckWackyFramesForGUIDUpdate", 0.15)
	
	-- register unit change events
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("PLAYER_FOCUS_CHANGED")
	self:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
	self:RegisterEvent("PLAYER_PET_CHANGED")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("UNIT_PET")
	
	self:RegisterEvent("UNIT_ENTERED_VEHICLE")
	self:RegisterEvent("UNIT_EXITED_VEHICLE")
	
	-- enter/leave combat for :RunOnLeaveCombat
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	
	self:RegisterEvent("RAID_ROSTER_UPDATE")
	self:RegisterEvent("PARTY_MEMBERS_CHANGED")

	if oRA then
		LibStub("AceEvent-2.0"):RegisterEvent("oRA_MainTankUpdate",main_tank_update)

		-- Workaround for the fact that oRA loads the MT list from SV's on load but doesn't
		-- bother to trigger an event.  oRA should get the SV file within 1 second of us loading.
		self:ScheduleTimer(main_tank_update, 1)
	end
	
	-- show initial frames
	self:OnProfileChanged()
	self:RAID_ROSTER_UPDATE()
end

--- Iterate over all wacky frames, and call their respective :UpdateGUID methods.
-- @usage PitBull4:CheckWackyFramesForGUIDUpdate()
function PitBull4:CheckWackyFramesForGUIDUpdate()
	for frame in self:IterateWackyFrames() do
		if frame.unit then
			frame:UpdateGUID(UnitGUID(frame.unit))
		end
	end
end

--- Check the GUID of the given UnitID and send that info to all frames for that UnitID
-- @param unit the UnitID to check
-- @usage PitBull4:CheckGUIDForUnitID("player")
function PitBull4:CheckGUIDForUnitID(unit)
	if not PitBull4.Utils.GetBestUnitID(unit) then
		-- for ids such as npctarget
		return
	end
	refresh_guid(unit)
	local guid = UnitGUID(unit)
	for frame in self:IterateFramesForUnitID(unit, true) do
		frame:UpdateGUID(guid)
	end
end

function PitBull4:PLAYER_TARGET_CHANGED() self:CheckGUIDForUnitID("target") end
function PitBull4:PLAYER_FOCUS_CHANGED() self:CheckGUIDForUnitID("focus") end
function PitBull4:UPDATE_MOUSEOVER_UNIT() self:CheckGUIDForUnitID("mouseover") end
function PitBull4:PLAYER_PET_CHANGED() self:CheckGUIDForUnitID("pet") end
function PitBull4:UNIT_TARGET(_, unit) self:CheckGUIDForUnitID(unit .. "target") end
function PitBull4:UNIT_PET(_, unit) self:CheckGUIDForUnitID(unit .. "pet") end

local tmp = {}
function PitBull4:UNIT_ENTERED_VEHICLE(_, unit)
	tmp[unit] = true
	tmp[PitBull4.Utils.GetBestUnitID(unit)] = true
	local pet = PitBull4.Utils.GetBestUnitID(unit .. "pet")
	tmp[unit .. "pet"] = true
	if pet then
		tmp[pet] = true
	end
	local non_pet = unit:gsub("pet", "")
	if non_pet == "" then
		non_pet = "player"
	end
	tmp[non_pet] = true
	for frame in self:IterateFrames(true) do
		if tmp[frame:GetAttribute("unit")] then
			local new_unit = SecureButton_GetModifiedUnit(frame, "LeftButton")
			local old_unit = frame.unit
			if old_unit ~= new_unit then
				frame.unit = new_unit
				if old_unit then
					PitBull4.unit_id_to_frames[old_unit][frame] = nil
					PitBull4.unit_id_to_frames_with_wacky[old_unit][frame] = nil
				end
				if new_unit then
					PitBull4.unit_id_to_frames[new_unit][frame] = true
					PitBull4.unit_id_to_frames_with_wacky[new_unit][frame] = true
				end
				frame:UpdateGUID(UnitGUID(new_unit), true)
			end
		end
	end
	wipe(tmp)
end
PitBull4.UNIT_EXITED_VEHICLE = PitBull4.UNIT_ENTERED_VEHICLE

local STATE
--- Get the current state that the player is in.
-- This will return one of "solo", "party", "raid10", "raid25", or "raid40".
-- Setting config mode does override this.
-- @usage local state = PitBull4:GetState()
-- @return the state of the player.
function PitBull4:GetState()
	return PitBull4.config_mode or STATE
end

local last_state = nil
function PitBull4:RAID_ROSTER_UPDATE()
	for unit in pairs(NORMAL_UNITS) do
		refresh_guid(unit)
	end
	
	local raid = GetNumRaidMembers()
	local party = GetNumPartyMembers()
	if raid > 0 then
		if raid > 25 then
			STATE = "raid40"
		elseif raid > 10 then
			STATE = "raid25"
		elseif raid <= 5 and party == raid - 1 then -- TODO: make it an option to have 5-man raids act as parties.
			STATE = "party"
		else
			STATE = "raid10"
		end
	elseif party > 0 then
		STATE = "party"
	else
		STATE = "solo"
	end
	
	local state = PitBull4:GetState()
	if last_state ~= state then
		last_state = state
		for header in PitBull4:IterateHeaders() do
			header:UpdateShownState(state)
		end
	end
end
PitBull4.RAID_ROSTER_UPDATE = PitBull4:OutOfCombatWrapper(PitBull4.RAID_ROSTER_UPDATE)
PitBull4.PARTY_MEMBERS_CHANGED = PitBull4.RAID_ROSTER_UPDATE

do
	local in_combat = false
	local in_lockdown = false
	local actions_to_perform = {}
	local pool = {}
	function PitBull4:PLAYER_REGEN_ENABLED()
		in_combat = false
		in_lockdown = false
		for i, t in ipairs(actions_to_perform) do
			t[1](unpack(t, 2, t.n+1))
			for k in pairs(t) do
				t[k] = nil
			end
			actions_to_perform[i] = nil
			pool[t] = true
		end
	end
	function PitBull4:PLAYER_REGEN_DISABLED()
		in_combat = true
	end
	--- Call a function if out of combat or schedule to run once combat ends.
	-- You can also pass in a table (or frame), method, and arguments.
	-- If current out of combat, the function provided will be called without delay.
	-- @param func function to call
	-- @param ... arguments to pass into func
	-- @usage PitBull4:RunOnLeaveCombat(someSecureFunction)
	-- @usage PitBull4:RunOnLeaveCombat(someSecureFunction, "player")
	-- @usage PitBull4:RunOnLeaveCombat(frame.SetAttribute, frame, "key", "value")
	-- @usage PitBull4:RunOnLeaveCombat(frame, 'SetAttribute', "key", "value")
	function PitBull4:RunOnLeaveCombat(func, ...)
		if DEBUG then
			expect(func, 'typeof', 'table;function')
			if type(func) == "table" then
				expect(func[(...)], 'typeof', 'function')
			end
		end
		if type(func) == "table" then
			return self:RunOnLeaveCombat(func[(...)], func, select(2, ...))
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
		
		t[1] = func
		local n = select('#', ...)
		t.n = n
		for i = 1, n do
			t[i+1] = select(i, ...)
		end
	end
end
