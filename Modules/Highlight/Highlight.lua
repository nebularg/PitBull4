if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Highlight requires PitBull4")
end

local PitBull4_Highlight = PitBull4.NewModule("Highlight", "Highlight", "Show a highlight when hovering or targeting", {}, {}, "custom")

PitBull4_Highlight:AddFrameScriptHook("OnPopulate", function(frame)
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
end)

PitBull4_Highlight:AddFrameScriptHook("OnClear", function(frame)
	frame.highlight.texture = frame.highlight.texture:Delete()
	frame.highlight = frame.highlight:Delete()
end)

PitBull4_Highlight:AddFrameScriptHook("OnEnter", function(frame)
	if not frame.highlight then
		return
	end
	frame.highlight:Show()
end)

PitBull4_Highlight:AddFrameScriptHook("OnLeave", function(frame)
	if not frame.highlight then
		return
	end
	frame.highlight:Hide()
end)
