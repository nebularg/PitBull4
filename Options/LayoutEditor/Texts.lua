local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local CURRENT_CUSTOM_TEXT_MODULE
local CURRENT_TEXT_PROVIDER_MODULE
local CURRENT_TEXT_PROVIDER_ID

--- Return the DB dictionary for the current text for the current layout selected in the options frame.
-- TextProvider modules should be calling this and manipulating data within it.
-- @usage local db = PitBull.Options.GetTextLayoutDB(); db.some_option = "something"
-- @return the DB dictionary for the current text
function PitBull4.Options.GetTextLayoutDB()
	if not CURRENT_TEXT_PROVIDER_MODULE then
		return
	end
	
	return PitBull4.Options.GetLayoutDB(CURRENT_TEXT_PROVIDER_MODULE).texts[CURRENT_TEXT_PROVIDER_ID]
end

function PitBull4.Options.get_layout_editor_text_options()
	local GetLayoutDB = PitBull4.Options.GetLayoutDB
	local GetTextLayoutDB = PitBull4.Options.GetTextLayoutDB
	local UpdateFrames = PitBull4.Options.UpdateFrames
	
	local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
	LoadAddOn("AceGUI-3.0-SharedMediaWidgets")
	local AceGUI = LibStub("AceGUI-3.0")
	
	local options = {
		name = L["Texts"],
		desc = L["Texts convey information in a non-graphical manner."],
		type = 'group',
		args = {}
	}
	
	local root_locations = PitBull4.Options.root_locations
	local bar_locations = PitBull4.Options.bar_locations
	
	local function disabled()
		if CURRENT_CUSTOM_TEXT_MODULE then
			return not GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).enabled
		else
			return not CURRENT_TEXT_PROVIDER_MODULE
		end
	end
	
	options.args.current_text = {
		name = L["Current text"],
		desc = L["Change the current text that you are editing."],
		type = 'select',
		order = 1,
		values = function(info)
			local t = {}
			local first, first_module, first_id
			for id, module in PitBull4:IterateModulesOfType("text_provider") do
				local texts_db = GetLayoutDB(module).texts
				for i = 1, texts_db.n do
					local v = texts_db[i]
					local key = ("%s;%03d"):format(id, i)
					if not first_module then
						first_module = module
						first_id = i
					end
					t[key] = v.name or L["<Unnamed>"]
				end
			end
			for id, module in PitBull4:IterateModulesOfType("custom_text") do
				t[id] = module.name
				if not first_module then
					first_module = module
					first_id = nil
				end
			end
			if (not CURRENT_TEXT_PROVIDER_MODULE or not t[("%s;%03d"):format(CURRENT_TEXT_PROVIDER_MODULE.id, CURRENT_TEXT_PROVIDER_ID)]) and (not CURRENT_CUSTOM_TEXT_MODULE or not t[CURRENT_CUSTOM_TEXT_MODULE.id]) then
				if first_id then
					CURRENT_TEXT_PROVIDER_MODULE = first_module
					CURRENT_TEXT_PROVIDER_ID = first_id
					CURRENT_CUSTOM_TEXT_MODULE = nil
				else
					CURRENT_TEXT_PROVIDER_MODULE = nil
					CURRENT_TEXT_PROVIDER_ID = nil
					CURRENT_CUSTOM_TEXT_MODULE = first_module
				end
			end
			return t
		end,
		get = function(info)
			if CURRENT_TEXT_PROVIDER_MODULE then
				return ("%s;%03d"):format(CURRENT_TEXT_PROVIDER_MODULE.id, CURRENT_TEXT_PROVIDER_ID)
			elseif CURRENT_CUSTOM_TEXT_MODULE then
				return CURRENT_CUSTOM_TEXT_MODULE.id
			else
				return nil
			end
		end,
		set = function(info, value)
			local module_name, id = (";"):split(value)
			if id then
				for m_id, m in PitBull4:IterateModulesOfType("text_provider") do
					if module_name == m_id then
						CURRENT_TEXT_PROVIDER_MODULE = m
						CURRENT_TEXT_PROVIDER_ID = id+0
						CURRENT_CUSTOM_TEXT_MODULE = nil
					end
				end
			else
				for m_id, m in PitBull4:IterateModulesOfType("custom_text") do
					if module_name == m_id then
						CURRENT_TEXT_PROVIDER_MODULE = nil
						CURRENT_TEXT_PROVIDER_ID = nil
						CURRENT_CUSTOM_TEXT_MODULE = m
					end
				end
			end
		end,
		disabled = disabled
	}
	
	local function text_name_validate(info, value)
		if value:len() < 3 then
			return L["Must be at least 3 characters long."]
		end
		
		for id, module in PitBull4:IterateModulesOfType("text_provider") do
			local texts_db = GetLayoutDB(module).texts
			
			for i = 1, texts_db.n do
				if texts_db[i].name and value:lower() == texts_db[i].name:lower() then
					return L["'%s' is already a text."]:format(value)
				end
			end
		end
		
		for id, module in PitBull4:IterateModulesOfType("text_provider") do
			return true -- found a module
		end
		return L["You have no enabled text providers."]
	end
	
	options.args.new_text = {
		name = L["New text"],
		desc = L["This will make a new text for the layout."],
		type = 'input',
		order = 2,
		get = function(info) return "" end,
		set = function(info, value)
			local module = CURRENT_TEXT_PROVIDER_MODULE
			
			if not module then
				for id, m in PitBull4:IterateModulesOfType("text_provider") do
					module = m
					break
				end
				
				assert(module) -- the validate function should verify that at least one module exists
			end
			
			local texts_db = GetLayoutDB(module).texts
			
			texts_db.n = texts_db.n + 1
			local db = texts_db[texts_db.n]
			db.name = value
			
			CURRENT_TEXT_PROVIDER_MODULE = module
			CURRENT_TEXT_PROVIDER_ID = texts_db.n
			
			UpdateFrames()
		end,
		validate = text_name_validate,
	}
	
	options.args.font = {
		type = 'select',
		name = L["Default font"],
		desc = L["The font of texts, unless overridden."],
		order = 3,
		get = function(info)
			return GetLayoutDB(false).font
		end,
		set = function(info, value)
			GetLayoutDB(false).font = value

			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			for k in pairs(LibSharedMedia:HashTable("font")) do
				t[k] = k
			end
			return t
		end,
		hidden = function(info)
			return not LibSharedMedia or #LibSharedMedia:List("font") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Font"] and "LSM30_Font" or nil,
	}
	
	options.args.edit = {
		type = 'group',
		name = L["Edit text"],
		inline = true,
		args = {},
	}
	
	options.args.edit.args.remove = {
		type = 'execute',
		name = L["Remove"],
		desc = L["Remove this text."],
		confirm = true,
		confirmText = L["Are you sure you want to remove this text?"],
		order = 1,
		func = function()
			local texts_db = GetLayoutDB(CURRENT_TEXT_PROVIDER_MODULE).texts
			
			table.remove(texts_db, CURRENT_TEXT_PROVIDER_ID)
			local n = texts_db.n - 1
			texts_db.n = n
			if n >= 1 then
				if CURRENT_TEXT_PROVIDER_ID > n then
					CURRENT_TEXT_PROVIDER_ID = n
				end
			else
				CURRENT_TEXT_PROVIDER_MODULE = nil
				CURRENT_TEXT_PROVIDER_ID = nil
				for id, module in PitBull4:IterateModulesOfType("text_provider") do
					local texts_db = GetLayoutDB(module).texts
					
					if texts_db.n > 0 then
						CURRENT_TEXT_PROVIDER_MODULE = module
						CURRENT_TEXT_PROVIDER_ID = 1
						break
					end
				end
			end
			
			UpdateFrames()
		end,
		disabled = disabled,
		hidden = function(info)
			return not not CURRENT_CUSTOM_TEXT_MODULE
		end
	}
	
	options.args.edit.args.enabled = {
		type = 'toggle',
		name = L["Enable"],
		desc = L["Enable this text."],
		order = 1,
		get = function(info)
			return GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).enabled
		end,
		set = function(info, value)
			GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).enabled = value
			
			UpdateFrames()
		end,
		hidden = function(info)
			return not CURRENT_CUSTOM_TEXT_MODULE
		end,
	}
	
	options.args.edit.args.name = {
		type = 'input',
		name = L["Name"],
		order = 2,
		desc = function()
			local db = GetTextLayoutDB()
			return L["Rename the '%s' text."]:format(db and db.name or L["<Unnamed>"])
		end,
		get = function(info)
			local db = GetTextLayoutDB()
			return db and db.name or L["<Unnamed>"]
		end,
		set = function(info, value)
			GetTextLayoutDB().name = value
			
			UpdateFrames()
		end,
		validate = text_name_validate,
		disabled = disabled,
		hidden = function(info)
			return not not CURRENT_CUSTOM_TEXT_MODULE
		end
	}
	
	options.args.edit.args.provider = {
		type = 'select',
		name = L["Type"],
		desc = L["What text provider is used for this text."],
		order = 3,
		get = function(info)
			return CURRENT_TEXT_PROVIDER_MODULE and CURRENT_TEXT_PROVIDER_MODULE.id
		end,
		set = function(info, value)
			if value == CURRENT_TEXT_PROVIDER_MODULE.id then
				return
			end
			
			local texts_db = GetLayoutDB(CURRENT_TEXT_PROVIDER_MODULE).texts
			
			local old_db = table.remove(texts_db, CURRENT_TEXT_PROVIDER_ID)
			local n = texts_db.n - 1
			texts_db.n = n
			
			CURRENT_TEXT_PROVIDER_MODULE = PitBull4:GetModule(value)
			texts_db = GetLayoutDB(CURRENT_TEXT_PROVIDER_MODULE).texts
			n = texts_db.n + 1
			texts_db.n = n
			
			local new_db = texts_db[n]
			new_db.name = old_db.name
			new_db.size = old_db.size
			new_db.attach_to = old_db.attach_to
			new_db.location = old_db.location
			new_db.position = old_db.position
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			for id, m in PitBull4:IterateModulesOfType("text_provider") do
				t[id] = m.name
			end
			return t
		end,
		disabled = disabled,
		hidden = function(info)
			return not not CURRENT_CUSTOM_TEXT_MODULE
		end
	}
	
	options.args.edit.args.attach_to = {
		type = 'select',
		name = L["Attach to"],
		desc = L["Which control to attach to."],
		order = 4,
		get = function(info)
			if CURRENT_CUSTOM_TEXT_MODULE then
				return GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).attach_to
			end
			if not CURRENT_TEXT_PROVIDER_MODULE then
				return
			end
			return GetTextLayoutDB().attach_to
		end,
		set = function(info, value)
			if CURRENT_CUSTOM_TEXT_MODULE then
				GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).attach_to = value
			else
				GetTextLayoutDB().attach_to = value
			end
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			
			t["root"] = L["Unit frame"]
			
			for id, module in PitBull4:IterateModulesOfType("status_bar") do
				t[id] = module.name
			end
			
			return t
		end,
		disabled = disabled,
	}
	
	options.args.edit.args.location = {
		type = 'select',
		name = L["Location"],
		desc = L["Where on the control to place the text."],
		order = 5,
		get = function(info)
			if CURRENT_CUSTOM_TEXT_MODULE then
				return GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).location
			end
			if not CURRENT_TEXT_PROVIDER_MODULE then
				return nil
			end
			return GetTextLayoutDB().location
		end,
		set = function(info, value)
			if CURRENT_CUSTOM_TEXT_MODULE then
				GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).location = value
			else
				GetTextLayoutDB().location = value
			end
			
			UpdateFrames()
		end,
		values = function(info)
			local attach_to
			if CURRENT_CUSTOM_TEXT_MODULE then
				attach_to = GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).attach_to
			elseif CURRENT_TEXT_PROVIDER_MODULE then
				attach_to = GetTextLayoutDB().attach_to
			else
				attach_to = "root"
			end
			if attach_to == "root" then
				return root_locations
			else
				return bar_locations
			end
		end,
		disabled = disabled,
	}
	
	options.args.edit.args.font = {
		type = 'select',
		name = L["Font"],
		desc = L["Which font to use for this text."],
		order = 4,
		get = function(info)
			local font
			if CURRENT_CUSTOM_TEXT_MODULE then
				font = GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).font
			elseif CURRENT_TEXT_PROVIDER_MODULE then
				font = GetTextLayoutDB().font
			end
			return font or GetLayoutDB(false).font
		end,
		set = function(info, value)
			local default = GetLayoutDB(false).font
			if value == default then
				value = nil
			end
			
			if CURRENT_CUSTOM_TEXT_MODULE then
				GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).font = value
			else
				GetTextLayoutDB().font = value
			end
			
			UpdateFrames()
		end,
		values = function(info)
			local t = {}
			local default = GetLayoutDB(false).font
			for k in pairs(LibSharedMedia:HashTable("font")) do
				if k == default then
					t[k] = ("%s (Default)"):format(k)
				else
					t[k] = k
				end
			end
			return t
		end,
		disabled = disabled,
		hidden = function(info)
			return not LibSharedMedia or #LibSharedMedia:List("font") <= 1
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Font"] and "LSM30_Font" or nil,
	}
	
	options.args.edit.args.size = {
		type = 'range',
		name = L["Size"],
		desc = L["Size of the text."],
		order = 7,
		get = function(info)
			if CURRENT_CUSTOM_TEXT_MODULE then
				return GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).size
			end
			if not CURRENT_TEXT_PROVIDER_MODULE then
				return 1
			end
			return GetTextLayoutDB().size
		end,
		set = function(info, value)
			if CURRENT_CUSTOM_TEXT_MODULE then
				GetLayoutDB(CURRENT_CUSTOM_TEXT_MODULE).size = value
			else
				GetTextLayoutDB().size = value
			end
			
			UpdateFrames()
		end,
		min = 0.5,
		max = 3,
		step = 0.01,
		bigStep = 0.05,
		isPercent = true,
		disabled = disabled,
	}
	
	local layout_functions = PitBull4.Options.layout_functions
	
	for id, module in PitBull4:IterateModulesOfType("text_provider", true) do
		if layout_functions[module] then
			local t = { layout_functions[module](module) }
			layout_functions[module] = false
			
			for i = 1, #t, 2 do
				local k = t[i]
				local v = t[i+1]
				
				v.order = i + 100
				
				local old_disabled = v.disabled
				v.disabled = function(info)
					return disabled(info) or (old_disabled and old_disabled(info))
				end
				
				local old_hidden = v.hidden
				v.hidden = function(info)
					return module ~= CURRENT_TEXT_PROVIDER_MODULE or (old_hidden and old_hidden(info))
				end
				
				options.args.edit.args[id .. "-" .. k] = v
			end
		end
	end
	
	for id, module in PitBull4:IterateModulesOfType("custom_text", true) do
		if layout_functions[module] then
			local t = { layout_functions[module](module) }
			layout_functions[module] = false
			
			local order = 100
			for i = 1, #t, 2 do
				local k = t[i]
				local v = t[i+1]
				
				order = order + 1
				
				v.order = order
				
				local old_disabled = v.disabled
				v.disabled = function(info)
					return disabled(info) or (old_disabled and old_disabled(info))
				end
				
				local old_hidden = v.hidden
				v.hidden = function(info)
					return module ~= CURRENT_CUSTOM_TEXT_MODULE or (old_hidden and old_hidden(info))
				end
				
				options.args.edit.args[id .. "-" .. k] = v
			end
		end
	end
	
	return options
end