if UnitClassBase("player") ~= "DEATHKNIGHT" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- CONSTANTS ----------------------------------------------------------------

local RUNE_IDS = { 1, 2, 5, 6, 3, 4 } -- for some ungodly reason, unholy and frost are switched.
local NUM_RUNES = #RUNE_IDS

local SPELL_POWER_RUNES = Enum.PowerType.Runes

local STANDARD_SIZE = 15
local BORDER_SIZE = 3
local SPACING = 3

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_WIDTH = STANDARD_SIZE * NUM_RUNES + BORDER_SIZE * 2 + SPACING * (NUM_RUNES - 1)
local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local PitBull4_Runes = PitBull4:NewModule("Runes")

PitBull4_Runes:SetModuleType("indicator")
PitBull4_Runes:SetName(L["Runes"])
PitBull4_Runes:SetDescription(L["Show Death Knight rune icons."])
PitBull4_Runes:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	click_through = false,
	size = 1.5,
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_Runes:OnEnable()
	self:RegisterEvent("RUNE_POWER_UPDATE")
	self:RegisterEvent("RUNE_TYPE_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function PitBull4_Runes:PLAYER_ENTERING_WORLD()
	self:UpdateForUnitID("player")
end

function PitBull4_Runes:RUNE_POWER_UPDATE(event, rune_id, usable)
	if rune_id > NUM_RUNES or rune_id < 1 then return end

	for frame in PitBull4:IterateFramesForUnitID("player") do
		if frame.Runes then
			local rune = frame.Runes[rune_id]
			if rune then
				rune:UpdateCooldown()
			end
		end
	end
end

function PitBull4_Runes:RUNE_TYPE_UPDATE(event, rune_id)
	if rune_id > NUM_RUNES or rune_id < 1 then return end

	for frame in PitBull4:IterateFramesForUnitID("player") do
		if frame.Runes then
			local rune = frame.Runes[rune_id]
			if rune then
				rune:UpdateTexture()
			end
		end
	end
end

function PitBull4_Runes:ClearFrame(frame)
	local container = frame.Runes
	if not container then
		return false
	end

	for i = 1, container.max_runes do
		container[i] = container[i]:Delete()
	end
	container.max_runes = nil
	container.bg = container.bg:Delete()
	frame.Runes = container:Delete()

	return true
end

function PitBull4_Runes:UpdateFrame(frame)
	if frame.unit ~= "player" then
		return self:ClearFrame(frame)
	end

	local num_runes = #RUNE_IDS
	local container = frame.Runes
	if container and container.max_runes ~= num_runes then
		self:ClearFrame(frame)
		container = nil
	end

	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.Runes = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)

		local db = self:GetLayoutDB(frame)
		local vertical = db.vertical

		for i = 1, num_runes do
			local id = RUNE_IDS[i]
			local rune = PitBull4.Controls.MakeRune(container, id)
			container[id] = rune
			rune:SetSize(STANDARD_SIZE, STANDARD_SIZE)
			rune:ClearAllPoints()
			rune:EnableMouse(not db.click_through)
			if not vertical then
				rune:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				rune:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end
		container.max_runes = num_runes

		local width = STANDARD_SIZE * num_runes + BORDER_SIZE * 2 + SPACING * (num_runes - 1)
		if not vertical then
			container:SetWidth(width)
			container:SetHeight(CONTAINER_HEIGHT)
			container.height = 1
		else
			container:SetWidth(CONTAINER_HEIGHT)
			container:SetHeight(width)
			container.height = width / CONTAINER_HEIGHT
		end

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetColorTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	for i = 1, num_runes do
		container[i]:UpdateTexture()
		container[i]:UpdateCooldown()
	end

	container:Show()

	return true
end

PitBull4_Runes:SetLayoutOptionsFunction(function(self)
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
