local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_layout_editor_other_options(layout_options)
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	local RefreshFrameLayouts = PitBull4.Options.RefreshFrameLayouts
	
	local options = {
		name = L["Other"],
		type = 'group',
		childGroups = "tab",
		order = 6,
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
				end
			},
		}
	}
	
	local layout_functions = PitBull4.Options.layout_functions
	
	for id, module in PitBull4:IterateModulesOfType("custom", true) do
		if layout_functions[module] then
			local t = { layout_functions[module](module) }
			layout_functions[module] = false
			
			local top_level = (t[1] == true)
			if top_level then
				table.remove(t, 1)
			end
			
			local args = top_level and layout_options.args or options.args
			
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
			
			for i = 1, #t, 2 do
				local k = t[i]
				local v = t[i+1]
				
				v.order = i + 100
				
				args[id].args[k] = v
			end
		end
	end
	
	return options
end