if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ComboPoints requires PitBull4")
end

-- CONSTANTS ----------------------------------------------------------------

local BASE_TEXTURE_PATH = [[Interface\AddOns\]] .. debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z]-%.lua") .. [[\]]

local L = PitBull4.L

local TEXTURES = {
	default = L["Default"],
}

local MAX_COMBOS = 5
local ICON_SIZE = 15
local BORDER_SIZE = 3

-----------------------------------------------------------------------------

local PitBull4_ComboPoints = PitBull4:NewModule("ComboPoints", "AceEvent-3.0")

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
	spacing = 5,
	texture = "default",
	has_background_color = false,
	background_color = { 0, 0, 0, 0.5 }
})

function PitBull4_ComboPoints:OnEnable()
	self:RegisterEvent("UNIT_COMBO_POINTS")
end

function PitBull4_ComboPoints:UNIT_COMBO_POINTS(event, unit)
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
	if frame.unit ~= "target" then
		return self:ClearFrame(frame)
	end
	
	local has_vehicle = UnitHasVehicleUI("player")
	
	local num_combos = GetComboPoints(has_vehicle and "vehicle" or "player", "target")
	
	if frame.force_show then
		num_combos = MAX_COMBOS
	end
	
	local db = self:GetLayoutDB(frame)
	if num_combos == 0 and not db.has_background_color then
		return self:ClearFrame(frame)
	end
	local combos = frame.ComboPoints
	
	if combos and #combos == num_combos then
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
			bg:SetTexture(unpack(db.background_color))
			bg:SetAllPoints(combos)

			local height
			if not vertical then
				height = ICON_SIZE + 2*BORDER_SIZE
				combos:SetHeight(height)
				combos:SetWidth(ICON_SIZE*MAX_COMBOS + BORDER_SIZE*2 + spacing*(MAX_COMBOS-1))
			else
				height = ICON_SIZE*MAX_COMBOS + BORDER_SIZE*2 + spacing*(MAX_COMBOS-1)
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
		combo:SetVertexColor(unpack(db.color))
		combo:SetWidth(ICON_SIZE)
		combo:SetHeight(ICON_SIZE)
		local border_size = db.has_background_color and BORDER_SIZE or 0
		if not vertical then
			combo:SetPoint("LEFT", combos, "LEFT", border_size + (i - 1) * (ICON_SIZE + spacing), 0)
		else
			combo:SetPoint("BOTTOM", combos, "BOTTOM", 0, border_size + (i - 1) * (ICON_SIZE + spacing))
		end
	end
	
	combos:Show()

	return true
end

PitBull4_ComboPoints:SetLayoutOptionsFunction(function(self)
	return 'vertical', {
		type = 'toggle',
		name = L["Vertical"],
		desc = L["Show the combo points stacked vertically instead of horizontally."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).vertical
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).vertical = value
			
			for frame in PitBull4:IterateFramesForUnitID("target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
	}, 'spacing', {
		type = 'range',
		name = L["Spacing"],
		desc = L["How much spacing to show between combo points."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).spacing
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).spacing = value
			
			for frame in PitBull4:IterateFramesForUnitID("target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		softMin = 0,
		softMax = 15,
		step = 1,
	}, 'texture', {
		type = 'select',
		name = L["Texture"],
		desc = L["What texture to use for combo points."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).texture
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).texture = value
			
			for frame in PitBull4:IterateFramesForUnitID("target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
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
			
			for frame in PitBull4:IterateFramesForUnitID("target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
	}, 'has_background_color', {
		type = 'toggle',
		name = L["Has background color"],
		desc = L["Show a background color behind the icons."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).has_background_color
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).has_background_color = value
			
			for frame in PitBull4:IterateFramesForUnitID("target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
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

			for frame in PitBull4:IterateFramesForUnitID("target") do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		disabled = function(info)
			return not PitBull4.Options.GetLayoutDB(self).has_background_color or
				   not PitBull4.Options.GetLayoutDB(self).enabled
		end
	}
end)
