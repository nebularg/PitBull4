local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_layout_editor_bar_options()
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	
	local options = {
		name = L["Bars"],
		desc = L["Status bars graphically display a value from 0% to 100%."],
		type = 'group',
		childGroups = "tab",
		args = {}
	}
	
	local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
	LoadAddOn("AceGUI-3.0-SharedMediaWidgets")
	local AceGUI = LibStub("AceGUI-3.0")
	
	options.args.general = {
		type = 'group',
		name = L["General"],
		desc = L["Options that apply to all status bars."],
		order = 1,
		args = {}
	}
	
	options.args.general.args.texture = {
		type = 'select',
		name = L["Default texture"],
		desc = L["The texture of status bars, unless overridden."],
		order = 1,
		get = function(info)
			return GetLayoutDB(false).bar_texture
		end,
		set = function(info, value)
			GetLayoutDB(false).bar_texture = value

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
	
	options.args.general.args.spacing = {
		type = 'range',
		name = L["Spacing"],
		desc = L["Spacing in pixels between bars."],
		order = 2,
		min = 0,
		max = 10,
		step = 1,
		get = function(info)
			return GetLayoutDB(false).bar_spacing
		end,
		set = function(info, value)
			GetLayoutDB(false).bar_spacing = value

			UpdateFrames()
		end,
	}
	
	options.args.general.args.padding = {
		type = 'range',
		name = L["Padding"],
		desc = L["Padding in pixels between bars and the sides of the unit frame."],
		order = 3,
		min = 0,
		max = 10,
		step = 1,
		get = function(info)
			return GetLayoutDB(false).bar_padding
		end,
		set = function(info, value)
			GetLayoutDB(false).bar_padding = value

			UpdateFrames()
		end,
	}
	
	local bar_args = {}
	
	bar_args.enable = {
		type = 'toggle',
		name = L["Enable"],
		desc = L["Enable this status bar."],
		order = 1,
		get = function(info)
			return GetLayoutDB(info[#info-1]).enabled
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).enabled = value
			
			UpdateFrames()
		end
	}
	
	local disabled = function(info)
		return not GetLayoutDB(info[#info-1]).enabled
	end
	
	bar_args.side = {
		type = 'select',
		name = L["Side"],
		desc = L["Which side of the unit frame to place the status bar on. Note: For the left and right sides, your bar will be vertical rather than horizontal."],
		order = 2,
		get = function(info)
			return GetLayoutDB(info[#info-1]).side
		end,
		set = function(info, value)
			local db = GetLayoutDB(info[#info-1])
			db.side = value

			UpdateFrames()
		end,
		values = {
			center = "Center",
			left = "Left",
			right = "Right",
		},
		disabled = disabled,
	}
	
	bar_args.position = {
		type = 'select',
		name = L["Position"],
		desc = L["Where to place the bar in relation to other bars on the frame."],
		order = 3,
		values = function(info)
			local db = GetLayoutDB(info[#info-1])
			local side = db.side
			local t = {}
			local sort = {}
			for other_id, other_module in PitBull4:IterateModulesOfType("status_bar") do
				local other_db = GetLayoutDB(other_id)
				if side == other_db.side and other_db.enabled then
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
		end,
		disabled = disabled,
	}
	
	bar_args.texture = {
		type = 'select',
		name = L["Texture"],
		desc = L["What texture the status bar should use."],
		order = 4,
		get = function(info)
			return GetLayoutDB(info[#info-1]).texture or GetLayoutDB(false).bar_texture
		end,
		set = function(info, value)
			local default = GetLayoutDB(false).bar_texture
			if value == default then
				value = nil
			end
			GetLayoutDB(info[#info-1]).texture = value
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			local default = GetLayoutDB(false).bar_texture
			for k in pairs(LibSharedMedia:HashTable("statusbar")) do
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
			return not LibSharedMedia or #LibSharedMedia:List("statusbar") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Statusbar"] and "LSM30_Statusbar" or nil,
	}
	
	bar_args.size = {
		type = 'range',
		name = function(info)
			if GetLayoutDB(info[#info-1]).side == "center" then
				return L["Height"]
			else
				return L["Width"]
			end
		end,
		desc = function(info)
			if GetLayoutDB(info[#info-1]).side == "center" then
				return L["How tall the bar should be in relation to other bars."]
			else
				return L["How wide the bar should be in relation to other bars."]
			end
		end,
		order = 5,
		get = function(info)
			return GetLayoutDB(info[#info-1]).size
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).size = value

			UpdateFrames()
		end,
		min = 1,
		max = 12,
		step = 1,
		disabled = disabled,
	}
	
	bar_args.deficit = {
		type = 'toggle',
		name = L["Deficit"],
		desc = L["Drain the bar instead of filling it."],
		order = 6,
		get = function(info)
			return GetLayoutDB(info[#info-1]).deficit
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).deficit = value

			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	bar_args.reverse = {
		type = 'toggle',
		name = L["Reverse"],
		desc = L["Reverse the direction of the bar, filling from right-to-left instead of left-to-right."],
		order = 7,
		get = function(info)
			return GetLayoutDB(info[#info-1]).reverse
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).reverse = value

			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	bar_args.alpha = {
		type = 'range',
		name = L["Full opacity"],
		desc = L["How opaque the full section of the bar is."],
		order = 8,
		get = function(info)
			return GetLayoutDB(info[#info-1]).alpha
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).alpha = value

			UpdateFrames()
		end,
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		disabled = disabled,
	}
	
	bar_args.background_alpha = {
		type = 'range',
		name = L["Empty opacity"],
		desc = L["How opaque the empty section of the bar is."],
		order = 9,
		get = function(info)
			return GetLayoutDB(info[#info-1]).background_alpha
		end,
		set = function(info, value)
			GetLayoutDB(info[#info-1]).background_alpha = value

			UpdateFrames()
		end,
		min = 0,
		max = 1,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		disabled = disabled,
	}
	
	bar_args.toggle_custom_color = {
		type = 'toggle',
		name = L["Custom color"],
		desc = L["Whether to override the color and use a custom one."],
		order = -2,
		get = function(info)
			return not not GetLayoutDB(info[#info-1]).custom_color
		end,
		set = function(info, value)
			if value then
				GetLayoutDB(info[#info-1]).custom_color = { 0.75, 0.75, 0.75, 1 }
			else
				GetLayoutDB(info[#info-1]).custom_color = nil
			end
			
			UpdateFrames()
		end,
		disabled = disabled,
	}
	
	bar_args.custom_color = {
		type = 'color',
		name = L["Custom color"],
		desc = L["What color to override the bar with."],
		order = -1,
		hasAlpha = true,
		get = function(info)
			return unpack(GetLayoutDB(info[#info-1]).custom_color)
		end,
		set = function(info, r, g, b, a)
			local color = GetLayoutDB(info[#info-1]).custom_color
			color[1], color[2], color[3], color[4] = r, g, b, a
			
			UpdateFrames()
		end,
		hidden = function(info)
			return not GetLayoutDB(info[#info-1]).custom_color
		end,
		disabled = disabled,
	}
	
	local layout_functions = PitBull4.Options.layout_functions
	
	for id, module in PitBull4:IterateModulesOfType("status_bar", true) do
		local args = {}
		for k, v in pairs(bar_args) do
			args[k] = v
		end
		if layout_functions[module] then
			local data = { layout_functions[module](module) }
			layout_functions[module] = false
			for i = 1, #data, 2 do
				local k, v = data[i], data[i + 1]
				
				args[k] = v
				v.order = 100 + i
				local v_disabled = v.disabled
				function v.disabled(info)
					return disabled(info) or (v_disabled and v_disabled(info))
				end
			end
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