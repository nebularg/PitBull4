local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_unit_options()
	local unit_options = {
		type = 'group',
		name = L["Units"],
		desc = L["Change individual settings for units and unit groups."],
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
	
	local shared_args = {}
	
	shared_args.enable = {
		name = L["Enable"],
		desc = L["Enable this unit."],
		type = 'toggle',
		order = next_order(),
		get = function(info)
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].enabled
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].enabled = value
			
			if PitBull4.Utils.IsSingletonUnitID(classification) then
				if value then
					PitBull4:MakeSingletonFrame(classification)
				else
					for frame in PitBull4:IterateFramesForClassification(classification, true) do
						frame:Deactivate()
					end
				end
			else
				if value then
					PitBull4:MakeGroupHeader(classification, nil)
				else
					for header in PitBull4:IterateHeadersForClassification(classification) do
						header:Hide()
					end
				end
			end
			
			PitBull4:RecheckConfigMode()
		end,
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].layout
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].layout = value
			
			for header in PitBull4:IterateHeadersForClassification(classification) do
				header:RefreshLayout(true)
			end
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:RefreshLayout()
			end
		end
	}
	
	shared_args.horizontal_mirror = {
		name = L["Mirror horizontally"],
		desc = L["Whether all options will be mirrored, e.g. what would be on the left is now on the right and vice-versa."],
		order = next_order(),
		type = 'toggle',
		get = function(info)
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].horizontal_mirror
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].horizontal_mirror = value
			
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:Update(true, true)
			end
		end
	}
	
	shared_args.vertical_mirror = {
		name = L["Mirror vertically"],
		desc = L["Whether all options will be mirrored, e.g. what would be on the bottom is now on the top and vice-versa."],
		order = next_order(),
		type = 'toggle',
		get = function(info)
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].vertical_mirror
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].vertical_mirror = value
			
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:Update(true, true)
			end
		end
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].scale
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].scale = value
			
			for header in PitBull4:IterateHeadersForClassification(classification) do
				header:RefreshLayout(true)
			end
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:RefreshLayout()
			end
		end
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].size_x
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].size_x = value
			
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:RefreshLayout()
			end
		end,
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].size_y
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].size_y = value
			
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:RefreshLayout()
			end
		end,
	}
	
	shared_args.click_through = {
		name = L["Click-through"],
		desc = L["Whether the unit should be unclickable, allowing you to use it as a HUD without interfering with the game world."],
		order = next_order(),
		type = 'toggle',
		get = function(info)
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].click_through
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].click_through = value
			
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:RefreshLayout()
			end
		end
	}
	
	local singleton_args = {}
	
	singleton_args.position_x = {
		name = L["Horizontal position"],
		desc = L["Horizontal position on the x-axis of the screen."],
		order = next_order(),
		type = 'range',
		min = -math.floor(GetScreenWidth() / 10) * 5,
		max = math.floor(GetScreenWidth() / 10) * 5,
		get = function(info)
			local classification = info[2]
			
			return math.floor(PitBull4.db.profile.classifications[classification].position_x + 0.5)
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].position_x = value
			
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:RefreshLayout()
			end
		end,
		step = 1,
		bigStep = 5,
	}
	
	singleton_args.position_y = {
		name = L["Vertical position"],
		desc = L["Vertical position on the y-axis of the screen."],
		order = next_order(),
		type = 'range',
		min = -math.floor(GetScreenHeight() / 10) * 5,
		max = math.floor(GetScreenHeight() / 10) * 5,
		get = function(info)
			local classification = info[2]
			
			return math.floor(PitBull4.db.profile.classifications[classification].position_y + 0.5)
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].position_y = value
			
			for frame in PitBull4:IterateFramesForClassification(classification, true) do
				frame:RefreshLayout()
			end
		end,
		step = 1,
		bigStep = 5,
	}
	
	local party_only_args = {}
	
	party_only_args.sort_method = {
		name = L["Sort method"],
		desc = L["How to sort the frames within the group."],
		type = 'select',
		order = next_order(),
		values = {
			INDEX = L["By index"],
			NAME = L["By name"],
		},
		get = function(info)
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].sort_method
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].sort_method = value
			
			for header in PitBull4:IterateHeadersForSuperClassification(classification) do
				header:RefreshLayout()
			end
		end,
	}
	
	party_only_args.sort_direction = {
		name = L["Sort direction"],
		desc = L["Which direction to sort the frames within a group."],
		type = 'select',
		order = next_order(),
		values = {
			ASC = L["Ascending"],
			DESC = L["Descending"],
		},
		get = function(info)
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].sort_direction
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].sort_direction = value
			
			for header in PitBull4:IterateHeadersForSuperClassification(classification) do
				header:RefreshLayout()
			end
		end,
	}
	
	local VERTICAL_FIRST = {
		down_right = true,
		down_left = true,
		up_right = true,
		up_left = true,
	}
	
	local group_args = {}
	
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].vertical_spacing
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].vertical_spacing = value
			
			for header in PitBull4:IterateHeadersForClassification(classification) do
				header:RefreshLayout()
			end
		end,
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].horizontal_spacing
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].horizontal_spacing = value
			
			for header in PitBull4:IterateHeadersForClassification(classification) do
				header:RefreshLayout()
			end
		end,
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].direction
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].direction = value
			
			for header in PitBull4:IterateHeadersForClassification(classification) do
				header:RefreshLayout()
			end
		end,
	}
	
	group_args.units_per_column = {
		name = function(info)
			local classification = info[2]
			
			if VERTICAL_FIRST[PitBull4.db.profile.classifications[classification].direction] then
				return L["Units per column"]
			else
				return L["Units per row"]
			end
		end,
		desc = function(info)
			local classification = info[2]
			
			if VERTICAL_FIRST[PitBull4.db.profile.classifications[classification].direction] then
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
			local classification = info[2]
			
			return PitBull4.db.profile.classifications[classification].units_per_column
		end,
		set = function(info, value)
			local classification = info[2]
			
			PitBull4.db.profile.classifications[classification].units_per_column = value
			
			for header in PitBull4:IterateHeadersForClassification("party") do
				header:RefreshLayout()
			end
		end,
		step = 1,
	}
	
	local current_order = 0
	
	for _, classification in ipairs(PitBull4.SINGLETON_CLASSIFICATIONS) do
		current_order = current_order + 1
		local args = {}
		for k, v in pairs(shared_args) do
			args[k] = v
		end
		for k, v in pairs(singleton_args) do
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
		if classification == "party" then
			for k, v in pairs(party_only_args) do
				args[k] = v
			end
		end
		for k, v in pairs(group_args) do
			args[k] = v
		end
		
		unit_options.args[classification] = {
			type = 'group',
			name = PitBull4.Utils.GetLocalizedClassification(classification),
			order = current_order,
			args = args,
		}
	end
	
	return unit_options
end
