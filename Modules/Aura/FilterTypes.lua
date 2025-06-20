-- FilterTypes.lua: Code to implement the various filter types

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:GetModule("Aura")

local function copy(data)
	local t = {}
	for k, v in pairs(data) do
		if type(v) == table then
			t[k] = copy(v)
		else
			t[k] = v
		end
	end
	return t
end

local filter_types = {}
PitBull4_Aura.filter_types = filter_types

local whitelist_values = {
	['wl'] = L["Whitelist"],
	['bl'] = L["Blacklist"],
}

-- Generic comparision operators
local operators = {
	['>'] = L["Greater than"],
	['<'] = L["Less than"],
	['>='] = L["Greater than or equal"],
	['<='] = L["Less than or equal"],
	['=='] = L["Equal"],
	['~='] = L["Not equal"],
}

local time_units = {
	['h'] = L["Hours"],
	['m'] = L["Minutes"],
	['s'] = L["Seconds"],
}

local bool_values = {
	['yes'] = L["Yes"],
	['no'] = L["No"],
}

local unit_values = {
	['=='] = L["is"],
	['~='] = L["is not"],
	['friend'] = L["is friend"],
	['enemy'] = L["is enemy"],
	['is'] = L["is the same as unit"],
	['isnot'] = L["is not the same as unit"],
	['match'] = L["matches the pattern"],
	['nomatch'] = L["does not match the pattern"],
	['player'] = L["is a player"],
	['not_player'] = L["is not a player"],
	['player_controlled'] = L["is player controlled"],
	['not_player_controlled'] = L["is not player controlled"],
	['other_player_pet'] = L["is another player's pet"],
	['not_other_player_pet'] = L["is not another player's pet"],
	['combat'] = L["is in combat"],
	['nocombat'] = L["is not in combat"],
}

local function compare_unit(unit,op,value,frame)
	if op == "==" then
		return unit == value
	elseif op == "~=" then
		return unit ~= value
	elseif op == "known" then
		return not not unit
	elseif op == "unknown" then
		return not unit
	elseif op == "friend" then
		if not unit then return false end
		return UnitIsFriend(unit,'player')
		-- return not UnitCanAttack("player", unit)
	elseif op == "enemy" then
		if not unit then return false end
		return not UnitIsFriend(unit,'player')
		-- return UnitCanAttack("player", unit)
	elseif op == "is" then
		if not unit then return false end
		return UnitIsUnit(unit,value)
	elseif op == "isnot" then
		if not unit then return false end
		return not UnitIsUnit(unit,value)
	elseif op == "player" then
		if not unit then return false end
		return UnitIsPlayer(unit)
	elseif op == "not_player" then
		if not unit then return false end
		return not UnitIsPlayer(unit)
	elseif op == "player_controlled" then
		if not unit then return false end
		return UnitPlayerControlled(unit)
	elseif op == "not_player_controlled" then
		if not unit then return false end
		return not UnitPlayerControlled(unit)
	elseif op == "other_player_pet" then
		if not unit then return false end
		return UnitIsOtherPlayersPet(unit)
	elseif op == "not_other_player_pet" then
		if not unit then return false end
		return not UnitIsOtherPlayersPet(unit)
	elseif op == "match" then
		if not unit then return false end
		return not not string.match(unit,value)
	elseif op == "nomatch" then
		if not unit then return false end
		return not string.match(unit,value)
	elseif op == "combat" then
		if not unit then return false end
		return UnitAffectingCombat(unit)
	elseif op == "nocombat" then
		if not unit then return false end
		return not UnitAffectingCombat(unit)
	end
end

--- Registers a new filter type.
-- Anyone that wants to add a new filter type to the Aura module needs this.
-- @param name the name to index the filter type by
-- @param display_name the localized name to display to users
-- @param filter_func a function to actually do the filtering takes the filtername, an aura entry table and the frame as parameters
-- @param config a function to set the options table takes the filtername and a table to put the options into as parameters
-- @param references a function to say which filters the filter references, takes the name of the filter as a reference.  Only needed by filters that call other filters.
-- @return nil
function PitBull4_Aura:RegisterFilterType(name, display_name, filter_func, config, references)
	if PitBull4.DEBUG then
		PitBull4.expect(name, 'typeof', 'string')
		PitBull4.expect(name, 'not_inset', filter_types)
		PitBull4.expect(display_name, 'typeof', 'string')
		PitBull4.expect(filter_func, 'typeof', 'function')
		PitBull4.expect(config, 'typeof', 'function')
	end

	local filter = {}
	filter.name = name
	filter.display_name = display_name
	filter.filter_func = filter_func
	filter.config = config
	filter.references = references
	filter_types[name] = filter
end

--- Determines if a filter is referenced by another filter.
-- @param filter_name the filter to look for a given reference on
-- @param reference the referenced filter to look for
-- @usage PitBull4_Aura:FilterReferences("myfilter","someotherfilter")
-- @return true or false depending on if filter_name references reference
function PitBull4_Aura:FilterReferences(filter_name, reference)
	if not filter_name or filter_name == "" then return false end
	local filter = self:GetFilterDB(filter_name)
	local filter_ref_func = filter and filter_types[filter.filter_type].references
	if not filter_ref_func then return false end
	local references = filter_ref_func(filter_name)
	for i=1,#references do
		local n = references[i]
		if n == reference then
			return true
		end
		if self:FilterReferences(n, reference) then
			return true
		end
	end
	return false
end

--- Determine if a filter is referenced by any other filter.
-- @param reference the filter name to look for
-- @usage PitBull4_Aura:AnyFilterReferences("myfilter")
-- @return true if the filter is referenced by any other filter, false otherwise.
function PitBull4_Aura:AnyFilterReferences(reference)
	local filters = self.db.profile.global.filters
	for f in pairs(filters) do
		if self:FilterReferences(f, reference) then
			return true
		end
	end
	return false
end

-- Meta filter, allows multiple filters to be combined
local meta_operators = {
	['&'] = 'AND',
	['|'] = 'OR',
	['&~'] = 'AND NOT',
	['|~'] = 'OR NOT',
}
local meta_filter_funcs = {}

PitBull4_Aura.OnProfileChanged_funcs[#PitBull4_Aura.OnProfileChanged_funcs+1] =
function(self)
	-- Must invalidate the cached filter functions on a profile change
	wipe(meta_filter_funcs)
end

local function meta_filter(self, entry, frame)
  -- See if the meta_func is already made and if so run it and
	-- return the value
	local meta_func = meta_filter_funcs[self]
	if meta_func then
		return meta_func(entry, frame)
	end

  -- Otherwise we're going to have to build it
	local filters = PitBull4_Aura.db.profile.global.filters
	local filter = filters[self]
	local names = filter.filters
	local ops = filter.operators

	-- Build our enviornment for the function
	local funcs = {}
	local env = {funcs=funcs, names=names}
	for i=1,#names do
		funcs[i] = filter_types[filters[names[i]].filter_type].filter_func
	end

	-- Now build the lua we're going to use to create the function
	local luastring = 'return function(entry, frame) return '
	for i=1,#funcs do
		if i~= 1 then
			local op = meta_operators[ops[i-1]]:lower()
			luastring = luastring .. op .. ' '
		end
		luastring = luastring .. 'funcs['..i..'](names['..i..'], entry, frame) '
	end
	luastring = luastring .. 'end'

  -- Create and store the actual function
	local create_func = loadstring(luastring,'PitBull4_Aura filter_'..self)
	setfenv(create_func,env)
	meta_filter_funcs[self] = create_func()
	return meta_filter_funcs[self](entry, frame)
end

local function meta_filter_option(self, options)
	local filter_option = {
		type = 'select',
		name = L["Filter"],
		desc = L["Select a filter to use in this meta filter."],
		get = function(info)
			local pos = tonumber(string.match(info[#info],"_(%d+)"))
			return PitBull4_Aura:GetFilterDB(self).filters[pos] or ""
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			local filters = db.filters
			local pos = tonumber(string.match(info[#info],"_(%d+)"))
			if value == "" then
				table.remove(filters,pos)
				table.remove(db.operators,pos)
			else
				filters[pos] = value
				if not db.operators[pos-1] then
					db.operators[pos-1] = '&'
				end
			end
			meta_filter_funcs[self] = nil -- wipe the cached function
			PitBull4_Aura:SetFilterOptions(self, options)
			PitBull4_Aura:UpdateAll()
		end,
		values = function(info)
			local t = {}
			local filters = PitBull4_Aura.db.profile.global.filters
			t[""] = L["None"]
			for k,v in pairs(filters) do
				if k ~= self and not PitBull4_Aura:FilterReferences(k,self) then
					t[k] = v.display_name or k
				end
			end
			return t
		end,
		width = 'double',
	}
	local operator_option = {
		type = 'select',
		name = L["Operator"],
		desc = L["Operator to use to combine the filters."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			local pos = tonumber(string.match(info[#info],"_(%d+)"))
			return db.operators[pos] or '&'
		end,
		set = function(info, value)
			local pos = tonumber(string.match(info[#info],"_(%d+)"))
			local db = PitBull4_Aura:GetFilterDB(self)
			if pos >= #db.filters then
				-- Don't store it if we're at or past the filters
				db.operators[pos] = nil
			else
				db.operators[pos] = value
			end
			meta_filter_funcs[self] = nil -- wipe the cached function
			PitBull4_Aura:UpdateAll()
		end,
		values = meta_operators,
	}

	local db = PitBull4_Aura:GetFilterDB(self)
	local filters = db.filters
	if not filters then
		filters = {}
		db.filters = filters
	end
	db.operators = db.operators or {}

	local order = 1
	for i=1,#filters+1 do
		local slot
		if i~= 1 then
			slot = 'operator_'..i-1
			options[slot] = copy(operator_option)
			options[slot].order = order
			order = order + 1
		end
		slot = 'filter_'..i
		options[slot] = copy(filter_option)
		options[slot].order = order
		order = order + 1
	end
end

local function meta_filter_references(self)
	local filter = PitBull4_Aura:GetFilterDB(self)
	return filter.filters
end

PitBull4_Aura:RegisterFilterType('Meta',L["Meta"],meta_filter,meta_filter_option,meta_filter_references)

-- Name, allows filtering by the aura name
local function name_filter(self, entry)
	local cfg = PitBull4_Aura:GetFilterDB(self)
	if cfg.name_list[entry.name] then
		if cfg.whitelist then
			return true
		else
			return nil
		end
	else
		if cfg.whitelist then
			return nil
		else
			return true
		end
	end
end
PitBull4_Aura:RegisterFilterType('Name',L["Name"],name_filter, function(self, options)
	options.whitelist = {
		type = 'select',
		name = L["List type"],
		desc = L["Select if the list of names are treated as a whitelist or blacklist. A whitelist will only display the selected auras and a blacklist will only show unchecked or unlisted auras."],
		get = function(info)
			return PitBull4_Aura:GetFilterDB(self).whitelist and 'wl' or 'bl'
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).whitelist = (value == 'wl')
			PitBull4_Aura:UpdateAll()
		end,
		values = whitelist_values,
		confirm = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if db.built_in then
				return L["Are you sure you want to change the list type of a built in filter?  Doing so may break the default filtering."]
			end
			return false
		end,
		order = 1,
	}
	options.name_list = {
		type = 'multiselect',
		name = L["Aura names"],
		desc = L["Names of the auras you want the filter to include or exclude."],
		get = function(info, key)
			return PitBull4_Aura:GetFilterDB(self).name_list[key]
		end,
		set = function(info, key, value)
			PitBull4_Aura:GetFilterDB(self).name_list[key] = value
			PitBull4_Aura:UpdateAll()
		end,
		values = function(info)
			local t = {}
			local db = PitBull4_Aura:GetFilterDB(self)
			local name_list = db.name_list
			if not name_list then
				name_list = {}
				db.name_list = name_list
			end
			for k in pairs(name_list) do
				t[k] = k
			end
			return t
		end,
		order = 2,
	}
	options.new_name = {
		type = 'input',
		name = L["New name"],
		desc = L["Add a new name to the list."],
		get = function(info) return "" end,
		set = function(info, value)
			local name_list = PitBull4_Aura:GetFilterDB(self).name_list
			name_list[value] = true
			PitBull4_Aura:UpdateAll()
		end,
		validate = function(info, value)
			if value:len() < 3 then
				return L["Must be at least 3 characters long."]
			end
			return true
		end,
		order = 3,
	}
	options.delete_name = {
		type = 'input',
		name = L["Remove name"],
		desc = L["Remove a name from the list."],
		get = function(info) return "" end,
		set = function(info, value)
			local name_list = PitBull4_Aura:GetFilterDB(self).name_list
			name_list[value] = nil
			PitBull4_Aura:UpdateAll()
		end,
		order = 4,
	}
end)

-- Aura Type, Allows filtering by the type of Aura.
local function aura_type_filter(self, entry)
	local cfg = PitBull4_Aura:GetFilterDB(self)
	if cfg.aura_type_list[tostring(entry.dispelName)] then
		if cfg.whitelist then
			return true
		else
			return nil
		end
	else
		if cfg.whitelist then
			return nil
		else
			return true
		end
	end
end
local aura_types = {
	['Poison'] = L["Poison"],
	['Magic'] = L["Magic"],
	['Disease'] = L["Disease"],
	['Curse'] = L["Curse"],
	['Enrage'] = L["Enrage"],
	['nil'] = L["Other"],
}
PitBull4_Aura:RegisterFilterType('Aura Type',L["Aura Type"],aura_type_filter, function(self,options)
	options.whitelist = {
		type = 'select',
		name = L["List type"],
		desc = L["Select if the list of names are treated as a whitelist or blacklist. A whitelist will only display the selected auras and a blacklist will only show unchecked or unlisted auras."],
		get = function(info)
			return PitBull4_Aura:GetFilterDB(self).whitelist and 'wl' or 'bl'
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).whitelist = (value == 'wl')
			PitBull4_Aura:UpdateAll()
		end,
		values = whitelist_values,
		confirm = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if db.built_in then
				return L["Are you sure you want to change the list type of a built in filter?  Doing so may break the default filtering."]
			end
			return false
		end,
		order = 1,
	}
	options.name_list = {
		type = 'multiselect',
		name = L["Aura types"],
		desc = L["Types of the auras you want the filter to include or exclude."],
		get = function(info, key)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.aura_type_list then
				db.aura_type_list = {}
			end
			return db.aura_type_list[key]
		end,
		set = function(info, key, value)
			PitBull4_Aura:GetFilterDB(self).aura_type_list[key] = value
			PitBull4_Aura:UpdateAll()
		end,
		values = aura_types,
		order = 2,
	}
end)

-- Rank, Allows filtering by the rank of the aura
local rank_pattern = _G.RANK .. " (%d+)"
local function rank_filter(self, entry)
	local cfg = PitBull4_Aura:GetFilterDB(self)
	local operator = cfg.operator
	local value = cfg.value
	local rank = 0 -- tonumber(string.match(entry[6], rank_pattern)) or 0
	if operator == '>' then
		return rank > value
	elseif operator == '<' then
		return rank < value
	elseif operator == '>=' then
		return rank >= value
	elseif operator == '<=' then
		return rank <= value
	elseif operator == '==' then
		return rank == value
	elseif operator == '~=' then
		return rank ~= value
	end
end
PitBull4_Aura:RegisterFilterType('Rank',L["Rank"],rank_filter, function(self,options)
	options.operator = {
		type = 'select',
		name = L["Operator"],
		desc = L["Select the operator to compare the rank against the value."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.operator then
				db.operator = '>'
			end
			return db.operator
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).operator = value
			PitBull4_Aura:UpdateAll()
		end,
		values = operators,
		order = 1,
	}
	options.value = {
		type = 'input',
		name = L["Value"],
		desc = L["Enter the value to compare the rank against."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.value then
				db.value = 0
			end
			return tostring(db.value)
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).value = tonumber(value)
			PitBull4_Aura:UpdateAll()
		end,
		validate = function(info, value)
			if tonumber(value) then
				return true
			else
				return L["Value needs to be a number."]
			end
		end,
		order = 2,
	}
end)

-- Count, Allows filter by the count of the aura
local function count_filter(self, entry)
	local cfg = PitBull4_Aura:GetFilterDB(self)
	local operator = cfg.operator
	local value = cfg.value
	local count = entry.applications
	if operator == '>' then
		return count > value
	elseif operator == '<' then
		return count < value
	elseif operator == '>=' then
		return count >= value
	elseif operator == '<=' then
		return count <= value
	elseif operator == '==' then
		return count == value
	elseif operator == '~=' then
		return count ~= value
	end
end
PitBull4_Aura:RegisterFilterType('Count',L["Count"],count_filter, function(self,options)
	options.operator = {
		type = 'select',
		name = L["Operator"],
		desc = L["Select the operator to compare the count against the value."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.operator then
				db.operator = '>'
			end
			return db.operator
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).operator = value
			PitBull4_Aura:UpdateAll()
		end,
		values = operators,
		order = 1,
	}
	options.value = {
		type = 'input',
		name = L["Value"],
		desc = L["Enter the value to compare the count against."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.value then
				db.value = 0
			end
			return tostring(db.value)
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).value = tonumber(value)
			PitBull4_Aura:UpdateAll()
		end,
		validate = function(info, value)
			if tonumber(value) then
				return true
			else
				return L["Value needs to be a number."]
			end
		end,
		order = 2,
	}
end)

-- Duration, Allows filter by the duration of the aura
local function duration_filter(self, entry)
	local cfg = PitBull4_Aura:GetFilterDB(self)
	local operator = cfg.operator
	local value = cfg.value
	local units = cfg.time_unit
	local duration = entry.duration
	if units == 'h' then
		value = value * 3600
	elseif units == 'm' then
		value = value * 60
	end
	if operator == '>' then
		return duration > value
	elseif operator == '<' then
		return duration < value
	elseif operator == '>=' then
		return duration >= value
	elseif operator == '<=' then
		return duration <= value
	elseif operator == '==' then
		return duration == value
	elseif operator == '~=' then
		return duration ~= value
	end
end
PitBull4_Aura:RegisterFilterType('Duration',L["Duration"],duration_filter, function(self,options)
	options.operator = {
		type = 'select',
		name = L["Operator"],
		desc = L["Select the operator to compare the duration against the value."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.operator then
				db.operator = '>'
			end
			return db.operator
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).operator = value
			PitBull4_Aura:UpdateAll()
		end,
		values = operators,
		order = 1,
	}
	options.value = {
		type = 'input',
		name = L["Value"],
		desc = L["Enter the value to compare the duration against."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.value then
				db.value = 0
			end
			return tostring(db.value)
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).value = tonumber(value)
			PitBull4_Aura:UpdateAll()
		end,
		validate = function(info, value)
			if tonumber(value) then
				return true
			else
				return L["Value needs to be a number."]
			end
		end,
		order = 2,
	}
	options.time_unit = {
		type = 'select',
		name = L["Time unit"],
		desc = L["Select the time units the value represents."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.time_unit then
				db.time_unit = 's'
			end
			return db.time_unit
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).time_unit = value
			PitBull4_Aura:UpdateAll()
		end,
		values = time_units,
		order = 3,
	}
end)

-- Time Left, Allows filter by the time left of the aura
local function time_left_filter(self, entry, frame)
	local cfg = PitBull4_Aura:GetFilterDB(self)
	local operator = cfg.operator
	local value = cfg.value
	local units = cfg.time_unit
	local duration = entry.duration
	local expiration_time = entry.expirationTime
	local time_mod = entry.timeMod

	-- No duration and no expiration time means it never expires
	-- so it has an infinite amount of time left.  Can't really
	-- compare to infinite time so we consider that it's never
	-- less than value and always greater than value and never
	-- equal to a value and always not equal to any value
	if duration == 0 and expiration_time == 0 then
		if operator == '>' then
			return true
		elseif operator == '<' then
			return false
		elseif operator == '>=' then
			return true
		elseif operator == '<=' then
			return false
		elseif operator == '==' then
			return false
		elseif operator == '~=' then
			return true
		end
	end

	local time_left = expiration_time - GetTime()
	if time_mod > 0 then
		time_left = time_left / time_mod
	end
	time_left = math.floor(time_left)

	if units == 'h' then
		value = value * 3600
	elseif units == 'm' then
		value = value * 60
	end

	-- Force the auras to update on this frame on a timer so
	-- we can recheck this filter.  This is done here so that
	-- we don't force the update if the frame only has auras
	-- with no expiration time on them that the response of this
	-- filter will never change on.
	PitBull4_Aura:RequestTimedFilterUpdate(frame)
	if operator == '>' then
		return time_left > value
	elseif operator == '<' then
		return time_left < value
	elseif operator == '>=' then
		return time_left >= value
	elseif operator == '<=' then
		return time_left <= value
	elseif operator == '==' then
		return time_left == value
	elseif operator == '~=' then
		return time_left ~= value
	end
end
PitBull4_Aura:RegisterFilterType('Time Left',L["Time Left"],time_left_filter, function(self,options)
	options.operator = {
		type = 'select',
		name = L["Operator"],
		desc = L["Select the operator to compare the time left against the value."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.operator then
				db.operator = '>'
			end
			return db.operator
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).operator = value
			PitBull4_Aura:UpdateAll()
		end,
		values = operators,
		order = 1,
	}
	options.value = {
		type = 'input',
		name = L["Value"],
		desc = L["Enter the value to compare the time left against."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.value then
				db.value = 0
			end
			return tostring(db.value)
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).value = tonumber(value)
			PitBull4_Aura:UpdateAll()
		end,
		validate = function(info, value)
			if tonumber(value) then
				return true
			else
				return L["Value needs to be a number."]
			end
		end,
		order = 2,
	}
	options.time_unit = {
		type = 'select',
		name = L["Time unit"],
		desc = L["Select the time units the value represents."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.time_unit then
				db.time_unit = 's'
			end
			return db.time_unit
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).time_unit = value
			PitBull4_Aura:UpdateAll()
		end,
		values = time_units,
		order = 3,
	}
end)

local my_units = {
	player = true,
	pet = true,
	vehicle = true,
}

-- Mine, Filter by if you cast it or not.
local function mine_filter(self, entry)
	-- local caster = entry.sourceUnit
	-- local is_mine = caster and (UnitIsUnit("player", caster) or UnitIsOwnerOrControllerOfUnit("player", caster))
	if PitBull4_Aura:GetFilterDB(self).mine then
		return my_units[entry.sourceUnit]
	else
		return not my_units[entry.sourceUnit]
	end
end
PitBull4_Aura:RegisterFilterType('Mine',L["Mine"],mine_filter, function(self,options)
	options.mine = {
		type = 'select',
		name = L["Is mine"],
		desc = L["Filter by if the debuff is yours or not."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.mine and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.mine = true
			else
				db.mine = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Stealable, filter by if you can steal the debuff or not.
local function stealable_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).stealable then
		return entry.isStealable
	else
		return not entry.isStealable
	end
end
PitBull4_Aura:RegisterFilterType('Stealable',L["Stealable"],stealable_filter, function(self,options)
	options.stealable = {
		type = 'select',
		name = L["Is stealable"],
		desc = L["Filter by if the debuff is stealable or not."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.stealable and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.stealable = true
			else
				db.stealable = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Weapon enchant
local function weapon_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).weapon then
		return entry.weaponEnchantSlot and true or nil
	else
		return not entry.weaponEnchantSlot and true or nil
	end
end
PitBull4_Aura:RegisterFilterType('Weapon Enchant',L["Weapon Enchant"],weapon_filter, function(self,options)
	options.weapon = {
		type = 'select',
		name = L["Is weapon enchant"],
		desc = L["Filter by if the aura is weapon enchant or not."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.weapon and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.weapon = true
			else
				db.weapon = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Buff
local function buff_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).buff then
		return entry.isHelpful
	else
		return entry.isHarmful
	end
end
PitBull4_Aura:RegisterFilterType('Buff',L["Buff"],buff_filter, function(self,options)
	options.buff = {
		type = 'select',
		name = L["Is buff"],
		desc = L["Filter by if the aura is a buff or not."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.buff and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.buff = true
			else
				db.buff = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Unit
local function unit_filter(self, entry, frame)
	local db = PitBull4_Aura:GetFilterDB(self)
	return compare_unit(frame.unit,db.unit_operator,db.unit,frame)
end
PitBull4_Aura:RegisterFilterType('Unit',L["Unit"],unit_filter,function(self,options)
	options.unit_operator = {
		type = 'select',
		name = L["Test"],
		desc = L["Type of test to check the unit by."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.unit_operator then
				db.unit_operator = '=='
			end
			return db.unit_operator
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			db.unit_operator = value
			if value ~= "match" and value ~= "nomatch" and not PitBull4.Utils.GetBestUnitID(db.unit) then
				db.unit = "player"
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = unit_values,
		order = 1,
	}
	options.unit = {
		type = 'input',
		name = L["Unit"],
		desc = L["Enter the unit to compare the unit the aura is on against."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.unit then
				db.unit = "player"
			end
			return db.unit
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).unit = value
			PitBull4_Aura:UpdateAll()
		end,
		hidden = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			local unit_operator = db.unit_operator
			return unit_operator == 'friend' or
				unit_operator == 'enemy' or
				unit_operator == "player" or
				unit_operator == "not_player" or
				unit_operator == "player_controlled" or
				unit_operator == "not_player_controlled" or
				unit_operator == "other_player_pet" or
				unit_operator == "not_other_player_pet" or
				unit_operator == "combat" or
				unit_operator == "nocombat"
		end,
		validate = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			local unit_operator = db.unit_operator
			if unit_operator == "match" or unit_operator == "nomatch" then
				return true
			end
			if PitBull4.Utils.GetBestUnitID(value) then
				return true
			else
				return L["Must be a valid unit id."]
			end
		end,
		order = 2,
	}
end)

-- Mapping filter, to allow using a different filter based on
-- player race or class
local LN = PitBull4.LOCALIZED_NAMES
local player_class = UnitClassBase("player")
local _, player_race  = UnitRace("player")
local classes = CopyTable(CLASS_SORT_ORDER)
local class_names = {}
for i, v in ipairs(classes) do
	class_names[i] = LN[v]
end
local races = {
	'Human',
	'Dwarf',
	'NightElf',
	'Gnome',
	'Draenei',
	'Orc',
	'Scourge',
	'Tauren',
	'Troll',
	'BloodElf',
	'Worgen',
	'Goblin',
	'Pandaren',
	'DarkIronDwarf',
	'LightforgedDraenei',
	'VoidElf',
	'MagharOrc',
	'HighmountainTauren',
	'Nightborne',
	-- 'KulTiranHuman',
	-- 'ZandalariTroll',
	-- 'Vulpera',
	-- 'Mechagnome',
	-- 'Dracthyr',
}
local race_names = {}
for i, v in ipairs(races) do
	race_names[i] = LN[v]
end
local function map_filter(self, entry, frame)
	local filters = PitBull4_Aura.db.profile.global.filters
	local db = filters[self]
	local map = db.map
	local map_type = db.map_type
	local filter
	if map_type == "class" then
		filter = map[player_class]
	else
		filter = map[player_race]
	end

	if not filter or filter == "" then
		return false
	end
	return filter_types[filters[filter].filter_type].filter_func(filter, entry, frame)
end
local function map_filter_options(self,options)
	options.map_type = {
		type = 'select',
		name = L["Map type"],
		desc = L["What to map based on."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.map_type then
				db.map_type = "class"
			end
			return db.map_type
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).map_type = value
			PitBull4_Aura:SetFilterOptions(self, options)
			PitBull4_Aura:UpdateAll()
		end,
		values = {
			['class'] = L["Player class"],
			['race'] = L["Player race"],
		},
		order = 1,
	}

	options.map_spacer = {
		type = 'description',
		name = '',
		desc = '',
		order = 2,
	}

	local option_entry = {
		type = 'select',
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			local entry = info[#info]
			if not db.map[entry] then
				db.map[entry] = "@J"
			end
			return db.map[entry]
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).map[info[#info]] = value
			PitBull4_Aura:UpdateAll()
		end,
		values = function(info)
			local t = {}
			local filters = PitBull4_Aura.db.profile.global.filters
			for k,v in pairs(filters) do
				if k ~= self and not PitBull4_Aura:FilterReferences(k,self) then
					t[k] = v.display_name or k
				end
			end
			return t
		end,
		width = 'double',
	}

	local db = PitBull4_Aura:GetFilterDB(self)
	if not db.map_type then
		db.map_type = "class"
	end
	if not db.map then
		db.map = {}
	end
	local t, desc, n
	if db.map_type == "class" then
		t = classes
		n = class_names
		desc = L["Select a filter to use for the class."]
	else
		t = races
		n = race_names
		desc = L["Select a filter to use for the race."]
	end
	local order = 3
	for i=1,#t do
		local k = t[i]
		if not db.map[k] then
			db.map[k] = "@J"
		end
		options[k] = copy(option_entry)
		options[k].order = order
		options[k].name = n[i]
		options[k].desc = desc
		order = order + 1
	end
end

local function map_filter_references(self)
	local filter = PitBull4_Aura:GetFilterDB(self)
	local t = {}
	for _,v in pairs(filter.map) do
		table.insert(t,v)
	end
	return t
end
PitBull4_Aura:RegisterFilterType('Map',L["Map"],map_filter,map_filter_options,map_filter_references)

-- Boolean filters
local function false_filter()
	return false
end
PitBull4_Aura:RegisterFilterType('False',L["False"],false_filter,function(self,options)
	options.text = {
		type = 'description',
		name = L["The False filter is always false."],
	}
end)

local function true_filter()
	return true
end
PitBull4_Aura:RegisterFilterType('True',L["True"],true_filter,function(self,options)
	options.text = {
		type = 'description',
		name = L["The True filter is always true."],
	}
end)

-- Caster
local caster_unit_values = {
	['known'] = L["is known"],
	['unknown'] = L["is unknown"],
}
for k,v in pairs(unit_values) do
	caster_unit_values[k] = v
end
local function caster_filter(self, entry, frame)
	local db = PitBull4_Aura:GetFilterDB(self)
	return compare_unit(entry.sourceUnit, db.unit_operator, db.unit, frame)
end
PitBull4_Aura:RegisterFilterType('Caster',L["Caster"],caster_filter,function(self,options)
	options.unit_operator = {
		type = 'select',
		name = L["Test"],
		desc = L["Type of test to check the caster by."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.unit_operator then
				db.unit_operator = '=='
			end
			return db.unit_operator
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			db.unit_operator = value
			if value ~= "match" and value ~= "nomatch" and not PitBull4.Utils.GetBestUnitID(db.unit) then
				db.unit = "player"
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = caster_unit_values,
		order = 1,
	}
	options.unit = {
		type = 'input',
		name = L["Unit"],
		desc = L["Enter the unit to compare the caster of the aura against."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if not db.unit then
				db.unit = "player"
			end
			return db.unit
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).unit = value
			PitBull4_Aura:UpdateAll()
		end,
		hidden = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			local unit_operator = db.unit_operator
			return unit_operator == 'friend' or unit_operator == 'enemy' or unit_operator == "player_controlled" or unit_operator == "not_player_controlled" or unit_operator == "combat" or unit_operator == "nocombat" or unit_operator == "known" or unit_operator == "unknown"
		end,
		validate = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			local unit_operator = db.unit_operator
			if unit_operator == "match" or unit_operator == "nomatch" then
				return true
			end
			if PitBull4.Utils.GetBestUnitID(value) then
				return true
			else
				return L["Must be a valid unit id."]
			end
		end,
		order = 2,
	}
end)

-- Personal nameplate aura, Filter by if the aura is eligible to show on your personal nameplate
local function personal_nameplate_filter(self, entry)
	local value = (ClassicExpansionAtMost(LE_EXPANSION_WARLORDS_OF_DRAENOR) and entry.shouldConsolidate or entry.nameplateShowPersonal) or false
	if PitBull4_Aura:GetFilterDB(self).should_consolidate then
		return value
	else
		return not value
	end
end
PitBull4_Aura:RegisterFilterType('Should consolidate',ClassicExpansionAtMost(LE_EXPANSION_WARLORDS_OF_DRAENOR) and L["Should consolidate"] or L["Personal nameplate"],personal_nameplate_filter,function(self,options)
	options.personal_nameplate_filter = {
		type = 'select',
		name = ClassicExpansionAtMost(LE_EXPANSION_WARLORDS_OF_DRAENOR) and L["Should consolidate"] or L["Personal nameplate"],
		desc = ClassicExpansionAtMost(LE_EXPANSION_WARLORDS_OF_DRAENOR) and L["Filter by if the aura is eligible for consolidation."] or L["Filter by if the aura is flagged to show on your personal nameplate."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.should_consolidate and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.should_consolidate = true
			else
				db.should_consolidate = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Spell ID, allows filtering by the spell id that created the aura
local function id_filter(self, entry)
	local cfg = PitBull4_Aura:GetFilterDB(self)
	if cfg.id_list[entry.spellId] then
		if cfg.whitelist then
			return true
		else
			return nil
		end
	else
		if cfg.whitelist then
			return nil
		else
			return true
		end
	end
end
PitBull4_Aura:RegisterFilterType('Spell id',L["Spell id"],id_filter,function(self,options)
	options.whitelist = {
		type = 'select',
		name = L["List type"],
		desc = L["Select if the list of ids are treated as a whitelist or blacklist. A whitelist will only display the selected auras and a blacklist will only show unchecked or unlisted auras."],
		get = function(info)
			return PitBull4_Aura:GetFilterDB(self).whitelist and 'wl' or 'bl'
		end,
		set = function(info, value)
			PitBull4_Aura:GetFilterDB(self).whitelist = (value == 'wl')
			PitBull4_Aura:UpdateAll()
		end,
		values = whitelist_values,
		confirm = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			if db.built_in then
				return L["Are you sure you want to change the list type of a built in filter?  Doing so may break the default filtering."]
			end
			return false
		end,
		order = 1,
	}
	options.id_list = {
		type = 'multiselect',
		name = L["Aura ids"],
		desc = L["Ids of the auras you want the filter to include or exclude."],
		get = function(info, key)
			return PitBull4_Aura:GetFilterDB(self).id_list[key]
		end,
		set = function(info, key, value)
			PitBull4_Aura:GetFilterDB(self).id_list[key] = value
			PitBull4_Aura:UpdateAll()
		end,
		values = function(info)
			local t = {}
			local db = PitBull4_Aura:GetFilterDB(self)
			local id_list = db.id_list
			if not id_list then
				id_list = {}
				db.id_list = id_list
			end
			for k in pairs(id_list) do
				local name = C_Spell.GetSpellName(k)
				if not name then
					name = L["Unknown"]
				end
				t[k] = format("%s [%s]",name,k)
			end
			return t
		end,
		order = 2,
		width = 'double',
	}
	options.new_id = {
		type = 'input',
		name = L["New id"],
		desc = L["Add an id to the list."],
		get = function(info) return "" end,
		set = function(info, value)
			local id_list = PitBull4_Aura:GetFilterDB(self).id_list
			id_list[tonumber(value)] = true
			PitBull4_Aura:UpdateAll()
		end,
		validate = function(info, value)
			if not tonumber(value) then
				return L["Must be a number."]
			end
			if not C_Spell.DoesSpellExist(value) then
				return L["Must be a valid spell id."]
			end
			return true
		end,
		order = 3,
	}
	options.delete_id = {
		type = 'input',
		name = L["Remove id"],
		desc = L["Remove an id from the list."],
		get = function(info) return "" end,
		set = function(info, value)
			local id = tonumber(value)
			if id then
				local id_list = PitBull4_Aura:GetFilterDB(self).id_list
				id_list[id] = nil
				PitBull4_Aura:UpdateAll()
			end
		end,
		order = 4,
	}
end)

local function self_buff_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).self_buff then
		return SpellIsSelfBuff(entry.spellId)
	else
		return not SpellIsSelfBuff(entry.spellId)
	end
end
PitBull4_Aura:RegisterFilterType('Self buff',L["Self buff"],self_buff_filter,function(self,options)
	options.self_buff_filter = {
		type = 'select',
		name = L["Self buff"],
		desc = L["Filter by if the aura is flagged as a self buff."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.self_buff and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.self_buff = true
			else
				db.self_buff = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

local function has_custom_visibility_filter(self, entry, frame)
	local hasCustom = false
	if entry.spellId then
		local state = UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT"
		hasCustom = SpellGetVisibilityInfo(entry.spellId, state)
	end
	if PitBull4_Aura:GetFilterDB(self).custom_visibility then
		return hasCustom
	else
		return not hasCustom
	end
end
PitBull4_Aura:RegisterFilterType('Has custom visibility',L["Has custom visibility"],has_custom_visibility_filter,function(self,options)
	options.has_custom_visibility_filter = {
		type = 'select',
		name = L["Has custom visibility"],
		desc = L["Filter by if the aura has custom visibility rules."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.custom_visibility and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.custom_visibility = true
			else
				db.custom_visibility = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

local function should_show_filter(self, entry, frame)
	local show = false
	if entry.spellId then
		local state = UnitAffectingCombat("player") and "RAID_INCOMBAT" or "RAID_OUTOFCOMBAT"
		local hasCustom, alwaysShowMine, showForMySpec = SpellGetVisibilityInfo(entry.spellId, state)
		show = hasCustom and (showForMySpec or (alwaysShowMine and my_units[entry.sourceUnit]))
	end
	if PitBull4_Aura:GetFilterDB(self).should_show then
		return show
	else
		return not show
	end
end
PitBull4_Aura:RegisterFilterType('Should show',L["Custom show"],should_show_filter,function(self,options)
	options.should_show_filter = {
		type = 'select',
		name = L["Custom show"],
		desc = L["Filter by if the aura should show based on custom visibility rules."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.should_show and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.should_show = true
			else
				db.should_show = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Can apply aura, true for auras the player can apply (not necessarily if the
-- player _did_ apply the aura, just if the player _can_ apply the aura)
local function can_apply_aura_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).can_apply_aura then
		return not not entry.canApplyAura
	else
		return not entry.canApplyAura
	end
end
PitBull4_Aura:RegisterFilterType('Can apply aura',L["Can apply aura"],can_apply_aura_filter,function(self,options)
	options.can_apply_aura_filter = {
		type = 'select',
		name = L["Can apply aura"],
		desc = L["Filter by if the aura can be applied by you."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.can_apply_aura and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			db.can_apply_aura = value == "yes"
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Boss, filter by if the aura is applied by a boss
local function boss_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).boss_debuff then
		return not not entry.isBossAura
	else
		return not entry.isBossAura
	end
end
PitBull4_Aura:RegisterFilterType('Boss debuff',L["Boss"],boss_filter,function(self,options)
	options.boss = {
		type = 'select',
		name = L["Boss"],
		desc = L["Filter by if the aura is applied by a boss."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.boss_debuff and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			db.boss_debuff = value == "yes"
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Cast by a player
local function caster_is_player_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).caster_is_player then
		return not not entry.isFromPlayerOrPlayerPet
	else
		return not entry.isFromPlayerOrPlayerPet
	end
end
PitBull4_Aura:RegisterFilterType('Cast by a player',L["Cast by a player"],caster_is_player_filter,function(self,options)
	options.caster_is_player_filter = {
		type = 'select',
		name = L["Cast by a player"],
		desc = L["Filter by if the aura was cast by a player."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.caster_is_player and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.caster_is_player = true
			else
				db.caster_is_player = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)

-- Global nameplate aura, Filter by if the aura is eligible to show on all nameplates
local function global_nameplate_filter(self, entry)
	if PitBull4_Aura:GetFilterDB(self).global_nameplate then
		return not not entry.nameplateShowAll
	else
		return not entry.nameplateShowAll
	end
end
PitBull4_Aura:RegisterFilterType('Global nameplate',L["Global nameplate"],global_nameplate_filter,function(self,options)
	options.global_nameplate_filter = {
		type = 'select',
		name = L["Global nameplate"],
		desc = L["Filter by if the aura is flagged to show on all nameplates."],
		get = function(info)
			local db = PitBull4_Aura:GetFilterDB(self)
			return db.global_nameplate and "yes" or "no"
		end,
		set = function(info, value)
			local db = PitBull4_Aura:GetFilterDB(self)
			if value == "yes" then
				db.global_nameplate = true
			else
				db.global_nameplate = false
			end
			PitBull4_Aura:UpdateAll()
		end,
		values = bool_values,
		order = 1,
	}
end)
