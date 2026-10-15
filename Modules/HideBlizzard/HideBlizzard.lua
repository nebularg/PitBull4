
local PitBull4 = _G.PitBull4
local L = PitBull4.L

-----------------------------------------------------------------------------
-- luacheck: no global

local PitBull4_HideBlizzard = PitBull4:NewModule("HideBlizzard")
local module_active = false

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
	module_active = true
	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD", "UpdateFrames")
	self:RegisterEvent("GROUP_ROSTER_UPDATE", "UpdateFrames")
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnDisable()
	module_active = false
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnProfileChanged()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:ADDON_LOADED(_, addon)
	if addon == "Blizzard_ArenaUI" or addon == "Blizzard_Deprecated_ArenaUI"
		or addon == "Blizzard_CompactRaidFrames" or addon == "Blizzard_UnitFrame"
		or addon == "Blizzard_BuffFrame" or addon == "Blizzard_UIPanels_Game"
		or addon == "Blizzard_EditMode" then
		self:UpdateFrames()
	end
end

local hiders = {}
local frame_states = {}
local generation_hooks = {}
local generation_names = { "CompactPartyFrame_Generate", "CompactArenaFrame_Generate" }
local updating = false
local update_again = false
local hidden_frame = CreateFrame("Frame")
hidden_frame:Hide()

-- This listener survives module disable so restoration requested during combat
-- still finishes. Repeated changes are coalesced and use the latest profile.
hidden_frame:SetScript("OnEvent", function(self)
	self:UnregisterEvent("PLAYER_REGEN_ENABLED")
	PitBull4_HideBlizzard:UpdateFrames()
end)

local function defer_update()
	hidden_frame:RegisterEvent("PLAYER_REGEN_ENABLED")
end

local function hide_alpha(state)
	if not state.alpha_hidden then
		state.alpha = state.frame:GetAlpha()
		state.alpha_hidden = true
	end
	state.applying = true
	state.frame:SetAlpha(0)
	state.applying = false
end

local function restore_alpha(state)
	if state.alpha_hidden then
		state.alpha_hidden = false
		-- Alpha may be secret. Pass it directly to the native display method;
		-- never compare, calculate, or convert it in addon code.
		state.frame:SetAlpha(state.alpha)
		state.alpha = nil
	end
end

local function suppress_frame(state)
	local frame = state.frame
	if state.keep_parent then
		-- Keep native cast/animation state, visibility, parenting, and Edit Mode
		-- methods intact. Only suppress rendering and mouse input.
		hide_alpha(state)
		if not state.mouse_hidden then
			state.mouse_enabled = frame:IsMouseEnabled()
			state.mouse_hidden = true
		end
		state.applying = true
		frame:EnableMouse(false)
		state.applying = false
	else
		state.applying = true
		frame:SetParent(hidden_frame)
		state.applying = false
		restore_alpha(state)
	end
end

local function parent_changed(frame)
	local state = frame_states[frame]
	if not state.suppressed or state.applying or state.keep_parent then return end
	local parent = frame:GetParent()
	if parent == hidden_frame then return end
	-- Retain Blizzard's latest parent request, including Edit Mode changes.
	state.parent = parent
	if InCombatLockdown() then
		-- SetAlpha is cosmetic and combat-safe; SetParent is protected. Keep a
		-- native combat reparent invisible until parenting can be reapplied.
		hide_alpha(state)
		defer_update()
	else
		suppress_frame(state)
	end
end

local function alpha_changed(frame, alpha)
	local state = frame_states[frame]
	if not state.alpha_hidden or state.applying then return end
	state.alpha = alpha
	state.applying = true
	frame:SetAlpha(0)
	state.applying = false
end

local function mouse_changed(frame, enabled)
	local state = frame_states[frame]
	if not state.mouse_hidden or state.applying then return end
	state.mouse_enabled = enabled
	if InCombatLockdown() then
		defer_update()
	else
		state.applying = true
		frame:EnableMouse(false)
		state.applying = false
	end
end

local function track_frames(keep_parent, ...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		if frame then
			local state = frame_states[frame]
			if not state then
				state = { frame = frame, keep_parent = keep_parent }
				frame_states[frame] = state
				hooksecurefunc(frame, "SetParent", parent_changed)
				hooksecurefunc(frame, "SetAlpha", alpha_changed)
				if keep_parent then
					hooksecurefunc(frame, "EnableMouse", mouse_changed)
				end
			end
			state.wanted = true
		end
	end
end

local function frames_generated()
	if module_active and PitBull4_HideBlizzard:IsEnabled() then
		PitBull4_HideBlizzard:UpdateFrames()
	end
end

function PitBull4_HideBlizzard:UpdateFrames()
	if InCombatLockdown() then
		defer_update()
		return
	end
	if updating then
		update_again = true
		return
	end
	updating = true
	repeat
		update_again = false
		-- Modern compact frames may be generated after login or an option
		-- change without an ADDON_LOADED event. Install each post-hook once.
		for _, name in ipairs(generation_names) do
			if not generation_hooks[name] and type(_G[name]) == "function" then
				generation_hooks[name] = true
				hooksecurefunc(name, frames_generated)
			end
		end
		for _, state in pairs(frame_states) do state.wanted = false end
		if module_active and self:IsEnabled() then
			for name, hider in pairs(hiders) do
				if self.db.profile.global[name] then hider(self) end
			end
		end
		for frame, state in pairs(frame_states) do
			if state.wanted then
				if not state.suppressed then
					state.parent = frame:GetParent()
					state.suppressed = true
					suppress_frame(state)
				elseif not state.keep_parent and frame:GetParent() ~= hidden_frame then
					suppress_frame(state)
				elseif state.keep_parent and frame:IsMouseEnabled() then
					state.applying = true
					frame:EnableMouse(false)
					state.applying = false
				end
			elseif state.suppressed then
				-- Release suppression before native OnShow/parent callbacks run.
				-- Never force Show(): targets, pets, bosses, cast bars, etc. retain
				-- Blizzard's current unit-watch and contextual visibility state.
				state.suppressed = false
				if not state.keep_parent then frame:SetParent(state.parent) end
				restore_alpha(state)
				if state.mouse_hidden then
					state.mouse_hidden = false
					frame:EnableMouse(state.mouse_enabled)
					state.mouse_enabled = nil
				end
				state.parent = nil
			end
		end
	until not update_again
	updating = false
end

-----------------------------------------------------------------------------

function hiders:player()
	if ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) then
		track_frames(false, PlayerFrame, PlayerFrameAlternateManaBar or AlternatePowerBar)
	else
		track_frames(false, PlayerFrame)
	end
	track_frames(false, PetFrame)
end

if ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM) then
	function hiders:runebar()
		local monk_bar = MonkHarmonyBarFrame
		local paladin_bar = PaladinPowerBarFrame
		if PitBull4.wow_classic then
			monk_bar = monk_bar or MonkHarmonyBar
			paladin_bar = paladin_bar or PaladinPowerBar
		end
		-- Class-resource frames are optional and use different Classic names.
		-- Modern ClassPowerBar:GetUnit(), Setup(), and UpdateMaxPower() read
		-- the native grandparent's unit. Reparenting the bar breaks that chain,
		-- including combat events on a hidden/inactive WarlockPowerFrame.
		-- Keep modern parenting intact; retain legacy Classic suppression.
		track_frames(not PitBull4.wow_classic, RuneFrame, WarlockPowerFrame, monk_bar, paladin_bar, MageArcaneChargesFrame, EssencePlayerFrame)
	end
end

function hiders:party()
	if PartyFrame then
		track_frames(false, PartyFrame)
	else
		for i = 1, MAX_PARTY_MEMBERS or 4 do
			local name = "PartyMemberFrame" .. i
			track_frames(false, _G[name])
		end
	end
	track_frames(false, CompactPartyFrame)
end

function hiders:raid()
	-- Do not overwrite IsShown or unregister roster events. Blizzard remains
	-- responsible for the user's raid/raid-style-party display preferences.
	track_frames(false, CompactRaidFrameManager, CompactRaidFrameContainer, CompactPartyFrame)
end

function hiders:target()
	track_frames(false, TargetFrame, ComboFrame, TargetFrameToT)
end

function hiders:focus()
	track_frames(false, FocusFrame, FocusFrameToT)
end

function hiders:castbar()
	track_frames(true, PlayerCastingBarFrame or CastingBarFrame, PetCastingBarFrame)
end

function hiders:aura()
	track_frames(false, BuffFrame, TemporaryEnchantFrame or DebuffFrame)
end

function hiders:altpower()
	-- Its native OnHide calls Setup(), which reparents the bar and would
	-- undo ancestor suppression. Preserve that lifecycle like the cast bars.
	track_frames(true, PlayerPowerBarAlt)
end

function hiders:boss()
	for i = 1, MAX_BOSS_FRAMES or 5 do
		local name = "Boss" .. i .. "TargetFrame"
		track_frames(false, _G[name])
	end
end

function hiders:arena()
	if ArenaEnemyFramesContainer then -- Retail/Forever bg flag carriers
		track_frames(false, ArenaEnemyFramesContainer, ArenaEnemyPrepFramesContainer, ArenaEnemyMatchFramesContainer)
	else -- Classic or an unloaded optional arena addon
		track_frames(false, ArenaPrepFrames, ArenaEnemyFrames)
	end
	track_frames(false, CompactArenaFrame)
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
		disabled = not ClassicExpansionAtLeast(LE_EXPANSION_CATACLYSM),
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
	}
end)
