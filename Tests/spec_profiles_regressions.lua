local root = arg[1] or "PitBull4/"
local Fixture = dofile(root .. "Tests/native_fixture.lua")
local passed = 0
local function check(value, message) assert(value, message); passed = passed + 1 end
local function setup(project, expansion, data)
	local env = Fixture.New(project, expansion)
	env.spec, env.group, env.spec_count = 3, 1, 3
	env.C_SpecializationInfo = {
		GetSpecialization = function() return env.spec end,
		GetActiveSpecGroup = function() return env.group end,
		GetNumSpecializationsForClassID = function() return env.spec_count end,
		GetSpecializationInfoForClassID = function(_, index) return index, "Spec " .. index end,
		CanPlayerUseTalentSpecUI = function() return env.usable ~= false end,
	}
	local store = { char = data or {} }
	local db = { current = "Default", callbacks = {}, profile_changes = 0 }
	function db:GetNamespace(name, silent)
		assert(name == "LibDualSpec-1.0" and silent == true)
		return store
	end
	function db:RegisterNamespace() error("existing namespace must be reused") end
	function db:GetCurrentProfile() return self.current end
	function db:SetProfile(profile) self.current = profile; self.profile_changes = self.profile_changes + 1 end
	db.RegisterCallback = function(owner, event) db.callbacks[event] = owner end
	local ns = {}
	Fixture.Load(root .. "Compat.lua", env, "PitBull4", ns)
	Fixture.Load(root .. "SpecProfiles.lua", env, "PitBull4", ns)
	local addon = { L = setmetatable({}, { __index = function(_, key) return key end }) }
	return env, ns, addon, db, store
end
for _, case in ipairs({ { 1, 11 }, { 19, 4 } }) do
	local env, ns, addon, db, store = setup(case[1], case[2], { enabled = true, [3] = "Healer", [1] = "Damage" })
	local controller = ns.SpecProfiles.Attach(addon, db)
	check(controller.current == 3 and db.current == "Healer", "native specialization index selects saved profile")
	check(store.char[1] == "Damage" and store.char.enabled == true, "existing bindings are retained")
	check(env.LibStub == nil and not db.IsDualSpecEnabled, "no library load or library method injection")
	check(controller.frame.registered.PLAYER_SPECIALIZATION_CHANGED == "player", "player event is unit-filtered")
	env.spec = 1
	controller.frame.scripts.OnEvent(controller.frame, "PLAYER_SPECIALIZATION_CHANGED", "target")
	check(controller.current == 3, "foreign unit event is ignored")
	env.in_combat = true
	controller.frame.scripts.OnEvent(controller.frame, "PLAYER_SPECIALIZATION_CHANGED", "player")
	check(controller.current == 1 and db.current == "Healer" and controller.pending, "profile switch is deferred in combat")
	env.spec = 2
	controller:SetProfile("Tank", 2)
	env.in_combat = false
	controller.frame.scripts.OnEvent(controller.frame, "PLAYER_REGEN_ENABLED")
	check(controller.current == 2 and db.current == "Tank", "latest specialization is applied after combat")
	env.spec = nil
	controller:Refresh()
	check(controller.current == 0 and db.current == "Tank", "unselected specialization does not switch")
	env.spec = { opaque = true }
	controller:Refresh()
	check(controller.current == 0, "unreadable specialization is not compared")
	env.spec = 5
	controller:Refresh()
	check(controller.current == 0, "starter sentinel is not a specialization")
	env.spec, env.usable = 1, false
	controller:Refresh()
	check(controller.current == 0, "unavailable talent UI disables switching")
	env.usable = true
	controller:Refresh()
	check(db.current == "Damage", "switching recovers when available")
	controller:OnProfileDeleted("OnProfileDeleted", db, "Tank")
	check(store.char[2] == "Damage", "deleted bindings fall back to current profile")
	controller:SetEnabled(false)
	check(not controller:IsEnabled() and store.char[1] == nil, "disable preserves legacy clearing behavior")
	controller:SetEnabled(true)
	check(controller:IsEnabled() and store.char[3] == "Damage", "enable initializes missing bindings")
	controller:SetProfile("Invalid", 0)
	controller:SetProfile("", 1)
	check(store.char[1] == "Damage", "invalid profile/index inputs are ignored")
	local options = { handler = { db = db }, args = { new = {}, choose = {} } }
	controller:EnhanceOptions(options)
	check(options.args.specProfile1.name() == "Spec 1 - Active", "profile choices label active specialization")
	env.in_combat = true
	check(options.args.spec_profiles_enabled.disabled() and options.args.choose.disabled({}), "profile options are disabled in combat")
	env.in_combat = false
	options.args.new.set({}, "NewProfile")
	check(db.current == "NewProfile" and store.char[1] == "NewProfile", "creating a profile updates active binding")
	env.spec_count = 2
	controller:Refresh()
	check(options.args.specProfile3 == nil and options.args.specProfile2 ~= nil, "option choices recover from changed count")
	store.char = {}
	controller:OnDatabaseReset("OnDatabaseReset", db)
	check(controller.settings == store.char and not controller:IsEnabled(), "database reset rebinds settings")
end
do
	local env, ns, addon, db = setup(2, 0)
	check(ns.SpecProfiles.Attach(addon, db) == nil and next(db.callbacks) == nil, "regular Era needs neither season API nor library")
	env.C_Seasons = { GetActiveSeason = function() return 2 end }
	-- C_Seasons is captured when the application module loads.
	Fixture.Load(root .. "SpecProfiles.lua", env, "PitBull4", ns)
	local controller = ns.SpecProfiles.Attach(addon, db)
	check(controller.current == 1 and controller.count == 2, "supported Era season uses talent groups")
end
for _, case in ipairs({ { 18, 0 }, { 5, 1 }, { 14, 3 } }) do
	local env, ns, addon, db, store = setup(case[1], case[2], { enabled = true, [2] = "Secondary" })
	env.group = 2
	local controller = ns.SpecProfiles.Attach(addon, db)
	check(controller.current == 2 and controller.count == 2 and db.current == "Secondary", "legacy/Forever group selection")
	check(controller.frame.registered.ACTIVE_TALENT_GROUP_CHANGED == true, "talent-group event is registered")
end
do
	local env, ns, addon, db, store = setup(1, 11, { enabled = true, profile = "Alternate", specGroup = 1 })
	ns.SpecProfiles.Attach(addon, db)
	check(store.char[3] == "Default" and store.char[1] == "Alternate"
		and store.char.profile == nil and store.char.specGroup == nil, "old alternate-profile data migrates without library")
end
do
	local env, ns, addon, db = setup(1, 11)
	env.C_SpecializationInfo.GetSpecialization = nil
	Fixture.Load(root .. "Compat.lua", env, "PitBull4", ns)
	Fixture.Load(root .. "SpecProfiles.lua", env, "PitBull4", ns)
	check(ns.SpecProfiles.Attach(addon, db) == nil, "missing specialization getter cannot select talent-group fallback")
end
do
	local env, ns, addon, db = setup(1, 11)
	env.spec_count = 0
	local controller = ns.SpecProfiles.Attach(addon, db)
	local options = { handler = { db = db }, args = { new = {}, choose = {} } }
	controller:EnhanceOptions(options)
	check(options.args.specProfile1 == nil, "unready specialization list is empty")
	env.spec_count, env.spec = 3, 1
	controller:Refresh()
	check(options.args.specProfile3 ~= nil and controller.current == 1, "delayed player data rebuilds choices")
end
do
	local env, ns, addon = setup(1, 11)
	env.GetRealmName = function() return "Realm" end
	env.GetCurrentRegion = function() return 1 end
	env.UnitClass = function() return "Mage", "MAGE", 8 end
	env.UnitRace = function() return "Human", "Human" end
	env.UnitFactionGroup = function() return "Alliance" end
	for _, file in ipairs({ "Libs/LibStub/LibStub.lua",
		"Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua",
		"Libs/AceDB-3.0/AceDB-3.0.lua", "Libs/AceDBOptions-3.0/AceDBOptions-3.0.lua" }) do
		Fixture.Load(root .. file, env)
	end
	local saved = {}
	local db = env.LibStub("AceDB-3.0"):New(saved, { profile = { marker = "default" } }, true)
	local controller = ns.SpecProfiles.Attach(addon, db)
	local store = db:GetNamespace("LibDualSpec-1.0")
	check(store.char == controller.settings and not controller:IsEnabled(), "fresh real AceDB namespace is created")
	controller:SetEnabled(true)
	controller:SetProfile("Healer", 3)
	check(db:GetCurrentProfile() == "Healer" and db.profile.marker == "default", "real database profile switching retains defaults")
	controller:SetProfile("Damage", 1)
	env.spec = 1
	controller:Refresh()
	db:DeleteProfile("Healer")
	check(store.char[3] == "Damage", "real profile-deleted callback updates bindings")
	local options = env.LibStub("AceDBOptions-3.0"):GetOptionsTable(db)
	controller:EnhanceOptions(options)
	check(options.args.specProfile1.values == "ListProfiles" and options.handler.db == db,
		"real database options retain their profile-list handler")
	options.args.new.set({}, "Created")
	check(db:GetCurrentProfile() == "Created" and store.char[1] == "Created", "real options create an assigned profile")
	db:ResetDB(true)
	check(controller.settings == store.char and not controller:IsEnabled()
		and db:GetCurrentProfile() == "Default", "real database-reset callback rebinds cleared character data")
	check(env.LibStub("LibDualSpec-1.0", true) == nil and not db.IsDualSpecEnabled,
		"real database has no specialization-library registration or injected methods")
	-- Execute the real application initialization body with a saved spec binding.
	local initialized, registered, profile_callbacks = false, false, 0
	addon.InitializeModuleDefaults = function() initialized = true end
	addon.RegisterEvent = function() end
	addon.OnProfileChanged = function()
		assert(initialized and registered, "saved-profile callbacks ran before module/minimap initialization")
		profile_callbacks = profile_callbacks + 1
	end
	addon.OnProfileReset, addon.OnNewProfile = function() end, function() end
	local broker = env.LibStub:NewLibrary("LibDataBroker-1.1", 1)
	broker.NewDataObject = function() return {} end
	local icon = env.LibStub:NewLibrary("LibDBIcon-1.0", 1)
	icon.Register = function() registered = true end
	env.PitBull4DB = { namespaces = { ["LibDualSpec-1.0"] = {
		char = { ["Tester - Realm"] = { enabled = true, [3] = "Healer" } },
	} } }
	env.spec = 3
	env.PitBull4, env.namespace = addon, ns
	env.CopyTable = function(value) return value end
	env.check_config_version = function() return false end
	env.CURRENT_CONFIG_VERSION = 1
	env.DATABASE_DEFAULTS = { profile = { colors = { power = {} }, minimap_icon = {} } }
	local file = assert(io.open(root .. "Main.lua", "r"))
	local source = file:read("*a"); file:close()
	local first = assert(source:find("function PitBull4:OnInitialize()", 1, true))
	local last = assert(source:find("\ndo\n\tlocal function find_PitBull4", first, true))
	assert(load(source:sub(first, last - 1), "PitBull4:OnInitialize", "t", env))()
	addon:OnInitialize()
	check(initialized and registered and profile_callbacks == 1,
		"real initialization completes module/minimap setup before applying saved profile")
	check(addon.db:GetCurrentProfile() == "Healer" and addon.SpecProfiles.current == 3,
		"real initialization attaches native profile controller and selects saved binding")
end
print("Native specialization-profile assertions passed: " .. passed)
