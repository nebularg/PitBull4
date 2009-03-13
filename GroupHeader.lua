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
	
	if group_db and group_db.enabled and group_db.show_when[state] and ACCEPTABLE_STATES[self.super_unit_group][state] then
		self:Show()
	else
		self:Hide()
	end
end

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
	
	local changed_units = self.unit_group ~= unit_group or self.include_player ~= include_player or self.show_solo ~= show_solo or self.group_filter ~= group_filter
	
	if changed_units then
		local old_unit_group = self.unit_group
		local old_super_unit_group = self.super_unit_group
		self.unit_group = unit_group
		self.include_player = include_player
		self.show_solo = show_solo
		self.group_filter = group_filter
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
	
	self:SetScale(layout_db.scale * group_db.scale)
	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	
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
	self:ProxySetAttribute("sortMethod", group_db.sort_method)
	self:ProxySetAttribute("sortDir", group_db.sort_direction)
	self:ProxySetAttribute("template", "SecureUnitButtonTemplate")
	self:ProxySetAttribute("templateType", "Button")
	self:ProxySetAttribute("groupBy", group_db.group_by)
	self:ProxySetAttribute("groupingOrder", GROUPING_ORDER[group_db.group_by])
	self:ProxySetAttribute("unitsPerColumn", group_db.units_per_column)
	self:ProxySetAttribute("maxColumns", self:GetMaxUnits())
	self:ProxySetAttribute("startingIndex", 1)
	self:ProxySetAttribute("columnAnchorPoint", DIRECTION_TO_COLUMN_ANCHOR_POINT[direction])
	self:ProxySetAttribute("useOwnerUnit", 1)
	
	self:ForceUnitFrameCreation()
	self:AssignFakeUnitIDs()
	
	self:ClearAllPoints()
	
	local x_diff, y_diff = 0, 0
	local frame = self[1]
	if frame then
		if point == "TOP" then
			y_diff = frame:GetHeight() / 2
		elseif point == "BOTTOM" then
			y_diff = -frame:GetHeight() / 2
		elseif point == "LEFT" then
			x_diff = -frame:GetWidth() / 2
		elseif point == "RIGHT" then
			x_diff = frame:GetWidth() / 2
		end
	end
	self:SetPoint(point, UIParent, "CENTER", group_db.position_x / scale + x_diff, group_db.position_y / scale + y_diff)
	
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
	local group_db = self.group_db

	local layout = group_db.layout
	self.layout = layout
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	self.layout_db = layout_db
	
	self:SetScale(layout_db.scale * group_db.scale)
	
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

--- Force num unit frames to be created on the group header, even if those units don't exist.
-- Note: this is a hack to get around a Blizzard bug preventing frames from being initialized properly while in combat.
-- @usage header:ForceUnitFrameCreation()
function GroupHeader:ForceUnitFrameCreation()
	local num = self:GetMaxUnits()
	for _, frame in self:IterateMembers() do
		if frame:GetAttribute("unit") and UnitExists(frame:GetAttribute("unit")) then
			num = num - 1
		end
	end
	
	local maxColumns = self:GetAttribute("maxColumns")
	local unitsPerColumn = self:GetAttribute("unitsPerColumn")
	local startingIndex = self:GetAttribute("startingIndex")
	if maxColumns == nil then
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
		self:AssignFakeUnitIDs()
	end)
end

function GroupHeader:AssignFakeUnitIDs()
	if not self.force_show then
		return
	end

	local super_unit_group = self.super_unit_group
	
	local current_group_num = 0
	
	local start, finish, step = 1, #self, 1
	
	if self:GetAttribute("sortDir") == "DESC" then
		start, finish, step = finish, start, -1
	end
	
	for i = start, finish, step do
		local frame = self[i]
		
		if not frame.guid then
			local old_unit = frame:GetAttribute("unit")
			local unit
			
			if self.include_player and i == start then
				unit = "player"
			else
				repeat
					current_group_num = current_group_num + 1
					unit = super_unit_group .. current_group_num
				until not UnitExists(unit)
			end
			
			if old_unit ~= unit then
				frame:SetAttribute("unit", unit)
				frame:Update()
			end
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

function GroupHeader:GetMaxUnits()
	if self.super_unit_group == "raid" then
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
