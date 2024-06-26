local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local LN = PitBull4.LOCALIZED_NAMES
local DEBUG = PitBull4.DEBUG
local expect = PitBull4.expect

local color_functions = {}

--- Set the function to be called that will return a tuple of key-value pairs that will cause an options table show in the colors section.
-- The last return must be a function that resets all colors.
-- @name Module:SetColorOptionsFunction
-- @param func function to call
-- @usage MyModule:SetColorOptionsFunction(function(self)
--     return 'someOption', { name = "Some option", }, -- etc
--     function(info)
--         -- reset all colors
--     end
-- end)
function PitBull4.defaultModulePrototype:SetColorOptionsFunction(func)
	if DEBUG then
		expect(func, 'typeof', 'function')
		expect(color_functions[self], '==', nil)
	end
	color_functions[self] = func
end

local function get_class_options()
	local class_options = {
		type = 'group',
		name = CLASS,
		args = {},
	}

	local option = {
		type = 'color',
		name = function(info)
			local class = info[#info]

			return LN[class] or class
		end,
		hasAlpha = false,
		get = function(info)
			local class = info[#info]
			return unpack(PitBull4.db.profile.colors.class[class])
		end,
		set = function(info, r, g, b)
			local class = info[#info]
			local color = PitBull4.db.profile.colors.class[class]
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end
	}

	for _, class in pairs(CLASS_SORT_ORDER) do
		class_options.args[class] = option
	end

	class_options.args.UNKNOWN = CopyTable(option)
	class_options.args.UNKNOWN.name = UNKNOWN

	class_options.args.reset_sep = {
		type = 'header',
		name = '',
		order = -2,
	}
	class_options.args.reset = {
		type = 'execute',
		name = L["Reset to defaults"],
		confirm = true,
		confirmText = L["Are you sure you want to reset to defaults?"],
		order = -1,
		func = function(info)
			for class, color in pairs(RAID_CLASS_COLORS) do
				local db_color = PitBull4.db.profile.colors.class[class]
				db_color[1], db_color[2], db_color[3] = color.r, color.g, color.b
			end

			local db_color = PitBull4.db.profile.colors.class.UNKNOWN
			db_color[1], db_color[2], db_color[3] = 204/255, 204/255, 204/255

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end,
	}

	return class_options
end

local function get_power_options()
	local power_options = {
		type = 'group',
		name = L["Power"],
		args = {},
	}

	local option = {
		type = 'color',
		name = function(info)
			local power_token = info[#info]

			if power_token == "PB4_ALTERNATE" then
				return L["Alternate"]
			end
			return _G[power_token] or power_token
		end,
		hasAlpha = false,
		get = function(info)
			local power_token = info[#info]
			return unpack(PitBull4.db.profile.colors.power[power_token])
		end,
		set = function(info, r, g, b)
			local power_token = info[#info]
			local color = PitBull4.db.profile.colors.power[power_token]
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end
	}

	for power_token in pairs(PitBull4.PowerColors) do
		if type(power_token) == "string" then
			power_options.args[power_token] = option
		end
	end


	power_options.args.reset_sep = {
		type = 'header',
		name = '',
		order = -2,
	}
	power_options.args.reset = {
		type = 'execute',
		name = L["Reset to defaults"],
		confirm = true,
		confirmText = L["Are you sure you want to reset to defaults?"],
		order = -1,
		func = function(info)
			for power_token, color in next, PitBull4.DEFAULT_COLORS do
				local db_color = PitBull4.db.profile.colors.power[power_token]
				db_color[1], db_color[2], db_color[3] = unpack(color)
			end

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end,
	}

	return power_options
end

local function get_reaction_options()
	local reaction_options = {
		type = 'group',
		name = L["Reaction"],
		args = {},
	}

	local option = {
		type = 'color',
		name = function(info)
			local reaction = info[#info]
			local label = "FACTION_STANDING_LABEL" .. reaction
			return _G[label] or label
		end,
		hasAlpha = false,
		get = function(info)
			local reaction = tonumber(info[#info])
			return unpack(PitBull4.db.profile.colors.reaction[reaction])
		end,
		set = function(info, r, g, b)
			local reaction = tonumber(info[#info])
			local color = PitBull4.db.profile.colors.reaction[reaction]
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end
	}

	for reaction in pairs(_G.FACTION_BAR_COLORS) do
		local my_option = {}
		for k, v in pairs(option) do
			my_option[k] = v
		end
		my_option.order = reaction
		reaction_options.args[tostring(reaction)] = my_option
	end

	reaction_options.args.unknown = {
		type = 'color',
		name = UNKNOWN,
		get = function(info)
			return unpack(PitBull4.db.profile.colors.reaction.unknown)
		end,
		set = function(info, r, g, b)
			local color = PitBull4.db.profile.colors.reaction.unknown
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end
	}

	reaction_options.args.civilan = {
		type = 'color',
		name = L["Civilian"],
		get = function(info)
			return unpack(PitBull4.db.profile.colors.reaction.civilian)
		end,
		set = function(info, r, g, b)
			local color = PitBull4.db.profile.colors.reaction.civilian
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end
	}

	reaction_options.args.paragon = {
		type = 'color',
		name = L["Paragon"],
		get = function(info)
			return unpack(PitBull4.db.profile.colors.reaction.paragon)
		end,
		set = function(info, r, g, b)
			local color = PitBull4.db.profile.colors.reaction.paragon
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end
	}

	reaction_options.args.tapped = {
		type = 'color',
		name = L["Tapped"],
		get = function(info)
			return unpack(PitBull4.db.profile.colors.reaction.tapped)
		end,
		set = function(info, r, g, b)
			local color = PitBull4.db.profile.colors.reaction.tapped
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end
	}

	reaction_options.args.reset_sep = {
		type = 'header',
		name = '',
		order = -2,
	}
	reaction_options.args.reset = {
		type = 'execute',
		name = L["Reset to defaults"],
		confirm = true,
		confirmText = L["Are you sure you want to reset to defaults?"],
		order = -1,
		func = function(info)
			local db_color
			for reaction, color in pairs(_G.FACTION_BAR_COLORS) do
				db_color = PitBull4.db.profile.colors.reaction[reaction]
				db_color[1], db_color[2], db_color[3] = color.r, color.g, color.b
			end

			db_color = PitBull4.db.profile.colors.reaction.unknown
			db_color[1], db_color[2], db_color[3] = 204/255, 204/255, 204/255

			db_color = PitBull4.db.profile.colors.reaction.civilian
			db_color[1], db_color[2], db_color[3] = 48/255, 113/255, 191/255

			db_color = PitBull4.db.profile.colors.reaction.paragon
			db_color[1], db_color[2], db_color[3] = 66/255, 107/255, 1

			db_color = PitBull4.db.profile.colors.reaction.tapped
			db_color[1], db_color[2], db_color[3] = 127/255, 127/255, 127/255

			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end,
	}

	return reaction_options
end

function PitBull4.Options.get_color_options()
	local color_options = {
		type = 'group',
		name = L["Colors"],
		desc = L["Set colors that PitBull uses."],
		args = {},
		childGroups = "tree",
	}

	color_options.args.class = get_class_options()
	color_options.args.power = get_power_options()
	color_options.args.reaction = get_reaction_options()

	function PitBull4.Options.colors_handle_module_load(module)
		if color_functions[module] then
			local id = module.id
			local opt = {
				type = 'group',
				name = module.name,
				desc = module.description,
				args = {},
				handler = module,
				hidden = function(info)
					return not module:IsEnabled()
				end
			}
			color_options.args[id] = opt

			local t = { color_functions[module](module) }

			local reset_func = table.remove(t)
			if DEBUG then
				expect(reset_func, 'typeof', 'function')
			end
			for i = 1, #t, 2 do
				local k, v = t[i], t[i + 1]
				opt.args[k] = v
				v.order = i
			end


			opt.args.reset_sep = {
				type = 'header',
				name = '',
				order = -2,
			}
			opt.args.reset = {
				type = 'execute',
				name = L["Reset to defaults"],
				confirm = true,
				confirmText = L["Are you sure you want to reset to defaults?"],
				order = -1,
				func = function(info)
					reset_func(info)

					for frame in PitBull4:IterateFrames() do
						module:Update(frame)
					end
				end,
			}

			color_functions[module] = false
		end
	end

	for id, module in PitBull4:IterateModules() do
		PitBull4.Options.colors_handle_module_load(module)
	end

	return color_options
end
