local _G = _G

local addonName, addonNamespace = ...
addonNamespace = addonNamespace or {}

local Compat = addonNamespace.Compat or {}
addonNamespace.Compat = Compat

Compat.AddonName = addonName
Compat.ProjectID = _G.WOW_PROJECT_ID
Compat.IsRetail = _G.WOW_PROJECT_ID == _G.WOW_PROJECT_MAINLINE
Compat.IsClassic = not Compat.IsRetail

local function get_expansion_level()
	if type(_G.GetClassicExpansionLevel) == "function" then
		return _G.GetClassicExpansionLevel()
	end

	if Compat.IsRetail then
		return _G.LE_EXPANSION_THE_WAR_WITHIN
			or _G.LE_EXPANSION_DRAGONFLIGHT
			or _G.LE_EXPANSION_SHADOWLANDS
			or _G.LE_EXPANSION_BATTLE_FOR_AZEROTH
			or 0
	end

	return 0
end

Compat.ExpansionLevel = get_expansion_level()

function Compat.GetExpansionLevel()
	return get_expansion_level()
end

do
	local native = _G.C_AddOns
	local legacy_get_num_addons = _G.GetNumAddOns
	local legacy_get_addon_info = _G.GetAddOnInfo
	local legacy_get_addon_dependencies = _G.GetAddOnDependencies
	local legacy_get_addon_metadata = _G.GetAddOnMetadata
	local legacy_is_addon_lod = _G.IsAddOnLoadOnDemand
	local legacy_get_addon_enable_state = _G.GetAddOnEnableState
	local legacy_disable_addon = _G.DisableAddOn
	local legacy_load_addon = _G.LoadAddOn
	local legacy_is_addon_loaded = _G.IsAddOnLoaded

	local AddOns = {}

	function AddOns.GetNumAddOns()
		if native and native.GetNumAddOns then
			return native.GetNumAddOns()
		elseif legacy_get_num_addons then
			return legacy_get_num_addons()
		end
		return 0
	end

	function AddOns.GetAddOnInfo(index_or_name)
		if native and native.GetAddOnInfo then
			return native.GetAddOnInfo(index_or_name)
		elseif legacy_get_addon_info then
			return legacy_get_addon_info(index_or_name)
		end
	end

	function AddOns.GetAddOnDependencies(index_or_name)
		if native and native.GetAddOnDependencies then
			return native.GetAddOnDependencies(index_or_name)
		elseif legacy_get_addon_dependencies then
			return legacy_get_addon_dependencies(index_or_name)
		end
	end

	function AddOns.GetAddOnMetadata(name, key)
		if native and native.GetAddOnMetadata then
			return native.GetAddOnMetadata(name, key)
		elseif legacy_get_addon_metadata then
			return legacy_get_addon_metadata(name, key)
		end
	end

	function AddOns.IsAddOnLoadOnDemand(index_or_name)
		if native and native.IsAddOnLoadOnDemand then
			return native.IsAddOnLoadOnDemand(index_or_name)
		elseif legacy_is_addon_lod then
			return legacy_is_addon_lod(index_or_name)
		end
		return false
	end

	function AddOns.GetAddOnEnableState(addon_name, player_name)
		if native and native.GetAddOnEnableState then
			local ok, result = pcall(native.GetAddOnEnableState, addon_name, player_name)
			if ok and type(result) == "number" then
				return result
			end

			ok, result = pcall(native.GetAddOnEnableState, player_name or _G.UnitName("player"), addon_name)
			if ok and type(result) == "number" then
				return result
			end
		end

		if legacy_get_addon_enable_state then
			local ok, result = pcall(legacy_get_addon_enable_state, player_name or _G.UnitName("player"), addon_name)
			if ok and type(result) == "number" then
				return result
			end

			ok, result = pcall(legacy_get_addon_enable_state, addon_name, player_name)
			if ok and type(result) == "number" then
				return result
			end
		end

		return 0
	end

	function AddOns.DisableAddOn(addon_name, character)
		if native and native.DisableAddOn then
			local ok = pcall(native.DisableAddOn, addon_name, character)
			if ok then
				return true
			end
		end

		if legacy_disable_addon then
			local ok = pcall(legacy_disable_addon, addon_name, character)
			if ok then
				return true
			end
		end

		return false
	end

	function AddOns.LoadAddOn(addon_name)
		if native and native.LoadAddOn then
			return native.LoadAddOn(addon_name)
		elseif legacy_load_addon then
			return legacy_load_addon(addon_name)
		end
		return false, "MISSING"
	end

	function AddOns.IsAddOnLoaded(addon_name)
		if native and native.IsAddOnLoaded then
			return native.IsAddOnLoaded(addon_name)
		elseif legacy_is_addon_loaded then
			return legacy_is_addon_loaded(addon_name)
		end
		return false
	end

	Compat.AddOns = AddOns

	_G.C_AddOns = _G.C_AddOns or {}
	for key, value in pairs(AddOns) do
		if _G.C_AddOns[key] == nil then
			_G.C_AddOns[key] = value
		end
	end
end

do
	local native = _G.C_Spell
	local legacy_get_spell_info = _G.GetSpellInfo
	local legacy_is_spell_in_range = _G.IsSpellInRange
	local legacy_get_spell_cooldown = _G.GetSpellCooldown

	local Spell = {}

	function Spell.GetSpellName(spell)
		if native and native.GetSpellName then
			return native.GetSpellName(spell)
		elseif legacy_get_spell_info then
			return legacy_get_spell_info(spell)
		end
	end

	function Spell.GetSpellTexture(spell)
		if native and native.GetSpellTexture then
			return native.GetSpellTexture(spell)
		elseif legacy_get_spell_info then
			return select(3, legacy_get_spell_info(spell))
		end
	end

	function Spell.DoesSpellExist(spell)
		if native and native.DoesSpellExist then
			return native.DoesSpellExist(spell)
		elseif legacy_get_spell_info then
			return legacy_get_spell_info(spell) ~= nil
		end
		return false
	end

	function Spell.IsSpellInRange(spell, unit)
		if native and native.IsSpellInRange then
			return native.IsSpellInRange(spell, unit)
		elseif legacy_is_spell_in_range then
			return legacy_is_spell_in_range(spell, unit)
		end
	end

	function Spell.GetSpellCooldown(spell)
		if native and native.GetSpellCooldown then
			return native.GetSpellCooldown(spell)
		elseif legacy_get_spell_cooldown then
			return legacy_get_spell_cooldown(spell)
		end
	end

	function Spell.GetSpellIDForSpellIdentifier(spell)
		if native and native.GetSpellIDForSpellIdentifier then
			return native.GetSpellIDForSpellIdentifier(spell)
		elseif type(spell) == "number" then
			return spell
		elseif legacy_get_spell_info then
			return select(7, legacy_get_spell_info(spell))
		end
	end

	Compat.Spell = Spell

	_G.C_Spell = _G.C_Spell or {}
	for key, value in pairs(Spell) do
		if _G.C_Spell[key] == nil then
			_G.C_Spell[key] = value
		end
	end
end

do
	local native = _G.C_UnitAuras
	local legacy_unit_aura = _G.UnitAura

	local function build_aura_data(unit, index, filter)
		if not legacy_unit_aura then
			return nil
		end

		local name, icon, applications, dispel_name, duration, expiration_time, source_unit, is_stealable, nameplate_show_personal, spell_id, can_apply_aura, is_boss_debuff, cast_by_player, nameplate_show_all, time_mod, should_consolidate, value1, value2, value3 = legacy_unit_aura(unit, index, filter)
		if not name then
			return nil
		end

		local is_harmful = type(filter) == "string" and filter:find("HARMFUL", 1, true) ~= nil

		return {
			name = name,
			icon = icon,
			applications = applications or 0,
			dispelName = dispel_name,
			duration = duration or 0,
			expirationTime = expiration_time or 0,
			sourceUnit = source_unit,
			isStealable = not not is_stealable,
			nameplateShowPersonal = not not nameplate_show_personal,
			spellId = spell_id,
			canApplyAura = not not can_apply_aura,
			isBossAura = not not is_boss_debuff,
			isFromPlayerOrPlayerPet = not not cast_by_player,
			nameplateShowAll = not not nameplate_show_all,
			timeMod = time_mod or 1,
			points = { value1, value2, value3 },
			index = index,
			shouldConsolidate = should_consolidate,
			isHelpful = not is_harmful,
			isHarmful = is_harmful,
		}
	end

	local UnitAuras = {}

	function UnitAuras.GetAuraDataByIndex(unit, index, filter)
		if native and native.GetAuraDataByIndex then
			return native.GetAuraDataByIndex(unit, index, filter)
		end

		return build_aura_data(unit, index, filter)
	end

	function UnitAuras.GetAuraDataByAuraInstanceID(unit, aura_instance_id)
		if native and native.GetAuraDataByAuraInstanceID then
			return native.GetAuraDataByAuraInstanceID(unit, aura_instance_id)
		end

		return nil
	end

	Compat.UnitAuras = UnitAuras

	_G.C_UnitAuras = _G.C_UnitAuras or {}
	for key, value in pairs(UnitAuras) do
		if _G.C_UnitAuras[key] == nil then
			_G.C_UnitAuras[key] = value
		end
	end
end

do
	local native = _G.C_TooltipInfo

	local TooltipInfo = {}
	local tooltip
	local left = {}
	local right = {}

	local function ensure_tooltip()
		if tooltip then
			return tooltip
		end

		tooltip = CreateFrame("GameTooltip", "PitBull4_CompatTooltip", nil)
		for i = 1, 40 do
			left[i] = tooltip:CreateFontString(nil, nil, "GameFontNormal")
			right[i] = tooltip:CreateFontString(nil, nil, "GameFontNormal")
			tooltip:AddFontStrings(left[i], right[i])
		end

		return tooltip
	end

	local function capture_lines(setter)
		local tt = ensure_tooltip()
		local owner = _G.WorldFrame or _G.UIParent

		tt:ClearLines()
		if not tt:IsOwned(owner) then
			tt:SetOwner(owner, "ANCHOR_NONE")
		end

		setter(tt)

		local lines = {}
		local count = 0
		for i = 1, 40 do
			local left_text = left[i]:GetText()
			local right_text = right[i]:GetText()
			if not left_text and not right_text then
				break
			end

			count = count + 1
			lines[count] = {
				type = 0,
				leftText = left_text,
				rightText = right_text,
			}
		end

		if count == 0 then
			return nil
		end

		return { lines = lines }
	end

	function TooltipInfo.GetInventoryItem(unit, slot)
		if native and native.GetInventoryItem then
			return native.GetInventoryItem(unit, slot, true)
		end

		return capture_lines(function(tt)
			tt:SetInventoryItem(unit, slot)
		end)
	end

	function TooltipInfo.GetSpellByID(spell_id)
		if native and native.GetSpellByID then
			return native.GetSpellByID(spell_id, true)
		end

		return capture_lines(function(tt)
			if tt.SetSpellByID then
				tt:SetSpellByID(spell_id)
			else
				tt:SetHyperlink(("spell:%d"):format(spell_id))
			end
		end)
	end

	function TooltipInfo.GetUnit(unit)
		if native and native.GetUnit then
			return native.GetUnit(unit)
		end

		return capture_lines(function(tt)
			tt:SetUnit(unit)
		end)
	end

	Compat.TooltipInfo = TooltipInfo

	_G.C_TooltipInfo = _G.C_TooltipInfo or {}
	for key, value in pairs(TooltipInfo) do
		if _G.C_TooltipInfo[key] == nil then
			_G.C_TooltipInfo[key] = value
		end
	end
end

do
	local native = _G.C_Reputation
	local legacy_get_watched_faction_info = _G.GetWatchedFactionInfo

	local Reputation = {}

	function Reputation.GetWatchedFactionData()
		if native and native.GetWatchedFactionData then
			return native.GetWatchedFactionData()
		elseif legacy_get_watched_faction_info then
			local name, reaction, min_value, max_value, current_value, faction_id = legacy_get_watched_faction_info()
			if not name then
				return nil
			end

			return {
				name = name,
				reaction = reaction,
				currentReactionThreshold = min_value,
				nextReactionThreshold = max_value,
				currentStanding = current_value,
				factionID = faction_id,
			}
		end
	end

	function Reputation.IsFactionParagon(faction_id)
		if native and native.IsFactionParagon then
			return native.IsFactionParagon(faction_id)
		end
		return false
	end

	function Reputation.GetFactionParagonInfo(faction_id)
		if native and native.GetFactionParagonInfo then
			return native.GetFactionParagonInfo(faction_id)
		end
	end

	function Reputation.IsMajorFaction(faction_id)
		if native and native.IsMajorFaction then
			return native.IsMajorFaction(faction_id)
		end
		return false
	end

	Compat.Reputation = Reputation

	_G.C_Reputation = _G.C_Reputation or {}
	for key, value in pairs(Reputation) do
		if _G.C_Reputation[key] == nil then
			_G.C_Reputation[key] = value
		end
	end
end
