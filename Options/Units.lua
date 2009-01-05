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
	
	local shared_args = {
		enable = {
			name = L["Enable"],
			desc = L["Enable this unit."],
			type = 'toggle',
			order = 1,
			get = function(info)
				local classification = info[2]
				
				return PitBull4.db.profile.classifications[classification].enabled
			end,
			set = function(info, value)
				local classification = info[2]
				
				PitBull4.db.profile.classifications[classification].enabled = value
				
				if value then
					PitBull4:MakeSingletonFrame(classification)
				else
					for frame in PitBull4:IterateFramesForClassification(classification, true) do
						frame:Deactivate()
					end
				end
			end,
		},
		layout = {
			name = L["Layout"],
			desc = L["Which layout the unit should use. Note: Use the layout editor to change any layout settings."],
			type = 'select',
			order = 2,
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
				
				for frame in PitBull4:IterateFramesForClassification(classification, true) do
					frame:RefreshLayout()
				end
			end
		},
		horizontal_mirror = {
			name = L["Mirror horizontally"],
			desc = L["Whether all options will be mirrored, e.g. what would be on the left is now on the right and vice-versa."],
			order = 3,
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
		},
		vertical_mirror = {
			name = L["Mirror vertically"],
			desc = L["Whether all options will be mirrored, e.g. what would be on the bottom is now on the top and vice-versa."],
			order = 4,
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
		},
		scale = {
			name = L["Scale"],
			desc = L["The scale of the unit. This will be multiplied against the layout's scale."],
			order = 5,
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
				
				for frame in PitBull4:IterateFramesForClassification(classification, true) do
					frame:RefreshLayout()
				end
			end
		},
		width_multiplier = {
			name = L["Width multiplier"],
			desc = L["A width multiplier applied to the unit. Your layout's width will be multiplied against this value."],
			order = 6,
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
		},
		height_multiplier = {
			name = L["Height multiplier"],
			desc = L["A height multiplier applied to the unit. Your layout's height will be multiplied against this value."],
			order = 7,
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
		},
	}
	
	local singleton_args = {
		position_x = {
			name = L["Horizontal position"],
			desc = L["Horizontal position on the x-axis of the screen."],
			order = 8,
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
		},
		position_y = {
			name = L["Vertical position"],
			desc = L["Vertical position on the y-axis of the screen."],
			order = 8,
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
		},
	}
	
	local party_only_args = {
		sort_method = {
			name = L["Sort method"],
			desc = L["How to sort the frames within the group."],
			type = 'select',
			order = 8,
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
		},
		sort_direction = {
			name = L["Sort direction"],
			desc = L["Which direction to sort the frames within a group."],
			type = 'select',
			order = 9,
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
		
		unit_options.args[classification] = {
			type = 'group',
			name = PitBull4.Utils.GetLocalizedClassification(classification),
			order = current_order,
			args = args,
		}
	end
	
	return unit_options
end
