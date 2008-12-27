local _G = _G
local PitBull4 = _G.PitBull4

function PitBull4.Options.get_unit_options()
	local unit_options = {
		type = 'group',
		name = "Units",
		args = {},
		childGroups = "tab",
	}
	
	for i, classification in ipairs(PitBull4.SINGLETON_CLASSIFICATIONS) do
		unit_options.args[classification] = {
			type = 'group',
			name = PitBull4.Utils.GetLocalizedClassification(classification),
			order = i,
			args = {
				layout = {
					name = "Layout",
					type = 'select',
					order = 1,
					values = function(info)
						local t = {}
						t[""] = ("Disable %s"):format(PitBull4.Utils.GetLocalizedClassification(classification))
						for name in pairs(PitBull4.db.profile.layouts) do
							t[name] = name
						end
						return t
					end,
					get = function(info)
						local db = PitBull4.db.profile.classifications[classification]
						if db.hidden then
							return ""
						else
							return db.layout
						end
					end,
					set = function(info, value)
						local db = PitBull4.db.profile.classifications[classification]
						if value == "" then
							-- TODO: handle this properly
							db.hidden = true
							for frame in PitBull4:IterateFramesForClassification(classification, false) do
								frame:Deactivate()
							end
						else
							local was_hidden = db.hidden
							db.hidden = false
							db.layout = value
							
							if was_hidden then
								PitBull4:MakeSingletonFrame(classification)
							else
								for frame in PitBull4:IterateFramesForClassification(classification, false) do
									frame:RefreshLayout()
								end
							end
						end
					end
				},
				horizontal_mirror = {
					name = "Mirror horizontally",
					desc = "Whether all options will be mirrored, e.g. what would be on the left is now on the right and vice-versa.",
					order = 2,
					type = 'toggle',
					get = function(info)
						return PitBull4.db.profile.classifications[classification].horizontal_mirror
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].horizontal_mirror = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, false) do
							frame:Update(true, true)
						end
					end
				},
				vertical_mirror = {
					name = "Mirror vertically",
					desc = "Whether all options will be mirrored, e.g. what would be on the bottom is now on the top and vice-versa.",
					order = 3,
					type = 'toggle',
					get = function(info)
						return PitBull4.db.profile.classifications[classification].vertical_mirror
					end,
					set = function(info, value)
						PitBull4.db.profile.classifications[classification].vertical_mirror = value
						
						for frame in PitBull4:IterateFramesForClassification(classification, false) do
							frame:Update(true, true)
						end
					end
				},
				scale = {
					name = "Scale",
					desc = "The scale of the unit. This will be multiplied against the layout's scale.",
					order = 4,
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
						
						for frame in PitBull4:IterateFramesForClassification(classification, false) do
							frame:RefreshLayout()
						end
					end
				}
			}
		}
	end
	
	return unit_options
end