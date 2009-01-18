local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_layout_editor_general_options(layout_options)
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	local RefreshFrameLayouts = PitBull4.Options.RefreshFrameLayouts
	
	local options = {
		name = L["General"],
		type = 'group',
		childGroups = "tab",
		args = {}
	}
	
	options.args.size = {
		type = 'group',
		name = L["Size"],
		desc = L["Size of the unit frame."],
		order = 1,
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
					return GetLayoutDB(false).size_x
				end,
				set = function(info, value)
					GetLayoutDB(false).size_x = value
					
					RefreshFrameLayouts()
				end,
				disabled = function(info)
					return InCombatLockdown()
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
					return GetLayoutDB(false).size_y
				end,
				set = function(info, value)
					GetLayoutDB(false).size_y = value
					
					RefreshFrameLayouts()
				end,
				disabled = function(info)
					return InCombatLockdown()
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
					return GetLayoutDB(false).scale
				end,
				set = function(info, value)
					GetLayoutDB(false).scale = value
					
					RefreshFrameLayouts()
				end,
				disabled = function(info)
					return InCombatLockdown()
				end
			},
		}
	}
	
	options.args.remove = {
		type = 'group',
		name = L["Delete"],
		desc = L["Delete this layout."],
		order = -1,
		args = {
			remove = {
				type = 'execute',
				name = L["Delete"],
				desc = L["Delete this layout."],
				confirm = function(info)
					return L["Are you sure you want to delete the '%s' layout? This is irreversible."]:format(PitBull4.Options.GetCurrentLayout())
				end,
				func = function(info)
					local layout = PitBull4.Options.GetCurrentLayout()
					
					PitBull4.db.profile.layouts[layout] = nil
					
					for id, module in PitBull4:IterateModules() do
						if module.db then
							module.db.profile.layouts[layout] = nil
						end
					end
					
					local new_layout = L["Normal"]
					for name in pairs(PitBull4.db.profile.layouts) do
						new_layout = name
						break
					end
					
					PitBull4.Options.SetCurrentLayout(new_layout)
					
					for classification, db in pairs(PitBull4.db.profile.classifications) do
						if db.layout == layout then
							db.layout = new_layout
							for frame in PitBull4:IterateFramesForClassification(classification, true) do
								frame:RefreshLayout()
							end
						end
					end
				end,
				disabled = function(info)
					local num = 0
					for name in pairs(PitBull4.db.profile.layouts) do
						num = num + 1
					end
					return num <= 1 or InCombatLockdown()
				end
			}
		}
	}
	
	return options
end