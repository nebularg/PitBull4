if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Background requires PitBull4")
end

local PitBull4_Background = PitBull4:NewModule("Background")

PitBull4_Background:SetModuleType("custom")
PitBull4_Background:SetName("Background")
PitBull4_Background:SetDescription("Show a flat background for your unit frames.")
PitBull4_Background:SetDefaults({
	color = { 0, 0, 0, 0.5 }
})

function PitBull4_Background:UpdateFrame(frame)
	if not self:GetLayoutDB(frame).enabled then
		return self:ClearFrame(frame)
	end
	
	if frame.Background then
		return false
	end
	
	local background = PitBull4.Controls.MakeTexture(frame, "BACKGROUND")
	frame.Background = background
	background:SetTexture(unpack(PitBull4_Background:GetLayoutDB(frame).color))
	background:SetAllPoints(frame)
	return false
end

function PitBull4_Background:ClearFrame(frame)
	if not frame.Background then
		return false
	end
	
	frame.Background = frame.Background:Delete()
	return false
end

PitBull4_Background:SetLayoutOptionsFunction(function(self) end)
