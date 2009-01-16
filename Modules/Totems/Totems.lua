if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass('player')) ~= "SHAMAN" then
	-- don't load if player is not a shaman.
	return
end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Totems requires PitBull4")
end

-- CONSTANTS ----------------------------------------------------------------
local MAX_TOTEMS = MAX_TOTEMS or 4 -- comes from blizzard's totem frame lua
local FIRE_TOTEM_SLOT  = FIRE_TOTEM_SLOT  or 1
local EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT or 2
local WATER_TOTEM_SLOT = WATER_TOTEM_SLOT or 3
local AIR_TOTEM_SLOT   = AIR_TOTEM_SLOT   or 4

local TOTEMSIZE = 50

local CFGMODE_ICON = [[Interface\Icons\Spell_Fire_TotemOfWrath]]

local _G = _G
local GetTime = _G.GetTime
local floor = _G.math.floor
local ceil = _G.math.ceil
local fmod = _G.math.fmod
local max = _G.math.max
local min = _G.math.min
local fmt = _G.string.format
local type = _G.type
local GetTotemTimeLeft = _G.GetTotemTimeLeft
local GetTotemInfo = _G.GetTotemInfo
-----------------------------------------------------------------------------



local PitBull4_Totems = PitBull4:NewModule("Totems", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
local self = PitBull4_Totems

--@alpha@
PBTDBG = PitBull4_Totems
--@end-alpha@

local border_path
do
	local path = "Interface\\AddOns\\" .. _G.debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z0-9]-%.lua")
	border_path = path .. "\\border"
end

-- Load LibSharedMedia
local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end
-- Register our default sound. (comes with the wow engine)
LibSharedMedia:Register('sound','Drop',"Sound\\interface\\DropOnGround.wav")

-- Fetch localization
local L = PitBull4.L

-- Register some metadata of ours with PB4
PitBull4_Totems:SetModuleType("custom_indicator")
PitBull4_Totems:SetName(L["Totems"])
PitBull4_Totems:SetDescription(L["Show which Totems are dropped and the time left until they expire."])



local function getVerboseSlotName(slot)
	if slot == FIRE_TOTEM_SLOT then
		return L["Fire"]
	elseif slot == EARTH_TOTEM_SLOT then
		return L["Earth"]
	elseif slot == WATER_TOTEM_SLOT then
		return L["Water"]
	elseif slot == AIR_TOTEM_SLOT then
		return L["Air"]
	else
		return L["Unknown Slot "]..tostring(slot)
	end
end

--------------------------------------------------------------------------------
-- this function is borrowed from Got Wood which got it from neronix. 
function PitBull4_Totems:SecondsToTimeAbbrev(time)
	local m, s
	if( time < 0 ) then
		text = ""
	elseif( time < 3600 ) then
		m = floor(time / 60)
		s = fmod(time, 60)
		if (m==0) then 
			text = fmt("0:%02d", s)
		else
			text = fmt("%01d:%02d", m, s)
		end
	end
	return text
end

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Configuration Proxyfunctions
--    lowercase g and l refer to Global and Layout Options
-------------------------------
---- General Purpose Proxies
local function gOptGet(key)
	if type(key) == 'table' then
		return self.db.profile.global[key[#key]]
	else
		return self.db.profile.global[key]
	end
end
local function gOptSet(key, value)
	if type(key) == 'table' then
		self.db.profile.global[key[#key]] = value
	else
		self.db.profile.global[key] = value
	end
end
local function cOptGet(key)
	if type(key) == 'table' then
		return unpack(self.db.profile.global.colors[key[#key]])
	else
		return unpack(self.db.profile.global.colors[key])
	end
end
local function cOptSet(key, r, g, b, a)
	if type(key) == 'table' then
		self.db.profile.global.colors[key[#key]] = {r, g, b, a} 
	else
		self.db.profile.global.colors[key] = {r, g, b, a} 
	end
end

local function lOptGet(frame,key)
	if type(key) == 'table' then
		return self:GetLayoutDB(frame)[key[#key]]
	else
		return self:GetLayoutDB(frame)[key]
	end
end
local function lOptSet(frame,key, value)
	if type(key) == 'table' then
		self:GetLayoutDB(frame)[key[#key]]  = value
	else
		self:GetLayoutDB(frame)[key] = value
	end
end


-------------------------------
---- Totem Order Proxies

local function getOrderDefault()
	-- usually 4 but this is dynamic incase blizzard adds a new totem-element in the future
	local order = {}
	for i=1, MAX_TOTEMS do
		order[i] = i
	end
	return order
end

local function getOrder(slot)
	return gOptGet('order')[slot]
end

local function getOrderAsString(info)
	local slot = info.arg
	return tostring(getOrder(slot))
end

local function getSlotFromOrder(pos)
	for k,v in ipairs(gOptGet('order')) do
		if v == pos then
			return k
		end
	end
	self:Print("ERROR: getSlotFromOrder failed to find slot for pos "..tostring(pos))
	return nil -- this shouldn't ever happen
end

local function listOrder(info)
	local slot = info.arg
	if not slot then
		local slot = -1
	end
	local choices = {}
	for i=1, MAX_TOTEMS do
		choices[tostring(i)] = fmt(L["Position %i (Currently: %s)"], i,getVerboseSlotName(getSlotFromOrder(i)))
	end
	return choices
end

local function setOrder(info, neworderposstring) -- global option
	local slot = info.arg
	local neworderpos = tonumber(neworderposstring)
	for i=1, MAX_TOTEMS do
		if not (i == slot) then
			if self.db.profile.global.order[i] == neworderpos then
				-- switch the position with the element that had it earlier
				self.db.profile.global.order[i] = getOrder(slot)
				self.db.profile.global.order[slot] = neworderpos
				break
			end
		end
	end
	for frame in PitBull4:IterateFramesForUnitID('player') do
		self:RealignTotems(frame)
	end
	return true
end

-------------------------------
---- Sound Proxies

local function getSoundNameForSlot(info)
	local slot = 1
	if type(info) == 'table' then
		slot = info.arg
	else
		slot = info
	end
	
	if self.db.profile.global.deathsoundpaths and self.db.profile.global.deathsoundpaths[slot] then
		return self.db.profile.global.deathsoundpaths[slot]
	else
		return false
	end
end

local function getSoundPathForSlot(slot)
	local chosen = getSoundNameForSlot(slot)
	if LibSharedMedia and chosen then
		return LibSharedMedia:Fetch('sound', chosen)
	else
		return false
	end
end
local function getSoundNumForSlot(info)
	local soundName = getSoundNameForSlot(info) or 'Drop'
	local lsmsounds = LibSharedMedia:List('sound')
	for i=1,#lsmsounds do
		if lsmsounds[i] == soundName then
			return i
		end
	end
	return 1
end
local function setSoundNumForSlot(info, pathnum)
	local slot = info.arg
	local path = LibSharedMedia:List('sound')[pathnum]
	if self.db.profile.global.deathsoundpaths then
		self.db.profile.global.deathsoundpaths[slot] = path
		PlaySoundFile(getSoundPathForSlot(slot))
	end
end

local function getSoundpathsDefault()
	local dsf = {}
	for i=1, MAX_TOTEMS do
		dsf[i] = "Drop"
	end
	return dsf
end


--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Totem Logic

-- Wrapper function to simulate totems most accurately when configmode is enabled.
local function MyGetTotemTimeLeft(slot, frame)
	if not frame.force_show then return GetTotemTimeLeft(slot) end
	
	-- Config mode is on, simulate some time.
	return 10*slot
end
-- Wrapper function to simulate totems most accurately when configmode is enabled.
local function MyGetTotemInfo(slot, frame)
	if not frame.force_show then return GetTotemInfo(slot) end
	
	-- Config mode on, simulate some fake totem info
	local fakeLeft = MyGetTotemTimeLeft(slot, frame)
	return true,
		"Fake Totem",
		ceil(GetTime()),
		119,
		CFGMODE_ICON
	
end

function PitBull4_Totems:OneOrMoreDown()
	for i=1, MAX_TOTEMS do
		if ( self.totemIsDown[i] == true ) then
			return true
		end
	end
	-- none is down
	return false
end

function PitBull4_Totems:StartTimer()
	if not self.timerhandle then
		self.timerhandle = self:ScheduleRepeatingTimer(function() PitBull4_Totems:UpdateAllTimes() end, 0.25)
	end
end

function PitBull4_Totems:StopTimer()
	if self.timerhandle then
		self:CancelTimer(self.timerhandle)
		self.timerhandle = nil
	end
end

function PitBull4_Totems:StartPulse(frame) -- starts a continuous pulse
	frame.pulseStopAfterThis = false
	frame.pulseStart = true
	frame.lastUpdated = 0
	if frame:GetScript("OnUpdate") == nil then
		frame:SetScript("OnUpdate", self.ButtonOnUpdate)
	end
end

function PitBull4_Totems:StartPulseOnce(frame) -- starts a single pulse
	frame.pulseStopAfterThis = true
	frame.pulseStart = true
	frame.lastUpdated = 0
	if frame:GetScript("OnUpdate") == nil then
		frame:SetScript("OnUpdate", self.ButtonOnUpdate)
	end
end

function PitBull4_Totems:StopPulse(frame)
	frame.pulseStopAfterThis = false
	frame.pulseStart = false
	frame.pulseActive = false
	if frame.pulse.icon:IsVisible() then
		frame.pulse.icon:Hide()
	end
	frame.lastUpdated = 0
	if frame:GetScript("OnUpdate") ~= nil then
		frame:SetScript("OnUpdate", nil)
	end
end


function PitBull4_Totems:UpdateAllTimes()
	local mf = nil
	for frame in PitBull4:IterateFramesForUnitID('player') do
		mf = frame
		if (not mf) or (not mf.Totems) or (not mf.Totems.elements) then
			self:Print("ERROR: Update time called but no Totemtimer Frame initialized.")
			--self:StopTimer()
			--return
		else 
			local elements = mf.Totems.elements
			
			local nowTime = floor(GetTime())
			for slot=1, MAX_TOTEMS do
				if (not elements) or (not elements[slot]) or (not elements[slot].frame) then return end
				
				local timeleft = MyGetTotemTimeLeft(slot,mf)
				
				if timeleft > 0 then
					-- need to update shown time
					if ( lOptGet(frame,'timertext') ) then
						elements[slot].text:SetText(self:SecondsToTimeAbbrev(timeleft))
					else
						elements[slot].text:SetText("")
					end
					-- Hide the cooldown frame if it's shown and the user changed preference
					if ( not lOptGet(frame,'timerspiral') and elements[slot].spiral:IsShown() ) then
						elements[slot].spiral:Hide()
					end
					
					if gOptGet('expirypulse') and (timeleft < gOptGet('expirypulsetime')) and (timeleft > 0) then
						self:StartPulse(elements[slot].frame)
					else
						self:StopPulse(elements[slot].frame)
					end
				else
					-- Totem expired
					
					self:StopPulse(elements[slot].frame)
					elements[slot].frame:SetAlpha(0.5)
					if lOptGet(frame,'hideinactive') then
						elements[slot].frame:Hide()
					end
					elements[slot].text:SetText("")
					elements[slot].spiral:Hide()
				end
			end
		end
	end
end

function PitBull4_Totems:SpiralUpdate(frame,slot,start,left)
	if not frame.Totems then return end
	local tspiral = frame.Totems.elements[slot].spiral
	local startTime = start or select(3, MyGetTotemInfo(slot,frame))
	local timeLeft = left or MyGetTotemTimeLeft(slot,frame)

	tspiral:SetCooldown(startTime, timeLeft)
	if self.totemIsDown[slot] == true and lOptGet(frame,'timerspiral') then
		tspiral:Show()
	else
		tspiral:Hide()
	end
end


function PitBull4_Totems:ActivateTotem(slot)
	for frame in PitBull4:IterateFramesForUnitID('player') do
		if not frame.Totems then
			return
		end
		
		local haveTotem, name, startTime, duration, icon = MyGetTotemInfo(slot, frame)
		-- queried seperately because GetTotemInfo apprears to give less reliable results (wtf?!)
		local timeleft = MyGetTotemTimeLeft(slot, frame)
	
		if ( name == "" ) then
			self:Print("WARNING: Can't activate a nondropped totem")
			return
		end
	
		self.totemIsDown[slot] = true

		local tframe = frame.Totems.elements[slot].frame
		local ttext = frame.Totems.elements[slot].text
		
		tframe:SetNormalTexture(icon)
		tframe.totemIcon = icon
		tframe:SetAlpha(1)
		tframe:Show()
		tframe.force_show = frame.force_show
		
		self:StopPulse(tframe)
		
		tframe.border:Show()
		if ( lOptGet(frame,'timertext') ) then
			ttext:SetText(self:SecondsToTimeAbbrev(timeleft))
		end
		self:SpiralUpdate(frame, slot, startTime, timeLeft)
		
		self:StartTimer()
	end
end

function PitBull4_Totems:DeactivateTotem(slot)
	for frame in PitBull4:IterateFramesForUnitID('player') do
		if not frame.Totems then
			return
		end

		local haveTotem, name, startTime, duration, icon = MyGetTotemInfo(slot, frame)
	
		if ( name ~= "" ) then
			self:Print("WARNING: Can't deactivate a dropped totem")
			return
		end
	
		self.totemIsDown[slot] = false
		
		local tframe = frame.Totems.elements[slot].frame
		local ttext = frame.Totems.elements[slot].text
		local tspiral = frame.Totems.elements[slot].spiral
		
		-- cleanup timer event if no totems are down
		if not self:OneOrMoreDown() then
			self:StopTimer()
		end
		tspiral:Hide()
		
		self:StopPulse(tframe)
		
		tframe:SetAlpha(0.5)
		if lOptGet(frame,'hideinactive') then
			tframe:Hide()
		end
		ttext:SetText("")
	end
end

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Frame functions

-- This function is a hack and wants to be replaced by a proper solution to ticket:
-- http://www.wowace.com/projects/pitbull4/tickets/14-make-get-font-available-to-custom_frame-modules/
local DEFAULT_FONT, DEFAULT_FONT_SIZE = ChatFontNormal:GetFont()
function PitBull4_Totems:myGetFont(frame)
	local db = self:GetLayoutDB(frame)
	local font
	if LibSharedMedia then
		font = LibSharedMedia:Fetch("font", db.font or PitBull4.db.profile.layouts[frame.layout].font or "")
	end
	
	return font or DEFAULT_FONT, DEFAULT_FONT_SIZE * db.size
end

function PitBull4_Totems:ResizeMainFrame(frame)
	if not frame.Totems then
		return
	end
	local tSpacing = lOptGet(frame,'totemspacing')
	local lbreak = lOptGet(frame,'linebreak')
	local nlines = ceil(MAX_TOTEMS / lbreak)
	local ttf = frame.Totems
	local width = nil
	local height = nil
	if (lOptGet(frame,'totemdirection') == "h") then
		width = (lbreak*TOTEMSIZE)+((lbreak-1)*tSpacing)
		height = (nlines*TOTEMSIZE)+((nlines-1)*tSpacing)
		ttf.height = nlines + ((nlines-1)*(tSpacing/TOTEMSIZE))
	else
		width = (nlines*TOTEMSIZE)+((nlines-1)*tSpacing) 
		height = (lbreak*TOTEMSIZE)+((lbreak-1)*tSpacing)
		ttf.height = lbreak + ((lbreak-1)*(tSpacing/TOTEMSIZE))
	end
	ttf:SetWidth(width)
	ttf:SetHeight(height)
end

function PitBull4_Totems:RealignTotems(frame)
	local lbreak = lOptGet(frame,'linebreak') or MAX_TOTEMS
	local tspacing = lOptGet(frame,'totemspacing') or 0

	if frame.Totems then
		local elements = frame.Totems.elements
		for i=1, MAX_TOTEMS do
			local o = getSlotFromOrder(i)
			
			
			if (not o) then
				return
			end
			
			if i==1 then
				elements[o].frame:ClearAllPoints()
				elements[o].frame:SetPoint("TOPLEFT", frame.Totems, "TOPLEFT", 0, 0)
			else
				elements[o].frame:ClearAllPoints()
				-- Attach the button to the previous one
				if (lOptGet(frame,'totemdirection') == "h") then
					-- grow horizontally
					if (fmod(i - 1, lbreak) == 0) then
						-- Reached a linebreak
						local o3 = getSlotFromOrder(i-lbreak)
						elements[o].frame:SetPoint("TOPLEFT", elements[o3].frame, "BOTTOMLEFT", 0, 0-tspacing)
					else
						local o2 = getSlotFromOrder(i-1)
						elements[o].frame:SetPoint("TOPLEFT", elements[o2].frame, "TOPRIGHT", tspacing, 0)
					end
				else
					--grow vertically
					if (fmod(i - 1, lbreak) == 0) then
						local o3 = getSlotFromOrder(i-lbreak)
						elements[o].frame:SetPoint("TOPLEFT", elements[o3].frame, "TOPRIGHT", tspacing, 0)
					else
						local o2 = getSlotFromOrder(i-1)
						elements[o].frame:SetPoint("TOPLEFT", elements[o2].frame, "BOTTOMLEFT", 0, 0-tspacing)
					end
				end
			end
		end
		self:RealignTimerTexts(frame)
	end
end

local function TimerTextAlignmentLogic(frame, parent, side, offsetX, offsetY) 
	if ((not frame) or (not parent)) then
		return
	end
	
	local offX = offsetX or 0
	local offY = offsetY or 0
	frame:ClearAllPoints()
	if side == "topinside" then
		frame:SetPoint("TOP", parent, "TOP", offX, offY)
	elseif side == "topoutside" then
		frame:SetPoint("BOTTOM", parent, "TOP", offX, offY)
	elseif side == "bottominside" then
		frame:SetPoint("BOTTOM", parent, "BOTTOM", offX, offY)
	elseif side == "bottomoutside" then
		frame:SetPoint("TOP", parent, "BOTTOM", offX, offY)
	elseif side == "leftoutside" then
		frame:SetPoint("RIGHT", parent, "LEFT", offX, offY)
	elseif side == "rightoutside" then
		frame:SetPoint("LEFT", parent, "RIGHT", offX, offY)
	elseif side == "middle" then
		frame:SetPoint("CENTER", parent, "CENTER", offX, offY)
	else
		return
	end
	
end

function PitBull4_Totems:RealignTimerTexts(frame)
	if not frame or not frame.Totems then return end

	local elements = frame.Totems.elements
	for i=1, MAX_TOTEMS do
		if (elements[i].text) then
			TimerTextAlignmentLogic(elements[i].text, elements[i].textFrame, lOptGet(frame, 'timertextside'), 0, 0)
			local font, fontsize = self:myGetFont(frame)
			elements[i].text:SetFont(font, fontsize * lOptGet(frame,'timertextscale'), "OUTLINE")

			elements[i].text:SetTextColor(cOptGet('timertext'))
		end
	end
end

function PitBull4_Totems:UpdateIconColor(frame)
	if frame.Totems and frame.Totems.elements then
		local elements = frame.Totems.elements
		for i=1, MAX_TOTEMS do
			if elements[i].frame and elements[i].frame.border then
				elements[i].frame.border:Hide()
				elements[i].frame.border:SetVertexColor(cOptGet('totemborder'))
				elements[i].frame.border:Show()
			end
		end
	end
end

function PitBull4_Totems:ButtonOnClick(mousebutton)
	if (mousebutton == "RightButton" and this.slot and not this.force_show) then
		DestroyTotem( this.slot )
	end
end

function PitBull4_Totems:ButtonOnEnter()
	if this.force_show then return end
	if ( this.slot and gOptGet('totemtooltips') ) then
		-- setting the tooltip
		GameTooltip_SetDefaultAnchor(GameTooltip, this)
		GameTooltip:SetTotem(this.slot)
	end
end

function PitBull4_Totems:ButtonOnLeave()
	if this.force_show then return end
	if ( gOptGet('totemtooltips') ) then
		-- hiding the tooltip
		GameTooltip:Hide()
	end
end

-- inline credits: Parts of the following function were heavily inspired by the addon CooldownButtons by Dodge (permission given)
function PitBull4_Totems:ButtonOnUpdate(elapsed)
	if not this:IsVisible() then 
		return -- nothing to do when we aren't visible
	end
	
	if this.lastUpdate > elapsed then
		this.lastUpdate = this.lastUpdate - elapsed
		return
	else
		this.lastUpdate = 0.75
	end

	-- start a pulse if it isn't active yet, if it is, do the animation as normal
	if this.pulseStart then
		this.pulse.icon:Hide()
		this.lastUpdate = 0
		if not this.pulseActive then
			-- Pulse isn't active yet so we start it
			local icon = this.texture
			if this:IsVisible() then
				local pulse = this.pulse
				if pulse then
					pulse.scale = 1
					pulse.icon:SetTexture(this.totemIcon)
					this.pulseActive = true
					--PitBull:Print(fmt("DEBUG: Starting pulse on slot %i, elapsed is: %s", this.slot, tostring(elapsed)))
				end
			end
		else
			-- Pulse is already active, do the animation...
			local pulse = this.pulse
			if pulse.scale >= 2 then
				pulse.dec = 1
			elseif pulse.scale <= 1 then
				pulse.dec = nil
			end
			pulse.scale = max(min(pulse.scale + (pulse.dec and -1 or 1) * pulse.scale * (elapsed/0.5), 2), 1)
			
			
			if this.pulseStopAfterThis and pulse.scale <= 1 then
				-- Pulse animation is to be stopped now.
				pulse.icon:Hide()
				pulse.dec = nil
				this.pulseActive = false
				this.pulseStart = false
				this.pulseStopAfterThis = false

				if this.hideinactive then
					this:Hide()
				end
				
				--self:Print(fmt("DEBUG: Stopping pulse on slot %i", this.slot))
			else
				-- Applying the new scaling (animation frame)
				--self:Print(fmt("DEBUG: Showing with scale %s", tostring(pulse.scale)))
				pulse.icon:Show()
				pulse.icon:SetHeight(pulse:GetHeight() * pulse.scale)
				pulse.icon:SetWidth(pulse:GetWidth() * pulse.scale)
			end
		end
		
	end
end




function PitBull4_Totems:PLAYER_TOTEM_UPDATE(event, slot)
	local sSlot = tostring(slot)

	for frame in PitBull4:IterateFramesForUnitID('player') do
		local haveTotem, name, startTime, duration, icon = MyGetTotemInfo(slot,frame)
		if ( haveTotem and name ~= "") then
			-- New totem created
			self:ActivateTotem(slot)
		elseif ( haveTotem ) then
			-- Totem just got removed or killed.
			self:DeactivateTotem(slot)
			
			-- Sound functions
			if gOptGet('deathsound') and getSoundNameForSlot(slot) and not (event == nil) then
				--self:Print(string.format('DEBUG: Playing Death sound for slot %s: %s', tostring(slot), tostring(getSoundPathForSlot(slot))))
				PlaySoundFile(getSoundPathForSlot(slot))
			end
		end
	end
end

function PitBull4_Totems:ForceSilentTotemUpdate()
	for i=1, MAX_TOTEMS do
		self:PLAYER_TOTEM_UPDATE(nil, i) -- we intentionally send a nil event (to avoid sounds)
	end
end

function PitBull4_Totems:PLAYER_ENTERING_WORLD(...)
	-- we simulate totem events whenever a player zones to make sure totems left back in the instance hide properly.
	self:ForceSilentTotemUpdate()
end

function PitBull4_Totems:BuildFrames(frame)
	if not frame then return end -- not enough legit parameters
	if frame.Totems then return end -- Can't create the frames when they already exist..

	local font, fontsize = self:myGetFont(frame)
	local tSpacing = lOptGet(frame,'totemspacing')
	
	-- Main frame
	
	frame.Totems = PitBull4.Controls.MakeFrame(frame)
	local ttf = frame.Totems

	if (lOptGet(frame,'totemdirection') == "h") then
		ttf:SetWidth((MAX_TOTEMS*TOTEMSIZE)+((MAX_TOTEMS-1)*tSpacing))
		ttf:SetHeight(TOTEMSIZE)
	else
		ttf:SetWidth(TOTEMSIZE)
		ttf:SetHeight((MAX_TOTEMS*TOTEMSIZE)+((MAX_TOTEMS-1)*tSpacing))
	end
	ttf:Show()
	
	-- Main background
	if not ttf.background then
		ttf.background = PitBull4.Controls.MakeTexture(ttf, "BACKGROUND")
	end
	local bg = ttf.background
	bg:SetTexture(cOptGet('mainbg'))
	bg:SetAllPoints(ttf)
	
	-- Now create the main timer frames for each totem element
	local elements = {}
	for i=1, MAX_TOTEMS do
		-------------------------------
		-- Main totem slot frame
		elements[i] = {}
		if not elements[i].frame then
			elements[i].frame = PitBull4.Controls.MakeTTButton(ttf)
		end
		local frm = elements[i].frame
		
		frm:SetWidth(TOTEMSIZE)
		frm:SetHeight(TOTEMSIZE)
		frm:Hide()
		frm.slot = i
		frm.hideinactive = lOptGet(frame,'hideinactive')
		
		-------------------------------
		-- totem slot border frame
		if not frm.border then
			frm.border = PitBull4.Controls.MakeTexture(frm, "OVERLAY")
		end
		local border = frm.border
		border:SetAlpha(1)
		border:ClearAllPoints()
		border:SetAllPoints(frm)
		border:SetTexture(border_path)
		border:SetVertexColor(cOptGet('totemborder'))
		border:Show()
		
		----------------------------
		-- Spiral cooldown frame
		if not elements[i].spiral then
			elements[i].spiral = PitBull4.Controls.MakeTTCooldown(frm)
		end
		local spiral = elements[i].spiral
		spiral:SetReverse(true)
		spiral:SetAllPoints(frm)
		if ( lOptGet(frame,'suppressocc') ) then
			-- user wishes to suppress omnicc on his timer spiral, requires recent (post-2.4) omnicc version!
			if OMNICC_VERSION and OMNICC_VERSION < 210 then
				spiral.noomnicc = true
			else
				spiral.noCooldownCount = true
			end
		end
		
		--------------------
		-- Text frame
		if not elements[i].textFrame then
			elements[i].textFrame = PitBull4.Controls.MakeFrame(frame)
		end
		local textFrame = elements[i].textFrame
		textFrame:SetAllPoints(frm)
		textFrame:SetFrameLevel(spiral:GetFrameLevel() + 7)
		
		if not elements[i].text then
			elements[i].text = PitBull4.Controls.MakeFontString(textFrame, "OVERLAY")
		end
		local text = elements[i].text
		text:ClearAllPoints()
		text:SetPoint("BOTTOM", textFrame, "BOTTOM", 0, 0)
		text:SetFont(font, fontsize * lOptGet(frame,'timertextscale'), "OUTLINE")
		text:SetShadowColor(0,0,0,1)
		text:SetShadowOffset(0.8, -0.8)
		text:SetTextColor(cOptGet('timertext'))
		text:Show()
		
		--------------------
		-- Pulse frame
		if not frm.pulse then
			frm.pulse = PitBull4.Controls.MakeFrame(frm)
		end
		local pulse = frm.pulse
		pulse:SetAllPoints(frm)
		pulse:SetToplevel(true)
		pulse.icon = PitBull4.Controls.MakeTexture(frm, "OVERLAY")
		pulse.icon:SetPoint("CENTER")
		pulse.icon:SetBlendMode("ADD")
		pulse.icon:SetVertexColor(0.5,0.5,0.5,0.7)
		pulse.icon:SetHeight(frm:GetHeight())
		pulse.icon:SetWidth(frm:GetWidth())
		pulse.icon:Hide()
		frm.pulseActive = false
		frm.pulseStart = false
		
		
		-----------------
		-- Click handling
		-- click handling for destroying single totems
		frm:RegisterForClicks("RightButtonUp")
		frm:SetScript("OnClick", self.ButtonOnClick)
		-- tooltip handling
		frm:SetScript("OnEnter", self.ButtonOnEnter)
		frm:SetScript("OnLeave", self.ButtonOnLeave)
		frm.lastUpdate = 1
		frm:SetScript("OnUpdate", self.ButtonOnUpdate)
	end
	
	ttf.elements = elements
	
	self:ResizeMainFrame(frame)
	self:RealignTotems(frame)
end

function PitBull4_Totems:ApplyLayoutSettings(frame)
	if not frame or not frame.Totems then return end

	local elements = frame.Totems.elements

	for i=1, MAX_TOTEMS do
		elements[i].frame:SetHeight(TOTEMSIZE)
		elements[i].frame:SetWidth(TOTEMSIZE)
		elements[i].text:SetWidth(TOTEMSIZE)
		elements[i].text:SetHeight(TOTEMSIZE/3)

		elements[i].frame.hideinactive = lOptGet(frame,'hideinactive')
		
		self:SpiralUpdate(frame, i, nil, nil)
	end


	self:ResizeMainFrame(frame)
	
	-- Background color of the main frame
	frame.Totems.background:SetTexture(cOptGet('mainbg'))
	
	-- Bordercolor of the buttons
	self:UpdateIconColor(frame)

	-- Update timertext settings
	self:RealignTimerTexts(frame)
end

function PitBull4_Totems:UpdateFrame(frame)
	if frame.unit ~= 'player' then return end -- we only work for the player unit itself
	
	--self:Print('DBG: UpdateFrame called.')
	
	if (lOptGet(frame,'enabled') ~= true) and frame.Totems then
		return self:ClearFrame(frame)
	end
	
	if frame.Totems then
		-- make sure the timer is still running (it gets deactivated if the frame is gone for a moment)
		self:StartTimer()
		
		-- Now rebuild most of the layout since some setting might have changed.
		self:RealignTotems(frame)
		self:ApplyLayoutSettings(frame)
		self:ForceSilentTotemUpdate()
		return false -- our frame exists already, nothing more to do...
	else
		self:BuildFrames(frame)
		self:ForceSilentTotemUpdate()
	end
	
	return true
end



function PitBull4_Totems:ClearFrame(frame)
	if not frame.Totems then
		return false
	end
	
	self:StopTimer()
	
	--cleanup the element frames
	for i=1, MAX_TOTEMS do
		local element = frame.Totems.elements[i]
		
		if element.pulse then
			element.pulse = element.pulse:Delete()
		end
		if element.text then
			element.text = element.text:Delete()
		end
		if element.textFrame then
			element.textFrame = element.textFrame:Delete()
		end
		if element.spiral then
			element.spiral = element.spiral:Delete()
		end
		if element.border then
			element.border = element.border:Delete()
		end
		if element.frame then
			element.frame = element.frame:Delete()
		end
	end
	
	frame.Totems.background = frame.Totems.background:Delete()
	frame.Totems = frame.Totems:Delete()
	
	return true
end

function PitBull4_Totems:OnEnable()
	self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function PitBull4_Totems:OnInitialize()
	-- Initialize Timer variables
	self.totemIsDown = {}
	for i=1,MAX_TOTEMS do
		self.totemIsDown[i] = false
	end
	
	self.timerhandle = nil
	self.borderpath = border_path
	
	-- Define new control type for our main element buttons
	PitBull4.Controls.MakeNewControlType("TTButton", "Button", function(control) end, function(control) end, function(control) end)
	PitBull4.Controls.MakeNewControlType("TTCooldown", "Cooldown", function(control) end, function(control) end, function(control) end)
	
end

local color_defaults = {
	mainbg = {0, 0, 0, 0.5},
	timertext = {0, 1, 0, 1},
	totemborder = {0, 0, 0, 0.5},
}

PitBull4_Totems:SetDefaults({
	attach_to = "root",
	location = "out_top_left",
	position = 1,
	size = 2, -- default to a 200% scaling, the 100% seems way too tiny.
	tlo1 = true, -- dummy for optiontests
	totemspacing = 0,
	totemdirection = "h",
	timerspiral = true,
	suppressocc = true,
	timertext = true,
	timertextside = "bottominside",
	timertextscale = 0.45,
	linebreak = MAX_TOTEMS,
	hideinactive = false,
}, {
	totemtooltips = true,
	order = getOrderDefault(), -- this is the order _by_slot_ not by position!
	expirypulse = true,
	expirypulsetime = 5,
	recastenabled = false,
	deathsound = false,
	deathsoundpaths = getSoundpathsDefault(),
	colors = color_defaults,
})

PitBull4_Totems:SetLayoutOptionsFunction(function(self)
	local function get(info)
		local id = info[#info]
		return PitBull4.Options.GetLayoutDB(self)[id]
	end
	local function set(info, value)
		local id = info[#info]
		PitBull4.Options.GetLayoutDB(self)[id] = value
		PitBull4.Options.UpdateFrames()
	end
	local function is_pbt_disabled(info)
		return not PitBull4.Options.GetLayoutDB(self).enabled
	end


	return 'totemspacing', {
		type = 'range',
		name = L["Totem Spacing"],
		desc = L["Sets the size of the gap between the totem icons."],
		min = 0,
		max = 100,
		step = 1,
		get = get,
		set = set,
		disabled = is_pbt_disabled,
		order = 12,
	},
	'totemdirection', {
		type = 'select',
		name = L["Totem Direction"],
		desc = L["Choose wether to grow horizontally or vertically."],
		get = get,
		set = set,
		values = {
			["h"] = L["Horizontal"],
			["v"] = L["Vertical"]
		},
		style = "radio",
		disabled = is_pbt_disabled,
		order = 13,
	},
	'linebreak', {
		type = 'range',
		name = L["Totems per line"],
		desc = L["How many totems to draw per line."],
		min = 1,
		max = MAX_TOTEMS,
		step = 1,
		get = get,
		set = set,
		disabled = is_pbt_disabled,
		order = 14,
	},
	'hideinactive', {
		type = 'toggle',
		name = L["Hide inactive"],
		desc = L["Hides inactive totem icons completely."],
		get = get,
		set = set,
		disabled = is_pbt_disabled,
		order = 15,
	},
	'grptimerspiral', {
		type = 'group',
		name = L["Spiral Timer"],
		desc = L["Options relating to the spiral display timer."],
		inline = true,
		order = 18,
		disabled = is_pbt_disabled,
		args = {
			timerspiral = {
				type = 'toggle',
				name = L["Enabled"],
				desc = L["Shows the pie-like cooldown spiral on the icons."],
				get = get,
				set = set,
				width = 'full',
				disabled = is_pbt_disabled,
				order = 1,
			},
			suppressocc = {
				type = 'toggle',
				name = L["Suppress Cooldown Counts"],
				desc = L["Tries to suppress CooldownCount-like addons on the spiral timer. (Requires UI reload to change the setting!)"],
				get = get,
				set = set,
				width = 'full',
				disabled = function() return not get({'timerspiral'}) or is_pbt_disabled() end,
				order = 2,
			},
		},
	},
	'grptimertext', {
		type = 'group',
		name = L["Text Timer"],
		desc = L["Options relating to the text display timer."],
		inline = true,
		order = 19,
		disabled = is_pbt_disabled,
		args = {
			timertext = {
				type = 'toggle',
				name = L["Enabled"],
				desc = L["Shows the remaining time in as text."],
				get = get,
				set = set,
				order = 1,
				width = 'full',
				disabled = is_pbt_disabled,
			},
			timertextside = {
				type = 'select',
				name = L["Location"],
				desc = L["What location to position the timer text at."],
				values = {
					topinside = L["Top, Inside"],
					topoutside = L["Top, Outside"],
					bottominside = L["Bottom, Inside"],
					bottomoutside = L["Bottom, Outside"],
					leftoutside = L["Left, Outside"],
					rightoutside = L["Right, Outside"],
					middle = L["Middle"],
				},
				get = get,
				set = set,
				disabled = function() return not get({'timertext'}) or is_pbt_disabled()  end,
				order = 3,
			},
			timertextscale = {
				type = 'range',
				name = L["Scale"],
				desc = L["Change the scaling of the text timer. Note: It's relative to PitBull's font size."],
				min = 0.1,
				max = 2,
				step = 0.01,
				get = get,
				set = set,
				disabled = function() return not get({'timertext'}) or is_pbt_disabled()  end,
				order = 4,
			},
		}
	},
	'globnoticehdr', {
		type = 'header',
		name = L["Did you know?"],
		order = 30,
	},
	'globnoticedesc', {
		type = 'description',
		name = L["There are more options for this module in the Modules -> Totems section."],
		order = 31,
	}
end)

local function getOrderOptionGroup()
	local oo = {}
	oo['orderdesc'] = {
		type = 'description',
		name = L["Define your preferred order in which the lements will be displayed. The numbers describe positions from left to right."],
		order = 1,
	}
	for i=1, MAX_TOTEMS do
		local verboseName = getVerboseSlotName(i)
		local slot = { 
			type = 'select',
			style = 'dropdown',
			width = 'full',
			name = verboseName,
			desc = verboseName,
			values = listOrder,
			get = getOrderAsString,
			set = setOrder,
			arg = i,
			order = 10+i,
			--disabled = getHide,
		}
		oo["slot"..tostring(i)] = slot
	end
	return oo
end

local function getSoundOptionGroup()
	local so = {}
	so['deathsound'] = {
		type = 'toggle',
		name = L["Totemsounds"],
		desc = L["This plays a sound file when a totem expires or gets destroyed. Individual sounds can be set per element."],
		get = gOptGet,
		set = gOptSet,
		order = 1,
	}
	for i=1, MAX_TOTEMS do
		local verboseName = getVerboseSlotName(i)
		local slot = { 
			name = verboseName,
			desc = verboseName,
			type = 'select',
			width = 'full',
			values = LibSharedMedia:List('sound'),
			get = getSoundNumForSlot,
			set = setSoundNumForSlot,
			arg = i,
			disabled = function() return not gOptGet('deathsound') end,
			order = 10 + i,
		}
		so["soundslot"..tostring(i)] = slot
	end
	return so
end

PitBull4_Totems:SetGlobalOptionsFunction(function(self)
	return 'layoutnoticehdr', {
		type = 'header',
		name = L["Did you know?"],
		order = 128,
		width = 'full',
	},
	'layoutnoticedesc', {
		type = 'description',
		name = L["There are more options for this module in the Layout editor -> Indicators -> Totems section."],
		order = 129,
		width = 'full',
	},
	'totemtooltips', {
		type = 'toggle',
		width = 'full',
		name = L["Totem Tooltips"],
		desc = L["Enables tooltips when hovering over the icons."],
		get = gOptGet,
		set = gOptSet,
		order = 110,
	},
	'grppulse', {
		type = 'group',
		name = L["Pulsing"],
		desc = L["Options related to the pulsing visualisation."],
		order = 111,
		inline = true,
		args = {
			expirypulse = {
				type = 'toggle',
				width = 'full',
				name = L["Expiry pulse"],
				desc = L["Causes the icon to pulse in the last few seconds of its lifetime."],
				get = gOptGet,
				set = gOptSet,
				order = 10,
			},
			expirypulsetime = {
				type = 'range',
				width = 'full',
				name = L["Expiry time"],
				desc = L["Pulse for this many seconds before the totem runs out."],
				min = 0.5,
				max = 60,
				step = 0.5,
				get = gOptGet,
				set = gOptSet,
				order = 11,
				disabled = function() return not gOptGet('expirypulse') end
			},
		},
	},

	'grptotemorder', {
		type = 'group',
		name = L["Order"],
		desc = L["The order in which the elements appear."],
		order = 113,
		inline = true,
		args = getOrderOptionGroup(),
	},
	'grptotemsound', {
		type = 'group',
		name = L["Sounds"],
		desc = L["Options relating to sound effects on totem events."],
		order = 114,
		inline = true,
		args = getSoundOptionGroup(),
	} 
end)

PitBull4_Totems:SetColorOptionsFunction(function(self)
	local function get(info)
		local id = info[#info]
		return unpack(self.db.profile.global.colors[id])
	end
	local function set(info, r, g, b, a)
		local id = info[#info]
		self.db.profile.global.colors[id] = {r, g, b, a} 
		self:UpdateAll()
	end
	return 'colgrpframes', {
		type = 'group',
		name = L["Frames"],
		inline = true,
		args = {
			mainbg = {
				type = 'color',
				name = L["Main Background"],
				desc = L["Sets the color and transparency of the background of the timers."],
				hasAlpha = true,
				get = get,
				set = set,
				width = 'full',
				order = 1
			},
			totemborder = {
				type = 'color',
				name = L["Icon Border"],
				desc = L["Sets the color of the individual iconborders."],
				hasAlpha = true,
				get = get,
				set = set,
				width = 'full',
				order = 2
			}
		}
	},
	'colgrptimertext', {
		type = 'group',
		name = L["Text Timer"],
		inline = true,
		args = {
			timertext = {
				type = 'color',
				name = L["Text"],
				desc = L["Color of the timer text."],
				hasAlpha = true,
				get = get,
				set = set,
				width = 'full',
				order = 1
			},
		}
	}, function(info)
		local db = self.db.profile.global.colors
		for setting,value in pairs(color_defaults) do
			if type(value) == "table" then
				for i = 1, #value do
					db[setting][i] = value[i]
				end
			else
				db[setting] = value
			end
		end
		-- update frames...
		self:UpdateAll()
	end
end)

