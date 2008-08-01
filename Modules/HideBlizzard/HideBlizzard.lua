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
	raid = false,
	target = true, 
	focus = true,
	castbar = true,
	aura = false,
	runebar = true,
	altpower = false,
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

local function hook_playerframe()
	hooksecurefunc("PlayerFrame_HideVehicleTexture",function()
		if currently_hidden["runebar"] then
			hiders["runebar"]()
		end
	end)
	hook_playerframe = nil
end

local function hook_raidmanager()
	hooksecurefunc("CompactRaidFrameManager_UpdateShown",function()
		if currently_hidden["raid"] then
			hiders["raid"]()
		end
	end)
	hook_raidmanager = nil
end

local function hook_compactparty()
	hooksecurefunc("CompactPartyFrame_UpdateShown",function()
		if currently_hidden["party"] then
			hiders["party"]()
		end
	end)
	hook_compactparty = nil
end

function hiders:player()
	-- Only hide the PlayerFrame, do not mess with the events.
	-- Unfortunately, messing the PlayerFrame ends up spreading
	-- taint to the BuffFrame which matters now that CancelUnitBuff
	-- is protected.
	PlayerFrame:Hide()
end

function showers:player()
	PlayerFrame:Show()
end

function hiders:party()
	for i = 1, 4 do
		local frame = _G["PartyMemberFrame"..i]
		frame:UnregisterAllEvents()
		frame:Hide()
		frame.Show = function() end
	end
	
	UIParent:UnregisterEvent("GROUP_ROSTER_UPDATE")
end

function showers:party()
	for i = 1, 4 do
		local frame = _G["PartyMemberFrame"..i]
		frame.Show = nil
		frame:GetScript("OnLoad")(frame)
		frame:GetScript("OnEvent")(frame, "GROUP_ROSTER_UPDATE")
		
		PartyMemberFrame_UpdateMember(frame)
	end

	UIParent:RegisterEvent("GROUP_ROSTER_UPDATE")
end

local compact_raid
function hiders:raid()
	CompactRaidFrameManager:UnregisterEvent("GROUP_ROSTER_UPDATE")
	CompactRaidFrameManager:UnregisterEvent("PLAYER_ENTERING_WORLD")
	CompactRaidFrameManager:Hide()
	compact_raid = CompactRaidFrameManager_GetSetting("IsShown")
	if compact_raid and compact_raid ~= "0" then 
		CompactRaidFrameManager_SetSetting("IsShown", "0")
	end
	if hook_raidmanager then
		hook_raidmanager()
	end
end

function showers:raid()
	CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")	
	CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
	if GetDisplayedAllyFrames then
		if GetDisplayedAllyFrames() == "raid" then
			CompactRaidFrameManager:Show()
		end
	elseif GetNumRaidMembers() > 0 then
		CompactRaidFrameManager:Show()
	end
	if compact_raid and compact_raid ~= "0" then
		CompactRaidFrameManager_SetSetting("IsShown", "1")
	end
end

function hiders:target()
	TargetFrame:UnregisterAllEvents()
	TargetFrame:Hide()

	ComboFrame:UnregisterAllEvents()
end

function showers:target()
	TargetFrame:GetScript("OnLoad")(TargetFrame)

	ComboFrame:GetScript("OnLoad")(ComboFrame)
end

function hiders:focus()
	FocusFrame:UnregisterAllEvents()
	FocusFrame:Hide()
end

function showers:focus()
	FocusFrame:GetScript("OnLoad")(FocusFrame)
end

function hiders:castbar()
	CastingBarFrame:UnregisterAllEvents()
	PetCastingBarFrame:UnregisterAllEvents()
end

function showers:castbar()
	CastingBarFrame:GetScript("OnLoad")(CastingBarFrame)
	PetCastingBarFrame:GetScript("OnLoad")(PetCastingBarFrame)
end

function hiders:runebar()
	if hook_playerframe then
		hook_playerframe()
	end
	RuneFrame:UnregisterAllEvents()
	RuneFrame:Hide()
end

function showers:runebar()
	local _,class = UnitClass("player")
	if class == "DEATHKNIGHT" then
		RuneFrame:Show()
	end
	RuneFrame:GetScript("OnLoad")(RuneFrame)
	RuneFrame:GetScript("OnEvent")(RuneFrame, "PLAYER_ENTERING_WORLD")
end

function hiders:aura()
	BuffFrame:Hide()
	TemporaryEnchantFrame:Hide()
	ConsolidatedBuffs:Hide()
	BuffFrame:UnregisterAllEvents()
end

function showers:aura()
	BuffFrame:Show()
	if GetCVarBool("consolidateBuffs") then
		ConsolidatedBuffs:Show()
	end
	TemporaryEnchantFrame:Show()

	-- Can't use OnLoad because doing so resets some variables which
	-- requires an update to get the frame back in the proper state,
	-- which in Cata causes taint.
	BuffFrame:RegisterEvent("UNIT_AURA")

	-- This isn't perfect.  It doesn't update the buffs till the next
	-- aura update.  However, in Cata it causes taint to force the update.
	-- However, it should work for 99% of peoples use cases, which is toggling
	-- it on and off to see what it does or setting it and leaving it set.
end

function hiders:altpower()
	PlayerPowerBarAlt:UnregisterAllEvents()
	PlayerPowerBarAlt:Hide()
end

function showers:altpower()
	PlayerPowerBarAlt:GetScript("OnLoad")(PlayerPowerBarAlt)
	UnitPowerBarAlt_UpdateAll(PlayerPowerBarAlt)
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
		get = function (info)
			if GetDisplayedAllyFrames() == "raid" then
				return false
			else
				return get(info)
			end
		end,
		set = set,
		hidden = hidden,	
		disabled = function() return GetDisplayedAllyFrames() == "raid" end,
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
	}, 'runebar', {
		type = 'toggle',
		name = L["Rune bar"],
		desc = L["Hides the standard rune bar in the top-left corner of the screen."],
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
	}
end)
