local player_class = UnitClassBase("player")

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local wow_expansion = PitBull4.wow_expansion

-- CONSTANTS ----------------------------------------------------------------

local MAX_TOTEMS = 4
local TOTEM_ORDER = { 1, 2, 3, 4 }

local MAX_CLASS_TOTEMS
local REQUIRED_SPELL
if player_class == "DEATHKNIGHT" then
	MAX_CLASS_TOTEMS = 1
	REQUIRED_SPELL = {
		46584, -- Raise Dead (Unholy)
	}
elseif player_class == "MONK" then
	MAX_CLASS_TOTEMS = 1
	REQUIRED_SPELL = {
		115313, -- Summon Jade Serpent Statue (Mistweaver)
		115315, -- Summon Black Ox Statue (Brewmaster/Windwalker)
	}
elseif player_class == "PALADIN" then
	MAX_CLASS_TOTEMS = 1
	REQUIRED_SPELL = {
		26573, -- Consecration (Holy/Protection)
		205228, -- Consecration (Retribution)
	}
elseif player_class == "PRIEST" then
	MAX_CLASS_TOTEMS = 1
	REQUIRED_SPELL = {
		34433, -- Shadowfiend (Holy/Discipline)
	}
elseif player_class == "SHAMAN" then
	MAX_CLASS_TOTEMS = MAX_TOTEMS
	TOTEM_ORDER = { 4, 3, 2, 1 }
end
local TOTEM_SLOT_TO_INDEX = tInvert(TOTEM_ORDER)

local TOTEM_SIZE = 50 -- fixed value used for internal frame creation, change the final size ingame only!

local CONFIG_MODE_ICON = [[Interface\Icons\Spell_Fire_TotemOfWrath]]
local BORDER_PATH = [[Interface\AddOns\PitBull4\Modules\Totems\border]]
local DEFAULT_SOUND_NAME = "Drop"
local DEFAULT_SOUND_PATH = [[Sound\Interface\DropOnGround.ogg]]

local COLOR_DEFAULTS = {
	main_background = {0, 0, 0, 0.5},
	timer_text = {0, 1, 0, 1},
	totem_border = {0, 0, 0, 0.5},
	slot1 = {1,0,0,1},
	slot2 = {0,1,0,1},
	slot3 = {0,1,1,1},
	slot4 = {1,0,1,1},
}

local GetTotemTimeLeft = _G.GetTotemTimeLeft
local GetTotemInfo = _G.GetTotemInfo

-----------------------------------------------------------------------------

if not MAX_CLASS_TOTEMS then return end

local PitBull4_Totems = PitBull4:NewModule("Totems")

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
PitBull4_Totems:SetDefaults({
	attach_to = "root",
	location = "out_top_left",
	position = 1,
	size = 2, -- default to a 200% scaling, the 100% seems way too tiny.
	totem_spacing = 0,
	totem_direction = "h",
	timer_spiral = true,
	suppress_occ = true,
	timer_text = true,
	timer_text_side = "bottominside",
	line_break = MAX_TOTEMS,
	hide_inactive = false,
	bar_size = 1, -- needs to exist for "show as bar" option, unused for now
	totem_tooltips = true,
}, {
	expiry_pulse = true,
	expiry_pulse_time = 5,
	recast_enabled = false,
	death_sound = false,
	colors = COLOR_DEFAULTS,
	totem_borders_per_element = true,
	text_color_per_element = false,
	sound_slot1 = DEFAULT_SOUND_NAME,
	sound_slot2 = DEFAULT_SOUND_NAME,
	sound_slot3 = DEFAULT_SOUND_NAME,
	sound_slot4 = DEFAULT_SOUND_NAME,
})

function PitBull4_Totems:OnEnable()
	self:RegisterEvent("PLAYER_TOTEM_UPDATE")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "ForceSilentTotemUpdate")
	if wow_expansion < LE_EXPANSION_MISTS_OF_PANDARIA then
		self:RegisterEvent("CHARACTER_POINTS_CHANGED", "UpdateAll")
	else
		self:RegisterEvent("PLAYER_TALENT_UPDATE", "UpdateAll")
	end
end

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


local function format_time(seconds)
	if seconds >= 86400 then
		return DAY_ONELETTER_ABBR, floor(seconds / 86400)
	elseif seconds >= 3600 then
		return HOUR_ONELETTER_ABBR, ceil(seconds / 3600)
	elseif seconds >= 180 then
		return MINUTE_ONELETTER_ABBR, ceil(seconds / 60)
	elseif seconds > 60 then
		return "%d:%02d", seconds / 60, seconds % 60
	else
		return "%d", ceil(seconds)
	end
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
local function global_option_set(key, value)
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

-- Wrapper functions to simulate totems for config mode
local MyGetTotemTimeLeft, MyGetTotemInfo
do
	local config_times = {}
	function MyGetTotemTimeLeft(slot, frame)
		local time_left = GetTotemTimeLeft(slot)
		if frame.force_show and time_left == 0 then
			return max(0, config_times[slot] - GetTime())
		end
		return time_left
	end

	function MyGetTotemInfo(slot, frame)
		local hasTotem, name, startTime, duration, icon, _ = GetTotemInfo(slot)
		if frame.force_show and (not hasTotem or name == "") then
			local t = ceil(GetTime())
			local duration = math.random(30, 120)
			config_times[slot] = t + duration
			if REQUIRED_SPELL then
				local spell = REQUIRED_SPELL[1]
				name = C_Spell.GetSpellName(spell)
				icon = C_Spell.GetSpellTexture(spell)
			else
				name, icon = "Fake Totem", CONFIG_MODE_ICON
			end
			return true, name, t, duration, icon
		end
		return hasTotem, name, startTime, duration, icon
	end
end


function PitBull4_Totems:StartPulse(frame)
	frame.pulse_stop_after_this = false
	frame.pulse_start = true
	frame.last_updated = 0
end

function PitBull4_Totems:StopPulse(frame)
	frame.pulse_stop_after_this = false
	frame.pulse_start = false
	frame.pulse_active = false
	frame.pulse.icon:Hide()
	frame.last_updated = 0
end


function PitBull4_Totems:ActivateTotem(slot)
	local index = TOTEM_SLOT_TO_INDEX[slot]
	for frame in PitBull4:IterateFramesForUnitID("player") do
		if frame.Totems and frame.Totems.elements[index] then
			local _, _, startTime, duration, icon = MyGetTotemInfo(slot, frame)

			local element = frame.Totems.elements[index]
			local tframe = element.frame
			local tspiral = element.spiral

			tframe:SetNormalTexture(icon)
			tframe.totem_icon = icon
			tframe:SetAlpha(1)
			tframe:Show()
			tframe.force_show = frame.force_show -- set configmode as a property of the frame, so the buttonscripts know about it
			self:StopPulse(tframe)

			tframe.border:Show()

			if layout_option_get(frame, 'timer_text') then
				element.text:SetFormattedText(format_time(duration))
			end

			tspiral:SetCooldown(startTime, duration)
			tspiral:SetShown(layout_option_get(frame, 'timer_spiral'))
		end
	end
end

function PitBull4_Totems:DeactivateTotem(slot)
	local index = TOTEM_SLOT_TO_INDEX[slot]
	for frame in PitBull4:IterateFramesForUnitID("player") do
		if frame.Totems and frame.Totems.elements[index] then
			local element = frame.Totems.elements[index]

			element.frame:SetAlpha(0.5)
			element.frame.totem_icon = nil
			if layout_option_get(frame, 'hide_inactive') then
				element.frame:Hide()
			end
			self:StopPulse(element.frame)

			element.spiral:Hide()

			element.text:SetText("")
		end
	end
end

--------------------------------------------------------------
--------------------------------------------------------------
--------------------------------------------------------------
-- Frame functions

local function TimerTextAlignmentLogic(frame, parent, side, offsetX, offsetY)
	if not frame or not parent then return end

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
	end
end


PitBull4_Totems.button_scripts = {}

function PitBull4_Totems.button_scripts:OnClick(mouseButton)
	if mouseButton == "RightButton" and self.slot and not self.force_show then
		DestroyTotem(self.slot)
	end
end

function PitBull4_Totems.button_scripts:OnEnter()
	if not self.force_show and self.slot and self.totem_tooltips then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetTotem(self.slot)
	end
end

function PitBull4_Totems.button_scripts:UpdateTooltip()
	if GameTooltip:IsOwned(self) then
		GameTooltip:SetTotem(self.slot)
	end
end

function PitBull4_Totems.button_scripts:OnLeave()
	if GameTooltip:IsOwned(self) then
		GameTooltip:Hide()
	end
end


-- inline credits: Parts of the following function were heavily inspired by the addon CooldownButtons by Dodge (permission given)
function PitBull4_Totems.button_scripts:OnUpdate(elapsed)
	-- Update timer
	local timeleft = MyGetTotemTimeLeft(self.slot, self.owner)
	if timeleft > 0 then
		if layout_option_get(self.owner, 'timer_text') then
			self.text:SetFormattedText(format_time(timeleft))
		else
			self.text:SetText("")
		end

		if global_option_get('expiry_pulse') and timeleft < global_option_get('expiry_pulse_time') then
			PitBull4_Totems:StartPulse(self)
		elseif self.pulse_start then
			PitBull4_Totems:StopPulse(self)
		end
	else
		-- Totem expired
		PitBull4_Totems:StopPulse(self)
		self:SetAlpha(0.5)
		if layout_option_get(self.owner, 'hide_inactive') then
			self:Hide()
		end
		self.text:SetText("")
		self.spiral:Hide()
		return
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
			local pulse = self.pulse
			if pulse then
				pulse.scale = 1
				pulse.icon:SetTexture(self.totem_icon)
				self.pulse_active = true
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

	local haveTotem, name = GetTotemInfo(slot)
	if name == "" then return end

	if haveTotem then
		-- New totem created
		self:ActivateTotem(slot)
	else
		-- Totem just got removed or killed
		self:DeactivateTotem(slot)

		-- Sound functions
		if global_option_get('death_sound') and event then
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





function PitBull4_Totems:BuildFrames(frame)
	if not frame or frame.Totems then
		return false
	end

	local font, fontsize = self:GetFont(frame)
	local tSpacing = layout_option_get(frame,'totem_spacing')

	-- Main frame

	frame.Totems = PitBull4.Controls.MakeFrame(frame)
	local ttf = frame.Totems

	if (layout_option_get(frame,'totem_direction') == "h") then
		ttf:SetWidth((MAX_CLASS_TOTEMS*TOTEM_SIZE)+((MAX_CLASS_TOTEMS-1)*tSpacing))
		ttf:SetHeight(TOTEM_SIZE)
	else
		ttf:SetWidth(TOTEM_SIZE)
		ttf:SetHeight((MAX_CLASS_TOTEMS*TOTEM_SIZE)+((MAX_CLASS_TOTEMS-1)*tSpacing))
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
	for i = 1, MAX_CLASS_TOTEMS do
		-------------------------------
		-- Main totem slot frame
		elements[i] = {}
		if not elements[i].frame then
			elements[i].frame = PitBull4.Controls.MakeButton(ttf)
		end
		local frm = elements[i].frame

		frm:SetWidth(TOTEM_SIZE)
		frm:SetHeight(TOTEM_SIZE)
		frm:SetFrameLevel(frame:GetFrameLevel() + 13)
		frm:Hide()
		frm.slot = TOTEM_ORDER[i]
		frm.hide_inactive = layout_option_get(frame,'hide_inactive')
		frm.owner = frame

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
		spiral:SetAllPoints(frm)
		spiral:SetReverse(true)
		spiral:SetDrawEdge(false)
		spiral:SetDrawSwipe(true)
		local hide_countdown = layout_option_get(frame, 'suppress_occ')
		spiral:SetHideCountdownNumbers(hide_countdown)
		spiral.noCooldownCount = hide_countdown or nil
		spiral:Show()
		frm.spiral = spiral

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
		frm.text = text

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


		-----------------
		-- Click handling
		-- click handling for destroying single totems
		frm:RegisterForClicks("RightButtonUp")
		frm:SetScript("OnClick", self.button_scripts.OnClick)
		-- tooltip handling
		frm:SetScript("OnEnter", self.button_scripts.OnEnter)
		frm:SetScript("OnLeave", self.button_scripts.OnLeave)
		frm.UpdateTooltip = self.button_scripts.OnEnter
		frm.last_update = 1
		frm:SetScript("OnUpdate", self.button_scripts.OnUpdate)
	end

	ttf.elements = elements

	return true
end




local function HasRequiredSpell()
	for _, spell in next, REQUIRED_SPELL do
		if IsPlayerSpell(spell) then
			return true
		end
	end
	return false
end

function PitBull4_Totems:UpdateFrame(frame)
	if frame.unit ~= "player" then
		return self:ClearFrame(frame)
	end

	if REQUIRED_SPELL and not HasRequiredSpell() then
		return self:ClearFrame(frame)
	end

	-- Workaround for Worldmap hiding elements the moment it's shown.
	if frame.Totems and not frame.Totems:IsShown() then
		frame.Totems:Show()
	end

	local created = self:BuildFrames(frame)

	-- Background color of the main frame
	frame.Totems.background:SetColorTexture(color_option_get('main_background'))

	-- RealignTotems
	local lbreak = min(MAX_CLASS_TOTEMS, layout_option_get(frame, 'line_break') or MAX_TOTEMS)
	local tspacing = layout_option_get(frame, 'totem_spacing') or 0

	local elements = frame.Totems.elements
	for i = 1, MAX_CLASS_TOTEMS do
		local slot = TOTEM_ORDER[i]
		if i == 1 then
			elements[i].frame:ClearAllPoints()
			elements[i].frame:SetPoint("TOPLEFT", frame.Totems, "TOPLEFT", 0, 0)
		else
			elements[i].frame:ClearAllPoints()
			-- Attach the button to the previous one
			if layout_option_get(frame, 'totem_direction') == "h" then
				-- grow horizontally
				if (i - 1) % lbreak == 0 then
					-- Reached a line_break
					elements[i].frame:SetPoint("TOPLEFT", elements[i-lbreak].frame, "BOTTOMLEFT", 0, 0-tspacing)
				else
					elements[i].frame:SetPoint("TOPLEFT", elements[i-1].frame, "TOPRIGHT", tspacing, 0)
				end
			else
				--grow vertically
				if (i - 1) % lbreak == 0 then
					elements[i].frame:SetPoint("TOPLEFT", elements[i-lbreak].frame, "TOPRIGHT", tspacing, 0)
				else
					elements[i].frame:SetPoint("TOPLEFT", elements[i-1].frame, "BOTTOMLEFT", 0, 0-tspacing)
				end
			end
		end

		-- ApplyLayoutSettings
		elements[i].frame.hide_inactive = layout_option_get(frame, 'hide_inactive')
		elements[i].frame.totem_tooltips = layout_option_get(frame, 'totem_tooltips')
		elements[i].spiral:SetShown(layout_option_get(frame, 'timer_spiral'))

		-- UpdateIconColor
		elements[i].frame.border:Hide()
		if global_option_get('totem_borders_per_element') then
			elements[i].frame.border:SetVertexColor(color_option_get('slot'..tostring(slot), 1,1,1,1))
		else
			elements[i].frame.border:SetVertexColor(color_option_get('totem_border'))
		end
		elements[i].frame.border:Show()

	-- RealignTimerTexts
		if elements[i].text then
			TimerTextAlignmentLogic(elements[i].text, elements[i].textFrame, layout_option_get(frame, 'timer_text_side'), 0, 0)
			local font, fontsize = self:GetFont(frame)
			elements[i].text:SetFont(font, fontsize, "OUTLINE")

			if global_option_get('text_color_per_element') then
				elements[i].text:SetTextColor(color_option_get('slot'..tostring(slot), 1,1,1,1))
			else
				elements[i].text:SetTextColor(color_option_get('timer_text'))
			end
		end
	end

	-- ResizeMainFrame
	local nlines = ceil(MAX_CLASS_TOTEMS / lbreak)
	if layout_option_get(frame, 'totem_direction') == "h" then
		frame.Totems:SetWidth( (lbreak*TOTEM_SIZE)+((lbreak-1)*tspacing) )
		frame.Totems:SetHeight( (nlines*TOTEM_SIZE)+((nlines-1)*tspacing) )
		frame.Totems.height = nlines + ((nlines-1)*(tspacing/TOTEM_SIZE))
	else
		frame.Totems:SetWidth( (nlines*TOTEM_SIZE)+((nlines-1)*tspacing) )
		frame.Totems:SetHeight( (lbreak*TOTEM_SIZE)+((lbreak-1)*tspacing) )
		frame.Totems.height = lbreak + ((lbreak-1)*(tspacing/TOTEM_SIZE))
	end

	self:ForceSilentTotemUpdate()

	if frame.force_show then
		for i = 1, MAX_CLASS_TOTEMS do
			local slot = elements[i].frame.slot
			local active, name = GetTotemInfo(slot)
			if not active or name == "" then
				self:ActivateTotem(slot)
			end
		end
	end

	return created
end

function PitBull4_Totems:ClearFrame(frame)
	if not frame.Totems then
		return false
	end

	-- cleanup the element frames
	for i = 1, MAX_CLASS_TOTEMS do
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
	'totem_tooltips', {
		type = 'toggle',
		name = L["Tooltip"],
		desc = L["Enables tooltips when hovering over the icons."],
		get = get,
		set = set,
		disabled = disabled,
		order = 16,
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
		order = 17,
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
				name = "Hide countdown number",
				-- name = L["Suppress cooldown numbers"],
				-- desc = L["Try to stop addons from showing cooldown numbers on the spiral timer."],
				get = get,
				set = function(info, value)
					PitBull4.Options.GetLayoutDB(self).suppress_occ = value

					for frame in PitBull4:IterateFramesForUnitID("player") do
						if frame.Totems and frame.Totems.elements then
							for _, element in ipairs(frame.Totems.elements) do
								element.spiral:SetHideCountdownNumbers(value)
								element.spiral.noCooldownCount = value or nil
							end
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
				set = global_option_set,
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
		oo['slot'..tostring(i)] = {
			type = 'color',
			name = ("[%d] %s"):format(i, get_verbose_slot_name(i)),
			hasAlpha = true,
			get = get,
			set = set,
			arg = i,
			order = 10+i,
			--disabled = getHide,
		}
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
		set = global_option_set,
		order = 1,
	}
	if LibSharedMedia then
		for i = 1, MAX_TOTEMS do
			so["sound_slot"..tostring(i)] = {
				name = ("[%d] %s"):format(i, get_verbose_slot_name(i)),
				type = 'select',
				width = 'double',
				values = function(info)
					return LibSharedMedia:HashTable("sound")
				end,
				get = function(info)
					return global_option_get(info) or DEFAULT_SOUND_NAME
				end,
				set = global_option_set,
				arg = i,
				disabled = function() return not global_option_get('death_sound') end,
				order = 10 + i,
				dialogControl = "LSM30_Sound",
			}
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
				set = global_option_set,
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
				set = global_option_set,
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
				set = global_option_set,
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
				set = global_option_set,
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
		local db = self.db.profile.global
		for key, value in next, COLOR_DEFAULTS do
			for i = 1, #value do
				db.colors[key][i] = value[i]
			end
		end
		db.totem_borders_per_element = true
		db.text_color_per_element = false
		self:UpdateAll()
	end
end)
