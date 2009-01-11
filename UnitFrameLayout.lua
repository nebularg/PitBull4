
-- CONSTANTS ----------------------------------------------------------------

-- how many width points the center bars take up if at least one exists
local CENTER_WIDTH_POINTS = 10

-- how many pixels wide to assume a text is
local ASSUMED_TEXT_WIDTH = 40

-----------------------------------------------------------------------------

local _G = _G
local PitBull4 = _G.PitBull4

local UnitFrame = PitBull4.UnitFrame

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
	
	local bar_spacing = self.layout_db.bar_spacing
	local bar_padding = self.layout_db.bar_padding
	
	local height_of_bars = height - bar_spacing * (#center_bars - 1) - bar_padding * 2
	local num_vertical_bars = #left_bars + #right_bars
	if #center_bars > 0 then
		num_vertical_bars = num_vertical_bars + num_vertical_bars
	end
	local width_of_bars = width - bar_spacing * (num_vertical_bars - 1) - bar_padding * 2
	
	local bar_height_per_point = height_of_bars / bar_height_points
	local bar_width_per_point = width_of_bars / bar_width_points

	local last_x = bar_padding
	for _, id in ipairs(left_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
	
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", last_x, 0)
		local bar_width = PitBull4.modules[id]:GetLayoutDB(layout).size * bar_width_per_point
		last_x = last_x + bar_width
		bar:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", last_x, 0)
		last_x = last_x + bar_spacing
	
		bar:SetOrientation("VERTICAL")
	end
	local left = last_x

	last_x = -bar_padding
	for _, id in ipairs(right_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
	
		bar:SetPoint("TOPRIGHT", self, "TOPRIGHT", last_x, 0)
		local bar_width = PitBull4.modules[id]:GetLayoutDB(layout).size * bar_width_per_point
		last_x = last_x - bar_width
		bar:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", last_x, 0)
		last_x = last_x - bar_spacing
	
		bar:SetOrientation("VERTICAL")
	end
	local right = last_x
	
	local last_y = -bar_padding
	for i, id in (not vertical_mirror and ipairs or reverse_ipairs)(center_bars) do
		local bar = self[id]
		bar:ClearAllPoints()
	
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", left, last_y)
		local bar_height = PitBull4.modules[id]:GetLayoutDB(layout).size * bar_height_per_point
		last_y = last_y - bar_height
		bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", right, last_y)
		last_y = last_y - bar_spacing
	
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

local function get_all_texts(frame)
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
	local layout_db = frame.layout_db
	
	for _, indicator_or_text in ipairs(indicators_and_texts) do
		if indicator_or_text.SetJustifyH then
			-- a text
			if indicator_or_text.db then
				num = num + ASSUMED_TEXT_WIDTH * indicator_or_text.db.size
			else
				local module = PitBull4.modules[indicator_or_text.id]
				num = num + ASSUMED_TEXT_WIDTH * module:GetLayoutDB(layout).size
			end
		else
			-- an indicator
			local module = PitBull4.modules[indicator_or_text.id]
			local height_multiplier = indicator_or_text.height or 1
			num = num + module:GetLayoutDB(layout).size * layout_db.indicator_size * indicator_or_text:GetWidth() / indicator_or_text:GetHeight() * height_multiplier
		end
	end
	
	num = num + (#indicators_and_texts - 1) * layout_db.indicator_spacing
	
	return num / 2
end

local position_indicator_on_root = {}
function position_indicator_on_root:out_top_left(indicator)
	indicator:SetPoint("BOTTOMLEFT", self, "TOPLEFT", self.layout_db.bar_padding, self.layout_db.indicator_root_outside_margin)
end
function position_indicator_on_root:out_top_right(indicator)
	indicator:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", -self.layout_db.bar_padding, self.layout_db.indicator_root_outside_margin)
end
function position_indicator_on_root:out_top(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("BOTTOM", self, "TOP", 0, self.layout_db.indicator_root_outside_margin)
	else
		indicator:SetPoint("BOTTOMLEFT", self, "TOP", -get_half_width(self, indicators_and_texts), self.layout_db.indicator_root_outside_margin)
	end
end
function position_indicator_on_root:out_bottom_left(indicator)
	indicator:SetPoint("TOPLEFT", self, "BOTTOMLEFT", self.layout_db.bar_padding, -self.layout_db.indicator_root_outside_margin)
end
function position_indicator_on_root:out_bottom_right(indicator)
	indicator:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", -self.layout_db.bar_padding, -self.layout_db.indicator_root_outside_margin)
end
function position_indicator_on_root:out_bottom(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("TOP", self, "BOTTOM", 0, self.layout_db.indicator_root_outside_margin)
	else
		indicator:SetPoint("TOPLEFT", self, "BOTTOM", -get_half_width(self, indicators_and_texts), self.layout_db.indicator_root_outside_margin)
	end
end
function position_indicator_on_root:out_left_top(indicator)
	indicator:SetPoint("TOPRIGHT", self, "TOPLEFT", -self.layout_db.indicator_root_outside_margin, -self.layout_db.bar_padding)
end
function position_indicator_on_root:out_left(indicator)
	indicator:SetPoint("RIGHT", self, "LEFT", -self.layout_db.indicator_root_outside_margin, 0)
end
function position_indicator_on_root:out_left_bottom(indicator)
	indicator:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -self.layout_db.indicator_root_outside_margin, self.layout_db.bar_padding)
end
function position_indicator_on_root:out_right_top(indicator)
	indicator:SetPoint("TOPLEFT", self, "TOPRIGHT", self.layout_db.indicator_root_outside_margin, -self.layout_db.bar_padding)
end
function position_indicator_on_root:out_right(indicator)
	indicator:SetPoint("LEFT", self, "RIGHT", self.layout_db.indicator_root_outside_margin, 0)
end
function position_indicator_on_root:out_right_bottom(indicator)
	indicator:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", self.layout_db.indicator_root_outside_margin, self.layout_db.bar_padding)
end
function position_indicator_on_root:in_center(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("CENTER", self, "CENTER", 0, 0)
	else
		indicator:SetPoint("LEFT", self, "CENTER", -get_half_width(self, indicators_and_texts), 0)
	end
end
function position_indicator_on_root:in_top_left(indicator)
	indicator:SetPoint("TOPLEFT", self, "TOPLEFT", self.layout_db.indicator_root_inside_horizontal_padding, -self.layout_db.indicator_root_inside_vertical_padding)
end
function position_indicator_on_root:in_top(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("TOP", self, "TOP", 0, -self.layout_db.indicator_root_inside_vertical_padding)
	else
		indicator:SetPoint("TOPLEFT", self, "TOP", -get_half_width(self, indicators_and_texts), -self.layout_db.indicator_root_inside_vertical_padding)
	end
end
function position_indicator_on_root:in_top_left(indicator)
	indicator:SetPoint("TOPRIGHT", self, "TOPRIGHT", -self.layout_db.indicator_root_inside_horizontal_padding, -self.layout_db.indicator_root_inside_vertical_padding)
end
function position_indicator_on_root:in_bottom_left(indicator)
	indicator:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", self.layout_db.indicator_root_inside_horizontal_padding, -self.layout_db.indicator_root_inside_vertical_padding)
end
function position_indicator_on_root:in_bottom(indicator, _, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("BOTTOM", self, "BOTTOM", 0, -self.layout_db.indicator_root_inside_vertical_padding)
	else
		indicator:SetPoint("BOTTOMLEFT", self, "BOTTOM", -get_half_width(self, indicators_and_texts), -self.layout_db.indicator_root_inside_vertical_padding)
	end
end
function position_indicator_on_root:in_bottom_left(indicator)
	indicator:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -self.layout_db.indicator_root_inside_horizontal_padding, -self.layout_db.indicator_root_inside_vertical_padding)
end
function position_indicator_on_root:in_left(indicator)
	indicator:SetPoint("LEFT", self, "LEFT", self.layout_db.indicator_root_inside_horizontal_padding, 0)
end
function position_indicator_on_root:in_right(indicator)
	indicator:SetPoint("RIGHT", self, "RIGHT", -self.layout_db.indicator_root_inside_horizontal_padding, 0)
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
	indicator:SetPoint("LEFT", bar, "LEFT", self.layout_db.indicator_bar_inside_horizontal_padding, 0)
end
function position_indicator_on_bar:center(indicator, bar, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("CENTER", bar, "CENTER", 0, 0)
	else
		indicator:SetPoint("LEFT", bar, "CENTER", -get_half_width(self, indicators_and_texts), 0)
	end
end
function position_indicator_on_bar:right(indicator, bar)
	indicator:SetPoint("RIGHT", bar, "RIGHT", -self.layout_db.indicator_bar_inside_horizontal_padding, 0)
end
function position_indicator_on_bar:top(indicator, bar, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("TOP", bar, "TOP", 0, 0)
	else
		indicator:SetPoint("TOPLEFT", bar, "TOP", -get_half_width(self, indicators_and_texts), -self.layout_db.indicator_bar_inside_vertical_padding)
	end
end
function position_indicator_on_bar:bottom(indicator, bar, _, indicators_and_texts)
	if #indicators_and_texts == 1 then
		indicator:SetPoint("BOTTOM", bar, "BOTTOM", 0, 0)
	else
		indicator:SetPoint("BOTTOMLEFT", bar, "BOTTOM", -get_half_width(self, indicators_and_texts), self.layout_db.indicator_bar_inside_vertical_padding)
	end
end
function position_indicator_on_bar:top_left(indicator, bar)
	indicator:SetPoint("TOPLEFT", bar, "TOPLEFT", self.layout_db.indicator_bar_inside_horizontal_padding, -self.layout_db.indicator_bar_inside_vertical_padding)
end
function position_indicator_on_bar:top_right(indicator, bar)
	indicator:SetPoint("TOPRIGHT", bar, "TOPRIGHT", -self.layout_db.indicator_bar_inside_horizontal_padding, -self.layout_db.indicator_bar_inside_vertical_padding)
end
function position_indicator_on_bar:bottom_left(indicator, bar)
	indicator:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", self.layout_db.indicator_bar_inside_horizontal_padding, self.layout_db.indicator_bar_inside_vertical_padding)
end
function position_indicator_on_bar:bottom_right(indicator, bar)
	indicator:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -self.layout_db.indicator_bar_inside_horizontal_padding, self.layout_db.indicator_bar_inside_vertical_padding)
end
function position_indicator_on_bar:out_right(indicator, bar)
	indicator:SetPoint("LEFT", bar, "RIGHT", self.layout_db.indicator_bar_outside_margin, 0)
end
function position_indicator_on_bar:out_left(indicator, bar)
	indicator:SetPoint("RIGHT", bar, "LEFT", -self.layout_db.indicator_bar_outside_margin, 0)
end

local position_next_indicator_on_root = {}
function position_next_indicator_on_root:out_top_left(indicator, _, last_indicator)
	indicator:SetPoint("LEFT", last_indicator, "RIGHT", self.layout_db.indicator_spacing, 0)
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
	indicator:SetPoint("RIGHT", last_indicator, "LEFT", -self.layout_db.indicator_spacing, 0)
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
	indicator:SetPoint("LEFT", last_indicator, "RIGHT", self.layout_db.indicator_spacing, 0)
end
position_next_indicator_on_bar.center = position_next_indicator_on_bar.left
position_next_indicator_on_bar.out_right = position_next_indicator_on_bar.left
position_next_indicator_on_bar.top_left = position_next_indicator_on_bar.left
position_next_indicator_on_bar.top = position_next_indicator_on_bar.left
position_next_indicator_on_bar.bottom_left = position_next_indicator_on_bar.left
position_next_indicator_on_bar.bottom = position_next_indicator_on_bar.left
function position_next_indicator_on_bar:right(indicator, bar, last_indicator)
	indicator:SetPoint("RIGHT", last_indicator, "LEFT", -self.layout_db.indicator_spacing, 0)
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

local function position_overlapping_texts_helper(attach_frame, left, center, right, inside_width, spacing)
	if center then
		-- clamp left to center
		if left and left[#left].SetJustifyH then
			left[#left]:SetJustifyH("LEFT")
			left[#left]:SetPoint("RIGHT", center[1], "LEFT", -spacing, 0)
		end
	
		-- clamp right to center
		if right and right[#right].SetJustifyH("RIGHT") then
			right[#right]:SetJustifyH("RIGHT")
			right[#right]:SetPoint("LEFT", center[#center], "RIGHT", spacing, 0)
		end
	elseif left and left[#left].SetJustifyH then	
		left[#left]:SetJustifyH("LEFT")
		if right then
			-- clamp left to right
			left[#left]:SetPoint("RIGHT", right[#right], "LEFT", -spacing, 0)
		else
			-- clamp left to attach_frame's right side
			left[#left]:SetPoint("RIGHT", attach_frame, "RIGHT", -inside_width, 0)
		end
	end
end

local function position_overlapping_texts(root, attach_frame, location_to_indicators_and_texts)
	local spacing = root.layout_db.indicator_spacing
	if root == attach_frame then
		local padding = root.layout_db.bar_padding
		position_overlapping_texts_helper(
			attach_frame,
			location_to_indicators_and_texts.in_left,
			location_to_indicators_and_texts.in_center,
			location_to_indicators_and_texts.in_right,
			padding,
			spacing)
		position_overlapping_texts_helper(
			attach_frame,
			location_to_indicators_and_texts.in_bottom_left,
			location_to_indicators_and_texts.in_bottom,
			location_to_indicators_and_texts.in_bottom_right,
			padding,
			spacing)
		position_overlapping_texts_helper(
			attach_frame,
			location_to_indicators_and_texts.in_top_left,
			location_to_indicators_and_texts.in_top,
			location_to_indicators_and_texts.in_top_right,
			padding,
			spacing)
		position_overlapping_texts_helper(
			attach_frame,
			location_to_indicators_and_texts.out_bottom_left,
			location_to_indicators_and_texts.out_bottom,
			location_to_indicators_and_texts.out_bottom_right,
			padding,
			spacing)
		position_overlapping_texts_helper(
			attach_frame,
			location_to_indicators_and_texts.out_top_left,
			location_to_indicators_and_texts.out_top,
			location_to_indicators_and_texts.out_top_right,
			padding,
			spacing)
	else
		position_overlapping_texts_helper(
			attach_frame,
			location_to_indicators_and_texts.left,
			location_to_indicators_and_texts.center,
			location_to_indicators_and_texts.right,
			root.layout_db.indicator_bar_inside_horizontal_padding,
			spacing)
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
	
	local indicator_size = self.layout_db.indicator_size
	
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
			
			local size = indicator_size * indicator_layout_db.size
			local unscaled_height = indicator:GetHeight()
			local height_multiplier = indicator.height or 1
			indicator:SetScale(indicator_size / unscaled_height * indicator_layout_db.size * height_multiplier)
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
		end
		
		position_overlapping_texts(self, attach_frame, attachments_attach_frame)
		
		for location, loc_indicators_and_texts in pairs(attachments_attach_frame) do
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
