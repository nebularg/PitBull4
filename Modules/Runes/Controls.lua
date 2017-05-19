
local PitBull4 = _G.PitBull4

-- CONSTANTS ----------------------------------------------------------------

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2

-- local ICON_TEXTURE = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-SingleRune]]
local ICON_TEXTURE = [[Interface\AddOns\PitBull4\Modules\Runes\Death]]
local SHINE_TEXTURE = [[Interface\AddOns\PitBull4\Modules\Runes\Shine]]

local UNREADY_ALPHA = 0.6
local READY_ALPHA = 1

-----------------------------------------------------------------------------

local Rune = {}
local Rune_scripts = {}

function Rune:UpdateCooldown()
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
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G.COMBAT_TEXT_RUNE_DEATH)
	GameTooltip:AddLine(_G.RUNES_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
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

	control:SetNormalTexture(ICON_TEXTURE)

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
end)
