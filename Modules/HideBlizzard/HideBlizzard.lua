if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HideBlizzard requires PitBull4")
end

local L = PitBull4.L

local PitBull4_HideBlizzard = PitBull4:NewModule("HideBlizzard")

PitBull4_HideBlizzard:SetModuleType("custom")
PitBull4_HideBlizzard:SetName(L["Hide Blizzard frames"])
PitBull4_HideBlizzard:SetDescription(L["Hide Blizzard frames that are no longer needed."])
PitBull4_HideBlizzard:SetDefaults({}, {
	player = true,
	party = true,
	target = true,
	focus = true,
	castbar = true,
	aura = false,
	runebar = true,
})

function PitBull4_HideBlizzard:OnEnable()
	self:UpdateFrames()
end

function PitBull4_HideBlizzard:OnDisable()
	self:UpdateFrames()
end

local showers = {}
local hiders = {}
local currently_hidden = {}

function PitBull4_HideBlizzard:UpdateFrames()
	for name in pairs(showers) do
		if not self:IsEnabled() or self.db.profile.global[name] then
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

function hiders:player()
	PlayerFrame:UnregisterAllEvents()
	PlayerFrameHealthBar:UnregisterAllEvents()
	PlayerFrameManaBar:UnregisterAllEvents()
	PlayerFrame:Hide()
end

function showers:player()
	PlayerFrame:RegisterEvent("UNIT_LEVEL")
	PlayerFrame:RegisterEvent("UNIT_COMBAT")
	PlayerFrame:RegisterEvent("UNIT_SPELLMISS")
	PlayerFrame:RegisterEvent("UNIT_PVP_UPDATE")
	PlayerFrame:RegisterEvent("UNIT_MAXMANA")
	PlayerFrame:RegisterEvent("PLAYER_ENTER_COMBAT")
	PlayerFrame:RegisterEvent("PLAYER_LEAVE_COMBAT")
	PlayerFrame:RegisterEvent("PLAYER_UPDATE_RESTING")
	PlayerFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	PlayerFrame:RegisterEvent("PARTY_LEADER_CHANGED")
	PlayerFrame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
	PlayerFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	PlayerFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
	PlayerFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
	PlayerFrameHealthBar:RegisterEvent("UNIT_HEALTH")
	PlayerFrameHealthBar:RegisterEvent("UNIT_MAXHEALTH")
	PlayerFrameManaBar:RegisterEvent("UNIT_MANA")
	PlayerFrameManaBar:RegisterEvent("UNIT_RAGE")
	PlayerFrameManaBar:RegisterEvent("UNIT_FOCUS")
	PlayerFrameManaBar:RegisterEvent("UNIT_ENERGY")
	PlayerFrameManaBar:RegisterEvent("UNIT_HAPPINESS")
	PlayerFrameManaBar:RegisterEvent("UNIT_MAXMANA")
	PlayerFrameManaBar:RegisterEvent("UNIT_MAXRAGE")
	PlayerFrameManaBar:RegisterEvent("UNIT_MAXFOCUS")
	PlayerFrameManaBar:RegisterEvent("UNIT_MAXENERGY")
	PlayerFrameManaBar:RegisterEvent("UNIT_MAXHAPPINESS")
	PlayerFrameManaBar:RegisterEvent("UNIT_DISPLAYPOWER")
	PlayerFrame:RegisterEvent("UNIT_NAME_UPDATE")
	PlayerFrame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	PlayerFrame:RegisterEvent("UNIT_DISPLAYPOWER")
	PlayerFrame:Show()
end

function hiders:party()
	for i = 1, 4 do
		local frame = _G["PartyMemberFrame"..i]
		frame:UnregisterAllEvents()
		frame:Hide()
		frame.Show = function() end
	end
	
	UIParent:UnregisterEvent("RAID_ROSTER_UPDATE")
end

function showers:party()
	for i = 1, 4 do
		local frame = _G["PartyMemberFrame"..i]
		frame.Show = nil
		frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
		frame:RegisterEvent("PARTY_LEADER_CHANGED")
		frame:RegisterEvent("PARTY_MEMBER_ENABLE")
		frame:RegisterEvent("PARTY_MEMBER_DISABLE")
		frame:RegisterEvent("PARTY_LOOT_METHOD_CHANGED")
		frame:RegisterEvent("UNIT_PVP_UPDATE")
		frame:RegisterEvent("UNIT_AURA")
		frame:RegisterEvent("UNIT_PET")
		frame:RegisterEvent("VARIABLES_LOADED")
		frame:RegisterEvent("UNIT_NAME_UPDATE")
		frame:RegisterEvent("UNIT_PORTRAIT_UPDATE")
		frame:RegisterEvent("UNIT_DISPLAYPOWER")

		UnitFrame_OnEvent("PARTY_MEMBERS_CHANGED")
		
		PartyMemberFrame_UpdateMember(frame)
	end
	
	UIParent:RegisterEvent("RAID_ROSTER_UPDATE")
end

function hiders:target()
	TargetFrame:UnregisterAllEvents()
	TargetFrame:Hide()

	ComboFrame:UnregisterAllEvents()
end

function showers:target()
	TargetFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	TargetFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	TargetFrame:RegisterEvent("UNIT_HEALTH")
	TargetFrame:RegisterEvent("UNIT_LEVEL")
	TargetFrame:RegisterEvent("UNIT_FACTION")
	TargetFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
	TargetFrame:RegisterEvent("UNIT_AURA")
	TargetFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
	TargetFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	TargetFrame_Update(TargetFrame)

	ComboFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	ComboFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	ComboFrame:RegisterEvent("PLAYER_COMBO_POINTS")
end

function hiders:focus()
	FocusFrame:UnregisterAllEvents()
	FocusFrame:Hide()
end

function showers:focus()
	FocusFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
	FocusFrame:RegisterEvent("PLAYER_FOCUS_CHANGED")
	FocusFrame:RegisterEvent("UNIT_HEALTH")
	FocusFrame:RegisterEvent("UNIT_LEVEL")
	FocusFrame:RegisterEvent("UNIT_FACTION")
	FocusFrame:RegisterEvent("UNIT_CLASSIFICATION_CHANGED")
	FocusFrame:RegisterEvent("UNIT_AURA")
	FocusFrame:RegisterEvent("PLAYER_FLAGS_CHANGED")
	FocusFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
	FocusFrame_Update(FocusFrame)
end

function hiders:castbar()
	CastingBarFrame:UnregisterAllEvents()
	PetCastingBarFrame:UnregisterAllEvents()
end

function showers:castbar()
	for _, frame in ipairs { CastingBarFrame, PetCastingBarFrame } do
		frame:RegisterEvent("UNIT_SPELLCAST_START")
		frame:RegisterEvent("UNIT_SPELLCAST_STOP")
		frame:RegisterEvent("UNIT_SPELLCAST_FAILED")
		frame:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED")
		frame:RegisterEvent("UNIT_SPELLCAST_DELAYED")
		frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_START")
		frame:RegisterEvent("UNIT_SPELLCAST_CHANNEL_UPDATE")
		frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	end

	PetCastingBarFrame:RegisterEvent("UNIT_PET")
end

function hiders:runebar()
	RuneFrame:Hide()
	RuneFrame:UnregisterEvent("PLAYER_ENTERING_WORLD")
	RuneFrame:UnregisterEvent("RUNE_POWER_UPDATE")
	RuneFrame:UnregisterEvent("RUNE_TYPE_UPDATE")
end

function showers:runebar()
	RuneFrame:Show()
	RuneFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
	RuneFrame:RegisterEvent("RUNE_POWER_UPDATE")
	RuneFrame:RegisterEvent("RUNE_TYPE_UPDATE")
	RuneFrame_OnEvent(RuneFrame, "PLAYER_ENTERING_WORLD")
end

function hiders:aura()
	BuffFrame:Hide()
	TemporaryEnchantFrame:Hide()
	BuffFrame:UnregisterAllEvents()
end

function showers:aura()
	BuffFrame:Show()
	TemporaryEnchantFrame:Show()
	BuffFrame:RegisterEvent("PLAYER_AURAS_CHANGED")

	BuffFrame_Update()
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
	return 'player', {
		type = 'toggle',
		name = L["Player"],
		desc = L["Hide the standard player frame."],
		get = get,
		set = set,
	}, 'party', {
		type = 'toggle',
		name = L["Party"],
		desc = L["Hide the standard party frames."],
		get = get,
		set = set,
	}, 'target', {
		type = 'toggle',
		name = L["Target"],
		desc = L["Hide the standard target frame."],
		get = get,
		set = set,
	}, 'focus', {
		type = 'toggle',
		name = L["Focus"],
		desc = L["Hide the standard focus frame."],
		get = get,
		set = set,
	}, 'castbar', {
		type = 'toggle',
		name = L["Cast bar"],
		desc = L["Hides the standard cast bar."],
		get = get,
		set = set,
	}, 'aura', {
		type = 'toggle',
		name = L["Buffs/debuffs"],
		desc = L["Hides the standard buff/debuff frame in the top-right corner of the screen."],
		get = get,
		set = set,
	}, 'runebar', {
		type = 'toggle',
		name = L["Rune bar"],
		desc = L["Hides the standard rune bar in the top-left corner of the screen."],
		get = get,
		set = set,
	}
end)