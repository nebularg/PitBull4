-- http://luacheck.readthedocs.io/en/stable/warnings.html

std = "lua51"
max_line_length = false
codes = true
exclude_files = {
	"**/Libs",
	".luacheckrc",
	".release",
	"Babelfish.lua",
	"Localization/_export.lua",
}
ignore = {
	"11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
	"11./BINDING_.*", -- Setting an undefined (Keybinding header) global variable
	"113/LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
	"113/NUM_LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
	"211", -- Unused local variable
	"211/L", -- Unused local variable "L"
	"211/CL", -- Unused local variable "CL"
	"212", -- Unused argument
	"213", -- Unused loop variable
	"311", -- Value assigned to a local variable is unused
	"314", -- Value of a field in a table literal is unused
	"42.", -- Shadowing a local variable, an argument, a loop variable.
	"43.", -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
	"542", -- An empty if branch
}
globals = {
	-- Third-party
	"ClickCastHeader",
	"LibStub",
	"oRA3",
	"PitBull4",

	"WOW_PROJECT_ID",
	"WOW_PROJECT_MAINLINE",
	"WOW_PROJECT_CLASSIC",
	"WOW_PROJECT_BURNING_CRUSADE_CLASSIC",
	"WOW_PROJECT_WRATH_CLASSIC",

	"Enum",
	"CLASS_SORT_ORDER",
	"RAID_CLASS_COLORS",
	"SOUNDKIT",

	"BasicMessageDialog",
	"ChatFontNormal",
	"CombatFeedbackText",
	"DEFAULT_CHAT_FRAME",
	"GameTooltip",
	"StaticPopupDialogs",
	"UIErrorsFrame",
	"UIParent",
	"VoiceActivityManager",

	"CopyTable",
	"tContains",
	"tInvert",

	-- Functions
	"C_CreatureInfo",
	"C_Timer",
	"CancelItemTempEnchantment",
	"CancelUnitBuff",
	"CastingInfo",
	"ChannelInfo",
	"CheckInteractDistance",
	"CooldownFrame_Set",
	"CreateFrame",
	"DestroyTotem",
	"DisableAddOn",
	"GameTooltip_SetDefaultAnchor",
	"GameTooltip_UnitColor",
	"GetAddOnDependencies",
	"GetAddOnEnableState",
	"GetAddOnInfo",
	"GetAddOnMetadata",
	"GetBattlefieldStatus",
	"GetSpellBookItemName",
	"GetCVarBool",
	"GetComboPoints",
	"GetBuildInfo",
	"GetFriendshipReputation",
	"GetInventoryItemLink",
	"GetItemInfo",
	"GetItemQualityColor",
	"GetLocale",
	"GetManagedEnvironment",
	"GetMouseFocus",
	"GetNumAddOns",
	"GetNumClasses",
	"GetNumGroupMembers",
	"GetNumSubgroupMembers",
	"GetPVPTimer",
	"GetPartyAssignment",
	"GetPetExperience",
	"GetPetHappiness",
	"GetQuestDifficultyColor",
	"GetRaidRosterInfo",
	"GetRaidTargetIndex",
	"GetReadyCheckStatus",
	"GetRuneCooldown",
	"GetRuneType",
	"GetScreenHeight",
	"GetScreenWidth",
	"GetShapeshiftFormID",
	"GetSpellCooldown",
	"GetSpellInfo",
	"GetTime",
	"GetTotemInfo",
	"GetTotemTimeLeft",
	"GetWatchedFactionInfo",
	"GetXPExhaustion",
	"InCombatLockdown",
	"IsAddOnLoadOnDemand",
	"IsAddOnLoaded",
	"IsInGroup",
	"IsInRaid",
	"IsItemInRange",
	"IsPVPTimerRunning",
	"IsPlayerSpell",
	"IsResting",
	"IsShiftKeyDown",
	"IsSpellInRange",
	"IsSpellKnown",
	"LoadAddOn",
	"PlaySound",
	"PlaySoundFile",
	"RegisterAttributeDriver",
	"RegisterUnitWatch",
	"SecureButton_GetModifiedUnit",
	"SecureHandlerExecute",
	"SecureHandlerSetFrameRef",
	"SetPortraitTexture",
	"ShowBossFrameWhenUninteractable",
	"SpellGetVisibilityInfo",
	"SpellIsSelfBuff",
	"StaticPopup_Show",
	"UnitAffectingCombat",
	"UnitAura",
	"UnitCanAttack",
	"UnitCastingInfo",
	"UnitChannelInfo",
	"UnitClass",
	"UnitClassBase",
	"UnitClassification",
	"UnitCreatureFamily",
	"UnitCreatureType",
	"UnitDetailedThreatSituation",
	"UnitExists",
	"UnitFactionGroup",
	"UnitGUID",
	"UnitGetIncomingHeals",
	"UnitGetTotalAbsorbs",
	"UnitGroupRolesAssigned",
	"UnitHasIncomingResurrection",
	"UnitHasVehiclePlayerFrameUI",
	"UnitHasVehicleUI",
	"UnitHealth",
	"UnitHealthMax",
	"UnitInParty",
	"UnitInPhase",
	"UnitInRaid",
	"UnitInRange",
	"UnitIsAFK",
	"UnitIsConnected",
	"UnitIsDND",
	"UnitIsDead",
	"UnitIsDeadOrGhost",
	"UnitIsEnemy",
	"UnitIsFeignDeath",
	"UnitIsFriend",
	"UnitIsGhost",
	"UnitIsGroupLeader",
	"UnitIsOtherPlayersPet",
	"UnitIsPVP",
	"UnitIsPVPFreeForAll",
	"UnitIsPlayer",
	"UnitIsTapDenied",
	"UnitIsUnit",
	"UnitIsVisible",
	"UnitLevel",
	"UnitName",
	"UnitPlayerControlled",
	"UnitPlayerOrPetInRaid",
	"UnitPower",
	"UnitPowerDisplayMod",
	"UnitPowerMax",
	"UnitPowerType",
	"UnitRace",
	"UnitReaction",
	"UnitSelectionColor",
	"UnitThreatSituation",
	"UnitXP",
	"UnitXPMax",
	"UnregisterAttributeDriver",
	"UnregisterUnitWatch",
	"abs",
	"bit",
	"ceil",
	"date",
	"debugstack",
	"floor",
	"format",
	"geterrorhandler",
	"hooksecurefunc",
	"math",
	"max",
	"min",
	"string",
	"strjoin",
	"strsplit",
	"strtrim",
	"table",
	"tostringall",
	"tinsert",
	"tremove",
	"wipe",

	-- Strings
	"CANCEL",
	"CAT_FORM",
	"CLASS",
	"DAMAGER",
	"DAY_ONELETTER_ABBR",
	"DAYS_ABBR",
	"DECIMAL_SEPERATOR",
	"FIRST_NUMBER_CAP_NO_SPACE",
	"FULL_PLAYER_NAME",
	"HEALER",
	"HOUR_ONELETTER_ABBR",
	"HOURS_ABBR",
	"LARGE_NUMBER_SEPERATOR",
	"LOCALIZED_CLASS_NAMES_MALE",
	"MAX_PARTY_MEMBERS",
	"MAX_RAID_MEMBERS",
	"MINUTE_ONELETTER_ABBR",
	"MINUTES_ABBR",
	"NONE",
	"NUM_BAG_SLOTS",
	"RAID_TARGET_1",
	"RAID_TARGET_2",
	"RAID_TARGET_3",
	"RAID_TARGET_4",
	"RAID_TARGET_5",
	"RAID_TARGET_6",
	"RAID_TARGET_7",
	"RAID_TARGET_8",
	"RELOADUI",
	"SECOND_NUMBER_CAP_NO_SPACE",
	"SECOND_ONELETTER_ABBR",
	"SECONDS_ABBR",
	"TANK",
	"TOOLTIP_BATTLE_PET",
	"UNKNOWN",
}
