if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HideBlizzard requires PitBull4")
end
-- luacheck: no global

local legion_700 = select(4, GetBuildInfo()) >= 70000

local L = PitBull4.L
local PitBull4_HideBlizzard = PitBull4:NewModule("HideBlizzard", "AceHook-3.0")

PitBull4_HideBlizzard:SetModuleType("custom")
PitBull4_HideBlizzard:SetName(L["Hide Blizzard frames"])
PitBull4_HideBlizzard:SetDescription(L["Hide Blizzard frames that are no longer needed."])
PitBull4_HideBlizzard:SetDefaults({}, {
	player = true,
	party = true,
	raid = false,
	target = true,
	focus = true,
	castbar = true,
	aura = false,
	runebar = true,
	altpower = false,
	boss = false,
})

function PitBull4_HideBlizzard:OnEnable()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnDisable()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnProfileChanged()
	self:UpdateFrames()
end

local showers = {}
local hiders = {}
local currently_hidden = {}
local parents = {}



function PitBull4_HideBlizzard:UpdateFrames()
	for name in pairs(showers) do
		if self:IsEnabled() and self.db.profile.global[name] then
			if not currently_hidden[name] then
				currently_hidden[name] = true
				hiders[name](self)
			end
		else
			if currently_hidden[name] then
				currently_hidden[name] = nil
				showers[name](self)
			end
		end
	end
end
PitBull4_HideBlizzard.UpdateFrames = PitBull4:OutOfCombatWrapper(PitBull4_HideBlizzard.UpdateFrames)

local noop = function() end
local hide_frame = PitBull4:OutOfCombatWrapper(function(self) self:Hide() end)

local hidden_frame = CreateFrame("Frame")
hidden_frame:Hide()

local function hook_frames(...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		frame:UnregisterAllEvents()
		if not PitBull4_HideBlizzard:IsHooked(frame, "OnShow") then
			PitBull4_HideBlizzard:SecureHookScript(frame, "OnShow", hide_frame)
		end
		frame:Hide()
	end
end

local function hook_reparent_frames(...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		frame:UnregisterAllEvents()
		if not PitBull4_HideBlizzard:IsHooked(frame, "OnShow") then
			PitBull4_HideBlizzard:SecureHookScript(frame, "OnShow", hide_frame)
			parents[frame] = frame:GetParent()
			frame:SetParent(hidden_frame)
		end
		frame:Hide()
	end
end

local function rawhook_frames(...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		frame:UnregisterAllEvents()
		PitBull4_HideBlizzard:RawHook(frame, "Show", noop, true)
		frame:Hide()
	end
end

local function unhook_frame(frame)
	if PitBull4_HideBlizzard:IsHooked(frame, "OnShow") then
		PitBull4_HideBlizzard:Unhook(frame, "OnShow")
		local parent = parents[frame]
		if parent then
			frame:SetParent(parent)
		end
	elseif PitBull4_HideBlizzard:IsHooked(frame, "Show") then
		PitBull4_HideBlizzard:Unhook(frame, "Show")
	end
end

local function unhook_frames(...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		unhook_frame(frame)
		local handler = frame:GetScript("OnLoad")
		if handler then
			handler(frame)
		end
	end
end

local function unhook_frames_without_init(...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		unhook_frame(frame)
	end
end

function hiders:player()
	PlayerFrame:Hide()
end

function showers:player()
	PlayerFrame:Show()
end

function hiders:party()
	for i = 1, MAX_PARTY_MEMBERS do
		local frame = _G["PartyMemberFrame" .. i]
		rawhook_frames(frame)
		-- hook_reparent_frames(frame)
	end

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

function showers:party()
	for i = 1, MAX_PARTY_MEMBERS do
		local frame = _G["PartyMemberFrame" .. i]
		unhook_frames(frame)
		frame:GetScript("OnEvent")(frame, "GROUP_ROSTER_UPDATE")
	end

	UIParent:RegisterEvent("GROUP_ROSTER_UPDATE")
end

do
	local raid_shown = nil
	local function hide_raid()
			CompactRaidFrameManager:UnregisterEvent("GROUP_ROSTER_UPDATE")
			CompactRaidFrameManager:UnregisterEvent("PLAYER_ENTERING_WORLD")
			if InCombatLockdown() then return end

			raid_shown = CompactRaidFrameManager_GetSetting("IsShown")
			if raid_shown and raid_shown ~= "0" then
				CompactRaidFrameManager_SetSetting("IsShown", "0")
			end
			CompactRaidFrameManager:Hide()
	end

	function hiders:raid()
		if not CompactRaidFrameManager then return end -- Blizzard_CompactRaidFrames isn't loaded

		if not PitBull4_HideBlizzard:IsHooked("CompactRaidFrameManager_UpdateShown") then
			PitBull4_HideBlizzard:SecureHook("CompactRaidFrameManager_UpdateShown", hide_raid)
			PitBull4_HideBlizzard:SecureHookScript(CompactRaidFrameManager, "OnShow", hide_frame)
		end
		hide_raid()
	end

	function showers:raid()
		if not CompactRaidFrameManager then return end -- Blizzard_CompactRaidFrames isn't loaded

		PitBull4_HideBlizzard:Unhook("CompactRaidFrameManager_UpdateShown")
		PitBull4_HideBlizzard:Unhook(CompactRaidFrameManager, "OnShow")

		CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
		CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")

		if raid_shown and raid_shown ~= "0" then
			CompactRaidFrameManager_SetSetting("IsShown", "1")
		end

		if GetDisplayedAllyFrames() then
			CompactRaidFrameManager:Show()
		end
	end
end

function hiders:target()
	hook_frames(TargetFrame, ComboFrame)
end

function showers:target()
	unhook_frames(TargetFrame, ComboFrame)
	ComboFrame:Show()
end

function hiders:focus()
	hook_frames(FocusFrame)
end

function showers:focus()
	unhook_frames(FocusFrame)
end

function hiders:castbar()
	rawhook_frames(CastingBarFrame, PetCastingBarFrame)
end

function showers:castbar()
	unhook_frames(CastingBarFrame, PetCastingBarFrame)
end

function hiders:runebar()
	if not legion_700 then
		hook_frames(WarlockPowerFrame, TotemFrame, EclipseBarFrame, PaladinPowerBar, RuneFrame, PriestBarFrame, MonkHarmonyBar)
	else
		hook_frames(PlayerFrame.classPowerBar, TotemFrame, EclipseBarFrame, RuneFrame, PriestBarFrame)
	end
end

function showers:runebar()
	if not legion_700 then
		unhook_frames(WarlockPowerFrame, TotemFrame, EclipseBarFrame, PaladinPowerBar, RuneFrame, PriestBarFrame, MonkHarmonyBar)

		local _, class = UnitClass("player")
		if class == "WARLOCK" then
			WarlockPowerFrame_SetUpCurrentPower()
		elseif class == "SHAMAN" then
			TotemFrame_Update()
		elseif class == "DRUID" then
			EclipseBar_UpdateShown(EclipseBarFrame)
		elseif class == "PALADIN" then
			PaladinPowerBar:Show()
			PaladinPowerBar_Update(PaladinPowerBar)
		elseif class == "DEATHKNIGHT" then
			RuneFrame:Show()
			RuneFrame:GetScript("OnEvent")(RuneFrame, "PLAYER_ENTERING_WORLD")
		elseif class == "PRIEST" then
			PriestBarFrame_CheckAndShow()
		elseif class == "MONK" then
			MonkHarmonyBar:Show()
			MonkHarmonyBar_Update(MonkHarmonyBar)
		end
	else
		unhook_frames(PlayerFrame.classPowerBar, TotemFrame, EclipseBarFrame, RuneFrame, PriestBarFrame)

		local _, class = UnitClass("player")
		if PlayerFrame.classPowerBar then
			PlayerFrame.classPowerBar:Setup()
		elseif class == "SHAMAN" then
			TotemFrame_Update()
		elseif class == "DRUID" then
			EclipseBar_UpdateShown(EclipseBarFrame)
		elseif class == "DEATHKNIGHT" then
			RuneFrame:Show()
			RuneFrame:GetScript("OnEvent")(RuneFrame, "PLAYER_ENTERING_WORLD")
		elseif class == "PRIEST" then
			PriestBarFrame_CheckAndShow()
		end
	end
end

function hiders:aura()
	hook_frames(BuffFrame, TemporaryEnchantFrame)
	if not legion_700 then
		hook_frames(ConsolidatedBuffs)
	end
end

function showers:aura()
	unhook_frames_without_init(BuffFrame, TemporaryEnchantFrame)
	BuffFrame:RegisterUnitEvent("UNIT_AURA", "player", "vehicle")
	BuffFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	BuffFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	BuffFrame:Show()

	TemporaryEnchantFrame:Show()

	if not legion_700 then
		unhook_frames_without_init(ConsolidatedBuffs)
		if ShouldShowConsolidatedBuffFrame() then
			ConsolidatedBuffs:Show()
		end
	end
end

function hiders:altpower()
	hook_frames(PlayerPowerBarAlt)
end

function showers:altpower()
	unhook_frames_without_init(PlayerPowerBarAlt)
	PlayerPowerBarAlt:RegisterEvent("UNIT_POWER_BAR_SHOW")
	PlayerPowerBarAlt:RegisterEvent("UNIT_POWER_BAR_HIDE")
	PlayerPowerBarAlt:RegisterEvent("PLAYER_ENTERING_WORLD")
	UnitPowerBarAlt_UpdateAll(PlayerPowerBarAlt)
end

function hiders:boss()
	for i=1, MAX_BOSS_FRAMES do
		local frame = _G["Boss"..i.."TargetFrame"]
		hook_frames(frame)
	end
end

function showers:boss()
	for i=1, MAX_BOSS_FRAMES do
		local frame = _G["Boss"..i.."TargetFrame"]
		unhook_frames_without_init(frame)
		if i == 1 then
			BossTargetFrame_OnLoad(frame, "boss1", "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
		else
			BossTargetFrame_OnLoad(frame, "boss"..i)
		end
		Target_Spellbar_OnEvent(frame.spellbar, "INSTANCE_ENCOUNTER_ENGAGE_UNIT")
	end
end

for k, v in pairs(hiders) do
	hiders[k] = PitBull4:OutOfCombatWrapper(v)
end
for k, v in pairs(showers) do
	showers[k] = PitBull4:OutOfCombatWrapper(v)
end

PitBull4_HideBlizzard:SetGlobalOptionsFunction(function(self)
	local function get(info)
		local id = info[#info]
		return self.db.profile.global[id]
	end
	local function set(info, value)
		local id = info[#info]
		self.db.profile.global[id] = value

		self:UpdateFrames()
	end
	local function hidden(info)
		return not self:IsEnabled()
	end
	return 'player', {
		type = 'toggle',
		name = L["Player"],
		desc = L["Hide the standard player frame."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'runebar', {
		type = 'toggle',
		name = "Class power bar",
		desc = "Hides the class resource bar attached to your player frame.",
		get = get,
		set = set,
		hidden = hidden,
		disabled = function() return self.db.profile.global.player end,
	}, 'party', {
		type = 'toggle',
		name = L["Party"],
		desc = L["Hide the standard party frames."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'raid', {
		type = 'toggle',
		name = L["Raid"],
		desc = L["Hide the standard raid manager and raid frames and party frames (when set to use raid style in blizzard interface options)."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'target', {
		type = 'toggle',
		name = L["Target"],
		desc = L["Hide the standard target frame."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'focus', {
		type = 'toggle',
		name = L["Focus"],
		desc = L["Hide the standard focus frame."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'castbar', {
		type = 'toggle',
		name = L["Cast bar"],
		desc = L["Hides the standard cast bar."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'aura', {
		type = 'toggle',
		name = L["Buffs/debuffs"],
		desc = L["Hides the standard buff/debuff frame in the top-right corner of the screen."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'altpower', {
		type = 'toggle',
		name = L["Alternate power"],
		desc = L["Hides the standard alternate power bar shown in some encounters and quests."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'boss', {
		type = 'toggle',
		name = L["Boss"],
		desc = L["Hides the standard boss frames."],
		get = get,
		set = set,
		hidden = hidden,
	}
end)
