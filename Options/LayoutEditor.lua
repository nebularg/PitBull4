local _G = _G
local PitBull4 = _G.PitBull4

local L = PitBull4.L

local CURRENT_LAYOUT = "Normal"
local CURRENT_CUSTOM_TEXT_MODULE
local CURRENT_TEXT_PROVIDER_MODULE
local CURRENT_TEXT_PROVIDER_ID

--- Return the DB dictionary for the current layout selected in the options frame.
-- Modules should be calling this and manipulating data within it.
-- @param module the module to check
-- @usage local db = PitBull.Options.GetLayoutDB(MyModule); db.some_option = "something"
-- @return the DB dictionary for the current layout
function PitBull4.Options.GetLayoutDB(module)
	--@alpha@
	expect(module, 'typeof', 'string;table')
	if type(module) == "table" then
		expect(module.id, 'inset', PitBull4.modules)
	end
	--@end-alpha@
	if type(module) == "string" then
		module = PitBull4:GetModule(module)
	end
	return module:GetLayoutDB(CURRENT_LAYOUT)
end

--- Return the DB dictionary for the current text for the current layout selected in the options frame.
-- TextProvider modules should be calling this and manipulating data within it.
-- @usage local db = PitBull.Options.GetTextLayoutDB(); db.some_option = "something"
-- @return the DB dictionary for the current text
function PitBull4.Options.GetTextLayoutDB()
	if not CURRENT_TEXT_PROVIDER_MODULE then
		return
	end
	
	return CURRENT_TEXT_PROVIDER_MODULE:GetLayoutDB(CURRENT_LAYOUT).texts[CURRENT_TEXT_PROVIDER_ID]
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
			local k, v = select(i, ...)
			if not v.order then
				v.order = 100 + i
			end
			dict[k] = v
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
	
	local GetTextLayoutDB = PitBull4.Options.GetTextLayoutDB
	
	local layout_options = {
		type = 'group',
		name = L["Layout editor"],
		desc = L["Edit the way your frames look, including the controls on your frames."],
		args = {},
		childGroups = "tab",
	}
	
	layout_options.args.current_layout = {
		name = L["Current layout"],
		desc = L["Change the layout you are currently editing."],
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
		name = L["New layout"],
		desc = L["Create a new layout. This will copy the data of the currently-selected layout."],
		type = 'input',
		get = function(info) return "" end,
		set = function(info, value)
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
				return L["Must be at least 3 characters long."]
			end
			return true
		end,
	}

	layout_options.args.bars = {
		name = L["Bars"],
		desc = L["Status bars graphically display a value from 0% to 100%."],
		type = 'group',
		childGroups = "tab",
		order = 1,
		args = {}
	}

	layout_options.args.indicators = {
		name = L["Indicators"],
		desc = L["Indicators are icons or other graphical displays that convey a specific, usually temporary, status."],
		type = 'group',
		childGroups = "tab",
		order = 2,
		args = {}
	}

	layout_options.args.texts = {
		name = L["Texts"],
		desc = L["Texts convey information in a non-graphical manner."],
		type = 'group',
		order = 3,
		args = {}
	}
	
	layout_options.args.faders = {
		name = L["Faders"],
		desc = L["Faders cause the unit frame to become more or less opaque on certain conditions."],
		type = 'group',
		order = 4,
		args = {}
	}

	layout_options.args.other = {
		name = L["Other"],
		type = 'group',
		childGroups = "tab",
		order = 6,
		args = {}
	}
	
	local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
	LoadAddOn("AceGUI-3.0-SharedMediaWidgets")
	local AceGUI = LibStub("AceGUI-3.0")
	
	layout_options.args.bars.args.texture = {
		type = 'select',
		name = L["Default texture"],
		desc = L["The texture of status bars, unless overridden."],
		order = 1,
		get = function(info)
			return PitBull4.db.profile.layouts[CURRENT_LAYOUT].status_bar_texture
		end,
		set = function(info, value)
			PitBull4.db.profile.layouts[CURRENT_LAYOUT].status_bar_texture = value

			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			for k in pairs(LibSharedMedia:HashTable("statusbar")) do
				t[k] = k
			end
			return t
		end,
		hidden = function(info)
			return not LibSharedMedia or #LibSharedMedia:List("statusbar") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Statusbar"] and "LSM30_Statusbar" or nil,
	}
	
	local status_bar_args = {
		enable = {
			type = 'toggle',
			name = L["Enable"],
			desc = L["Enable this status bar."],
			order = 1,
			get = function(info)
				return GetLayoutDB(info[3]).enabled
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).enabled = value
				
				UpdateFrames()
			end
		},
		side = {
			type = 'select',
			name = L["Side"],
			desc = L["Which side of the unit frame to place the status bar on. Note: For the left and right sides, your bar will be vertical rather than horizontal."],
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
			name = L["Position"],
			desc = L["Where to place the bar in relation to other bars on the frame."],
			order = 3,
			values = function(info)
				local db = GetLayoutDB(info[3])
				local side = db.side
				local t = {}
				for other_id, other_module in PitBull4:IterateModulesOfType("status_bar") do
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
				
				for other_id, other_module in PitBull4:IterateModulesOfType("status_bar", true) do
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
		texture = {
			type = 'select',
			name = L["Texture"],
			desc = L["What texture the status bar should use."],
			order = 4,
			get = function(info)
				return GetLayoutDB(info[3]).texture or PitBull4.db.profile.layouts[CURRENT_LAYOUT].status_bar_texture
			end,
			set = function(info, value)
				local default = PitBull4.db.profile.layouts[CURRENT_LAYOUT].status_bar_texture
				if value == default then
					value = nil
				end
				GetLayoutDB(info[3]).texture = value
				
				UpdateFrames()
			end,
			values = function(info)
				local t = {}
				local default = PitBull4.db.profile.layouts[CURRENT_LAYOUT].status_bar_texture
				for k in pairs(LibSharedMedia:HashTable("statusbar")) do
					if k == default then
						t[k] = ("%s (Default)"):format(k)
					else
						t[k] = k
					end
				end
				return t
			end,
			hidden = function(info)
				return not LibSharedMedia or #LibSharedMedia:List("statusbar") <= 1
			end,
			dialogControl = AceGUI.WidgetRegistry["LSM30_Statusbar"] and "LSM30_Statusbar" or nil,
		},
		size = {
			type = 'range',
			name = function(info)
				if GetLayoutDB(info[3]).side == "center" then
					return L["Height"]
				else
					return L["Width"]
				end
			end,
			desc = function(info)
				if GetLayoutDB(info[3]).side == "center" then
					return L["How tall the bar should be in relation to other bars."]
				else
					return L["How wide the bar should be in relation to other bars."]
				end
			end,
			order = 5,
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
			name = L["Deficit"],
			desc = L["Drain the bar instead of filling it."],
			order = 6,
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
			name = L["Reverse"],
			desc = L["Reverse the direction of the bar, filling from right-to-left instead of left-to-right."],
			order = 7,
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
			name = L["Full opacity"],
			desc = L["How opaque the full section of the bar is."],
			order = 8,
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
			name = L["Empty opacity"],
			desc = L["How opaque the empty section of the bar is."],
			order = 9,
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
	
	for id, module in PitBull4:IterateModulesOfType("status_bar", true) do
		local args = {}
		for k, v in pairs(status_bar_args) do
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
			hidden = function(info)
				return not module:IsEnabled()
			end,
		}
	end
	
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
	
	local bar_locations = {
		out_left = ("%s, %s"):format(L["Outside"], L["Left"]),
		left = L["Left"],
		center = L["Middle"],
		right = L["Right"],
		out_right = ("%s, %s"):format(L["Outside"], L["Right"]),
	}
	
	local indicator_args = {
		enable = {
			type = 'toggle',
			name = L["Enable"],
			desc = L["Enable this indicator."],
			order = 1,
			get = function(info)
				return GetLayoutDB(info[3]).enabled
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).enabled = value
				
				UpdateFrames()
			end
		},
		attach_to = {
			type = 'select',
			name = L["Attach to"],
			desc = L["Which control to attach to."],
			order = 2,
			get = function(info)
				return GetLayoutDB(info[3]).attach_to
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).attach_to = value
				
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
		},
		location = {
			type = 'select',
			name = L["Location"],
			desc = L["Where on the control to place the indicator."],
			order = 3,
			get = function(info)
				return GetLayoutDB(info[3]).location
			end,
			set = function(info, value)
				GetLayoutDB(info[3]).location = value
				
				UpdateFrames()
			end,
			values = function(info)
				local attach_to = GetLayoutDB(info[3]).attach_to
				if attach_to == "root" then
					return root_locations
				else
					return bar_locations
				end
			end,
		},
		position = {
			type = 'select',
			name = L["Position"],
			desc = L["Where to place the indicator compared to others in the same location."],
			order = 4,
			values = function(info)
				local db = GetLayoutDB(info[3])
				local attach_to = db.attach_to
				local location = db.location
				local t = {}
				for other_id, other_module in PitBull4:IterateModulesOfType("icon", "custom_indicator") do
					local other_db = GetLayoutDB(other_id)
					if attach_to == other_db.attach_to and location == other_db.location then
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
			end
		},
		size = {
			type = 'range',
			name = L["Size"],
			desc = L["Size of the indicator."],
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
	
	for id, module in PitBull4:IterateModulesOfType("icon", "custom_indicator", true) do
		local args = {}
		for k, v in pairs(indicator_args) do
			args[k] = v
		end
		if layout_functions[module] then
			merge_onto(args, layout_functions[module](module))
			layout_functions[module] = false
		end
		
		layout_options.args.indicators.args[id] = {
			name = module.name,
			desc = module.description,
			type = 'group',
			args = args,
			hidden = function(info)
				return not module:IsEnabled()
			end,
		}
	end
	
	local function disabled()
		return not CURRENT_TEXT_PROVIDER_MODULE and not CURRENT_CUSTOM_TEXT_MODULE
	end
	
	layout_options.args.texts.args.current_text = {
		name = L["Current text"],
		desc = L["Change the current text that you are editing."],
		type = 'select',
		order = 1,
		values = function(info)
			local t = {}
			local first, first_module, first_id
			for id, module in PitBull4:IterateModulesOfType("text_provider") do
				local texts_db = module:GetLayoutDB(CURRENT_LAYOUT).texts
				for i = 1, texts_db.n do
					local v = texts_db[i]
					local key = ("%s;%03d"):format(id, i)
					if not first then
						first = key
						first_module = module
						first_id = i
					end
					t[key] = v.name or L["<Unnamed>"]
				end
			end
			for id, module in PitBull4:IterateModulesOfType("custom_text") do
				t[id] = module.name
				if not first then
					first = key
					first_module = module
					first_id = nil
				end
			end
			if (not CURRENT_TEXT_PROVIDER_MODULE or not t[("%s;%03d"):format(CURRENT_TEXT_PROVIDER_MODULE.id, CURRENT_TEXT_PROVIDER_ID)]) and (not CURRENT_CUSTOM_TEXT_MODULE or not t[CURRENT_CUSTOM_TEXT_MODULE.id]) then
				if first_id then
					CURRENT_TEXT_PROVIDER_MODULE = first_module
					CURRENT_TEXT_PROVIDER_ID = first_id
					CURRENT_CUSTOM_TEXT_MODULE = nil
				else
					CURRENT_TEXT_PROVIDER_MODULE = nil
					CURRENT_TEXT_PROVIDER_ID = nil
					CURRENT_CUSTOM_TEXT_MODULE = first_module
				end
			end
			return t
		end,
		get = function(info)
			if CURRENT_TEXT_PROVIDER_MODULE then
				return ("%s;%03d"):format(CURRENT_TEXT_PROVIDER_MODULE.id, CURRENT_TEXT_PROVIDER_ID)
			elseif CURRENT_CUSTOM_TEXT_MODULE then
				return CURRENT_CUSTOM_TEXT_MODULE.id
			else
				return nil
			end
		end,
		set = function(info, value)
			local module_name, id = (";"):split(value)
			if id then
				for m_id, m in PitBull4:IterateModulesOfType("text_provider") do
					if module_name == m_id then
						CURRENT_TEXT_PROVIDER_MODULE = m
						CURRENT_TEXT_PROVIDER_ID = id+0
						CURRENT_CUSTOM_TEXT_MODULE = nil
					end
				end
			else
				for m_id, m in PitBull4:IterateModulesOfType("custom_text") do
					if module_name == m_id then
						CURRENT_TEXT_PROVIDER_MODULE = nil
						CURRENT_TEXT_PROVIDER_ID = nil
						CURRENT_CUSTOM_TEXT_MODULE = m
					end
				end
			end
		end,
		disabled = disabled
	}
	
	local function text_name_validate(info, value)
		if value:len() < 3 then
			return L["Must be at least 3 characters long."]
		end
		
		for id, module in PitBull4:IterateModulesOfType("text_provider") do
			local texts_db = module:GetLayoutDB(CURRENT_LAYOUT).texts
			
			for i = 1, texts_db.n do
				if texts_db[i].name and value:lower() == texts_db[i].name:lower() then
					return L["'%s' is already a text."]:format(value)
				end
			end
		end
		
		for id, module in PitBull4:IterateModulesOfType("text_provider") do
			return true -- found a module
		end
		return L["You have no enabled text providers."]
	end
	
	layout_options.args.texts.args.new_text = {
		name = L["New text"],
		desc = L["This will make a new text for the layout."],
		type = 'input',
		order = 2,
		get = function(info) return "" end,
		set = function(info, value)
			local module = CURRENT_TEXT_PROVIDER_MODULE
			
			if not module then
				for id, m in PitBull4:IterateModulesOfType("text_provider") do
					module = m
					break
				end
				
				assert(module) -- the validate function should verify that at least one module exists
			end
			
			local texts_db = module:GetLayoutDB(CURRENT_LAYOUT).texts
			
			texts_db.n = texts_db.n + 1
			local db = texts_db[texts_db.n]
			db.name = value
			
			CURRENT_TEXT_PROVIDER_MODULE = module
			CURRENT_TEXT_PROVIDER_ID = texts_db.n
			
			UpdateFrames()
		end,
		validate = text_name_validate,
	}
	
	layout_options.args.texts.args.font = {
		type = 'select',
		name = L["Default font"],
		desc = L["The font of texts, unless overridden."],
		order = 3,
		get = function(info)
			return PitBull4.db.profile.layouts[CURRENT_LAYOUT].font
		end,
		set = function(info, value)
			PitBull4.db.profile.layouts[CURRENT_LAYOUT].font = value

			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			for k in pairs(LibSharedMedia:HashTable("font")) do
				t[k] = k
			end
			return t
		end,
		hidden = function(info)
			return not LibSharedMedia or #LibSharedMedia:List("font") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Font"] and "LSM30_Font" or nil,
	}
	
	layout_options.args.texts.args.edit = {
		type = 'group',
		name = L["Edit text"],
		inline = true,
		args = {},
	}
	
	layout_options.args.texts.args.edit.args.remove = {
		type = 'execute',
		name = L["Remove"],
		desc = L["Remove this text."],
		order = 1,
		func = function()
			local texts_db = CURRENT_TEXT_PROVIDER_MODULE:GetLayoutDB(CURRENT_LAYOUT).texts
			
			table.remove(texts_db, CURRENT_TEXT_PROVIDER_ID)
			local n = texts_db.n - 1
			texts_db.n = n
			if n >= 1 then
				if CURRENT_TEXT_PROVIDER_ID > n then
					CURRENT_TEXT_PROVIDER_ID = n
				end
			else
				CURRENT_TEXT_PROVIDER_MODULE = nil
				CURRENT_TEXT_PROVIDER_ID = nil
				for id, m in PitBull4:IterateModulesOfType("text_provider") do
					local texts_db = m:GetLayoutDB(CURRENT_LAYOUT).texts
					
					if texts_db.n > 0 then
						CURRENT_TEXT_PROVIDER_MODULE = m
						CURRENT_TEXT_PROVIDER_ID = 1
						break
					end
				end
			end
			
			UpdateFrames()
		end,
		disabled = disabled,
		hidden = function(info)
			return not not CURRENT_CUSTOM_TEXT_MODULE
		end
	}
	
	layout_options.args.texts.args.edit.args.enabled = {
		type = 'toggle',
		name = L["Enable"],
		desc = L["Enable this text."],
		order = 1,
		get = function(info)
			return CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).enabled
		end,
		set = function(info, value)
			CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).enabled = value
			
			UpdateFrames()
		end,
		hidden = function(info)
			return not CURRENT_CUSTOM_TEXT_MODULE
		end,
	}
	
	layout_options.args.texts.args.edit.args.name = {
		type = 'input',
		name = L["Name"],
		order = 2,
		desc = function()
			local db = GetTextLayoutDB()
			return L["Rename the '%s' text."]:format(db and db.name or L["<Unnamed>"])
		end,
		get = function(info)
			local db = GetTextLayoutDB()
			return db and db.name or L["<Unnamed>"]
		end,
		set = function(info, value)
			GetTextLayoutDB().name = value
			
			UpdateFrames()
		end,
		validate = text_name_validate,
		disabled = disabled,
		hidden = function(info)
			return not not CURRENT_CUSTOM_TEXT_MODULE
		end
	}
	
	layout_options.args.texts.args.edit.args.provider = {
		type = 'select',
		name = L["Type"],
		desc = L["What text provider is used for this text."],
		order = 3,
		get = function(info)
			return CURRENT_TEXT_PROVIDER_MODULE and CURRENT_TEXT_PROVIDER_MODULE.id
		end,
		set = function(info, value)
			if value == CURRENT_TEXT_PROVIDER_MODULE.id then
				return
			end
			
			local texts_db = CURRENT_TEXT_PROVIDER_MODULE:GetLayoutDB(CURRENT_LAYOUT).texts
			
			local old_db = table.remove(texts_db, CURRENT_TEXT_PROVIDER_ID)
			local n = texts_db.n - 1
			texts_db.n = n
			
			CURRENT_TEXT_PROVIDER_MODULE = Pitbull4:GetModule(value)
			texts_db = CURRENT_TEXT_PROVIDER_MODULE:GetLayoutDB(CURRENT_LAYOUT).texts
			n = texts_db.n + 1
			texts_db.n = n
			
			local new_db = texts_db[n]
			new_db.name = old_db.name
			new_db.size = old_db.size
			new_db.attach_to = old_db.attach_to
			new_db.location = old_db.location
			new_db.position = old_db.position
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			for id, m in PitBull4:IterateModulesOfType("text_provider") do
				t[id] = m.name
			end
			return t
		end,
		disabled = disabled,
		hidden = function(info)
			return not not CURRENT_CUSTOM_TEXT_MODULE
		end
	}
	
	layout_options.args.texts.args.edit.args.attach_to = {
		type = 'select',
		name = L["Attach to"],
		desc = L["Which control to attach to."],
		order = 4,
		get = function(info)
			if CURRENT_CUSTOM_TEXT_MODULE then
				return CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).attach_to
			end
			if not CURRENT_TEXT_PROVIDER_MODULE then
				return
			end
			return GetTextLayoutDB().attach_to
		end,
		set = function(info, value)
			if CURRENT_CUSTOM_TEXT_MODULE then
				CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).attach_to = value
			else
				GetTextLayoutDB().attach_to = value
			end
			
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
	
	layout_options.args.texts.args.edit.args.location = {
		type = 'select',
		name = L["Location"],
		desc = L["Where on the control to place the text."],
		order = 5,
		get = function(info)
			if CURRENT_CUSTOM_TEXT_MODULE then
				return CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).location
			end
			if not CURRENT_TEXT_PROVIDER_MODULE then
				return nil
			end
			return GetTextLayoutDB().location
		end,
		set = function(info, value)
			if CURRENT_CUSTOM_TEXT_MODULE then
				CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).location = value
			else
				GetTextLayoutDB().location = value
			end
			
			UpdateFrames()
		end,
		values = function(info)
			local attach_to
			if CURRENT_CUSTOM_TEXT_MODULE then
				attach_to = CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).attach_to
			elseif CURRENT_TEXT_PROVIDER_MODULE then
				attach_to = GetTextLayoutDB().attach_to
			else
				attach_to = "root"
			end
			if attach_to == "root" then
				return root_locations
			else
				return bar_locations
			end
		end,
		disabled = disabled,
	}
	
	layout_options.args.texts.args.edit.args.font = {
		type = 'select',
		name = L["Font"],
		desc = L["Which font to use for this text."],
		order = 4,
		get = function(info)
			local font
			if CURRENT_CUSTOM_TEXT_MODULE then
				font = CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).font
			elseif CURRENT_TEXT_PROVIDER_MODULE then
				font = GetTextLayoutDB().font
			end
			return font or PitBull4.db.profile.layouts[CURRENT_LAYOUT].font
		end,
		set = function(info, value)
			local default = PitBull4.db.profile.layouts[CURRENT_LAYOUT].font
			if value == default then
				value = nil
			end
			
			if CURRENT_CUSTOM_TEXT_MODULE then
				CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).font = value
			else
				GetTextLayoutDB().font = value
			end
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			local default = PitBull4.db.profile.layouts[CURRENT_LAYOUT].font
			for k in pairs(LibSharedMedia:HashTable("font")) do
				if k == default then
					t[k] = ("%s (Default)"):format(k)
				else
					t[k] = k
				end
			end
			return t
		end,
		disabled = disabled,
		hidden = function(info)
			return not LibSharedMedia or #LibSharedMedia:List("font") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Font"] and "LSM30_Font" or nil,
	}
	
	layout_options.args.texts.args.edit.args.size = {
		type = 'range',
		name = L["Size"],
		desc = L["Size of the text."],
		order = 7,
		get = function(info)
			if CURRENT_CUSTOM_TEXT_MODULE then
				return CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).size
			end
			if not CURRENT_TEXT_PROVIDER_MODULE then
				return 1
			end
			return GetTextLayoutDB().size
		end,
		set = function(info, value)
			if CURRENT_CUSTOM_TEXT_MODULE then
				CURRENT_CUSTOM_TEXT_MODULE:GetLayoutDB(CURRENT_LAYOUT).size = value
			else
				GetTextLayoutDB().size = value
			end
			
			UpdateFrames()
		end,
		min = 0.5,
		max = 3,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		disabled = disabled,
	}
	
	for id, module in PitBull4:IterateModulesOfType("text_provider", true) do
		if layout_functions[module] then
			local t = { layout_functions[module](module) }
			layout_functions[module] = false
			
			local order = 100
			for i = 1, #t, 2 do
				local k = t[i]
				local v = t[i+1]
				
				order = order + 1
				
				v.order = order
				
				local old_disabled = v.disabled
				v.disabled = function(info)
					return disabled(info) or (old_disabled and old_disabled(info))
				end
				
				local old_hidden = v.hidden
				v.hidden = function(info)
					return module ~= CURRENT_TEXT_PROVIDER_MODULE or (old_hidden and old_hidden(info))
				end
				
				layout_options.args.texts.args.edit.args[id .. "-" .. k] = v
			end
		end
	end
	
	for id, module in PitBull4:IterateModulesOfType("custom_text", true) do
		if layout_functions[module] then
			local t = { layout_functions[module](module) }
			layout_functions[module] = false
			
			local order = 100
			for i = 1, #t, 2 do
				local k = t[i]
				local v = t[i+1]
				
				order = order + 1
				
				v.order = order
				
				local old_disabled = v.disabled
				v.disabled = function(info)
					return disabled(info) or (old_disabled and old_disabled(info))
				end
				
				local old_hidden = v.hidden
				v.hidden = function(info)
					return module ~= CURRENT_CUSTOM_TEXT_MODULE or (old_hidden and old_hidden(info))
				end
				
				layout_options.args.texts.args.edit.args[id .. "-" .. k] = v
			end
		end
	end
	
	layout_options.args.faders.args.min_opacity = {
		type = 'range',
		name = L["Minimum opacity"],
		desc = L["The minimum opacity that a shown frame can be."],
		order = 1,
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			return PitBull4.db.profile.layouts[CURRENT_LAYOUT].opacity_min
		end,
		set = function(info, value)
			local db = PitBull4.db.profile.layouts[CURRENT_LAYOUT]
			if value > db.opacity_max then
				value = db.opacity_max
			end
			db.opacity_min = value
			
			UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}
	
	layout_options.args.faders.args.max_opacity = {
		type = 'range',
		name = L["Maximum opacity"],
		desc = L["The maximum opacity that a shown frame can be."],
		order = 2,
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			return PitBull4.db.profile.layouts[CURRENT_LAYOUT].opacity_max
		end,
		set = function(info, value)
			local db = PitBull4.db.profile.layouts[CURRENT_LAYOUT]
			if value < db.opacity_min then
				value = db.opacity_min
			end
			db.opacity_max = value
			
			UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}
	
	for id, module in PitBull4:IterateModulesOfType("fader", true) do
		layout_options.args.faders.args[id] = {
			type = 'group',
			inline = true,
			name = module.name,
			desc = module.description,
			args = {
				enable = {
					type = 'toggle',
					name = L["Enable"],
					desc = L["Enable this fader."],
					get = function(info)
						return module:GetLayoutDB(CURRENT_LAYOUT).enabled
					end,
					set = function(info, value)
						module:GetLayoutDB(CURRENT_LAYOUT).enabled = value
						
						UpdateFrames()
						PitBull4:RecheckAllOpacities()
					end,
				},
			},
			hidden = function(info)
				return not module:IsEnabled()
			end
		}
		
		local args = layout_options.args.faders.args[id].args
		
		if layout_functions[module] then
			local t = { layout_functions[module](module) }
			layout_functions[module] = false

			local order = 100
			for i = 1, #t, 2 do
				local k = t[i]
				local v = t[i+1]

				order = order + 1

				v.order = order
				
				args[k] = v
			end
		end
	end
	
	layout_options.args.other.args.size = {
		type = 'group',
		name = L["Size"],
		desc = L["Size of the unit frame."],
		args = {
			width = {
				type = 'range',
				name = L["Width"],
				desc = L["Width of the unit frame."],
				min = 20,
				max = 400,
				step = 1,
				bigStep = 5,
				order = 1,
				get = function(info)
					return PitBull4.db.profile.layouts[CURRENT_LAYOUT].size_x
				end,
				set = function(info, value)
					PitBull4.db.profile.layouts[CURRENT_LAYOUT].size_x = value
					
					for frame in PitBull4:IterateFramesForLayout(CURRENT_LAYOUT, true) do
						frame:RefreshLayout()
					end
				end
			},
			height = {
				type = 'range',
				name = L["Height"],
				desc = L["Height of the unit frame."],
				min = 5,
				max = 400,
				step = 1,
				bigStep = 5,
				order = 2,
				get = function(info)
					return PitBull4.db.profile.layouts[CURRENT_LAYOUT].size_y
				end,
				set = function(info, value)
					PitBull4.db.profile.layouts[CURRENT_LAYOUT].size_y = value
					
					for frame in PitBull4:IterateFramesForLayout(CURRENT_LAYOUT, true) do
						frame:RefreshLayout()
					end
				end
			},
			scale = {
				type = 'range',
				name = L["Scale"],
				desc = L["Multiplicative scale of the unit frame."],
				min = 0.5,
				max = 2,
				step = 0.01,
				bigStep = 0.05,
				order = 3,
				isPercent = true,
				get = function(info)
					return PitBull4.db.profile.layouts[CURRENT_LAYOUT].scale
				end,
				set = function(info, value)
					PitBull4.db.profile.layouts[CURRENT_LAYOUT].scale = value
					
					for frame in PitBull4:IterateFramesForLayout(CURRENT_LAYOUT, true) do
						frame:RefreshLayout()
					end
				end
			},
		}
	}
	
	for id, module in PitBull4:IterateModulesOfType("custom", true) do
		if layout_functions[module] then
			local t = { layout_functions[module](module) }
			layout_functions[module] = false
			
			local top_level = (t[1] == true)
			if top_level then
				table.remove(t, 1)
			end
			
			local args = top_level and layout_options.args or layout_options.args.other.args
			
			args[id] = {
				type = 'group',
				name = module.name,
				desc = module.description,
				childGroups = 'tab',
				order = 5,
				hidden = function(info)
					return not module:IsEnabled()
				end,
				args = {
					enable = {
						type = 'toggle',
						name = L["Enable"],
						desc = L["Enable this module for this layout."],
						order = 1,
						get = function(info)
							return GetLayoutDB(module).enabled
						end,
						set = function(info, value)
							GetLayoutDB(module).enabled = value

							UpdateFrames()
						end
					},
				},
			}
			
			local order = 100
			for i = 1, #t, 2 do
				local k = t[i]
				local v = t[i+1]
				
				order = order + 1
				
				v.order = order
				
				args[id].args[k] = v
			end
		end
	end
	
	return layout_options
end
