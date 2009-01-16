local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local color_functions = {}

--- Set the function to be called that will return a tuple of key-value pairs that will cause an options table show in the colors section.
-- @name Module:SetColorOptionsFunction
-- @param func function to call
-- @usage MyModule:SetColorOptionsFunction(function(self)
--     return 'someOption', { name = "Some option", } -- etc
-- end)
function PitBull4.defaultModulePrototype:SetColorOptionsFunction(func)
	--@alpha@
	expect(func, 'typeof', 'function')
	expect(color_functions[self], '==', nil)
	--@end-alpha@
	
	color_functions[self] = func
end

local function get_class_options()
	local class_options = {
		type = 'group',
		name = CLASS,
		args = {},
	}
	
	local class_translations = {
		WARRIOR = L["Warriors"],
		DRUID = L["Druids"],
		ROGUE = L["Rogues"],
		PRIEST = L["Priests"],
		DEATHKNIGHT = L["Death Knights"],
		SHAMAN = L["Shamans"],
		PALADIN = L["Paladins"],
		MAGE = L["Mages"],
		WARLOCK = L["Warlocks"],
		HUNTER = L["Hunters"],
	}
	
	local option = {
		type = 'color',
		name = function(info)
			local class = info[#info]
			
			return class_translations[class] or class
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
	
	for class in pairs(RAID_CLASS_COLORS) do
		class_options.args[class] = option
	end
	
	
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
			
			for frame in PitBull4:IterateFrames() do
				frame:Update()
			end
		end,
	}
	
	return class_options
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
	
	for id, module in PitBull4:IterateModules() do
		if color_functions[module] then
			local opt = {
				type = 'group',
				name = module.name,
				desc = module.description,
				args = {},
				handler = module,
			}
			color_options.args[id] = opt
			
			local t = { color_functions[module](module) }
			for i = 1, #t, 2 do
				local k, v = t[i], t[i + 1]
				opt.args[k] = v
				v.order = i
			end
			
			color_functions[module] = false
		end
	end
	
	return color_options
end
