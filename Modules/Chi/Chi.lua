if UnitClassBase("player") ~= "MONK" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local GetSpecialization = C_SpecializationInfo.GetSpecialization or _G.GetSpecialization -- XXX wow_compat

-- CONSTANTS ----------------------------------------------------------------

local SPELL_POWER_CHI = Enum.PowerType.Chi -- 12
local SPEC_MONK_WINDWALKER = 3

local MAX_POWER = 6

local STANDARD_SIZE = 15
local BORDER_SIZE = 3
local SPACING = -1

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local PitBull4_Chi = PitBull4:NewModule("Chi")

PitBull4_Chi:SetModuleType("indicator")
PitBull4_Chi:SetName(L["Chi"])
PitBull4_Chi:SetDescription(L["Show Monk chi icons."])
PitBull4_Chi:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	click_through = false,
	size = 1.5,
	active_color = { 1, 1, 1, 1 },
	inactive_color = { 0.5, 0.5, 0.5, 0.5 },
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_Chi:OnEnable()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "PLAYER_ENTERING_WORLD")
end

local function update_player(self)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_Chi:UNIT_POWER_FREQUENT(event, unit, power_type)
	if unit ~= "player" or power_type ~= "CHI" then
		return
	end

	update_player(self)
end

function PitBull4_Chi:UNIT_DISPLAYPOWER(event, unit)
	if unit ~= "player" then
		return
	end

	update_player(self)
end

function PitBull4_Chi:PLAYER_ENTERING_WORLD(event)
	update_player(self)
end

function PitBull4_Chi:ClearFrame(frame)
	local container = frame.Chi
	if not container then
		return false
	end

	for i = 1, MAX_POWER do
		container[i] = container[i]:Delete()
	end
	container.max_chi = nil
	container.bg = container.bg:Delete()
	frame.Chi = container:Delete()

	return true
end

local function update_container_size(container, vertical, max_chi)
	local width = STANDARD_SIZE * max_chi + BORDER_SIZE * 2 + SPACING * (max_chi - 1)
	if not vertical then
		container:SetWidth(width)
		container:SetHeight(CONTAINER_HEIGHT)
		container.height = 1
	else
		container:SetWidth(CONTAINER_HEIGHT)
		container:SetHeight(width)
		container.height = width / CONTAINER_HEIGHT
	end
	container.max_chi = max_chi
end

function PitBull4_Chi:UpdateFrame(frame)
	if frame.unit ~= "player" or GetSpecialization() ~= SPEC_MONK_WINDWALKER then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local vertical = db.vertical

	local container = frame.Chi
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.Chi = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)

		for i = 1, MAX_POWER do
			local chi_icon = PitBull4.Controls.MakeChiIcon(container, i)
			container[i] = chi_icon
			chi_icon:SetSize(STANDARD_SIZE, STANDARD_SIZE)
			chi_icon:ClearAllPoints()
			chi_icon:UpdateColors(db.active_color, db.inactive_color)
			chi_icon:UpdateTexture()
			chi_icon:EnableMouse(not db.click_through)
			if not vertical then
				chi_icon:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				chi_icon:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end

		update_container_size(container, vertical, 4)

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetColorTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	local num_chi = UnitPower("player", SPELL_POWER_CHI)
	local max_chi = UnitPowerMax("player", SPELL_POWER_CHI)
	if max_chi ~= container.max_chi then
		update_container_size(container, vertical, max_chi)
	end
	for i = 1, MAX_POWER do
		local chi_icon = container[i]
		if i > max_chi then
			chi_icon:Hide()
		elseif i <= num_chi then
			chi_icon:Show()
			chi_icon:Activate()
		else
			chi_icon:Show()
			chi_icon:Deactivate()
		end
	end

	container:Show()

	return true
end

PitBull4_Chi:SetLayoutOptionsFunction(function(self)
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
		order = 102,
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
		order = 103,
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
