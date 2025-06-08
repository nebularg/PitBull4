if UnitClassBase("player") ~= "MAGE" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- CONSTANTS ----------------------------------------------------------------

local SPELL_POWER_ARCANE_CHARGES = _G.Enum.PowerType.ArcaneCharges -- 16
local SPEC_MAGE_ARCANE = _G.SPEC_MAGE_ARCANE

local NUM_CHARGES = 4

local STANDARD_SIZE = 39
local BORDER_SIZE = 3
local SPACING = -1

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_WIDTH = STANDARD_SIZE * NUM_CHARGES + BORDER_SIZE * 2 + SPACING * (NUM_CHARGES - 1)
local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local PitBull4_ArcaneCharges = PitBull4:NewModule("ArcaneCharges")

PitBull4_ArcaneCharges:SetModuleType("indicator")
PitBull4_ArcaneCharges:SetName(L["Arcane charges"])
PitBull4_ArcaneCharges:SetDescription(L["Show Mage Arcane charges."])
PitBull4_ArcaneCharges:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	click_through = false,
	size = 2,
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_ArcaneCharges:OnEnable()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "PLAYER_ENTERING_WORLD")
end

function PitBull4_ArcaneCharges:UNIT_POWER_FREQUENT(event, unit, power_type)
	if unit == "player" and power_type == "ARCANE_CHARGES" then
		self:UpdateForUnitID("player")
	end
end

function PitBull4_ArcaneCharges:UNIT_DISPLAYPOWER(event, unit)
	if unit == "player" then
		self:UpdateForUnitID("player")
	end
end

function PitBull4_ArcaneCharges:PLAYER_ENTERING_WORLD(event)
	self:UpdateForUnitID("player")
end

function PitBull4_ArcaneCharges:ClearFrame(frame)
	local container = frame.ArcaneCharges
	if not container then
		return false
	end

	for i = 1, NUM_CHARGES do
		container[i] = container[i]:Delete()
	end
	container.bg = container.bg:Delete()
	frame.ArcaneCharges = container:Delete()

	return true
end

function PitBull4_ArcaneCharges:UpdateFrame(frame)
	if frame.unit ~= "player" or C_SpecializationInfo.GetSpecialization() ~= SPEC_MAGE_ARCANE then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local vertical = db.vertical

	local container = frame.ArcaneCharges
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.ArcaneCharges = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)

		for i = 1, NUM_CHARGES do
			local charge = PitBull4.Controls.MakeArcaneCharge(container, i)
			container[i] = charge
			charge:SetSize(STANDARD_SIZE, STANDARD_SIZE)
			charge:ClearAllPoints()
			charge:EnableMouse(not db.click_through)
			if not vertical then
				charge:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				charge:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
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
		bg:SetColorTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	local power = UnitPower("player", SPELL_POWER_ARCANE_CHARGES, true)
	for i = 1, NUM_CHARGES do
		local charge = container[i]
		charge:SetActive(i <= power)
	end

	container:Show()

	return true
end

PitBull4_ArcaneCharges:SetLayoutOptionsFunction(function(self)
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
		order = 103,
	}
end)
