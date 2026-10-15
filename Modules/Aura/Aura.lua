-- Aura.lua : Core setup of the Aura module and event processing

local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_Aura = PitBull4:NewModule("Aura")

local C_Secrets = _G.C_Secrets
local C_UnitAuras = _G.C_UnitAuras
local GetAuraDataByIndex = C_UnitAuras and C_UnitAuras.GetAuraDataByIndex
local GetAuraDataByAuraInstanceID = C_UnitAuras and C_UnitAuras.GetAuraDataByAuraInstanceID
local ShouldUnitAuraIndexBeSecret = C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret
local ShouldUnitAuraInstanceBeSecret = C_Secrets and C_Secrets.ShouldUnitAuraInstanceBeSecret
local issecrettable = _G.issecrettable
local pcall = _G.pcall
local MAX_AURA_SCAN_INDEX = 255

local function query_will_be_secret(predicate, ...)
	if not predicate then
		return false
	end

	local ok, is_secret = pcall(predicate, ...)
	return ok and is_secret or false
end

local function is_secret_aura_table(aura)
	if aura == nil or not issecrettable then
		return false
	end

	local ok, is_secret = pcall(issecrettable, aura)
	return not ok or is_secret
end

-- Midnight blocks tainted callers from querying aura entries whose data is
-- secret. Return a second true value when the caller should skip this index;
-- a normal nil aura instead marks the end of the list. Older clients do not
-- expose C_Secrets and continue through the original C_UnitAuras path.
function PitBull4_Aura.GetAccessibleAuraDataByIndex(unit, index, filter)
	if index > MAX_AURA_SCAN_INDEX then
		return nil, false
	end
	if query_will_be_secret(ShouldUnitAuraIndexBeSecret, unit, index, filter) then
		return nil, true
	end
	if not GetAuraDataByIndex then
		return nil, false
	end

	local ok, aura = pcall(GetAuraDataByIndex, unit, index, filter)
	if not ok then
		return nil, false
	end
	if is_secret_aura_table(aura) then
		return nil, true
	end

	return aura, false
end

function PitBull4_Aura.GetAccessibleAuraDataByAuraInstanceID(unit, aura_instance_id)
	if query_will_be_secret(ShouldUnitAuraInstanceBeSecret, unit, aura_instance_id) then
		return nil
	end
	if not GetAuraDataByAuraInstanceID then
		return nil
	end

	local ok, aura = pcall(GetAuraDataByAuraInstanceID, unit, aura_instance_id)
	if not ok or is_secret_aura_table(aura) then
		return nil
	end

	return aura
end

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
	self:RegisterEvent("PLAYER_REGEN_DISABLED", "UpdateAll")
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "UpdateAll")
	self:RegisterEvent("UNIT_AURA")
	timerFrame:Show()

	-- Rescan spells that can change what we can dispel and purge.
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	self:RegisterEvent("SPELLS_CHANGED", "PLAYER_TALENT_UPDATE")
	self:PLAYER_TALENT_UPDATE()
end

function PitBull4_Aura:OnDisable()
	timerFrame:Hide()
end

function PitBull4_Aura:OnProfileChanged()
	local funcs = self.OnProfileChanged_funcs
	for i = 1, #funcs do
		funcs[i](self)
	end
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
