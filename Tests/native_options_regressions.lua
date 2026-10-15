local root = arg[1] or "PitBull4/"
local Fixture = dofile(root .. "Tests/native_fixture.lua")
local passed = 0
local function check(value, message) assert(value, message); passed = passed + 1 end
for _, case in ipairs({ { "Forever", 18, 0 }, { "Retail 12.1.0", 1, 11 },
	{ "Retail 12.1.5", 1, 11 }, { "Era", 2, 0 }, { "Mists", 19, 4 } }) do
	local env = Fixture.New(case[2], case[3])
	local ns = {}
	Fixture.Load(root .. "Options/NativeControls.lua", env, "PitBull4", ns)
	local standalone = ns.NativeOptionsControls.CreateToggle(env.UIParent)
	standalone:SetValue(true)
	check(standalone.check.shown and not standalone.check.desaturated, "native toggle needs no library")
	check(env.LibStub == nil and env.SetDesaturation == nil, "standalone does not inject a library/global")
	for _, file in ipairs({
		"Libs/LibStub/LibStub.lua", "Libs/CallbackHandler-1.0/CallbackHandler-1.0.lua",
		"Libs/AceGUI-3.0/AceGUI-3.0.lua", "Libs/AceGUI-3.0/widgets/AceGUIWidget-CheckBox.lua",
		"Libs/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua",
		"Libs/AceConfig-3.0/AceConfigDialog-3.0/AceConfigDialog-3.0.lua",
	}) do Fixture.Load(root .. file, env) end
	local gui = env.LibStub("AceGUI-3.0")
	local registry = env.LibStub("AceConfigRegistry-3.0")
	local dialog = env.LibStub("AceConfigDialog-3.0")
	local original_constructor = gui.WidgetRegistry.CheckBox
	local ok, message = pcall(gui.Create, gui, "CheckBox")
	check(not ok and tostring(message):find("SetDesaturation", 1, true), "unmodified old checkbox reproduces original error")
	local state, multi, selected = false, { one = true }, "a"
	local options = { type = "group", name = "Native controls", args = {
		toggle = { type = "toggle", name = "Toggle", order = 1, descStyle = "inline", desc = "Help",
			get = function() return state end, set = function(_, value) state = value end },
		multiple = { type = "multiselect", name = "Multiple", order = 2,
			values = { one = "One", two = "Two" }, get = function(_, key) return multi[key] end,
			set = function(_, key, value) multi[key] = value end },
		unknown = { type = "multiselect", name = "Unknown", order = 3, tristate = true,
			values = { x = "Unknown" }, get = function() return nil end, set = function() end },
		radio = { type = "select", name = "Radio", order = 4, style = "radio",
			values = { a = "A", b = "B" }, get = function() return selected end,
			set = function(_, key) selected = key end },
	} }
	local function provider() return ns.NativeOptionsControls.PrepareOptions(options) end
	registry:RegisterOptionsTable("PitBull4_NativeTest", provider)
	local resolved = registry:GetOptionsTable("PitBull4_NativeTest")("dialog", "AceConfigDialog-3.0")
	local container = Fixture.Container()
	dialog:Open("PitBull4_NativeTest", container)
	check(#container.children == 4, "real dialog creates all option controls")
	local toggle, multiple, unknown, radio = table.unpack(container.children)
	check(toggle.type == "PitBull4Toggle" and multiple.type == "PitBull4MultiSelect"
		and unknown.type == "PitBull4TriStateMultiSelect" and radio.type == "PitBull4RadioSelect",
		"real dialog selects only PitBull controls")
	check(toggle.description == "Help" and toggle.desc.shown, "inline description is rendered")
	check(multiple.rows[1].checked == true and multiple.rows[2].checked == nil, "initial multiselect values")
	check(unknown.rows[1].checked == nil and unknown.rows[1].check.shown
		and unknown.rows[1].check.desaturated, "three-state unknown display")
	toggle.frame.scripts.OnMouseUp(toggle.frame)
	check(state == true and toggle.checked == true, "real dialog writes the toggle setting")
	toggle:SetDisabled(true)
	toggle.frame.scripts.OnMouseUp(toggle.frame)
	check(state == true and not toggle.frame.enabled and toggle.check.desaturated, "disabled toggle ignores input")
	toggle:SetDisabled(false)
	toggle:SetTriState(true)
	toggle:ToggleChecked()
	check(toggle.checked == nil and toggle.check.shown and toggle.check.desaturated, "true to unknown")
	toggle:ToggleChecked()
	check(toggle.checked == false and not toggle.check.shown, "unknown to false")
	toggle:ToggleChecked()
	check(toggle.checked == true and not toggle.check.desaturated, "false to true")
	multiple.rows[2].frame.scripts.OnMouseUp(multiple.rows[2].frame)
	check(multi.two == true, "real dialog writes multiselect key/value")
	radio.rows[2].frame.scripts.OnMouseUp(radio.rows[2].frame)
	check(selected == "b" and radio.rows[2].checked and not radio.rows[1].checked, "radio selection writes one value")
	radio.rows[2].frame.scripts.OnMouseUp(radio.rows[2].frame)
	check(selected == "b" and radio.rows[2].checked, "selected radio stays selected")
	multiple:SetWidth(420)
	check(multiple.frame.height == 48, "wide collection uses two columns")
	multiple:SetWidth(170)
	check(multiple.frame.height == 72, "narrow collection reflows without polling")
	gui:Release(toggle)
	local reused = gui:Create("PitBull4Toggle")
	check(reused == toggle and reused.checked == false and not reused.tristate
		and not reused.disabled and not reused.desc.shown, "toggle reuse resets native state")
	gui:Release(multiple)
	local reused_multi = gui:Create("PitBull4MultiSelect")
	check(reused_multi == multiple and #reused_multi.keys == 0 and not reused_multi.rows[1].frame.shown,
		"collection reuse hides old rows")
	reused_multi:SetList({ fresh = "Fresh" })
	check(#reused_multi.keys == 1 and reused_multi.rows[1].key == "fresh"
		and not reused_multi.rows[2].frame.shown, "reused rows get current keys")
	options.args.later = { type = "toggle", name = "Late", get = function() return false end, set = function() end }
	provider()
	check(options.args.later.dialogControl == "PitBull4Toggle", "late options are routed on every query")
	local custom = { type = "toggle", dialogControl = "OtherAddonToggle" }
	local cyclic = { type = "group", args = { custom = custom } }
	cyclic.args.self = cyclic
	ns.NativeOptionsControls.PrepareOptions(cyclic)
	check(custom.dialogControl == "OtherAddonToggle", "explicit foreign controls are preserved")
	check(gui.WidgetRegistry.CheckBox == original_constructor and gui:GetWidgetVersion("CheckBox") == 26,
		"shared checkbox factory/version are unchanged")
	check(env.SetDesaturation == nil and env.LibStub("LibDualSpec-1.0", true) == nil, "no global shim or specialization library")
	check(#env.errors == 0, "dialog does not suppress widget/callback errors")
	print(case[1] .. ": native controls and actual AceConfig dialog pass")
end
print("Native options regression assertions passed: " .. passed)
