if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_BlankSpace requires PitBull4")
end

local L = PitBull4.L

local PitBull4_BlankSpace = PitBull4:NewModule("BlankSpace")

PitBull4_BlankSpace:SetModuleType("status_bar")
PitBull4_BlankSpace:SetName(L["Blank space"])
PitBull4_BlankSpace:SetDescription(L["Show an empty bar for spacing."])
PitBull4_BlankSpace:SetDefaults({
	position = 2,
	enabled = false
})

function PitBull4_BlankSpace:GetValue(frame)
	return 1
end

function PitBull4_BlankSpace:GetExampleValue(frame)
	return 1
end

function PitBull4_BlankSpace:GetColor(frame, value)
	return 0, 0, 0
end

PitBull4_BlankSpace:SetLayoutOptionsFunction(function(self)
	return
		'deficit', nil,
		'background_alpha', nil
end)