local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local root_locations = {
	out_top_left = ("%s, %s"):format(L["Outside"], L["Above-left"]),
	out_top = ("%s, %s"):format(L["Outside"], L["Above"]),
	out_top_right = ("%s, %s"):format(L["Outside"], L["Above-right"]),
	out_bottom_left = ("%s, %s"):format(L["Outside"], L["Below-left"]),
	out_bottom = ("%s, %s"):format(L["Outside"], L["Below"]),
	out_bottom_right = ("%s, %s"):format(L["Outside"], L["Below-right"]),
	out_left_top = ("%s, %s"):format(L["Outside"], L["Left-top"]),
	out_left = ("%s, %s"):format(L["Outside"], L["Left"]),
	out_left_bottom = ("%s, %s"):format(L["Outside"], L["Left-bottom"]),
	out_right_top = ("%s, %s"):format(L["Outside"], L["Right-top"]),
	out_right = ("%s, %s"):format(L["Outside"], L["Right"]),
	out_right_bottom = ("%s, %s"):format(L["Outside"], L["Right-bottom"]),
	
	in_center = ("%s, %s"):format(L["Inside"], L["Middle"]),
	in_top_left = ("%s, %s"):format(L["Inside"], L["Top-left"]),
	in_top = ("%s, %s"):format(L["Inside"], L["Top"]),
	in_top_right = ("%s, %s"):format(L["Inside"], L["Top-right"]),
	in_bottom_left = ("%s, %s"):format(L["Inside"], L["Bottom-left"]),
	in_bottom = ("%s, %s"):format(L["Inside"], L["Bottom"]),
	in_bottom_right = ("%s, %s"):format(L["Inside"], L["Bottom-right"]),
	in_left = ("%s, %s"):format(L["Inside"], L["Left"]),
	in_right = ("%s, %s"):format(L["Inside"], L["Right"]),
	
	edge_top_left = ("%s, %s"):format(L["Edge"], L["Top-left"]),
	edge_top = ("%s, %s"):format(L["Edge"], L["Top"]),
	edge_top_right = ("%s, %s"):format(L["Edge"], L["Top-right"]),
	edge_left = ("%s, %s"):format(L["Edge"], L["Left"]),
	edge_right = ("%s, %s"):format(L["Edge"], L["Right"]),
	edge_bottom_left = ("%s, %s"):format(L["Edge"], L["Bottom-left"]),
	edge_bottom = ("%s, %s"):format(L["Edge"], L["Bottom"]),
	edge_bottom_right = ("%s, %s"):format(L["Edge"], L["Bottom-right"]),
}
PitBull4.Options.root_locations = root_locations

local bar_locations = {
	out_left = ("%s, %s"):format(L["Outside"], L["Left"]),
	left = L["Left"],
	center = L["Middle"],
	right = L["Right"],
	out_right = ("%s, %s"):format(L["Outside"], L["Right"]),
}
PitBull4.Options.bar_locations = bar_locations

function PitBull4.Options.get_layout_editor_indicator_options()
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	
	local options = {
		name = L["Indicators"],
		desc = L["Indicators are icons or other graphical displays that convey a specific, usually temporary, status."],
		type = 'group',
		childGroups = "tab",
		args = {}
	}
	
	options.args.general = {
		type = 'group',
		name = L["General"],
		desc = L["Options that apply to all indicators."],
		order = 1,
		args = {},
	}
	
	local general_args = options.args.general.args
	
	general_args.spacing = {
		type = 'range',
		name = L["Spacing"],
		desc = L["Spacing between adjacent indicators."],
		min = 1,
		max = 20,
		step = 1,
		order = 1,
		get = function(info)
			return GetLayoutDB(false).indicator_spacing
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_spacing = value
			
			UpdateFrames()
		end,
	}
	
	general_args.size = {
		type = 'range',
		name = L["Size"],
		desc = L["Unscaled size of indicators."],
		min = 5,
		max = 50,
		step = 1,
		bigStep = 5,
		order = 2,
		get = function(info)
			return GetLayoutDB(false).indicator_size
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_size = value
			
			UpdateFrames()
		end,
	}
	
	general_args.bar = {
		type = 'group',
		name = L["Bar relation"],
		inline = true,
		order = 3,
		args = {}
	}
	
	general_args.bar.args.inside_horizontal_padding = {
		type = 'range',
		name = L["Inside horizontal padding"],
		desc = L["How far in pixels that indicators are horizontally placed inside bars."],
		min = 0,
		max = 20,
		step = 1,
		order = 1,
		get = function(info)
			return GetLayoutDB(false).indicator_bar_inside_horizontal_padding
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_bar_inside_horizontal_padding = value
			
			UpdateFrames()
		end,
	}
	
	general_args.bar.args.inside_vertical_padding = {
		type = 'range',
		name = L["Inside vertical padding"],
		desc = L["How far in pixels that indicators are vertically placed inside bars."],
		min = 0,
		max = 20,
		step = 1,
		order = 2,
		get = function(info)
			return GetLayoutDB(false).indicator_bar_inside_vertical_padding
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_bar_inside_vertical_padding = value
			
			UpdateFrames()
		end,
		hidden = true,
	}
	
	general_args.bar.args.outside_margin = {
		type = 'range',
		name = L["Outside margin"],
		desc = L["How far in pixels that indicators are placed outside of bars."],
		min = 0,
		max = 20,
		step = 1,
		order = 3,
		get = function(info)
			return GetLayoutDB(false).indicator_bar_outside_margin
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_bar_outside_margin = value
			
			UpdateFrames()
		end,
	}
	
	general_args.root = {
		type = 'group',
		name = L["Frame relation"],
		inline = true,
		order = 4,
		args = {}
	}
	
	general_args.root.args.root_inside_horizontal_padding = {
		type = 'range',
		name = L["Inside horizontal padding"],
		desc = L["How far in pixels that indicators are horizontally placed inside the unit frame."],
		min = 0,
		max = 20,
		step = 1,
		order = 1,
		get = function(info)
			return GetLayoutDB(false).indicator_root_inside_horizontal_padding
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_root_inside_horizontal_padding = value
			
			UpdateFrames()
		end,
	}
	
	general_args.root.args.root_inside_vertical_padding = {
		type = 'range',
		name = L["Inside vertical padding"],
		desc = L["How far in pixels that indicators are vertically placed inside the unit frame."],
		min = 0,
		max = 20,
		step = 1,
		order = 2,
		get = function(info)
			return GetLayoutDB(false).indicator_root_inside_vertical_padding
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_root_inside_vertical_padding = value
			
			UpdateFrames()
		end,
	}
	
	general_args.root.args.root_outside_margin = {
		type = 'range',
		name = L["Outside margin"],
		desc = L["How far in pixels that indicators are placed outside the unit frame."],
		min = 0,
		max = 20,
		step = 1,
		order = 3,
		get = function(info)
			return GetLayoutDB(false).indicator_root_outside_margin
		end,
		set = function(info, value)
			GetLayoutDB(false).indicator_root_outside_margin = value
			
			UpdateFrames()
		end,
	}
	
	local indicator_args = {}
	
	indicator_args.enable = {
		type = 'toggle',
		name = L["Enable"],
		desc = L["Enable this indicator."],
		order = 1,
		get = function(info)
			return GetLayoutDB(info[#info-1]).enabled
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).enabled = value
			
			UpdateFrames()
		end
	}
	
	local function disabled(info)
		return not GetLayoutDB(info[#info-1]).enabled
	end
	
	indicator_args.attach_to = {
		type = 'select',
		name = L["Attach to"],
		desc = L["Which control to attach to."],
		order = 2,
		get = function(info)
			return GetLayoutDB(info[#info-1]).attach_to
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).attach_to = value
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			
			t["root"] = L["Unit frame"]
			
			for id, module in PitBull4:IterateModulesOfType("status_bar") do
				t[id] = module.name
			end
			
			return t
		end,
		disabled = disabled,
	}
	
	indicator_args.location = {
		type = 'select',
		name = L["Location"],
		desc = L["Where on the control to place the indicator."],
		order = 3,
		get = function(info)
			return GetLayoutDB(info[#info-1]).location
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).location = value
			
			UpdateFrames()
		end,
		values = function(info)
			local attach_to = GetLayoutDB(info[#info-1]).attach_to
			if attach_to == "root" then
				return root_locations
			else
				return bar_locations
			end
		end,
		disabled = disabled,
	}
	
	indicator_args.position = {
		type = 'select',
		name = L["Position"],
		desc = L["Where to place the indicator compared to others in the same location."],
		order = 4,
		values = function(info)
			local db = GetLayoutDB(info[#info-1])
			local attach_to = db.attach_to
			local location = db.location
			local t = {}
			local sort = {}
			for other_id, other_module in PitBull4:IterateModulesOfType("icon", "custom_indicator") do
				local other_db = GetLayoutDB(other_id)
				if attach_to == other_db.attach_to and location == other_db.location then
					local position = other_db.position
					while t[position] do
						position = position + 1e-5
						other_db.position = position
					end
					t[position] = other_module.name
					sort[#sort+1] = position
				end
			end
			table.sort(sort)
			local sort_reverse = {}
			for k, v in pairs(sort) do
				sort_reverse[v] = k
			end
			for position, name in pairs(t) do
				t[position] = ("%d. %s"):format(sort_reverse[position], name)
			end
			return t
		end,
		get = function(info)
			return GetLayoutDB(info[#info-1]).position
		end,
		set = function(info, new_position)
			local id = info[#info-1]
			local db = GetLayoutDB(id)
			
			local id_to_position = {}
			local indicators = {}
			
			local old_position = db.position
			
			for other_id, other_module in PitBull4:IterateModulesOfType("icon", "custom_indicator", true) do
				local other_db = GetLayoutDB(other_id)
				local other_position = other_db.position
				if other_id == id then
					other_position = new_position
				elseif other_position >= old_position and other_position <= new_position then
					other_position = other_position - 1
				elseif other_position <= old_position and other_position >= new_position then
					other_position = other_position + 1
				end
				
				id_to_position[other_id] = other_position
				indicators[#indicators+1] = other_id
			end
			
			table.sort(indicators, function(alpha, bravo)
				return id_to_position[alpha] < id_to_position[bravo]
			end)
			
			for position, indicator_id in ipairs(indicators) do
				GetLayoutDB(indicator_id).position = position
			end
			
			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	indicator_args.size = {
		type = 'range',
		name = L["Size"],
		desc = L["Size of the indicator."],
		order = 5,
		get = function(info)
			return GetLayoutDB(info[#info-1]).size
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).size = value
			
			UpdateFrames()
		end,
		min = 0.5,
		max = 4,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		disabled = disabled,
	}
	
	local layout_functions = PitBull4.Options.layout_functions
	
	for id, module in PitBull4:IterateModulesOfType("icon", "custom_indicator", true) do
		local args = {}
		for k, v in pairs(indicator_args) do
			args[k] = v
		end
		if layout_functions[module] then
			local data = { layout_functions[module](module) }
			for i = 1, #data, 2 do
				local k, v = data[i], data[i+1]
				
				args[k] = v
				v.order = 100 + i
				
				local v_disabled = v.disabled
				function v.disabled(info)
					return disabled(info) or (v_disabled and v_disabled(info))
				end
			end
			layout_functions[module] = false
		end
		
		options.args[id] = {
			name = module.name,
			desc = module.description,
			type = 'group',
			args = args,
			hidden = function(info)
				return not module:IsEnabled()
			end,
		}
	end
	
	return options
end
