
local PitBull4 = _G.PitBull4

-- CONSTANTS ----------------------------------------------------------------

local ICON_TEXTURE = [[Interface\AddOns\PitBull4\Modules\HolyPower\Holy]]
local SHINE_TEXTURE = [[Interface\AddOns\PitBull4\Modules\HolyPower\Shine]]

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2

-----------------------------------------------------------------------------

local HolyIcon = {}
local HolyIcon_scripts = {}

local tmp_color = { 1, 1, 1, 1 }
function HolyIcon:UpdateColors(active_color, inactive_color)
	self.active_color = active_color
	self.inactive_color = inactive_color
end

function HolyIcon:UpdateTexture()
	self.shine.ag:Stop()
	self.shine:SetAlpha(0)
	local texture = self:GetNormalTexture()
	if self.active then
		self.shine.ag:Play()
		texture:SetVertexColor(unpack(self.active_color))
	else
		texture:SetVertexColor(unpack(self.inactive_color))
	end
end

function HolyIcon:Activate()
	if self.active then
		return
	end
	self.active = true
	self:UpdateTexture()
end

function HolyIcon:Deactivate()
	if not self.active then
		return
	end
	self.active = nil
	self:UpdateTexture()
end

function HolyIcon_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G.HOLY_POWER)
	GameTooltip:AddLine(_G.HOLY_POWER_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

function HolyIcon_scripts:OnLeave()
	GameTooltip:Hide()
end

PitBull4.Controls.MakeNewControlType("HolyIcon", "Button", function(control)
	-- onCreate

	for k, v in pairs(HolyIcon) do
		control[k] = v
	end
	for k, v in pairs(HolyIcon_scripts) do
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
end, function(control, id)
	-- onRetrieve

	control.id = id
	control:UpdateColors(tmp_color, tmp_color)
end, function(control)
	-- onDelete

	control.id = nil
	control.active = nil
	control.active_color = nil
	control.inactive_color = nil
end)
