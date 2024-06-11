
local _G = _G
local PitBull4 = _G.PitBull4
local L = setmetatable({}, {__index = function(t,k) t[k]=k return k end}) -- PitBull4.L
--[[

-- ui
L["Current Profile: |cffffd100%s|r"]
L["Import"]
L["Layouts"]
L["Paste (CTRL-V) the share string into the field below then click \"Accept\""]
L["Profiles"]
L["Select which layouts to share."]
L["Select which profile to share."]
L["Share"]
L["Share layouts"]
L["Share profile"]
L["Some things to keep in mind:\n- Fonts and textures are not included and may get reset to default if not available.\n- Global module settings are not included with layouts (e.g. Aura filters)\n- Module settings and will only be imported if the module is currently enabled.\n"]

-- popup
L["Are you sure you want to import the following layouts into the current profile?\n\n%s"]
L["Enter a new profile name:"]
L["Copy (Ctrl-C) this to the clipboard."]

-- processing
L["Profile import complete! You may now select %q under Profiles."]
L["Skipped settings for the following disabled or unavailable modules: %s"]
-- ERROR
L["Import data is corrupt."]
L["Import data is from an incompatible version."]
L["Missing profile name."]
L["Layout %q is corrupt, skipping."]
L["No layouts found."]
L["Unknown import type."]

--]]

local AceGUI = LibStub("AceGUI-3.0")
local LibSerialize = LibStub("LibSerialize")
local LibDeflate = LibStub("LibDeflate")

local CURRENT_VERSION = 2
local MINIMAL_VERSION = 2
local DEFLATE_OPTS = { level = 9 }

local layouts_to_export = {}
local profile_to_export = nil

local DoExport, DoImportPhase1, DoImportPhase2Layout, DoImportPhase2Profile

local deep_copy = PitBull4.Utils.deep_copy
local sort = table.sort

local function Print(...)
	PitBull4:Print(...)
end

local function Error(...)
	PitBull4:Print("|cffff2020ERROR!|r", ...)
end

local function Debug(...)
	if PitBull4.DEBUG then
		PitBull4:Print("|cff5de2e7DEBUG:|r", ...)
	end
end

-- soooo normal table look ups error and/or crash wow. AceDB voodoo to blame?
local function checkLayoutExists(name)
	for key in next, PitBull4.db.profile.layouts do
		if name == key then
			return true
		end
	end
end

local function suggestLayoutName(name)
	if checkLayoutExists(name) then
		local counter = 1
		local new_name = ("%s (%d)"):format(name, counter)
		while checkLayoutExists(new_name) do
			counter = counter + 1
			new_name = ("%s (%d)"):format(name, counter)
		end
		return new_name
	end

	return name
end


StaticPopupDialogs["PB4ShareConfigImportLayoutsConfirmDialog"] = {
	text = L["Are you sure you want to import the following layouts into the current profile?\n\n%s"],
	button1 = _G.OKAY,
	button2 = _G.CANCEL,
	hasEditBox = false,
	OnAccept = function(self) DoImportPhase2Layout(self.data) end,
	OnShow = function(self)
		-- Get above the PB4 config window
		self:SetFrameStrata("FULLSCREEN_DIALOG")
		self:SetFrameLevel(self:GetFrameLevel() + 2)
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 4,
}

StaticPopupDialogs["PB4ShareConfigImportProfileConfirmDialog"] = {
	text = L["Enter a new profile name:"],
	button1 = _G.OKAY,
	button2 = _G.CANCEL,
	hasEditBox = true,
	maxLetters = 64,
	editBoxWidth = 150,
	OnAccept = function(self)
		local profile_name = self.editBox:GetText()
		if profile_name and profile_name ~= "" then
			DoImportPhase2Profile(self.data, profile_name)
		end
	end,
	EditBoxOnEnterPressed = function(self)
		local dialog = self:GetParent()
		dialog:OnAccept()
		dialog:Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	OnShow = function(self)
		-- Get above the PB4 config window
		self:SetFrameStrata("FULLSCREEN_DIALOG")
		self:SetFrameLevel(self:GetFrameLevel() + 2)
	end,
	OnHide = function(self)
		self:SetFrameStrata("DIALOG")
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
	preferredIndex = 4,
}

local function ImportDialog(imported_table)
	if imported_table.profile then
		StaticPopup_Show("PB4ShareConfigImportProfileConfirmDialog", nil, nil, imported_table)
	else
		local layouts = {}
		for key in next, imported_table.layouts do
			layouts[#layouts+1] = key
		end
		sort(layouts)
		layouts = table.concat(layouts, ", ")

		StaticPopup_Show("PB4ShareConfigImportLayoutsConfirmDialog", layouts, nil, imported_table)
	end
end


local function ExportDialog(export_mode)
	local exported_string = DoExport(export_mode)

	local frame = AceGUI:Create("Frame")
	frame:SetTitle(L["Share"])
	frame:SetLayout("Fill")
	frame:EnableResize(false)

	local editBox = AceGUI:Create("MultiLineEditBox")
	editBox:DisableButton(true)
	editBox:SetLabel(L["Copy (Ctrl-C) this to the clipboard."])
	editBox:SetText(exported_string)
	editBox:SetFocus()
	editBox:HighlightText(0)
	frame:AddChild(editBox)

	frame:SetCallback("OnClose", function(widget)
		editBox:SetText("")
		AceGUI:Release(widget)
	end)

	frame:Show()
end

function DoExport(export_mode)
	Debug("DoExport", export_mode)

	local exported_table = {
		version = CURRENT_VERSION,
		modules = {},
	}

	if export_mode == "profile" then
		Debug("Including profile", profile_to_export)
		exported_table.type = "profile"
		exported_table.profile = deep_copy(PitBull4.db.profiles[profile_to_export])

		for id, module in PitBull4:IterateModules() do
			local module_db = module.db and module.db.profiles and module.db.profiles[profile_to_export]
			if module_db then
				Debug("Including module", id)
				exported_table.modules[id] = deep_copy(module_db)
			end
		end
	else
		exported_table.type = "layouts"
		exported_table.layouts = {}

		for layout in next, layouts_to_export do
			Debug("Including layout", layout)
			exported_table.layouts[layout] = deep_copy(PitBull4.db.profile.layouts[layout])

			exported_table.modules[layout] = {}
			for id, module in PitBull4:IterateModules() do
				local module_db = module.db and module.db.profile and module.db.profile.layouts and module.db.profile.layouts[layout]
				if module_db then
					Debug("Including module", id)
					exported_table.modules[layout][id] = deep_copy(module_db)
				end
			end
		end
	end

	local serialized = LibSerialize:Serialize(exported_table)
	Debug("Length (Serialized):", #serialized)
	local compressed = LibDeflate:CompressDeflate(serialized, DEFLATE_OPTS)
	Debug("Length (Serialized+Compressed):", #compressed)
	local encoded = LibDeflate:EncodeForPrint(compressed)
	Debug("Length (Serialized+Compressed+Encoded):", #encoded)

	return encoded
end

function DoImportPhase1(import_string)
	local imported_table = nil
	local success, result = nil, nil

	if type(import_string) ~= "string" then
		Debug("Import needs a string, got", type(import_string))
	else
		local decompressed, result = LibDeflate:DecompressDeflate(LibDeflate:DecodeForPrint(import_string))
		if not decompressed then
			Debug("Decompress error", result)
		else
			success, result = LibSerialize:Deserialize(decompressed)
			if success then
				imported_table = result
			else
				Debug("Deserialize error", result)
			end
		end
	end

	if not imported_table or type(imported_table) ~= "table" then
		Error(L["Import data is corrupt."])
		return
	end
	if (imported_table.version or 0) < MINIMAL_VERSION then
		Error(L["Import data is from an incompatible version."])
		return
	end

	if imported_table.type == "profile" then
		if type(imported_table.profile) ~= "table" or type(imported_table.profile.layouts) ~= "table" or not next(imported_table.profile.layouts) then
			Error(L["No layouts found."])
			return
		end

		ImportDialog(imported_table)

	elseif imported_table.type == "layouts" then
		-- rename layouts with name conflicts
		local layout_names = {}
		for layout, content in next, imported_table.layouts do
			if type(layout) == "string" and type(content) == "table" then
				layout_names[layout] = true
			end
		end

		if not next(layout_names) then
			Error(L["No layouts found."])
			return
		end

		-- use a name table to rename without fear of iterating endlessly
		for layout in next, layout_names do
			local new_layout = suggestLayoutName(layout)
			if new_layout ~= layout then
				imported_table.layouts[new_layout] = imported_table.layouts[layout]
				imported_table.layouts[layout] = nil

				imported_table.modules[new_layout] = imported_table.modules[layout]
				imported_table.modules[layout] = nil
			end
		end

		ImportDialog(imported_table)

	else
		Error(L["Unknown import type."])
	end
end

function DoImportPhase2Layout(layouts_to_import)
	if type(layouts_to_import) ~= "table" or type(layouts_to_import.layouts) ~= "table" or not next(layouts_to_import.layouts) then
		Error(L["No layouts found."])
		return
	end

	local skipped = {}
	for layout, content in next, layouts_to_import.layouts do
		if type(layout) == "string" and type(content) == "table" then
			Debug("Importing layout", layout)
			PitBull4.db.profile.layouts[layout] = deep_copy(content)

			local layout_modules = layouts_to_import.modules[layout]
			for id, module in PitBull4:IterateModules() do
				local layout_module = layout_modules[id]
				if layout_module and type(layout_module) == "table" then
					Debug("Importing module settings for", id)
					module.db.profile.layouts[layout] = deep_copy(layout_module)
					layout_modules[id] = nil
				end
			end
			for name in next, layout_modules do
				skipped[name] = true
			end
			Debug("Imported layout", layout)
		else
			Error(L["Layout %q is corrupt, skipping."]:format(tostring(layout)))
		end
	end

	Print(L["Layout import complete!"])
	if next(skipped) then
		local temp = {}
		for name in next, skipped do
			temp[#temp+1] = name
		end
		sort(temp)
		Print(L["Skipped settings for the following disabled or unavailable modules: %s"]:format(table.concat(temp, ", ")))
	end
end

function DoImportPhase2Profile(profile_to_import, profile_name_to_import)
	local profile_name = tostring(profile_name_to_import)
	if profile_name == "" or profile_name == nil then
		Error(L["Missing profile name."])
		return
	end

	Debug("Importing new profile", profile_name)
	PitBull4.db.profiles[profile_name] = deep_copy(profile_to_import.profile)

	-- import the module settings
	local skipped = {}
	for id, module in PitBull4:IterateModules() do
		local profile_module = profile_to_import.modules[id]
		if profile_module and module.db and module.db.profiles then
			Debug("Including module", id)
			module.db.profiles[profile_name] = deep_copy(profile_module)
			profile_to_import.modules[id] = nil
		end
	end
	for name in next, profile_to_import.modules do
		skipped[name] = true
	end

	Print(L["Profile import complete! You may now select %q under Profiles."]:format(profile_name))
	if next(skipped) then
		local temp = {}
		for name in next, skipped do
			temp[#temp+1] = name
		end
		sort(temp)
		Print(L["Skipped settings for the following disabled or unavailable modules: %s"]:format(table.concat(temp, ", ")))
	end
end


-------------------
-- User Interface
-------------------

local function get_profile_export()
	return profile_to_export
end
local function set_profile_export(_, value)
	profile_to_export = value
end

local function get_layout_export(_, key)
	return layouts_to_export[key]
end
local function set_layout_export(_, key, value)
	local layouts_list = PitBull4.db.profile.layouts
	if checkLayoutExists(key) then
		layouts_to_export[key] = value or nil
	end
end

function PitBull4.Options.OnProfileChanged()
	profile_to_export = nil
	wipe(layouts_to_export)
end

function PitBull4.Options.get_share_options()
	local group_import = {
		type = "group",
		name = L["Import"],
		args = {
			import_info = {
				type = "description",
				name = L["While this should be safe, it's always good to have a backup of your SavedVariables in case something bad happens!"],
				order = 1,
				fontSize = "medium",
			},
			import_text = {
				type = "input",
				name = L["Paste (CTRL-V) the share string into the field below then click \"Accept\""],
				order = 2,
				get = function() return "" end,
				set = function(_, value)
					value = tostring(value)
					if value and value ~= "" then
						DoImportPhase1(string.gsub(value, "\n", ""))
					end
				end,
				multiline = 5,
				width = "full",
			},
		},
	}

	local group_export = {
		type = "group",
		name = L["Share"],
		args = {
			export_info = {
				type = "description",
				name = L["Some things to keep in mind:\n- Fonts and textures are not included and may get reset to default if not available.\n- Global module settings are not included with layouts (e.g. Aura filters)\n- Module settings and will only be imported if the module is currently enabled.\n"],
				order = 1,
				fontSize = "medium"
			},
			export_layout = {
				type = "group",
				name = L["Share layouts"],
				inline = true,
				order = 2,
				args = {
					export_layout_select = {
						type = "multiselect",
						name = L["Layouts"],
						desc = L["Select which layouts to share."],
						order = 1,
						get = get_layout_export,
						set = set_layout_export,
						values = function()
							local layouts_list = {}
							for name in next, PitBull4.db.profile.layouts do
								layouts_list[name] = name
							end
							return layouts_list
						end,
					},
					export_layout_button = {
						type = "execute",
						name = L["Share"],
						order = 2,
						func = function()
							ExportDialog("layout")
							wipe(layouts_to_export)
						end,
						disabled = function() return not next(layouts_to_export) end,
					},
					current_profile = {
						type = "description",
						name = function() return " " .. L["Current Profile: |cffffd100%s|r"]:format(PitBull4.db:GetCurrentProfile()) end,
						order = 3,
						width = "default",
					},
				},
			},
			export_profile = {
				type = "group",
				name = L["Share profile"],
				inline = true,
				order = 3,
				args = {
					export_profile_select = {
						type = "select",
						name = L["Profiles"],
						desc = L["Select which profile to share."],
						order = 1,
						get = get_profile_export,
						set = set_profile_export,
						values = function()
							local profiles_list = {}
							for name in next, PitBull4.db.profiles do
								if name ~= "global" then
									profiles_list[name] = name
								end
							end
							return profiles_list
						end,
					},
					export_profile_button = {
						type = "execute",
						name = L["Share"],
						order = 2,
						func = function()
							ExportDialog("profile")
							profile_to_export = nil
						end,
						disabled = function() return not profile_to_export or profile_to_export == "" end,
					},
				},
			},
		},
	}

	return group_import, group_export
end
