local _G = _G
local PitBull4 = _G.PitBull4
local PitBull4_Utils = PitBull4.Utils

local db
local defaults = {
	classifications = {
		['*'] = {
			hidden = false,
			position_x = 0,
			position_y = 0,
			layout = "Normal",
			horizontalMirror = false,
			verticalMirror = false,
		},
	},
	layouts = {
		['*'] = {
			size_x = 300,
			size_y = 100,
		},
		Normal = {}
	},
}

local add_defaults
do
	-- metatable cache
	local cache = {}
	
	-- make the metatable which creates a new table on access
	local function make_default_table_mt(value)
		if cache[value] then
			return cache[value]
		end
		local mt = {}
		cache[value] = mt
		function mt:__index(key)
			local t = {}
			self[key] = t
			add_defaults(t, value)
			return t
		end
		return mt
	end
	
	-- make the metatable which returns a simple value on access
	local function make_default_value_mt(value)
		if cache[value] then
			return cache[value]
		end
		local mt = {}
		cache[value] = mt
		function mt:__index(key)
			self[key] = value
			return value
		end
		return mt
	end
	
	local function add_star_defaults_to_database(database, default)
		for k, v in pairs(database) do
			add_defaults(v, default)
		end
	end
	
	-- add a default table structure to a database table
	local function add_default_table(database, key, default, default_star)
		if key == '*' then
			add_star_defaults_to_database(database, default)
			setmetatable(database, make_default_table_mt(default))
			return
		end
		
		if type(rawget(database, key)) ~= "table" then
			-- make sure that the database table structure matches
			database[key] = {}
		end
		add_defaults(database[key], default) -- handle sub-tables
		if default_star then
			add_defaults(database[key], default_star)
		end
	end
	
	-- add a specific value (or table structure) to a database table
	local function add_default_value(database, key, default, default_star)
		if type(default) == "table" then -- make sure the table structure is consistent
			add_default_table(database, key, default, default_star)
			return
		end
		
		if key == '*' then -- all keys
			setmetatable(database, make_default_value_mt(value))
			return
		end
		
		if database[key] == nil then -- if it's nil, then go for what the defaults say
			database[key] = default
		end
	end
	
	-- add default values to a database table
	function add_defaults(database, defaults)
		if type(database) ~= "table" then
			return
		end
		for k, v in pairs(defaults) do -- loop through each default value and add it to the database
			add_default_value(database, k, v, defaults['**'])
		end
	end
end

--- Add defaults for a specific module
-- @param moduleID identifier for the module in question
-- @param globalDefaults a defaults table for global settings
-- @param layoutDefaults a defaults table for layout-specific settings
-- @usage PitBull4.AddModuleDefaults("Monkey", { banana = true }, { color = { 1, 0.82, 0 } })
function PitBull4.AddModuleDefaults(moduleID, globalDefaults, layoutDefaults)
	if not globalDefaults.disabled then
		globalDefaults.disabled = false
	end
	defaults[moduleID] = globalDefaults
	defaults.layouts['*'][moduleID] = layoutDefaults
	if not db then
		return
	end
	
	if not db[moduleID] then
		db[moduleID] = {}
	end
	add_defaults(db[moduleID], globalDefaults)
	
	for layout, data in pairs(db.layouts) do
		data[moduleID] = data[moduleID] or {}
		add_defaults(data[moduleID], layoutDefaults)
	end
end

-- set the db table and populate it with the defaults
local function handle_db()
	handle_db = nil
	
	db = _G.PitBull4DB
	if type(db) ~= "table" then
		db = { version = 0 }
		_G.PitBull4DB = db
	end
	local version = db.version
	db.version = nil
	
	add_defaults(db, defaults)
	
	PitBull4.db = db
end

local function ADDON_LOADED(event, name)
	if name ~= "PitBull4" then
		return
	end
	PitBull4.Utils.RemoveEventListener("ADDON_LOADED", ADDON_LOADED)
	ADDON_LOADED = nil
	
	handle_db()
end
PitBull4.Utils.AddEventListener("ADDON_LOADED", ADDON_LOADED)

PitBull4.Utils.AddEventListener("PLAYER_LOGOUT", function()
	local remove_defaults
	
	local function remove_default_table(database, key, defaults)
		-- remove the * defaults, if it exists
		remove_defaults(database[key], defaults['*'])
		-- remove the standard default
		remove_defaults(database[key], defaults[key])
		
		if next(database[key]) == nil then
			-- if the table's empty, nil out the table
			database[key] = nil
		end
	end
	
	local function remove_default_value(database, key, defaults)
		local default = defaults[key]
		if default == nil then
			-- no default value, use the star default instead
			default = defaults['*']
		end
		
		if type(database[key]) ~= type(default) then
			-- vastly different, cut out early
			return
		end
		
		if type(default) == "table" then
			-- handle the table case
			remove_default_table(database, key, defaults)
			return
		end
		
		if database[key] == default then
			-- simple equality, nil out
			database[key] = nil
		end
	end
	
	-- remove any unnecessary values from the database
	-- this is useful in case the defaults change (so that unchanged values are updated)
	-- it is also useful because the stored SV looks a lot smaller cause it has only
	-- the useful information
	function remove_defaults(database, defaults)
		if type(defaults) ~= "table" or type(database) ~= "table" then
			return
		end
		for k, v in pairs(database) do
			-- loop through each default and remove from the database
			remove_default_value(database, k, defaults)
		end
	end
	remove_defaults(db, defaults)
	
	db.version = 0
end)
