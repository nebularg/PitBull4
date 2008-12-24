if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HealthBar requires PitBull4")
end

local PitBull4_HealthBar = PitBull4.NewModule("HealthBar", "Health Bar", "Show a health bar", {}, {
	position = 1,
	colorByClass = true,
}, "statusbar")

function PitBull4_HealthBar.GetValue(frame)
	return UnitHealth(frame.unit) / UnitHealthMax(frame.unit)
end

function PitBull4_HealthBar.GetColor(frame)
	if frame.layoutDB.HealthBar.colorByClass then
		local _, class = UnitClass(frame.unit)
		local t = RAID_CLASS_COLORS[class]
		if t then
			return t.r, t.g, t.b
		end
	end
	local percent = PitBull4_HealthBar.GetValue(frame)
	if percent < 0.5 then
		return
			1,
			percent * 2,
			0
	else
		return
			(1 - percent) * 2,
			1,
			0
	end
end

PitBull4_HealthBar:SetValueFunction('GetValue')
PitBull4_HealthBar:SetColorFunction('GetColor')

function PitBull4_HealthBar.UNIT_HEALTH(event, unit)
	PitBull4_HealthBar:UpdateForUnitID(unit)
end

PitBull4.Utils.AddEventListener("UNIT_HEALTH", PitBull4_HealthBar.UNIT_HEALTH)
PitBull4.Utils.AddEventListener("UNIT_MAXHEALTH", PitBull4_HealthBar.UNIT_HEALTH)

PitBull4_HealthBar:SetLayoutOptionsFunction(function()
	return 'colorByClass', {
		name = "Color by class",
		desc = "Color the health bar by unit class",
		type = 'toggle',
		get = function(info)
			return PitBull4.Options.GetLayoutDB().HealthBar.colorByClass
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB().HealthBar
			db.colorByClass = value
			
			PitBull4.Options.UpdateFrames()
		end
	}
end)
