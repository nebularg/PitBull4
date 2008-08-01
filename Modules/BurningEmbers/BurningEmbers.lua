if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_BurningEmbers requires PitBull4")
end

if select(2, UnitClass("player")) ~= "WARLOCK" then
	return
end

local mop_520 = select(4,GetBuildInfo()) >= 50200

-- CONSTANTS ----------------------------------------------------------------

local STANDARD_SIZE = 15
local BORDER_SIZE = 3
local SPACING = 3

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local L = PitBull4.L

local PitBull4_BurningEmbers = PitBull4:NewModule("BurningEmbers", "AceEvent-3.0")

PitBull4_BurningEmbers:SetModuleType("indicator")
PitBull4_BurningEmbers:SetName(L["Burning embers"])
PitBull4_BurningEmbers:SetDescription(L["Show destruction warlock burning embers."])
PitBull4_BurningEmbers:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	size = 1.5,
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_BurningEmbers:OnEnable()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TALENT_UPDATE","PLAYER_ENTERING_WORLD")
	self:RegisterEvent("SPELLS_CHANGED","PLAYER_ENTERING_WORLD")
end

local function update_player(self)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_BurningEmbers:UNIT_POWER_FREQUENT(event, unit, kind)
	if unit ~= "player" or kind ~= "BURNING_EMBERS" then
		return
	end
	
	update_player(self)
end

function PitBull4_BurningEmbers:UNIT_DISPLAYPOWER(event, unit)
	if unit ~= "player" then
		return
	end
	
	update_player(self)
end

function PitBull4_BurningEmbers:PLAYER_ENTERING_WORLD(event)
	update_player(self)
end

function PitBull4_BurningEmbers:ClearFrame(frame)
	local container = frame.BurningEmbers
	if not container then
		return false
	end
	
	for i = 1, 4 do
		container[i] = container[i]:Delete()
	end
	container.bg = container.bg:Delete()
	frame.BurningEmbers = container:Delete()
	
	return true
end

local function update_container_size(container, vertical, max_embers)
	local width = STANDARD_SIZE * max_embers + BORDER_SIZE * 2 + SPACING * (max_embers - 1)
	if not vertical then
		container:SetWidth(width)
		container:SetHeight(CONTAINER_HEIGHT)
		container.height = 1
	else
		container:SetWidth(CONTAINER_HEIGHT)
		container:SetHeight(width)
		container.height = width / CONTAINER_HEIGHT
	end
	container.max_embers = max_embers
end

function PitBull4_BurningEmbers:UpdateFrame(frame)
	if frame.unit ~= "player" or not IsPlayerSpell(WARLOCK_BURNING_EMBERS) then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local vertical = db.vertical
	
	local container = frame.BurningEmbers
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.BurningEmbers = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)
		
		local point, attach
		for i = 1, 4  do
			local ember = PitBull4.Controls.MakeBurningEmber(container, i)
			container[i] = ember
			ember:UpdateTexture()
			ember:ClearAllPoints()
			if not vertical then
				ember:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				ember:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end

		update_container_size(container, vertical, 4)

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end
	
	local ember_power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
	local max_ember_power = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS, true)
	local max_embers = floor(max_ember_power / MAX_POWER_PER_EMBER)
	if max_embers ~= container.max_embers then
		update_container_size(container, vertical, max_embers)
	end

	local green_fire = mop_520 and IsSpellKnown(WARLOCK_GREEN_FIRE)
	for i = 1, 4  do
		local ember = container[i]
		if i > max_embers then
			ember:Hide()
		else
			ember:Show()
			ember:SetValue(ember_power)
			ember:SetGreenFire(green_fire)
			ember_power = ember_power - MAX_POWER_PER_EMBER
		end
	end
	
	container:Show()

	return true
end

PitBull4_BurningEmbers:SetLayoutOptionsFunction(function(self)
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
