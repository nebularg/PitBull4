local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local global_functions = {}

--- Set the function to be called that will return a tuple of key-value pairs that will be merged onto the options table for the module options.
-- @name Module:SetGlobalOptionsFunction
-- @param func function to call
-- @usage MyModule:SetGlobalOptionsFunction(function(self)
--     return 'someOption', { name = "Some option", } -- etc
-- end)
function PitBull4.defaultModulePrototype:SetGlobalOptionsFunction(func)
	--@alpha@
	expect(func, 'typeof', 'function')
	expect(global_functions[self], '==', nil)
	--@end-alpha@
	
	global_functions[self] = func
end

function PitBull4.Options.get_module_options()
	local function merge_onto(dict, ...)
		for i = 1, select('#', ...), 2 do
			local k, v = select(i, ...)
			if not v.order then
				v.order = 100 + i
			end
			dict[k] = v
		end
	end
	
	local module_options = {
		type = 'group',
		name = L["Modules"],
		desc = L["Modules provide actual functionality for PitBull."],
		args = {},
		childGroups = "tree",
	}
	
	local module_args = {
		enabled = {
			type = 'toggle',
			name = L["Enable"],
			desc = L["Globally enable this module."],
			get = function(info)
				return info.handler:IsEnabled()
			end,
			set = function(info, value)
				if value then
					PitBull4:EnableModule(info.handler)
				else
					PitBull4:DisableModule(info.handler)
				end
			end
		}
	}
	for id, module in PitBull4:IterateModules() do
		local opt = {
			type = 'group',
			name = module.name,
			desc = module.description,
			args = {},
			handler = module,
		}
		module_options.args[id] = opt
		
		for k, v in pairs(module_args) do
			opt.args[k] = v
		end
		
		if global_functions[module] then
			merge_onto(opt.args, global_functions[module](module))
			global_functions[module] = false
		end
	end
	
	return module_options
end