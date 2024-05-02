
local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- luacheck: no global

local PitBull4_HideBlizzard = PitBull4:NewModule("HideBlizzard")

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
	boss = true,
})

function PitBull4_HideBlizzard:OnEnable()
	if not CompactRaidFrameManager then
		self:RegisterEvent("ADDON_LOADED")
	end
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnDisable()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnProfileChanged()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:ADDON_LOADED(event, addon)
	if addon == "Blizzard_CompactRaidFrames" then
		self:UnregisterEvent(event)
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
			self:Print("Showing hidden frames requires reloading the UI.")
			LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
		end
	end
end
PitBull4_HideBlizzard.UpdateFrames = PitBull4:OutOfCombatWrapper(PitBull4_HideBlizzard.UpdateFrames)

local noop = function() end
local hide_frame = PitBull4:OutOfCombatWrapper(function(self) self:Hide() end)

local hidden_frame = CreateFrame("Frame")
hidden_frame:Hide()

local function hook_frames(raw, ...)
	for i = 1, select("#", ...) do
		local frame = select(i, ...)
		UnregisterUnitWatch(frame)
		frame:UnregisterAllEvents()
		frame:Hide()

		if frame.manabar then frame.manabar:UnregisterAllEvents() end
		if frame.healthbar then frame.healthbar:UnregisterAllEvents() end
		if frame.spellbar then frame.spellbar:UnregisterAllEvents() end

		if raw then
			frame.Show = noop
		else
			frame:SetParent(hidden_frame)
			frame:HookScript("OnShow", hide_frame)
		end
	end
end


function hiders:player()
	hook_frames(false, PlayerFrame)
	-- BuffFrame_Update()
	-- BuffFrame needs an update, but calling directly will taint things
	PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	PlayerFrame:SetMovable(true)
	PlayerFrame:SetUserPlaced(true)
	PlayerFrame:SetDontSavePosition(true)
end

function hiders:party()
	for i = 1, MAX_PARTY_MEMBERS do
		local name = "PartyMemberFrame" .. i
		hook_frames(false, _G[name], _G[name .. "HealthBar"], _G[name .. "ManaBar"])
	end

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")

	if CompactPartyFrame then
		hook_frames(false, CompactPartyFrame)
	end
end

do
	local raid_shown = nil
	local function hide_raid()
			CompactRaidFrameManager:UnregisterAllEvents()
			CompactRaidFrameContainer:UnregisterAllEvents()
			if InCombatLockdown() then return end

			CompactRaidFrameManager:Hide()
			raid_shown = CompactRaidFrameManager_GetSetting("IsShown")
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
			if self:IsEnabled() and self.db.profile.global.raid then
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

function hiders:castbar()
	hook_frames(true, CastingBarFrame, PetCastingBarFrame)
end

function hiders:aura()
	hook_frames(false, BuffFrame, TemporaryEnchantFrame)
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
		hidden = function() return not self:IsEnabled() or not reload_needed end,
	}
end)
