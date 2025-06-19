if UnitClassBase("player") ~= "DEATHKNIGHT" then
	return
end

local PitBull4 = _G.PitBull4

-- CONSTANTS ----------------------------------------------------------------

local RUNETYPE_BLOOD = 1
local RUNETYPE_FROST = 2
local RUNETYPE_UNHOLY = 3
local RUNETYPE_DEATH = 4

local RUNE_MAPPING = {
	[RUNETYPE_BLOOD] = "BLOOD",
	[RUNETYPE_FROST] = "FROST",
	[RUNETYPE_UNHOLY] = "UNHOLY",
	[RUNETYPE_DEATH] = "DEATH",
}

local ICON_TEXTURES = {
	[RUNETYPE_BLOOD] = [[Interface\AddOns\PitBull4\modules\Runes\Blood]],
	[RUNETYPE_UNHOLY] = [[Interface\AddOns\PitBull4\modules\Runes\Unholy]],
	[RUNETYPE_FROST] = [[Interface\AddOns\PitBull4\modules\Runes\Frost]],
	[RUNETYPE_DEATH] = [[Interface\AddOns\PitBull4\modules\Runes\Death]],
}

local RUNE_COLORS = {
	[RUNETYPE_BLOOD] = {1, 0, 0},
	[RUNETYPE_FROST] = {0, 1, 1},
	[RUNETYPE_UNHOLY] = {0, 0.5, 0},
	[RUNETYPE_DEATH] = {0.8, 0.1, 1},
}

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2

local SHINE_TEXTURE = [[Interface\AddOns\PitBull4\Modules\Runes\Shine]]

local UNREADY_ALPHA = 0.6
local READY_ALPHA = 1

-----------------------------------------------------------------------------

local Rune = {}
local Rune_scripts = {}

function Rune:UpdateTexture()
	if not self.id then return end
	local rune_type = GetRuneType(self.id)
	if self.rune_type == rune_type then
		return
	end

	local old_rune_type = self.rune_type
	self.rune_type = rune_type
	self:SetNormalTexture(ICON_TEXTURES[rune_type])
	if old_rune_type then
		self.shine.ag:Play()
	end
end

function Rune:UpdateCooldown()
	if not self.id then return end
	local start, duration, ready = GetRuneCooldown(self.id)

	self.shine.ag:Stop()
	self.shine:SetAlpha(0)
	if ready or not start then
		self.cooldown:Clear()
		self.shine.ag:Play()
		self:GetNormalTexture():SetAlpha(READY_ALPHA)
	else
		self.cooldown:SetCooldown(start, duration)
		self:GetNormalTexture():SetAlpha(UNREADY_ALPHA)
	end
end

function Rune_scripts:OnEnter()
	if self.rune_type then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(_G["COMBAT_TEXT_RUNE_" .. RUNE_MAPPING[self.rune_type]])
		GameTooltip:Show()
	end
end

function Rune_scripts:OnLeave()
	GameTooltip:Hide()
end

PitBull4.Controls.MakeNewControlType("Rune", "Button", function(control)
	-- onCreate

	for k, v in pairs(Rune) do
		control[k] = v
	end
	for k, v in pairs(Rune_scripts) do
		control:SetScript(k, v)
	end

	local shine = PitBull4.Controls.MakeAnimatedTexture(control, "OVERLAY")
	control.shine = shine
	shine:SetAllPoints(control)
	shine:SetTexture(SHINE_TEXTURE)
	shine:SetBlendMode("ADD")
	shine:SetAlpha(0)

	local fade_in = PitBull4.Controls.MakeAlpha(shine.ag)
	fade_in:SetDuration(SHINE_HALF_TIME)
	fade_in:SetFromAlpha(0)
	fade_in:SetToAlpha(1)
	fade_in:SetOrder(1)

	local fade_out = PitBull4.Controls.MakeAlpha(shine.ag)
	fade_out:SetDuration(SHINE_HALF_TIME)
	fade_out:SetFromAlpha(1)
	fade_out:SetToAlpha(0)
	fade_out:SetOrder(2)

	local cooldown = PitBull4.Controls.MakeCooldown(control)
	control.cooldown = cooldown
	cooldown:SetAllPoints(control)
	cooldown:SetDrawEdge(true)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:Clear()
end, function(control, id)
	-- onRetrieve

	control.id = id
end, function(control)
	-- onDelete

	control.id = nil
	control.rune_type = nil

	control:SetNormalTexture(0)
end)
