
local PitBull4 = _G.PitBull4
local L = PitBull4.L

-- luacheck: no global

local PitBull4_HideBlizzard = PitBull4:NewModule("HideBlizzard", "AceHook-3.0")

local wow_bcc = PitBull4.wow_bcc

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
		frame:SetAttribute("statehidden", true)
		hook_frames(frame)
	end

	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

function showers:party()
	for i = 1, MAX_PARTY_MEMBERS do
		local frame = _G["PartyMemberFrame" .. i]
		frame:SetAttribute("statehidden", nil)
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
	if not wow_bcc then return end
	hook_frames(FocusFrame)
end

function showers:focus()
	if not wow_bcc then return end
	unhook_frames(FocusFrame)
end

function hiders:castbar()
	rawhook_frames(CastingBarFrame, PetCastingBarFrame)
end

function showers:castbar()
	unhook_frames(CastingBarFrame, PetCastingBarFrame)
end

function hiders:aura()
	hook_frames(BuffFrame, TemporaryEnchantFrame)
end

function showers:aura()
	unhook_frames_without_init(BuffFrame, TemporaryEnchantFrame)
	BuffFrame:RegisterUnitEvent("UNIT_AURA", "player", "vehicle")
	BuffFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
	BuffFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	BuffFrame:Show()

	TemporaryEnchantFrame:Show()
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
		hidden = function(info) return not wow_bcc or hidden(info) end,
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
	}
end)
