local _G = _G
local PitBull4 = _G.PitBull4

local DEBUG = PitBull4.DEBUG

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

-----------------------------------------------------------------------------

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
		frame = CreateFrame("Button", frame_name, UIParent, "SecureUnitButtonTemplate")
		frame:SetFrameStrata(PitBull4.UNITFRAME_STRATA)
		frame:SetFrameLevel(PitBull4.UNITFRAME_LEVEL)
		
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

local PitBull4_UnitFrame_DropDown = CreateFrame("Frame", "PitBull4_UnitFrame_DropDown", UIParent, "UIDropDownMenuTemplate")

-- from a unit, figure out the proper menu and, if appropriate, the corresponding ID
local function figure_unit_menu(unit)
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
		return "RAID_TARGET_ICON"
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

local function f()
	local unit = PitBull4_UnitFrame_DropDown.unit
	if not unit then
		return
	end
	
	local menu, id = figure_unit_menu(unit)
	if menu then
		UnitPopup_ShowMenu(PitBull4_UnitFrame_DropDown, menu, unit, nil, id)
	end
end
UIDropDownMenu_Initialize(PitBull4_UnitFrame_DropDown, f, "MENU", nil)
function UnitFrame:menu(unit)
	PitBull4_UnitFrame_DropDown.unit = unit
	ToggleDropDownMenu(1, nil, PitBull4_UnitFrame_DropDown, "cursor")
end

function UnitFrame:ProxySetAttribute(key, value)
	if self:GetAttribute(key) ~= value then
		self:SetAttribute(key, value)
	end
end

local moving_frame = nil
function SingletonUnitFrame__scripts:OnDragStart()
	if PitBull4.db.profile.lock_movement or InCombatLockdown() then
		return
	end
	
	-- this start/stop thing is to make WoW move the frame the initial few pixels between OnMouseDown and OnDragStart
	self:StartMoving()
	self:StopMovingOrSizing()
	
	moving_frame = self
	LibStub("LibSimpleSticky-1.0"):StartMoving(self, PitBull4.all_frames_list, 0, 0, 0, 0)
end

function SingletonUnitFrame__scripts:OnDragStop()
	if not moving_frame then return end
	moving_frame = nil
	LibStub("LibSimpleSticky-1.0"):StopMoving(self)
	
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
		GameTooltip_SetDefaultAnchor(GameTooltip, self)
		GameTooltip:SetUnit(self.unit)
		local r, g, b = GameTooltip_UnitColor(self.unit)
		GameTooltipTextLeft1:SetTextColor(r, g, b)
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
	
		local old_unit = self.unit
		if old_unit == new_unit then
			return
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
	self:UpdateGUID(nil)
end

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
	_G.ClickCastFrames[frame] = true
	table.insert(self.all_frames_list, frame)
	
	self.classification_to_frames[frame.classification][frame] = true
	
	if frame.is_wacky then
		self.wacky_frames[frame] = true
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
	overlay:SetFrameLevel(frame:GetFrameLevel() + 4)
	
	for k, v in pairs(UnitFrame__scripts) do
		frame:SetScript(k, v)
	end
	
	for k, v in pairs(frame.is_singleton and SingletonUnitFrame__scripts or MemberUnitFrame__scripts) do
		frame:SetScript(k, v)
	end
	
	for k, v in pairs(UnitFrame) do
		frame[k] = v
	end

	for k, v in pairs(frame.is_singleton and SingletonUnitFrame or MemberUnitFrame) do
		frame[k] = v
	end
	
	if not isExampleFrame then
		if frame.is_singleton then
			frame:SetMovable(true)
		end
		frame:RegisterForDrag("LeftButton")
		frame:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp","Button4Up","Button5Up")
		frame:SetAttribute("*type1", "target")
		frame:SetAttribute("*type2", "menu")
	end
	frame:SetAttribute("toggleForVehicle", true)
	
	UnitFrame__scripts:OnAttributeChanged(frame, "unit", frame:GetAttribute("unit"))
	
	frame:SetClampedToScreen(true)
end
PitBull4.ConvertIntoUnitFrame = PitBull4:OutOfCombatWrapper(PitBull4.ConvertIntoUnitFrame)

-- we store layout_db instead of layout, since if a new profile comes up, it'll be a distinct table
local seen_layout_dbs = setmetatable({}, {__mode='k'})

--- Recheck the layout of the unit frame, make sure it's up to date, and update the frame.
-- @usage frame:RefreshLayout()
function UnitFrame:RefreshLayout()
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
	
	if classification_db.click_through then
		self:EnableMouse(false)
	else
		self:EnableMouse(true)
	end
	
	self:RefixSizeAndPosition()

	if old_layout then
		self:Update(true, true)
	end
end
UnitFrame.RefreshLayout = PitBull4:OutOfCombatWrapper(UnitFrame.RefreshLayout)

--- Reset the size and position of the unit frame.
-- @usage frame:RefixSizeAndPosition()
function SingletonUnitFrame:RefixSizeAndPosition()
	local layout_db = self.layout_db
	local classification_db = self.classification_db
	
	self:SetWidth(layout_db.size_x * classification_db.size_x)
	self:SetHeight(layout_db.size_y * classification_db.size_y)
	self:SetScale(layout_db.scale * classification_db.scale)
	
	local scale = self:GetEffectiveScale() / UIParent:GetEffectiveScale()
	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "CENTER", classification_db.position_x / scale, classification_db.position_y / scale)
end
SingletonUnitFrame.RefixSizeAndPosition = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.RefixSizeAndPosition)

--- Activate the unit frame.
-- This is just a thin wrapper around RegisterUnitWatch.
-- @usage frame:Activate()
function SingletonUnitFrame:Activate()
	RegisterUnitWatch(self)
end
SingletonUnitFrame.Activate = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.Activate)

--- Deactivate the unit frame.
-- This is just a thin wrapper around UnregisterUnitWatch.
-- @usage frame:Deactivate()
function SingletonUnitFrame:Deactivate()
	UnregisterUnitWatch(self)
	self:Hide()
end
SingletonUnitFrame.Deactivate = PitBull4:OutOfCombatWrapper(SingletonUnitFrame.Deactivate)

function UnitFrame:ForceShow()
	if not self.force_show then
		self.force_show = true
	
		-- Continue to watch the frame but do the hiding and showing ourself
		UnregisterUnitWatch(self)
		RegisterUnitWatch(self, true)
	end

	-- Always make sure the frame is shown even if we think it already is
	self:Show()
end
UnitFrame.ForceShow = PitBull4:OutOfCombatWrapper(UnitFrame.ForceShow)

function UnitFrame:UnforceShow()
	if not self.force_show then
		return
	end
	self.force_show = nil
	
	-- Ask the SecureStateDriver to show/hide the frame for us
	UnregisterUnitWatch(self)
	RegisterUnitWatch(self)
end
UnitFrame.UnforceShow = PitBull4:OutOfCombatWrapper(UnitFrame.UnforceShow)

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
	return font or DEFAULT_FONT, DEFAULT_FONT_SIZE * layout_db.font_size * (size_multiplier or 1)
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
-- @param force_update force an update even if the guid isn't changed, but is non-nil
-- @usage frame:UpdateGUID(UnitGUID(frame.unit))
-- @usage frame:UpdateGUID(UnitGUID(frame.unit), true)
function UnitFrame:UpdateGUID(guid, force_update)
	if DEBUG then
		expect(guid, 'typeof', 'string;nil')
	end
	
	-- if the guids are the same, cut out, but don't if it's a wacky unit that has a guid.
	if not force_update and self.guid == guid and not (guid and self.is_wacky and not self.best_unit) then
		return
	end
	local previousGUID = self.guid
	self.guid = guid
	self:Update(previousGUID == guid)
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
