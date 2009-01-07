if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass('player')) ~= "SHAMAN" then
	-- don't load if player is not a shaman.
	return
end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_TotemTimers requires PitBull4")
end

-- CONSTANTS ----------------------------------------------------------------
local MAX_TOTEMS = MAX_TOTEMS or 4 -- comes from blizzard's totem frame lua
local FIRE_TOTEM_SLOT  = FIRE_TOTEM_SLOT  or 1
local EARTH_TOTEM_SLOT = EARTH_TOTEM_SLOT or 2
local WATER_TOTEM_SLOT = WATER_TOTEM_SLOT or 3
local AIR_TOTEM_SLOT   = AIR_TOTEM_SLOT   or 4

local _G = _G
local GetTime = _G.GetTime
local floor = math.floor
local ceil = math.ceil
local fmod = math.fmod
local max = math.max
local min = math.min
local fmt = string.format
local type = type
local GetTotemTimeLeft = GetTotemTimeLeft
local GetTotemInfo = GetTotemInfo
-----------------------------------------------------------------------------



local PitBull4_TotemTimers = PitBull4:NewModule("TotemTimers", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0")
local self = PitBull4_TotemTimers

--@alpha@
PBTTDBG = PitBull4_TotemTimers
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
PitBull4_TotemTimers:SetModuleType("custom_indicator")
PitBull4_TotemTimers:SetName(L["Totem Timers"])
PitBull4_TotemTimers:SetDescription(L["Show which Totems are dropped and the time left until they expire."])



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


function PitBull4_TotemTimers:OnEnable()
	self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

--------------------------------------------------------------------------------
-- this function is borrowed from Got Wood which got it from neronix. 
function PitBull4_TotemTimers:SecondsToTimeAbbrev(time)
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
local function lOptGet(key)
	if type(key) == 'table' then
		return PitBull4.Options.GetLayoutDB("TotemTimers")[key[#key]]
	else
		return PitBull4.Options.GetLayoutDB("TotemTimers")[key]
	end
end
local function lOptSet(key, value)
	if type(key) == 'table' then
		PitBull4.Options.GetLayoutDB("TotemTimers")[key[#key]] = value
	else
		PitBull4.Options.GetLayoutDB("TotemTimers")[key] = value
	end
end
local function lOptGetColor(key)
	return unpack(lOptGet(key))
end
local function lOptSetColor(key, r, g, b, a)
	lOptSet(key, {r, g, b, a})
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

local function setOrder(info, neworderposstring)
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

function PitBull4_TotemTimers:OneOrMoreDown()
	for i=1, MAX_TOTEMS do
		if ( self.totemIsDown[i] == true ) then
			return true
		end
	end
	-- none is down
	return false
end

function PitBull4_TotemTimers:StartTimer()
	if not self.timerhandle then
		self.timerhandle = self:ScheduleRepeatingTimer(function() PitBull4_TotemTimers:UpdateAllTimes() end, 0.25)
	end
end

function PitBull4_TotemTimers:StopTimer()
	if self.timerhandle then
		self:CancelTimer(self.timerhandle)
		self.timerhandle = nil
	end
end

function PitBull4_TotemTimers:StartPulse(frame) -- starts a continuous pulse
	frame.pulseStopAfterThis = false
	frame.pulseStart = true
	frame.lastUpdated = 0
	if frame:GetScript("OnUpdate") == nil then
		frame:SetScript("OnUpdate", self.ButtonOnUpdate)
	end
end

function PitBull4_TotemTimers:StartPulseOnce(frame) -- starts a single pulse
	frame.pulseStopAfterThis = true
	frame.pulseStart = true
	frame.lastUpdated = 0
	if frame:GetScript("OnUpdate") == nil then
		frame:SetScript("OnUpdate", self.ButtonOnUpdate)
	end
end

function PitBull4_TotemTimers:StopPulse(frame)
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


function PitBull4_TotemTimers:UpdateAllTimes()
	local mf = nil
	for frame in PitBull4:IterateFramesForUnitID('player') do
		mf = frame
		if (not mf) or (not mf.TotemTimers) or (not mf.TotemTimers.elements) then
			self:Print("ERROR: Update time called but no Totemtimer Frame initialized.")
			--self:StopTimer()
			--return
		else 
			local elements = mf.TotemTimers.elements
			
			local nowTime = floor(GetTime())
			for slot=1, MAX_TOTEMS do
				if (not elements) or (not elements[slot]) or (not elements[slot].frame) then return end
				
				local timeleft = GetTotemTimeLeft(slot)
				
				if timeleft > 0 then
					-- need to update shown time
					if ( lOptGet('timertext') ) then
						elements[slot].text:SetText(self:SecondsToTimeAbbrev(timeleft))
					else
						elements[slot].text:SetText("")
					end
					-- Hide the cooldown frame if it's shown and the user changed preference
					if ( not lOptGet('timerspiral') and elements[slot].spiral:IsShown() ) then
						elements[slot].spiral:Hide()
					end
					
					if gOptGet('expirypulse') and (timeleft < gOptGet('expirypulsetime')) and (timeleft > 0) then
						--elements[slot].frame.pulseStart = true
						--elements[slot].frame.lastUpdate = 0
						self:StartPulse(elements[slot].frame)
					else
						--elements[slot].frame.pulseStart = false
						--elements[slot].frame.pulseActive = false
						--if elements[slot].frame.pulse.icon:IsVisible() then
						--	elements[slot].frame.pulse.icon:Hide()
						--end
						self:StopPulse(elements[slot].frame)
					end
				else
					-- Totem expired
					
					--elements[slot].frame.pulseStart = false
					--elements[slot].frame.pulseActive = false
					--elements[slot].frame.lastUpdate = 0
					self:StopPulse(elements[slot].frame)
					elements[slot].frame:SetAlpha(0.5)
					if lOptGet('hideinactive') then
						elements[slot].frame:Hide()
					end
					elements[slot].text:SetText("")
					elements[slot].spiral:Hide()
				end
			end
		end
	end
end


function PitBull4_TotemTimers:ActivateTotem(slot)
	local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
	-- queried seperately because GetTotemInfo apprears to give less reliable results (wtf?!)
	local timeleft = GetTotemTimeLeft(slot)
	
	if ( name == "" ) then
		self:Print("WARNING: Can't activate a nondropped totem")
		return
	end
	
	self.totemIsDown[slot] = true
	self.startTimes[slot] = startTime
	self.durations[slot] = duration
	
	for frame in PitBull4:IterateFramesForUnitID('player') do
		if not frame.TotemTimers then
			return
		end

		local tframe = frame.TotemTimers.elements[slot].frame
		local ttext = frame.TotemTimers.elements[slot].text
		local tspiral = frame.TotemTimers.elements[slot].spiral
		
		tframe:SetNormalTexture(icon)
		tframe.totemIcon = icon
		tframe:SetAlpha(1)
		tframe:Show()
		
		self:StopPulse(tframe)
		
		--tframe.border:SetVertexColor(lOptGetColor("totembordercolor"))
		tframe.border:Show()
		if ( lOptGet('timertext') ) then
			ttext:SetText(self:SecondsToTimeAbbrev(timeleft))
		end
		tspiral:SetCooldown(startTime, timeleft)
		if ( lOptGet('timerspiral') ) then
			tspiral:Show()
		else
			tspiral:Hide()
		end
		
		self:StartTimer()
	end
end

function PitBull4_TotemTimers:DeactivateTotem(slot)
	local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
	
	if ( name ~= "" ) then
		self:Print("WARNING: Can't deactivate a dropped totem")
		return
	end
	
	self.totemIsDown[slot] = false
	self.startTimes[slot] = 0
	self.durations[slot] = 0
	
	for frame in PitBull4:IterateFramesForUnitID('player') do
		if not frame.TotemTimers then
			return
		end

		local tframe = frame.TotemTimers.elements[slot].frame
		local ttext = frame.TotemTimers.elements[slot].text
		local tspiral = frame.TotemTimers.elements[slot].spiral
		
		-- cleanup timer event if no totems are down
		if not self:OneOrMoreDown() then
			self:StopTimer()
		end
		tspiral:Hide()
		
		--tframe.pulseStart = true
		--tframe.lastUpdate = 0
		self:StopPulse(tframe)
		
		
		tframe:SetAlpha(0.5)
		if lOptGet('hideinactive') then
			tframe:Hide()
		end
		ttext:SetText("")
	end
end

function PitBull4_TotemTimers:GetTotemStatus()
	for i=1, MAX_TOTEMS do
		local haveTotem, name, startTime, duration, icon = GetTotemInfo(i)
		if (name ~= "") then
			self.totemIsDown[i] = true
			self.startTimes[i] = startTime
			self.durations[i] = duration
			-- TODO: Must run the rest of the enabling stuff also to be useful (frame modifications, etc.)
		else
			self.totemIsDown[i] = false
			self.startTimes[i] = 0
			self.durations[i] = 0
		end
	end
end



--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Frame functions


local DEFAULT_FONT, DEFAULT_FONT_SIZE = ChatFontNormal:GetFont()
function PitBull4_TotemTimers:myGetFont(frame)
	local db = self:GetLayoutDB(frame)
	local font
	if LibSharedMedia then
		font = LibSharedMedia:Fetch("font", db.font or PitBull4.db.profile.layouts[frame.layout].font or "")
	end
	
	return font or DEFAULT_FONT, DEFAULT_FONT_SIZE * db.size
end

function PitBull4_TotemTimers:ResizeMainFrame(frame)
	if not frame.TotemTimers then
		return
	end
	local tSize = lOptGet('totemsize')
	local tSpacing = lOptGet('totemspacing')
	local lbreak = lOptGet('linebreak')
	local nlines = ceil(MAX_TOTEMS / lbreak)
	local ttf = frame.TotemTimers
	if (lOptGet('totemdirection') == "h") then
		ttf:SetWidth((lbreak*tSize)+((lbreak-1)*tSpacing))
		ttf:SetHeight((nlines*tSize)+((nlines-1)*tSpacing))
	else
		ttf:SetWidth((nlines*tSize)+((nlines-1)*tSpacing))
		ttf:SetHeight((lbreak*tSize)+((lbreak-1)*tSpacing))
	end
end

function PitBull4_TotemTimers:RealignTotems(frame)
	local lbreak = lOptGet('linebreak') or MAX_TOTEMS
	local tspacing = lOptGet('totemspacing') or 0

	if frame.TotemTimers then
		self:ResizeMainFrame(frame)

		local elements = frame.TotemTimers.elements
		for i=1, MAX_TOTEMS do
			local o = getSlotFromOrder(i)
			
			
			if (not o) then
				return
			end
			
			if i==1 then
				elements[o].frame:ClearAllPoints()
				elements[o].frame:SetPoint("TOPLEFT", frame.TotemTimers, "TOPLEFT", 0, 0)
			else
				elements[o].frame:ClearAllPoints()
				-- Attach the button to the previous one
				if (lOptGet('totemdirection') == "h") then
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

function PitBull4_TotemTimers:RealignTimerTexts(frame)
	if frame.TotemTimers then
		local elements = frame.TotemTimers.elements
		for i=1, MAX_TOTEMS do
			if (elements[i].text) then
				TimerTextAlignmentLogic(elements[i].text, elements[i].textFrame, lOptGet('timertextside'), 0, 0)
				local font, fontsize = self:myGetFont(frame)
				elements[i].text:SetFont(font, fontsize * lOptGet('timertextscale'), "OUTLINE")
			end
		end
	end
end

function PitBull4_TotemTimers:UpdateIconColor()
	for frame in PitBull4:IterateFramesForUnitID('player') do
		if frame.TotemTimers and frame.TotemTimers.elements then
			local elements = frame.TotemTimers.elements
			for i=1, MAX_TOTEMS do
				if elements[i].frame and elements[i].frame.border then
					elements[i].frame.border:Hide()
					elements[i].frame.border:SetVertexColor(lOptGetColor('totembordercolor'))
					elements[i].frame.border:Show()
				end
			end
		end
	end
end
function PitBull4_TotemTimers:ButtonOnClick(mousebutton)
	if (mousebutton == "RightButton" and this.slot ) then
		DestroyTotem( this.slot )
	end
end

function PitBull4_TotemTimers:ButtonOnEnter()
	if ( this.slot and gOptGet('totemtooltips') ) then
		-- setting the tooltip
		GameTooltip_SetDefaultAnchor(GameTooltip, this)
		GameTooltip:SetTotem(this.slot)
	end
end

function PitBull4_TotemTimers:ButtonOnLeave()
	if ( gOptGet('totemtooltips') ) then
		-- hiding the tooltip
		GameTooltip:Hide()
	end
end

-- inline credits: Parts of the following function were heavily inspired by the addon CooldownButtons by Dodge (permission given)
function PitBull4_TotemTimers:ButtonOnUpdate(elapsed)
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
					--local normtex = this:GetNormalTexture()
					--pulse.icon:SetTexture(normtex)
					--local r, g, b = normtex:GetVertexColor()
					--pulse.icon:SetVertexColor(r, g, b, 0.7)
					pulse.icon:SetTexture(this.totemIcon)
					--pulse.icon:SetVertexColor(0.5,0.5,0.5,0.7)
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
				if lOptGet('hideinactive') then
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




function PitBull4_TotemTimers:PLAYER_TOTEM_UPDATE(event, slot)
	local haveTotem, name, startTime, duration, icon = GetTotemInfo(slot)
	local sSlot = tostring(slot)

	for frame in PitBull4:IterateFramesForUnitID('player') do
		if not frame.TotemTimers then
			--self:OnPopulateUnitFrame('player', frame)
			if frame.TotemTimers then
				--PitBull:UpdateLayout(frame)
			end
		end
		
		if ( haveTotem and name ~= "") then
			-- New totem created
			--self:Print("Activating Totem")
			self:ActivateTotem(slot)
		elseif ( haveTotem ) then
			-- Totem just got removed or killed.
			--self:Print("Deactivating Totem")
			self:DeactivateTotem(slot)
			
			-- Sound functions
			if gOptGet('deathsound') and getSoundNameForSlot(slot) and not (event == nil) then
				--self:Print(string.format('DEBUG: Playing Death sound for slot %s: %s', tostring(slot), tostring(getSoundPathForSlot(slot))))
				PlaySoundFile(getSoundPathForSlot(slot))
			end
		end
	end
end

function PitBull4_TotemTimers:PLAYER_ENTERING_WORLD(...)
	-- we simulate totem events whenever a player zones to make sure totems left back in the instance hide properly.
	for i=1, MAX_TOTEMS do
		self:PLAYER_TOTEM_UPDATE(nil, i) -- we intentionally send a nil event (to avoid sounds upon login)
	end
end


function PitBull4_TotemTimers:UpdateFrame(frame)
	if frame.unit ~= 'player' then return end -- we only work for the player unit itself
	
	if frame.TotemTimers and (lOptGet('enabled') ~= true) then
		return self:ClearFrame(frame)
	end
	
	if frame.TotemTimers then
		-- make sure the timer is still running (it gets deactivated if the frame is gone for a moment
		self:StartTimer()
		return false -- our frame exists already, nothing more to do...
	end
	
	local font, fontsize = self:myGetFont(frame)
	local tSize = lOptGet('totemsize')
	local tSpacing = lOptGet('totemspacing')
	
	-- Main frame
	
	-- ttf shouldn't ever exist at this point but if it does, make sure we don't leak frames.
	if not frame.TotemTimers then
		frame.TotemTimers = PitBull4.Controls.MakeFrame(frame)
	end
	local ttf = frame.TotemTimers

	if (lOptGet('totemdirection') == "h") then
		ttf:SetWidth((MAX_TOTEMS*tSize)+((MAX_TOTEMS-1)*tSpacing))
		ttf:SetHeight(tSize)
	else
		ttf:SetWidth(tSize)
		ttf:SetHeight((MAX_TOTEMS*tSize)+((MAX_TOTEMS-1)*tSpacing))
	end
	ttf:Show()
	
	-- Main background
	if not ttf.background then
		ttf.background = PitBull4.Controls.MakeTexture(ttf, "BACKGROUND")
	end
	local bg = ttf.background
	bg:SetTexture(lOptGetColor('mainbgcolor'))
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
		local frame = elements[i].frame
		
		frame:SetWidth(tSize)
		frame:SetHeight(tSize)
		frame:Hide()
		frame.slot = i
		
		-------------------------------
		-- totem slot border frame
		if not frame.border then
			frame.border = PitBull4.Controls.MakeTexture(frame, "OVERLAY")
		end
		local border = frame.border
		border:SetAlpha(1)
		border:ClearAllPoints()
		border:SetAllPoints(frame)
		border:SetTexture(border_path)
		border:SetVertexColor(lOptGetColor('totembordercolor'))
		border:Show()
		
		----------------------------
		-- Spiral cooldown frame
		if not elements[i].spiral then
			elements[i].spiral = PitBull4.Controls.MakeTTCooldown(frame)
		end
		local spiral = elements[i].spiral
		spiral:SetReverse(true)
		spiral:SetAllPoints(frame)
		if ( lOptGet('suppressocc') ) then
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
		textFrame:SetAllPoints(frame)
		--textFrame:SetFrameLevel(spiral:GetFrameLevel() + 7)
		
		if not elements[i].text then
			elements[i].text = PitBull4.Controls.MakeFontString(frame, "OVERLAY")
		end
		local text = elements[i].text
		text:SetWidth(tSize)
		text:SetHeight((tSize/3))
		text:ClearAllPoints()
		text:SetPoint("BOTTOM", textFrame, "BOTTOM", 0, 0)
		text:SetFont(font, fontsize * lOptGet('timertextscale'), "OUTLINE")
		text:SetShadowColor(0,0,0,1)
		text:SetShadowOffset(0.8, -0.8)
		if ( lOptGetColor('timertextcolor') ) then
			text:SetTextColor(lOptGetColor('timertextcolor'))
		end
		text:Show()
		
		--------------------
		-- Pulse frame
		if not frame.pulse then
			frame.pulse = PitBull4.Controls.MakeFrame(frame)
		end
		local pulse = frame.pulse
		pulse:SetAllPoints(frame)
		pulse:SetToplevel(true)
		pulse.icon = PitBull4.Controls.MakeTexture(frame, "OVERLAY")
		pulse.icon:SetPoint("CENTER")
		pulse.icon:SetBlendMode("ADD")
		pulse.icon:SetVertexColor(0.5,0.5,0.5,0.7)
		pulse.icon:SetHeight(frame:GetHeight())
		pulse.icon:SetWidth(frame:GetWidth())
		pulse.icon:Hide()
		frame.pulseActive = false
		frame.pulseStart = false
		
		-----------------
		-- Click handling
		-- click handling for destroying single totems
		frame:RegisterForClicks("RightButtonUp")
		frame:SetScript("OnClick", self.ButtonOnClick)
		-- tooltip handling
		frame:SetScript("OnEnter", self.ButtonOnEnter)
		frame:SetScript("OnLeave", self.ButtonOnLeave)
		frame.lastUpdate = 1
		frame:SetScript("OnUpdate", self.ButtonOnUpdate)
	end
	
	ttf.elements = elements
	
	self:ResizeMainFrame(frame)
	self:RealignTotems(frame)
	
	return true
end



function PitBull4_TotemTimers:ClearFrame(frame)
	if not frame.TotemTimers then
		return false
	end
	
	self:StopTimer()
	
	--cleanup the element frames
	for i=1, MAX_TOTEMS do
		if frame.TotemTimers.elements[i].frame then
			frame.TotemTimers.elements[i].frame = frame.TotemTimers.elements[i].frame:Delete()
		end
	end
	
	frame.TotemTimers.background = frame.TotemTimers.background:Delete()
	frame.TotemTimers = frame.TotemTimers:Delete()
	
	return true
end

function PitBull4_TotemTimers:OnInitialize()
	-- Initialize Timer variables
	self.startTimes = {}
	self.durations = {}
	self.totemIsDown = {}
	for i=1,MAX_TOTEMS do
		self.startTimes[i] = 0
		self.durations[i] = 0
		self.totemIsDown[i] = false
	end
	
	self.timerhandle = nil
	self.borderpath = border_path
	
	-- Define new control type for our main element buttons
	PitBull4.Controls.MakeNewControlType("TTButton", "Button", function(control) end, function(control) end, function(control) end)
	PitBull4.Controls.MakeNewControlType("TTCooldown", "Cooldown", function(control) end, function(control) end, function(control) end)
	
	-- Get initial status
	self:GetTotemStatus()
end

PitBull4_TotemTimers:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_left",
	position = 1,
	bgcolor = {0.8, 0.8, 0.8},
	tlo1 = true, -- dummy for optiontests
	totemsize = 25,
	totemspacing = 0,
	totemdirection = "h",
	timerspiral = true,
	suppressocc = true,
	timertext = true,
	timertextcolor = {0, 1, 0, 1},
	timertextside = "bottominside",
	timertextscale = 0.75,
	mainbgcolor = {0, 0, 0, 0.5},
	linebreak = MAX_TOTEMS,
	hideinactive = false,
	totembordercolor = {0, 0, 0, 0.5},
	mainoffsetx = 0,
	mainoffsety = 0,
}, {
	totemtooltips = true,
	order = getOrderDefault(), -- this is the order _by_slot_ not by position!
	expirypulse = true,
	expirypulsetime = 5,
	recastenabled = false,
	deathsound = false,
	deathsoundpaths = getSoundpathsDefault(),
})

PitBull4_TotemTimers:SetLayoutOptionsFunction(function(self)
	return 'totemsize', {
		type = 'range',
		name = L["Totem Size"],
		desc = L["Sets the size of the individual totem icons."],
		min = 5,
		max = 100,
		step = 1,
		get = lOptGet,
		set = function(info, value) 
			lOptSet('totemsize', value) 
			for frame in PitBull4:IterateFramesForUnitID('player') do
				if frame.TotemTimers then
					local elements = frame.TotemTimers.elements
					for i=1, MAX_TOTEMS do
						elements[i].frame:SetHeight(value)
						elements[i].frame:SetWidth(value)
						elements[i].text:SetWidth(value)
						elements[i].text:SetHeight((value/3))
					end
					self:ResizeMainFrame(frame)
				end
			end
		end,
		disabled = function() return not lOptGet('enabled') end,
		order = 11,
	},
	'totemspacing', {
		type = 'range',
		name = L["Totem Spacing"],
		desc = L["Sets the size of the gap between the totem icons."],
		min = 0,
		max = 100,
		step = 1,
		get = lOptGet,
		set = function(info, value)
			lOptSet('totemspacing', value)
			for frame in PitBull4:IterateFramesForUnitID('player') do
				self:RealignTotems(frame)
			end
		end,
		disabled = function() return not lOptGet('enabled') end,
		order = 12,
	},
	'totemdirection', {
		type = 'select',
		name = L["Totem Direction"],
		desc = L["Choose wether to grow horizontally or vertically."],
		get = lOptGet,
		set = function(info, value)
			lOptSet('totemdirection', value)
			for frame in PitBull4:IterateFramesForUnitID('player') do
				self:RealignTotems(frame)
			end
		end,
		values = {
			["h"] = L["Horizontal"],
			["v"] = L["Vertical"]
		},
		style = "radio",
		disabled = function() return not lOptGet('enabled') end,
		order = 13,
	},
	'linebreak', {
		type = 'range',
		name = L["Totems per line"],
		desc = L["How many totems to draw per line."],
		min = 1,
		max = MAX_TOTEMS,
		step = 1,
		get = lOptGet,
		set = function(info, value)
			lOptSet('linebreak', value)
			for frame in PitBull4:IterateFramesForUnitID('player') do
				self:RealignTotems(frame)
			end
		end,
		disabled = function() return not lOptGet('enabled') end,
		order = 14,
	},
	'hideinactive', {
		type = 'toggle',
		name = L["Hide inactive"],
		desc = L["Hides inactive totem icons completely."],
		get = lOptGet,
		set = lOptSet,
		disabled = function() return not lOptGet('enabled') end,
		order = 15,
	},
	'mainbgcolor', {
		type = 'color',
		name = L["Background Color"],
		desc = L["Sets the color and transparency of the background of the timers."],
		hasAlpha = true,
		get = lOptGetColor,
		--set = lOptSetColor,
		set = function(info, r,g,b,a) 
			lOptSetColor('mainbgcolor', r,g,b,a)
			for frame in PitBull4:IterateFramesForUnitID('player') do
				if frame.TotemTimers then
					frame.TotemTimers.background:SetTexture(r,g,b,a)
				end
			end
		end,
		disabled = function() return not lOptGet('enabled') end,
		order = 16,
	},
	'totembordercolor', {
		type = 'color',
		name = L["Border Color"],
		desc = L["Sets the bordercolor of the individual icons."],
		hasAlpha = true,
		get = lOptGetColor,
		--set = lOptSetColor,
		set = function(info, r,g,b,a) 
			lOptSetColor(info, r,g,b,a)
			self:UpdateIconColor()
		end,
		disabled = function() return not lOptGet('enabled') end,
		order = 17,
	},
	'grptimerspiral', {
		type = 'group',
		name = L["Spiral Timer"],
		desc = L["Options relating to the spiral display timer."],
		inline = true,
		order = 18,
		disabled = function() return not lOptGet('enabled') end,
		args = {
			timerspiral = {
				type = 'toggle',
				name = L["Timer Spiral"],
				desc = L["Shows the pie-like cooldown spiral on the icons."],
				get = lOptGet,
				set = lOptSet,
				width = 'full',
				disabled = function() return not lOptGet('enabled') end,
				order = 1,
			},
			suppressocc = {
				type = 'toggle',
				name = L["Suppress Cooldown Counts"],
				desc = L["Tries to suppress CooldownCount-like addons on the spiral timer. (Requires UI reload to change the setting!)"],
				get = lOptGet,
				set = lOptSet,
				width = 'full',
				disabled = function() return not lOptGet('timerspiral') or not lOptGet('enabled') end,
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
		disabled = function() return not lOptGet('enabled') end,
		args = {
			timertext = {
				type = 'toggle',
				name = L["Timer Text"],
				desc = L["Shows the remaining time in as text."],
				get = lOptGet,
				set = lOptSet,
				order = 1,
				disabled = function() return not lOptGet('enabled') end,
			},
			timertextcolor = {
				type = 'color',
				name = L["Text Color"],
				desc = L["Color of the timer text."],
				hasAlpha = true,
				get = lOptGetColor,
				set = function(info, r,g,b,a)
					lOptSetColor('timertextcolor', r,g,b,a)
					for frame in PitBull4:IterateFramesForUnitID('player') do
						if frame.TotemTimers and frame.TotemTimers.elements then
							local elements = frame.TotemTimers.elements
							for i=1, MAX_TOTEMS do
								if elements[i].text then
									elements[i].text:SetTextColor(r,g,b,a)
								end
							end
						end
					end
				end,
				disabled = function() return not lOptGet('timertext') or not lOptGet('enabled')  end,
				order = 2,
			},
			timertextside = {
				type = 'select',
				name = L["Text Side"],
				desc = L["Which side to position the timer text at."],
				values = {
					topinside = L["Top, Inside"],
					topoutside = L["Top, Outside"],
					bottominside = L["Bottom, Inside"],
					bottomoutside = L["Bottom, Outside"],
					leftoutside = L["Left, Outside"],
					rightoutside = L["Right, Outside"],
					middle = L["Middle"],
				},
				get = lOptGet,
				set = function(info, value)
					lOptSet('timertextside', value)
					for frame in PitBull4:IterateFramesForUnitID('player') do
						self:RealignTimerTexts(frame)
					end
				end,
				disabled = function() return not lOptGet('timertext') or not lOptGet('enabled')  end,
				order = 3,
			},
			timertextscale = {
				type = 'range',
				name = L["Text Scale"],
				desc = L["Change the scaling of the text timer. Note: It's relative to PitBull's font size."],
				min = 0.1,
				max = 2,
				step = 0.01,
				get = lOptGet,
				set = function(info, value)
					lOptSet('timertextscale', value)
					for frame in PitBull4:IterateFramesForUnitID('player') do
						self:RealignTimerTexts(frame)
					end
				end,
				disabled = function() return not lOptGet('timertext') or not lOptGet('enabled')  end,
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
		name = L["There are more options for this module in the Modules -> TotemTimers section."],
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

PitBull4_TotemTimers:SetGlobalOptionsFunction(function(self)
	return 'layoutnoticehdr', {
		type = 'header',
		name = L["Did you know?"],
		order = 128,
		width = 'full',
	},
	'layoutnoticedesc', {
		type = 'description',
		name = L["There are more options for this module in the Layout editor -> Indicators -> TotemTimers section."],
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

