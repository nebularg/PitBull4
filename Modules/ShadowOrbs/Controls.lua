if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass("player")) ~= "PRIEST" then
	return
end

-- CONSTANTS ---------------------------------------------------------------SHADOW_ORBS-

local module_path = _G.debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z0-9]-%.lua")

local UI_TEXTURE = [[Interface\PlayerFrame\Priest-ShadowUI]]

local STANDARD_SIZE = 38 

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2
local INVERSE_SHINE_HALF_TIME = 1 / SHINE_HALF_TIME

local UNREADY_ALPHA = 0.6
local READY_ALPHA = 1

-----------------------------------------------------------------------------

local ShadowOrb = {}
local ShadowOrb_scripts = {}

local tmp_color = { 1, 1, 1, 1 }
function ShadowOrb:UpdateColors(active_color, inactive_color)
	self.active_color = active_color
	self.inactive_color = inactive_color
end

function ShadowOrb:UpdateTexture()
	self:SetNormalTexture(UI_TEXTURE)
	self:GetNormalTexture():SetTexCoord(0.45703125, 0.60546875, 0.44531250, 0.73437500)
	local texture = self:GetNormalTexture()
	if self.active then
		texture:SetVertexColor(unpack(self.active_color or tmp_color))
	else
		texture:SetVertexColor(unpack(self.inactive_color or tmp_color))
	end
end

local function ShadowOrb_OnUpdate(self, elapsed)
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

function ShadowOrb:Activate()
	if self.active then
		return
	end
	self.active = true
	self:Shine()
	self:UpdateTexture()
end

function ShadowOrb:Deactivate()
	if not self.active then
		return
	end
	self.active = nil
	self:UpdateTexture()
end

function ShadowOrb:Shine()
	local shine = self.shine
	if not shine then
		shine = PitBull4.Controls.MakeTexture(self, "OVERLAY")
		self.shine = shine
		shine:SetTexture(UI_TEXTURE)
		shine:SetTexCoord(0.45703125, 0.60546875, 0.44531250, 0.73475600)
		shine:SetBlendMode("ADD")
		shine:SetAlpha(0)
		shine:SetAllPoints(self)
		shine:SetVertexColor(unpack(self.active_color or tmp_color))
		self:SetScript("OnUpdate", ShadowOrb_OnUpdate)
	end
	self.shine_time = 0
end

function ShadowOrb_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(SHADOW_ORBS, 1, 1, 1)
	GameTooltip:AddLine(SHADOW_ORBS_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

function ShadowOrb_scripts:OnLeave()
	GameTooltip:Hide()
end

PitBull4.Controls.MakeNewControlType("ShadowOrb", "Button", function(control)
	-- onCreate
	
	for k, v in pairs(ShadowOrb) do
		control[k] = v
	end
	for k, v in pairs(ShadowOrb_scripts) do
		control:SetScript(k, v)
	end
end, function(control, id)
	-- onRetrieve
	
	control.id = id
	control:SetWidth(STANDARD_SIZE)
	control:SetHeight(STANDARD_SIZE)
end, function(control)
	-- onDelete
	
	control.id = nil
	control.active = nil
	control.shine_time = nil
	
	control:SetNormalTexture(nil)
	if control.shine then
		control.shine = control.shine:Delete()
	end
	control:SetScript("OnUpdate", nil)
end)
