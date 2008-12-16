local _G = _G
local PitBull4 = _G.PitBull4

local LibSimpleOptions = LibStub and LibStub("LibSimpleOptions-1.0", true)
if not LibSimpleOptions then
	LoadAddOn("LibSimpleOptions-1.0")
	LibSimpleOptions = LibStub and LibStub("LibSimpleOptions-1.0", true)
	if not LibSimpleOptions then
		message(("PitBull4 requires the library %q and will not work without it."):format("LibSimpleOptions-1.0"))
		error(("PitBull4 requires the library %q and will not work without it."):format("LibSimpleOptions-1.0"))
	end
end

LibSimpleOptions.AddOptionsPanel("PitBull Unit Frames 4.0", function(self)
	local title, subText = self:MakeTitleTextAndSubText("PitBull Unit Frames 4.0", "These options allow you to configure PitBull Unit Frames 4.0")
end)

LibSimpleOptions.AddSuboptionsPanel("PitBull Unit Frames 4.0", "Layouts", function(self)
	local title, subText = self:MakeTitleTextAndSubText("Layouts", "These options allow you to manipulate the way a specific layout looks")
	
	local SELECTED_LAYOUT = "Normal"
	local SELECTED_CONTROL = 'root'
	
	local example_unit_frame = CreateFrame("Button", nil, self)
	example_unit_frame.is_singleton = true
	example_unit_frame.classification = 'irrelevant'
	example_unit_frame.classificationDB = {}
	example_unit_frame.layout = SELECTED_LAYOUT
	example_unit_frame.layoutDB = PitBull4.db.layouts[SELECTED_LAYOUT]
	example_unit_frame.unitID = "player"
	example_unit_frame.guid = UnitGUID("player")
	example_unit_frame:SetAttribute("unit", "player")
	
	local function make_example_statusbar(id)
		local bar = PitBull4.Controls.MakeBetterStatusBar(example_unit_frame)
		return bar
	end
	
	example_unit_frame:SetPoint("TOPLEFT", subText, "BOTTOMLEFT", 0, -16)
	example_unit_frame:SetWidth(200)
	example_unit_frame:SetHeight(70)
	
	local top = example_unit_frame:CreateTexture(nil, "BACKGROUND")
	top:SetPoint("TOPLEFT", example_unit_frame, "TOPLEFT")
	top:SetPoint("TOPRIGHT", example_unit_frame, "TOPRIGHT")
	top:SetHeight(1)
	top:SetTexture(1, 1, 1)
	
	local bottom = example_unit_frame:CreateTexture(nil, "BACKGROUND")
	bottom:SetPoint("BOTTOMLEFT", example_unit_frame, "BOTTOMLEFT")
	bottom:SetPoint("BOTTOMRIGHT", example_unit_frame, "BOTTOMRIGHT")
	bottom:SetHeight(1)
	bottom:SetTexture(1, 1, 1)
	
	local left = example_unit_frame:CreateTexture(nil, "BACKGROUND")
	left:SetPoint("TOPLEFT", example_unit_frame, "TOPLEFT")
	left:SetPoint("BOTTOMLEFT", example_unit_frame, "BOTTOMLEFT")
	left:SetWidth(1)
	left:SetTexture(1, 1, 1)
	
	local right = example_unit_frame:CreateTexture(nil, "BACKGROUND")
	right:SetPoint("TOPRIGHT", example_unit_frame, "TOPRIGHT")
	right:SetPoint("BOTTOMRIGHT", example_unit_frame, "BOTTOMRIGHT")
	right:SetWidth(1)
	right:SetTexture(1, 1, 1)
	
	local make_bar_drop_down
	local function reset()
		make_bar_drop_down.value = nil
		UIDropDownMenu_SetSelectedValue(make_bar_drop_down, nil)
		UIDropDownMenu_SetText(make_bar_drop_down, "Make a bar")
	end
	local function values_iter(_, id)
		local func, t = PitBull4.IterateModulesOfType('statusbar', true)
		local id, module = func(t, id)
		if not id then
			return nil
		end
		if not PitBull4.db.layouts[SELECTED_LAYOUT][id].hidden then
			return values_iter(nil, id)
		end
		return id, module.name
	end
	make_bar_drop_down = self:MakeDropDown(
		'name', '', -- don't want a label
		'description', "Make a bar of the type you specify",
		'values', values_iter,
		'default', '',
		'getFunc', function() return end,
		'setFunc', function(id)
			if not id then
				return
			end
			reset()
			-- do something with id
		end
	)
	reset()
	make_bar_drop_down:SetPoint("TOPLEFT", example_unit_frame, "TOPRIGHT", 8, 0)
	
	local current_selected_control_drop_down
	local function select_control(id)
		SELECTED_CONTROL = id
		if not current_selected_control_drop_down then
			return
		end
		current_selected_control_drop_down.value = id
		UIDropDownMenu_SetSelectedValue(current_selected_control_drop_down, id)
		
		UIDropDownMenu_SetText(current_selected_control_drop_down, id == 'root' and "Unit Frame" or PitBull4.GetModule(id).name)
	end
	
	local values = {
		'root', 'Unit Frame',
	}
	current_selected_control_drop_down = self:MakeDropDown(
		'name', '', -- don't want a label
		'description', "The current selected control",
		'values', values,
		'default', 'root',
		'getFunc', function()
			--select_control('root')
			return SELECTED_CONTROL
		end,
		'setFunc', select_control
	)
	
	current_selected_control_drop_down:SetPoint("TOPLEFT", example_unit_frame, "BOTTOMLEFT", -16, -16)
	
	local control_options_panel = self:MakeScrollFrame()
	control_options_panel:SetPoint("TOPLEFT", current_selected_control_drop_down, "BOTTOMLEFT", 16, 0)
	control_options_panel:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -32, 16)
	
	PitBull4.ConvertIntoUnitFrame(example_unit_frame, true)
	
	function self:refreshFunc()
		example_unit_frame:Update()
		wipe(values)
		values[#values+1] = 'root'
		values[#values+1] = 'Unit Frame'
		for id, control, module in example_unit_frame:IterateControlsOfType('statusbar') do
			values[#values+1] = id
			values[#values+1] = module.name
			control:SetMovable(true)
			control:EnableMouse(true)
			control:RegisterForClicks("LeftButtonUp")
			control:RegisterForDrag("LeftButton")
		
			control:SetScript("OnDragStart", function(self)
				self.start_x, self.start_y = control:GetCenter()
				self:StartMoving()
				self:SetFrameLevel(self:GetFrameLevel() + 5)
			end)
		
			control:SetScript("OnDragStop", function(self)
				self:StopMovingOrSizing()
				self:SetFrameLevel(self:GetFrameLevel() - 5)
				local control_x, control_y = control:GetCenter()
				local control_width, control_height = control:GetWidth(), control:GetHeight()
			
				local start_x, start_y = self.start_x, self.start_y
				self.start_x, self.start_y = nil, nil
			
				local side = example_unit_frame.layoutDB[id].side
			
				local above, below = 0, 1/0
				local above_coord, below_coord
			
				local control_position = example_unit_frame.layoutDB[id].position
			
				local bars = {}
			
				for other_id, other_control, other_module in example_unit_frame:IterateControlsOfType('statusbar') do
					if other_control ~= self and example_unit_frame.layoutDB[other_id].side == side then
						bars[#bars+1] = other_id
					end
				end
			
				table.sort(bars, function(alpha, bravo)
					return example_unit_frame.layoutDB[alpha].position < example_unit_frame.layoutDB[bravo].position
				end)
			
				local above, below = nil, nil
				local above_coord, below_coord = nil, nil
				
				for i, bar_id in ipairs(bars) do
					local bar = example_unit_frame[bar_id]
				
					local bar_x, bar_y = bar:GetCenter()
				
					if side == "center" then
						if bar_y < start_y then
							bar_y = bar_y + control_height / 2
						else
							bar_y = bar_y - control_height / 2
						end
					
						if control_y > bar_y then
			 				if not above_coord or above_coord < bar_y then
								above = i
								above_coord = bar_y
							end
						else
			 				if not below_coord or below_coord > bar_y then
								below = i
								below_coord = bar_y
							end
						end
					end
				end
				
				if not above then
					table.insert(bars, id)
				else
					table.insert(bars, above, id)
				end
			
				for i, bar_id in ipairs(bars) do
					example_unit_frame.layoutDB[bar_id].position = i
				end
			
				example_unit_frame:UpdateLayout()
				PitBull4.UpdateLayoutForLayout(example_unit_frame.layout)
			end)
		
			control:SetScript("OnClick", function(self)
				select_control(self.id)
			end)
		
			function control:extraDelete()
				control:SetMovable(false)
				control:EnableMouse(false)
				control:RegisterForDrag()
				control:SetScript("OnDragStart", nil)
				control:SetScript("OnDragStop", nil)
				control:SetScript("OnClick", nil)
			end
		end
	end
	self:Refresh()
end)

LibSimpleOptions.AddSlashCommand("PitBull Unit Frames 4.0", "/PitBull4", "/PitBull", "/PB4", "/PB", "/PBUF", "/Pit")
