local _G = _G
local PitBull4 = _G.PitBull4

local CURRENT_LAYOUT = "Normal"

--- Return the DB dictionary for the current layout selected in the options frame.
-- Modules should be calling this and manipulating data within it.
-- @usage local db = PitBull.Options.GetLayoutDB(MyModule); db.someOption = "something"
-- @return the DB dictionary for the current layout
function PitBull4.Options.GetLayoutDB(module)
	if not module then
		return PitBull4.db.profile.layouts[CURRENT_LAYOUT]
	else
		if type(module) == "string" then
			module = PitBull4:GetModule(module)
		end
		return module:GetLayoutDB(CURRENT_LAYOUT)
	end
end

--- Update frames for the currently selected layout.
-- This should be called by modules after changing an option in the DB.
-- @usage PitBull.Options.UpdateFrames()
function PitBull4.Options.UpdateFrames()
	PitBull4:UpdateForLayout(CURRENT_LAYOUT)
end

local layout_functions = {}

--- Set the function to be called that will return a tuple of key-value pairs that will be merged onto the options table for the layout editor.
-- @name Module:SetLayoutOptionsFunction
-- @param func function to call
-- @usage MyModule:SetLayoutOptionsFunction(function(self)
--     return 'someOption', { name = "Some option", } -- etc
-- end)
function PitBull4.defaultModulePrototype:SetLayoutOptionsFunction(func)
	--@alpha@
	expect(func, 'typeof', 'function')
	expect(layout_functions[self], '==', nil)
	--@end-alpha@
	
	layout_functions[self] = func
end

function PitBull4.Options.get_layout_options()
	local function merge_onto(dict, ...)
		for i = 1, select('#', ...), 2 do
			dict[(select(i, ...))] = (select(i+1, ...))
		end
	end

	local function deep_copy(data)
		local t = {}
		for k, v in pairs(data) do
			if type(v) == "table" then
				t[k] = deep_copy(v)
			else
				t[k] = v
			end
		end
		return t
	end
	
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	
	local layout_options = {
		type = 'group',
		name = "Layout editor",
		args = {},
		childGroups = "tab",
	}
	
	layout_options.args.current_layout = {
		name = "Current layout",
		type = 'select',
		order = 1,
		values = function(info)
			local t = {}
			for name in pairs(PitBull4.db.profile.layouts) do
				t[name] = name
			end
			return t
		end,
		get = function(info)
			return CURRENT_LAYOUT
		end,
		set = function(info, value)
			CURRENT_LAYOUT = value
		end
	}
	
	layout_options.args.new_layout = {
		name = "New layout",
		desc = "This will copy the data of the currently-selected layout.",
		type = 'input',
		get = function(info) return "" end,
		set = function(info, value)
			local old_db = PitBull4.Options.GetLayoutDB()
			
			PitBull4.db.profile.layouts[value] = deep_copy(PitBull4.db.profile.layouts[CURRENT_LAYOUT])
			for id, module in PitBull4:IterateModules() do
				if module.db and module.db.profile and module.db.profile.layouts and module.db.profile.layouts[CURRENT_LAYOUT] then
					module.db.profile.layouts[value] = deep_copy(module.db.profile.layouts[CURRENT_LAYOUT])
				end
			end
			
			CURRENT_LAYOUT = value
		end,
		validate = function(info, value)
			if value:len() < 3 then
				return "Must be at least 3 characters long."
			end
		end,
	}

	layout_options.args.bars = {
		name = "Bars",
		type = 'group',
		childGroups = "tab",
		order = 1,
		args = {}
	}

	layout_options.args.icons = {
		name = "Icons",
		type = 'group',
		childGroups = "tab",
		order = 2,
		args = {}
	}

	layout_options.args.texts = {
		name = "Texts",
		type = 'group',
		order = 3,
		args = {}
	}

	layout_options.args.other = {
		name = "Other",
		type = 'group',
		order = 4,
		args = {}
	}
	
	local statusbar_args = {
		enable = {
			type = 'toggle',
			name = "Enable",
			order = 1,
			get = function(info)
				return not GetLayoutDB(info[3]).hidden
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).hidden = not value
				
				UpdateFrames()
			end
		},
		side = {
			type = 'select',
			name = "Side",
			order = 2,
			get = function(info)
				return GetLayoutDB(info[3]).side
			end,
			set = function(info, value)
				local db = GetLayoutDB(info[3])
				db.side = value

				UpdateFrames()
			end,
			values = {
				center = "Center",
				left = "Left",
				right = "Right",
			}
		},
		position = {
			type = 'select',
			name = "Position",
			order = 3,
			values = function(info)
				local db = GetLayoutDB(info[3])
				local side = db.side
				local t = {}
				for other_id, other_module in PitBull4:IterateModulesOfType("statusbar", true) do
					local other_db = GetLayoutDB(other_id)
					if side == other_db.side then
						local position = other_db.position
						while t[position] do
							position = position + 1e-5
							other_db.position = position
						end
						t[position] = other_module.name
					end
				end
				return t
			end,
			get = function(info)
				return GetLayoutDB(info[3]).position
			end,
			set = function(info, new_position)
				local id = info[3]
				local db = GetLayoutDB(id)
				
				local id_to_position = {}
				local bars = {}
				
				local old_position = db.position
				
				for other_id, other_module in PitBull4:IterateModulesOfType("statusbar", false) do
					local other_position = GetLayoutDB(other_id).position
					if other_id == id then
						other_position = new_position
					elseif other_position >= old_position and other_position <= new_position then
						other_position = other_position - 1
					elseif other_position <= old_position and other_position >= new_position then
						other_position = other_position + 1
					end
					
					id_to_position[other_id] = other_position
					bars[#bars+1] = other_id
				end
				
				table.sort(bars, function(alpha, bravo)
					return id_to_position[alpha] < id_to_position[bravo]
				end)
				
				for position, bar_id in ipairs(bars) do
					GetLayoutDB(bar_id).position = position
				end
				
				UpdateFrames()
			end
		},
		size = {
			type = 'range',
			name = function(info)
				if GetLayoutDB(info[3]).side == "center" then
					return "Height"
				else
					return "Width"
				end
			end,
			order = 4,
			get = function(info)
				return GetLayoutDB(info[3]).size
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).size = value

				UpdateFrames()
			end,
			min = 1,
			max = 12,
			step = 1,
		},
		deficit = {
			type = 'toggle',
			name = "Deficit",
			desc = "Drain the bar instead of filling it.",
			order = 5,
			get = function(info)
				return GetLayoutDB(info[3]).deficit
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).deficit = value

				UpdateFrames()
			end,
		},
		reverse = {
			type = 'toggle',
			name = "Reverse",
			desc = "Reverse the direction of the bar, filling from right-to-left instead of left-to-right",
			order = 6,
			get = function(info)
				return GetLayoutDB(info[3]).reverse
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).reverse = value

				UpdateFrames()
			end,
		},
		alpha = {
			type = 'range',
			name = "Full opacity",
			order = 7,
			get = function(info)
				return GetLayoutDB(info[3]).alpha
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).alpha = value

				UpdateFrames()
			end,
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
		},
		background_alpha = {
			type = 'range',
			name = "Empty opacity",
			order = 8,
			get = function(info)
				return GetLayoutDB(info[3]).background_alpha
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).background_alpha = value

				UpdateFrames()
			end,
			min = 0,
			max = 1,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
		},
	}
	
	for id, module in PitBull4:IterateModulesOfType("statusbar") do
		local args = {}
		for k, v in pairs(statusbar_args) do
			args[k] = v
		end
		if layout_functions[module] then
			merge_onto(args, layout_functions[module](module))
			layout_functions[module] = false
		end
		
		layout_options.args.bars.args[id] = {
			name = module.name,
			desc = module.description,
			type = 'group',
			args = args,
		}
	end
	
	local root_locations = {
		out_top_left = "Outside, Above-left",
		out_top = "Outside, Above-middle",
		out_top_right = "Outside, Above-right",
		out_bottom_left = "Outside, Below-left",
		out_bottom = "Outside, Below",
		out_bottom_right = "Outside, Below-right",
		out_left_top = "Outside, Left-top",
		out_left = "Outside, Left",
		out_left_bottom = "Outside, Left-bottom",
		out_right_top = "Outside, Right-top",
		out_right = "Outside, Right",
		out_right_bottom = "Outside, Right-bottom",
		
		in_center = "Inside, Middle",
		in_top_left = "Inside, Top-left",
		in_top = "Inside, Top",
		in_top_right = "Inside, Top-right",
		in_bottom_left = "Inside, Bottom-left",
		in_bottom = "Inside, Bottom",
		in_bottom_right = "Inside, Bottom-right",
		in_left = "Inside, Left",
		in_right = "Inside, Right",
		
		edge_top_left = "Edge, Top-left",
		edge_top = "Edge, Top",
		edge_top_right = "Edge, Top-right",
		edge_left = "Edge, Left",
		edge_right = "Edge, Right",
		edge_bottom_left = "Edge, Bottom-left",
		edge_bottom = "Edge, Bottom",
		edge_bottom_right = "Edge, Bottom-right",
	}
	
	local bar_locations = {
		out_left = "Outside, left",
		left = "Left",
		center = "Middle",
		right = "Right",
		out_right = "Outside, right",
	}
	
	local icon_args = {
		enable = {
			type = 'toggle',
			name = "Enable",
			order = 1,
			get = function(info)
				return not GetLayoutDB(info[3]).hidden
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).hidden = not value
				
				UpdateFrames()
			end
		},
		attachTo = {
			type = 'select',
			name = "Attach to",
			order = 2,
			get = function(info)
				return GetLayoutDB(info[3]).attachTo
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).attachTo = value
				
				UpdateFrames()
			end,
			values = function(info)
				local t = {}
				
				t["root"] = "Unit frame"
				
				for id, module in PitBull4:IterateModulesOfType("statusbar", true) do
					t[id] = module.name
				end
				
				return t
			end,
		},
		location = {
			type = 'select',
			name = "Location",
			order = 3,
			get = function(info)
				return GetLayoutDB(info[3]).location
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).location = value
				
				UpdateFrames()
			end,
			values = function(info)
				local attachTo = GetLayoutDB(info[3]).attachTo
				if attachTo == "root" then
					return root_locations
				else
					return bar_locations
				end
			end,
		},
		position = {
			type = 'select',
			name = "Position",
			order = 4,
			values = function(info)
				local db = GetLayoutDB(info[3])
				local attachTo = db.attachTo
				local location = db.location
				local t = {}
				for other_id, other_module in PitBull4:IterateModulesOfType("icon", true) do
					local other_db = GetLayoutDB(other_id)
					if attachTo == other_db.attachTo and location == other_db.location then
						local position = other_db.position
						while t[position] do
							position = position + 1e-5
							db[other_id].position = position
						end
						t[position] = other_module.name
					end
				end
				return t
			end,
			get = function(info)
				return GetLayoutDB(info[3]).position
			end,
			set = function(info, new_position)
				local id = info[3]
				local db = GetLayoutDB(id)
				
				local id_to_position = {}
				local icons = {}
				
				local old_position = db.position
				
				for other_id, other_module in PitBull4:IterateModulesOfType("icon", false) do
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
					icons[#icons+1] = other_id
				end
				
				table.sort(icons, function(alpha, bravo)
					return id_to_position[alpha] < id_to_position[bravo]
				end)
				
				for position, icon_id in ipairs(icons) do
					GetLayoutDB(icon_id).position = position
				end
				
				UpdateFrames()
			end
		},
		size = {
			type = 'range',
			name = "Size",
			order = 5,
			get = function(info)
				return GetLayoutDB(info[3]).size
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).size = value
				
				UpdateFrames()
			end,
			min = 0.5,
			max = 4,
			step = 0.01,
			bigStep = 0.05,
			isPercent = true,
		}
	}
	
	for id, module in PitBull4:IterateModulesOfType("icon") do
		local args = {}
		for k, v in pairs(icon_args) do
			args[k] = v
		end
		if layout_functions[module] then
			merge_onto(args, layout_functions[module]())
			layout_functions[module] = false
		end
		
		layout_options.args.icons.args[id] = {
			name = module.name,
			desc = module.description,
			type = 'group',
			args = args,
		}
	end
	
	return layout_options
end