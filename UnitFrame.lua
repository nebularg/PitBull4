local _G = _G
local PitBull4 = _G.PitBull4

-- CONSTANTS ----------------------------------------------------------------

local MODULE_UPDATE_ORDER = {
	"status_bar",
	"icon",
	"custom_indicator",
	"text_provider",
	"custom_text",
	"custom",
	"fader",
}

-----------------------------------------------------------------------------

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

function SingletonUnitFrame__scripts:OnDragStart()
	self:StartMoving()
end

function SingletonUnitFrame__scripts:OnDragStop()
	self:StopMovingOrSizing()
	
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
	if key ~= "unit" and key ~= "unitsuffix" then
		return
	end
	
	local new_unit = PitBull4.Utils.GetBestUnitID(SecureButton_GetUnit(self)) or nil
	
	local old_unit = self.unit
	if old_unit == new_unit then
		return
	end
	
	if old_unit then
		PitBull4.unit_id_to_frames[old_unit][self] = nil
	end
	
	self.unit = new_unit
	if value then
		PitBull4.unit_id_to_frames[new_unit][self] = true
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
	self:UpdateGUID(nil)
end

--- Add the proper functions and scripts to a SecureUnitButton, as well as some various initialization.
-- @param frame a Button which inherits from SecureUnitButton
-- @param isExampleFrame whether the button is an example frame, thus not a real unit frame
-- @usage PitBull4:ConvertIntoUnitFrame(frame)
function PitBull4:ConvertIntoUnitFrame(frame, isExampleFrame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	expect(frame, 'frametype', 'Button')
	expect(isExampleFrame, 'typeof', 'nil;boolean')
	--@end-alpha@
	
	self.all_frames[frame] = true
	_G.ClickCastFrames[frame] = true
	
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
	
	UnitFrame__scripts:OnAttributeChanged(frame, "unit", frame:GetAttribute("unit"))
	
	frame:SetClampedToScreen(true)
end
PitBull4.ConvertIntoUnitFrame = PitBull4:OutOfCombatWrapper(PitBull4.ConvertIntoUnitFrame)

--- Recheck the layout of the unit frame, make sure it's up to date, and update the frame.
-- @usage frame:RefreshLayout()
function UnitFrame:RefreshLayout()
	local old_layout = self.layout
	
	local classification_db = self.classification_db
	
	local layout = classification_db.layout
	self.layout = layout
	
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
	local layout_db = PitBull4.db.profile.layouts[self.layout]
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

local do_nothing = function() end

function UnitFrame:ForceShow()
	if self.force_show then
		return
	end
	self.force_show = true
	self.Hide = do_nothing
	UnregisterUnitWatch(self)
	self:Show()
end
UnitFrame.ForceShow = PitBull4:OutOfCombatWrapper(UnitFrame.ForceShow)

function UnitFrame:UnforceShow()
	if not self.force_show then
		return
	end
	self.Hide = nil
	self.force_show = nil
	RegisterUnitWatch(self)
end
UnitFrame.UnforceShow = PitBull4:OutOfCombatWrapper(UnitFrame.UnforceShow)

--- Update all details about the UnitFrame, possibly after a GUID change
-- @param same_guid whether the previous GUID is the same as the current, at which point is less crucial to update
-- @param update_layout whether to update the layout no matter what
-- @usage frame:Update()
-- @usage frame:Update(true)
-- @usage frame:Update(false, true)
function UnitFrame:Update(same_guid, update_layout)
	-- TODO: something with same_guid
	if not self.guid and not self.force_show then
	 	if self.populated then
			self.populated = nil
			
			for _, module in PitBull4:IterateEnabledModules() do
				module:Clear(self)
			end
		end
		return
	end
	self.populated = true
	
	local changed = update_layout
	
	for _, module_type in ipairs(MODULE_UPDATE_ORDER) do
		for _, module in PitBull4:IterateModulesOfType(module_type) do
			changed = module:Update(self, true) or changed
		end
	end
	
	if changed then
		self:UpdateLayout()
	end
end

--- Check the guid of the Unit Frame, if it is changed, then update the frame.
-- @param guid result from UnitGUID(unit)
-- @param force_update force an update even if the guid isn't changed, but is non-nil
-- @usage frame:UpdateGUID(UnitGUID(frame.unit))
-- @usage frame:UpdateGUID(UnitGUID(frame.unit), true)
function UnitFrame:UpdateGUID(guid, force_update)
	--@alpha@
	expect(guid, 'typeof', 'string;nil')
	--@end-alpha@
	
	-- if the guids are the same, cut out, but don't if it's a wacky unit that has a guid.
	if not force_update and self.guid == guid and not (guid and self.is_wacky) then
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
-- @param module_type one of "status_bar", "icon", "custom_indicator", "custom"
-- @usage for id, control, module in PitBull4.IterateControlsOfType("status_bar") do
--     doSomethingWith(control)
-- end
-- @return iterator which returns the id, control, and module
function UnitFrame:IterateControlsOfType(module_type)
	return iters[module_type], self, nil
end
