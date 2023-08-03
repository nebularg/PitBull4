-- Aura.lua : Core setup of the Aura module and event processing

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:NewModule("Aura")

local wow_classic_era = PitBull4.wow_classic_era
local wow_wrath = PitBull4.wow_wrath

PitBull4_Aura:SetModuleType("custom")
PitBull4_Aura:SetName(L["Aura"])
PitBull4_Aura:SetDescription(L["Shows buffs and debuffs for PitBull4 frames."])

PitBull4_Aura.OnProfileChanged_funcs = {}

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()
local timer = 0
local elapsed_since_text_update = 0
timerFrame:SetScript("OnUpdate",function(self, elapsed)
	timer = timer + elapsed
	if timer >= 0.2 then
		if not PitBull4_Aura.db then
			self:Hide()
			geterrorhandler()("PitBull4_Aura: There was an error loading the module")
			for frame in PitBull4:IterateFrames() do
				PitBull4_Aura:ClearFrame(frame)
			end
			return
		end
		PitBull4_Aura:OnUpdate()
		timer = 0
	end

	local next_text_update = PitBull4_Aura.next_text_update
	if next_text_update then
		next_text_update = next_text_update - elapsed
		elapsed_since_text_update = elapsed_since_text_update + elapsed
		if next_text_update <= 0 then
			next_text_update = PitBull4_Aura:UpdateCooldownTexts(elapsed_since_text_update)
			elapsed_since_text_update = 0
		end
		PitBull4_Aura.next_text_update = next_text_update
	end
end)


function PitBull4_Aura:OnEnable()
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateAll")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateAll")
	self:RegisterEvent("UNIT_AURA")

	if wow_classic_era then
		local LibClassicDurations = LibStub("LibClassicDurations", true)
		if LibClassicDurations then
			LibClassicDurations:Register(self)
			LibClassicDurations.RegisterCallback(self, "UNIT_BUFF", "UNIT_AURA")
		end
	end

	timerFrame:Show()

	-- Need to track spec changes since it can change what they can dispel.
	local dispel_classes = {
		DRUID = true,
		HUNTER = true,
		MAGE = true,
		PALADIN = true,
		PRIEST = true,
		SHAMAN = true,
		WARLOCK = true,
		WARRIOR = wow_wrath,
	}
	local player_class = UnitClassBase("player")
	if dispel_classes[player_class] then
		if wow_classic_era then
			self:RegisterEvent("CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE")
		else
			self:RegisterEvent("PLAYER_TALENT_UPDATE")
		end
		self:RegisterEvent("SPELLS_CHANGED", "PLAYER_TALENT_UPDATE")
	end
	self:PLAYER_TALENT_UPDATE()
end

function PitBull4_Aura:OnDisable()
	timerFrame:Hide()

	if wow_classic_era then
		local LibClassicDurations = LibStub("LibClassicDurations", true)
		if LibClassicDurations then
			LibClassicDurations.UnregisterCallback(self, "UNIT_BUFF", "UNIT_AURA")
			LibClassicDurations:Unregister(self)
		end
	end
end

function PitBull4_Aura:OnProfileChanged()
	local funcs = self.OnProfileChanged_funcs
	for i = 1, #funcs do
		funcs[i](self)
	end
	LibStub("AceConfigRegistry-3.0"):NotifyChange("PitBull4")
end

function PitBull4_Aura:ClearFrame(frame)
	self:ClearAuras(frame)
	if frame.aura_highlight then
		frame.aura_highlight = frame.aura_highlight:Delete()
	end
end

PitBull4_Aura.OnHide = PitBull4_Aura.ClearFrame

function PitBull4_Aura:UpdateFrame(frame)
	self:UpdateSkin(frame)
	self:UpdateAuras(frame)
	self:LayoutAuras(frame)
end

function PitBull4_Aura:LibSharedMedia_Registered(event, mediatype, key)
	if mediatype == "font" then
		self:UpdateAll()
	end
end
