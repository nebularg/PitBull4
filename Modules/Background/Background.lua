if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Background requires PitBull4")
end

local PitBull4_Background = PitBull4.NewModule("Background", "Background", "Show a flat background for your unit frames", {}, {
	color = { 0, 0, 0, 0.5 }
})

PitBull4_Background:AddFrameScriptHook("OnPopulate", function(frame)
	local background = PitBull4.Controls.MakeTexture(frame, "BACKGROUND")
	frame.background = background
	background:SetTexture(unpack(frame.layoutDB.Background.color))
	background:SetAllPoints(frame)
end)

PitBull4_Background:AddFrameScriptHook("OnClear", function(frame)
	frame.background = frame.background:Delete()
end)
