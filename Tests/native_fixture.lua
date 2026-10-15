local Fixture = {}
local Methods = {}
local function region(parent)
	return setmetatable({ parent = parent, scripts = {}, points = {}, native_width = 200,
		native_height = 24, shown = true, enabled = true, registered = {} }, { __index = Methods })
end
function Methods:GetWidth() return self.native_width end
function Methods:GetHeight() return self.native_height end
function Methods:SetWidth(value)
	local changed = self.native_width ~= value
	self.native_width = value
	if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self, value, self.native_height) end
end
function Methods:SetHeight(value)
	local changed = self.native_height ~= value
	self.native_height = value
	if changed and self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self, self.native_width, value) end
end
function Methods:SetSize(width, height) self:SetWidth(width); self:SetHeight(height) end
function Methods:SetPoint(...) self.points[#self.points + 1] = { ... } end
function Methods:ClearAllPoints() self.points = {} end
function Methods:SetAllPoints() end
function Methods:Hide() self.shown = false end
function Methods:Show() self.shown = true end
function Methods:IsShown() return self.shown end
function Methods:IsVisible() return self.shown end
function Methods:Enable() self.enabled = true end
function Methods:Disable() self.enabled = false end
function Methods:SetParent(value) self.parent = value end
function Methods:SetScript(event, callback) self.scripts[event] = callback end
function Methods:GetScript(event) return self.scripts[event] end
function Methods:RegisterEvent(event) self.registered[event] = true end
function Methods:RegisterUnitEvent(event, unit) self.registered[event] = unit end
function Methods:SetTexture(value) self.texture = value end
function Methods:GetTexture() return self.texture end
function Methods:SetText(value) self.text = value end
function Methods:GetText() return self.text end
function Methods:GetStringHeight() return 18 end
function Methods:SetTextColor(r, g, b) self.color = { r, g, b } end
function Methods:SetDesaturated(value)
	assert(type(value) == "boolean", "native texture method requires a boolean")
	self.desaturated = value
end
function Methods:CreateTexture() return region(self) end
function Methods:CreateFontString() return region(self) end
function Methods:SetNormalTexture(value) self.normal = region(); self.normal:SetTexture(value) end
function Methods:SetPushedTexture(value) self.pushed = region(); self.pushed:SetTexture(value) end
function Methods:SetHighlightTexture(value) self.highlight = region(); self.highlight:SetTexture(value) end
function Methods:GetNormalTexture() return self.normal end
function Methods:GetPushedTexture() return self.pushed end
function Methods:GetHighlightTexture() return self.highlight end
for _, method in ipairs({ "EnableMouse", "SetTexCoord", "SetBlendMode", "SetJustifyH",
	"SetJustifyV", "SetFrameStrata", "SetFrameLevel", "SetFixedFrameStrata",
	"SetFixedFrameLevel", "SetNormalFontObject", "SetHighlightFontObject" }) do
	Methods[method] = function() end
end

function Fixture.Load(path, env, ...)
	local chunk, message = loadfile(path, "t", env)
	assert(chunk, message)
	return chunk(...)
end
function Fixture.New(project, expansion)
	local env = setmetatable({}, { __index = _G })
	env._G = env
	env.table = setmetatable({ wipe = function(t) for key in pairs(t) do t[key] = nil end end }, { __index = table })
	env.wipe, env.unpack = env.table.wipe, table.unpack
	env.strmatch = function(value, pattern) return string.match(tostring(value), pattern) end
	env.strjoin = function(separator, ...) return table.concat({ ... }, separator) end
	env.securecallfunction = function(callback, ...) return callback(...) end
	env.UIParent = region()
	env.CreateFrame = function(_, _, parent) return region(parent) end
	env.InCombatLockdown = function() return env.in_combat == true end
	env.WOW_PROJECT_ID, env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC = project, 1, 2
	env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC, env.WOW_PROJECT_CATACLYSM_CLASSIC = 5, 14
	env.WOW_PROJECT_MISTS_CLASSIC, env.WOW_PROJECT_CAMELOT = 19, 18
	env.LE_EXPANSION_CLASSIC, env.LE_EXPANSION_MISTS_OF_PANDARIA = 0, 4
	env.GetClassicExpansionLevel = function() return expansion end
	env.UnitClassBase = function() return "MAGE", 8 end
	env.UnitName = function() return "Tester" end
	env.canaccessvalue = function(value) return not (type(value) == "table" and value.opaque) end
	env.C_EventUtils = { IsEventValid = function(event) return not (env.invalid_events or {})[event] end }
	env.GetLocale = function() return "enUS" end
	env.CloseSpecialWindows = function() return false end
	env.ACCEPT, env.CANCEL = "Accept", "Cancel"
	env.errors, env.sounds = {}, {}
	env.PlaySound = function(sound) env.sounds[#env.sounds + 1] = sound end
	env.geterrorhandler = function() return function(message) env.errors[#env.errors + 1] = message end end
	return env
end
function Fixture.Container()
	local container = { type = "InlineGroup", children = {}, userdata = {}, content = region() }
	function container:SetLayout() end
	function container:PauseLayout() end
	function container:ResumeLayout() end
	function container:DoLayout() end
	function container:ReleaseChildren()
		for _, child in ipairs(self.children) do child:Release() end
		self.children = {}
	end
	function container:AddChild(widget)
		self.children[#self.children + 1] = widget
		widget:SetParent(self)
		widget:SetWidth(widget.width == "fill" and 420 or 170)
	end
	function container:GetUserData(key) return self.userdata[key] end
	function container:SetUserData(key, value) self.userdata[key] = value end
	function container:GetUserDataTable() return self.userdata end
	return container
end
return Fixture
