if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HolyPower requires PitBull4")
end

if select(2, UnitClass("player")) ~= "PALADIN" or not PowerBarColor["HOLY_POWER"] then
	return
end

-- CONSTANTS ----------------------------------------------------------------

local HOLY_POWER_FULL = HOLY_POWER_FULL
assert(HOLY_POWER_FULL)
local SPELL_POWER_HOLY_POWER = assert(_G.SPELL_POWER_HOLY_POWER)

local STANDARD_SIZE = 15
local BORDER_SIZE = 3
local SPACING = 3

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_WIDTH = STANDARD_SIZE * HOLY_POWER_FULL + BORDER_SIZE * 2 + SPACING * (HOLY_POWER_FULL - 1)
local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local L = PitBull4.L

local PitBull4_HolyPower = PitBull4:NewModule("HolyPower", "AceEvent-3.0")

PitBull4_HolyPower:SetModuleType("indicator")
PitBull4_HolyPower:SetName(L["Holy power"])
PitBull4_HolyPower:SetDescription(L["Show Paladin Holy power icons."])
PitBull4_HolyPower:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	size = 1.5,
	active_color = { 0.95, 0.9, 0.6, 1 },
	inactive_color = { 0.5, 0.5, 0.5, 0.5 },
	background_color = { 0, 0, 0, 0.5 }
})

local player_level

function PitBull4_HolyPower:OnEnable()
	player_level = UnitLevel("player")
	self:RegisterEvent("UNIT_POWER")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	if player_level < PALADINPOWERBAR_SHOW_LEVEL then
		self:RegisterEvent("PLAYER_LEVEL_UP")
	end
end

local function update_player(self)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_HolyPower:UNIT_POWER(event, unit, kind)
	if unit ~= "player" or kind ~= "HOLY_POWER" then
		return
	end
	
	update_player(self)
end

function PitBull4_HolyPower:UNIT_DISPLAYPOWER(event, unit)
	if unit ~= "player" then
		return
	end
	
	update_player(self)
end

function PitBull4_HolyPower:PLAYER_ENTERING_WORLD(event)
	update_player(self)
end

function PitBull4_HolyPower:PLAYER_LEVEL_UP(event, level)
	player_level = level
	if player_level >= PALADINPOWERBAR_SHOW_LEVEL then
		self:UnregisterEvent("PLAYER_LEVEL_UP")
		update_player(self)
	end
end

function PitBull4_HolyPower:ClearFrame(frame)
	local container = frame.HolyPower
	if not container then
		return false
	end
	
	for i = 1, 5 do
		container[i] = container[i]:Delete()
	end
	container.bg = container.bg:Delete()
	frame.HolyPower = container:Delete()
	
	return true
end

local function update_container_size(container, vertical, max_holy_power)
	local width = STANDARD_SIZE * max_holy_power + BORDER_SIZE * 2 + SPACING * (max_holy_power - 1)
	if not vertical then
		container:SetWidth(width)
		container:SetHeight(CONTAINER_HEIGHT)
		container.height = 1
	else
		container:SetWidth(CONTAINER_HEIGHT)
		container:SetHeight(width)
		container.height = width / CONTAINER_HEIGHT
	end
	container.max_holy_power = max_holy_power
end

function PitBull4_HolyPower:UpdateFrame(frame)
	if frame.unit ~= "player" or player_level < PALADINPOWERBAR_SHOW_LEVEL then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local vertical = db.vertical
	
	local container = frame.HolyPower
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.HolyPower = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)
		
		local point, attach
		for i = 1, 5 do
			local holy_icon = PitBull4.Controls.MakeHolyIcon(container, i)
			container[i] = holy_icon
			holy_icon:ClearAllPoints()
			holy_icon:UpdateColors(db.active_color, db.inactive_color)
			holy_icon:UpdateTexture()
			if not vertical then
				holy_icon:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				holy_icon:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end
		
		update_container_size(container, vertical, 3)

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end
	
	local num_holy_power = UnitPower("player", SPELL_POWER_HOLY_POWER)
	local max_holy_power = UnitPowerMax("player", SPELL_POWER_HOLY_POWER)
	if max_holy_power ~= container.max_holy_power then
		update_container_size(container, vertical, max_holy_power)
	end
	for i = 1, 5 do
		local holy_icon = container[i]
		holy_icon:UpdateColors(db.active_color, db.inactive_color)
		if i > max_holy_power then
			holy_icon:Hide()
		elseif i <= num_holy_power then
			holy_icon:Show()
			holy_icon:Activate()
		else
			holy_icon:Show()
			holy_icon:Deactivate()
		end
	end
	
	container:Show()

	return true
end

PitBull4_HolyPower:SetLayoutOptionsFunction(function(self)
	return 'vertical', {
		type = 'toggle',
		name = L["Vertical"],
		desc = L["Show the icons stacked vertically instead of horizontally."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).vertical
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).vertical = value
			
			for frame in PitBull4:IterateFramesForUnitID("player") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		order = 100,
	},
	'active_color', {
		type = 'color',
		hasAlpha = true,
		name = L["Active color"],
		desc = L["The color of the active icons."],
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).active_color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).active_color
			color[1], color[2], color[3], color[4] = r, g, b, a
			
			for frame in PitBull4:IterateFramesForUnitID("player") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		order = 101,
	},
	'inactive_color', {
		type = 'color',
		hasAlpha = true,
		name = L["Inactive color"],
		desc = L["The color of the inactive icons."],
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).inactive_color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).inactive_color
			color[1], color[2], color[3], color[4] = r, g, b, a
			
			for frame in PitBull4:IterateFramesForUnitID("player") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		order = 102,
	},
	'background_color', {
		type = 'color',
		hasAlpha = true,
		name = L["Background color"],
		desc = L["The background color behind the icons."],
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).background_color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).background_color
			color[1], color[2], color[3], color[4] = r, g, b, a
			
			for frame in PitBull4:IterateFramesForUnitID("player") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		order = 103,
	}
end)
