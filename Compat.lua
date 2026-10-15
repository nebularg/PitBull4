local addon_name, namespace = ...
local Compat = {}
namespace.Compat = Compat

Compat.AddonName = addon_name
Compat.ProjectID = WOW_PROJECT_ID

local function is_project(project)
	return project ~= nil and WOW_PROJECT_ID == project
end

Compat.IsRetail = is_project(WOW_PROJECT_MAINLINE)
Compat.IsEra = is_project(WOW_PROJECT_CLASSIC)
Compat.IsTBC = is_project(WOW_PROJECT_BURNING_CRUSADE_CLASSIC)
Compat.IsWrath = is_project(WOW_PROJECT_WRATH_CLASSIC)
Compat.IsCata = is_project(WOW_PROJECT_CATACLYSM_CLASSIC)
Compat.IsMists = is_project(WOW_PROJECT_MISTS_CLASSIC)
Compat.IsForever = is_project(WOW_PROJECT_CAMELOT or 18)
Compat.IsClassic = Compat.IsEra or Compat.IsTBC or Compat.IsWrath or Compat.IsCata or Compat.IsMists
Compat.Client = Compat.IsRetail and "mainline"
	or Compat.IsForever and "camelot"
	or Compat.IsEra and "vanilla"
	or Compat.IsTBC and "tbc"
	or Compat.IsWrath and "wrath"
	or Compat.IsCata and "cata"
	or Compat.IsMists and "mists"
	or "unknown"

local classic_expansion = GetClassicExpansionLevel
function Compat.GetExpansionLevel()
	-- Camelot's modern APIs do not add expansion-specific classes/resources.
	if Compat.IsForever or Compat.IsEra then
		return LE_EXPANSION_CLASSIC or 0
	end
	if classic_expansion and (Compat.IsClassic or Compat.IsRetail) then
		return classic_expansion()
	end
	if Compat.IsRetail and GetExpansionLevel then
		return GetExpansionLevel()
	end
	return 0
end
Compat.ExpansionLevel = Compat.GetExpansionLevel()
Compat.UsesSpecializations = Compat.IsRetail or (Compat.IsClassic and Compat.ExpansionLevel >= (LE_EXPANSION_MISTS_OF_PANDARIA or 4))

local access_value = canaccessvalue
local secret_value = issecretvalue
function Compat.IsValueAccessible(value)
	if access_value then
		return access_value(value)
	end
	if secret_value then
		return not secret_value(value)
	end
	return true
end

local event_valid = C_EventUtils and C_EventUtils.IsEventValid
function Compat.IsEventValid(event)
	return event_valid ~= nil and event_valid(event)
end
function Compat.RegisterOptionalEvent(module, event, method)
	if Compat.IsEventValid(event) then
		module:RegisterEvent(event, method)
		return true
	end
	return false
end

local restriction_state = C_RestrictedActions and C_RestrictedActions.GetAddOnRestrictionState or GetAddOnRestrictionState
Compat.GetRestrictionState = restriction_state
Compat.HasRestrictionState = restriction_state ~= nil and Enum ~= nil
	and Enum.AddOnRestrictionState ~= nil and Enum.AddOnRestrictionType ~= nil

local reverse_curve = CurveConstants and CurveConstants.Reverse
function Compat.GetReverseCurve()
	if not reverse_curve and C_CurveUtil and C_CurveUtil.CreateCurve then
		reverse_curve = C_CurveUtil.CreateCurve()
		reverse_curve:AddPoint(0, 1)
		reverse_curve:AddPoint(1, 0)
	end
	return reverse_curve
end

-- Save individual functions; adapters never modify Blizzard namespace tables.
local native_addons = C_AddOns or {}
local AddOns = {}
Compat.AddOns = AddOns
local addon_fallbacks = {
	GetNumAddOns = GetNumAddOns,
	GetAddOnInfo = GetAddOnInfo,
	GetAddOnDependencies = GetAddOnDependencies,
	GetAddOnMetadata = GetAddOnMetadata,
	IsAddOnLoadOnDemand = IsAddOnLoadOnDemand,
	DisableAddOn = DisableAddOn,
	LoadAddOn = LoadAddOn,
	IsAddOnLoaded = IsAddOnLoaded,
}
for name, fallback in pairs(addon_fallbacks) do
	AddOns[name] = native_addons[name] or fallback
end
for _, name in ipairs({ "GetNumAddOns", "GetAddOnInfo", "GetAddOnDependencies", "GetAddOnMetadata", "IsAddOnLoadOnDemand", "DisableAddOn", "LoadAddOn", "IsAddOnLoaded" }) do
	AddOns[name] = AddOns[name] or native_addons[name]
end
local native_enable_state = native_addons.GetAddOnEnableState
local legacy_enable_state = GetAddOnEnableState
local player_name = UnitName
function AddOns.GetAddOnEnableState(name, character)
	if native_enable_state then
		return native_enable_state(name, character)
	end
	if legacy_enable_state then
		return legacy_enable_state(character or player_name("player"), name)
	end
	return 0
end

local native_spell = C_Spell or {}
local Spell = {}
Compat.Spell = Spell
local native_name = native_spell.GetSpellName
local native_texture = native_spell.GetSpellTexture
local native_info = native_spell.GetSpellInfo
local native_exists = native_spell.DoesSpellExist
local native_range = native_spell.IsSpellInRange
local native_cooldown = native_spell.GetSpellCooldown
local native_identifier = native_spell.GetSpellIDForSpellIdentifier
local legacy_info = GetSpellInfo
local legacy_range = IsSpellInRange
local legacy_cooldown = GetSpellCooldown

function Spell.GetSpellInfo(spell)
	if native_info then
		return native_info(spell)
	end
	if legacy_info then
		local name, _, icon, cast_time, min_range, max_range, id, original_icon = legacy_info(spell)
		if name then
			return { name = name, iconID = icon, castTime = cast_time, minRange = min_range, maxRange = max_range, spellID = id, originalIconID = original_icon }
		end
	end
end

function Spell.GetSpellName(spell)
	if native_name then
		return native_name(spell)
	end
	local info = Spell.GetSpellInfo(spell)
	return info and info.name
end

function Spell.GetSpellTexture(spell)
	if native_texture then
		return native_texture(spell)
	end
	local info = Spell.GetSpellInfo(spell)
	return info and info.iconID
end

function Spell.DoesSpellExist(spell)
	if native_exists then
		return native_exists(spell)
	end
	return Spell.GetSpellInfo(spell) ~= nil
end

function Spell.IsSpellInRange(spell, unit)
	if native_range then
		return native_range(spell, unit)
	end
	if legacy_range then
		local result = legacy_range(spell, unit)
		if Compat.IsValueAccessible(result) and result ~= nil then
			return result == 1 or result == true
		end
	end
end

function Spell.GetSpellCooldown(spell)
	if native_cooldown then
		return native_cooldown(spell)
	end
	if legacy_cooldown then
		local start, duration, enabled, rate = legacy_cooldown(spell)
		if start ~= nil then
			return { startTime = start, duration = duration, isEnabled = enabled == 1 or enabled == true, modRate = rate or 1 }
		end
	end
end

function Spell.GetSpellIDForSpellIdentifier(spell)
	if native_identifier then
		return native_identifier(spell)
	end
	local info = Spell.GetSpellInfo(spell)
	return info and info.spellID
end

local specs = C_SpecializationInfo or {}
Compat.GetSpecialization = specs.GetSpecialization or GetSpecialization
Compat.GetActiveSpecGroup = specs.GetActiveSpecGroup or GetActiveSpecGroup

local build_info = GetBuildInfo
function Compat.GetClientInfo()
	local version, build, date, interface
	if build_info then
		version, build, date, interface = build_info()
	end
	local manifest = AddOns.GetAddOnMetadata and AddOns.GetAddOnMetadata(addon_name, "X-PitBull4-Manifest")
	return { client = Compat.Client, project = Compat.ProjectID, version = version, build = build, date = date, interface = interface, manifest = manifest }
end
