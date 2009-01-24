if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_CastBar requires PitBull4")
end
local L = PitBull4.L

local PitBull4_CastBar = PitBull4:NewModule("CastBar", "AceEvent-3.0")

PitBull4_CastBar:SetModuleType("bar")
PitBull4_CastBar:SetName(L["Cast bar"])
PitBull4_CastBar:SetDescription(L["Show a cast bar."])
PitBull4_CastBar:SetDefaults({
	size = 1,
	position = 10,
})

local castData = {}
PitBull4_CastBar.castData = castData

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
timerFrame:SetScript("OnUpdate", function() PitBull4_CastBar:FixCastDataAndUpdateAll() end)

local player_guid, target_guid, pet_guid
function PitBull4_CastBar:OnEnable()
	player_guid = UnitGUID("player")
	
	timerFrame:Show()
	
	self:RegisterEvent("PLAYER_PET_CHANGED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
	self:RegisterEvent("UNIT_SPELLCAST_START")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
	self:RegisterEvent("UNIT_SPELLCAST_STOP")
	self:RegisterEvent("UNIT_SPELLCAST_FAILED")
	self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	self:RegisterEvent("UNIT_SPELLCAST_DELAYED")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
	self:RegisterEvent("UNIT_SPELLCAST_CHANNEL_STOP")
	
	self:PLAYER_PET_CHANGED()
	self:PLAYER_TARGET_CHANGED()
end

function PitBull4_CastBar:OnDisable()
	timerFrame:Hide()
end

function PitBull4_CastBar:PLAYER_TARGET_CHANGED()
	target_guid = UnitGUID("target")
end

function PitBull4_CastBar:PLAYER_PET_CHANGED()
	pet_guid = UnitGUID("pet")
end

function PitBull4_CastBar:FixCastDataAndUpdateAll()
	self:UpdateInfoForGUID("player", player_guid)
	self:UpdateInfoForGUID("pet", pet_guid)
	self:UpdateInfoForGUID("target", target_guid)
	
	self:FixCastData()
	self:UpdateAll()
end

local new, del
do
	local pool = setmetatable({}, {__mode='k'})
	function new()
		local t = next(pool)
		if t then
			pool[t] = nil
			return t
		end
		
		return {}
	end
	function del(t)
		wipe(t)
		pool[t] = true
	end
end

function PitBull4_CastBar:GetValue(frame)
	local unit = frame.unit
	if frame.is_wacky or unit == "target" and unit == "focus" then
		self:UpdateInfo(nil, unit)
	end
	
	local guid = frame.guid
	local data = castData[guid]
	if not data then
		return 0
	end
	
	if data.casting then
		local startTime = data.startTime
		return (GetTime() - startTime) / (data.endTime - startTime)
	elseif data.channeling then	
		local endTime = data.endTime
		return (endTime - GetTime()) / (endTime - data.startTime)
	elseif data.fadeOut then
		return frame.CastBar and frame.CastBar:GetValue() or 0
	end
	return 0
end

function PitBull4_CastBar:GetExampleValue(frame)
	return 0.4
end

function PitBull4_CastBar:GetColor(frame, value)
	local guid = frame.guid
	local data = castData[guid]
	if not data then
		return 0, 0, 0, 0
	end
	
	if data.casting then
		return 0, 1, 0, 1
	elseif data.channeling then
		return 0, 1, 0, 1
	elseif data.fadeOut then
		local alpha
		local stopTime = data.stopTime
		if stopTime then
			alpha = stopTime - GetTime() + 1
		else
			alpha = 0
		end
		if alpha >= 1 then
			alpha = 1
		end
		if alpha <= 0 then
			castData[guid] = del(data)
			return 0, 0, 0, 0
		else
			return 0, 1, 0, alpha
		end
	else
		castData[guid] = del(data)
	end
	return 0, 0, 0, 0
end

function PitBull4_CastBar:UpdateInfoForGUID(unit, guid)
	if not guid then
		return
	end
	local data = castData[guid]
	if not data then
		data = new()
		castData[guid] = data
	end

	local spell, rank, displayName, icon, startTime, endTime = UnitCastingInfo(unit)
	local channeling = false
	if not spell then
		spell, rank, displayName, icon, startTime, endTime = UnitChannelInfo(unit)
		channeling = true
	end
	if spell then
		data.icon = icon
		data.startTime = startTime * 0.001
		data.endTime = endTime * 0.001
		data.casting = not channeling
		data.channeling = channeling
		data.fadeOut = false
		data.stopTime = nil
		return
	end

	if not data.icon then
		castData[guid] = del(data)
		return
	end

	data.casting = false
	data.channeling = false
	data.fadeOut = true
	if not data.stopTime then
		data.stopTime = GetTime()
	end
end

function PitBull4_CastBar:UpdateInfo(event, unit)
	self:UpdateInfoForGUID(unit, UnitGUID(unit))
end

function PitBull4_CastBar:FixCastData()
	local frame
	local currentTime = GetTime()
	for guid, data in pairs(castData) do
		local found = false
		for frame in PitBull4:IterateFramesForGUID(guid) do
			local castBar = frame.CastBar
			if castBar then
				found = true
				if data.casting then
					if currentTime > data.endTime and player_guid ~= guid then
						data.casting = false
						data.fadeOut = true
						data.stopTime = currentTime
					end
				elseif data.channeling then
					if currentTime > data.endTime then
						data.channeling = false
						data.fadeOut = true
						data.stopTime = currentTime
					end
				elseif data.fadeOut then
					local alpha = 0
					local stopTime = data.stopTime
					if stopTime then
						alpha = stopTime - currentTime + 1
					end
					
					if alpha <= 0 then
						castData[guid] = del(data)
					end
				else
					castData[guid] = del(data)
				end
			end	
			break
		end
		if not found then
			castData[guid] = del(data)
		end
	end
end

PitBull4_CastBar.UNIT_SPELLCAST_START = PitBull4_CastBar.UpdateInfo
PitBull4_CastBar.UNIT_SPELLCAST_CHANNEL_START = PitBull4_CastBar.UpdateInfo
PitBull4_CastBar.UNIT_SPELLCAST_STOP = PitBull4_CastBar.UpdateInfo
PitBull4_CastBar.UNIT_SPELLCAST_FAILED = PitBull4_CastBar.UpdateInfo
PitBull4_CastBar.UNIT_SPELLCAST_INTERRUPTED = PitBull4_CastBar.UpdateInfo
PitBull4_CastBar.UNIT_SPELLCAST_DELAYED = PitBull4_CastBar.UpdateInfo
PitBull4_CastBar.UNIT_SPELLCAST_CHANNEL_UPDATE = PitBull4_CastBar.UpdateInfo
PitBull4_CastBar.UNIT_SPELLCAST_CHANNEL_STOP = PitBull4_CastBar.UpdateInfo
