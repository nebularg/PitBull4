
local PitBull4 = _G.PitBull4
local L = PitBull4.L
local securecallfunction = _G.securecallfunction

local PitBull4_CombatFader = PitBull4:NewModule("CombatFader")

PitBull4_CombatFader:SetModuleType("fader")
PitBull4_CombatFader:SetName(L["Combat fader"])
PitBull4_CombatFader:SetDescription(L["Make the unit frame fade if out of combat."])
PitBull4_CombatFader:SetDefaults({
	enabled = false,
	hurt_opacity = 0.75,
	in_combat_opacity = 1,
	out_of_combat_opacity = 0.25,
	target_opacity = 0.75,
})

local state = 'out_of_combat'

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

timerFrame:SetScript("OnUpdate", function(self)
	self:Hide()

	PitBull4_CombatFader:RecalculateState()
	PitBull4_CombatFader:UpdateAll()
end)

function PitBull4_CombatFader:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED", "PLAYER_REGEN_ENABLED")
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "player")
	self:RegisterUnitEvent("UNIT_POWER_UPDATE", "UNIT_HEALTH", "player")
	self:RegisterUnitEvent("UNIT_DISPLAYPOWER", "UNIT_HEALTH", "player")

	self:RecalculateState()
	timerFrame:Show()
end

local power_check
do
	local function not_full()
		local ok, result = pcall(function()
			return UnitPower("player") < UnitPowerMax("player")
		end)
		return ok and result or false
	end
	local function not_empty()
		local ok, result = pcall(function()
			return UnitPower("player") > 0
		end)
		return ok and result or false
	end
	local function lunar_not_empty()
		local ok, result = pcall(function()
			if IsPlayerSpell(202430) then -- Nature's Balance
				local power = UnitPower("player")
				return power < 50 or power > 51
			end
			return UnitPower("player") > 0
		end)
		return ok and result or false
	end
	power_check = {
		MANA = not_full,
		RAGE = not_empty,
		FOCUS = not_full,
		ENERGY = not_full,
		RUNIC_POWER = not_empty,
		LUNAR_POWER = lunar_not_empty,
		MAELSTROM = not_empty,
		INSANITY = not_empty,
		FURY = not_empty,
		PAIN = not_empty,
	}
end

function PitBull4_CombatFader:RecalculateState()
	-- Config mode should never depend on live secure unit values. Midnight can
	-- expose secret numeric values here, so keep preview frames fully visible.
	if PitBull4:IsInConfigMode() then
		state = "in_combat"
		return
	end

	if not PitBull4.world_ready then
		state = "in_combat"
		return
	end

	if PitBull4.HasRestrictedUnitData and PitBull4:HasRestrictedUnitData() then
		state = "in_combat"
		return
	end

	if UnitAffectingCombat("player") then
		state = "in_combat"
	elseif UnitExists("target") then
		state = "target"
	else
		local ok, is_hurt = pcall(function()
			return UnitHealth("player") < UnitHealthMax("player")
		end)
		if not ok then
			is_hurt = false
		end
		if is_hurt then
			state = "hurt"
			return
		end
		local _, power_token
		local function get_power_type()
			return UnitPowerType("player")
		end
		if securecallfunction then
			_, power_token = securecallfunction(get_power_type)
		else
			_, power_token = get_power_type()
		end
		local func = power_check[power_token]
		if func and func() then
			state = "hurt"
		else
			state = "out_of_combat"
		end
	end
end

function PitBull4_CombatFader:PLAYER_REGEN_ENABLED()
	-- this is handled through a timer because PLAYER_TARGET_CHANGED looks funny otherwise
	timerFrame:Show()
end

function PitBull4_CombatFader:UNIT_HEALTH(event, unit)
	if unit ~= "player" then
		return
	end

	return self:PLAYER_REGEN_ENABLED()
end

function PitBull4_CombatFader:GetOpacity(frame)
	local layout_db = self:GetLayoutDB(frame)

	return layout_db[state .. "_opacity"]
end

PitBull4_CombatFader:SetLayoutOptionsFunction(function(self)
	return 'hurt', {
		type = 'range',
		name = L["Hurt opacity"],
		desc = L["The opacity to display if the player is missing health or mana."],
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)

			return db.hurt_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)

			db.hurt_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}, 'in_combat', {
		type = 'range',
		name = L["In-combat opacity"],
		desc = L["The opacity to display if the player is in combat."],
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)

			return db.in_combat_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)

			db.in_combat_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}, 'out_of_combat', {
		type = 'range',
		name = L["Out-of-combat opacity"],
		desc = L["The opacity to display if the player is out of combat."],
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)

			return db.out_of_combat_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)

			db.out_of_combat_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}, 'target', {
		type = 'range',
		name = L["Target-selected opacity"],
		desc = L["The opacity to display if the player is selecting a target."],
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)

			return db.target_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)

			db.target_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}
end)
