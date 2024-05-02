
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local wow_cata = PitBull4.wow_cata

-----------------------------------------------------------------------------
-- luacheck: no global

local PitBull4_HideBlizzard = PitBull4:NewModule("HideBlizzard")

PitBull4_HideBlizzard:SetModuleType("custom")
PitBull4_HideBlizzard:SetName(L["Hide Blizzard frames"])
PitBull4_HideBlizzard:SetDescription(L["Hide Blizzard frames that are no longer needed."])
PitBull4_HideBlizzard:SetDefaults({}, {
	player = true,
	runebar = true,
	party = true,
	raid = false,
	target = true,
	focus = true,
	castbar = true,
	aura = false,
	altpower = false,
	boss = false,
	arena = false,
})

function PitBull4_HideBlizzard:OnEnable()
	self:RegisterEvent("ADDON_LOADED")
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnDisable()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnProfileChanged()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:ADDON_LOADED(_, addon)
	if addon == "Blizzard_ArenaUI" or addon == "Blizzard_CompactRaidFrames" then
		self:UpdateFrames()
	end
end

local hiders = {}
local currently_hidden = {}
local reload_needed = false

function PitBull4_HideBlizzard:UpdateFrames()
	for name in pairs(hiders) do
		if self:IsEnabled() and self.db.profile.global[name] then
			if not currently_hidden[name] then
				currently_hidden[name] = not hiders[name](self)
			end
		elseif currently_hidden[name] and not reload_needed then
			reload_needed = true
			self:Print(L["Showing hidden frames requires reloading the UI."])
			LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
		end
	end
end
PitBull4_HideBlizzard.UpdateFrames = PitBull4:OutOfCombatWrapper(PitBull4_HideBlizzard.UpdateFrames)

-----------------------------------------------------------------------------

local noop = function() end
local hide_frame = PitBull4:OutOfCombatWrapper(function(self) self:Hide() end)

local hidden_frame = CreateFrame("Frame")
hidden_frame:Hide()

-----------------------------------------------------------------------------

local function simple_hook_frames(...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		frame:UnregisterAllEvents()
		frame:HookScript("OnShow", hide_frame)
		frame:Hide()
	end
end

local function hook_frames(raw, ...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		UnregisterUnitWatch(frame)
		frame:UnregisterAllEvents()
		frame:Hide()

		if frame.manabar then frame.manabar:UnregisterAllEvents() end
		if frame.healthbar then frame.healthbar:UnregisterAllEvents() end
		if frame.spellbar then frame.spellbar:UnregisterAllEvents() end
		if frame.powerBarAlt then frame.powerBarAlt:UnregisterAllEvents() end

		if raw then
			frame.Show = noop
		else
			frame:SetParent(hidden_frame)
			frame:HookScript("OnShow", hide_frame)
		end
	end
end

-----------------------------------------------------------------------------

function hiders:player()
	hook_frames(false, PlayerFrame, PlayerFrameAlternateManaBar or AlternatePowerBar)
	-- BuffFrame_Update()
	-- BuffFrame needs an inital update, but calling directly will taint things
	PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	PlayerFrame:RegisterEvent("UNIT_ENTERING_VEHICLE")
	PlayerFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
	PlayerFrame:RegisterEvent("UNIT_EXITING_VEHICLE")
	PlayerFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
	PlayerFrame:SetMovable(true)
	PlayerFrame:SetUserPlaced(true)
	PlayerFrame:SetDontSavePosition(true)
end

function hiders:runebar()
	if not wow_cata then
		simple_hook_frames(RuneFrame, WarlockPowerFrame, MonkHarmonyBarFrame, PaladinPowerBarFrame, MageArcaneChargesFrame, EssencePlayerFrame)
	end
end

function hiders:party()
	if PartyFrame then
		hook_frames(false, PartyFrame)
		for memberFrame in PartyFrame.PartyMemberFramePool:EnumerateActive() do
			hook_frames(false, memberFrame, memberFrame.HealthBar, memberFrame.ManaBar)
		end
		PartyFrame.PartyMemberFramePool:ReleaseAll()
	else
		for i = 1, MAX_PARTY_MEMBERS do
			local name = "PartyMemberFrame" .. i
			hook_frames(false, _G[name], _G[name .. "HealthBar"], _G[name .. "ManaBar"])
		end
	end

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	if CompactPartyFrame then
		hook_frames(false, CompactPartyFrame)
	end
end

do
	local function hide_raid()
			CompactRaidFrameManager:UnregisterAllEvents()
			CompactRaidFrameContainer:UnregisterAllEvents()
			if InCombatLockdown() then return end

			CompactRaidFrameManager:Hide()
			local raid_shown = CompactRaidFrameManager_GetSetting("IsShown")
			if raid_shown and raid_shown ~= "0" then
				CompactRaidFrameManager_SetSetting("IsShown", "0")
			end
	end

	function hiders:raid()
		if not CompactRaidFrameManager then
			-- Blizzard_CompactRaidFrames isn't loaded
			return true
		end

		hooksecurefunc("CompactRaidFrameManager_UpdateShown", function()
			if PitBull4_HideBlizzard:IsEnabled() and PitBull4_HideBlizzard.db.profile.global.raid then
				hide_raid()
			end
		end)

		hide_raid()
		CompactRaidFrameContainer:HookScript("OnShow", hide_raid)
		CompactRaidFrameManager:HookScript("OnShow", hide_raid)
	end
end

function hiders:target()
	hook_frames(false, TargetFrame, ComboFrame, TargetFrameToT)
end

function hiders:focus()
	hook_frames(false, FocusFrame, FocusFrameToT)
end

function hiders:castbar()
	hook_frames(true, PlayerCastingBarFrame or CastingBarFrame, PetCastingBarFrame)
end

function hiders:aura()
	hook_frames(false, BuffFrame, TemporaryEnchantFrame or DebuffFrame)
end

function hiders:altpower()
	hook_frames(false, PlayerPowerBarAlt)
end

function hiders:boss()
	for i = 1, MAX_BOSS_FRAMES do
		local name = "Boss" .. i .. "TargetFrame"
		if _G[name].TargetFrameContent then -- retail
			hook_frames(false, _G[name], _G[name].TargetFrameContent.TargetFrameContentMain.HealthBar, _G[name].TargetFrameContent.TargetFrameContentMain.ManaBar)
		else -- classic
			hook_frames(false, _G[name], _G[name .. "HealthBar"], _G[name .. "ManaBar"])
		end
	end
end

do
	-- XXX untested
	local function hide_arena()
		hooksecurefunc(CompactArenaFrame, "UpdateVisibility", function(self)
			if InCombatLockdown() then return end
			if PitBull4_HideBlizzard:IsEnabled() and PitBull4_HideBlizzard.db.profile.global.arena then
				self:SetParent(hidden_frame)
			end
		end)
	end

	function hiders:arena()
		if not ArenaEnemyFramesContainer and not ArenaEnemyFrames then
			return true
		end

		if ArenaEnemyFramesContainer then -- retail bg flag carriers
			hook_frames(true, ArenaEnemyFramesContainer, ArenaEnemyPrepFramesContainer, ArenaEnemyMatchFramesContainer)
		elseif ArenaEnemyFrames then -- classic
			hook_frames(false, ArenaPrepFrames, ArenaEnemyFrames)
		end

		-- retail
		if CompactArenaFrame then
			hide_arena()
		elseif CompactArenaFrame_Generate then
			hooksecurefunc(CompactArenaFrame_Generate, hide_arena)
		end
	end
end

-----------------------------------------------------------------------------

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
		name = L["Class power bar"],
		desc = L["Hides the class resource bar attached to your player frame."],
		get = get,
		set = set,
		hidden = hidden,
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
	}, 'arena', {
		type = 'toggle',
		name = L["Arena"],
		desc = L["Hide the standard arena frames."],
		get = get,
		set = set,
		hidden = hidden,
	}, 'sep', {
		type = 'header',
		name = '',
		order = -2,
		hidden = function() return not self:IsEnabled() or not reload_needed end,
	}, 'reloadui', {
		type = 'execute',
		name = 'Reload UI',
		order = -1,
		func = function() C_UI.Reload() end,
		hidden = function() return not reload_needed end,
	}
end)
