if UnitClassBase("player") ~= "WARLOCK" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- CONSTANTS ----------------------------------------------------------------

local SPELL_POWER_SOUL_SHARDS = Enum.PowerType.SoulShards
local SHARDBAR_SHOW_LEVEL = 10

local MAX_SHARDS = 4

local STANDARD_SIZE = 15
local BORDER_SIZE = 3
local SPACING = 3

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

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

local player_level = UnitLevel("player")

function PitBull4_SoulShards:OnEnable()
	player_level = UnitLevel("player")
	self:RegisterUnitEvent("UNIT_POWER_FREQUENT", nil, "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", nil, "player")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_TALENT_UPDATE", "UNIT_DISPLAYPOWER")
	if player_level < SHARDBAR_SHOW_LEVEL then
		self:RegisterEvent("PLAYER_LEVEL_UP")
	end
end

function PitBull4_SoulShards:UNIT_POWER_FREQUENT(_, unit, power_type)
	if power_type ~= "SOUL_SHARDS" then return end
	self:UpdateForUnitID("player")
end

function PitBull4_SoulShards:UNIT_DISPLAYPOWER()
	self:UpdateForUnitID("player")
end

function PitBull4_SoulShards:PLAYER_LEVEL_UP(_, level)
	player_level = level
	if player_level >= SHARDBAR_SHOW_LEVEL then
		self:UnregisterEvent("PLAYER_LEVEL_UP")
		self:UpdateForUnitID("player")
	end
end

function PitBull4_SoulShards:ClearFrame(frame)
	local container = frame.SoulShards
	if not container then
		return false
	end

	for i = 1, MAX_SHARDS do
		container[i] = container[i]:Delete()
	end
	container.bg = container.bg:Delete()
	frame.SoulShards = container:Delete()

	return true
end

local function update_container_size(container, vertical, max_shards)
	local width = STANDARD_SIZE * max_shards + BORDER_SIZE * 2 + SPACING * (max_shards - 1)
	if not vertical then
		container:SetWidth(width)
		container:SetHeight(CONTAINER_HEIGHT)
		container.height = 1
	else
		container:SetWidth(CONTAINER_HEIGHT)
		container:SetHeight(width)
		container.height = width / CONTAINER_HEIGHT
	end
	container.max_shards = max_shards
end

function PitBull4_SoulShards:UpdateFrame(frame)
	if frame.unit ~= "player" or player_level < SHARDBAR_SHOW_LEVEL then
		return self:ClearFrame(frame)
	end

	local db = self:GetLayoutDB(frame)
	local vertical = db.vertical

	local container = frame.SoulShards
	if not container then
		container = PitBull4.Controls.MakeFrame(frame)
		frame.SoulShards = container
		container:SetFrameLevel(frame:GetFrameLevel() + 13)

		local point, attach
		for i = 1, MAX_SHARDS do
			local soul_shard = PitBull4.Controls.MakeSoulShard(container, i)
			container[i] = soul_shard
			soul_shard:UpdateTexture()
			soul_shard:ClearAllPoints()
			soul_shard:EnableMouse(not db.click_through)
			if not vertical then
				soul_shard:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				soul_shard:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end

		update_container_size(container, vertical, MAX_SHARDS)

		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	local max_shards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
	if max_shards ~= container.max_shards then
		update_container_size(container, vertical, max_shards)
	end

	local num_soul_shards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
	for i = 1, MAX_SHARDS do
		local soul_shard = container[i]
		if i > max_shards then
			soul_shard:Hide()
		elseif i <= num_soul_shards then
			soul_shard:Show()
			soul_shard:Activate()
		else
			soul_shard:Show()
			soul_shard:Deactivate()
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
