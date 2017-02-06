local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local DEBUG = PitBull4.DEBUG
local expect = PitBull4.expect

local global_functions = {}

--- Set the function to be called that will return a tuple of key-value pairs that will be merged onto the options table for the module options.
-- @name Module:SetGlobalOptionsFunction
-- @param func function to call
-- @usage MyModule:SetGlobalOptionsFunction(function(self)
--     return 'someOption', { name = "Some option", } -- etc
-- end)
function PitBull4.defaultModulePrototype:SetGlobalOptionsFunction(func)
	if DEBUG then
		expect(func, 'typeof', 'function')
		expect(global_functions[self], '==', nil)
	end

	global_functions[self] = func
end

function PitBull4.Options.get_module_options()
	local module_options = {
		type = 'group',
		name = L["Modules"],
		desc = L["Modules provide actual functionality for PitBull."],
		args = {},
		childGroups = "tree",
	}

	local function merge_onto(dict, ...)
		for i = 1, select('#', ...), 2 do
			local k, v = select(i, ...)
			if not v.order then
				v.order = 100 + i
			end
			dict[k] = v
		end
	end

	local function hidden(info)
		return not info.handler:IsEnabled()
	end

	function PitBull4.Options.modules_handle_module_load(module)
		module_options.args[module.id .. "_toggle"] = {
			type = "toggle",
			name = module.name,
			desc = (module.description or "") .. "\n\n" .. L["Globally enable this module."],
			get = function(info)
				return module:IsEnabled()
			end,
			set = function(info, value)
				if value then
					PitBull4:EnableModuleAndSaveState(module)
				else
					PitBull4:DisableModuleAndSaveState(module)
				end
			end
		}

		if global_functions[module] then
			local opt = {
				type = "group",
				name = module.name,
				desc = module.description,
				childGroups = "tab",
				hidden = hidden,
				args = {},
				handler = module,
			}
			merge_onto(opt.args, global_functions[module](module))
			module_options.args[module.id] = opt
			global_functions[module] = false
		end
	end

	for id, module in PitBull4:IterateModules() do
		PitBull4.Options.modules_handle_module_load(module)
	end

	-- and now for disabled modules not yet loaded
	local modules_not_loaded = PitBull4.modules_not_loaded

	local player_name = UnitName("player")

	local function loadable(info)
		local id = info[#info - 1]
		local addon_name = 'PitBull4_'..id
		return GetAddOnEnableState(player_name, addon_name) > 0 and IsAddOnLoadOnDemand(addon_name)
	end

	local function unloadable(info)
		return not loadable(info)
	end

	local arg_enabled = {
		type = 'toggle',
		name = L["Enable"],
		desc = L["Globally enable this module."],
		get = function(info)
			return false
		end,
		set = function(info, value)
			local id = info[#info - 1]
			PitBull4:LoadAndEnableModule(id)
		end,
		hidden = unloadable,
	}

	local no_mem_notice = {
		type = 'description',
		name = L["This module is not loaded and will not take up and memory or processing power until enabled."],
		order = -1,
		hidden = unloadable,
	}

	local unloadable_notice = {
		type = 'description',
		name = function(info)
			if not loadable(info) then
				local id = info[#info - 1]
				local _, _, _, _, reason = GetAddOnInfo('PitBull4_'..id)
				if reason then
					if reason == "DISABLED" then
						reason = L["Disabled in the Blizzard addon list."]
					else
						reason = _G["ADDON_"..reason]
					end
				end
				if not reason then
					reason = UNKNOWN
				end
				return format(L["This module can not be loaded: %s"], reason)
			end
		end,
		order = -1,
		hidden = loadable,
	}

	for id in pairs(modules_not_loaded) do
		local addon_name = 'PitBull4_' .. id
		local title = GetAddOnMetadata(addon_name, "Title")
		local notes = GetAddOnMetadata(addon_name, "Notes")

		local name = title:match("%[(.*)%]")
		if not name then
			name = id
		else
			name = name:gsub("|r", ""):gsub("|c%x%x%x%x%x%x%x%x", "")
		end

		module_options.args[id .. "_toggle"] = {
			type = "toggle",
			name = name,
			desc = (notes or "") .. "\n\n" .. L["Globally enable this module."],
			get = function(info)
				return false
			end,
			set = function(info, value)
				PitBull4:LoadAndEnableModule(id)
			end,
			disabled = function(info)
				return GetAddOnEnableState(player_name, addon_name) == 0 or not select(4, GetAddOnInfo(addon_name))
			end,
		}

		if not module_options.args[id] then
			module_options.args[id] = {
				type = 'group',
				name = function(info)
					if not loadable(info) then
						return ("|cff7f7f7f%s|r"):format(name)
					end
					return name
				end,
				desc = notes,
				args = {
					enabled = arg_enabled,
					no_mem_notice = no_mem_notice,
					unloadable_notice = unloadable_notice,
				},
			}
		end
	end

	return module_options
end
