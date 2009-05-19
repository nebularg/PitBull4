-- Aura.lua : Core setup of the Aura module and event processing

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
if not PitBull4 then
        error("PitBull4_Aura requires PitBull4")
end
local wipe = _G.table.wipe

local L = PitBull4.L
local PitBull4_Aura= PitBull4:NewModule("Aura", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_Aura:SetModuleType("custom")
PitBull4_Aura:SetName(L["Aura"])
PitBull4_Aura:SetDescription(L["Shows buffs and debuffs for PitBull4 frames."])

-- constants for slot ids
PitBull4_Aura.MAINHAND = GetInventorySlotInfo("MainHandSlot")
PitBull4_Aura.OFFHAND = GetInventorySlotInfo("SecondaryHandSlot")


function PitBull4_Aura:OnEnable()
	self:RegisterEvent("UNIT_AURA")
	self:ScheduleRepeatingTimer("OnUpdate", 0.2)

	-- Need to track talents for Shaman since it can change what they
	-- can dispel.
	local _,player_class = UnitClass('player')
	if player_class == 'SHAMAN' then
		self:RegisterEvent("PLAYER_TALENT_UPDATE")
		self:RegisterEvent("CHARACTER_POINTS_CHANGED","PLAYER_TALENT_UPDATE")
		-- Update the Shaman can dispel filter
		PitBull4_Aura:GetFilterDB('23').aura_type_list.Curse = PitBull4_Aura.can_dispel.SHAMAN.Curse
	end
end

function PitBull4_Aura:ClearFrame(frame)
	self:ClearAuras(frame)
end

function PitBull4_Aura:UpdateFrame(frame)
	self:UpdateAuras(frame)
	self:LayoutAuras(frame)
end
