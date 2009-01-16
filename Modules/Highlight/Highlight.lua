if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Highlight requires PitBull4")
end

local L = PitBull4.L

local PitBull4_Highlight = PitBull4:NewModule("Highlight")

PitBull4_Highlight:SetModuleType("custom")
PitBull4_Highlight:SetName(L["Highlight"])
PitBull4_Highlight:SetDescription(L["Show a highlight when hovering or targeting."])
PitBull4_Highlight:SetDefaults({
	color = { 1, 1, 1, 1 }
})

function PitBull4_Highlight:OnEnable()
	self:AddFrameScriptHook("OnEnter")
	self:AddFrameScriptHook("OnLeave")
	
	local mouseFocus = GetMouseFocus()
	for frame in PitBull4:IterateFrames() do
		if mouseFocus == frame then
			self:OnEnter(frame)
		end
	end
end

function PitBull4_Highlight:OnDisable()
        self:RemoveFrameScriptHook("OnEnter")
        self:RemoveFrameScriptHook("OnLeave")
end

function PitBull4_Highlight:UpdateFrame(frame)
	if frame.Highlight then
		frame.Highlight.texture:SetVertexColor(unpack(self:GetLayoutDB(frame).color))
		return false
	end
	
	local highlight = PitBull4.Controls.MakeFrame(frame)
	frame.Highlight = highlight
	highlight:SetAllPoints(frame)
	highlight:SetFrameLevel(highlight:GetFrameLevel() + 5)
	highlight:Hide()
	
	local texture = PitBull4.Controls.MakeTexture(highlight, "OVERLAY")
	highlight.texture = texture
	texture:SetTexture([=[Interface\QuestFrame\UI-QuestTitleHighlight]=])
	texture:SetBlendMode("ADD")
	texture:SetAlpha(0.5)
	texture:SetAllPoints(highlight)
	texture:SetVertexColor(unpack(self:GetLayoutDB(frame).color))
	
	return false
end

function PitBull4_Highlight:ClearFrame(frame)
	if not frame.Highlight then
		return false
	end
	
	frame.Highlight.texture = frame.Highlight.texture:Delete()
	frame.Highlight = frame.Highlight:Delete()
	
	return false
end

function PitBull4_Highlight:OnEnter(frame)
	if not frame.Highlight then
		return
	end
	frame.Highlight:Show()
end

function PitBull4_Highlight:OnLeave(frame)
	if not frame.Highlight then
		return
	end
	frame.Highlight:Hide()
end

PitBull4_Highlight:SetLayoutOptionsFunction(function(self)
	return 'color', {
		type = 'color',
		name = L["Color"],
		desc = L["Color that the highlight should be."],
		hasAlpha = true,
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).color
			color[1], color[2], color[3], color[4] = r, g, b, a
			
			PitBull4.Options.UpdateFrames()
		end,
	}
end)
