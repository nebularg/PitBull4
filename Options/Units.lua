local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local CURRENT_UNIT = "player"
local CURRENT_GROUP = nil

function PitBull4.Options.get_unit_options()
	local unit_options = {
		type = 'group',
		name = L["Units"],
		desc = L["Change settings for units."],
		args = {},
		childGroups = "tab",
	}
	
	local group_options = {
		type = 'group',
		name = L["Groups"],
		desc = L["Change settings for unit groups."],
		args = {},
		childGroups = "tab",
	}
	
	local function get_unit_db()
		return PitBull4.db.profile.units[CURRENT_UNIT]
	end

	local function get_group_db()
		return PitBull4.db.profile.groups[CURRENT_GROUP]
	end

	local function get_db(type)
		if type == "units" then
			return get_unit_db()
		else
			return get_group_db()
		end
	end
	
	local function deep_copy(data)
		local t = {}
		for k, v in pairs(data) do
			if type(v) == "table" then
				t[k] = deep_copy(v)
			else
				t[k] = v
			end
		end
		setmetatable(t,getmetatable(data))
		return t
	end
	
	unit_options.args.current_unit = {
		name = L["Current unit"],
		desc = L["Change the unit you are currently editing."],
		type = 'select',
		order = 1,
		values = function(info)
			local t = {}
			for _, name in ipairs(PitBull4.SINGLETON_CLASSIFICATIONS) do
				t[name] = PitBull4.Utils.GetLocalizedClassification(name)
			end
			return t
		end,
		get = function(info)
			return CURRENT_UNIT
		end,
		set = function(info, value)
			CURRENT_UNIT = value
		end
	}
	
	CURRENT_GROUP = next(PitBull4.db.profile.groups)
	if not CURRENT_GROUP then
		CURRENT_GROUP = L["Party"]
		local _ = PitBull4.db.profile.groups[CURRENT_GROUP]
	end
	
	group_options.args.current_group = {
		name = L["Current group"],
		desc = L["Change the unit group you are currently editing."],
		type = 'select',
		order = 1,
		values = function(info)
			local t = {}
			for name in pairs(PitBull4.db.profile.groups) do
				t[name] = name
			end
			return t
		end,
		get = function(info)
			return CURRENT_GROUP
		end,
		set = function(info, value)
			CURRENT_GROUP = value
		end
	}
	
	local function validate_group(info, value)
		if value:len() < 3 then
			return L["Must be at least 3 characters long."]
		end
		if rawget(PitBull4.db.profile.groups, value) then
			return L["Must be unique."]
		end
		return true
	end
	
	group_options.args.new_group = {
		name = L["New group"],
		desc = L["Create a new group. This will copy the data of the currently-selected group."],
		type = 'input',
		order = 2,
		get = function(info) return "" end,
		set = function(info, value)
			PitBull4.db.profile.groups[value] = deep_copy(PitBull4.db.profile.groups[CURRENT_GROUP])
			
			CURRENT_GROUP = value
			
			if get_group_db().enabled then
				PitBull4:MakeGroupHeader(CURRENT_GROUP)
				PitBull4:RecheckConfigMode()
			end
		end,
		validate = validate_group,
	}
	
	local next_order
	do
		local current = 0
		function next_order()
			current = current + 1
			return current
		end
	end
	
	local update, refresh_group, refresh_layout
	do
		local update_funcs, refresh_group_funcs, refresh_layout_funcs = {}, {}, {}
		
		function update(type)
			return update_funcs[type]()
		end
		
		function refresh_group(type)
			return refresh_group_funcs[type]()
		end
		
		function refresh_layout(type)
			return refresh_layout_funcs[type]()
		end
		
		function update_funcs.groups()
			for header in PitBull4:IterateHeadersForName(CURRENT_GROUP) do
				header:UpdateMembers(true, true)
			end
		end
		
		function update_funcs.units()
			for frame in PitBull4:IterateFramesForClassification(CURRENT_UNIT, true) do
				frame:Update(true, true)
			end
		end
		
		function refresh_group_funcs.groups()
			for header in PitBull4:IterateHeadersForName(CURRENT_GROUP) do
				header:RefreshGroup()
			end
		end
		
		function refresh_layout_funcs.groups()
			for header in PitBull4:IterateHeadersForName(CURRENT_GROUP) do
				header:RefreshLayout()
			end
		end
		
		function refresh_group_funcs.units()
			for frame in PitBull4:IterateFramesForClassification(CURRENT_UNIT, true) do
				frame:RefreshLayout()
			end
		end
		refresh_layout_funcs.units = refresh_group_funcs.units
	end
	
	local function round(value)
		return math.floor(value + 0.5)
	end
	
	local function disabled(info)
		return InCombatLockdown()
	end
	
	local shared_args = {}
	local unit_args = {}
	local group_args = {}
	
	unit_args.enable = {
		name = L["Enable"],
		desc = L["Enable this unit."],
		type = 'toggle',
		order = next_order(),
		get = function(info)
			return get_unit_db().enabled
		end,
		set = function(info, value)
			get_unit_db().enabled = value
			
			-- Note RecheckConfigMode() must be called after the frame is made
			-- if we're turning on the frame so it can be ForceShown() and before
			-- the frame is deactivated if we are hiding it so that the Hide() in 
			-- Deactivate() will actually hide the frame, since Hide() is disabled
			-- when the frame is force_shown. 
			if value then
				PitBull4:MakeSingletonFrame(CURRENT_UNIT)
				PitBull4:RecheckConfigMode()
			else
				PitBull4:RecheckConfigMode()
				for frame in PitBull4:IterateFramesForClassification(CURRENT_UNIT, true) do
					frame:Deactivate()
				end
			end
		end,
		disabled = disabled,
	}
	
	group_args.enable = {
		name = L["Enable"],
		desc = L["Enable this unit group."],
		type = 'toggle',
		order = next_order(),
		get = function(info)
			return get_group_db().enabled
		end,
		set = function(info, value)
			get_group_db().enabled = value
			
			if value then
				PitBull4:MakeGroupHeader(CURRENT_GROUP, nil)
			else
				for header in PitBull4:IterateHeadersForName(CURRENT_GROUP) do
					header:Hide()
				end
			end
			
			PitBull4:RecheckConfigMode()
		end,
		disabled = disabled,
	}
	
	group_args.remove = {
		name = L["Remove"],
		desc = L["Remove this unit group. Note: there is no way to recover after removal."],
		confirm = true,
		order = next_order(),
		type = 'execute',
		func = function(info)
			for header in PitBull4:IterateHeadersForName(CURRENT_GROUP) do
				header:Hide()
			end
			
			PitBull4.db.profile.groups[CURRENT_GROUP] = nil
			
			PitBull4:RecheckConfigMode()
		end,
		disabled = function(info)
			if next(PitBull4.db.profile.groups) == CURRENT_GROUP and not next(PitBull4.db.profile.groups, CURRENT_GROUP) then
				return true
			end
			
			return disabled(info)
		end,
	}
	
	local function get(info)
		local type = info[1]
		
		return get_db(type)[info[#info]]
	end
	
	local function set(info, value)
		local type = info[1]
		local key = info[#info]
		
		local db = get_db(type)
		if db[key] == value then
			return false
		end
		
		db[key] = value
		
		return true
	end
	local function set_with_refresh_group(info, value)
		if set(info, value) then
			refresh_group(info[1])
		end
	end
	local function set_with_refresh_layout(info, value)
		if set(info, value) then
			refresh_layout(info[1])
		end
	end
	local function set_with_refresh_group_shown(info, value)
		if set(info, value) then
			refresh_group(info[1])
			for header in PitBull4:IterateHeadersForName(CURRENT_GROUP) do
				header:UpdateShownState(PitBull4:GetState())
			end
		end
	end
	local function set_with_update(info)
		if set(info, value) then
			update(info[1])
		end
	end
	
	group_args.name = {
		name = L["Name"],
		desc = function(info)
			return L["Rename the '%s' unit group."]:format(CURRENT_GROUP)
		end,
		type = 'input',
		order = next_order(),
		get = function(info)
			return CURRENT_GROUP
		end,
		set = function(info, value)
			PitBull4.db.profile.groups[value], PitBull4.db.profile.groups[CURRENT_GROUP] = PitBull4.db.profile.groups[CURRENT_GROUP], nil
			local old_group = CURRENT_GROUP
			CURRENT_GROUP = value
			
			for header in PitBull4:IterateHeadersForName(old_group) do
				header:Rename(CURRENT_GROUP)
			end
		end,
		validate = validate_group,
	}
	
	group_args.unit_group = {
		name = L["Unit group"],
		desc = L["Which units this group should show."],
		type = 'select',
		order = next_order(),
		values = function(info)
			local t = {}
			for _, name in ipairs(PitBull4.UNIT_GROUPS) do
				t[name] = PitBull4.Utils.GetLocalizedClassification(name)
			end
			return t
		end,
		get = get,
		set = set_with_refresh_group_shown,
		disabled = disabled,
	}
	
	group_args.include_player = {
		name = function(info)
			local unit_group = get_group_db().unit_group:sub(6)
			if unit_group == "" then
				unit_group = "player"
			end
			return L["Include %s"]:format(PitBull4.Utils.GetLocalizedClassification(unit_group))
		end,
		desc = function(info)
			local unit_group = get_group_db().unit_group:sub(6)
			if unit_group == "" then
				unit_group = "player"
			end
			return L["Include %s as part of the unit group."]:format(PitBull4.Utils.GetLocalizedClassification(unit_group))
		end,
		type = 'toggle',
		order = next_order(),
		get = get,
		set = set_with_refresh_group_shown,
		disabled = disabled,
		hidden = function(info)
			return get_group_db().unit_group:sub(1, 5) ~= "party"
		end
	}
	
	shared_args.layout = {
		name = L["Layout"],
		desc = L["Which layout the unit should use. Note: Use the layout editor to change any layout settings."],
		type = 'select',
		order = next_order(),
		values = function(info)
			local t = {}
			for name in pairs(PitBull4.db.profile.layouts) do
				t[name] = name
			end
			return t
		end,
		get = get,
		set = set_with_refresh_layout,
		disabled = disabled,
	}
	
	shared_args.horizontal_mirror = {
		name = L["Mirror horizontally"],
		desc = L["Whether all options will be mirrored, e.g. what would be on the left is now on the right and vice-versa."],
		order = next_order(),
		type = 'toggle',
		get = get,
		set = set_with_refresh_layout,
		disabled = disabled,
	}
	
	shared_args.vertical_mirror = {
		name = L["Mirror vertically"],
		desc = L["Whether all options will be mirrored, e.g. what would be on the bottom is now on the top and vice-versa."],
		order = next_order(),
		type = 'toggle',
		get = get,
		set = set_with_refresh_layout,
		disabled = disabled,
	}
	
	shared_args.scale = {
		name = L["Scale"],
		desc = L["The scale of the unit. This will be multiplied against the layout's scale."],
		order = next_order(),
		type = 'range',
		min = 0.5,
		max = 2,
		isPercent = true,
		step = 0.01,
		bigStep = 0.05,
		get = get,
		set = set_with_refresh_layout,
		disabled = disabled,
	}
	
	shared_args.size_x = {
		name = L["Width multiplier"],
		desc = L["A width multiplier applied to the unit. Your layout's width will be multiplied against this value."],
		order = next_order(),
		type = 'range',
		min = 0.5,
		max = 2,
		isPercent = true,
		step = 0.01,
		bigStep = 0.05,
		get = get,
		set = set_with_refresh_layout,
		disabled = disabled,
	}
	
	shared_args.size_y = {
		name = L["Height multiplier"],
		desc = L["A height multiplier applied to the unit. Your layout's height will be multiplied against this value."],
		order = next_order(),
		type = 'range',
		min = 0.5,
		max = 2,
		isPercent = true,
		step = 0.01,
		bigStep = 0.05,
		get = get,
		set = set_with_refresh_layout,
		disabled = disabled,
	}
	
	shared_args.click_through = {
		name = L["Click-through"],
		desc = L["Whether the unit should be unclickable, allowing you to use it as a HUD without interfering with the game world."],
		order = next_order(),
		type = 'toggle',
		get = get,
		set = set_with_refresh_layout,
		disabled = disabled,
	}
	
	unit_args.position_x = {
		name = L["Horizontal position"],
		desc = L["Horizontal position on the x-axis of the screen."],
		order = next_order(),
		type = 'range',
		min = -math.floor(GetScreenWidth() / 10) * 5,
		max = math.floor(GetScreenWidth() / 10) * 5,
		get = function(info)
			return round(get_unit_db().position_x)
		end,
		set = set_with_refresh_layout,
		step = 1,
		bigStep = 5,
		disabled = disabled,
	}
	
	unit_args.position_y = {
		name = L["Vertical position"],
		desc = L["Vertical position on the y-axis of the screen."],
		order = next_order(),
		type = 'range',
		min = -math.floor(GetScreenHeight() / 10) * 5,
		max = math.floor(GetScreenHeight() / 10) * 5,
		get = function(info)
			return round(get_unit_db().position_y)
		end,
		set = set_with_refresh_layout,
		step = 1,
		bigStep = 5,
		disabled = disabled,
	}
	
	local party_values = {
		INDEX = L["By index"],
		NAME = L["By name"],
	}
	
	local raid_values = {
		INDEX = L["By index"],
		NAME = L["By name"],
		CLASS = L["By class"],
		GROUP = L["By group"],
	}
	
	group_args.sort_method = {
		name = L["Sort method"],
		desc = L["How to sort the frames within the group."],
		type = 'select',
		order = next_order(),
		values = function(info)
			local unit_group = get_group_db().unit_group
			if unit_group:sub(1, 5) == "party" then
				return party_values
			else
				return raid_values
			end
		end,
		get = function(info)
			local db = get_group_db()
			if db.unit_group:sub(1, 5) ~= "party" then
				local group_by = db.group_by
				if group_by == "CLASS" or group_by == "GROUP" then
					return group_by
				end
			end
			return db.sort_method
		end,
		set = function(info, value)
			local db = get_group_db()
			
			if value == "INDEX" or value == "NAME" then
				db.sort_method = value
				db.group_by = nil
			elseif value == "CLASS" then
				db.sort_method = "NAME"
				db.group_by = "CLASS"
			else
				db.sort_method = "INDEX"
				db.group_by = "GROUP"
			end
			
			refresh_group('groups')
		end,
		disabled = disabled,
	}
	
	group_args.sort_direction = {
		name = L["Sort direction"],
		desc = L["Which direction to sort the frames within a group."],
		type = 'select',
		order = next_order(),
		values = {
			ASC = L["Ascending"],
			DESC = L["Descending"],
		},
		get = get,
		set = set_with_refresh_group,
		disabled = disabled,
	}
	
	local VERTICAL_FIRST = {
		down_right = true,
		down_left = true,
		up_right = true,
		up_left = true,
	}
	
	group_args.vertical_spacing = {
		name = L["Vertical spacing"],
		desc = L["How many pixels between rows in this group."],
		order = next_order(),
		type = 'range',
		min = 0,
		max = 300,
		step = 1,
		bigStep = 5,
		get = get,
		set = set_with_refresh_group,
		disabled = disabled,
	}
	
	group_args.horizontal_spacing = {
		name = L["Horizontal spacing"],
		desc = L["How many pixels between columns in this group."],
		order = next_order(),
		type = 'range',
		min = 0,
		max = 300,
		step = 1,
		bigStep = 5,
		get = get,
		set = set_with_refresh_group,
		disabled = disabled,
	}
	
	group_args.direction = {
		name = L["Growth direction"],
		desc = L["Which way frames should placed."],
		order = next_order(),
		type = 'select',
		values = {
			down_right = ("%s, %s"):format(L["Rows down"], L["Columns right"]),
			down_left = ("%s, %s"):format(L["Rows down"], L["Columns left"]),
			up_right = ("%s, %s"):format(L["Rows up"], L["Columns right"]),
			up_left = ("%s, %s"):format(L["Rows up"], L["Columns left"]),
			right_down = ("%s, %s"):format(L["Columns right"], L["Rows down"]),
			right_up = ("%s, %s"):format(L["Columns right"], L["Rows up"]),
			left_down = ("%s, %s"):format(L["Columns left"], L["Rows down"]),
			left_up = ("%s, %s"):format(L["Columns left"], L["Rows up"]),
		},
		get = get,
		set = set_with_refresh_group,
		disabled = disabled,
	}
	
	group_args.units_per_column = {
		name = function(info)
			if VERTICAL_FIRST[get_group_db().direction] then
				return L["Units per column"]
			else
				return L["Units per row"]
			end
		end,
		desc = function(info)
			if VERTICAL_FIRST[get_group_db().direction] then
				return L["The maximum amount of units per column before making a new column."]
			else
				return L["The maximum amount of units per row before making a new row."]
			end
		end,
		order = next_order(),
		type = 'range',
		min = 1,
		max = MAX_RAID_MEMBERS,
		get = get,
		set = set_with_refresh_group,
		step = 1,
		disabled = disabled,
	}
	
	group_args.shown_when = {
		name = L["Show when in"],
		desc = L["Which situations to show the unit group in."],
		order = next_order(),
		type = 'multiselect',
		values = function(info)
			local unit_group = get_group_db().unit_group
			
			local party_based = unit_group:sub(1, 5) == "party"
			
			local t = {}
			
			if party_based then
				if get_group_db().include_player then
					t.solo = L["Solo"]
				end
				t.party = L["Party"]
			end
			
			t.raid10 = L["10-man raid"]
			t.raid25 = L["25-man raid"]
			t.raid40 = L["40-man raid"]
			
			return t
		end,
		get = function(info, key)
			local db = get_group_db()
			
			return db.show_when[key]
		end,
		set = function(info, key, value)
			local db = get_group_db()
			
			db.show_when[key] = value
			
			for header in PitBull4:IterateHeadersForName(CURRENT_GROUP) do
				header:UpdateShownState(PitBull4:GetState())
			end
			refresh_group('groups')
		end,
		disabled = disabled,
	}
	
	group_args.filter_type = {
		name = L["Filter type"],
		desc = L["What type of filter to run on the unit group."],
		order = next_order(),
		type = 'select',
		values = {
			ALL = L["Show all"],
			NUMBER = L["By raid group"],
			CLASS = L["By class"],
			MAINTANK = L["Main tanks"],
			MAINASSIST = L["Main assists"],
		},
		get = function(info)
			local db = get_group_db()
			
			local group_filter = db.group_filter
			
			if not group_filter then
				return 'ALL'
			end
			
			if group_filter == "" then
				return 'NUMBER'
			end
			
			local start = ((","):split(group_filter))
			
			if tonumber(start) then
				return 'NUMBER'
			end
			
			if RAID_CLASS_COLORS[start] then
				return 'CLASS'
			end
			
			if start == 'MAINTANK' or start == 'MAINASSIST' then
				return start
			end
			
			-- WTF here, should never happen
			db.group_filter = nil
			return 'ALL'
		end,
		set = function(info, value)
			local db = get_group_db()
			
			if value == 'ALL' then
				db.group_filter = nil
			elseif value == 'NUMBER' then
				local t = {}
				for i = 1, NUM_RAID_GROUPS do
					t[#t+1] = i..""
				end
				db.group_filter = table.concat(t, ",")
			elseif value == 'CLASS' then
				local t = {}
				for class in pairs(RAID_CLASS_COLORS) do
					t[#t+1] = class
				end
				db.group_filter = table.concat(t, ",")
			else--if value == 'MAINTANK' or value == 'MAINASSIST' then
				db.group_filter = value
			end
			
			refresh_group('groups')
		end,
		disabled = disabled,
		hidden = function(info)
			local db = get_group_db()
			
			local unit_group = db.unit_group
			local party_based = unit_group:sub(1, 5) == "party"
			
		 	return party_based -- only show in raid
		end
	}
	
	local function new_set(...)
		local set = {}
		for i = 1, select('#', ...) do
			set[(select(i, ...))] = true
		end
		set[""] = nil
		return set
	end
	
	local function concat_set_by_comma(set)
		local t = {}
		for k in pairs(set) do
			t[#t+1] = k
		end
		return table.concat(t, ",")
	end
	
	local function get_filter(info, key)
		local db = get_group_db()
		return not not db.group_filter:match(key)
	end
	
	local function set_filter(info, key, value)
		local db = get_group_db()
		
		local set = new_set((","):split(db.group_filter))
		
		set[key] = value or nil
		
		db.group_filter = concat_set_by_comma(set)
		
		refresh_group('groups')
	end
	
	group_args.group_filter_number = {
		name = L["Filter groups"],
		desc = L["Which raid groups should show in this unit group"],
		order = next_order(),
		type = 'multiselect',
		values = {
		},
		get = get_filter,
		set = set_filter,
		disabled = disabled,
		hidden = function(info)
			local db = get_group_db()

			local unit_group = db.unit_group
			local party_based = unit_group:sub(1, 5) == "party"

		 	if party_based then
				-- only show in raid
				return true
			end
			
			local group_filter = db.group_filter
			
			if not group_filter then
				return true
			end
			
			if group_filter == "" then
				return false
			end
			
			local start = ((","):split(group_filter))
			
			return not tonumber(start)
		end
	}
	for i = 1, NUM_RAID_GROUPS do
		group_args.group_filter_number.values[i..""] = L["Group #%d"]:format(i)
	end
	
	group_args.group_filter_class = {
		name = L["Filter classes"],
		desc = L["Which classes should show in this unit group"],
		order = next_order(),
		type = 'multiselect',
		values = {
		},
		get = get_filter,
		set = set_filter,
		disabled = disabled,
		hidden = function(info)
			local db = get_group_db()

			local unit_group = db.unit_group
			local party_based = unit_group:sub(1, 5) == "party"

		 	if party_based then
				-- only show in raid
				return true
			end
			
			local group_filter = db.group_filter
			
			if not group_filter or group_filter == "" then
				return true
			end
			
			local start = ((","):split(group_filter))
			
			return not RAID_CLASS_COLORS[start]
		end
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
	for class in pairs(RAID_CLASS_COLORS) do
		group_args.group_filter_class.values[class] = class_translations[class] or class
	end
	
	local current_order = 0
	
	local args = {}
	for k, v in pairs(shared_args) do
		args[k] = v
	end
	for k, v in pairs(unit_args) do
		args[k] = v
	end
	unit_options.args.sub = {
		type = 'group',
		name = "",
		inline = true,
		args = args,
	}
	
	local args = {}
	for k, v in pairs(shared_args) do
		args[k] = v
	end
	for k, v in pairs(group_args) do
		args[k] = v
	end
	group_options.args.sub = {
		type = 'group',
		name = "",
		inline = true,
		args = args,
	}
	
	return unit_options, group_options
end
