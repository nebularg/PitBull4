if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ComboPoints requires PitBull4")
end

-- CONSTANTS ----------------------------------------------------------------

local TEXTURE_PATH = [[Interface\AddOns\]] .. debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z]-%.lua") .. [[\combo]]

-----------------------------------------------------------------------------

local PitBull4_ComboPoints = PitBull4:NewModule("ComboPoints", "AceEvent-3.0")

PitBull4_ComboPoints:SetModuleType("custom_indicator")
PitBull4_ComboPoints:SetName("Combo Points")
PitBull4_ComboPoints:SetDescription("Show combo points on the unit frame if you are a Rogue or Druid in Cat form.")
PitBull4_ComboPoints:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_right",
	position = 1,
	vertical = false,
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
	combos.vertical = nil
	combos.height = nil
	
	for i, combo in ipairs(combos) do
		combos[i] = combo:Delete()
	end
	
	frame.ComboPoints = combos:Delete()
	return true
end

function PitBull4_ComboPoints:UpdateFrame(frame)
	if frame.unit ~= "target" then
		return self:ClearFrame(frame)
	end
	
	local num_combos = GetComboPoints(UnitHasVehicleUI("player") and "vehicle" or "player", "target")
	
	if num_combos == 0 then
		return self:ClearFrame(frame)
	end
	
	local combos = frame.ComboPoints
	local db = self:GetLayoutDB(frame)
	
	local vertical = db.vertical
	
	if combos and combos.vertical ~= vertical then
		self:ClearFrame(frame)
		combos = nil
		-- still continue, though
	end
	
	if combos and #combos == num_combos then
		return false
	end
	
	if not combos then
		combos = PitBull4.Controls.MakeFrame(frame)
		frame.ComboPoints = combos
		combos.vertical = vertical
	end
	
	if not vertical then
		combos:SetHeight(15)
		combos:SetWidth(15 * num_combos)
		combos.height = 1
	else
		combos:SetHeight(15 * num_combos)
		combos:SetWidth(15)
		combos.height = num_combos
	end
	
	for i = #combos, num_combos + 1, -1 do
		local combo = combos[i]
		
		combos[i] = combo:Delete()
	end
	
	for i = #combos + 1, num_combos do
		local combo = PitBull4.Controls.MakeTexture(combos, "ARTWORK")
		combos[i] = combo
		
		combo:SetTexture(TEXTURE_PATH)
		combo:SetWidth(15)
		combo:SetHeight(15)
		if not vertical then
			combo:SetPoint("LEFT", combos, "LEFT", (i - 1) * 15, 0)
		else
			combo:SetPoint("BOTTOM", combos, "BOTTOM", 0, (i - 1) * 15)
		end
	end
	
	return true
end

PitBull4_ComboPoints:SetLayoutOptionsFunction(function(self)
	return 'vertical', {
		type = 'toggle',
		name = "Vertical",
		desc = "Show the combo points stacked vertically instead of horizontally",
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).vertical
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).vertical = value
			
			PitBull4.Options.UpdateFrames()
		end,
	}
end)
