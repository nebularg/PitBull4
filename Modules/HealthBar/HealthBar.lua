if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HealthBar requires PitBull4")
end

local PitBull4_HealthBar = PitBull4.NewModule("HealthBar", "Health Bar", "Show a health bar", {}, {
	position = 1,
}, "statusbar")

function PitBull4_HealthBar.GetValue(frame)
	return UnitHealth(frame.unitID) / UnitHealthMax(frame.unitID)
end

function PitBull4_HealthBar.GetColor(frame)
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

function PitBull4_HealthBar.UNIT_HEALTH(event, unitID)
	PitBull4_HealthBar:UpdateForUnitID(unitID)
end

PitBull4.Utils.AddEventListener("UNIT_HEALTH", PitBull4_HealthBar.UNIT_HEALTH)
PitBull4.Utils.AddEventListener("UNIT_MAXHEALTH", PitBull4_HealthBar.UNIT_HEALTH)
