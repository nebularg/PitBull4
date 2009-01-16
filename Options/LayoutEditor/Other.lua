local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_layout_editor_other_options(layout_options)
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	
	local options = {
		name = L["Other"],
		type = 'group',
		childGroups = "tab",
		args = {}
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
				order = 6,
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