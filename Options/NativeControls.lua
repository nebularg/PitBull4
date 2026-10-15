local _, namespace = ...
local Controls = {}
namespace.NativeOptionsControls = Controls

local CreateFrame, PlaySound = CreateFrame, PlaySound
local floor, max = math.floor, math.max
local Toggle = {}
Toggle.__index = Toggle

local function fire(self, event, ...)
	local callback = self.events[event]
	if callback then return callback(self, event, ...) end
end

function Toggle:SetCallback(event, callback) self.events[event] = callback end
function Toggle:Fire(event, ...) return fire(self, event, ...) end
function Toggle:GetValue() return self.checked end
function Toggle:SetLabel(label) self.text:SetText(label or "") end
function Toggle:SetHeight(height)
	self.frame:SetHeight(height)
	self.frame.height = height
end
function Toggle:SetWidth(width)
	self.frame:SetWidth(width)
	self.frame.width = width
	self:OnWidthSet(width)
end
function Toggle:OnWidthSet(width)
	self.text:ClearAllPoints()
	local anchor = self.image:GetTexture() and self.image or self.checkbg
	self.text:SetPoint("LEFT", anchor, "RIGHT", self.pressed and 1 or 0, self.pressed and -1 or 0)
	self.text:SetPoint("RIGHT", self.frame, "RIGHT")
	self.desc:SetWidth(max(1, width - 30))
	self:SetHeight(self.description and 28 + self.desc:GetStringHeight() or 24)
end
function Toggle:Render()
	local disabled = self.disabled
	self.check:SetDesaturated(disabled or (self.tristate and self.checked == nil) or false)
	if self.checked or (self.tristate and self.checked == nil) then
		self.check:Show()
	else
		self.check:Hide()
	end
	local color = disabled and 0.5 or 1
	self.text:SetTextColor(color, color, color)
	self.desc:SetTextColor(color, color, color)
	if disabled then self.frame:Disable() else self.frame:Enable() end
end
function Toggle:SetValue(value) self.checked = value; self:Render() end
function Toggle:SetDisabled(disabled) self.disabled = not not disabled; self:Render() end
function Toggle:SetTriState(enabled) self.tristate = not not enabled; self:Render() end
function Toggle:SetType(kind)
	if kind == "radio" then
		self.checkbg:SetTexture(130843)
		self.checkbg:SetTexCoord(0, 0.25, 0, 1)
		self.check:SetTexture(130843)
		self.check:SetTexCoord(0.25, 0.5, 0, 1)
		self.check:SetBlendMode("ADD")
		self.highlight:SetTexture(130843)
		self.highlight:SetTexCoord(0.5, 0.75, 0, 1)
		self.checkbg:SetSize(16, 16)
	else
		self.checkbg:SetTexture(130755)
		self.checkbg:SetTexCoord(0, 1, 0, 1)
		self.check:SetTexture(130751)
		self.check:SetTexCoord(0, 1, 0, 1)
		self.check:SetBlendMode("BLEND")
		self.highlight:SetTexture(130753)
		self.highlight:SetTexCoord(0, 1, 0, 1)
		self.checkbg:SetSize(24, 24)
	end
end
function Toggle:SetImage(path, ...)
	self.image:SetTexture(path)
	local count = select("#", ...)
	if count == 4 or count == 8 then self.image:SetTexCoord(...)
	else self.image:SetTexCoord(0, 1, 0, 1) end
	self:OnWidthSet(self.frame:GetWidth())
end
function Toggle:SetDescription(description)
	self.description = description
	self.desc:SetText(description or "")
	if description then self.desc:Show() else self.desc:Hide() end
	self:OnWidthSet(self.frame:GetWidth())
end
function Toggle:ToggleChecked()
	local value = self.checked
	if self.tristate then
		if value then value = nil elseif value == nil then value = false else value = true end
	else
		value = not value
	end
	self:SetValue(value)
end
function Toggle:OnAcquire()
	self.pressed, self.tristate, self.disabled = false, false, false
	self:SetType()
	self:SetValue(false)
	self:SetLabel("")
	self:SetWidth(200)
	self:SetImage()
	self:SetDescription()
end

function Controls.CreateToggle(parent)
	local frame = CreateFrame("Button", nil, parent)
	frame:Hide()
	frame:EnableMouse(true)
	local self = setmetatable({
		frame = frame, events = {}, checked = false, tristate = false, disabled = false,
		checkbg = frame:CreateTexture(nil, "ARTWORK"),
		check = frame:CreateTexture(nil, "OVERLAY"),
		highlight = frame:CreateTexture(nil, "HIGHLIGHT"),
		image = frame:CreateTexture(nil, "OVERLAY"),
		text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight"),
		desc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"),
	}, Toggle)
	self.checkbg:SetPoint("TOPLEFT")
	self.check:SetAllPoints(self.checkbg)
	self.highlight:SetAllPoints(self.checkbg)
	self.highlight:SetBlendMode("ADD")
	self.image:SetSize(16, 16)
	self.image:SetPoint("LEFT", self.checkbg, "RIGHT", 1, 0)
	self.text:SetJustifyH("LEFT")
	self.text:SetHeight(18)
	self.desc:SetJustifyH("LEFT")
	self.desc:SetJustifyV("TOP")
	self.desc:SetPoint("TOPLEFT", self.checkbg, "TOPRIGHT", 5, -21)
	frame:SetScript("OnEnter", function() self:Fire("OnEnter") end)
	frame:SetScript("OnLeave", function() self:Fire("OnLeave") end)
	frame:SetScript("OnMouseDown", function()
		if self.onFocus then self:onFocus() end
		if not self.disabled then
			self.pressed = true
			self:OnWidthSet(frame:GetWidth())
		end
	end)
	frame:SetScript("OnMouseUp", function()
		self.pressed = false
		self:OnWidthSet(frame:GetWidth())
		if self.disabled then return end
		self:ToggleChecked()
		if PlaySound then PlaySound(self.checked and 856 or 857) end
		self:Fire("OnValueChanged", self.checked)
	end)
	self:OnAcquire()
	return self
end

local Collection = {}
Collection.__index = Collection
function Collection:Fire(event, ...) return fire(self, event, ...) end
function Collection:SetHeight(height)
	self.frame:SetHeight(height)
	self.frame.height = height
end
function Collection:OnWidthSet(width)
	local columns = max(1, floor(width / 200))
	local row_width = width / columns
	for index, row in ipairs(self.rows) do
		if index <= #self.keys then
			row.frame:ClearAllPoints()
			row.frame:SetPoint("TOPLEFT", self.frame, "TOPLEFT",
				((index - 1) % columns) * row_width, -24 - floor((index - 1) / columns) * 24)
			row:SetWidth(row_width)
		end
	end
	self:SetHeight(24 + math.ceil(#self.keys / columns) * 24)
end
function Collection:SetWidth(width)
	self.frame:SetWidth(width)
	self.frame.width = width
	self:OnWidthSet(width)
end
function Collection:SetLabel(label) self.label:SetText(label or "") end
function Collection:SetMultiselect(enabled) self.multiselect = enabled end
function Collection:SetDisabled(disabled)
	self.disabled = not not disabled
	for _, row in ipairs(self.rows) do row:SetDisabled(disabled) end
end
function Collection:SetItemValue(key, value)
	for index, row in ipairs(self.rows) do
		if index <= #self.keys and row.key == key then row:SetValue(value); return end
	end
end
function Collection:SetValue(value)
	self.selected = value
	for index, row in ipairs(self.rows) do
		if index <= #self.keys then row:SetValue(row.key == value) end
	end
end
function Collection:SetList(values, sorting)
	for index = #self.keys, 1, -1 do self.keys[index] = nil end
	if sorting then
		for _, key in ipairs(sorting) do
			if values[key] ~= nil then self.keys[#self.keys + 1] = key end
		end
	else
		for key in pairs(values or {}) do self.keys[#self.keys + 1] = key end
		table.sort(self.keys, function(a, b)
			if type(a) == "number" and type(b) == "number" then return a < b end
			return tostring(a) < tostring(b)
		end)
	end
	for index, key in ipairs(self.keys) do
		local row = self.rows[index]
		if not row then
			row = Controls.CreateToggle(self.frame)
			self.rows[index] = row
			row.onFocus = function() if self.onFocus then self:onFocus() end end
			row:SetCallback("OnValueChanged", function(_, _, value)
				if self.multiselect then
					self:Fire("OnValueChanged", row.key, value)
				else
					self:SetValue(row.key)
					self:Fire("OnValueChanged", row.key)
				end
			end)
			row:SetCallback("OnEnter", function()
				if self.userdata then self.userdata.text = row.text:GetText() end
				self:Fire("OnEnter")
			end)
			row:SetCallback("OnLeave", function() self:Fire("OnLeave") end)
		end
		row.key = key
		row:SetType(self.radio and "radio" or nil)
		row:SetTriState(self.tristate)
		row:SetValue(false)
		row:SetLabel(values[key])
		row:SetDisabled(self.disabled)
		row.frame:Show()
	end
	for index = #self.keys + 1, #self.rows do self.rows[index].frame:Hide() end
	self:OnWidthSet(self.frame:GetWidth())
end
function Collection:OnAcquire()
	self.selected, self.disabled = nil, false
	self.multiselect = not self.radio
	self:SetLabel("")
	self:SetList({})
	self:SetWidth(200)
end

local function create_collection(parent, tristate, radio)
	local frame = CreateFrame("Frame", nil, parent)
	frame:Hide()
	local self = setmetatable({
		frame = frame, events = {}, rows = {}, keys = {},
		tristate = tristate, radio = radio,
		label = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal"),
	}, Collection)
	self.label:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
	self.label:SetPoint("RIGHT", frame, "RIGHT")
	self.label:SetJustifyH("LEFT")
	self:OnAcquire()
	return self
end

function Controls.RegisterWidgets()
	local gui = LibStub("AceGUI-3.0")
	local function register(name, factory)
		if (gui:GetWidgetVersion(name) or 0) >= 1 then return end
		gui:RegisterWidgetType(name, function()
			local widget = factory(UIParent)
			widget.type = name
			widget.onFocus = function() gui:ClearFocus() end
			-- Copy application methods before AceGUI adds its instance base.
			for method, callback in pairs(getmetatable(widget).__index) do
				widget[method] = callback
			end
			return gui:RegisterAsWidget(widget)
		end, 1)
	end
	register("PitBull4Toggle", Controls.CreateToggle)
	register("PitBull4MultiSelect", function(parent) return create_collection(parent, false, false) end)
	register("PitBull4TriStateMultiSelect", function(parent) return create_collection(parent, true, false) end)
	register("PitBull4RadioSelect", function(parent) return create_collection(parent, false, true) end)
end

function Controls.PrepareOptions(options)
	Controls.RegisterWidgets()
	local visited = {}
	local function visit(option)
		if type(option) ~= "table" or visited[option] then return end
		visited[option] = true
		local custom = option.dialogControl or option.control
		if option.type == "toggle" and (not custom or custom == "CheckBox") then
			option.dialogControl = "PitBull4Toggle"
		elseif option.type == "multiselect" and not custom then
			option.dialogControl = option.tristate and "PitBull4TriStateMultiSelect" or "PitBull4MultiSelect"
			option.width = "full"
		elseif option.type == "select" and option.style == "radio" and not custom then
			option.style = nil
			option.dialogControl = "PitBull4RadioSelect"
			option.width = "full"
		end
		for _, child in pairs(option.args or {}) do visit(child) end
		for _, plugin in pairs(option.plugins or {}) do
			if type(plugin) == "table" then
				for _, child in pairs(plugin) do visit(child) end
			end
		end
	end
	visit(options)
	return options
end
