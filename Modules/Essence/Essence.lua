if UnitClassBase("player") ~= "EVOKER" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- CONSTANTS ----------------------------------------------------------------

local SPELL_POWER_ESSENCE = 19 -- Enum.PowerType.Essence

local STANDARD_SIZE = 15
local BORDER_SIZE = 4
local SPACING = 8

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local PitBull4_Essence = PitBull4:NewModule("Essence")

PitBull4_Essence:SetModuleType("indicator")
PitBull4_Essence:SetName(L["Essence"])
PitBull4_Essence:SetDescription(L["Show Evoker Essence charges."])
PitBull4_Essence:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	click_through = false,
	size = 1.5,
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_Essence:OnEnable()
	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "player")
	self:RegisterUnitEvent("UNIT_MAXPOWER", "UNIT_POWER_FREQUENT", "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", nil, "player")
	self:RegisterUnitEvent("UNIT_POWER_POINT_CHARGE", "UNIT_DISPLAYPOWER", "player")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function PitBull4_Essence:UNIT_POWER_FREQUENT(_, unit, power_type)
	if power_type == "ESSENCE" then
		self:UpdateForUnitID(unit)
	end
end

function PitBull4_Essence:UNIT_DISPLAYPOWER(_, unit)
	self:UpdateForUnitID(unit)
end

function PitBull4_Essence:PLAYER_ENTERING_WORLD()
	self:UpdateForUnitID("player")
end

function PitBull4_Essence:ClearFrame(frame)
	local container = frame.Essence
	if not container then
		return false
	end

	for i = 1, container.max_power do
		container[i] = container[i]:Delete()
	end
	container.max_power = nil
	container.bg = container.bg:Delete()
	frame.Essence = container:Delete()

	return true
end

local function update_container_size(container, vertical, max_power)
	local width = STANDARD_SIZE * max_power + BORDER_SIZE * 2 + SPACING * (max_power - 1)
	if not vertical then
		container:SetWidth(width)
		container:SetHeight(CONTAINER_HEIGHT)
		container.height = 1
	else
		container:SetWidth(CONTAINER_HEIGHT)
		container:SetHeight(width)
		container.height = width / CONTAINER_HEIGHT
	end
	container.max_power = max_power
end

function PitBull4_Essence:UpdateFrame(frame)
	if frame.unit ~= "player" then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local vertical = db.vertical

	local num_power = UnitPower("player", SPELL_POWER_ESSENCE)
	local max_power = UnitPowerMax("player", SPELL_POWER_ESSENCE)

	if frame.Essence and frame.Essence.max_power ~= max_power then
		self:ClearFrame(frame)
	end

	local container = frame.Essence
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.Essence = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)

		for i = 1, max_power do
			local icon = PitBull4.Controls.MakeEssenceIcon(container, i)
			container[i] = icon
			icon:SetSize(STANDARD_SIZE, STANDARD_SIZE)
			icon:ClearAllPoints()
			icon:EnableMouse(not db.click_through)
			if not vertical then
				icon:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				icon:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end

		update_container_size(container, vertical, max_power)

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetColorTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	for i = 1, min(num_power, max_power) do
		container[i]:SetEssennceFull()
	end
	for i = num_power + 1, max_power do
		container[i]:AnimOut()
	end

	local next_power_icon = container[num_power + 1]
	if num_power ~= max_power and next_power_icon and not next_power_icon.EssenceFull:IsShown() then
		local peace = GetPowerRegenForPowerType(SPELL_POWER_ESSENCE) or 0.2
		if peace == 0 then
			peace = 0.2
		end
		local duration = 1 / peace
		local multipler = 5 / duration
		next_power_icon:AnimIn(multipler)
	end

	container:Show()

	return true
end

PitBull4_Essence:SetLayoutOptionsFunction(function(self)
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
	'click_through', {
		type = 'toggle',
		name = L["Click-through"],
		desc = L["Disable capturing clicks on icons, allowing the click to fall through to the window underneath the icon."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).click_through
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).click_through = value

			for frame in PitBull4:IterateFramesForUnitID("player") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		order = 101,
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
		order = 104,
	}
end)
