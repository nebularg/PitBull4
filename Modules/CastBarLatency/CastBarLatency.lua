if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

-- CONSTANTS
local ALPHA_MODIFIER = 0.6		-- Multiplied to the main CastBar's alpha at any point of time.

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_CastBarLatency requires PitBull4")
end

local GetTime = _G.GetTime
local L = PitBull4.L

local PitBull4_CastBar = PitBull4:GetModule("CastBar", true)
if not PitBull4_CastBar then
	error(L["PitBull4_CastBarLatency requires the CastBar module"])
end

local PitBull4_CastBarLatency = PitBull4:NewModule("CastBarLatency", "AceEvent-3.0")

PitBull4_CastBarLatency:SetModuleType("custom")
PitBull4_CastBarLatency:SetName(L["Cast bar latency"])
PitBull4_CastBarLatency:SetDescription(L["Show a guessed safe zone at the end of the player castbar."])
PitBull4_CastBarLatency:SetDefaults({},{latency_color = {1, 0, 0, 1}})
PitBull4_CastBarLatency:SetLayoutOptionsFunction(function(self) end)

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function()
	for frame in PitBull4:IterateFrames() do
		local unit = frame.unit
		if unit and UnitIsUnit(unit,"player") then
			PitBull4_CastBarLatency:Update(frame)
		end
	end
end)


local send_time  = 0
local start_time = 0
local lag_time   = 0
local max_time   = 0

local function StartCast(event, unit, spell, spellrank)
	if unit ~= 'player' then
		return
	end

	local name, _, _, _, new_start, new_end, _, _ = UnitCastingInfo(unit)
	if not name then
		return
	end
	
	end_time = (new_end / 1e3)
	start_time = (new_start / 1e3)
	max_time = end_time - start_time
	lag_time = start_time - send_time
end

function PitBull4_CastBarLatency:UNIT_SPELLCAST_SENT(event, unit, spell, spellrank) 
	if unit ~= 'player' then
		return
	end
	send_time = GetTime()
end

function PitBull4_CastBarLatency:OnEnable()
	timerFrame:Show()
	
	self:RegisterEvent("UNIT_SPELLCAST_SENT")
	self:RegisterEvent("UNIT_SPELLCAST_START", StartCast)
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START", StartCast)
end

function PitBull4_CastBarLatency:OnDisable()
	timerFrame:Hide()
end

function PitBull4_CastBarLatency:UpdateFrame(frame)
	local unit = frame.unit
	if not unit or not UnitIsUnit(unit,"player") then
		return self:ClearFrame(frame)
	end
	
	local bar = frame.CastBar
	if not bar then
		return self:ClearFrame(frame)
	end
	
	local safe_zone = frame.CastBarLatency
	if not safe_zone then -- Our own Bar doesn't exist yet, create it
		safe_zone = PitBull4.Controls.MakeBetterStatusBar(frame)
		safe_zone:SetTexture(bar:GetTexture()) -- Might need to be moved down to update properly
		safe_zone:SetValue(1)
		safe_zone:SetColor(unpack(self.db.profile.global.latency_color))
		safe_zone:SetBackgroundAlpha(0) -- so we can actually see the main bar behind us
		
		frame.CastBarLatency = safe_zone
	end
	local safe_zone_percent = 0
	if max_time > 0 then
		safe_zone_percent = (lag_time / max_time)
	end
	if (safe_zone_percent > 1) then safe_zone_percent = 1 end
	
	safe_zone:ClearAllPoints()
	safe_zone:SetAllPoints(bar)
	local bar_alpha = select(4,PitBull4_CastBar:GetColor(frame, 'player'))
	if bar_alpha then
		safe_zone:SetAlpha(bar_alpha*ALPHA_MODIFIER)
	end
	safe_zone:SetColor(unpack(self.db.profile.global.latency_color))
	safe_zone:SetFrameLevel( (bar:GetFrameLevel()+1) )
	safe_zone:SetReverse( (not bar:GetReverse()) )
	safe_zone:SetOrientation( bar:GetOrientation() )
	if bar:GetDeficit() then
		safe_zone:SetReverse( bar:GetReverse() )
	end
	safe_zone:Show()

	safe_zone:SetValue(safe_zone_percent)
	
	return false
end

function PitBull4_CastBarLatency:ClearFrame(frame)
	if not frame.CastBarLatency then
		return false
	end
	
	frame.CastBarLatency = frame.CastBarLatency:Delete()
	return false
end

PitBull4_CastBarLatency:SetColorOptionsFunction(function(self)
	return 'latency_color', {
		type = 'color',
		name = L['Latency'],
		desc = L['Sets which color the latency overlay on the castbar is using.'],
		get = function(info)
			return unpack(self.db.profile.global.latency_color)
		end,
		set = function(info, r, g, b, a)
			self.db.profile.global.latency_color = {r, g, b, 1}
			self:UpdateAll()
		end,
	},
	function(info)
		self.db.profile.global.latency_color = {1, 0, 0, 1}
	end
end)
