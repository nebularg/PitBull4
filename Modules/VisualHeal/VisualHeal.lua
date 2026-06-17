
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local UnitGetTotalAbsorbs = _G.UnitGetTotalAbsorbs or nil  -- XXX UnitGetTotalAbsorbs was added in MoP but classic doesn't have the API?

local EPSILON = 1e-5

local REVERSE_POINT = {
	LEFT = "RIGHT",
	RIGHT = "LEFT",
	TOP = "BOTTOM",
	BOTTOM = "TOP",
}

local PitBull4_VisualHeal = PitBull4:NewModule("VisualHeal")

PitBull4_VisualHeal:SetModuleType("custom")
PitBull4_VisualHeal:SetName(L["Visual heal"])
PitBull4_VisualHeal:SetDescription(L["Visualises healing done by you and your group members before it happens."])
PitBull4_VisualHeal:SetDefaults({
	show_overheal = true,
	show_overabsorb = true,
}, {
	incoming_color = { 0.4, 0.6, 0.4, 0.75 },
	outgoing_color = { 0, 1, 0, 1 },
	outgoing_color_overheal = { 1, 0, 0, 0.65 },
	absorb_color = { .4, .258, .619, 1},
	auto_luminance = true,
})

local function clamp(value, min, max)
	if value < min then
		return min
	elseif value > max then
		return max
	else
		return value
	end
end


local function get_or_create_bar(frame, health_bar)
	local bar = frame.VisualHeal
	if not bar then
		bar = PitBull4.Controls.MakeBetterStatusBar(health_bar)
		frame.VisualHeal = bar
		bar:SetBackgroundAlpha(0)
	end
	return bar
end

function PitBull4_VisualHeal:ShowExampleFrame(frame, health_bar)
	local bar = get_or_create_bar(frame, health_bar)
	bar:SetTexture(health_bar:GetTexture())
	bar:SetOrientation(health_bar.orientation)
	bar:SetReverse(false)
	bar:SetDeficit(false)
	bar:SetValue(0.18)
	bar:SetExtraValue(0.12)
	bar:SetExtra2Value(0.10)

	local db = self.db.profile.global
	local r, g, b, a = unpack(db.incoming_color)
	bar:SetColor(r, g, b)
	bar:SetNormalAlpha(a)
	local r2, g2, b2, a2 = unpack(db.outgoing_color)
	bar:SetExtraColor(r2, g2, b2)
	bar:SetExtraAlpha(a2)
	local r3, g3, b3, a3 = unpack(db.absorb_color)
	bar:SetExtra2Color(r3, g3, b3)
	bar:SetExtra2Alpha(a3)

	bar:ClearAllPoints()
	if health_bar.orientation == "HORIZONTAL" then
		bar:SetWidth(health_bar:GetWidth())
		bar:SetHeight(0)
		bar:SetPoint("TOP", health_bar, "TOP")
		bar:SetPoint("BOTTOM", health_bar, "BOTTOM")
		bar:SetPoint("LEFT", health_bar.fg or health_bar, "RIGHT")
	else
		bar:SetHeight(health_bar:GetHeight())
		bar:SetWidth(0)
		bar:SetPoint("LEFT", health_bar, "LEFT")
		bar:SetPoint("RIGHT", health_bar, "RIGHT")
		bar:SetPoint("BOTTOM", health_bar.fg or health_bar, "TOP")
	end

	return true
end

function PitBull4_VisualHeal:OnEnable()
	self:RegisterEvent("UNIT_HEAL_PREDICTION")
	self:RegisterEvent("UNIT_HEALTH", "UNIT_HEAL_PREDICTION")
	self:RegisterEvent("UNIT_MAXHEALTH", "UNIT_HEAL_PREDICTION")
	if UnitGetTotalAbsorbs then
		self:RegisterEvent("UNIT_ABSORB_AMOUNT_CHANGED", "UNIT_HEAL_PREDICTION")
	end
end

function PitBull4_VisualHeal:UpdateFrame(frame)
	local health_bar = frame.HealthBar
	local unit = frame.unit
	local guid = frame.guid
	if not health_bar or not unit then
		return self:ClearFrame(frame)
	end

	if PitBull4:IsInConfigMode() or frame.force_show then
		return self:ShowExampleFrame(frame, health_bar)
	end

	if not guid then
		return self:ClearFrame(frame)
	end

	if PitBull4.HasRestrictedUnitData and PitBull4:HasRestrictedUnitData() then
		return self:ClearFrame(frame)
	end

	local ok, player_healing, all_healing, all_absorbs, unit_health_max, current_percent, others_percent, player_percent, absorb_percent = pcall(function()
		local incoming_player = UnitGetIncomingHeals(unit, "player")
		local incoming_all = UnitGetIncomingHeals(unit)
		local incoming_absorbs = UnitGetTotalAbsorbs and UnitGetTotalAbsorbs(unit) or nil

		if not incoming_player and not incoming_all and not incoming_absorbs then
			return nil
		end

		incoming_player = tonumber(incoming_player) or 0
		incoming_all = tonumber(incoming_all) or 0
		incoming_absorbs = tonumber(incoming_absorbs) or 0

		local others_healing = incoming_all - incoming_player
		local max_health = tonumber(UnitHealthMax(unit)) or 0
		local current = 0
		local others = 0
		local player = 0
		local absorbs = 0

		if max_health > 0 then
			current = (tonumber(UnitHealth(unit)) or 0) / max_health
			others = others_healing / max_health
			player = incoming_player / max_health
			absorbs = incoming_absorbs / max_health
		end

		return incoming_player, incoming_all, incoming_absorbs, max_health, current, others, player, absorbs
	end)

	if not ok or player_healing == nil then
		return self:ClearFrame(frame)
	end

	if others_percent <= 0 and player_percent <= 0 and absorb_percent <= 0 then
		return self:ClearFrame(frame)
	end

	local bar = get_or_create_bar(frame, health_bar)

	local show_overheal = self:GetLayoutDB(frame).show_overheal
	local show_overabsorb = self:GetLayoutDB(frame).show_overabsorb

	-- If the user has selected to not show overheal we make sure to not set a value that goes beyond 100%.
	if not show_overheal and ((others_percent+current_percent) > 1) then
		others_percent = 1 - current_percent
	end

	bar:SetValue(math.min(others_percent, 1))

	if not show_overheal and ((player_percent+others_percent+current_percent) > 1) then
		player_percent = 1 - (others_percent+current_percent)
	end

	bar:SetExtraValue(player_percent)

	if not show_overabsorb and ((player_percent+others_percent+current_percent+absorb_percent) > 1) then
		absorb_percent = 1 - (player_percent+others_percent+current_percent)
	end
	bar:SetExtra2Value(absorb_percent)

	bar:SetTexture(health_bar:GetTexture())

	local deficit = health_bar.deficit
	local orientation = health_bar.orientation
	local reverse = health_bar.reverse
	bar:SetOrientation(orientation)
	bar:SetReverse(deficit ~= reverse)
	bar:SetDeficit(false)

	bar:ClearAllPoints()
	local point, attach, attach_frame
	if orientation == "HORIZONTAL" then
		point, attach = "LEFT", "RIGHT"
		bar:SetWidth(health_bar:GetWidth())
		bar:SetHeight(0)
		bar:SetPoint("TOP", health_bar, "TOP")
		bar:SetPoint("BOTTOM", health_bar, "BOTTOM")
	else
		point, attach = "BOTTOM", "TOP"
		bar:SetHeight(health_bar:GetHeight())
		bar:SetWidth(0)
		bar:SetPoint("LEFT", health_bar, "LEFT")
		bar:SetPoint("RIGHT", health_bar, "RIGHT")
	end

	if deficit then
		point, attach = attach, point
		attach_frame = health_bar.bg
	else
		attach_frame = health_bar.fg
	end

	if reverse then
		point, attach = REVERSE_POINT[point], REVERSE_POINT[attach]
	end

	bar:SetPoint(point, attach_frame, attach)

	local db = self.db.profile.global

	if others_percent > 0 then
		local r, g, b, a = unpack(db.incoming_color)
		bar:SetColor(r, g, b)
		bar:SetNormalAlpha(a)
	end

	if player_percent > 0 then
		local waste = clamp((current_percent + others_percent + player_percent - 1) / player_percent, 0, 1)

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

	if absorb_percent > 0 then
		local r, g, b, a = unpack(db.absorb_color)
		bar:SetExtra2Color(r, g, b)
		bar:SetExtra2Alpha(a)
	end

	return true
end

function PitBull4_VisualHeal:UNIT_HEAL_PREDICTION(_, unit)
	if not unit then return end
	self:UpdateForUnitID(unit)
end

function PitBull4_VisualHeal:ClearFrame(frame)
	if not frame.VisualHeal then
		return false
	end

	frame.VisualHeal = frame.VisualHeal:Delete()
	return true
end

PitBull4_VisualHeal.OnHide = PitBull4_VisualHeal.ClearFrame

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
		name = L["Incoming color"],
		desc = L["The color of the bar that shows incoming heals from other players."],
		get = get,
		set = set,
		hasAlpha = true,
		width = 'double',
	},
	'outgoing_color', {
		type = 'color',
		name = L["Outgoing color (no overheal)"],
		desc = L["The color of the bar that shows your own heals, when no overhealing is due."],
		get = get,
		set = set,
		hasAlpha = true,
		width = 'double',
	},
	'outgoing_color_overheal', {
		type = 'color',
		name = L["Outgoing color (overheal)"],
		desc = L["The color of the bar that shows your own heals, when full overhealing is due."],
		get = get,
		set = set,
		hasAlpha = true,
		width = 'double',
	},
	'absorb_color', {
		type = 'color',
		name = L["Absorb color"],
		desc = L["The color of the bar that shows absorption shields."],
		get = get,
		set = set,
		hasAlpha = true,
		width = 'double',
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
		width = 'double',
	},
	function(info)
		self.db.profile.global.incoming_color = { 0.4, 0.6, 0.4, 0.75 }
		self.db.profile.global.outgoing_color = { 0, 1, 0, 1 }
		self.db.profile.global.outgoing_color_overheal = { 1, 0, 0, 0.65 }
		self.db.profile.global.absorb_color = { .4, .258, .619, 1}
		self.db.profile.global.auto_luminance = true
	end
end)

PitBull4_VisualHeal:SetLayoutOptionsFunction(function(self)
	local function disabled(info)
		return not PitBull4.Options.GetLayoutDB(self).enabled
	end

	return 'show_overheal', {
		type = 'toggle',
		name = L["Show overheals"],
		desc = L["Show overheals past the end of the health bar."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).show_overheal
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).show_overheal = value
		end,
		disabled = disabled,
	}, 'show_overabsorb', {
		type = 'toggle',
		name = L["Show overabsorb"],
		desc = L["Show absorb past the end of the health bar."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).show_overabsorb
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).show_overabsorb = value
		end,
		hidden = not UnitGetTotalAbsorbs,
		disabled = disabled,
	}

end)
