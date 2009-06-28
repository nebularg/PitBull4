if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_VisualHeal requires PitBull4")
end

-- CONSTANTS ----------------------------------------------------------------

local EPSILON = 1e-5

-----------------------------------------------------------------------------

local L = PitBull4.L
local LibHealComm

local PitBull4_VisualHeal = PitBull4:NewModule("VisualHeal", "AceEvent-3.0")

PitBull4_VisualHeal:SetModuleType("custom")
PitBull4_VisualHeal:SetName(L["Visual heal"])
PitBull4_VisualHeal:SetDescription(L["Visualises healing done by you and your group members before it happens."])
PitBull4_VisualHeal:SetDefaults({}, {
	incoming_color = { 0.4, 0.6, 0.4, 0.75 },
	outgoing_color = { 0, 1, 0, 1 },
	outgoing_color_overheal = { 1, 0, 0, 0.65 },
	auto_luminance = true,
})

function PitBull4_VisualHeal:OnEnable()
	LibHealComm = LibStub("LibHealComm-3.0", true)
	if not LibHealComm then
		error(L["PitBull4_VisualHeal requires the library LibHealComm-3.0 to be available."])
	end
	
	LibHealComm.RegisterCallback(self, "HealComm_DirectHealStart")
	LibHealComm.RegisterCallback(self, "HealComm_DirectHealUpdate")
	LibHealComm.RegisterCallback(self, "HealComm_DirectHealStop")
	LibHealComm.RegisterCallback(self, "HealComm_HealModifierUpdate")
	
	self:RegisterEvent("UNIT_HEALTH")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEALTH")
end

function PitBull4_VisualHeal:OnDisable()
	LibHealComm.UnregisterAllCallbacks(self)
end

local function clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	else
		return value
	end
end

local REVERSE_POINT = {
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	TOP = "BOTTOM",
	BOTTOM = "TOP",
}

local player_name = UnitName("player")
local player_is_casting = false
local player_healing_target_name = nil
local player_healing_size = 0
local player_end_time = nil

function PitBull4_VisualHeal:UpdateFrame(frame)
	local health_bar = frame.HealthBar
	if not health_bar or not LibHealComm then
		return self:ClearFrame(frame)
	end
	
	local unit = frame.unit
	
	local name,server = UnitName(unit)
	if server and server ~= "" then
		name = name .. "-" .. server
	end
	local is_casting_on_this_unit = player_is_casting and player_healing_target_name == name 
	
	local incoming_heal
	if is_casting_on_this_unit then
		incoming_heal = LibHealComm:UnitIncomingHealGet(unit, player_end_time)
	else
		incoming_heal = select(2, LibHealComm:UnitIncomingHealGet(unit, GetTime()))
	end
	
	-- Bail out early if nothing going on for this unit
	if not is_casting_on_this_unit and not incoming_heal then
		return self:ClearFrame(frame)
	end
	
	local heal_modifier = LibHealComm:UnitHealModifierGet(unit)
	local unit_health_max = UnitHealthMax(unit)
	
	local current_percent = UnitHealth(unit) / unit_health_max
	
	local incoming_percent = incoming_heal and heal_modifier * incoming_heal / unit_health_max or 0
	local player_percent = is_casting_on_this_unit and heal_modifier * player_healing_size / unit_health_max or 0
	if incoming_percent <= 0 and player_percent <= 0 then
		return self:ClearFrame(frame)
	end
	
	local bar = frame.VisualHeal
	if not bar then
		bar = PitBull4.Controls.MakeBetterStatusBar(health_bar)
		frame.VisualHeal = bar
		bar:SetBackgroundAlpha(0)
	end
	bar:SetValue(math.min(incoming_percent, 1))
	bar:SetExtraValue(player_percent)
	bar:SetWidth(health_bar:GetWidth())
	bar:SetHeight(health_bar:GetHeight())
	bar:SetTexture(health_bar:GetTexture())
	
	local deficit = health_bar.deficit
	local orientation = health_bar.orientation
	local reverse = health_bar.reverse
	bar:SetOrientation(orientation)
	bar:SetReverse(deficit ~= reverse)
	
	local point, attach
	if orientation == "HORIZONTAL" then
		point, attach = "LEFT", "RIGHT"
	else
		point, attach = "BOTTOM", "TOP"
	end
	
	if deficit then
		point, attach = attach, point
	end
	
	if reverse then
		point, attach = REVERSE_POINT[point], REVERSE_POINT[attach]
	end
	
	bar:ClearAllPoints()
	bar:SetPoint(point, health_bar.fg, attach)
	
	local db = self.db.profile.global
	
	if incoming_percent > 0 then
		local r, g, b, a = unpack(db.incoming_color)
		bar:SetColor(r, g, b)
		bar:SetNormalAlpha(a)
	end
	
	if player_percent > 0 then
		local waste = clamp((current_percent + incoming_percent + player_percent - 1) / player_percent, 0, 1)
		
		local r, g, b, a = unpack(db.outgoing_color)
		if waste > 0 then
			local r2, g2, b2, a2 = unpack(db.outgoing_color_overheal)
			
			local inverse_waste = 1 - waste
			r = r * inverse_waste + r2 * waste
			g = g * inverse_waste + g2 * waste
			b = b * inverse_waste + b2 * waste
			a = a * inverse_waste + a2 * waste
		end
		
		if db.auto_luminance then
			local high = math.max(r, g, b, EPSILON)
			r, g, b = r / high, g / high, b / high
		end
		
		bar:SetExtraColor(r, g, b)
		bar:SetExtraAlpha(a)
	end
	
	return true
end

function PitBull4_VisualHeal:UNIT_HEALTH(event, unit)
	self:UpdateForUnitID(unit)
end

function PitBull4_VisualHeal:ClearFrame(frame)
	if not frame.VisualHeal then
		return false
	end
	
	frame.VisualHeal = frame.VisualHeal:Delete()
	return true
end

local function update_names(...)
	for i = 1, select('#', ...) do
		local target_name = (select(i, ...))
		local name, server = strsplit('-', target_name)
		
		for frame in PitBull4:IterateFramesForName(name,server) do
			PitBull4_VisualHeal:Update(frame)
		end
	end
end

function PitBull4_VisualHeal:HealComm_DirectHealStart(event, healer_name, heal_size, end_time, ...)
	if healer_name == player_name then
		player_is_casting = true
		player_healing_target_name = (...)
		player_healing_size = heal_size
		player_end_time = end_time
	end
	
	update_names(...)
end

function PitBull4_VisualHeal:HealComm_DirectHealUpdate(event, healer_name, heal_size, end_time, ...)
	if healer_name == playerName then
		player_end_time = end_time
	end
	
	update_names(...)
end

function PitBull4_VisualHeal:HealComm_DirectHealStop(event, healer_name, heal_size, succeeded, ...)
	if healer_name == player_name then
		player_is_casting = false
	end
	
	update_names(...)
end

function PitBull4_VisualHeal:HealComm_HealModifierUpdate(event, unit, target_name, heal_modifier)
	self:UpdateForUnitID(unit)
end

PitBull4_VisualHeal:SetColorOptionsFunction(function(self)
	local function get(info)
		return unpack(self.db.profile.global[info[#info]])
	end
	local function set(info, r, g, b, a)
		local color = self.db.profile.global[info[#info]]
		color[1], color[2], color[3], color[4] = r, g, b, a
		self:UpdateAll()
	end
	return 'incoming_color', {
		type = 'color',
		name = L['Incoming color'],
		desc = L['The color of the bar that shows incoming heals from other players.'],
		get = get,
		set = set,
		hasAlpha = true,
	},
	'outgoing_color', {
		type = 'color',
		name = L['Outcoming color (no overheal)'],
		desc = L['The color of the bar that shows your own heals, when no overhealing is due.'],
		get = get,
		set = set,
		hasAlpha = true,
	},
	'outgoing_color_overheal', {
		type = 'color',
		name = L['Outcoming color (overheal)'],
		desc = L['The color of the bar that shows your own heals, when full overhealing is due.'],
		get = get,
		set = set,
		hasAlpha = true,
	},
	'auto_luminance', {
		type = 'toggle',
		name = L["Auto-luminance"],
		desc = L["Automatically adjust the luminance of the color of the outgoing heal bar to max."],
		get = function(info)
			return self.db.profile.global.auto_luminance
		end,
		set = function(info, value)
			self.db.profile.global.auto_luminance = value
			self:UpdateAll()
		end,
	},
	function(info)
		self.db.profile.global.incoming_color = { 0.4, 0.6, 0.4, 0.75 }
		self.db.profile.global.outgoing_color = { 0, 1, 0, 1 }
		self.db.profile.global.outgoing_color_overheal = { 1, 0, 0, 0.65 }
		self.db.profile.global.auto_luminance = true
	end
end)
PitBull4_VisualHeal:SetLayoutOptionsFunction(function(self) end)
