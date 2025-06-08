if UnitClassBase("player") ~= "WARLOCK" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- CONSTANTS ----------------------------------------------------------------

local SPELL_POWER_SOUL_SHARDS = 7 -- Enum.PowerType.SoulShards

local MAX_SHARDS = 5

local STANDARD_WIDTH = 17
local STANDARD_HEIGHT = 22
local BORDER_SIZE = 3
local SPACING = 6

local HALF_STANDARD_WIDTH = STANDARD_WIDTH / 2
local HALF_STANDARD_HEIGHT = STANDARD_HEIGHT / 2

local CONTAINER_WIDTH = STANDARD_WIDTH + BORDER_SIZE * 2
local CONTAINER_HEIGHT = STANDARD_HEIGHT + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local PitBull4_SoulShards = PitBull4:NewModule("SoulShards")

PitBull4_SoulShards:SetModuleType("indicator")
PitBull4_SoulShards:SetName(L["Soul shards"])
PitBull4_SoulShards:SetDescription(L["Show Warlock Soul shards."])
PitBull4_SoulShards:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	click_through = false,
	size = 1.5,
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_SoulShards:OnEnable()
	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", nil, "player")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UNIT_DISPLAYPOWER")
end

function PitBull4_SoulShards:UNIT_POWER_FREQUENT(_, unit, power_type)
	if power_type ~= "SOUL_SHARDS" then return end
	self:UpdateForUnitID("player")
end

function PitBull4_SoulShards:UNIT_DISPLAYPOWER()
	self:UpdateForUnitID("player")
end

function PitBull4_SoulShards:ClearFrame(frame)
	local container = frame.SoulShards
	if not container then
		return false
	end

	for i = 1, MAX_SHARDS do
		container[i] = container[i]:Delete()
		container.Shards[i] = nil
	end
	container.Shards = nil
	container.max_shards = nil
	container.bg = container.bg:Delete()
	frame.SoulShards = container:Delete()

	return true
end

local function update_container_size(container, vertical, max_shards)
	if not vertical then
		local width = STANDARD_WIDTH * max_shards + BORDER_SIZE * 2 + SPACING * (max_shards - 1)
		container:SetWidth(width)
		container:SetHeight(CONTAINER_HEIGHT)
		container.height = 1
	else
		local height = STANDARD_HEIGHT * max_shards + BORDER_SIZE * 2 + SPACING * (max_shards - 1)
		container:SetWidth(CONTAINER_WIDTH)
		container:SetHeight(height)
		container.height = height / CONTAINER_HEIGHT
	end
	container.max_shards = max_shards
end

function PitBull4_SoulShards:UpdateFrame(frame)
	if frame.unit ~= "player" then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local vertical = db.vertical

	local container = frame.SoulShards
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.SoulShards = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)
		container.Shards = {}

		for i = 1, MAX_SHARDS do
			local soul_shard = PitBull4.Controls.MakeSoulShard(container, i)
			container[i] = soul_shard
			soul_shard:SetSize(STANDARD_WIDTH, STANDARD_HEIGHT)
			soul_shard:ClearAllPoints()
			soul_shard:EnableMouse(not db.click_through)
			if not vertical then
				soul_shard:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_WIDTH) + HALF_STANDARD_WIDTH, 0)
			else
				soul_shard:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_HEIGHT) + HALF_STANDARD_HEIGHT)
			end
		end

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetColorTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	local max_shards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
	if max_shards ~= container.max_shards then
		update_container_size(container, vertical, max_shards)
	end

	local modifier = UnitPowerDisplayMod(SPELL_POWER_SOUL_SHARDS)
	local num_soul_shards = (modifier ~= 0) and (UnitPower("player", SPELL_POWER_SOUL_SHARDS, true) / modifier) or 0
	if C_SpecializationInfo.GetSpecialization() ~= 3 then
		-- Destruction is supposed to show partial soulshards, but Affliction and Demonology should only show full ones
		num_soul_shards = math.floor(num_soul_shards)
	end
	for i = 1, MAX_SHARDS do
		local soul_shard = container[i]
		if i > max_shards then
			soul_shard:Hide()
		else
			soul_shard:Show()
			soul_shard:Update(num_soul_shards)
		end
	end

	container:Show()

	return true
end

PitBull4_SoulShards:SetLayoutOptionsFunction(function(self)
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
