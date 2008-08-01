if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_SoulShards requires PitBull4")
end

if select(2, UnitClass("player")) ~= "WARLOCK" or not PowerBarColor["SOUL_SHARDS"] then
	return
end

-- CONSTANTS ----------------------------------------------------------------

local SHARDBAR_SHOW_LEVEL = SHARDBAR_SHOW_LEVEL
if not SHARDBAR_SHOW_LEVEL then
	SHARDBAR_SHOW_LEVEL = 0
end

local STANDARD_SIZE = 15
local BORDER_SIZE = 3
local SPACING = 3

local HALF_STANDARD_SIZE = STANDARD_SIZE / 2

local CONTAINER_HEIGHT = STANDARD_SIZE + BORDER_SIZE * 2

-----------------------------------------------------------------------------

local L = PitBull4.L

local PitBull4_SoulShards = PitBull4:NewModule("SoulShards", "AceEvent-3.0")

PitBull4_SoulShards:SetModuleType("indicator")
PitBull4_SoulShards:SetName(L["Soul shards"])
PitBull4_SoulShards:SetDescription(L["Show Warlock Soul shards."])
PitBull4_SoulShards:SetDefaults({
	attach_to = "root",
	location = "out_top",
	position = 1,
	vertical = false,
	size = 1.5,
	background_color = { 0, 0, 0, 0.5 }
})

local player_level

function PitBull4_SoulShards:OnEnable()
	player_level = UnitLevel("player")
	self:RegisterEvent("UNIT_POWER")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_TALENT_UPDATE","PLAYER_ENTERING_WORLD")
	if player_level < SHARDBAR_SHOW_LEVEL then
		self:RegisterEvent("PLAYER_LEVEL_UP")
	end
end

local function update_player(self)
	for frame in PitBull4:IterateFramesForUnitID("player") do
		self:Update(frame)
	end
end

function PitBull4_SoulShards:UNIT_POWER(event, unit, kind)
	if unit ~= "player" or kind ~= "SOUL_SHARDS" then
		return
	end
	
	update_player(self)
end

function PitBull4_SoulShards:UNIT_DISPLAYPOWER(event, unit)
	if unit ~= "player" then
		return
	end
	
	update_player(self)
end

function PitBull4_SoulShards:PLAYER_ENTERING_WORLD(event)
	update_player(self)
end

function PitBull4_SoulShards:PLAYER_LEVEL_UP(event, level)
	player_level = level
	if player_level >= SHARDBAR_SHOW_LEVEL then
		self:UnregisterEvent("PLAYER_LEVEL_UP")
		update_player(self)
	end
end

function PitBull4_SoulShards:ClearFrame(frame)
	local container = frame.SoulShards
	if not container then
		return false
	end
	
	for i = 1, 4 do
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
	if frame.unit ~= "player" or player_level < SHARDBAR_SHOW_LEVEL or (WARLOCK_SOULBURN and not IsPlayerSpell(WARLOCK_SOULBURN)) then
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
		for i = 1, 4 do
			local soul_shard = PitBull4.Controls.MakeSoulShard(container, i)
			container[i] = soul_shard
			soul_shard:UpdateTexture()
			soul_shard:ClearAllPoints()
			if not vertical then
				soul_shard:SetPoint("CENTER", container, "LEFT", BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE, 0)
			else
				soul_shard:SetPoint("CENTER", container, "BOTTOM", 0, BORDER_SIZE + (i - 1) * (SPACING + STANDARD_SIZE) + HALF_STANDARD_SIZE)
			end
		end
	
		update_container_size(container, vertical, 4)
		
		local bg = PitBull4.Controls.MakeTexture(container, "BACKGROUND")
		container.bg = bg
		bg:SetTexture(unpack(db.background_color))
		bg:SetAllPoints(container)
	end

	local num_soul_shards = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
	local max_shards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
	if max_shards ~= container.max_shards then
		update_container_size(container, vertical, max_shards)
	end
	for i = 1, 4 do
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
		desc = L["Show the soul shards stacked vertically instead of horizontally."],
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
		desc = L["The background color behind the soul shards."],
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
