if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass("player")) ~= "WARLOCK" then
	return
end

-- CONSTANTS ----------------------------------------------------------------

local module_path = _G.debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z0-9]-%.lua")

local ICON_TEXTURE = [[Interface\playerFrame\Warlock-DestructionUI]]

local STANDARD_SIZE = 15

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2
local INVERSE_SHINE_HALF_TIME = 1 / SHINE_HALF_TIME

local UNREADY_ALPHA = 0.6
local READY_ALPHA = 1

local EPSILON = 1e-5

local FIRE_TOP = 0.40812500
local FIRE_BOTTOM = 0.80750000
local DELTA_PER_POWER = (FIRE_BOTTOM - FIRE_TOP) / MAX_POWER_PER_EMBER

-----------------------------------------------------------------------------

local BurningEmber = {}
local BurningEmber_scripts = {}

function BurningEmber:UpdateTexture()
	local texture = self:GetNormalTexture()
	local value = self.value or 0
	local inverse_value = MAX_POWER_PER_EMBER - value
	if value == 0 then
		value = EPSILON
	end
	if value < MAX_POWER_PER_EMBER then 
		texture:SetTexCoord(0.00390625, 0.14453125, FIRE_TOP + (DELTA_PER_POWER * inverse_value), FIRE_BOTTOM)
		texture:SetVertexColor(0.5, 0.5, 0.5)
		texture:ClearAllPoints()
		texture:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, 0)
		texture:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 0, 0)
		texture:SetHeight(STANDARD_SIZE * (value / MAX_POWER_PER_EMBER))
	else
		texture:SetVertexColor(1, 1, 1)
		texture:SetTexCoord(0.00390625, 0.14453125, 0.40812500, 0.80750000)
		texture:SetAllPoints(self)
	end
end

local function BurningEmber_OnUpdate(self, elapsed)
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

function BurningEmber:SetValue(value)
	local clamped_value = value
	if clamped_value < 0 then
		clamped_value = 0
	elseif clamped_value > MAX_POWER_PER_EMBER then
		clamped_value = MAX_POWER_PER_EMBER
	end
	if self.value == clamped_value then
		return
	end
	self.value = clamped_value
	self:UpdateTexture()
	if clamped_value == MAX_POWER_PER_EMBER then
		self:Shine()
	end
end

function BurningEmber:SetGreenFire(value)
	value = not not value
	if self.green_fire == value then return end
	self:SetNormalTexture(ICON_TEXTURE .. (value and "-Green" or ""))
	self.green_fire = value
end

function BurningEmber:Shine()
	local shine = self.shine
	if not shine then
		shine = PitBull4.Controls.MakeTexture(self, "OVERLAY")
		self.shine = shine
		shine:SetTexture(ICON_TEXTURE)
		shine:SetTexCoord(0.00390625, 0.14453125, 0.40812500, 0.80750000)
		shine:SetBlendMode("ADD")
		shine:SetAlpha(0)
		shine:SetAllPoints(self)
		self:SetScript("OnUpdate", BurningEmber_OnUpdate)
	end
	self.shine_time = 0
end

function BurningEmber_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(BURNING_EMBERS, 1, 1, 1)
	GameTooltip:AddLine(BURNING_EMBERS_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

function BurningEmber_scripts:OnLeave()
	GameTooltip:Hide()
end

PitBull4.Controls.MakeNewControlType("BurningEmber", "Button", function(control)
	-- onCreate
	
	for k, v in pairs(BurningEmber) do
		control[k] = v
	end
	for k, v in pairs(BurningEmber_scripts) do
		control:SetScript(k, v)
	end
end, function(control, id)
	-- onRetrieve
	
	control.id = id
	control:SetWidth(STANDARD_SIZE)
	control:SetHeight(STANDARD_SIZE)
	control:SetNormalTexture(ICON_TEXTURE)
end, function(control)
	-- onDelete
	
	control.id = nil
	control.value = nil
	control.shine_time = nil
	
	control:SetNormalTexture(nil)
	if control.shine then
		control.shine = control.shine:Delete()
	end
	control:SetScript("OnUpdate", nil)
end)
