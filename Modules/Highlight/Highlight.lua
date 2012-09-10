if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Highlight requires PitBull4")
end

local L = PitBull4.L

local LibSharedMedia
local AceGUI

local PitBull4_Highlight = PitBull4:NewModule("Highlight", "AceEvent-3.0")

PitBull4_Highlight:SetModuleType("custom")
PitBull4_Highlight:SetName(L["Highlight"])
PitBull4_Highlight:SetDescription(L["Show a highlight when hovering or targeting."])
PitBull4_Highlight:SetDefaults({
	color = { 1, 1, 1, 1 },
	show_target = true,
	while_hover = true,
	texture = "Blizzard QuestTitleHighlight",
})

local EXEMPT_UNITS = {}
for i = 1, 5 do
	EXEMPT_UNITS[("target"):rep(i)] = true
end

local target_guid = nil
local mouse_focus = nil
function PitBull4_Highlight:OnEnable()
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
	LoadAddOn("AceGUI-3.0-SharedMediaWidgets")
	AceGUI = LibStub("AceGUI-3.0")

	LibSharedMedia:Register("background","Blizzard QuestTitleHighlight", [[Interface\QuestFrame\UI-QuestTitleHighlight]])
	LibSharedMedia:Register("background","Blizzard QuestLogTitleHighlight", [[Interface\QuestFrame\UI-QuestLogTitleHighlight]])

	self:AddFrameScriptHook("OnEnter")
	self:AddFrameScriptHook("OnLeave")
	
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	
	self:PLAYER_TARGET_CHANGED()
end

function PitBull4_Highlight:OnDisable()
	self:RemoveFrameScriptHook("OnEnter")
	self:RemoveFrameScriptHook("OnLeave")
end

function PitBull4_Highlight:UpdateFrame(frame)
	local highlight = frame.Highlight
	
	if not self:ShouldShow(frame) then
		if highlight then
			highlight:Hide()
		end
		return false
	end

	if not highlight then
		highlight = PitBull4.Controls.MakeFrame(frame)
		frame.Highlight = highlight
		highlight:SetAllPoints(frame)
		highlight:SetFrameLevel(frame:GetFrameLevel() + 17)
	
		local texture = PitBull4.Controls.MakeTexture(highlight, "OVERLAY")
		highlight.texture = texture
		texture:SetBlendMode("ADD")
		texture:SetAllPoints(highlight)
	end
		
	local layout_db = self:GetLayoutDB(frame)
	local texture = highlight.texture
	local texture_path = LibSharedMedia:Fetch("background", layout_db.texture)
	texture:SetTexture(texture_path)
	texture:SetVertexColor(unpack(layout_db.color))

	highlight:Show()
	
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
	mouse_focus = frame
	self:Update(frame)
end

function PitBull4_Highlight:OnLeave(frame)
	mouse_focus = nil
	self:Update(frame)
end

function PitBull4_Highlight:ShouldShow(frame)
	local db = self:GetLayoutDB(frame)
	
	if mouse_focus == frame and db.while_hover then
		return true
	end
	
	if not target_guid or frame.guid ~= target_guid or EXEMPT_UNITS[frame.unit] then
		return false
	end
	
	if not db.show_target then
		return false
	end
	
	return true
end

function PitBull4_Highlight:PLAYER_TARGET_CHANGED()
	target_guid = UnitGUID("target")
	
	self:UpdateAll()
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
	}, 'show_target', {
		type = 'toggle',
		name = L["When targetted"],
		desc = L["Highlight this unit frame when it is the same as your current target."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).show_target
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).show_target = value
			
			self:PLAYER_TARGET_CHANGED()
		end,
	}, 'while_hover', {
		type = 'toggle',
		name = L["On mouse hover"],
		desc = L["Highlight this unit frame while the mouse hovers over it."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).while_hover
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).while_hover = value

			PitBull4.Options.UpdateFrames()
		end,
	}, 'texture', {
		type = 'select',
		name = L["Texture"],
		desc = L["What texture the highlight should use."] .. "\n" .. L["If you want more textures, you should install the addon 'SharedMedia'."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).texture
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).texture = value

			PitBull4.Options.UpdateFrames()
		end,
		values = function(info)
			return LibSharedMedia:HashTable("background")
		end,
		disabled = disabled,
		hidden = function(info)
			return not LibSharedMedia
		end,
		dialogControl = AceGUI.WidgetRegistry["LSM30_Background"] and "LSM30_Background" or nil,
	}
end)
