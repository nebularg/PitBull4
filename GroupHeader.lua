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

--- Recheck the layout of the group header, including sorting, position, what units are shown, and refreshing the layout of all members.
-- @usage header:RefreshLayout()
function GroupHeader:RefreshLayout()
	local classification_db = self.classification_db

	local layout = classification_db.layout
	self.layout = layout
	
	local layout_db = PitBull4.db.profile.layouts[layout]
	
	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	self:SetPoint("CENTER", UIParent, "CENTER", classification_db.position_x / scale, classification_db.position_y / scale)
	
	self:SetAttribute("xOffset", 0)
	self:SetAttribute("yOffset", 0)
	self:SetAttribute("sortMethod", "INDEX") -- or "NAME"
	self:SetAttribute("sortDir", "ASC") -- or "DESC"
	self:SetAttribute("template", "SecureUnitButtonTemplate")
	self:SetAttribute("templateType", "Button")
	self:SetAttribute("groupBy", nil) -- or "GROUP", "CLASS", "ROLE"
	self:SetAttribute("groupingOrder", "1,2,3,4,5,6,7,8")
	self:SetAttribute("maxColumns", 1)
	self:SetAttribute("unitsPerColumn", nil)
	self:SetAttribute("startingIndex", 1)
	self:SetAttribute("columnSpacing", 0)
	self:SetAttribute("columnAnchorPoint", "LEFT") -- or "RIGHT", but all directions apparently work
	
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
		if frame:GetAttribute("unit") then
			num = num - 1
		end
	end
	
	local maxColumns = self:GetAttribute("maxColumns")
	local unitsPerColumn = self:GetAttribute("unitsPerColumn")
	local startingIndex = self:GetAttribute("startingIndex")
	if maxColumns ~= nil then
		self:SetAttribute("unitsPerColumn", math.ceil(num / maxColumns))
	else
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

function MemberUnitFrame__scripts:OnDragStart()
	return self.header:StartMoving()
end

function MemberUnitFrame__scripts:OnDragStop()
	local header = self.header
	header:StopMovingOrSizing()
	
	local ui_scale = UIParent:GetEffectiveScale()
	local scale = header:GetEffectiveScale() / ui_scale
	
	local x, y = header:GetCenter()
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
