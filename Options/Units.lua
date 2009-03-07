local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_unit_options()
	local unit_options = {
		type = 'group',
		name = L["Units"],
		desc = L["Change settings for units."],
		args = {},
		childGroups = "tree",
	}
	
	local group_options = {
		type = 'group',
		name = L["Groups"],
		desc = L["Change settings for unit groups."],
		args = {},
		childGroups = "tree",
	}
	
	local next_order
	do
		local current = 0
		function next_order()
			current = current + 1
			return current
		end
	end
	
	local update, refresh
	do
		local update_funcs, refresh_funcs = {}, {}
		
		function update(type, unit)
			return update_funcs[type](unit)
		end
		
		function refresh(type, unit)
			return refresh_funcs[type](unit)
		end
		
		function update_funcs.groups(unit)
			for header in PitBull4:IterateHeadersForName(unit) do
				header:UpdateMembers(true, true)
			end
		end
		
		function update_funcs.units(unit)
			for frame in PitBull4:IterateFramesForClassification(unit, true) do
				frame:Update(true, true)
			end
		end
		
		function refresh_funcs.groups(unit)
			for header in PitBull4:IterateHeadersForName(unit) do
				header:RefreshLayout()
			end
		end
		
		function refresh_funcs.units(unit)
			for frame in PitBull4:IterateFramesForClassification(unit, true) do
				frame:RefreshLayout()
			end
		end
	end
	
	local function round(value)
		return math.floor(value + 0.5)
	end
	
	local function disabled(info)
		return InCombatLockdown()
	end
	
	local shared_args = {}
	local unit_args = {}
	local group_args = {}
	
	unit_args.enable = {
		name = L["Enable"],
		desc = L["Enable this unit."],
		type = 'toggle',
		order = next_order(),
		get = function(info)
			local unit = info[2]
			
			return PitBull4.db.profile.units[unit].enabled
		end,
		set = function(info, value)
			local unit = info[2]
			
			PitBull4.db.profile.units[unit].enabled = value
			
			if value then
				PitBull4:MakeSingletonFrame(unit)
			else
				for frame in PitBull4:IterateFramesForClassification(unit, true) do
					frame:Deactivate()
				end
			end
			
			PitBull4:RecheckConfigMode()
		end,
		disabled = disabled,
	}
	
	group_args.enable = {
		name = L["Enable"],
		desc = L["Enable this unit group."],
		type = 'toggle',
		order = next_order(),
		get = function(info)
			local group = info[2]
			
			return PitBull4.db.profile.groups[group].enabled
		end,
		set = function(info, value)
			local group = info[2]
			
			PitBull4.db.profile.groups[group].enabled = value
			
			if value then
				PitBull4:MakeGroupHeader(group, nil)
			else
				for header in PitBull4:IterateHeadersForName(group) do
					header:Hide()
				end
			end
			
			PitBull4:RecheckConfigMode()
		end,
		disabled = disabled,
	}
	
	shared_args.layout = {
		name = L["Layout"],
		desc = L["Which layout the unit should use. Note: Use the layout editor to change any layout settings."],
		type = 'select',
		order = next_order(),
		values = function(info)
			local t = {}
			for name in pairs(PitBull4.db.profile.layouts) do
				t[name] = name
			end
			return t
		end,
		get = function(info)
			local type = info[1]
			local unit = info[2]
			
			return PitBull4.db.profile[type][unit].layout
		end,
		set = function(info, value)
			local type = info[1]
			local unit = info[2]
			
			PitBull4.db.profile[type][unit].layout = value
			
			refresh(type, unit)
		end,
		disabled = disabled,
	}
	
	shared_args.horizontal_mirror = {
		name = L["Mirror horizontally"],
		desc = L["Whether all options will be mirrored, e.g. what would be on the left is now on the right and vice-versa."],
		order = next_order(),
		type = 'toggle',
		get = function(info)
			local type = info[1]
			local unit = info[2]
			
			return PitBull4.db.profile[type][unit].horizontal_mirror
		end,
		set = function(info, value)
			local type = info[1]
			local unit = info[2]
			
			PitBull4.db.profile[type][unit].horizontal_mirror = value
			
			update(type, unit)
		end,
		disabled = disabled,
	}
	
	shared_args.vertical_mirror = {
		name = L["Mirror vertically"],
		desc = L["Whether all options will be mirrored, e.g. what would be on the bottom is now on the top and vice-versa."],
		order = next_order(),
		type = 'toggle',
		get = function(info)
			local type = info[1]
			local unit = info[2]
			
			return PitBull4.db.profile[type][unit].vertical_mirror
		end,
		set = function(info, value)
			local type = info[1]
			local unit = info[2]
			
			PitBull4.db.profile[type][unit].vertical_mirror = value
			
			update(type, unit)
		end,
		disabled = disabled,
	}
	
	shared_args.scale = {
		name = L["Scale"],
		desc = L["The scale of the unit. This will be multiplied against the layout's scale."],
		order = next_order(),
		type = 'range',
		min = 0.5,
		max = 2,
		isPercent = true,
		step = 0.01,
		bigStep = 0.05,
		get = function(info)
			local type = info[1]
			local unit = info[2]
			
			return PitBull4.db.profile[type][unit].scale
		end,
		set = function(info, value)
			local type = info[1]
			local unit = info[2]
			
			PitBull4.db.profile[type][unit].scale = value
			
			refresh(type, unit)
		end,
		disabled = disabled,
	}
	
	shared_args.width_multiplier = {
		name = L["Width multiplier"],
		desc = L["A width multiplier applied to the unit. Your layout's width will be multiplied against this value."],
		order = next_order(),
		type = 'range',
		min = 0.5,
		max = 2,
		isPercent = true,
		step = 0.01,
		bigStep = 0.05,
		get = function(info)
			local type = info[1]
			local unit = info[2]
			
			return PitBull4.db.profile[type][unit].size_x
		end,
		set = function(info, value)
			local type = info[1]
			local unit = info[2]
			
			PitBull4.db.profile[type][unit].size_x = value
			
			refresh(type, unit)
		end,
		disabled = disabled,
	}
	
	shared_args.height_multiplier = {
		name = L["Height multiplier"],
		desc = L["A height multiplier applied to the unit. Your layout's height will be multiplied against this value."],
		order = next_order(),
		type = 'range',
		min = 0.5,
		max = 2,
		isPercent = true,
		step = 0.01,
		bigStep = 0.05,
		get = function(info)
			local type = info[1]
			local unit = info[2]
			
			return PitBull4.db.profile[type][unit].size_y
		end,
		set = function(info, value)
			local type = info[1]
			local unit = info[2]
			
			PitBull4.db.profile[type][unit].size_y = value
			
			refresh(type, unit)
		end,
		disabled = disabled,
	}
	
	shared_args.click_through = {
		name = L["Click-through"],
		desc = L["Whether the unit should be unclickable, allowing you to use it as a HUD without interfering with the game world."],
		order = next_order(),
		type = 'toggle',
		get = function(info)
			local type = info[1]
			local unit = info[2]
			
			return PitBull4.db.profile[type][unit].click_through
		end,
		set = function(info, value)
			local type = info[1]
			local unit = info[2]
			
			PitBull4.db.profile[type][unit].click_through = value
			
			refresh(type, unit)
		end,
		disabled = disabled,
	}
	
	unit_args.position_x = {
		name = L["Horizontal position"],
		desc = L["Horizontal position on the x-axis of the screen."],
		order = next_order(),
		type = 'range',
		min = -math.floor(GetScreenWidth() / 10) * 5,
		max = math.floor(GetScreenWidth() / 10) * 5,
		get = function(info)
			local unit = info[2]
			
			return round(PitBull4.db.profile.units[unit].position_x)
		end,
		set = function(info, value)
			local unit = info[2]
			
			PitBull4.db.profile.units[unit].position_x = value
			
			refresh("units", unit)
		end,
		step = 1,
		bigStep = 5,
		disabled = disabled,
	}
	
	unit_args.position_y = {
		name = L["Vertical position"],
		desc = L["Vertical position on the y-axis of the screen."],
		order = next_order(),
		type = 'range',
		min = -math.floor(GetScreenHeight() / 10) * 5,
		max = math.floor(GetScreenHeight() / 10) * 5,
		get = function(info)
			local unit = info[2]
			
			return round(PitBull4.db.profile.units[unit].position_y)
		end,
		set = function(info, value)
			local unit = info[2]
			
			PitBull4.db.profile.units[unit].position_y = value
			
			refresh("units", unit)
		end,
		step = 1,
		bigStep = 5,
		disabled = disabled,
	}
	
	group_args.sort_method = {
		-- TODO: check to see if party-only or not
		name = L["Sort method"],
		desc = L["How to sort the frames within the group."],
		type = 'select',
		order = next_order(),
		values = {
			INDEX = L["By index"],
			NAME = L["By name"],
		},
		get = function(info)
			local group = info[2]
			
			return PitBull4.db.profile.groups[group].sort_method
		end,
		set = function(info, value)
			local group = info[2]
			
			PitBull4.db.profile.groups[group].sort_method = value
			
			refresh("groups", group)
		end,
		disabled = disabled,
	}
	
	group_args.sort_direction = {
		-- TODO: check to see if party-only or not
		name = L["Sort direction"],
		desc = L["Which direction to sort the frames within a group."],
		type = 'select',
		order = next_order(),
		values = {
			ASC = L["Ascending"],
			DESC = L["Descending"],
		},
		get = function(info)
			local group = info[2]
			
			return PitBull4.db.profile.groups[group].sort_direction
		end,
		set = function(info, value)
			local group = info[2]
			
			PitBull4.db.profile.groups[group].sort_direction = value
			
			refresh("groups", group)
		end,
		disabled = disabled,
	}
	
	local VERTICAL_FIRST = {
		down_right = true,
		down_left = true,
		up_right = true,
		up_left = true,
	}
	
	group_args.vertical_spacing = {
		name = L["Vertical spacing"],
		desc = L["How many pixels between rows in this group."],
		order = next_order(),
		type = 'range',
		min = 0,
		max = 300,
		step = 1,
		bigStep = 5,
		get = function(info)
			local group = info[2]
			
			return PitBull4.db.profile.groups[group].vertical_spacing
		end,
		set = function(info, value)
			local group = info[2]
			
			PitBull4.db.profile.groups[group].vertical_spacing = value
			
			refresh("groups", group)
		end,
		disabled = disabled,
	}
	
	group_args.horizontal_spacing = {
		name = L["Horizontal spacing"],
		desc = L["How many pixels between columns in this group."],
		order = next_order(),
		type = 'range',
		min = 0,
		max = 300,
		step = 1,
		bigStep = 5,
		get = function(info)
			local group = info[2]
			
			return PitBull4.db.profile.groups[group].horizontal_spacing
		end,
		set = function(info, value)
			local group = info[2]
			
			PitBull4.db.profile.groups[group].horizontal_spacing = value
			
			refresh("groups", group)
		end,
		disabled = disabled,
	}
	
	group_args.direction = {
		name = L["Growth direction"],
		desc = L["Which way frames should placed."],
		order = next_order(),
		type = 'select',
		values = {
			down_right = ("%s, %s"):format(L["Rows down"], L["Columns right"]),
			down_left = ("%s, %s"):format(L["Rows down"], L["Columns left"]),
			up_right = ("%s, %s"):format(L["Rows up"], L["Columns right"]),
			up_left = ("%s, %s"):format(L["Rows up"], L["Columns left"]),
			right_down = ("%s, %s"):format(L["Columns right"], L["Rows down"]),
			right_up = ("%s, %s"):format(L["Columns right"], L["Rows up"]),
			left_down = ("%s, %s"):format(L["Columns left"], L["Rows down"]),
			left_up = ("%s, %s"):format(L["Columns left"], L["Rows up"]),
		},
		get = function(info)
			local group = info[2]
			
			return PitBull4.db.profile.groups[group].direction
		end,
		set = function(info, value)
			local group = info[2]
			
			PitBull4.db.profile.groups[group].direction = value
			
			refresh("groups", group)
		end,
		disabled = disabled,
	}
	
	group_args.units_per_column = {
		name = function(info)
			local group = info[2]
			
			if VERTICAL_FIRST[PitBull4.db.profile.groups[group].direction] then
				return L["Units per column"]
			else
				return L["Units per row"]
			end
		end,
		desc = function(info)
			local group = info[2]
			
			if VERTICAL_FIRST[PitBull4.db.profile.groups[group].direction] then
				return L["The maximum amount of units per column before making a new column."]
			else
				return L["The maximum amount of units per row before making a new row."]
			end
		end,
		order = next_order(),
		type = 'range',
		min = 1,
		max = MAX_RAID_MEMBERS,
		get = function(info)
			local group = info[2]
			
			return PitBull4.db.profile.groups[group].units_per_column
		end,
		set = function(info, value)
			local group = info[2]
			
			PitBull4.db.profile.groups[group].units_per_column = value
			
			refresh("groups", group)
		end,
		step = 1,
		disabled = disabled,
	}
	
	local current_order = 0
	
	for _, classification in ipairs(PitBull4.SINGLETON_CLASSIFICATIONS) do
		current_order = current_order + 1
		local args = {}
		for k, v in pairs(shared_args) do
			args[k] = v
		end
		for k, v in pairs(unit_args) do
			args[k] = v
		end
		
		unit_options.args[classification] = {
			type = 'group',
			name = PitBull4.Utils.GetLocalizedClassification(classification),
			order = current_order,
			args = args,
		}
	end
	
	for _, classification in ipairs(PitBull4.PARTY_CLASSIFICATIONS) do
		current_order = current_order + 1
		local args = {}
		for k, v in pairs(shared_args) do
			args[k] = v
		end
		for k, v in pairs(group_args) do
			args[k] = v
		end
		
		group_options.args[classification] = {
			type = 'group',
			name = PitBull4.Utils.GetLocalizedClassification(classification),
			order = current_order,
			args = args,
		}
	end
	
	return unit_options, group_options
end
