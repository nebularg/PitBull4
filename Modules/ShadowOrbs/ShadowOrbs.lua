if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ShadowOrbs requires PitBull4")
end

if select(2, UnitClass("player")) ~= "PRIEST" then
	return
end

-- CONSTANTS ----------------------------------------------------------------

local PRIEST_BAR_NUM_ORBS = assert(_G.PRIEST_BAR_NUM_ORBS)
local SPELL_POWER_SHADOW_ORBS = assert(_G.SPELL_POWER_SHADOW_ORBS)

local STANDARD_SIZE = 38
local BORDER_SIZE = 3
local SPACING = 3

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_WIDTH = STANDARD_SIZE * PRIEST_BAR_NUM_ORBS + BORDER_SIZE * 2 + SPACING * (PRIEST_BAR_NUM_ORBS - 1)
local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local L = PitBull4.L

local PitBull4_ShadowOrbs = PitBull4:NewModule("ShadowOrbs", "AceEvent-3.0")

PitBull4_ShadowOrbs:SetModuleType("indicator")
PitBull4_ShadowOrbs:SetName(L["Shadow orbs"])
PitBull4_ShadowOrbs:SetDescription(L["Show Priest shadow orbs."])
PitBull4_ShadowOrbs:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	size = 1.5,
	active_color = { 0.79, 0.19, 1, 1 },
	active_color = { 1, 1, 1, 1 },
	inactive_color = { 0.5, 0.5, 0.5, 0.5 },
	background_color = { 0, 0, 0, 0.5 }
})

local player_level
local player_spec

function PitBull4_ShadowOrbs:OnEnable()
	player_level = UnitLevel("player")
	player_spec = GetSpecialization()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	if player_level < SHADOW_ORBS_SHOW_LEVEL then
		self:RegisterEvent("PLAYER_LEVEL_UP")
	end
end

local function update_player(self)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_ShadowOrbs:UNIT_POWER_FREQUENT(event, unit, kind)
	if unit ~= "player" or kind ~= "SHADOW_ORBS" then
		return
	end
	
	update_player(self)
end

function PitBull4_ShadowOrbs:UNIT_DISPLAYPOWER(event, unit)
	if unit ~= "player" then
		return
	end
	
	update_player(self)
end

function PitBull4_ShadowOrbs:PLAYER_ENTERING_WORLD(event)
	update_player(self)
end

function PitBull4_ShadowOrbs:PLAYER_LEVEL_UP(event, level)
	player_level = level
	if player_level >= SHADOW_ORBS_SHOW_LEVEL then
		self:UnregisterEvent("PLAYER_LEVEL_UP")
		update_player(self)
	end
end

function PitBull4_ShadowOrbs:PLAYER_TALENT_UPDATE(event)
	player_spec = GetSpecialization()
	update_player(self)
end

function PitBull4_ShadowOrbs:ClearFrame(frame)
	local container = frame.ShadowOrbs
	if not container then
		return false
	end
	
	for i = 1, PRIEST_BAR_NUM_ORBS do
		container[i] = container[i]:Delete()
	end
	container.bg = container.bg:Delete()
	frame.ShadowOrbs = container:Delete()
	
	return true
end

function PitBull4_ShadowOrbs:UpdateFrame(frame)
	if frame.unit ~= "player" or player_spec ~= SPEC_PRIEST_SHADOW or player_level < SHADOW_ORBS_SHOW_LEVEL then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local container = frame.ShadowOrbs
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.ShadowOrbs = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)
		
		local vertical = db.vertical
		
		local point, attach
		for i = 1, PRIEST_BAR_NUM_ORBS do
			local orb_icon = PitBull4.Controls.MakeShadowOrb(container, i)
			container[i] = orb_icon
			orb_icon:ClearAllPoints()
			orb_icon:UpdateColors(db.active_color, db.inactive_color)
			orb_icon:UpdateTexture()
			if not vertical then
				orb_icon:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				orb_icon:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end

		if not vertical then
			container:SetWidth(CONTAINER_WIDTH)
			container:SetHeight(CONTAINER_HEIGHT)
			container.height = 1
		else
			container:SetWidth(CONTAINER_HEIGHT)
			container:SetHeight(CONTAINER_WIDTH)
			container.height = CONTAINER_WIDTH / CONTAINER_HEIGHT
		end

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	local num_orb = UnitPower("player", SPELL_POWER_SHADOW_ORBS)
	for i = 1, PRIEST_BAR_NUM_ORBS do
		local orb_icon = container[i]
		orb_icon:UpdateColors(db.active_color, db.inactive_color)
		if i <= num_orb then
			orb_icon:Activate()
		else
			orb_icon:Deactivate()
		end
	end
	
	container:Show()

	return true
end

PitBull4_ShadowOrbs:SetLayoutOptionsFunction(function(self)
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
