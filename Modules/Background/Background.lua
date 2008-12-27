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

function PitBull4_Background:OnEnable()
	self:AddFrameScriptHook("OnPopulate")
	self:AddFrameScriptHook("OnClear")
	for frame in PitBull4:IterateFrames() do
		self:OnPopulate(frame)
	end
end

function PitBull4_Background:OnDisable()
	for frame in PitBull4:IterateFrames() do
		self:OnClear(frame)
	end
end

function PitBull4_Background:OnPopulate(frame)
	local background = PitBull4.Controls.MakeTexture(frame, "BACKGROUND")
	frame.Background = background
	background:SetTexture(unpack(PitBull4_Background:GetLayoutDB(frame).color))
	background:SetAllPoints(frame)
end

function PitBull4_Background:OnClear(frame)
	frame.Background = frame.Background:Delete()
end
