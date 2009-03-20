local _G = _G
local PitBull4 = _G.PitBull4

local MAX_PARTY_MEMBERS_WITH_PLAYER = MAX_PARTY_MEMBERS + 1
local NUM_CLASSES = 0
for _ in pairs(RAID_CLASS_COLORS) do
	NUM_CLASSES = NUM_CLASSES + 1
end
local MINIMUM_EXAMPLE_GROUP = 2

local ACCEPTABLE_STATES = {
	party = {
		solo = true,
		party = true,
		raid10 = true,
		raid25 = true,
		raid40 = true,
	},
	raid = {
		solo = false,
		party = false,
		raid10 = true,
		raid25 = true,
		raid40 = true,
	}
}

local CLASS_ORDER = { -- TODO: make this configurable
	"WARRIOR",
	"HUNTER",
	"ROGUE",
	"PALADIN",
	"SHAMAN",
	"PRIEST",
	"MAGE",
	"WARLOCK",
	"DRUID",
	"DEATHKNIGHT"
}
for class in pairs(RAID_CLASS_COLORS) do
	local found = false
	for i, v in ipairs(CLASS_ORDER) do
		if v == class then
			found = true
			break
		end
	end
	if not found then
		CLASS_ORDER[#CLASS_ORDER+1] = class
	end
end

--- Make a group header.
-- @param group the name for the group. Also acts as a unique identifier.
-- @usage local header = PitBull4:MakeGroupHeader("Monkey")
function PitBull4:MakeGroupHeader(group)
	--@alpha@
	expect(group, 'typeof', 'string')
	--@end-alpha@
	
	local header_name = "PitBull4_Groups_" .. group
	
	local header = _G[header_name]
	if not header then
		header = CreateFrame("Frame", header_name, UIParent, "SecureGroupHeaderTemplate")
		header:Hide() -- it will be shown later and attributes being set won't cause lag
		header:SetFrameStrata(PitBull4.UNITFRAME_STRATA)
		header:SetFrameLevel(PitBull4.UNITFRAME_LEVEL - 1)
		
		header.name = group
		
		local group_db = PitBull4.db.profile.groups[group]
		header.group_db = group_db
		
		self:ConvertIntoGroupHeader(header)
	end
	
	header:UpdateShownState(self:GetState())
end
PitBull4.MakeGroupHeader = PitBull4:OutOfCombatWrapper(PitBull4.MakeGroupHeader)

local GroupHeader = {}
PitBull4.GroupHeader = GroupHeader
local GroupHeader__scripts = {}
PitBull4.GroupHeader__scripts = GroupHeader__scripts

local MemberUnitFrame = PitBull4.MemberUnitFrame
local MemberUnitFrame__scripts = PitBull4.MemberUnitFrame__scripts

--- Force an update on the group header.
-- This is just a wrapper for SecureGroupHeader_Update.
-- @usage header:Update()
function GroupHeader:Update()
	SecureGroupHeader_Update(self)
end
GroupHeader.Update = PitBull4:OutOfCombatWrapper(GroupHeader.Update)

--- Send :Update to all member frames.
-- @args ... the arguments to send along with :Update
-- @usage header:UpdateMembers(true, true)
function GroupHeader:UpdateMembers(...)
	for _, frame in self:IterateMembers() do
		frame:Update(...)
	end
end

function GroupHeader:ProxySetAttribute(key, value)
	if self:GetAttribute(key) ~= value then
		self:SetAttribute(key, value)
	end
end

function GroupHeader:UpdateShownState(state)
	local group_db = self.group_db
	if not group_db then
		return
	end
	
	if group_db and group_db.enabled and group_db.show_when[state] and ACCEPTABLE_STATES[self.super_unit_group][state] and (state ~= "solo" or group_db.include_player) then
		self:Show()
	else
		self:Hide()
	end
end
GroupHeader.UpdateShownState = PitBull4:OutOfCombatWrapper(GroupHeader.UpdateShownState)

local DIRECTION_TO_POINT = {
	down_right = "TOP",
	down_left = "TOP",
	up_right = "BOTTOM",
	up_left = "BOTTOM",
	right_down = "LEFT",
	right_up = "LEFT",
	left_down = "RIGHT",
	left_up = "RIGHT",
}

local DIRECTION_TO_GROUP_ANCHOR_POINT = {
	down_right = "TOPLEFT",
	down_left = "TOPRIGHT",
	up_right = "BOTTOMLEFT",
	up_left = "BOTTOMRIGHT",
	right_down = "TOPLEFT",
	right_up = "BOTTOMLEFT",
	left_down = "TOPRIGHT",
	left_up = "BOTTOMRIGHT",
}

local DIRECTION_TO_COLUMN_ANCHOR_POINT = {
	down_right = "LEFT",
	down_left = "RIGHT",
	up_right = "LEFT",
	up_left = "RIGHT",
	right_down = "TOP",
	right_up = "BOTTOM",
	left_down = "TOP",
	left_up = "BOTTOM",
}

local DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER = {
	down_right = 1,
	down_left = -1,
	up_right = 1,
	up_left = -1,
	right_down = 1,
	right_up = 1,
	left_down = -1,
	left_up = -1,
}

local DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER = {
	down_right = -1,
	down_left = -1,
	up_right = 1,
	up_left = 1,
	right_down = -1,
	right_up = 1,
	left_down = -1,
	left_up = 1,
}

local GROUPING_ORDER = {}
do
	local t = {}
	for i = 1, NUM_RAID_GROUPS do
		t[i] = i..""
	end
	GROUPING_ORDER.GROUP = table.concat(t, ',')
end
GROUPING_ORDER.CLASS = table.concat(CLASS_ORDER, ",")

local function position_label(self, label)
	label:ClearAllPoints()
	local group_db = self.group_db
	if group_db.direction:match("down") then
		label:SetPoint("BOTTOM", self, "TOP", 0, group_db.vertical_spacing)
	else
		label:SetPoint("TOP", self, "BOTTOM", 0, -group_db.vertical_spacing)
	end
end

--- Reset the size and position of the group header.  More accurately,
-- the scale and the position since size is set dynamically.
-- @usage header:RefixSizeAndPosition()
function GroupHeader:RefixSizeAndPosition()
	local group_db = self.group_db
	local layout = group_db.layout
	local layout_db = PitBull4.db.profile.layouts[layout]
	
	self:SetScale(layout_db.scale * group_db.scale)

	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	local x_diff, y_diff = 0, 0
	local direction = group_db.direction
	local anchor = DIRECTION_TO_GROUP_ANCHOR_POINT[direction]
	local frame = self[1]

	if frame then
		x_diff = frame:GetWidth() / 2 * -DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[direction]
		y_diff = frame:GetHeight() / 2 * -DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[direction]
	end

	self:ClearAllPoints()
	self:SetPoint(anchor, UIParent, "CENTER", group_db.position_x / scale + x_diff, group_db.position_y / scale + y_diff)
end

--- Recheck the group-based settings of the group header, including sorting, position, what units are shown.
-- @param dont_refresh_children don't call :RefreshLayout on the child frames
-- @usage header:RefreshGroup()
function GroupHeader:RefreshGroup(dont_refresh_children)
	local group_db = self.group_db
	
	local layout = group_db.layout
	self.layout = layout
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	self.layout_db = layout_db
	
	for _, frame in self:IterateMembers() do
		frame.dont_update = true
	end
	
	local is_shown = self:IsShown()
	self:Hide()
	
	local force_show = self.force_show
	self:UnforceShow()
	
	local unit_group = group_db.unit_group
	local party_based = unit_group:sub(1, 5) == "party"
	local include_player = party_based and group_db.include_player
	local show_solo = include_player and group_db.show_when.solo
	local group_filter = not party_based and group_db.group_filter or nil
	local sort_direction = group_db.sort_direction
	local sort_method = group_db.sort_method
	local group_by = group_db.group_by
	
	local changed_units = self.unit_group ~= unit_group or self.include_player ~= include_player or self.show_solo ~= show_solo or self.group_filter ~= group_filter or self.sort_direction ~= sort_direction or self.sort_method ~= sort_method or self.group_by ~= group_by
	
	if changed_units then
		local old_unit_group = self.unit_group
		local old_super_unit_group = self.super_unit_group
		self.unit_group = unit_group
		self.include_player = include_player
		self.show_solo = show_solo
		self.group_filter = group_filter
		self.sort_direction = sort_direction
		self.sort_method = sort_method
		self.group_by = group_db.group_by
		--@alpha@
		if not party_based then
			expect(unit_group:sub(1, 4), '==', "raid")
		end
		--@end-alpha@
	
		if party_based then
			self.super_unit_group = "party"
			self.unitsuffix = unit_group:sub(6)
			self:ProxySetAttribute("showRaid", nil)
			self:ProxySetAttribute("showParty", true)
			self:ProxySetAttribute("showPlayer", include_player and true or nil)
			self:ProxySetAttribute("showSolo", show_solo and true or nil)
			self:ProxySetAttribute("groupFilter", nil)
		else
			self.super_unit_group = "raid"
			self.unitsuffix = unit_group:sub(5)
			self:ProxySetAttribute("showParty", nil)
			self:ProxySetAttribute("showPlayer", nil)
			self:ProxySetAttribute("showSolo", nil)
			self:ProxySetAttribute("showRaid", true)
			self:ProxySetAttribute("groupFilter", group_filter)
		end
		if self.unitsuffix == "" then
			self.unitsuffix = nil
		end
	
		self.is_wacky = PitBull4.Utils.IsWackyUnitGroup(unit_group)
		
		if old_unit_group then
			PitBull4.unit_group_to_headers[old_unit_group][self] = nil
			PitBull4.super_unit_group_to_headers[old_super_unit_group][self] = nil
		end
		
		for _, frame in self:IterateMembers() do
			frame:ProxySetAttribute("unitsuffix", self.unitsuffix)
		end
		PitBull4.unit_group_to_headers[unit_group][self] = true
		PitBull4.super_unit_group_to_headers[self.super_unit_group][self] = true
	end
	
	local direction = group_db.direction
	local point = DIRECTION_TO_POINT[direction]
	
	self:ProxySetAttribute("point", point)
	if point == "LEFT" or point == "RIGHT" then
		self:ProxySetAttribute("xOffset", group_db.horizontal_spacing * DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[direction])
		self:ProxySetAttribute("yOffset", 0)
		self:ProxySetAttribute("columnSpacing", group_db.vertical_spacing)
	else
		self:ProxySetAttribute("xOffset", 0)
		self:ProxySetAttribute("yOffset", group_db.vertical_spacing * DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[direction])
		self:ProxySetAttribute("columnSpacing", group_db.horizontal_spacing)
	end
	if self.label then
		position_label(self, self.label)
	end
	self:ProxySetAttribute("sortMethod", sort_method)
	self:ProxySetAttribute("sortDir", sort_direction)
	self:ProxySetAttribute("template", "SecureUnitButtonTemplate")
	self:ProxySetAttribute("templateType", "Button")
	self:ProxySetAttribute("groupBy", group_by)
	self:ProxySetAttribute("groupingOrder", GROUPING_ORDER[group_db.group_by])
	self:ProxySetAttribute("unitsPerColumn", group_db.units_per_column)
	self:ProxySetAttribute("maxColumns", self:GetMaxUnits())
	self:ProxySetAttribute("startingIndex", 1)
	self:ProxySetAttribute("columnAnchorPoint", DIRECTION_TO_COLUMN_ANCHOR_POINT[direction])
	self:ProxySetAttribute("useOwnerUnit", 1)
	
	self:ForceUnitFrameCreation()
	self:AssignFakeUnitIDs()

	self:RefixSizeAndPosition()
	
	if is_shown then
		self:Show()
	end

	if force_show then
		self:ForceShow()
	end
	
	for _, frame in self:IterateMembers() do
		frame.dont_update = nil
	end
	
	if changed_units and not dont_refresh_children then
		for _, frame in self:IterateMembers() do
			frame:RefreshLayout()
		end
	end
end
GroupHeader.RefreshGroup = PitBull4:OutOfCombatWrapper(GroupHeader.RefreshGroup)

--- Recheck the layout of the group header, refreshing the layout of all members.
-- @param dont_refresh_children don't call :RefreshLayout on the child frames
-- @usage header:RefreshLayout()
function GroupHeader:RefreshLayout(dont_refresh_children)
	self:RefixSizeAndPosition()

	if not dont_refresh_children then
		for _, frame in self:IterateMembers() do
			frame:RefreshLayout()
		end
	end
end
GroupHeader.RefreshLayout = PitBull4:OutOfCombatWrapper(GroupHeader.RefreshLayout)

--- Initialize a member frame. This should be called once per member frame immediately following the frame's creation.
-- @usage header:InitializeConfigFunction(frame)
function GroupHeader:InitialConfigFunction(frame)
	self[#self+1] = frame
	frame.header = self
	frame.is_singleton = false
	frame.classification = self.name
	frame.classification_db = self.group_db
	frame.is_wacky = self.is_wacky
	
	local layout = self.group_db.layout
	frame.layout = layout
	
	PitBull4:ConvertIntoUnitFrame(frame)
	
	if self.unitsuffix then
		frame:ProxySetAttribute("unitsuffix", self.unitsuffix)
	end
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	frame.layout_db = layout_db
	
	frame:ProxySetAttribute("initial-width", layout_db.size_x * self.group_db.size_x)
	frame:ProxySetAttribute("initial-height", layout_db.size_y * self.group_db.size_y)
	frame:ProxySetAttribute("initial-unitWatch", true)
	
	frame:RefreshLayout()
end

--- Force unit frames to be created on the group header, even if those units don't exist.
-- Note: this is a hack to get around a Blizzard bug preventing frames from being initialized properly while in combat.
-- @usage header:ForceUnitFrameCreation()
function GroupHeader:ForceUnitFrameCreation()
	local num = self:GetMaxUnits()
	
	local maxColumns = self:GetAttribute("maxColumns")
	local unitsPerColumn = self:GetAttribute("unitsPerColumn")
	local startingIndex = self:GetAttribute("startingIndex")

	if unitsPerColumn and num > unitsPerColumn then
		self:ProxySetAttribute("maxColumns", num / unitsPerColumn)
	else
		self:ProxySetAttribute("maxColumns", 1)
		self:ProxySetAttribute("unitsPerColumn", num)
	end
	self:ProxySetAttribute("startingIndex", -num + 1)
	
	SecureGroupHeader_Update(self)
	
	self:ProxySetAttribute("maxColumns", maxColumns)
	self:ProxySetAttribute("unitsPerColumn", unitsPerColumn)
	self:ProxySetAttribute("startingIndex", startingIndex)
	
	SecureGroupHeader_Update(self)
	
	-- this is done because the previous hack can mess up some unit references
	for _, frame in self:IterateMembers() do
		local unit = SecureButton_GetUnit(frame)
		if unit ~= frame.unit then
			frame.unit = unit
			frame:Update()
		end
	end
end
GroupHeader.ForceUnitFrameCreation = PitBull4:OutOfCombatWrapper(GroupHeader.ForceUnitFrameCreation)

local function hook_SecureGroupHeader_Update()
	hook_SecureGroupHeader_Update = nil
	hooksecurefunc("SecureGroupHeader_Update", function(self)
		if not PitBull4.all_headers[self] then
			return
		end
		if not self.force_show then
			return
		end
		self:AssignFakeUnitIDs()
		PitBull4:RecheckConfigMode()
	end)
end

-- utility function for AssignFakeUnitIDs
local function fill_table(tbl, ...)
	wipe(tbl)
	for i = 1, select('#', ...), 1 do
		local key = select(i, ...)
		key = tonumber(key) or key
		tbl[key] = true
	end
end

-- utility function for AssignFakeUnitIDs
local function double_fill_table(tbl, ...)
	fill_table(tbl, ...)
	for i = 1, select('#', ...), 1 do
		tbl[i] = select(i, ...)
	end
end

-- utility function for AssignFakeUnitIDs, it doctors
-- up some data so don't reuse this elsewhere
local function get_group_roster_info(super_unit_group, index, sort_dir, group_by)
	local unit, name, subgroup, class_name, role
	if super_unit_group == "raid" then
		unit = "raid"..index
		name, _, subgroup, _, _, class_name, _, _, _, role = GetRaidRosterInfo(index)
	else
		if index > 0 then
			unit = "party"..index
		else
			unit = "player"
		end
		if UnitExists(unit) then
			name = UnitName(unit)
			_, class_name = UnitClass(unit)
			if GetPartyAssignment("MAINTANK", unit) then
				role = "MAINTANK"
			elseif  GetPartyAssignment("MAINASSIST", unit) then
				role = "MAINASSIST"
			end
			subgroup = 1
		end
	end

	-- return some bogus data to get our fake unit ids to sort where we want.
	if not name then
		name = (sort_dir == "DESC" and "!" or "~")..string.format("%02d",index)
		subgroup = '!' 
		class_name = '!' 
	end

	return unit, name, subgroup, class_name, role
end

-- AssigneFakeUnitIDs generates a bunch of fake unit ids for 
-- frames being show in config mode.  It's largely a rework
-- of SecureGroupHeader_Update for our purposes.  We need
-- to generate unit ids in roughly the same order that the
-- group header would for real frames but we want the fake
-- units to always be after the real units.  Sadly that makes
-- this code pretty downright ugly.

local sorting_table = {}
local token_table = {}
local grouping_table = {}
local temp_table = {}
function GroupHeader:AssignFakeUnitIDs()
	if not self.force_show then
		return
	end

	wipe(sorting_table)
	
	local super_unit_group = self.super_unit_group
	local config_mode = PitBull4.config_mode
	local start, finish, step = 1, self:GetMaxUnits(), 1

	if self.include_player then
		-- start at 0 for the player
		start = 0
		finish = finish - 1 -- GetMaxUnits already accounts for include_player
	end

	-- Limit the number of frames to the config mode for raid
	if config_mode and config_mode:sub(1,4) == "raid" and super_unit_group == "raid" then
		local num = config_mode:sub(5)+0 -- raid10, raid25, raid40 => 10, 25, 40
		if num < finish then
			finish = num
		end
	end

	local name_list = self:GetAttribute("nameList")
	local group_filter = self:GetAttribute("groupFilter")
	local sort_method = self:GetAttribute("sortMethod")
	local group_by = self:GetAttribute("groupBy")
	local sort_dir = self:GetAttribute("sortDir")

	if not group_filter and not name_list then
		group_filter = "1,2,3,4,5,6,7,8"
	end

	-- Add in our bogus group to the appropriate
	-- place on the group_filter.
	if sort_dir == 'DESC' then
		group_filter = "!,"..group_filter
	else
		group_filter = group_filter..",!"
	end

	if group_filter then
		-- filter by a list of group numbers and/or classes
		fill_table(token_table, strsplit(",", group_filter))
		local strict_filter = self:GetAttribute("strictFiltering")

		for i = start, finish, 1 do
			local unit, name, subgroup, class_name, role = get_group_roster_info(super_unit_group, i, sort_dir, group_by)

			if name and (not strict_filtering 
				and (token_table[subgroup] or token_table[class_name] or (role and token_table[role]))) -- non-strict filtering
				or (token_table[subgroup] and token_table[class_name]) -- strict filtering
				then
				sorting_table[#sorting_table+1] = name
				sorting_table[name] = unit
				if group_by == "GROUP" then
					grouping_table[name] = subgroup
				elseif group_by == "CLASS" then
					grouping_table[name] = class_name
				elseif group_by == "ROLE" then
					grouping_table[name] = role
				end
			end
		end

		if group_by then
			local grouping_order = self:GetAttribute("groupingOrder")

			-- Add in our bogus group token onto the grouping_order
			-- in the right place to achieve the sorting we want
			if sort_dir == 'DESC' then
				grouping_order = "!,"..grouping_order
			else	
				grouping_order = grouping_order..',!'
			end

			double_fill_table(token_table, strsplit(",", grouping_order))
			wipe(temp_table)
			for _, grouping in ipairs(token_table) do
				grouping = tonumber(grouping) or grouping
				for k in ipairs(grouping_table) do
					grouping_table[k] = nil
				end
				for index, name in ipairs(sorting_table) do
					if grouping_table[name] == grouping then
						grouping_table[#grouping_table+1] = name
						temp_table[name] = true
					end
				end
				if sort_method == "NAME" then -- sort by ID by default
					sort(grouping_table)
				end
				for _, name in ipairs(grouping_table) do
					temp_table[#temp_table+1] = name
				end
			end
			-- hande units whose group didn't appear in groupingOrder
			wipe(grouping_table)
			for index, name in ipairs(sorting_table) do
				if not temp_table[name] then
					grouping_table[#grouping_table+1] = name
				end
			end
			if sort_method == "NAME" then -- sort by ID by default
				sort(grouping_table)
			end
			for _, name in ipairs(grouping_table) do
				temp_table[#temp_table+1] = name
			end

			-- copy the names back to sorting_table
			for index, name in ipairs(temp_table) do
				sorting_table[index] = name
			end
		elseif sort_method == "NAME" then -- sort by ID by default
			sort(sorting_table)
		else
			-- Have to do some reordering on ID DESC sort order
			-- since normally the fake ids would come first.
			wipe(temp_table)
			-- add in the fake units first so they end up at the end 
			for _, name in ipairs(sorting_table) do
				if name:sub(1,1) == "!" then
					temp_table[#temp_table+1] = name
				end
			end
			-- now the real units
			for _, name in ipairs(sorting_table) do
				if name:sub(1,1) ~= "!" then
					temp_table[#temp_table+1] = name
				end
			end
			-- copy back to sorting_table
			for index, name in ipairs(temp_table) do
				sorting_table[index] = name
			end
		end
	else
		-- filtering via a list of names
		double_fill_table(sorting_table, strsplit(",", name_list))
		for i = start, finish, 1 do
			local unit, name = get_group_roster_info(super_unit_group, i)
			if sorting_table[name] then
				sorting_table[name] = unit
			end
		end
		for i = #sorting_table, 1, -1 do
			local name = sorting_table[i]
			if sorting_table[name] == true then
				tremove(sorting_table, i)
			end
		end
		if sort_method == "NAME" then
			sort(sorting_table)
		end
	end

	-- setup to actually set the units on the frames.
	-- From here on out the code is roughly borrowed
	-- from configureChildren.  However, we shortcut
	-- startingIndex to always be 1.  If we ever
	-- configure the startingIndex to be something else
	-- this code will have to be adjusted.
	start, finish = 1, #sorting_table
	if sort_dir == "DESC" then
		start, finish, step = finish, start, -1
	end

	local frame_num = 0
	for i = start, finish, step do
		frame_num = frame_num + 1
		local frame = self[frame_num]

		if not frame.guid then
			local old_unit = frame:GetAttribute("unit")
			local unit = sorting_table[sorting_table[i]]
			frame:SetAttribute("unit", unit)
			if old_unit ~= unit then
				frame:Update()
			end
		--@alpha@
		-- Spit out errors to chat if our code didn't
		-- come up with the same unit ids for the real frames
		-- that the group header did.
		else
			local unit = frame:GetAttribute("unit")
			local expected_unit = sorting_table[sorting_table[i]]
			if unit ~= expected_unit then
				print("PitBull4 expected "..tostring(expected_unit).." but found "..tostring(unit).." for "..frame:GetName())
			end
		--@end-alpha@
		end
	end
end
GroupHeader.AssignFakeUnitIDs = PitBull4:OutOfCombatWrapper(GroupHeader.AssignFakeUnitIDs)

local ipairs_upto_num
do
	local ipairs_helpers = setmetatable({}, {__index=function(self, num)
		local f = function(t, i)
			i = i + 1
			if i > num then
				return nil
			end
			
			local v = t[i]
			if v == nil then
				return nil
			end
			
			return i, v
		end
		self[num] = f
		return f
	end})
	function ipairs_upto_num(t, num)
		return ipairs_helpers[num], t, 0
	end
end

local function get_filter_type_count(...) 
	local start = select(1, ...)
	return tonumber(start) and true or false, select('#', ...)
end

function GroupHeader:GetMaxUnits()
	if self.super_unit_group == "raid" then
		local group_filter = self.group_db.group_filter
		if group_filter then
			if group_filter == "" then
			-- Everything filtered, but always have at least one unit
				return 1 
			end

			-- If we're filtering by raid group we may not need all 40
			-- units for this group header.
			local by_raid_group,count = get_filter_type_count(strsplit(",",group_filter))
			if by_raid_group then
				return MEMBERS_PER_RAID_GROUP * count
			end
		end

		-- Everything else we're gonna have to go by max.
		return MAX_RAID_MEMBERS
	else
		if self.include_player then
			return MAX_PARTY_MEMBERS_WITH_PLAYER
		else
			return MAX_PARTY_MEMBERS
		end
	end
end

local make_set
do
	local set = {}
	function make_set(...)
		wipe(set)
		local n = select('#', ...)
		for i = 1, n do
			set[select(i, ...)] = true
		end
		
		return set, n
	end
end

function GroupHeader:IterateMembers(guess_num)
	local max_units = self:GetMaxUnits()
	local num
	if guess_num then
		local config_mode = PitBull4.config_mode
		if config_mode == "solo" then
			num = self.include_player and 1 or 0
		elseif config_mode == "party" then
			num = self.include_player and MAX_PARTY_MEMBERS_WITH_PLAYER or MAX_PARTY_MEMBERS
		else
			num = config_mode:sub(5)+0 -- raid10, raid25, raid40 => 10, 25, 40
			-- check filters
			
			local filter = self.group_filter
			if not filter then
				-- do nothing, all is shown
			elseif filter == "" then
				-- all is hidden for some reason
				num = 0
			else
				local set, count = make_set((","):split(filter))
				local start = next(set)
				if start == "MAINTANK" or start == "MAINASSIST" then
					num = MINIMUM_EXAMPLE_GROUP
				elseif RAID_CLASS_COLORS[start] then
					num = math.ceil(num * count / NUM_CLASSES)
					if num < MINIMUM_EXAMPLE_GROUP then
						num = MINIMUM_EXAMPLE_GROUP
					end
				elseif tonumber(start) then
					local count = 0
					for i = 1, num / MEMBERS_PER_RAID_GROUP do
						if set[i..""] then
							count = count + 1
						end
					end
					num = count * MEMBERS_PER_RAID_GROUP
				end
			end
		end
	end
	
	if not num or num > max_units then
		num = max_units
	end
	return ipairs_upto_num(self, num)
end

function GroupHeader:ForceShow()
	if not self.force_show then
		if hook_SecureGroupHeader_Update then
			hook_SecureGroupHeader_Update()
		end
		self.force_show = true
		self:AssignFakeUnitIDs()
		if not self.label then
			local label = self:CreateFontString(self:GetName() .. "_Label", "OVERLAY", "ChatFontNormal")
			self.label = label
			local font, size, modifier = label:GetFont()
			label:SetFont(font, size * 1.5, modifier)
			label:SetText(self.name)
			position_label(self, label)
		end
		self.label:Show()
	end

	-- Always make sure that the members ForceShow() is called
	for _, frame in self:IterateMembers(true) do
		frame:ForceShow()
		frame:Update(true, true)
	end
end
GroupHeader.ForceShow = PitBull4:OutOfCombatWrapper(GroupHeader.ForceShow)

function GroupHeader:UnforceShow()
	if not self.force_show then
		return
	end
	self.force_show = nil
	self.label:Hide()
	for _, frame in ipairs(self) do
		frame:UnforceShow()
		frame:Update(true, true)
	end
end
GroupHeader.UnforceShow = PitBull4:OutOfCombatWrapper(GroupHeader.UnforceShow)

function GroupHeader:Rename(name)
	if self.name == name then
		return
	end
	
	local old_header_name = "PitBull4_Groups_" .. self.name
	local new_header_name = "PitBull4_Groups_" .. name
	
	PitBull4.name_to_header[self.name] = nil
	PitBull4.name_to_header[name] = self
	_G[old_header_name] = nil
	_G[new_header_name] = self
	self.name = name
	if self.label then
		self.label:SetText(name)
	end
	
	for i, frame in ipairs(self) do
		frame.classification = name
	end
end

local moving_frame = nil
function MemberUnitFrame__scripts:OnDragStart()
	if PitBull4.db.profile.lock_movement or InCombatLockdown() then
		return
	end
	
	moving_frame = self
	LibStub("LibSimpleSticky-1.0"):StartMoving(self.header, PitBull4.all_frames_list, 0, 0, 0, 0)
end

function MemberUnitFrame__scripts:OnDragStop()
	if not moving_frame then return end
	moving_frame = nil
	local header = self.header
	LibStub("LibSimpleSticky-1.0"):StopMoving(header)
	
	local ui_scale = UIParent:GetEffectiveScale()
	local scale = header[1]:GetEffectiveScale() / ui_scale
	
	local x, y = header[1]:GetCenter()
	x, y = x * scale, y * scale
	
	x = x - GetScreenWidth()/2
	y = y - GetScreenHeight()/2
	
	header.group_db.position_x = x
	header.group_db.position_y = y
	
	LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
	
	header:RefreshLayout(true)
end

function MemberUnitFrame__scripts:OnMouseUp(button)
	if button == "LeftButton" then
		return MemberUnitFrame__scripts.OnDragStop(self)
	end
end

LibStub("AceEvent-3.0").RegisterEvent("PitBull4-MemberUnitFrame:OnDragStop", "PLAYER_REGEN_DISABLED", function()
	if moving_frame then
		MemberUnitFrame__scripts.OnDragStop(moving_frame)
	end
end)

--- Reset the size of the unit frame, not position as that is handled through the group header.
-- @usage frame:RefixSizeAndPosition()
function MemberUnitFrame:RefixSizeAndPosition()
	local layout_db = self.layout_db
	local classification_db = self.classification_db
	
	self:SetWidth(layout_db.size_x * classification_db.size_x)
	self:SetHeight(layout_db.size_y * classification_db.size_y)
end
MemberUnitFrame.RefixSizeAndPosition = PitBull4:OutOfCombatWrapper(MemberUnitFrame.RefixSizeAndPosition)

--- Add the proper functions and scripts to a SecureGroupHeaderTemplate or SecureGroupPetHeaderTemplate, as well as some initialization.
-- @param frame a Frame which inherits from SecureGroupHeaderTemplate or SecureGroupPetHeaderTemplate
-- @usage PitBull4:ConvertIntoGroupHeader(header)
function PitBull4:ConvertIntoGroupHeader(header)
	--@alpha@
	expect(header, 'typeof', 'frame')
	expect(header, 'frametype', 'Frame')
	--@end-alpha@
	
	self.all_headers[header] = true
	self.name_to_header[header.name] = header
	
	for k, v in pairs(GroupHeader__scripts) do
		header:SetScript(k, v)
	end
	
	for k, v in pairs(GroupHeader) do
		header[k] = v
	end
	
	-- this is done to pass self in properly
	function header.initialConfigFunction(...)
		return header:InitialConfigFunction(...)
	end
	
	header:RefreshGroup()
	
	header:SetMovable(true)
	
	header:ForceUnitFrameCreation()
end
