local _G = _G
local PitBull4 = _G.PitBull4

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

UNITS_PER_COLUMN = 2
MAX_COLUMNS = 2
--- Recheck the layout of the group header, including sorting, position, what units are shown, and refreshing the layout of all members.
-- @usage header:RefreshLayout()
function GroupHeader:RefreshLayout()
	local classification_db = self.classification_db
	local super_classification_db = self.super_classification_db

	local layout = classification_db.layout
	self.layout = layout
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	
	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	
	local direction = classification_db.direction
	local point = DIRECTION_TO_POINT[direction]
	
	self:SetAttribute("point", point)
	if point == "LEFT" or point == "RIGHT" then
		self:SetAttribute("xOffset", classification_db.horizontal_spacing * DIRECTION_TO_HORIZONTAL_SPACING_MULTIPLIER[direction])
		self:SetAttribute("yOffset", 0)
		self:SetAttribute("columnSpacing", classification_db.vertical_spacing)
	else
		self:SetAttribute("xOffset", 0)
		self:SetAttribute("yOffset", classification_db.vertical_spacing * DIRECTION_TO_VERTICAL_SPACING_MULTIPLIER[direction])
		self:SetAttribute("columnSpacing", classification_db.horizontal_spacing)
	end
	self:SetAttribute("sortMethod", super_classification_db.sort_method)
	self:SetAttribute("sortDir", super_classification_db.sort_direction)
	self:SetAttribute("template", "SecureUnitButtonTemplate")
	self:SetAttribute("templateType", "Button")
	self:SetAttribute("groupBy", nil) -- or "GROUP", "CLASS", "ROLE"
	self:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
	self:SetAttribute("unitsPerColumn", classification_db.units_per_column)
	self:SetAttribute("maxColumns", MAX_RAID_MEMBERS)
	self:SetAttribute("startingIndex", 1)
	self:SetAttribute("columnAnchorPoint", DIRECTION_TO_COLUMN_ANCHOR_POINT[direction])
	
	self:ForceUnitFrameCreation(#self)
	self:AssignFakeUnitIDs()
	
	self:ClearAllPoints()
	
	local x_diff, y_diff = 0, 0
	if point == "TOP" then
		y_diff = self[1]:GetHeight() / 2
	elseif point == "BOTTOM" then
		y_diff = -self[1]:GetHeight() / 2
	elseif point == "LEFT" then
		x_diff = -self[1]:GetWidth() / 2
	elseif point == "RIGHT" then
		x_diff = self[1]:GetWidth() / 2
	end
	self:SetPoint(point, UIParent, "CENTER", classification_db.position_x / scale + x_diff, (classification_db.position_y + y_diff) / scale)
	
	for i, frame in ipairs(self) do
		frame:RefreshLayout()
	end
end
GroupHeader.RefreshLayout = PitBull4:OutOfCombatWrapper(GroupHeader.RefreshLayout)

--- Initialize a member frame. This should be called once per member frame immediately following the frame's creation.
-- @usage header:InitializeConfigFunction(frame)
function GroupHeader:InitialConfigFunction(frame)
	self[#self+1] = frame
	frame.header = self
	frame.is_singleton = false
	frame.classification = self.classification
	frame.classification_db = self.classification_db
	frame.is_wacky = self.is_wacky
	
	if self.unitsuffix then
		frame:SetAttribute("unitsuffix", self.unitsuffix)
	end
	
	local layout = self.classification_db.layout
	frame.layout = layout
	
	PitBull4:ConvertIntoUnitFrame(frame)
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	
	frame:SetAttribute("initial-width", layout_db.size_x * self.classification_db.size_x)
	frame:SetAttribute("initial-height", layout_db.size_y * self.classification_db.size_y)
	frame:SetAttribute("initial-unitWatch", true)
	
	frame:RefreshLayout()
end

--- Force num unit frames to be created on the group header, even if those units don't exist.
-- Note: this is a hack to get around a Blizzard bug preventing frames from being initialized properly while in combat.
-- @param num the total amount of unit frames that should exist after calling.
-- @usage header:ForceUnitFrameCreation(4)
function GroupHeader:ForceUnitFrameCreation(num)
	for _, frame in ipairs(self) do
		if frame:GetAttribute("unit") and UnitExists(frame:GetAttribute("unit")) then
			num = num - 1
		end
	end
	
	local maxColumns = self:GetAttribute("maxColumns")
	local unitsPerColumn = self:GetAttribute("unitsPerColumn")
	local startingIndex = self:GetAttribute("startingIndex")
	if maxColumns == nil then
		self:SetAttribute("maxColumns", 1)
		self:SetAttribute("unitsPerColumn", num)
	end
	self:SetAttribute("startingIndex", -num + 1)
	
	SecureGroupHeader_Update(self)
	
	self:SetAttribute("maxColumns", maxColumns)
	self:SetAttribute("unitsPerColumn", unitsPerColumn)
	self:SetAttribute("startingIndex", startingIndex)
	
	SecureGroupHeader_Update(self)
	
	-- this is done because the previous hack can mess up some unit references
	for i, frame in ipairs(self) do
		frame.unit = SecureButton_GetUnit(frame)
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
	
	local current_group_num = 0
	
	local start, finish, step = 1, #self, 1
	
	if self:GetAttribute("sortDir") == "DESC" then
		start, finish, step = finish, start, -1
	end
	
	for i = start, finish, step do
		local frame = self[i]
		
		if not frame.guid then
			repeat
				current_group_num = current_group_num + 1
			until not UnitExists("party" .. current_group_num)
			
			frame:SetAttribute("unit", "party" .. current_group_num)
		end
	end
end
GroupHeader.AssignFakeUnitIDs = PitBull4:OutOfCombatWrapper(GroupHeader.AssignFakeUnitIDs)

function GroupHeader:ForceShow()
	if self.force_show then
		return
	end
	if hook_SecureGroupHeader_Update then
		hook_SecureGroupHeader_Update()
	end
	self.force_show = true
	self:AssignFakeUnitIDs()
	for _, frame in ipairs(self) do
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
	for _, frame in ipairs(self) do
		frame:UnforceShow()
		frame:Update(true, true)
	end
end
GroupHeader.UnforceShow = PitBull4:OutOfCombatWrapper(GroupHeader.UnforceShow)

function MemberUnitFrame__scripts:OnDragStart()
	if PitBull4.db.profile.lock_movement then
		return
	end
	return self.header:StartMoving()
end

function MemberUnitFrame__scripts:OnDragStop()
	local header = self.header
	header:StopMovingOrSizing()
	
	local ui_scale = UIParent:GetEffectiveScale()
	local scale = header[1]:GetEffectiveScale() / ui_scale
	
	local x, y = header[1]:GetCenter()
	x, y = x * scale, y * scale
	
	x = x - GetScreenWidth()/2
	y = y - GetScreenHeight()/2
	
	header.classification_db.position_x = x
	header.classification_db.position_y = y
	
	LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
	
	header:RefreshLayout()
end

--- Reset the size of the unit frame, not position as that is handled through the group header.
-- @usage frame:RefixSizeAndPosition()
function MemberUnitFrame:RefixSizeAndPosition()
	local layout_db = PitBull4.db.profile.layouts[self.layout]
	
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
	self.classification_to_headers[header.classification][header] = true
	self.super_classification_to_headers[header.super_classification][header] = true
	
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
	
	header:RefreshLayout()
	
	header:SetMovable(true)
end
