-- Aura.lua : Core setup of the Aura module and event processing

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:NewModule("Aura", "AceEvent-3.0")

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
	self:RegisterEvent("UNIT_AURA")
	timerFrame:Show()

	-- Need to track spec changes since it can change what they can dispel.
	local _,player_class = UnitClass("player")
	if player_class == "DRUID" or player_class == "MONK" or player_class == "PALADIN" or player_class == "PRIEST" or player_class == "SHAMAN" then
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:RegisterEvent("SPELLS_CHANGED", "PLAYER_TALENT_UPDATE")
		self:PLAYER_TALENT_UPDATE()
	end
end

function PitBull4_Aura:OnDisable()
	timerFrame:Hide()
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
