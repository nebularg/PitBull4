local _G = _G
local PitBull4 = _G.PitBull4

function PitBull4.Options.get_unit_options()
	local unit_options = {
		type = 'group',
		name = "Units",
		args = {},
		childGroups = "tree",
	}
	
	for i, classification in ipairs(PitBull4.SINGLETON_CLASSIFICATIONS) do
		unit_options.args[classification] = {
			type = 'group',
			name = PitBull4.Utils.GetLocalizedClassification(classification),
			order = i,
			args = {
				enable = {
					name = "Enable",
					type = 'toggle',
					order = 1,
					get = function(info)
						return not PitBull4.db.profile.classifications[classification].hidden
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].hidden = not value
						
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
					name = "Layout",
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
						return PitBull4.db.profile.classifications[classification].layout
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].layout = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, true) do
							frame:RefreshLayout()
						end
					end
				},
				horizontal_mirror = {
					name = "Mirror horizontally",
					desc = "Whether all options will be mirrored, e.g. what would be on the left is now on the right and vice-versa.",
					order = 3,
					type = 'toggle',
					get = function(info)
						return PitBull4.db.profile.classifications[classification].horizontal_mirror
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].horizontal_mirror = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, true) do
							frame:Update(true, true)
						end
					end
				},
				vertical_mirror = {
					name = "Mirror vertically",
					desc = "Whether all options will be mirrored, e.g. what would be on the bottom is now on the top and vice-versa.",
					order = 4,
					type = 'toggle',
					get = function(info)
						return PitBull4.db.profile.classifications[classification].vertical_mirror
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].vertical_mirror = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, true) do
							frame:Update(true, true)
						end
					end
				},
				scale = {
					name = "Scale",
					desc = "The scale of the unit. This will be multiplied against the layout's scale.",
					order = 5,
					type = 'range',
					min = 0.5,
					max = 2,
					isPercent = true,
					step = 0.01,
					bigStep = 0.05,
					get = function(info)
						return PitBull4.db.profile.classifications[classification].scale
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].scale = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, true) do
							frame:RefreshLayout()
						end
					end
				},
				width_multiplier = {
					name = "Width multiplier",
					desc = "A width multiplier applied to the unit. Your layout's width will be multiplied against this value.",
					order = 6,
					type = 'range',
					min = 0.5,
					max = 2,
					isPercent = true,
					step = 0.01,
					bigStep = 0.05,
					get = function(info)
						return PitBull4.db.profile.classifications[classification].size_x
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].size_x = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, true) do
							frame:RefreshLayout()
						end
					end,
				},
				height_multiplier = {
					name = "Height multiplier",
					desc = "A height multiplier applied to the unit. Your layout's height will be multiplied against this value.",
					order = 7,
					type = 'range',
					min = 0.5,
					max = 2,
					isPercent = true,
					step = 0.01,
					bigStep = 0.05,
					get = function(info)
						return PitBull4.db.profile.classifications[classification].size_y
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].size_y = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, true) do
							frame:RefreshLayout()
						end
					end,
				},
			}
		}
	end
	
	return unit_options
end