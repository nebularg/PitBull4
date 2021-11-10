if select(2, UnitClass("player")) ~= "SHAMAN" then
	return
end

local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- CONSTANTS ----------------------------------------------------------------

local MAX_TOTEMS = 4
local TOTEM_ORDER = { 2, 1, 3, 4 }
local TOTEM_SLOT_TO_INDEX = tInvert(TOTEM_ORDER)

local TOTEM_SIZE = 50 -- fixed value used for internal frame creation, change the final size ingame only!

local CONFIG_MODE_ICON = [[Interface\Icons\Spell_Fire_TotemOfWrath]]
local BORDER_PATH  = [[Interface\AddOns\PitBull4\Modules\Totems\border]]
local DEFAULT_SOUND_NAME = "Drop"
local DEFAULT_SOUND_PATH = [[Sound\Interface\DropOnGround.ogg]] -- 567460

local COLOR_DEFAULTS = {
	main_background = {0, 0, 0, 0.5},
	timer_text = {0, 1, 0, 1},
	totem_border = {0, 0, 0, 0.5},
	slot1 = {1,0,0,1},
	slot2 = {0,1,0,1},
	slot3 = {0,1,1,1},
	slot4 = {0,0,1,1},
}

local LAYOUT_DEFAULTS = {
	attach_to = "root",
	location = "out_top_left",
	position = 1,
	size = 2, -- default to a 200% scaling, the 100% seems way too tiny.
	tlo1 = true, -- dummy for optiontests
	totem_spacing = 0,
	totem_direction = "h",
	timer_spiral = true,
	suppress_occ = true,
	timer_text = true,
	timer_text_side = "bottominside",
	line_break = MAX_TOTEMS,
	hide_inactive = false,
	bar_size = 1, -- needs to exist for "show as bar" option, unused for now
}

local GLOBAL_DEFAULTS = {
	expiry_pulse = true,
	expiry_pulse_time = 5,
	recast_enabled = false,
	death_sound = false,
	colors = COLOR_DEFAULTS,
	totem_borders_per_element = true,
	text_color_per_element = false,
}

-- inject sounds for each slot (non-fixed amount)
for i = 1, MAX_TOTEMS do
	GLOBAL_DEFAULTS['sound_slot'..tostring(i)] = DEFAULT_SOUND_NAME
end


local GetTime = _G.GetTime
local floor = _G.math.floor
local ceil = _G.math.ceil
local max = _G.math.max
local min = _G.math.min
local tostring = _G.tostring
local type = _G.type

-----------------------------------------------------------------------------

local PitBull4_Totems = PitBull4:NewModule("Totems", "AceTimer-3.0")

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if LibSharedMedia then
	LibSharedMedia:Register("sound", DEFAULT_SOUND_NAME, DEFAULT_SOUND_PATH)
end

-- Register some metadata of ours with PB4
PitBull4_Totems:SetModuleType('indicator')
PitBull4_Totems:SetName(L["Totems"])
PitBull4_Totems:SetDescription(L["Show which Totems are dropped and the time left until they expire."])
PitBull4_Totems.show_font_option = true
PitBull4_Totems.show_font_size_option = true
PitBull4_Totems.can_set_side_to_center = false -- Intentionally deactivated until I find out how to scale the resulting pseudo-bar

local function get_verbose_slot_name(slot)
	if slot == _G.FIRE_TOTEM_SLOT then
		return L["Fire"]
	elseif slot == _G.EARTH_TOTEM_SLOT then
		return L["Earth"]
	elseif slot == _G.WATER_TOTEM_SLOT then
		return L["Water"]
	elseif slot == _G.AIR_TOTEM_SLOT then
		return L["Air"]
	else
		return L["Unknown Slot "]..tostring(slot)
	end
end

--------------------------------------------------------------------------------
-- this function is borrowed from Got Wood which got it from neronix.
function PitBull4_Totems:SecondsToTimeAbbrev(time)
	local text, m, s
	if( time < 0 ) then
		text = ""
	elseif( time < 3600 ) then
		m = floor(time / 60)
		s = time % 60
		if (m==0) then
			text = ("0:%02d"):format(s)
		else
			text = ("%01d:%02d"):format(m, s)
		end
	end
	return text
end

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Configuration Proxyfunctions
--    lowercase g, l and c refer to Global, Layout and Color Options
--    Note that Layout options require handing a frame, as layout options are individual per frame
-------------------------------
---- General Purpose Proxies
local function global_option_get(key)
	if type(key) == 'table' then
		return PitBull4_Totems.db.profile.global[key[#key]]
	else
		return PitBull4_Totems.db.profile.global[key]
	end
end
local function gOptSet(key, value)
	if type(key) == 'table' then
		PitBull4_Totems.db.profile.global[key[#key]] = value
	else
		PitBull4_Totems.db.profile.global[key] = value
	end
	PitBull4.Options.UpdateFrames()
end
local function color_option_get(key, default_r, default_g, default_b, default_a)
	local ret = nil
	if type(key) == 'table' then
		ret = PitBull4_Totems.db.profile.global.colors[key[#key]]

	else
		ret = PitBull4_Totems.db.profile.global.colors[key]
	end
	if not ret and default_r then
		return default_r, default_g, default_b, default_a
	end
	return unpack(ret)
end
local function color_option_set(key, r, g, b, a)
	if type(key) == 'table' then
		PitBull4_Totems.db.profile.global.colors[key[#key]] = {r, g, b, a}
	else
		PitBull4_Totems.db.profile.global.colors[key] = {r, g, b, a}
	end
	PitBull4.Options.UpdateFrames()
end

local function layout_option_get(frame, key)
	if type(key) == 'table' then
		return PitBull4_Totems:GetLayoutDB(frame)[key[#key]]
	else
		return PitBull4_Totems:GetLayoutDB(frame)[key]
	end
end
local function layout_option_set(frame, key, value)
	if type(key) == 'table' then
		PitBull4_Totems:GetLayoutDB(frame)[key[#key]]  = value
	else
		PitBull4_Totems:GetLayoutDB(frame)[key] = value
	end
	PitBull4.Options.UpdateFrames()
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
	return true,
		"Fake Totem",
		ceil(GetTime()),
		119,
		CONFIG_MODE_ICON
end

function PitBull4_Totems:StartTimer()
	if not self.timer_handle then
		self.timer_handle = self:ScheduleRepeatingTimer(function() PitBull4_Totems:UpdateAllTimes() end, 0.25)
	end
end

function PitBull4_Totems:StopTimer()
	if self.timer_handle then
		self:CancelTimer(self.timer_handle)
		self.timer_handle = nil
	end
end

function PitBull4_Totems:StartPulse(frame) -- starts a continuous pulse
	frame.pulse_stop_after_this = false
	frame.pulse_start = true
	frame.last_updated = 0
	if frame:GetScript("OnUpdate") == nil then
		frame:SetScript("OnUpdate", self.button_scripts.OnUpdate)
	end
end

function PitBull4_Totems:StartPulseOnce(frame) -- starts a single pulse
	frame.pulse_stop_after_this = true
	frame.pulse_start = true
	frame.last_updated = 0
	if frame:GetScript("OnUpdate") == nil then
		frame:SetScript("OnUpdate", self.button_scripts.OnUpdate)
	end
end

function PitBull4_Totems:StopPulse(frame)
	frame.pulse_stop_after_this = false
	frame.pulse_start = false
	frame.pulse_active = false
	if frame.pulse.icon:IsVisible() then
		frame.pulse.icon:Hide()
	end
	frame.last_updated = 0
	if frame:GetScript("OnUpdate") ~= nil then
		frame:SetScript("OnUpdate", nil)
	end
end


function PitBull4_Totems:UpdateAllTimes()
	for frame in PitBull4:IterateFrames() do
		local unit = frame.unit
		if unit and UnitIsUnit(unit,"player") and frame.Totems and frame.Totems.elements then

			local elements = frame.Totems.elements

			for i, slot in ipairs(TOTEM_ORDER) do
				if (not elements) or (not elements[i]) or (not elements[i].frame) then return end

				local timeleft = MyGetTotemTimeLeft(slot,frame)
				local _, _, _, _, icon = MyGetTotemInfo(slot, frame)

				if timeleft > 0 then
					-- need to update shown time
					if ( layout_option_get(frame,'timer_text') ) then
						elements[i].text:SetText(self:SecondsToTimeAbbrev(timeleft))
					else
						elements[i].text:SetText("")
					end

					-- check if we need to update the shown icon
					if icon ~= elements[i].frame.totem_icon then
						elements[i].frame:SetNormalTexture(icon)
						elements[i].frame.totem_icon = icon
						--elements[slot].frame:SetAlpha(1)
						elements[i].frame:Show()
					end

					-- Hide the cooldown frame if it's shown and the user changed preference
					if ( not layout_option_get(frame,'timer_spiral') and elements[i].spiral:IsShown() ) then
						elements[i].spiral:Hide()
					end

					if global_option_get('expiry_pulse') and (timeleft < global_option_get('expiry_pulse_time')) and (timeleft > 0) then
						self:StartPulse(elements[i].frame)
					else
						self:StopPulse(elements[i].frame)
					end
				else
					-- Totem expired

					self:StopPulse(elements[i].frame)
					elements[i].frame:SetAlpha(0.5)
					if layout_option_get(frame,'hide_inactive') then
						elements[i].frame:Hide()
					end
					elements[i].text:SetText("")
					elements[i].spiral:Hide()
				end
			end
		end
	end
end

function PitBull4_Totems:SpiralUpdate(frame,slot,start,left)
	if not frame.Totems then return end
	local index = TOTEM_SLOT_TO_INDEX[slot]
	if not frame.Totems.elements[index] then return end
	local tspiral = frame.Totems.elements[index].spiral
	local startTime = start or select(3, MyGetTotemInfo(slot,frame))
	local timeLeft = left or MyGetTotemTimeLeft(slot,frame)

	CooldownFrame_Set(tspiral, startTime, timeLeft, 1)
	if self.totem_is_down[slot] and layout_option_get(frame,'timer_spiral') then
		tspiral:Show()
	else
		tspiral:Hide()
	end
end


function PitBull4_Totems:ActivateTotem(slot)
	local index = TOTEM_SLOT_TO_INDEX[slot]
	for frame in PitBull4:IterateFrames() do
		local unit = frame.unit
		if unit and UnitIsUnit(unit,"player") and self:GetLayoutDB(frame).enabled and frame.Totems and frame.Totems.elements[index] then
			local _, _, startTime, _, icon = MyGetTotemInfo(slot, frame)
			local timeLeft = MyGetTotemTimeLeft(slot, frame)

			local tframe = frame.Totems.elements[index].frame
			local ttext = frame.Totems.elements[index].text

			tframe:SetNormalTexture(icon)
			tframe.totem_icon = icon
			tframe:SetAlpha(1)
			tframe:Show()
			tframe.force_show = frame.force_show -- set configmode as a property of the frame, so the buttonscripts know about it

			self:StopPulse(tframe)

			tframe.border:Show()
			if ( layout_option_get(frame,'timer_text') ) then
				ttext:SetText(self:SecondsToTimeAbbrev(timeLeft))
			end
			self:SpiralUpdate(frame, slot, startTime, timeLeft)

			self:StartTimer()
		end
	end
end

function PitBull4_Totems:DeactivateTotem(slot)
	local index = TOTEM_SLOT_TO_INDEX[slot]
	for frame in PitBull4:IterateFrames() do
		local unit = frame.unit
		if unit and UnitIsUnit(unit,"player") and self:GetLayoutDB(frame).enabled and frame.Totems and frame.Totems.elements[index] then
			local tframe = frame.Totems.elements[index].frame
			local ttext = frame.Totems.elements[index].text
			local tspiral = frame.Totems.elements[index].spiral

			-- cleanup timer event if no totems are down
			if not next(self.totem_is_down) then
				self:StopTimer()
			end
			tspiral:Hide()

			self:StopPulse(tframe)

			tframe:SetAlpha(0.5)
			tframe.totem_icon = nil
			if layout_option_get(frame,'hide_inactive') then
				tframe:Hide()
			end
			ttext:SetText("")
		end
	end
end

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Frame functions

function PitBull4_Totems:ResizeMainFrame(frame)
	if not frame.Totems then
		return
	end
	local tSpacing = layout_option_get(frame,'totem_spacing')
	local lbreak = min(MAX_TOTEMS, layout_option_get(frame,'line_break'))
	local nlines = ceil(MAX_TOTEMS / lbreak)
	local ttf = frame.Totems
	local width = nil
	local height = nil
	if (layout_option_get(frame,'totem_direction') == "h") then
		width = (lbreak*TOTEM_SIZE)+((lbreak-1)*tSpacing)
		height = (nlines*TOTEM_SIZE)+((nlines-1)*tSpacing)
		ttf.height = nlines + ((nlines-1)*(tSpacing/TOTEM_SIZE))
	else
		width = (nlines*TOTEM_SIZE)+((nlines-1)*tSpacing)
		height = (lbreak*TOTEM_SIZE)+((lbreak-1)*tSpacing)
		ttf.height = lbreak + ((lbreak-1)*(tSpacing/TOTEM_SIZE))
	end
	ttf:SetWidth(width)
	ttf:SetHeight(height)
end

function PitBull4_Totems:RealignTotems(frame)
	local lbreak = min(MAX_TOTEMS, layout_option_get(frame,'line_break') or MAX_TOTEMS)
	local tspacing = layout_option_get(frame,'totem_spacing') or 0

	if frame.Totems then
		local elements = frame.Totems.elements
		for i = 1, MAX_TOTEMS do
			if i == 1 then
				elements[i].frame:ClearAllPoints()
				elements[i].frame:SetPoint("TOPLEFT", frame.Totems, "TOPLEFT", 0, 0)
			else
				elements[i].frame:ClearAllPoints()
				-- Attach the button to the previous one
				if (layout_option_get(frame,'totem_direction') == "h") then
					-- grow horizontally
					if ((i - 1) % lbreak == 0) then
						-- Reached a line_break
						elements[i].frame:SetPoint("TOPLEFT", elements[i-lbreak].frame, "BOTTOMLEFT", 0, 0-tspacing)
					else
						elements[i].frame:SetPoint("TOPLEFT", elements[i-1].frame, "TOPRIGHT", tspacing, 0)
					end
				else
					--grow vertically
					if ((i - 1) % lbreak == 0) then
						elements[i].frame:SetPoint("TOPLEFT", elements[i-lbreak].frame, "TOPRIGHT", tspacing, 0)
					else
						elements[i].frame:SetPoint("TOPLEFT", elements[i-1].frame, "BOTTOMLEFT", 0, 0-tspacing)
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
	for i = 1, MAX_TOTEMS do
		if (elements[i].text) then
			TimerTextAlignmentLogic(elements[i].text, elements[i].textFrame, layout_option_get(frame, 'timer_text_side'), 0, 0)
			local font, fontsize = self:GetFont(frame)
			elements[i].text:SetFont(font, fontsize, "OUTLINE")

			if global_option_get('text_color_per_element') then
				elements[i].text:SetTextColor(color_option_get('slot'..tostring(i), 1,1,1,1))
			else
				elements[i].text:SetTextColor(color_option_get('timer_text'))
			end

		end
	end
end

function PitBull4_Totems:UpdateIconColor(frame)
	if frame.Totems and frame.Totems.elements then
		for i = 1, MAX_TOTEMS do
			local frame = frame.Totems.elements[i] and frame.Totems.elements[i].frame
			if frame and frame.border then
				frame.border:Hide()
				if global_option_get('totem_borders_per_element') then
					frame.border:SetVertexColor(color_option_get('slot'..tostring(frame.slot), 1,1,1,1))
				else
					frame.border:SetVertexColor(color_option_get('totem_border'))
				end
				frame.border:Show()
			end
		end
	end
end

PitBull4_Totems.button_scripts = {}

-- inline credits: Parts of the following function were heavily inspired by the addon CooldownButtons by Dodge (permission given)
function PitBull4_Totems.button_scripts:OnUpdate(elapsed)
	if not self:IsVisible() then
		return -- nothing to do when we aren't visible
	end

	if self.last_update > elapsed then
		self.last_update = self.last_update - elapsed
		return
	else
		self.last_update = 0.75
	end

	-- start a pulse if it isn't active yet, if it is, do the animation as normal
	if self.pulse_start then
		self.pulse.icon:Hide()
		self.last_update = 0
		if not self.pulse_active then
			-- Pulse isn't active yet so we start it
			if self:IsVisible() then
				local pulse = self.pulse
				if pulse then
					pulse.scale = 1
					pulse.icon:SetTexture(self.totem_icon)
					self.pulse_active = true
				end
			end
		else
			-- Pulse is already active, do the animation...
			local pulse = self.pulse
			if pulse.scale >= 2 then
				pulse.dec = 1
			elseif pulse.scale <= 1 then
				pulse.dec = nil
			end
			pulse.scale = max(min(pulse.scale + (pulse.dec and -1 or 1) * pulse.scale * (elapsed/0.5), 2), 1)


			if self.pulse_stop_after_this and pulse.scale <= 1 then
				-- Pulse animation is to be stopped now.
				pulse.icon:Hide()
				pulse.dec = nil
				self.pulse_active = false
				self.pulse_start = false
				self.pulse_stop_after_this = false

				if self.hide_inactive then
					self:Hide()
				end
			else
				-- Applying the new scaling (animation frame)
				pulse.icon:Show()
				pulse.icon:SetHeight(pulse:GetHeight() * pulse.scale)
				pulse.icon:SetWidth(pulse:GetWidth() * pulse.scale)
			end
		end

	end
end




function PitBull4_Totems:PLAYER_TOTEM_UPDATE(event, slot)
	if not slot or slot < 1 or slot > MAX_TOTEMS then return end
	self.totem_is_down[slot] = nil

	local haveTotem, name = GetTotemInfo(slot)
	if name == "" then return end

	if haveTotem then
		-- New totem created
		self.totem_is_down[slot] = true
		self:ActivateTotem(slot)
	else
		-- Totem just got removed or killed.
		self:DeactivateTotem(slot)

		-- Sound functions
		if global_option_get('death_sound') and not (event == nil) then
			local soundpath = DEFAULT_SOUND_PATH
			if LibSharedMedia then
				soundpath = LibSharedMedia:Fetch("sound", global_option_get("sound_slot"..tostring(slot)))
			end
			PlaySoundFile(soundpath)
		end
	end
end

function PitBull4_Totems:ForceSilentTotemUpdate()
	for i = 1, MAX_TOTEMS do
		self:PLAYER_TOTEM_UPDATE(nil, i) -- we intentionally send a nil event (to avoid sounds)
	end
end

function PitBull4_Totems:PLAYER_ENTERING_WORLD(...)
	-- we simulate totem events whenever a player zones to make sure totems left back in the instance hide properly.
	self:ForceSilentTotemUpdate()
end

function PitBull4_Totems:PLAYER_TALENT_UPDATE()
	self:UpdateAll()
end

function PitBull4_Totems:BuildFrames(frame)
	if not frame then return end -- not enough legit parameters
	if frame.Totems then return end -- Can't create the frames when they already exist..

	local font, fontsize = self:GetFont(frame)
	local tSpacing = layout_option_get(frame,'totem_spacing')

	-- Main frame

	frame.Totems = PitBull4.Controls.MakeFrame(frame)
	local ttf = frame.Totems

	if (layout_option_get(frame,'totem_direction') == "h") then
		ttf:SetWidth((MAX_TOTEMS*TOTEM_SIZE)+((MAX_TOTEMS-1)*tSpacing))
		ttf:SetHeight(TOTEM_SIZE)
	else
		ttf:SetWidth(TOTEM_SIZE)
		ttf:SetHeight((MAX_TOTEMS*TOTEM_SIZE)+((MAX_TOTEMS-1)*tSpacing))
	end
	ttf:Show()

	-- Main background
	if not ttf.background then
		ttf.background = PitBull4.Controls.MakeTexture(ttf, "BACKGROUND")
	end
	local bg = ttf.background
	bg:SetColorTexture(color_option_get('main_background'))
	bg:SetAllPoints(ttf)

	-- Now create the main timer frames for each totem element
	local elements = {}
	for i = 1, MAX_TOTEMS do
		-------------------------------
		-- Main totem slot frame
		elements[i] = {}
		if not elements[i].frame then
			elements[i].frame = PitBull4.Controls.MakeButton(ttf)
		end
		local frm = elements[i].frame

		frm:EnableMouse(false)
		frm:SetWidth(TOTEM_SIZE)
		frm:SetHeight(TOTEM_SIZE)
		frm:SetFrameLevel(frame:GetFrameLevel() + 13)
		frm:Hide()
		frm.slot = TOTEM_ORDER[i]
		frm.hide_inactive = layout_option_get(frame,'hide_inactive')

		if frm.totem_icon then -- we're already supposed to show something!
			frm:SetNormalTexture(frm.totem_icon)
			frm:SetAlpha(1)
			frm:Show()
		else
			frm:SetNormalTexture(CONFIG_MODE_ICON)
		end

		-------------------------------
		-- totem slot border frame
		if not frm.border then
			frm.border = PitBull4.Controls.MakeTexture(frm, "OVERLAY")
		end
		local border = frm.border
		border:SetAlpha(1)
		border:ClearAllPoints()
		border:SetAllPoints(frm)
		border:SetTexture(BORDER_PATH)
		border:Show()

		----------------------------
		-- Spiral cooldown frame
		if not elements[i].spiral then
			elements[i].spiral = PitBull4.Controls.MakeCooldown(frm)
		end
		local spiral = elements[i].spiral
		spiral:SetReverse(true)
		spiral:SetDrawEdge(false)
		spiral:SetDrawSwipe(true)
		spiral:SetHideCountdownNumbers(true)
		spiral:SetAllPoints(frm)
		spiral:Show()
		spiral.noCooldownCount = layout_option_get(frame,'suppress_occ') or nil

		--------------------
		-- Text frame
		if not elements[i].textFrame then
			elements[i].textFrame = PitBull4.Controls.MakeFrame(frame)
		end
		local textFrame = elements[i].textFrame
		textFrame:SetScale(max(0.01,frm:GetScale()))
		textFrame:SetAllPoints(frm)
		textFrame:SetFrameLevel(spiral:GetFrameLevel() + 1)

		if not elements[i].text then
			elements[i].text = PitBull4.Controls.MakeFontString(textFrame, "OVERLAY")
		end
		local text = elements[i].text
		text:ClearAllPoints()
		text:SetPoint("BOTTOM", textFrame, "BOTTOM", 0, 0)
		text:SetWidth(TOTEM_SIZE)
		text:SetHeight(TOTEM_SIZE/3)
		text:SetFont(font, fontsize, "OUTLINE")
		text:SetShadowColor(0,0,0,1)
		text:SetShadowOffset(0.8, -0.8)
		text:SetTextColor(color_option_get('timer_text'))
		text:Show()

		--------------------
		-- Pulse frame
		if not frm.pulse then
			frm.pulse = PitBull4.Controls.MakeFrame(frm)
		end
		local pulse = frm.pulse
		pulse:SetAllPoints(frm)
		pulse:SetToplevel(true)
		if not pulse.icon then
			pulse.icon = PitBull4.Controls.MakeTexture(frm, "OVERLAY")
		end
		pulse.icon:SetPoint("CENTER")
		pulse.icon:SetBlendMode("ADD")
		pulse.icon:SetVertexColor(0.5,0.5,0.5,0.7)
		pulse.icon:SetHeight(frm:GetHeight())
		pulse.icon:SetWidth(frm:GetWidth())
		pulse.icon:Hide()
		frm.pulse_active = false
		frm.pulse_start = false
		frm.last_update = 1
		frm:SetScript("OnUpdate", self.button_scripts.OnUpdate)
	end

	ttf.elements = elements

end

function PitBull4_Totems:ApplyLayoutSettings(frame)
	if not frame or not frame.Totems then return end

	self:RealignTotems(frame)

	local elements = frame.Totems.elements

	for i = 1, MAX_TOTEMS do
		elements[i].frame.hide_inactive = layout_option_get(frame,'hide_inactive')

		self:SpiralUpdate(frame, elements[i].frame.slot, nil, nil)
	end


	self:ResizeMainFrame(frame)

	-- Background color of the main frame
	frame.Totems.background:SetColorTexture(color_option_get('main_background'))

	-- Bordercolor of the buttons
	self:UpdateIconColor(frame)

	-- Update timer_text settings
	self:RealignTimerTexts(frame)
end

function PitBull4_Totems:UpdateFrame(frame)
	local unit = frame.unit
	if not unit or not UnitIsUnit(unit,"player") then -- we only work for the player unit itself
		return self:ClearFrame(frame)
	end
	if frame.is_wacky then
		-- Disable for wacky frames, because something... wacky is going on with their updates.
		return self:ClearFrame(frame)
	end

	if (layout_option_get(frame,'enabled') ~= true) and frame.Totems then
		return self:ClearFrame(frame)
	end

	if frame.Totems then
		-- Workaround for Worldmap hiding elements the moment it's shown.
		-- Basically, if frame.Totems exists, it has no reason to be hidden ever...
		if not frame.Totems:IsShown() then
			frame.Totems:Show()
		end

		-- make sure the timer is still running (it gets deactivated if the frame is gone for a moment)
		self:StartTimer()

		-- Now rebuild most of the layout since some setting might have changed.
		self:ApplyLayoutSettings(frame)
		self:ForceSilentTotemUpdate()
		return false -- our frame exists already, nothing more to do...
	else
		self:BuildFrames(frame)
		self:ApplyLayoutSettings(frame)
		self:ForceSilentTotemUpdate()
		return true
	end
end



function PitBull4_Totems:ClearFrame(frame)
	if not frame.Totems then
		return false
	end

	--self:StopTimer()
	-- we're not stopping the timer anymore because we're not the only possible frame active

	--cleanup the element frames
	for i = 1, MAX_TOTEMS do
		local element = frame.Totems.elements[i]

		if element.pulse and element.pulse.icon then
			element.pulse.icon = element.pulse.icon:Delete()
		end
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
			element.spiral.noCooldownCount = nil
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
	self:RegisterEvent("CHARACTER_POINTS_CHANGED","PLAYER_TALENT_UPDATE")
end

function PitBull4_Totems:OnInitialize()
	-- Initialize Timer variables
	self.totem_is_down = {}
	self.timer_handle = nil	-- used for storing the reference to the ace3 timer
end


PitBull4_Totems:SetDefaults(LAYOUT_DEFAULTS, GLOBAL_DEFAULTS)

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
	local function disabled(info)
		return not PitBull4.Options.GetLayoutDB(self).enabled
	end


	return 'totem_spacing', {
		type = 'range',
		name = L["Totem spacing"],
		desc = L["Sets the size of the gap between the totem icons."],
		softMin = 0,
		softMax = 100,
		step = 1,
		get = get,
		set = set,
		disabled = disabled,
		order = 12,
	},
	'totem_direction', {
		type = 'select',
		name = L["Totem direction"],
		desc = L["Choose wether to grow horizontally or vertically."],
		get = get,
		set = set,
		values = {
			["h"] = L["Horizontal"],
			["v"] = L["Vertical"]
		},
		disabled = disabled,
		order = 13,
	},
	'line_break', {
		type = 'range',
		name = L["Totems per line"],
		desc = L["How many totems to draw per line."],
		min = 1,
		max = MAX_TOTEMS,
		step = 1,
		get = get,
		set = set,
		disabled = disabled,
		order = 14,
	},
	'hide_inactive', {
		type = 'toggle',
		name = L["Hide inactive"],
		desc = L["Hides inactive totem icons completely."],
		get = get,
		set = set,
		disabled = disabled,
		order = 15,
	},
	'background_color', { -- color option
		type = 'color',
		hasAlpha = true,
		name = L["Background color"],
		desc = L["The background color behind the icons."],
		get = function(info)
			return color_option_get('main_background')
		end,
		set = function(info, r, g, b, a)
			color_option_set('main_background', r, g, b, a)
		end,
		disabled = disabled,
		order = 16,
	},
	'group_timer_spiral', {
		type = 'group',
		name = L["Spiral timer"],
		desc = L["Options relating to the spiral display timer."],
		inline = true,
		order = 18,
		disabled = disabled,
		args = {
			timer_spiral = {
				type = 'toggle',
				name = L["Enabled"],
				desc = L["Shows a cooldown spiral on the totem icons."],
				get = get,
				set = set,
				disabled = disabled,
				order = 1,
			},
			suppress_occ = {
				type = 'toggle',
				name = L["Suppress cooldown numbers"],
				desc = L["Try to stop addons from showing cooldown numbers on the spiral timer."],
				get = get,
				set = function(info, value)
					PitBull4.Options.GetLayoutDB(self).suppress_occ = value

					for frame in PitBull4:IterateFrames() do
						if self:GetLayoutDB(frame).enabled and frame.Totems then
							for _, element in ipairs(frame.Totems) do
								element.spiral.noCooldownCount = value
							end
							self:Update(frame)
						end
					end
				end,
				width = 'double',
				disabled = function()
					local db = PitBull4.Options.GetLayoutDB(self)
					return not db.timer_spiral or not db.enabled
				end,
				order = 2,
			},
		},
	},
	'group_timer_text', {
		type = 'group',
		name = L["Text timer"],
		desc = L["Options relating to the text display timer."],
		inline = true,
		order = 19,
		disabled = disabled,
		args = {
			timer_text = {
				type = 'toggle',
				name = L["Enabled"],
				desc = L["Shows the remaining time in as text."],
				get = get,
				set = set,
				order = 1,
				disabled = disabled,
			},
			timer_text_side = {
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
				disabled = function()
					local db = PitBull4.Options.GetLayoutDB(self)
					return not db.timer_text or not db.enabled
				end,
				order = 3,
			},
			sep = {
				type = "description",
				name = "",
				order = 4,
			},
			timer_text_color = { -- color option
				type = 'color',
				name = L["Color"],
				desc = L["Color of the timer text."],
				hasAlpha = true,
				get = function(info)
					return color_option_get('timer_text')
				end,
				set = function(info, r, g, b, a)
					color_option_set('timer_text', r, g, b, a)
				end,
				order = 5,
				disabled = function()
					local db = PitBull4.Options.GetLayoutDB(self)
					return global_option_get('text_color_per_element') or not db.timer_text or not db.enabled
				end,
			},
			text_color_per_element = { -- global option
				type = 'toggle',
				name = L["Color text by element"],
				get = global_option_get,
				set = gOptSet,
				order = 6,
				disabled = function()
					local db = PitBull4.Options.GetLayoutDB(self)
					return not db.timer_text or not db.enabled
				end,
			},
		}
	},
	'global_notice_header', {
		type = 'header',
		name = L["Did you know?"],
		order = 30,
	},
	'global_notice_description', {
		type = 'description',
		name = L["There are more options for this module in the Modules -> Totems section."],
		order = 31,
	},
	'description_player_only', {
		type = 'description',
		name = "\n"..L["Totems only show for the Player. On all other units the frame will not be there, even when enabled in the layout of the frame."],
		order = 34,
	}
end)

local function get_elements_color_group()
	local function get(info)
		return color_option_get(info, 1,1,1,1 )
	end
	local function set(info, ...)
		color_option_set(info, ...)
	end

	local oo = {}

	oo['colordesc'] = {
		type = 'description',
		name = L["These color definitions will be used by per-element settings that need seperate color info per element."],
		order = 1,
	}

	for i = 1, MAX_TOTEMS do
		local verbose_name = get_verbose_slot_name(i)
		local slot = {
			type = 'color',
			name = verbose_name,
			desc = verbose_name,
			hasAlpha = true,
			get = get,
			set = set,
			arg = i,
			order = 10+i,
			--disabled = getHide,
		}
		oo['slot'..tostring(i)] = slot
	end
	return oo
end

local function get_sound_option_group()
	local so = {}
	so['death_sound'] = {
		type = 'toggle',
		width = 'full',
		name = L["Totemsounds"],
		desc = L["This plays a sound file when a totem expires or gets destroyed. Individual sounds can be set per element."],
		get = global_option_get,
		set = gOptSet,
		order = 1,
	}
	if LibSharedMedia then
		for i = 1, MAX_TOTEMS do
			local verbose_name = get_verbose_slot_name(i)
			local slot = {
				name = verbose_name,
				desc = verbose_name,
				type = 'select',
				width = 'double',
				values = function(info)
					return LibSharedMedia:HashTable("sound")
				end,
				get = function(info)
					return global_option_get(info) or DEFAULT_SOUND_NAME
				end,
				set = gOptSet,
				arg = i,
				disabled = function() return not global_option_get('death_sound') end,
				order = 10 + i,
				dialogControl = "LSM30_Sound",
			}
			so["sound_slot"..tostring(i)] = slot
		end
	else
		so['no_libsharedmedia_sound_header'] = {
			type = 'header',
			name = L["No LibSharedMedia detected"],
			order = 2,
		}
		so['no_libsharedmedia_sound_description'] = {
			type = 'description',
			name = L["You do not appear to have any addon installed that uses LibSharedMedia. If you want to select which sounds are used it is recommended that you install at least the 'SharedMedia' addon. (Don't install the 'LibSharedMedia' library yourself.)"],
			order = 3,
		}
	end
	return so
end

PitBull4_Totems:SetGlobalOptionsFunction(function(self)
	return 'layout_notice_header', {
		type = 'header',
		name = L["Did you know?"],
		order = 128,
		width = 'full',
	},
	'layout_notice_description', {
		type = 'description',
		name = L["There are more options for this module in the Layout editor -> Indicators -> Totems section."],
		order = 129,
		width = 'full',
	},
	'group_pulse', {
		type = 'group',
		name = L["Pulsing"],
		desc = L["Options related to the pulsing visualisation."],
		order = 111,
		inline = true,
		args = {
			expiry_pulse = {
				type = 'toggle',
				width = 'full',
				name = L["Expiry pulse"],
				desc = L["Causes the icon to pulse in the last few seconds of its lifetime."],
				get = global_option_get,
				set = gOptSet,
				order = 10,
			},
			expiry_pulse_time = {
				type = 'range',
				width = 'double',
				name = L["Expiry time"],
				desc = L["Pulse for this many seconds before the totem runs out."],
				min = 0.5,
				max = 60,
				step = 0.5,
				get = global_option_get,
				set = gOptSet,
				order = 11,
				disabled = function() return not global_option_get('expiry_pulse') end
			},
		},
	},
	'group_totem_sound', {
		type = 'group',
		name = L["Sounds"],
		desc = L["Options relating to sound effects on totem events."],
		order = 114,
		inline = true,
		args = get_sound_option_group(),
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
	return 'color_group_frames', {
		type = 'group',
		name = L["Backgrounds"],
		inline = true,
		args = {
			main_background = { -- color option
				type = 'color',
				name = L["Main background"],
				desc = L["Sets the color and transparency of the background of the timers."],
				hasAlpha = true,
				get = get,
				set = set,
				width = 'full',
				order = 1
			},
		}
	},
	'color_group_icon_border', {
		type = 'group',
		name = L["Borders"],
		inline = true,
		args = {
			totem_border = { -- color option
				type = 'color',
				name = L["Icon"],
				desc = L["Sets the color of the individual iconborders."],
				hasAlpha = true,
				get = get,
				set = set,
				order = 1,
				disabled = function() return global_option_get('totem_borders_per_element') end
			},
			totem_borders_per_element = { -- global option
				type = 'toggle',
				name = L["Color icon by element"],
				get = global_option_get,
				set = gOptSet,
				order = 2,
			},
		}
	},
	'color_group_timer_text', {
		type = 'group',
		name = L["Text timer"],
		inline = true,
		args = {
			timer_text = { -- color option
				type = 'color',
				name = L["Text"],
				desc = L["Color of the timer text."],
				hasAlpha = true,
				get = get,
				set = set,
				order = 1,
				disabled = function() return global_option_get('text_color_per_element') end,
			},
			text_color_per_element = { --global option
				type = 'toggle',
				name = L["Color text by element"],
				get = global_option_get,
				set = gOptSet,
				order = 2,
			},
		}
	},
	'color_group_elements', {
		type = 'group',
		name = L["Elements"],
		inline = true,
		args = get_elements_color_group(),
	}, function(info)
		local db = self.db.profile.global.colors
		for setting,value in pairs(COLOR_DEFAULTS) do
			if type(value) == "table" then
				for i = 1, #value do
					db[setting][i] = value[i]
				end
			else
				db[setting] = value
			end
		end
		gOptSet('totem_borders_per_element', true)
		gOptSet('text_color_per_element', false)
		-- update frames...
		self:UpdateAll()
	end
end)
