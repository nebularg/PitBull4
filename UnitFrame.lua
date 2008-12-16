--- A Unit Frame created by PitBull4
-- @class table
-- @name UnitFrame
-- @field is_singleton whether the Unit Frame is a singleton or member
-- @field classification the classification of the Unit Frame
-- @field classificationDB the database table for the Unit Frame's classification
-- @field layout the layout of the Unit Frame's classification
-- @field layoutDB the database table for the layout of the UnitFrame's classification
-- @field unitID the unitID of the Unit Frame. Can be nil.
-- @field guid the current GUID of the Unit Frame. Can be nil.
local UnitFrame = {}

local PitBull4_UnitFrame_DropDown = CreateFrame("Frame", "PitBull4_UnitFrame_DropDown", UIParent, "UIDropDownMenuTemplate")

local new, del = PitBull4.Utils.new, PitBull4.Utils.del

-- from a unit, figure out the proper menu and, if appropriate, the corresponding ID
local function figure_unit_menu(unit)
	if UnitIsUnit(unit, "player") then
		return "SELF"
	end
	
	if UnitIsUnit(unit, "vehicle") then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		return "VEHICLE"
	end
	
	if UnitIsUnit(unit, "pet") then
		return "PET"
	end
	
	if not UnitIsPlayer(unit) then
		return "RAID_TARGET_ICON"
	end
	
	local id = UnitInRaid(unit)
	if id then
		return "RAID_PLAYER", id
	end
	
	if UnitInParty(unit) then
		return "PARTY"
	end
	
	return "PLAYER"
end

local function f()
	local unit = PitBull4_UnitFrame_DropDown.unit
	if not unit then
		return
	end
	
	local menu, id = figure_unit_menu(unit)
	if menu then
		UnitPopup_ShowMenu(PitBull4_UnitFrame_DropDown, menu, unit, nil, id)
	end
end
UIDropDownMenu_Initialize(PitBull4_UnitFrame_DropDown, f, "MENU", nil)
function UnitFrame:menu(unit)
	PitBull4_UnitFrame_DropDown.unit = unit
	ToggleDropDownMenu(1, nil, PitBull4_UnitFrame_DropDown, "cursor")
end

local UnitFrame__scripts = {}
function UnitFrame__scripts:OnDragStart()
	self:StartMoving()
end

function UnitFrame__scripts:OnDragStop()
	self:StopMovingOrSizing()
	
	local x, y = self:GetCenter()
	x = x - GetScreenWidth()/2
	y = y - GetScreenHeight()/2
	
	self.classificationDB.position_x = x
	self.classificationDB.position_y = y
	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function UnitFrame__scripts:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(self.unitID)
	local r, g, b = GameTooltip_UnitColor(self.unitID)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
	
	PitBull4.RunFrameScriptHooks("OnEnter", self)
end

function UnitFrame__scripts:OnLeave()
	GameTooltip:Hide()
	
	PitBull4.RunFrameScriptHooks("OnLeave", self)
end

--- Add the proper functions and scripts to a SecureUnitButton
-- @param frame a Button which inherits from SecureUnitButton
-- @param isExampleFrame whether the button is an example frame, thus not a real unit frame
-- @usage PitBull4.ConvertIntoUnitFrame(frame)
function PitBull4.ConvertIntoUnitFrame(frame, isExampleFrame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	expect(frame, 'frametype', 'Button')
	expect(isExampleFrame, 'typeof', 'nil;boolean')
	--@end-alpha@
	
	for k, v in pairs(UnitFrame__scripts) do
		frame:SetScript(k, v)
	end
	
	for k, v in pairs(UnitFrame) do
		frame[k] = v
	end
	
	if not isExampleFrame then
		frame:SetMovable(true)
		frame:RegisterForDrag("LeftButton")
		frame:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp","Button4Up","Button5Up")
		frame:SetAttribute("*type1", "target")
		frame:SetAttribute("*type2", "menu")
	end
end

--- Update all details about the UnitFrame, possibly after a GUID change
-- @param sameGUID whether the previous GUID is the same as the current, at which point is less crucial to update
-- @usage frame:Update()
-- @usage frame:Update(true)
function UnitFrame:Update(sameGUID)
	-- TODO
	if not self.guid then
		PitBull4.RunFrameScriptHooks("OnClear", self)
		self.populated = nil
	end
	
	if not self.populated then
		PitBull4.RunFrameScriptHooks("OnPopulate", self)
		self.populated = true
	end
	
	PitBull4.RunFrameScriptHooks("OnUpdate", self)
	local changed = false
	for id, module in PitBull4.IterateModulesOfType("statusbar", true) do
		changed = module:Update(self, true) or changed
	end
	if changed then
		self:UpdateLayout()
	end
end

--- Check the guid of the Unit Frame, if it is changed, then update the frame.
-- @param guid result from UnitGUID(unitID)
-- @param forceUpdate force an update even if the guid isn't changed, but is non-nil
-- @usage frame:UpdateGUID(UnitGUID(frame.unitID))
-- @usage frame:UpdateGUID(UnitGUID(frame.unitID), true)
function UnitFrame:UpdateGUID(guid)
	--@alpha@
	expect(guid, 'typeof', 'string;nil')
	--@end-alpha@
	
	-- if the guids are the same, cut out, but don't if it's a wacky unit that has a guid.
	if self.guid == guid and not (guid and self.is_wacky) then
		return
	end
	local previousGUID = self.guid
	self.guid = guid
	self:Update(previousGUID == guid)
end

-- sort the bars in the order specified by the layout
local sort_bars
do
	local layoutDB
	local function helper(alpha, bravo)
		return layoutDB[alpha].position < layoutDB[bravo].position
	end

	function sort_bars(bars, frame)
		layoutDB = frame.layoutDB
		table.sort(bars, helper)
		layoutDB = nil
	end
end

local function filter_bars_for_side(layoutDB, bars, side)
	local side_bars = new()
	for _, id in ipairs(bars) do
		if layoutDB[id].side == side then
			side_bars[#side_bars+1] = id
		end
	end
	return side_bars
end

-- return a list of existing status bars on frame of the given side in the correct order
local function get_all_bars(frame)
	local bars = new()
	
	for id, module in PitBull4.IterateModulesOfType('statusbar', true) do
		if frame[id] then
			bars[#bars+1] = id
		end
	end
	
	sort_bars(bars, frame)
	
	return bars,
		filter_bars_for_side(frame.layoutDB, bars, 'center'),
		filter_bars_for_side(frame.layoutDB, bars, 'left'),
		filter_bars_for_side(frame.layoutDB, bars, 'right')
end

-- figure out the total width and height points for a frame based on its bars
local function calculate_width_height_points(layoutDB, center_bars, left_bars, right_bars)
	local bar_height_points = 0
	local bar_width_points = 0
	
	for _, id in ipairs(center_bars) do
		bar_height_points = bar_height_points + layoutDB[id].size
	end
	
	if #center_bars > 0 then
		-- the center takes up 10 width points if it exists
		bar_width_points = 10
	end
	
	for _, id in ipairs(left_bars) do
		bar_width_points = bar_width_points + layoutDB[id].size
	end
	for _, id in ipairs(right_bars) do
		bar_width_points = bar_width_points + layoutDB[id].size
	end
	
	return bar_width_points, bar_height_points
end

--- Reposition all controls on the Unit Frame
-- @usage frame:UpdateLayout()
function UnitFrame:UpdateLayout()
	local bars, center_bars, left_bars, right_bars = get_all_bars(self)
	
	local width, height = self:GetWidth(), self:GetHeight()
	
	local layoutDB = self.layoutDB
	
	local bar_width_points, bar_height_points = calculate_width_height_points(layoutDB, center_bars, left_bars, right_bars)
	
	local bar_height_per_point = height/bar_height_points
	local bar_width_per_point = width/bar_width_points
	
	local last_x = 0
	for _, id in ipairs(left_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
		
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", last_x, 0)
		local bar_width = layoutDB[id].size * bar_width_per_point
		last_x = last_x + bar_width
		bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", last_x, 0)
		
		bar:SetOrientation("VERTICAL")
	end
	local left = last_x
	
	last_x = 0
	for _, id in ipairs(right_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
		
		bar:SetPoint("TOPRIGHT", self, "TOPRIGHT", last_x, 0)
		local bar_width = layoutDB[id].size * bar_width_per_point
		last_x = last_x - bar_width
		bar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", last_x, 0)
		
		bar:SetOrientation("VERTICAL")
	end
	local right = last_x
	
	local last_y = 0
	for i, id in ipairs(center_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
		
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", left, last_y)
		local bar_height = layoutDB[id].size * bar_height_per_point
		last_y = last_y - bar_height
		bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", right, last_y)
		
		bar:SetOrientation("HORIZONTAL")
	end
	
	for _, id in ipairs(bars) do
		local bar = self[id]
		local bar_layoutDB = layoutDB[id]
		bar:SetReverse(bar_layoutDB.reverse)
		bar:SetDeficit(bar_layoutDB.deficit)
		bar:SetNormalAlpha(bar_layoutDB.alpha)
		bar:SetBackgroundAlpha(bar_layoutDB.bgAlpha)
	end
	
	bars = del(bars)
	center_bars = del(center_bars)
	left_bars = del(left_bars)
	right_bars = del(right_bars)
end

local function iter(frame, id)
	local func, t = PitBull4.IterateModules(true)
	local id, module = func(t, id)
	if id == nil then
		return nil
	end
	if not frame[id] then
		return iter(frame, id)
	end
	return id, frame[id], module
end

--- Iterate over all controls on this frame
-- @usage for id, control, module in PitBull4.IterateControls() do
--     doSomethingWith(control)
-- end
-- @return iterator which returns the id, control, and module
function UnitFrame:IterateControls()
	return iter, self, nil
end

local iters = setmetatable({}, {__index=function(iters, moduleType)
	local function iter(frame, id)
		local func, t = PitBull4.IterateModulesOfType(moduleType, true)
		local id, module = func(t, id)
		if id == nil then
			return nil
		end
		if not frame[id] then
			return iter(frame, id)
		end
		return id, frame[id], module
	end
	iters[moduleType] = iter
	return iter
end})

--- Iterate over all controls on this frame of the given type
-- @param moduleType one of "statusbar", "custom"
-- @usage for id, control, module in PitBull4.IterateControlsOfType("statusbar") do
--     doSomethingWith(control)
-- end
-- @return iterator which returns the id, control, and module
function UnitFrame:IterateControlsOfType(moduleType)
	return iters[moduleType], self, nil
end
