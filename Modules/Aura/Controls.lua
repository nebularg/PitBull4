-- Controls.lua : Implement the controls we need for the Aura module.

local PitBull4 = _G.PitBull4
local L = PitBull4.L
local PitBull4_Aura = PitBull4:GetModule("Aura")

local LibClassicDurations = PitBull4.wow_classic and LibStub("LibClassicDurations", true)

local UnitAura = LibClassicDurations and LibClassicDurations.UnitAuraWithBuffs or _G.UnitAura

-- Table of functions included into the aura controls
local Aura = {}

-- Table of scripts set on a control
local Aura_scripts = {}

-- Calculate the path to the texture for the borders.
local border_path = [[Interface\AddOns\PitBull4\Modules\Aura\border]]

-- Get the unit the aura applies to.
function Aura:GetUnit()
	return self:GetParent().unit
end


-- Update handler for tooltips.
-- Not in the Aura table since it is only active when the
-- tooltip is displayed.
local last_aura_OnUpdate = 0
local function OnUpdate(self, elapsed)
	last_aura_OnUpdate = last_aura_OnUpdate + elapsed
	if last_aura_OnUpdate < 0.2 then return end
	last_aura_OnUpdate = 0

	local id = self.id
	if id > 0 then
		-- Real Buffs
		local unit = self:GetUnit()
		local filter = self.is_buff and "HELPFUL" or "HARMFUL"
		-- Check that the cached id is still refrencing the same aura.
		-- If not walk the aura tree to find one of the same name so the
		-- tooltip will match.  UNIT_AURA events are not fired when the
		-- unit goes out of range but the order of the auras by index change.
		-- For a more detailed explanation for why this silly hack is necessary see:
		-- http://www.wowace.com/addons/pitbull4/tickets/532-aura-tooltips-not-matching-icons/
		-- or
		-- http://forums.worldofwarcraft.com/thread.html?topicId=16904201555&sid=1&pageNo=9#166
		local name = UnitAura(unit, id, filter)
		if name ~= self.name then
			local i = 1
			while true do
				name = UnitAura(unit, i, filter)
				if not name then
					-- Couldn't find a matching aura so do nothing.
					return
				end
				if name == self.name then
					-- Use this id, it may not be the right one but if the name
					-- doesn't match it means we're out of range of the unit so
					-- it doesn't matter which one we use as long as it is the same
					-- name to provide the proper tooltip.  Using the wrong one is
					-- ok since when we're out of range the time left won't be
					-- available anyway.  It may seem desireable to cache the
					-- id on the aura frame so we don't have to redo this.  However,
					-- if there are two of the same aura and we selected the wrong one
					-- then the time left tooltip will be wrong when we move back in range.
					id = i
					break
				end
				i = i + 1
			end
		end

		-- if filter == "HELPFUL" and not UnitIsFriend("player", unit) and not UnitAura(unit, 1, filter) then
		-- 	-- Fake the tooltip for enemy buffs
		-- 	local expiration_time, _, _, _, spell_id = select(6, UnitAura(unit, id, filter))

		-- 	GameTooltip:ClearLines()
		-- 	GameTooltip:AddDoubleLine(name, _G.ENEMY, 1, 0.82, 0, 1, 0.82, 0)

		-- 	local spell_description = GetSpellDescription(spell_id) or ""
		-- 	if spell_description ~= "" then
		-- 		GameTooltip:AddLine(spell_description, 1, 1, 1, 1)
		-- 	else
		-- 		last_aura_OnUpdate = 1 -- don't throttle updates until we have spell data
		-- 	end

		-- 	GameTooltip:Show()
		-- 	return
		-- end
		GameTooltip:SetUnitAura(unit, id, filter)
	elseif self.slot then
		local has_item = GameTooltip:SetInventoryItem("player", self.slot)
		if not has_item then
			GameTooltip:ClearLines()
			GameTooltip:AddLine(self.name, 1, 0.82, 0)
			GameTooltip:AddLine(L["Sample tempoary weapon enchant created by PitBull to allow you to see the results of your configuration easily."], 1, 1, 1, 1)
			GameTooltip:Show()
		end
	else
		-- Sample auras for config mode
		GameTooltip:ClearLines()
		-- Note that debuff_type gets localized here when displaying it
		-- because it needs to be in English for sorting and border
		-- purposes.  However the debuff types still need to be in our
		-- localization tables.  They are L["Poison"], L["Magic"],
		-- L["Disease"], L["Enrage"]
		GameTooltip:AddDoubleLine(self.name, self.debuff_type and L[self.debuff_type] or "", 1, 0.82, 0, 1, 0.82, 0)
		GameTooltip:AddLine(L["Sample aura created by PitBull to allow you to see the results of your configuration easily."], 1, 1, 1, 1)
		if self.is_mine then
			GameTooltip:AddLine(L["Aura shown as if cast by you."], 1, 0.82, 0, 1)
		else
			GameTooltip:AddLine(L["Aura shown as if cast by someone else."], 1, 0.82, 0, 1)
		end
		GameTooltip:Show()
	end
end

-- Click handler to allow buffs to be canceled.
-- Not in the Aura table since it is only active on
-- buff aura controls.
local function OnClick(self)
	if not self.is_buff or not UnitIsUnit("player",self:GetUnit()) then return end
	local slot = self.slot
	if InCombatLockdown() or slot then return end
	if slot then
		if slot == _G.INVSLOT_MAINHAND then
			CancelItemTempEnchantment(1)
		elseif slot == _G.INVSLOT_OFFHAND then
			CancelItemTempEnchantment(2)
		end
	else
		CancelUnitBuff("player", self.id)
	end
end

function Aura_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	last_aura_OnUpdate = 0
	self:SetScript("OnUpdate", OnUpdate)
	OnUpdate(self, 1)
end

function Aura_scripts:OnLeave()
	GameTooltip:Hide()
	self:SetScript("OnUpdate", nil)
end

-- Control for the Auras
PitBull4.Controls.MakeNewControlType("Aura", "Button", function(control)
	-- onCreate
	control:RegisterForClicks("RightButtonUp")
	control:SetScript("OnClick", OnClick)

	local texture = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
	control.texture = texture
	texture:SetAllPoints(control)

	local overlay = PitBull4.Controls.MakeFrame(control, "OVERLAY")
	control.overlay = overlay
	overlay:SetAllPoints(control)

	local border = PitBull4.Controls.MakeTexture(control, "BORDER")
	control.border = border
	border:SetAllPoints(control)
	border:SetTexture(border_path)

	local count_text = PitBull4.Controls.MakeFontString(overlay, "OVERLAY")
	control.count_text = count_text
	count_text:SetShadowColor(0, 0, 0, 1)
	count_text:SetShadowOffset(0.8, -0.8)
	count_text:SetPoint("BOTTOMRIGHT", control, "BOTTOMRIGHT", 0, 0)

	local cooldown = PitBull4.Controls.MakeCooldown(control)
	control.cooldown = cooldown
	cooldown:SetReverse(true)
	cooldown:SetHideCountdownNumbers(true)
	cooldown:SetAllPoints(control)

	-- Set the overlay above the cooldown spinner so the fonts will be over it.
	overlay:SetFrameLevel(cooldown:GetFrameLevel()+1)

	local cooldown_text = PitBull4.Controls.MakeFontString(overlay, "OVERLAY")
	control.cooldown_text = cooldown_text
	cooldown_text:SetShadowColor(0, 0, 0, 1)
	cooldown_text:SetShadowOffset(0.8, -0.8)
	cooldown_text:SetPoint("TOP", control, "TOP", 0, 0)

	for k,v in pairs(Aura) do
		control[k] = v
	end
	for k,v in pairs(Aura_scripts) do
		control:SetScript(k, v)
	end
end, function(control)
	-- onRetrieve
	-- It's important to note that you should never ever do something
	-- here that is dependent upon the actual aura being set or even
	-- the unit of the frame it is parented to.  It is fine to do things
	-- that depend upon the frame it is parented to here.  Other than
	-- that everything should be done when the actual aura is set on
	-- the control.  This is because the controls are recyled unless
	-- the number of them changes a new control will not be retrieved.

	local group = control:GetParent().masque_group
	if group then
		group:AddButton(control, {
			Icon = control.texture,
			Cooldown = control.cooldown,
			Border = control.border,
			-- Count = control.count_text,
			-- Duration = control.cooldown_text,
		}, "Legacy")
	else
		-- reset the control layout
		local texture = control.texture
		texture:SetAllPoints(control)
		texture:SetTexCoord(0, 1, 0, 1)

		local border = control.border
		border:SetAllPoints(control)
		border:SetTexture(border_path)
		border:SetBlendMode("BLEND")

		local cooldown = control.cooldown
		cooldown:SetAllPoints(control)
		cooldown:SetFrameLevel(control:GetFrameLevel() + 1)
		control.overlay:SetFrameLevel(cooldown:GetFrameLevel() + 1)
	end
end, function(control)
	-- onDelete
	control:SetScript("OnUpdate", nil)
	PitBull4_Aura:DisableCooldownText(control)

	local group = control:GetParent().masque_group
	if group then
		group:RemoveButton(control)

		-- Stop frame level tampering (Masque 8.0)
		control.__MSQ_Cooldown = nil

		-- Remove the "Blizzard" skin
		local texture = control.__MSQ_Normal or control.__MSQ_NormalTexture
		if texture then
			texture:SetTexture(nil)
		end
	end
end)
