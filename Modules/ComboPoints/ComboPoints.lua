
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local player_class = UnitClassBase("player")
local is_rogue = player_class == "ROGUE"
local is_druid = player_class == "DRUID"

-- CONSTANTS ----------------------------------------------------------------

local BASE_TEXTURE_PATH = [[Interface\AddOns\PitBull4\Modules\ComboPoints\]]

local SPELL_POWER_COMBO_POINTS = Enum.PowerType.ComboPoints

local TEXTURES = {
	default = L["Default"],
}

local ICON_SIZE = 15
local BORDER_SIZE = 3

-----------------------------------------------------------------------------

local PitBull4_ComboPoints = PitBull4:NewModule("ComboPoints")

PitBull4_ComboPoints:SetModuleType("indicator")
PitBull4_ComboPoints:SetName(L["Combo points"])
PitBull4_ComboPoints:SetDescription(L["Show combo points on the unit frame if you are a Rogue or Druid in Cat form."])
PitBull4_ComboPoints:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_right",
	position = 1,
	vertical = false,
	size = 0.75,
	color = { 0.7, 0.7, 0 },
	overflow_color = { 0.0, 0.5, 1 },
	spacing = 5,
	texture = "default",
	has_background_color = false,
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_ComboPoints:OnEnable()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	if is_druid and ClassicExpansionAtLeast(LE_EXPANSION_DRAGONFLIGHT) then
		self:RegisterEvent("UNIT_AURA")
	end
	if ClassicExpansionAtLeast(LE_EXPANSION_WARLORDS_OF_DRAENOR) then
		self:RegisterEvent("UNIT_DISPLAYPOWER")
		self:RegisterEvent("UNIT_EXITED_VEHICLE", "UNIT_DISPLAYPOWER")
	else
		self:RegisterEvent("UNIT_MAXPOWER")
		self:RegisterUnitEvent("UNIT_EXITED_VEHICLE", nil, "player")
		if is_druid then
			self:RegisterEvent("UPDATE_SHAPESHIFT_FORM", "UNIT_EXITED_VEHICLE")
		end
	end
end

function PitBull4_ComboPoints:UNIT_POWER_FREQUENT(_, unit, power_type)
	if unit ~= "player" and unit ~= "pet" then return end
	if power_type ~= "COMBO_POINTS" then return end

	if ClassicExpansionAtLeast(LE_EXPANSION_WARLORDS_OF_DRAENOR) then
		for frame in PitBull4:IterateFramesForUnitIDs("player", "pet", "target") do
			self:Update(frame)
		end
	else
		self:UpdateForUnitID("target")
	end
end

function PitBull4_ComboPoints:UNIT_DISPLAYPOWER(event, unit)
	if unit ~= "player" and unit ~= "pet" then return end

	for frame in PitBull4:IterateFramesForUnitIDs("player", "pet", "target") do
		self:Update(frame)
	end
end

function PitBull4_ComboPoints:UNIT_AURA(_, unit, info)
	if unit ~= "player" or info == nil then
        return
    end

	-- Only need to process if flowing power triggers an update
	local overflowingPowerChanged = false
	local overflowingPowerRemoved = false

	-- Check if Overflowing Power was added
	if info.addedAuras then
		for _, aura in ipairs(info.addedAuras) do
			if aura.spellId == 405189 then
				overflowingPowerChanged = true
				self.overflowingPowerInstanceID = aura.auraInstanceID
				break
			end
		end
	end

	-- Check if Overflowing Power was updated
	if not overflowingPowerChanged then
		for _, auraInstanceID in ipairs(info.updatedAuraInstanceIDs or {}) do
			local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unit, auraInstanceID)
			if aura and aura.spellId == 405189 then
				self.overflowingPowerInstanceID = aura.auraInstanceID
				overflowingPowerChanged = true
				break
			end
		end
	end

	-- Check if Overflowing Power was removed
	if not overflowingPowerChanged then
		for _, auraInstanceID in ipairs(info.removedAuraInstanceIDs or {}) do
			if self.overflowingPowerInstanceID and self.overflowingPowerInstanceID == auraInstanceID then
				self.overflowingPowerInstanceID = auraInstanceID
				overflowingPowerChanged = true
				overflowingPowerRemoved = true
				break
			end
		end
	end

	if not overflowingPowerChanged then
		return
	end

	for frame in PitBull4:IterateFramesForUnitIDs("player", "pet", "target") do
		self:Update(frame)
	end

	if overflowingPowerRemoved then
		self.overflowingPowerInstanceID = nil
	end
end

function PitBull4_ComboPoints:UNIT_MAXPOWER(_, unit)
	if unit ~= "player" and unit ~= "pet" then return end

	self:UpdateForUnitID("target")
end

function PitBull4_ComboPoints:UNIT_EXITED_VEHICLE(_, unit)
	self:UpdateForUnitID("target")
end

function PitBull4_ComboPoints:ClearFrame(frame)
	if not frame.ComboPoints then
		return false
	end

	local combos = frame.ComboPoints
	combos.height = nil

	for i, combo in ipairs(combos) do
		combos[i] = combo:Delete()
	end
	if combos.bg then
		combos.bg = combos.bg:Delete()
	end
	frame.ComboPoints = combos:Delete()
	return true
end

function PitBull4_ComboPoints:UpdateFrame(frame)
	if frame.unit ~= "target" and frame.unit ~= "player" and frame.unit ~= "pet" then
		return self:ClearFrame(frame)
	elseif not ClassicExpansionAtLeast(LE_EXPANSION_WARLORDS_OF_DRAENOR) and frame.unit ~= "target" then
		return self:ClearFrame(frame)
	end

	local has_vehicle = UnitHasVehicleUI("player")
	if frame.unit == "pet" and not has_vehicle then
		return self:ClearFrame(frame)
	end

	local num_combos
	if ClassicExpansionAtLeast(LE_EXPANSION_WARLORDS_OF_DRAENOR) then
		num_combos = has_vehicle and GetComboPoints("vehicle", "target") or UnitPower("player", SPELL_POWER_COMBO_POINTS)
	else
		num_combos = GetComboPoints(has_vehicle and "vehicle" or "player", "target")
	end

	-- While non-rogues and non-druids typically don't have combo points, certain game
	-- mechanics may add them anyway (e.g. Malygos vehicles). Always show the combo
	-- point indicator if there are combo points.
	if num_combos == 0 then
		if not is_rogue and not is_druid then
			-- class doesn't normally use combo points
			return self:ClearFrame(frame)
		end
		if is_druid and GetShapeshiftFormID() ~= CAT_FORM then
			-- druid in non-cat form, don't show the bar
			return self:ClearFrame(frame)
		end
	end

	local max_combos = UnitPowerMax("player", SPELL_POWER_COMBO_POINTS)
	if max_combos == 0 then max_combos = 5 end

	if frame.force_show then
		num_combos = max_combos
	end

	-- Overflowing combo points while in berserk or incarnation
	local overflowing_stacks = nil
	if is_druid and ClassicExpansionAtLeast(LE_EXPANSION_DRAGONFLIGHT) then
		-- Test for Berserk / Incarnation: Avatar of Ashamane
		if C_UnitAuras.GetPlayerAuraBySpellID(106951) or C_UnitAuras.GetPlayerAuraBySpellID(102543) then
			-- Check for Overflowing Power
			local aura = C_UnitAuras.GetPlayerAuraBySpellID(405189)
			overflowing_stacks = aura and (aura.applications or 0)
		end
	end

	local db = self:GetLayoutDB(frame)
	if num_combos == 0 and not db.has_background_color then
		return self:ClearFrame(frame)
	end
	local combos = frame.ComboPoints

	if not self.overflowingPowerInstanceID and combos and #combos == num_combos then
		combos:Show()
		return false
	end

	local spacing = db.spacing
	local vertical = db.vertical

	if not combos then
		combos = PitBull4.Controls.MakeFrame(frame)
		frame.ComboPoints = combos
		combos:SetFrameLevel(frame:GetFrameLevel() + 13)

		if db.has_background_color then
			local bg = PitBull4.Controls.MakeTexture(combos, "BACKGROUND")
			combos.bg = bg
			bg:SetColorTexture(unpack(db.background_color))
			bg:SetAllPoints(combos)

			local height
			if not vertical then
				height = ICON_SIZE + 2*BORDER_SIZE
				combos:SetHeight(height)
				combos:SetWidth(ICON_SIZE*max_combos + BORDER_SIZE*2 + spacing*(max_combos-1))
			else
				height = ICON_SIZE*max_combos + BORDER_SIZE*2 + spacing*(max_combos-1)
				combos:SetHeight(height)
				combos:SetWidth(ICON_SIZE + 2*BORDER_SIZE)
			end
			combos.height = height / ICON_SIZE
		end
	end

	if not db.has_background_color then
		if not vertical then
			combos:SetHeight(ICON_SIZE)
			combos:SetWidth(ICON_SIZE + (ICON_SIZE + spacing) * (num_combos - 1))
			combos.height = 1
		else
			local height = ICON_SIZE + (ICON_SIZE + spacing) * (num_combos - 1)
			combos:SetHeight(height)
			combos:SetWidth(ICON_SIZE)
			combos.height = height / ICON_SIZE
		end
	end

	for i = #combos, num_combos + 1, -1 do
		local combo = combos[i]

		combos[i] = combo:Delete()
	end

	for i = #combos + 1, num_combos do
		local combo = PitBull4.Controls.MakeTexture(combos, "ARTWORK")
		combos[i] = combo

		combo:SetTexture(BASE_TEXTURE_PATH .. db.texture)
		combo:SetWidth(ICON_SIZE)
		combo:SetHeight(ICON_SIZE)
		local border_size = db.has_background_color and BORDER_SIZE or 0
		if not vertical then
			combo:SetPoint("LEFT", combos, "LEFT", border_size + (i - 1) * (ICON_SIZE + spacing), 0)
		else
			combo:SetPoint("BOTTOM", combos, "BOTTOM", 0, border_size + (i - 1) * (ICON_SIZE + spacing))
		end
	end

	-- Color combos
	for i = 1, num_combos do
		local combo = combos[i]

		if i <= (overflowing_stacks or 0) then
			combo:SetVertexColor(unpack(db.overflow_color))
		else
			combo:SetVertexColor(unpack(db.color))
		end
	end

	combos:Show()

	return true
end

PitBull4_ComboPoints:SetLayoutOptionsFunction(function(self)
	local function get(info)
		return PitBull4.Options.GetLayoutDB(self)[info[#info]]
	end
	local function set(info, value)
		PitBull4.Options.GetLayoutDB(self)[info[#info]] = value

		for frame in PitBull4:IterateFramesForUnitIDs("player", "pet", "target") do
			self:Clear(frame)
			self:Update(frame)
		end
	end

	return 'vertical', {
		type = 'toggle',
		name = L["Vertical"],
		desc = L["Show the combo points stacked vertically instead of horizontally."],
		get = get,
		set = set,
	}, 'spacing', {
		type = 'range',
		name = L["Spacing"],
		desc = L["How much spacing to show between combo points."],
		get = get,
		set = set,
		softMin = 0,
		softMax = 15,
		step = 1,
	}, 'texture', {
		type = 'select',
		name = L["Texture"],
		desc = L["What texture to use for combo points."],
		get = get,
		set = set,
		values = TEXTURES,
		hidden = function(info)
			local i = 0
			for k in pairs(TEXTURES) do
				i = i + 1
				if i > 1 then
					return false
				end
			end
			return true
		end,
	}, 'color', {
		type = 'color',
		name = L["Color"],
		desc = L["What color the combo points should be."],
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).color)
		end,
		set = function(info, r, g, b)
			local color = PitBull4.Options.GetLayoutDB(self).color
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFramesForUnitIDs("player", "pet", "target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
	}, 'overflow_color', {
		type = 'color',
		name = L["Overflow Color"],
		desc = L["What color overflow combo points should be."],
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).overflow_color)
		end,
		set = function(info, r, g, b)
			local color = PitBull4.Options.GetLayoutDB(self).overflow_color
			color[1], color[2], color[3] = r, g, b

			for frame in PitBull4:IterateFramesForUnitIDs("player", "pet", "target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		disabled = function(info)
			return not is_druid and ClassicExpansionAtLeast(LE_EXPANSION_DRAGONFLIGHT)
		end
	}, 'has_background_color', {
		type = 'toggle',
		name = L["Has background color"],
		desc = L["Show a background color behind the icons."],
		get = get,
		set = set,
	}, 'background_color', {
		type = 'color',
		hasAlpha = true,
		name = L["Background color"],
		desc = L["The background color behind the icons."],
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).background_color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).background_color
			color[1], color[2], color[3], color[4] = r, g, b, a

			for frame in PitBull4:IterateFramesForUnitIDs("player", "pet", "target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		disabled = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return not db.has_background_color or not db.enabled
		end
	}
end)
