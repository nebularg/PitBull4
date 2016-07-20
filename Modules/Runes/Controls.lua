if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
local PitBull4_Runes = PitBull4:GetModule("Runes", true)
if not PitBull4_Runes then
	return
end

-- CONSTANTS ----------------------------------------------------------------

local module_path = _G.debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z0-9]-%.lua")

local STANDARD_SIZE = 15

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2
local INVERSE_SHINE_HALF_TIME = 1 / SHINE_HALF_TIME

-- local ICON_TEXTURE = [[Interface\PlayerFrame\UI-PlayerFrame-Deathknight-SingleRune]]
local ICON_TEXTURE = [[Interface\AddOns\]] .. module_path .. [[\Death]]
local SHINE_TEXTURE = [[Interface\AddOns\]] .. module_path .. [[\Shine]]

local UNREADY_ALPHA = 0.6
local READY_ALPHA = 1

-----------------------------------------------------------------------------

local Rune = {}
local Rune_scripts = {}

function Rune:UpdateCooldown()
	local start, duration, ready = GetRuneCooldown(self.id)

	local cooldown = self.cooldown
	if ready or not start then
		if cooldown:IsShown() then
			cooldown:Hide()
			self:Shine()
		end
		self:GetNormalTexture():SetAlpha(READY_ALPHA)
	else
		if self.shine then
			self:SetScript("OnUpdate", nil)
			self.shine_time = nil
			self.shine = self.shine:Delete()
		end
		cooldown:Show()
		CooldownFrame_Set(cooldown, start, duration, 1)
		self:GetNormalTexture():SetAlpha(UNREADY_ALPHA)
	end
end

local function Rune_OnUpdate(self, elapsed)
	local shine_time = self.shine_time + elapsed

	if shine_time > SHINE_TIME then
		self:SetScript("OnUpdate", nil)
		self.shine_time = nil
		self.shine = self.shine:Delete()
		return
	end
	self.shine_time = shine_time

	if shine_time < SHINE_HALF_TIME then
		self.shine:SetAlpha(shine_time * INVERSE_SHINE_HALF_TIME)
	else
		self.shine:SetAlpha((SHINE_TIME - shine_time) * INVERSE_SHINE_HALF_TIME)
	end
end

function Rune:Shine()
	local shine = self.shine
	if not shine then
		shine = PitBull4.Controls.MakeTexture(self, "OVERLAY")
		self.shine = shine
		shine:SetTexture(SHINE_TEXTURE)
		shine:SetBlendMode("ADD")
		shine:SetAlpha(0)
		shine:SetAllPoints(self)
		self:SetScript("OnUpdate", Rune_OnUpdate)
	end
	self.shine_time = 0
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

	local cooldown = PitBull4.Controls.MakeCooldown(control)
	control.cooldown = cooldown
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetAllPoints(control)
	cooldown:Show()
end, function(control, id)
	-- onRetrieve

	control.id = id
	control.cooldown:Hide()
	control:SetNormalTexture(ICON_TEXTURE)
	control:SetWidth(STANDARD_SIZE)
	control:SetHeight(STANDARD_SIZE)
end, function(control)
	-- onDelete

	control.id = nil
	control.shine_time = nil

	control.cooldown:Hide()
	control:SetNormalTexture(nil)
	if control.shine then
		control.shine = control.shine:Delete()
	end
	control:SetScript("OnUpdate", nil)
end)
