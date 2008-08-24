--- A Unit Frame created by PitBull4
-- @class table
-- @name UnitFrame
-- @field is_singleton whether the Unit Frame is a singleton or member
-- @field classification the classification of the Unit Frame
-- @field classificationDB the database table for the Unit Frame's classification
-- @field layout the layout of the Unit Frame's classification
-- @field layoutDB the database table for the layout of the UnitFrame's classification
-- @field unitID the unitID of the Unit Frame. Can be nil.
-- @field guid the current GUID of the Unit Frame. Can be nil.
local UnitFrame = {}

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

local UnitFrame__scripts = {}
function UnitFrame__scripts:OnDragStart()
	self:StartMoving()
end

function UnitFrame__scripts:OnDragStop()
	self:StopMovingOrSizing()
	
	local x, y = self:GetCenter()
	x = x - GetScreenWidth()/2
	y = y - GetScreenHeight()/2
	
	self.classificationDB.position_x = x
	self.classificationDB.position_y = y
	self:ClearAllPoints()
	self:SetPoint("CENTER", UIParent, "CENTER", x, y)
end

function UnitFrame__scripts:OnEnter()
	GameTooltip_SetDefaultAnchor(GameTooltip, self)
	GameTooltip:SetUnit(self.unitID)
	local r, g, b = GameTooltip_UnitColor(self.unitID)
	GameTooltipTextLeft1:SetTextColor(r, g, b)
	
	PitBull4.RunFrameScriptHooks("OnEnter", self)
end

function UnitFrame__scripts:OnLeave()
	GameTooltip:Hide()
	
	PitBull4.RunFrameScriptHooks("OnLeave", self)
end

--- Add the proper functions and scripts to a SecureUnitButton
-- @param frame a Button which inherits from SecureUnitButton
-- @usage PitBull4.ConvertIntoUnitFrame(frame)
function PitBull4.ConvertIntoUnitFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	expect(frame, 'frametype', 'Button')
	--@end-alpha@
	
	for k, v in pairs(UnitFrame__scripts) do
		frame:SetScript(k, v)
	end
	
	for k, v in pairs(UnitFrame) do
		frame[k] = v
	end
	
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:RegisterForClicks("LeftButtonUp","RightButtonUp","MiddleButtonUp","Button4Up","Button5Up")
	frame:SetAttribute("*type1", "target")
	frame:SetAttribute("*type2", "menu")
end

--- Update all details about the UnitFrame, possibly after a GUID change
-- @param sameGUID whether the previous GUID is the same as the current, at which point is less crucial to update
-- @usage frame:Update()
-- @usage frame:Update(true)
function UnitFrame:Update(sameGUID)
	-- TODO
	if not self.guid then
		PitBull4.RunFrameScriptHooks("OnClear", self)
		self.populated = nil
	end
	
	if not self.populated then
		PitBull4.RunFrameScriptHooks("OnPopulate", self)
		self.populated = true
	end
	
	PitBull4.RunFrameScriptHooks("OnUpdate", self)
	local changed = false
	for id, module in PitBull4.IterateModulesOfType("statusbar", true) do
		changed = module:Update(self, true) or changed
	end
	if changed then
		self:UpdateLayout()
	end
end

--- Check the guid of the Unit Frame, if it is changed, then update the frame.
-- @param guid result from UnitGUID(unitID)
-- @param forceUpdate force an update even if the guid isn't changed, but is non-nil
-- @usage frame:UpdateGUID(UnitGUID(frame.unitID))
-- @usage frame:UpdateGUID(UnitGUID(frame.unitID), true)
function UnitFrame:UpdateGUID(guid)
	--@alpha@
	expect(guid, 'typeof', 'string;nil')
	--@end-alpha@
	
	-- if the guids are the same, cut out, but don't if it's a wacky unit that has a guid.
	if self.guid == guid and not (guid and self.is_wacky) then
		return
	end
	local previousGUID = self.guid
	self.guid = guid
	self:Update(previousGUID == guid)
end

--- Reposition all controls on the Unit Frame
-- @usage frame:UpdateLayout()
function UnitFrame:UpdateLayout()
	local bars = {}
	if self.HealthBar then
		bars[#bars+1] = self.HealthBar
	end
	if self.PowerBar then
		bars[#bars+1] = self.PowerBar
	end
	local height = self:GetHeight()
	local bar_height = height/#bars
	for i, bar in ipairs(bars) do
		bar:ClearAllPoints()
		bar:SetPoint("TOPLEFT", self, "TOPLEFT", 0, -bar_height * (i - 1))
		bar:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, -bar_height * i)
	end
end
