if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Highlight requires PitBull4")
end

local PitBull4_Highlight = PitBull4:NewModule("Highlight")

PitBull4_Highlight:SetModuleType("custom")
PitBull4_Highlight:SetName("Highlight")
PitBull4_Highlight:SetDescription("Show a highlight when hovering or targeting.")
PitBull4_Highlight:SetDefaults({})

function PitBull4_Highlight:OnEnable()
	self:AddFrameScriptHook("OnPopulate")
	self:AddFrameScriptHook("OnClear")
	self:AddFrameScriptHook("OnEnter")
	self:AddFrameScriptHook("OnLeave")
	
	local mouseFocus = GetMouseFocus()
	for frame in PitBull4:IterateFrames(true) do
		self:OnPopulate(frame)
		
		if mouseFocus == frame then
			self:OnEnter(frame)
		end
	end
end

function PitBull4_Highlight:OnDisable()
	for frame in PitBull4:IterateFrames(true) do
		self:OnClear(frame)
	end
end

function PitBull4_Highlight:OnPopulate(frame)
	local highlight = PitBull4.Controls.MakeFrame(frame)
	frame.highlight = highlight
	highlight:SetAllPoints(frame)
	highlight:SetFrameLevel(highlight:GetFrameLevel() + 5)
	highlight:Hide()
	
	local texture = PitBull4.Controls.MakeTexture(highlight, "OVERLAY")
	highlight.texture = texture
	texture:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
	texture:SetBlendMode("ADD")
	texture:SetAlpha(0.5)
	texture:SetAllPoints(highlight)
end

function PitBull4_Highlight:OnClear(frame)
	frame.highlight.texture = frame.highlight.texture:Delete()
	frame.highlight = frame.highlight:Delete()
end

function PitBull4_Highlight:OnEnter(frame)
	if not frame.highlight then
		return
	end
	frame.highlight:Show()
end

function PitBull4_Highlight:OnLeave(frame)
	if not frame.highlight then
		return
	end
	frame.highlight:Hide()
end
