if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HealthBar requires PitBull4")
end

local PitBull4_HealthBar = PitBull4:NewModule("HealthBar", "AceEvent-3.0")

PitBull4_HealthBar:SetModuleType("statusbar")
PitBull4_HealthBar:SetName("Health Bar")
PitBull4_HealthBar:SetDescription("Show a health bar.")
PitBull4_HealthBar:SetDefaults({
	position = 1,
	colorByClass = true,
})

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

function PitBull4_HealthBar:OnEnable()
	timerFrame:Show()
	
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
	
	self:UpdateAll()
end

function PitBull4_HealthBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	for frame in PitBull4:IterateFramesForUnitIDs("player", "target", "targettarget", "pet", "focus") do
		PitBull4_HealthBar:Update(frame)
	end
end)

function PitBull4_HealthBar:GetValue(frame)
	return UnitHealth(frame.unit) / UnitHealthMax(frame.unit)
end

function PitBull4_HealthBar:GetColor(frame, value)
	if self:GetLayoutDB(frame).colorByClass then
		local _, class = UnitClass(frame.unit)
		local t = RAID_CLASS_COLORS[class]
		if t then
			return t.r, t.g, t.b
		end
	end
	if value < 0.5 then
		return
			1,
			value * 2,
			0
	else
		return
			(1 - value) * 2,
			1,
			0
	end
end

function PitBull4_HealthBar:UNIT_HEALTH(event, unit)
	PitBull4_HealthBar:UpdateForUnitID(unit)
end

PitBull4_HealthBar:SetLayoutOptionsFunction(function(self)
	return 'colorByClass', {
		name = "Color by class",
		desc = "Color the health bar by unit class",
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).colorByClass
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).colorByClass = value
			
			PitBull4.Options.UpdateFrames()
		end
	}
end)
