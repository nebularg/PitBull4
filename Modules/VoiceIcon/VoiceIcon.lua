
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_VoiceIcon = PitBull4:NewModule("VoiceIcon")

PitBull4_VoiceIcon:SetModuleType("indicator")
PitBull4_VoiceIcon:SetName(L["Voice icon"])
PitBull4_VoiceIcon:SetDescription(L["Show an icon on the unit frame when the player is speaking."])
PitBull4_VoiceIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_right",
	position = 1,
})

-- Called when the notification is shown (ie, someone is speaking)
local function notificationCreatedCallback(frame, icon)
	icon:SetParent(frame)
	icon:SetFrameLevel(frame:GetFrameLevel() + 13)
	icon:Show()

	frame.VoiceIcon = icon
	frame:UpdateLayout(false)
end

-- Called on acquire for new objects and on release
local function resetterFunc(pool, icon)
	icon:Hide()
	icon:ClearAllPoints()

	local frame = icon:GetParent()
	if frame.VoiceIcon then
		frame.VoiceIcon = nil
		frame:UpdateLayout(false)
	end
end

function PitBull4_VoiceIcon:ClearFrame(frame)
	if not VoiceActivityManager then return end

	local control = frame.VoiceIcon
	if control and control.force_show then
		control.force_show = nil
		frame.VoiceIcon = control:Delete()
		return true
	end

	VoiceActivityManager:UnregisterFrameForVoiceActivityNotifications(frame)

	return false
end

function PitBull4_VoiceIcon:UpdateFrame(frame)
	if not VoiceActivityManager then return end

	if not frame.unit or frame.is_wacky then
		return self:ClearFrame(frame)
	end

	-- Config mode
	if frame.force_show then
		VoiceActivityManager:UnregisterFrameForVoiceActivityNotifications(frame)

		local control = frame.VoiceIcon
		local made_control = not control
		if made_control then
			control = PitBull4.Controls.MakeIcon(frame)
			control:SetFrameLevel(frame:GetFrameLevel() + 13)
			frame.VoiceIcon = control
			control:SetWidth(16)
			control:SetHeight(16)
			control.force_show = true
		end
		control.texture:SetTexture(nil)
		control.texture:SetTexCoord(0,1,0,1)
		control.texture:SetAtlas("voicechat-icon-speaker")
		control:Show()

		return made_control
	elseif frame.VoiceIcon and frame.VoiceIcon.force_show then
		self:ClearFrame(frame)
	end

	if not frame.guid or not UnitIsPlayer(frame.unit) then
		return self:ClearFrame(frame)
	end

	-- Manually create the pool so we can set a reset function
	if not VoiceActivityManager.externalNotificationTemplates["VoiceActivityNotificationPitBull4Template"] then
		VoiceActivityManager.notificationPools:CreatePool("Button", VoiceActivityManager, "VoiceActivityNotificationPitBull4Template", resetterFunc)
		VoiceActivityManager.externalNotificationTemplates["VoiceActivityNotificationPitBull4Template"] = true
	end
	-- Just use the Blizzard system. The API has come a long way since UnitIsTalking(unit)
	VoiceActivityManager:RegisterFrameForVoiceActivityNotifications(frame, frame.guid, nil, "VoiceActivityNotificationPitBull4Template", "Button", notificationCreatedCallback)

	-- Layout updates are performed in the callbacks
	return false
end
