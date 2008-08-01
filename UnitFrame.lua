local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local DEBUG = PitBull4.DEBUG
local expect = PitBull4.expect

local mop_520 = select(4,GetBuildInfo()) >= 50200

-- CONSTANTS ----------------------------------------------------------------

local MODULE_UPDATE_ORDER = {
	"bar",
	"bar_provider",
	"indicator",
	"text_provider",
	"custom_text",
	"custom",
	"fader",
}


-- Handles hiding and showing singleton unit frames.  Please no tabs in this code if you edit it.
-- WoW can't render tabs in FontStrings and it makes the errors from this code look awful.
local Singleton_OnAttributeChanged = [[
  if name ~= "state-pb4visibility" and name ~= "state-unitexists" and name ~= "config_mode" then return end

  if name ~= "state-pb4visibility" then
    -- Replace the value with the state handler state if we weren't called
    -- on its state change
    value = self:GetAttribute("state-pb4visibility")
  end

  if self:GetAttribute("config_mode") then
    self:Show()
  elseif value == "show" then
    self:Show()
  elseif value == "hide" then
    self:Hide()
  else
    if UnitExists(self:GetAttribute("unit")) then
      self:Show()
    else
      self:Hide()
    end
  end
]]

--- Make a singleton unit frame.
-- @param unit the UnitID of the frame in question
-- @usage local frame = PitBull4:MakeSingletonFrame("player")
function PitBull4:MakeSingletonFrame(unit)
	if DEBUG then
		expect(unit, 'typeof', 'string')
	end
	
	local id = PitBull4.Utils.GetBestUnitID(unit)
	if not PitBull4.Utils.IsSingletonUnitID(id) then
		error(("Bad argument #1 to `MakeSingletonFrame'. %q is not a singleton UnitID"):format(tostring(unit)), 2)
	end
	unit = id
	
	local frame_name = "PitBull4_Frames_" .. unit
	local frame = _G[frame_name]
	
	if not frame then
		frame = CreateFrame("Button", frame_name, UIParent, "SecureUnitButtonTemplate,SecureHandlerBaseTemplate")
	
		frame:WrapScript(frame, "OnAttributeChanged", Singleton_OnAttributeChanged)
		frame.is_singleton = true
		
		-- for singletons, its classification is its UnitID
		local classification = unit
		frame.classification = classification
		frame.classification_db = PitBull4.db.profile.units[classification]
		
		local is_wacky = PitBull4.Utils.IsWackyUnitGroup(classification)
		frame.is_wacky = is_wacky
		
		self:ConvertIntoUnitFrame(frame)
		
		frame:SetAttribute("unit", unit)
	end
	
	frame:Activate()
	
	frame:RefreshLayout()
	
	frame:UpdateGUID(UnitGUID(unit))
end
PitBull4.MakeSingletonFrame = PitBull4:OutOfCombatWrapper(PitBull4.MakeSingletonFrame)

--- A Unit Frame created by PitBull4
-- @class table
-- @name UnitFrame
-- @field is_singleton whether the Unit Frame is a singleton or member
-- @field classification the classification of the Unit Frame
-- @field classification_db the database table for the Unit Frame's classification
-- @field layout the layout of the Unit Frame's classification
-- @field unit the UnitID of the Unit Frame. Can be nil.
-- @field guid the current GUID of the Unit Frame. Can be nil.
-- @field overlay an overlay frame for texts to be placed on.
local UnitFrame = {}
local SingletonUnitFrame = {}
local MemberUnitFrame = {}
PitBull4.UnitFrame = UnitFrame
PitBull4.SingletonUnitFrame = SingletonUnitFrame
PitBull4.MemberUnitFrame = MemberUnitFrame

local UnitFrame__scripts = {}
local SingletonUnitFrame__scripts = {}
local MemberUnitFrame__scripts = {}
PitBull4.UnitFrame__scripts = UnitFrame__scripts
PitBull4.SingletonUnitFrame__scripts = SingletonUnitFrame__scripts
PitBull4.MemberUnitFrame__scripts = MemberUnitFrame__scripts

-- All the old non-sense to try to work around menus that don't work.
-- It also injects menu items for ready and roll checks, but we can't
-- do that with this technique anymore.
local BLACKLISTED_UNIT_MENU_OPTIONS = {
	SET_FOCUS = "PB4_SET_FOCUS",
	CLEAR_FOCUS = "PB4_CLEAR_FOCUS",
	LOCK_FOCUS_FRAME = true,
	UNLOCK_FOCUS_FRAME = true,
}

local INSERT_UNIT_MENU_OPTIONS = {
	SELF = {"PB4_ROLE_CHECK","PB4_READY_CHECK"},
}

-----------------------------------------------------------------------------

UnitPopupButtons["PB4_SET_FOCUS"] = {
	text = L["Type %s to Set Focus"]:format(SLASH_FOCUS1),
	tooltipText = L["Blizzard currently does not provide a proper way to right-click focus with custom unit frames."],
	dist = 0,
}

UnitPopupButtons["PB4_CLEAR_FOCUS"] = {
	text = L["Type %s to Clear Focus"]:format(SLASH_CLEARFOCUS1),
	tooltipText = L["Blizzard currently does not provide a proper way to right-click focus with custom unit frames."],
	dist = 0,
}

UnitPopupButtons["PB4_ROLE_CHECK"] = {
	text = ROLE_POLL, 
	tooltipText = L["Initiate a role check, asking your group members to specify their roles."],
	dist = 0,
}

UnitPopupButtons["PB4_READY_CHECK"] = {
	text = READY_CHECK,
	tooltipText = L["Initiate a ready check, asking your group members if they are ready to continue."],
	dist = 0,
}

hooksecurefunc("UnitPopup_OnClick",function(self)
	local button = self.value
	if button == "PB4_ROLE_CHECK" then
		InitiateRolePoll()
	elseif button == "PB4_READY_CHECK" then
		DoReadyCheck()
	end
end)

hooksecurefunc("UnitPopup_HideButtons",function()
	local dropdownMenu = UIDROPDOWNMENU_INIT_MENU
	local inParty, inRaid, inBattleground, isLeader, isAssistant
	if IsInGroup() then 
		inParty = true 
	end
	if IsInRaid() then
		inRaid = true 
		inParty = true
	end
	if UnitInBattleground("player") then
		inBattleground = true
	end
	if UnitIsGroupLeader("player") then
		isLeader = true
	end
	if UnitIsGroupAssistant("player") then
		isAssistant = true
	end

	for index, value in ipairs(UnitPopupMenus[UIDROPDOWNMENU_MENU_VALUE] or UnitPopupMenus[dropdownMenu.which]) do
		if value == "PB4_ROLE_CHECK" then
			if (not isLeader and not isAssistant) or inBattleground or (not inParty and not inRaid) then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0
			end
		elseif value == "PB4_READY_CHECK" then
			if (not isLeader and not isAssistant) or inBattleground or (not inParty and not inRaid) then
				UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 0
			end
		end
	end
end)

local PitBull4_UnitFrame_DropDown = CreateFrame("Frame", "PitBull4_UnitFrame_DropDown", UIParent, "UIDropDownMenuTemplate")
UnitPopupFrames[#UnitPopupFrames+1] = "PitBull4_UnitFrame_DropDown"

-- from a unit, figure out the proper menu and, if appropriate, the corresponding ID
local function figure_unit_menu(unit)
	if unit == "focus" then
		return "FOCUS"
	end

	if UnitIsUnit(unit, "player") then
		return "SELF"
	end

	if UnitIsUnit(unit, "vehicle") then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		return "VEHICLE"
	end

	if UnitIsUnit(unit, "pet") then
		return "PET"
	end

	if not UnitIsPlayer(unit) then
		return "TARGET"
	end

	local id = UnitInRaid(unit)
	if id then
		return "RAID_PLAYER", id
	end

	if UnitInParty(unit) then
		return "PARTY"
	end

	return "PLAYER"
end

local munged_unit_menus = {}
local function munge_unit_menu(menu)
	local result = munged_unit_menus[menu]
	if result then
		return result
	end

	if not UnitPopupMenus then
		munged_unit_menus[menu] = menu
		return menu
	end

	local data = UnitPopupMenus[menu]
	if not data then
		munged_unit_menus[menu] = menu
		return menu
	end

	local found = false
	for _, v in ipairs(data) do
		if BLACKLISTED_UNIT_MENU_OPTIONS[v] then
			found = true
			break
		end
	end

	local insert = INSERT_UNIT_MENU_OPTIONS[menu]

	if not found and not insert then
		-- nothing to remove or add, we're all fine here.
		munged_unit_menus[menu] = menu
		return menu
	end

	local new_data = {}
	for _, v in ipairs(data) do
		local blacklisted = BLACKLISTED_UNIT_MENU_OPTIONS[v]
		if not blacklisted then
			if insert and v == "CANCEL" then
				for _,extra in ipairs(insert) do
					new_data[#new_data+1] = extra
				end
			end
			new_data[#new_data+1] = v
		elseif blacklisted ~= true then
			new_data[#new_data+1] = blacklisted
		end
	end
	local new_menu_name = "PB4_" .. menu

	UnitPopupMenus[new_menu_name] = new_data
	munged_unit_menus[menu] = new_menu_name
	return new_menu_name
end

local dropdown_unit = nil
UIDropDownMenu_Initialize(PitBull4_UnitFrame_DropDown, function()
	if not dropdown_unit then
		return
	end

	local menu, id = figure_unit_menu(dropdown_unit)
	if menu then
		menu = munge_unit_menu(menu)
		UnitPopup_ShowMenu(PitBull4_UnitFrame_DropDown, menu, dropdown_unit, nil, id)
	end
end, "MENU", nil)
function UnitFrame:menu(unit)
	dropdown_unit = unit
	ToggleDropDownMenu(1, nil, PitBull4_UnitFrame_DropDown, "cursor")
end

function UnitFrame:ProxySetAttribute(key, value)
	if self:GetAttribute(key) ~= value then
		self:SetAttribute(key, value)
		return true
	end
end

local moving_frame = nil
function SingletonUnitFrame__scripts:OnDragStart()
	local db = PitBull4.db.profile
	if db.lock_movement or InCombatLockdown() then
		return
	end
	
	self:StartMoving()
	moving_frame = self

	if db.frame_snap then
		-- stop thing is to make WoW move the frame the initial few pixels between
		-- OnMouseDown and OnDragStart
		self:StopMovingOrSizing()
	
		LibStub("LibSimpleSticky-1.0"):StartMoving(self, PitBull4.all_frames_list, 0, 0, 0, 0)
	end
end

function SingletonUnitFrame__scripts:OnDragStop()
	if moving_frame ~= self then return end
	moving_frame = nil
	if PitBull4.db.profile.frame_snap then
		LibStub("LibSimpleSticky-1.0"):StopMoving(self)
	else
		self:StopMovingOrSizing()
	end
	
	local ui_scale = UIParent:GetEffectiveScale()
	local scale = self:GetEffectiveScale() / ui_scale
	
	local x, y = self:GetCenter()
	x, y = x * scale, y * scale
	
	x = x - GetScreenWidth()/2
	y = y - GetScreenHeight()/2
	
	self.classification_db.position_x = x
	self.classification_db.position_y = y
	
	LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
	
	self:RefreshLayout()
end

function SingletonUnitFrame__scripts:OnMouseUp(button)
	if button == "LeftButton" then
		return SingletonUnitFrame__scripts.OnDragStop(self)
	end
end

function SingletonUnitFrame:PLAYER_REGEN_DISABLED()
	if moving_frame then
		SingletonUnitFrame__scripts.OnDragStop(moving_frame)
	end
end

function UnitFrame__scripts:OnEnter()
	if self.guid then
		local tooltip = self.classification_db.tooltip
		if tooltip == "always" or (tooltip == "ooc" and not InCombatLockdown()) then
			GameTooltip_SetDefaultAnchor(GameTooltip, self)
			GameTooltip:SetUnit(self.unit)
			local r, g, b = GameTooltip_UnitColor(self.unit)
			GameTooltipTextLeft1:SetTextColor(r, g, b)
		end
	end
	
	PitBull4:RunFrameScriptHooks("OnEnter", self)
end

function UnitFrame__scripts:OnLeave()
	GameTooltip:Hide()
	
	PitBull4:RunFrameScriptHooks("OnLeave", self)
end

function UnitFrame__scripts:OnAttributeChanged(key, value)
	if key == "unit" or key == "unitsuffix" then
		local new_unit = PitBull4.Utils.GetBestUnitID(SecureButton_GetModifiedUnit(self, "LeftButton")) or nil
	
		local updated = false
		local old_unit = self.unit

		-- As of 4.0.3 the the unit watch state handler no longer calls OnShow
		-- when the frame is already visible.  So you can't use that to detect
		-- that the unit on a frame has changed.  So we need to check for the
		-- GUID changing here.  However, if the frame is not shown we can't update
		-- the GUID or it hoses the update system.  So only update the GUID if
		-- we're already visible if we're not then the unit watch will update it
		-- normally.
		if self:IsVisible() then
			local guid = new_unit and UnitGUID(new_unit) or nil
			if guid ~= self.guid then
				self.unit = new_unit -- Make sure unit is set before updates happen.
				updated = true
				self:UpdateGUID(guid)
			end
		end

		if old_unit == new_unit then
			return
		end

		-- debug assertion to help try and track down ticket 475.
		if DEBUG then
			if not new_unit then
				expect(self.guid, '==', nil)
			end
		end
	
		if old_unit then
			PitBull4.unit_id_to_frames[old_unit][self] = nil
			PitBull4.unit_id_to_frames_with_wacky[old_unit][self] = nil
		end
	
		self.unit = new_unit
		if new_unit then
			PitBull4.unit_id_to_frames[new_unit][self] = true
			PitBull4.unit_id_to_frames_with_wacky[new_unit][self] = true
		end

		-- Hackaround Clique forcing the frames to use togglemenu, which
		-- is broken on raid frames.  Idea borrowed from ShadowedUF
		if new_unit and new_unit:sub(1, 4) == "raid" then
			self:WrapScript(self, "OnAttributeChanged", [[
        if value == "togglemenu" and self:GetAttribute("clique-shiv") == "1" then
          self:SetAttribute(name, "menu")
        end
      ]])
		end

		if not updated then
			self:Update(false)
		end
	elseif key == "state-unitexists" then
		if value then
			UnitFrame__scripts.OnShow(self)
		else
			UnitFrame__scripts.OnHide(self)
		end
	end
end

function UnitFrame__scripts:OnShow()
	if self.unit then
		local guid = UnitGUID(self.unit)
		if self.is_wacky or guid ~= self.guid then
			self:UpdateGUID(guid)
		end
	end
	
	self:SetAlpha(PitBull4:GetFinalFrameOpacity(self))
end

function UnitFrame__scripts:OnHide()
	self:GetScript("OnDragStop")(self)

	local force_show = self.force_show
	-- Clear the guid without causing an update unless the frame
	-- is force_shown in which case force an update.
	self:UpdateGUID(nil,force_show and true or false)
	if DEBUG then			
		-- debug test to help try and track down issue 475.  The
		-- guid should always end up set to nil after this.
		expect(self.guid, '==', nil)
	end
	if force_show then
		-- Nothing more to do the frame isn't really being hidden
		return
	end

	-- Iterate the modules and call their OnHide function to tell them 
	-- a frame was hidden.  They may very well be changing the frame and
	-- causing layout changes.  However, since the frame is hidden we
	-- do not track this or cause layout updates to happen.  They'll
	-- happen when the frame is shown again anyway.  Skip calling OnHide
	-- when dont_update is set becuase we're only temporarily hiding the
	-- frame for RefreshGroup().
	if not self.dont_update then
		for _, module_type in ipairs(MODULE_UPDATE_ORDER) do
			for _, module in PitBull4:IterateModulesOfType(module_type) do
				module:OnHide(self)
			end
		end
	end
end

-- Ugly hack function to allow running RegisterForClicks in cata.
-- This function is currently missing from the RestrictedFrames environment.
-- Frames created in combat won't have the ability to use the right click
-- menu on them until you leave combat the next time when this function runs.
local function register_for_clicks_helper(frame, clicks)
	frame:RegisterForClicks(clicks)
end
register_for_clicks_helper = PitBull4:OutOfCombatWrapper(register_for_clicks_helper)

--- Add the proper functions and scripts to a SecureUnitButton, as well as some various initialization.
-- @param frame a Button which inherits from SecureUnitButton
-- @param isExampleFrame whether the button is an example frame, thus not a real unit frame
-- @usage PitBull4:ConvertIntoUnitFrame(frame)
function PitBull4:ConvertIntoUnitFrame(frame, isExampleFrame)
	if DEBUG then
		expect(frame, 'typeof', 'frame')
		expect(frame, 'frametype', 'Button')
		expect(isExampleFrame, 'typeof', 'nil;boolean')
	end
	
	self.all_frames[frame] = true
	table.insert(self.all_frames_list, frame)
	
	self.classification_to_frames[frame.classification][frame] = true
	
	if frame.is_wacky then
		self.wacky_frames[frame] = true
		PitBull4.num_wacky_frames = PitBull4.num_wacky_frames + 1
	else
		self.non_wacky_frames[frame] = true
	end
	
	if frame.is_singleton then
		self.singleton_frames[frame] = true
	else
		self.member_frames[frame] = true
	end
	
	local overlay = PitBull4.Controls.MakeFrame(frame)
	frame.overlay = overlay
	overlay:SetFrameLevel(frame:GetFrameLevel() + 17)
	
	for k, v in pairs(UnitFrame__scripts) do
		frame:HookScript(k, v)
	end
	
	for k, v in pairs(frame.is_singleton and SingletonUnitFrame__scripts or MemberUnitFrame__scripts) do
		frame:HookScript(k, v)
	end
	
	for k, v in pairs(UnitFrame) do
		frame[k] = v
	end

	for k, v in pairs(frame.is_singleton and SingletonUnitFrame or MemberUnitFrame) do
		frame[k] = v
	end
	
	if not isExampleFrame then
		if frame:CanChangeAttribute() then
			if frame.is_singleton then
				frame:SetMovable(true)
			  frame:SetAttribute("*type1", "target")
			  frame:SetAttribute("*type2", mop_520 and "togglemenu" or "menu")
			end
			frame:RegisterForDrag("LeftButton")
			frame:RegisterForClicks("AnyUp")
		elseif not ClickCastHeader then
			-- if we can't set attributes directly and Clique isn't running
			-- then RegisterForClicks upon leaving combat.  Works around
			-- the lack of RegisterForClicks in the RestrictedFrames environment
			-- for cata.
			register_for_clicks_helper(frame, "AnyUp")
		end
	end
	frame:RefreshVehicle()
	
	frame:SetClampedToScreen(true)

	if frame.is_singleton then
		if not frame.classification_db.click_through then
			-- Only enable click casting if the frame isn't click_through.
			_G.ClickCastFrames[frame] = true
		end
	else
		if not ClickCastHeader then
			-- member unit frames are handled differently in cata.
			-- See the initialConfigFunction attribute on the GroupHeader.
			_G.ClickCastFrames[frame] = true
		end
	end
end

-- we store layout_db instead of layout, since if a new profile comes up, it'll be a distinct table
local seen_layout_dbs = setmetatable({}, {__mode='k'})
PitBull4.seen_layout_dbs = seen_layout_dbs

--- Reheck the toggleForVehicle attribute for the unit frame
-- @usage frame:RefreshVehicle()
function UnitFrame:RefreshVehicle()
	local classification_db = self.classification_db
	if not classification_db then
		return
	end

	local config_value = classification_db.vehicle_swap or nil 
	local frame_value = self:GetAttribute("toggleForVehicle")
	if self:CanChangeAttribute() and frame_value ~= config_value then
		self:SetAttribute("toggleForVehicle", config_value)
		local unit = self.unit
		if unit then
			PitBull4:UNIT_ENTERED_VEHICLE(nil, unit)
		end
	end
end

--- Recheck the layout of the unit frame, make sure it's up to date, and update the frame.
-- @usage frame:RefreshLayout()
function UnitFrame:_RefreshLayout()
	local old_layout = self.layout
	
	local classification_db = self.classification_db
	if not classification_db then
		return
	end
	
	local layout = classification_db.layout
	self.layout = layout
	self.layout_db = PitBull4.db.profile.layouts[layout]
	if not seen_layout_dbs[self.layout_db] then
		seen_layout_dbs[self.layout_db] = true
		PitBull4:CallMethodOnModules("OnNewLayout", layout)
	end

	self:SetClickThroughState(classification_db.click_through)

	self:RefixSizeAndPosition()

	if old_layout then
		self:Update(true, true)
	end
end
UnitFrame.RefreshLayout = PitBull4:OutOfCombatWrapper(UnitFrame._RefreshLayout)

-- Set the frame as able to be clicked through or not.
-- @usage frame:SetClickThroughState(true)
function SingletonUnitFrame:SetClickThroughState(state)
	local mouse_state = not not self:IsMouseEnabled()
	if not state ~= mouse_state then
		_G.ClickCastFrames[self] = not mouse_state
		self:EnableMouse(not mouse_state)
	end
end
SingletonUnitFrame.SetClickThroughState= PitBull4:OutOfCombatWrapper(SingletonUnitFrame.SetClickThroughState)

--- Reset the size and position of the unit frame.
-- @usage frame:RefixSizeAndPosition()
function SingletonUnitFrame:RefixSizeAndPosition()
	local layout_db = self.layout_db
	local classification_db = self.classification_db
	
	self:SetWidth(layout_db.size_x * classification_db.size_x)
	self:SetHeight(layout_db.size_y * classification_db.size_y)
	self:SetScale(layout_db.scale * classification_db.scale)
	self:SetFrameStrata(layout_db.strata)
	self:SetFrameLevel(layout_db.level)
	
	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "CENTER", classification_db.position_x / scale, classification_db.position_y / scale)
end
SingletonUnitFrame.RefixSizeAndPosition = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.RefixSizeAndPosition)

--- Activate the unit frame.
-- This handles UnitWatch and the custom StateDriver 
-- @usage frame:Activate()
function SingletonUnitFrame:Activate()
	RegisterUnitWatch(self, true)
	RegisterStateDriver(self, "pb4visibility", "[petbattle] hide; default")
end
SingletonUnitFrame.Activate = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.Activate)

--- Deactivate the unit frame.
-- This handles UnitWatch and the custom StateDriver 
-- @usage frame:Deactivate()
function SingletonUnitFrame:Deactivate()
	UnregisterUnitWatch(self)
	UnregisterStateDriver(self, "pb4visibility")
	self:SetAttribute("state-pb4visibility", nil)
	self:SetAttribute("state-unitexists", nil)
	self:Hide()
end
SingletonUnitFrame.Deactivate = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.Deactivate)

function SingletonUnitFrame:ForceShow()
	if not self.force_show then
		self.force_show = true
		self:SetAttribute("config_mode", true)
	end
end
SingletonUnitFrame.ForceShow = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.ForceShow)

function SingletonUnitFrame:UnforceShow()
	if not self.force_show then
		return
	end
	self.force_show = nil
	self:SetAttribute("config_mode", nil)
	
	-- If we're visible force an udpate so everything is properly in a
	-- non-config mode state
	if self:IsVisible() then
		self:Update()
	end
end
SingletonUnitFrame.UnforceShow = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.UnforceShow)

function UnitFrame:RecheckConfigMode()
	if PitBull4.config_mode and self.classification_db.enabled then
		self:ForceShow()
	else
		self:UnforceShow()
	end
	self:Update(true, true)
end

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end
local DEFAULT_FONT, DEFAULT_FONT_SIZE = ChatFontNormal:GetFont()

--- Get the font of the unit frame.
-- @param font_override nil or the LibSharedMedia name of a font
-- @param size_multiplier how much to multiply the default font size by. Defaults to 1.
-- @return path to the font
-- @return size of the font
-- @usage local font, size = frame:GetFont(db.font, db.size)
-- frame.MyModule:SetFont(font, size)
function UnitFrame:GetFont(font_override, size_multiplier)
	local layout_db = self.layout_db
	local font
	if LibSharedMedia then
		font = LibSharedMedia:Fetch("font", font_override or layout_db.font or "")
	end
	return font or DEFAULT_FONT, DEFAULT_FONT_SIZE * layout_db.font_size * (size_multiplier or 1) * self.classification_db.font_multiplier
end

local get_best_unit = PitBull4.get_best_unit
function UnitFrame:UpdateBestUnit()
	local old_best_unit = self.best_unit
	local new_best_unit = self.is_wacky and get_best_unit(self.guid) or nil
	if old_best_unit == new_best_unit then
		return
	end
	
	self.best_unit = new_best_unit
	
	if old_best_unit then
		PitBull4.unit_id_to_frames_with_wacky[old_best_unit][self] = nil
	end
	
	if new_best_unit then
		PitBull4.unit_id_to_frames_with_wacky[new_best_unit][self] = true
	end
end

--- Update all details about the UnitFrame, possibly after a GUID change
-- @param same_guid whether the previous GUID is the same as the current, at which point is less crucial to update
-- @param update_layout whether to update the layout no matter what
-- @usage frame:Update()
-- @usage frame:Update(true)
-- @usage frame:Update(false, true)
function UnitFrame:Update(same_guid, update_layout)
	if self.dont_update then
		return
	end
	if not self.guid and not self.force_show then
	 	if self.populated then
			self.populated = nil
			
			self:UpdateBestUnit()
			
			for _, module in PitBull4:IterateEnabledModules() do
				module:Clear(self)
			end
		end
		return
	elseif not self.classification_db or not self.layout_db then
		-- Possibly unused frame made for another profile
		return	
	end
	self.populated = true
	
	if not same_guid then
		self:UpdateBestUnit()
	end
	
	local changed = update_layout
	
	for _, module_type in ipairs(MODULE_UPDATE_ORDER) do
		for _, module in PitBull4:IterateModulesOfType(module_type) do
			changed = module:Update(self, true, same_guid) or changed
		end
	end
	
	if changed then
		self:UpdateLayout(false)
	end
end

--- Check the guid of the Unit Frame, if it is changed, then update the frame.
-- @param guid result from UnitGUID(unit)
-- @param update when true force an update even if the guid isn't changed, but is non-nil, when false never cause an update and when update is empty or nil let the function decide on its own if an update is needed.
-- @usage frame:UpdateGUID(UnitGUID(frame.unit))
-- @usage frame:UpdateGUID(UnitGUID(frame.unit), true)
function UnitFrame:UpdateGUID(guid, update)
	if DEBUG then
		expect(guid, 'typeof', 'string;nil')
	end
	
	-- if the guids are the same, cut out, but don't if it's a wacky unit that has a guid.
	if update ~= true and self.guid == guid and not (guid and self.is_wacky and not self.best_unit) then
		return
	end
	local previousGUID = self.guid
	self.guid = guid
	if update ~= false then
		self:Update(previousGUID == guid)
	end
end

local function iter(frame, id)
	local func, t = PitBull4:IterateEnabledModules()
	local id, module = func(t, id)
	if id == nil then
		return nil
	end
	if not frame[id] then
		return iter(frame, id)
	end
	return id, frame[id], module
end

--- Iterate over all controls on this frame
-- @usage for id, control, module in PitBull4.IterateControls() do
--     doSomethingWith(control)
-- end
-- @return iterator which returns the id, control, and module
function UnitFrame:IterateControls()
	return iter, self, nil
end

local iters = setmetatable({}, {__index=function(iters, module_type)
	local function iter(frame, id)
		local func, t = PitBull4:IterateModulesOfType(module_type)
		local id, module = func(t, id)
		if id == nil then
			return nil
		end
		if not frame[id] then
			return iter(frame, id)
		end
		return id, frame[id], module
	end
	iters[module_type] = iter
	return iter
end})

--- Iterate over all controls on this frame of the given type
-- @param module_type one of "bar", "indicator", "custom"
-- @usage for id, control, module in PitBull4.IterateControlsOfType("bar") do
--     doSomethingWith(control)
-- end
-- @return iterator which returns the id, control, and module
function UnitFrame:IterateControlsOfType(module_type)
	return iters[module_type], self, nil
end
