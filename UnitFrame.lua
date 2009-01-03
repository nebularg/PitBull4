local _G = _G
local PitBull4 = _G.PitBull4

-- CONSTANTS ----------------------------------------------------------------

-- size in pixels of indicators at 100% scaled
local INDICATOR_SIZE = 15

-- how many width points the center bars take up if at least one exists
local CENTER_WIDTH_POINTS = 10

-- how far in pixels that indicators are spaced away from the frame if set to Outside, something
local INDICATOR_OUT_ROOT_MARGIN = 5

-- how far into the frame from the sides for something like Outside, Left-Above
local INDICATOR_OUT_ROOT_BORDER = 2

-- how far in pixels that indicators are vertically spaced away from the edge of the frame if set to Inside, something
local INDICATOR_IN_ROOT_VERTICAL_MARGIN = 5

-- how far in pixels that indicators are horizontally spaced away from the edge of the frame if set to Inside, something
local INDICATOR_IN_ROOT_HORIZONTAL_MARGIN = 2

-- how far in pixels that indicators are horizontally placed inside bars if they are not set to Outside, Left or Right
local INDICATOR_BAR_INSIDE_HORIZONTAL_SPACING = 3

-- how far in pixels that indicators are vertically placed inside bars if they are not set to Outside, Left or Right
local INDICATOR_BAR_INSIDE_VERTICAL_SPACING = 3

-- how far in pixels that indicators are placed outside bars if they are set to Outside, Left or Right
local INDICATOR_BAR_OUTSIDE_SPACING = 3

-- how many pixels between adjacent indicators
local INDICATOR_SPACING_BETWEEN = 3

-- how many pixels wide to assume a text is
local ASSUMED_TEXT_WIDTH = 40

local MODULE_UPDATE_ORDER = {
	"status_bar",
	"icon",
	"custom_indicator",
	"text_provider",
	"custom_text",
	"custom",
	"fader",
}

-----------------------------------------------------------------------------

--- A Unit Frame created by PitBull4
-- @class table
-- @name UnitFrame
-- @field is_singleton whether the Unit Frame is a singleton or member
-- @field classification the classification of the Unit Frame
-- @field classification_db the database table for the Unit Frame's classification
-- @field layout the layout of the Unit Frame's classification
-- @field unit the UnitID of the Unit Frame. Can be nil.
-- @field guid the current GUID of the Unit Frame. Can be nil.
-- @field overlay an overlay frame for texts to be placed on.
local UnitFrame = {}
local SingletonUnitFrame = {}
local MemberUnitFrame = {}
PitBull4.UnitFrame = UnitFrame
PitBull4.SingletonUnitFrame = SingletonUnitFrame
PitBull4.MemberUnitFrame = MemberUnitFrame

local UnitFrame__scripts = {}
local SingletonUnitFrame__scripts = {}
local MemberUnitFrame__scripts = {}
PitBull4.UnitFrame__scripts = UnitFrame__scripts
PitBull4.SingletonUnitFrame__scripts = SingletonUnitFrame__scripts
PitBull4.MemberUnitFrame__scripts = MemberUnitFrame__scripts

local PitBull4_UnitFrame_DropDown = CreateFrame("Frame", "PitBull4_UnitFrame_DropDown", UIParent, "UIDropDownMenuTemplate")

local new, del = PitBull4.new, PitBull4.del

local ipairs_with_del
do
	local function iter(t, current)
		current = current + 1
		
		local value = t[current]
		if value == nil then
			del(t)
			return nil
		end
		
		return current, value
	end
	function ipairs_with_del(t)
		return iter, t, 0
	end
end

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

function SingletonUnitFrame__scripts:OnDragStart()
	self:StartMoving()
end

function SingletonUnitFrame__scripts:OnDragStop()
	self:StopMovingOrSizing()
	
	local ui_scale = UIParent:GetEffectiveScale()
	local scale = self:GetEffectiveScale() / ui_scale
	
	local x, y = self:GetCenter()
	x, y = x * scale, y * scale
	
	x = x - GetScreenWidth()/2
	y = y - GetScreenHeight()/2
	
	self.classification_db.position_x = x
	self.classification_db.position_y = y
	
	self:RefreshLayout()
end

function UnitFrame__scripts:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(self.unit)
	local r, g, b = GameTooltip_UnitColor(self.unit)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
	
	PitBull4:RunFrameScriptHooks("OnEnter", self)
end

function UnitFrame__scripts:OnLeave()
	GameTooltip:Hide()
	
	PitBull4:RunFrameScriptHooks("OnLeave", self)
end

function UnitFrame__scripts:OnAttributeChanged(key, value)
	if key ~= "unit" and key ~= "unitsuffix" then
		return
	end
	
	local new_unit = PitBull4.Utils.GetBestUnitID(SecureButton_GetUnit(self)) or nil
	
	local old_unit = self.unit
	if old_unit == new_unit then
		return
	end
	
	if old_unit then
		PitBull4.unit_id_to_frames[old_unit][self] = nil
	end
	
	self.unit = new_unit
	if value then
		PitBull4.unit_id_to_frames[new_unit][self] = true
	end
end

function UnitFrame__scripts:OnShow()
	if self.unit then
		local guid = UnitGUID(self.unit)
		if self.is_wacky or guid ~= self.guid then
			self:UpdateGUID(guid)
		end
	end
	
	self:SetAlpha(PitBull4:GetFinalFrameOpacity(self))
end

function UnitFrame__scripts:OnHide()
	self:UpdateGUID(nil)
end

--- Add the proper functions and scripts to a SecureUnitButton, as well as some various initialization.
-- @param frame a Button which inherits from SecureUnitButton
-- @param isExampleFrame whether the button is an example frame, thus not a real unit frame
-- @usage PitBull4:ConvertIntoUnitFrame(frame)
function PitBull4:ConvertIntoUnitFrame(frame, isExampleFrame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	expect(frame, 'frametype', 'Button')
	expect(isExampleFrame, 'typeof', 'nil;boolean')
	--@end-alpha@
	
	self.all_frames[frame] = true
	_G.ClickCastFrames[frame] = true
	
	self.classification_to_frames[frame.classification][frame] = true
	
	if frame.is_wacky then
		self.wacky_frames[frame] = true
	else
		self.non_wacky_frames[frame] = true
	end
	
	local overlay = PitBull4.Controls.MakeFrame(frame)
	frame.overlay = overlay
	overlay:SetFrameLevel(frame:GetFrameLevel() + 4)
	
	for k, v in pairs(UnitFrame__scripts) do
		frame:SetScript(k, v)
	end
	
	for k, v in pairs(frame.is_singleton and SingletonUnitFrame__scripts or MemberUnitFrame__scripts) do
		frame:SetScript(k, v)
	end
	
	for k, v in pairs(UnitFrame) do
		frame[k] = v
	end

	for k, v in pairs(frame.is_singleton and SingletonUnitFrame or MemberUnitFrame) do
		frame[k] = v
	end
	
	if not isExampleFrame then
		if frame.is_singleton then
			frame:SetMovable(true)
		end
		frame:RegisterForDrag("LeftButton")
		frame:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp","Button4Up","Button5Up")
		frame:SetAttribute("*type1", "target")
		frame:SetAttribute("*type2", "menu")
	end
	
	UnitFrame__scripts:OnAttributeChanged(frame, "unit", frame:GetAttribute("unit"))
	
	frame:SetClampedToScreen(true)
end
UnitFrame.ConvertIntoUnitFrame = PitBull4:OutOfCombatWrapper(UnitFrame.ConvertIntoUnitFrame)

--- Recheck the layout of the unit frame, make sure it's up to date, and update the frame.
-- @usage frame:RefreshLayout()
function UnitFrame:RefreshLayout()
	local old_layout = self.layout
	
	local classification_db = self.classification_db
	
	local layout = classification_db.layout
	self.layout = layout
	
	self:RefixSizeAndPosition()

	if old_layout then
		self:Update(true, true)
	end
end
UnitFrame.RefreshLayout = PitBull4:OutOfCombatWrapper(UnitFrame.RefreshLayout)

--- Reset the size and position of the unit frame.
-- @usage frame:RefixSizeAndPosition()
function SingletonUnitFrame:RefixSizeAndPosition()
	local layout_db = PitBull4.db.profile.layouts[self.layout]
	local classification_db = self.classification_db
	
	self:SetWidth(layout_db.size_x * classification_db.size_x)
	self:SetHeight(layout_db.size_y * classification_db.size_y)
	self:SetScale(layout_db.scale * classification_db.scale)
	
	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	self:SetPoint("CENTER", UIParent, "CENTER", classification_db.position_x / scale, classification_db.position_y / scale)
end

--- Activate the unit frame.
-- This is just a thin wrapper around RegisterUnitWatch.
-- @usage frame:Activate()
function SingletonUnitFrame:Activate()
	RegisterUnitWatch(self)
end
UnitFrame.Activate = PitBull4:OutOfCombatWrapper(UnitFrame.Activate)

--- Deactivate the unit frame.
-- This is just a thin wrapper around UnregisterUnitWatch.
-- @usage frame:Deactivate()
function SingletonUnitFrame:Deactivate()
	UnregisterUnitWatch(self)
	self:Hide()
end
UnitFrame.Deactivate = PitBull4:OutOfCombatWrapper(UnitFrame.Deactivate)

function UnitFrame:ForceShow()
	self.force_show = true
	UnregisterUnitWatch(self)
	self:Show()
end

function UnitFrame:UnforceShow()
	self.force_show = nil
	RegisterUnitWatch(self)
end

--- Update all details about the UnitFrame, possibly after a GUID change
-- @param same_guid whether the previous GUID is the same as the current, at which point is less crucial to update
-- @param update_layout whether to update the layout no matter what
-- @usage frame:Update()
-- @usage frame:Update(true)
-- @usage frame:Update(false, true)
function UnitFrame:Update(same_guid, update_layout)
	-- TODO: something with same_guid
	if not self.guid and not self.force_show then
	 	if self.populated then
			self.populated = nil
			
			for _, module in PitBull4:IterateEnabledModules() do
				module:Clear(self)
			end
		end
		return
	end
	self.populated = true
	
	local changed = update_layout
	
	for _, module_type in ipairs(MODULE_UPDATE_ORDER) do
		for _, module in PitBull4:IterateModulesOfType(module_type) do
			changed = module:Update(self, true) or changed
		end
	end
	
	if changed then
		self:UpdateLayout()
	end
end

--- Check the guid of the Unit Frame, if it is changed, then update the frame.
-- @param guid result from UnitGUID(unit)
-- @param force_update force an update even if the guid isn't changed, but is non-nil
-- @usage frame:UpdateGUID(UnitGUID(frame.unit))
-- @usage frame:UpdateGUID(UnitGUID(frame.unit), true)
function UnitFrame:UpdateGUID(guid, force_update)
	--@alpha@
	expect(guid, 'typeof', 'string;nil')
	--@end-alpha@
	
	-- if the guids are the same, cut out, but don't if it's a wacky unit that has a guid.
	if not force_update and self.guid == guid and not (guid and self.is_wacky) then
		return
	end
	local previousGUID = self.guid
	self.guid = guid
	self:Update(previousGUID == guid)
end

-- sort the bars in the order specified by the layout
local sort_positions
do
	local sort_positions__layout
	local function helper(alpha, bravo)
		return PitBull4.modules[alpha]:GetLayoutDB(sort_positions__layout).position < PitBull4.modules[bravo]:GetLayoutDB(sort_positions__layout).position
	end

	function sort_positions(positions, frame)
		sort_positions__layout = frame.layout
		table.sort(positions, helper)
		sort_positions__layout = nil
	end
end

local function filter_bars_for_side(layout, bars, side)
	local side_bars = new()
	for _, id in ipairs(bars) do
		if PitBull4.modules[id]:GetLayoutDB(layout).side == side then
			side_bars[#side_bars+1] = id
		end
	end
	return side_bars
end

-- return a list of existing status bars on frame of the given side in the correct order
local function get_all_bars(frame)
	local bars = new()
	
	for id, module in PitBull4:IterateModulesOfType('status_bar') do
		if frame[id] then
			bars[#bars+1] = id
		end
	end
	
	sort_positions(bars, frame)
	
	local layout = frame.layout
	
	return bars,
		filter_bars_for_side(layout, bars, 'center'),
		filter_bars_for_side(layout, bars, 'left'),
		filter_bars_for_side(layout, bars, 'right')
end

-- figure out the total width and height points for a frame based on its bars
local function calculate_width_height_points(layout, center_bars, left_bars, right_bars)
	local bar_height_points = 0
	local bar_width_points = 0
	
	for _, id in ipairs(center_bars) do
		bar_height_points = bar_height_points + PitBull4.modules[id]:GetLayoutDB(layout).size
	end
	
	if #center_bars > 0 then
		-- the center takes up CENTER_WIDTH_POINTS width points if it exists
		bar_width_points = CENTER_WIDTH_POINTS
	end
	
	for _, id in ipairs(left_bars) do
		bar_width_points = bar_width_points + PitBull4.modules[id]:GetLayoutDB(layout).size
	end
	for _, id in ipairs(right_bars) do
		bar_width_points = bar_width_points + PitBull4.modules[id]:GetLayoutDB(layout).size
	end
	
	return bar_width_points, bar_height_points
end

local reverse_ipairs
do
	local function iter(t, current)
		current = current - 1
		if current == 0 then
			return
		end
		
		return current, t[current]
	end
	function reverse_ipairs(t)
		return iter, t, #t+1
	end
end

local function update_bar_layout(self)
	local bars, center_bars, left_bars, right_bars = get_all_bars(self)
	
	local horizontal_mirror = self.classification_db.horizontal_mirror
	local vertical_mirror = self.classification_db.vertical_mirror
	
	if horizontal_mirror then
		left_bars, right_bars = right_bars, left_bars
	end

	local width, height = self:GetWidth(), self:GetHeight()
	
	local layout = self.layout
	
	local bar_width_points, bar_height_points = calculate_width_height_points(layout, center_bars, left_bars, right_bars)

	local bar_height_per_point = height/bar_height_points
	local bar_width_per_point = width/bar_width_points

	local last_x = 0
	for _, id in ipairs(left_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
	
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", last_x, 0)
		local bar_width = PitBull4.modules[id]:GetLayoutDB(layout).size * bar_width_per_point
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
		local bar_width = PitBull4.modules[id]:GetLayoutDB(layout).size * bar_width_per_point
		last_x = last_x - bar_width
		bar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", last_x, 0)
	
		bar:SetOrientation("VERTICAL")
	end
	local right = last_x
	
	local last_y = 0
	for i, id in (not vertical_mirror and ipairs or reverse_ipairs)(center_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
	
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", left, last_y)
		local bar_height = PitBull4.modules[id]:GetLayoutDB(layout).size * bar_height_per_point
		last_y = last_y - bar_height
		bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", right, last_y)
	
		bar:SetOrientation("HORIZONTAL")
	end

	for _, id in ipairs(bars) do
		local bar = self[id]
		local bar_layout_db = PitBull4.modules[id]:GetLayoutDB(layout)
		local reverse = bar_layout_db.reverse
		if bar_layout_db.side == "center" then
			if horizontal_mirror then
				reverse = not reverse
			end
		else
			if vertical_mirror then
				reverse = not reverse
			end
		end
		bar:SetReverse(reverse)
		bar:SetDeficit(bar_layout_db.deficit)
		bar:SetNormalAlpha(bar_layout_db.alpha)
		bar:SetBackgroundAlpha(bar_layout_db.background_alpha)
	end

	bars = del(bars)
	center_bars = del(center_bars)
	left_bars = del(left_bars)
	right_bars = del(right_bars)
end

local function get_all_indicators(frame)
	local indicators = new()
	
	for id, module in PitBull4:IterateModulesOfType('icon', 'custom_indicator') do
		if frame[id] then
			indicators[#indicators+1] = id
		end
	end
	
	sort_positions(indicators, frame)
	
	return indicators
end

function get_all_texts(frame)
	local texts = new()
	
	for id, module in PitBull4:IterateModulesOfType('text_provider') do
		if frame[id] then
			for _, text in pairs(frame[id]) do
				texts[#texts+1] = text
			end
		end
	end
	
	for id, module in PitBull4:IterateModulesOfType('custom_text') do
		if frame[id] then
			texts[#texts+1] = frame[id]
		end
	end
	
	return texts
end

local function get_half_width(frame, indicators_and_texts)
	local num = 0
	
	local layout = frame.layout
	
	for _, indicator_or_text in ipairs(indicators_and_texts) do
		if indicator_or_text.db then
			-- probably a text
			num = num + ASSUMED_TEXT_WIDTH * indicator_or_text.db.size
		else
			local module = PitBull4.modules[indicator_or_text.id]
			if module.module_type == "custom_text" then
				num = num + ASSUMED_TEXT_WIDTH * module:GetLayoutDB(layout).size
			else
				local height_multiplier = indicator_or_text.height or 1
				num = num + module:GetLayoutDB(layout).size * INDICATOR_SIZE * indicator_or_text:GetWidth() / indicator_or_text:GetHeight() * height_multiplier
			end
		end
	end
	
	num = num + (#indicators_and_texts - 1) * INDICATOR_SPACING_BETWEEN
	
	return num / 2
end

local position_indicator_on_root = {}
function position_indicator_on_root:out_top_left(indicator)
	indicator:SetPoint("BOTTOMLEFT", self, "TOPLEFT", INDICATOR_OUT_ROOT_BORDER, INDICATOR_OUT_ROOT_MARGIN)
end
function position_indicator_on_root:out_top_right(indicator)
	indicator:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -INDICATOR_OUT_ROOT_BORDER, INDICATOR_OUT_ROOT_MARGIN)
end
function position_indicator_on_root:out_top(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("BOTTOM", self, "TOP", 0, INDICATOR_OUT_ROOT_MARGIN)
	else
		indicator:SetPoint("BOTTOMLEFT", self, "TOP", -get_half_width(self, indicators_and_texts), INDICATOR_OUT_ROOT_MARGIN)
	end
end
function position_indicator_on_root:out_bottom_left(indicator)
	indicator:SetPoint("TOPLEFT", self, "BOTTOMLEFT", INDICATOR_OUT_ROOT_BORDER, -INDICATOR_OUT_ROOT_MARGIN)
end
function position_indicator_on_root:out_bottom_right(indicator)
	indicator:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -INDICATOR_OUT_ROOT_BORDER, -INDICATOR_OUT_ROOT_MARGIN)
end
function position_indicator_on_root:out_bottom(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("TOP", self, "BOTTOM", 0, INDICATOR_OUT_ROOT_MARGIN)
	else
		indicator:SetPoint("TOPLEFT", self, "BOTTOM", -get_half_width(self, indicators_and_texts), INDICATOR_OUT_ROOT_MARGIN)
	end
end
function position_indicator_on_root:out_left_top(indicator)
	indicator:SetPoint("TOPRIGHT", self, "TOPLEFT", -INDICATOR_OUT_ROOT_MARGIN, -INDICATOR_OUT_ROOT_BORDER)
end
function position_indicator_on_root:out_left(indicator)
	indicator:SetPoint("RIGHT", self, "LEFT", -INDICATOR_OUT_ROOT_MARGIN, 0)
end
function position_indicator_on_root:out_left_bottom(indicator)
	indicator:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -INDICATOR_OUT_ROOT_MARGIN, INDICATOR_OUT_ROOT_BORDER)
end
function position_indicator_on_root:out_right_top(indicator)
	indicator:SetPoint("TOPLEFT", self, "TOPRIGHT", INDICATOR_OUT_ROOT_MARGIN, -INDICATOR_OUT_ROOT_BORDER)
end
function position_indicator_on_root:out_right(indicator)
	indicator:SetPoint("LEFT", self, "RIGHT", INDICATOR_OUT_ROOT_MARGIN, 0)
end
function position_indicator_on_root:out_right_bottom(indicator)
	indicator:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", INDICATOR_OUT_ROOT_MARGIN, INDICATOR_OUT_ROOT_BORDER)
end
function position_indicator_on_root:in_center(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("CENTER", self, "CENTER", 0, 0)
	else
		indicator:SetPoint("LEFT", self, "CENTER", -get_half_width(self, indicators_and_texts), 0)
	end
end
function position_indicator_on_root:in_top_left(indicator)
	indicator:SetPoint("TOPLEFT", self, "TOPLEFT", INDICATOR_IN_ROOT_HORIZONTAL_MARGIN, -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
end
function position_indicator_on_root:in_top(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("TOP", self, "TOP", 0, -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
	else
		indicator:SetPoint("TOPLEFT", self, "TOP", -get_half_width(self, indicators_and_texts), -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
	end
end
function position_indicator_on_root:in_top_left(indicator)
	indicator:SetPoint("TOPRIGHT", self, "TOPRIGHT", -INDICATOR_IN_ROOT_HORIZONTAL_MARGIN, -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
end
function position_indicator_on_root:in_bottom_left(indicator)
	indicator:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", INDICATOR_IN_ROOT_HORIZONTAL_MARGIN, -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
end
function position_indicator_on_root:in_bottom(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("BOTTOM", self, "BOTTOM", 0, -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
	else
		indicator:SetPoint("BOTTOMLEFT", self, "BOTTOM", -get_half_width(self, indicators_and_texts), -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
	end
end
function position_indicator_on_root:in_bottom_left(indicator)
	indicator:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -INDICATOR_IN_ROOT_HORIZONTAL_MARGIN, -INDICATOR_IN_ROOT_VERTICAL_MARGIN)
end
function position_indicator_on_root:in_left(indicator)
	indicator:SetPoint("LEFT", self, "LEFT", INDICATOR_IN_ROOT_HORIZONTAL_MARGIN, 0)
end
function position_indicator_on_root:in_right(indicator)
	indicator:SetPoint("RIGHT", self, "RIGHT", -INDICATOR_IN_ROOT_HORIZONTAL_MARGIN, 0)
end
function position_indicator_on_root:edge_top_left(indicator)
	indicator:SetPoint("CENTER", self, "TOPLEFT", 0, 0)
end
function position_indicator_on_root:edge_top(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("CENTER", self, "TOP", 0, 0)
	else
		indicator:SetPoint("LEFT", self, "TOP", -get_half_width(self, indicators_and_texts), 0)
	end
end
function position_indicator_on_root:edge_top_right(indicator)
	indicator:SetPoint("CENTER", self, "TOPRIGHT", 0, 0)
end
function position_indicator_on_root:edge_left(indicator)
	indicator:SetPoint("CENTER", self, "LEFT", 0, 0)
end
function position_indicator_on_root:edge_right(indicator)
	indicator:SetPoint("CENTER", self, "RIGHT", 0, 0)
end
function position_indicator_on_root:edge_bottom_left(indicator)
	indicator:SetPoint("CENTER", self, "BOTTOMLEFT", 0, 0)
end
function position_indicator_on_root:edge_bottom(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("CENTER", self, "BOTTOM", 0, 0)
	else
		indicator:SetPoint("LEFT", self, "BOTTOM", -get_half_width(self, indicators_and_texts), 0)
	end
end
function position_indicator_on_root:edge_bottom_right(indicator)
	indicator:SetPoint("CENTER", self, "BOTTOMRIGHT", 0, 0)
end

local position_indicator_on_bar = {}
function position_indicator_on_bar:left(indicator, bar)
	indicator:SetPoint("LEFT", bar, "LEFT", INDICATOR_BAR_INSIDE_HORIZONTAL_SPACING, 0)
end
function position_indicator_on_bar:center(indicator, bar, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("CENTER", bar, "CENTER", 0, 0)
	else
		indicator:SetPoint("LEFT", bar, "CENTER", -get_half_width(self, indicators_and_texts), 0)
	end
end
function position_indicator_on_bar:right(indicator, bar)
	indicator:SetPoint("RIGHT", bar, "RIGHT", -INDICATOR_BAR_INSIDE_HORIZONTAL_SPACING, 0)
end
function position_indicator_on_bar:top(indicator, bar, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("TOP", bar, "TOP", 0, 0)
	else
		indicator:SetPoint("TOPLEFT", bar, "TOP", -get_half_width(self, indicators_and_texts), -INDICATOR_BAR_INSIDE_VERTICAL_SPACING)
	end
end
function position_indicator_on_bar:bottom(indicator, bar, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
	else
		indicator:SetPoint("BOTTOMLEFT", bar, "BOTTOM", -get_half_width(self, indicators_and_texts), INDICATOR_BAR_INSIDE_VERTICAL_SPACING)
	end
end
function position_indicator_on_bar:top_left(indicator, bar)
	indicator:SetPoint("TOPLEFT", bar, "TOPLEFT", INDICATOR_BAR_INSIDE_HORIZONTAL_SPACING, -INDICATOR_BAR_INSIDE_VERTICAL_SPACING)
end
function position_indicator_on_bar:top_right(indicator, bar)
	indicator:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -INDICATOR_BAR_INSIDE_HORIZONTAL_SPACING, -INDICATOR_BAR_INSIDE_VERTICAL_SPACING)
end
function position_indicator_on_bar:bottom_left(indicator, bar)
	indicator:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", INDICATOR_BAR_INSIDE_HORIZONTAL_SPACING, INDICATOR_BAR_INSIDE_VERTICAL_SPACING)
end
function position_indicator_on_bar:bottom_right(indicator, bar)
	indicator:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -INDICATOR_BAR_INSIDE_HORIZONTAL_SPACING, INDICATOR_BAR_INSIDE_VERTICAL_SPACING)
end
function position_indicator_on_bar:out_right(indicator, bar)
	indicator:SetPoint("LEFT", bar, "RIGHT", INDICATOR_BAR_OUTSIDE_SPACING, 0)
end
function position_indicator_on_bar:out_left(indicator, bar)
	indicator:SetPoint("RIGHT", bar, "LEFT", -INDICATOR_BAR_OUTSIDE_SPACING, 0)
end

local position_next_indicator_on_root = {}
function position_next_indicator_on_root:out_top_left(indicator, _, last_indicator)
	indicator:SetPoint("LEFT", last_indicator, "RIGHT", INDICATOR_SPACING_BETWEEN, 0)
end
position_next_indicator_on_root.out_top = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.out_bottom_left = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.out_bottom = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.out_right_top = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.out_right = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.out_right_bottom = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.in_center = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.in_top_left = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.in_top = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.in_bottom_left = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.in_bottom = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.in_left = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.edge_top_left = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.edge_top = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.edge_left = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.edge_bottom_left = position_next_indicator_on_root.out_top_left
position_next_indicator_on_root.edge_bottom = position_next_indicator_on_root.out_top_left
function position_next_indicator_on_root:out_top_right(indicator, _, last_indicator)
	indicator:SetPoint("RIGHT", last_indicator, "LEFT", -INDICATOR_SPACING_BETWEEN, 0)
end
position_next_indicator_on_root.out_bottom_right = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.out_left_top = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.out_left = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.out_left_bottom = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.in_top_right = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.in_bottom_right = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.in_right = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.edge_top_right = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.edge_right = position_next_indicator_on_root.out_top_right
position_next_indicator_on_root.edge_bottom_right = position_next_indicator_on_root.out_top_right

local position_next_indicator_on_bar = {}
function position_next_indicator_on_bar:left(indicator, bar, last_indicator)
	indicator:SetPoint("LEFT", last_indicator, "RIGHT", INDICATOR_SPACING_BETWEEN, 0)
end
position_next_indicator_on_bar.center = position_next_indicator_on_bar.left
position_next_indicator_on_bar.out_right = position_next_indicator_on_bar.left
position_next_indicator_on_bar.top_left = position_next_indicator_on_bar.left
position_next_indicator_on_bar.top = position_next_indicator_on_bar.left
position_next_indicator_on_bar.bottom_left = position_next_indicator_on_bar.left
position_next_indicator_on_bar.bottom = position_next_indicator_on_bar.left
function position_next_indicator_on_bar:right(indicator, bar, last_indicator)
	indicator:SetPoint("RIGHT", last_indicator, "LEFT", -INDICATOR_SPACING_BETWEEN, 0)
end
position_next_indicator_on_bar.out_left = position_next_indicator_on_bar.right
position_next_indicator_on_bar.top_right = position_next_indicator_on_bar.right
position_next_indicator_on_bar.bottom_right = position_next_indicator_on_bar.right

local function position_indicator_or_text(root, indicator, attach_frame, last_indicator, location, location_indicators_and_texts)
	local func
	if root == last_indicator then
		if root == attach_frame then
			func = position_indicator_on_root[location]
		else
			func = position_indicator_on_bar[location]
		end
	else
		if root == attach_frame then
			func = position_next_indicator_on_root[location]
		else
			func = position_next_indicator_on_bar[location]
		end
	end
	if func then
		func(root, indicator, attach_frame, last_indicator, location_indicators_and_texts)
	end
end

local horizontal_mirrored_location = setmetatable({}, {__index = function(self, key)
	local value = key:gsub("left", "temp"):gsub("right", "left"):gsub("temp", "right")
	self[key] = value
	return value
end})

local vertical_mirrored_location = setmetatable({}, {__index = function(self, key)
	local value = key:gsub("bottom", "temp"):gsub("top", "bottom"):gsub("temp", "top")
	self[key] = value
	return value
end})

local function update_indicator_and_text_layout(self)
	local attachments = new()
	
	local layout = self.layout
	
	local horizontal_mirror = self.classification_db.horizontal_mirror
	local vertical_mirror = self.classification_db.vertical_mirror
	
	for _, id in ipairs_with_del(get_all_indicators(self)) do
		local indicator = self[id]
		local indicator_layout_db = PitBull4.modules[id]:GetLayoutDB(layout)
	
		local attach_to = indicator_layout_db.attach_to
		local attach_frame
		if attach_to == "root" then
			attach_frame = self
		else
			attach_frame = self[attach_to]
		end
		
		if attach_frame then
			local location = indicator_layout_db.location
		
			local flip_positions = false
			if horizontal_mirror then
				local old_location = location
				location = horizontal_mirrored_location[location]
				if old_location == location then
					flip_positions = true
				end
			end
		
			if vertical_mirror then
				location = vertical_mirrored_location[location]
			end
			
			local size = INDICATOR_SIZE * indicator_layout_db.size
			local unscaled_height = indicator:GetHeight()
			local height_multiplier = indicator.height or 1
			indicator:SetScale(INDICATOR_SIZE / unscaled_height * indicator_layout_db.size * height_multiplier)
			indicator:ClearAllPoints()
			
			local attachments_attach_frame = attachments[attach_frame]
			if not attachments_attach_frame then
				attachments_attach_frame = new()
				attachments[attach_frame] = attachments_attach_frame
			end
			
			local attachments_attach_frame_location = attachments_attach_frame[location]
			if not attachments_attach_frame_location then
				attachments_attach_frame_location = new()
				attachments_attach_frame[location] = attachments_attach_frame_location
			end
			
			if flip_positions then
				table.insert(attachments_attach_frame_location, 1, indicator)
			else
				attachments_attach_frame_location[#attachments_attach_frame_location+1] = indicator
			end
		end
	end
	
	for _, text in ipairs_with_del(get_all_texts(self)) do
		local db = text.db
		if not db then
			db = PitBull4.modules[text.id]:GetLayoutDB(self)
		end
		local attach_to = db.attach_to
		local attach_frame
		if attach_to == "root" then
			attach_frame = self
		else
			attach_frame = self[attach_to]
		end
		
		if attach_frame then
			local location = db.location
		
			local flip_positions = false
			if horizontal_mirror then
				local old_location = location
				location = horizontal_mirrored_location[location]
				if old_location == location then
					flip_positions = true
				end
			end
		
			if vertical_mirror then
				location = vertical_mirrored_location[location]
			end
			
			text:ClearAllPoints()
			
			local attachments_attach_frame = attachments[attach_frame]
			if not attachments_attach_frame then
				attachments_attach_frame = new()
				attachments[attach_frame] = attachments_attach_frame
			end
			
			local attachments_attach_frame_location = attachments_attach_frame[location]
			if not attachments_attach_frame_location then
				attachments_attach_frame_location = new()
				attachments_attach_frame[location] = attachments_attach_frame_location
			end
			
			if flip_positions then
				table.insert(attachments_attach_frame_location, 1, text)
			else
				attachments_attach_frame_location[#attachments_attach_frame_location+1] = text
			end
		end
	end
	
	for attach_frame, attachments_attach_frame in pairs(attachments) do
		for location, loc_indicators_and_texts in pairs(attachments_attach_frame) do
			local last = self
			for _, indicator_or_text in ipairs(loc_indicators_and_texts) do
				position_indicator_or_text(self, indicator_or_text, attach_frame, last, location, loc_indicators_and_texts)
				last = indicator_or_text
			end
			attachments_attach_frame[location] = del(loc_indicators_and_texts)
		end
		attachments[attach_frame] = del(attachments_attach_frame)
	end
	attachments = del(attachments)
end

--- Reposition all controls on the Unit Frame
-- @usage frame:UpdateLayout()
function UnitFrame:UpdateLayout()
	update_bar_layout(self)
	update_indicator_and_text_layout(self)
end

local function iter(frame, id)
	local func, t = PitBull4:IterateEnabledModules()
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

local iters = setmetatable({}, {__index=function(iters, module_type)
	local function iter(frame, id)
		local func, t = PitBull4:IterateModulesOfType(module_type)
		local id, module = func(t, id)
		if id == nil then
			return nil
		end
		if not frame[id] then
			return iter(frame, id)
		end
		return id, frame[id], module
	end
	iters[module_type] = iter
	return iter
end})

--- Iterate over all controls on this frame of the given type
-- @param module_type one of "status_bar", "icon", "custom_indicator", "custom"
-- @usage for id, control, module in PitBull4.IterateControlsOfType("status_bar") do
--     doSomethingWith(control)
-- end
-- @return iterator which returns the id, control, and module
function UnitFrame:IterateControlsOfType(module_type)
	return iters[module_type], self, nil
end
