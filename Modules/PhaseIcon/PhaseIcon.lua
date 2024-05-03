
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local wow_cata = PitBull4.wow_cata

local PitBull4_PhaseIcon = PitBull4:NewModule("PhaseIcon")

PitBull4_PhaseIcon:SetModuleType("indicator")
PitBull4_PhaseIcon:SetName(L["Phase icon"])
PitBull4_PhaseIcon:SetDescription(L["Show an icon on the unit frame if the unit is out of phase with you."])
PitBull4_PhaseIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
	click_through = false,
})

function PitBull4_PhaseIcon:OnEnable()
	self:RegisterEvent("UNIT_PHASE")
	self:RegisterEvent("UNIT_FLAGS", "UNIT_PHASE")
	self:RegisterEvent("PARTY_MEMBER_ENABLE")
	self:RegisterEvent("PARTY_MEMBER_DISABLE", "PARTY_MEMBER_ENABLE")
end


function PitBull4_PhaseIcon:GetEnableMouse(frame)
	local db = self:GetLayoutDB(frame)
	return not db.click_through
end

function PitBull4_PhaseIcon:OnEnter()
	local tooltip = _G.PARTY_PHASED_MESSAGE
	if not wow_cata then
		local unit = self:GetParent().unit
		local phaseReason = UnitPhaseReason(unit)
		local tooltip = PartyUtil.GetPhasedReasonString(phaseReason, unit) or _G.PARTY_PHASED_MESSAGE
	end
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(tooltip, nil, nil, nil, nil, true)
	GameTooltip:Show()
end

function PitBull4_PhaseIcon:OnLeave()
	GameTooltip:Hide()
end

function PitBull4_PhaseIcon:GetTexture(frame)
	local unit = frame.unit
	-- Note the UnitInPhase function doesn't work for pets.
	if not unit or not UnitIsPlayer(unit) or not UnitExists(unit) or not UnitIsConnected(unit) then
		return nil
	end

	if wow_cata then
		if UnitInPhase(unit) then
			return nil
		end
	elseif not UnitPhaseReason(unit) then
		return nil
	end

	return [[Interface\TargetingFrame\UI-PhasingIcon]]
end

function PitBull4_PhaseIcon:GetExampleTexture(frame)
	return [[Interface\TargetingFrame\UI-PhasingIcon]]
end

function PitBull4_PhaseIcon:UNIT_PHASE(_, unit)
	-- UNIT_PHASE fires for some units at different points than for others.
	-- So we update by GUID rather than by unit id to increase accuracy
	self:UpdateForGUID(UnitGUID(unit))
end

function PitBull4_PhaseIcon:PARTY_MEMBER_ENABLE(_, unit)
	self:UpdateAll()
end


PitBull4_PhaseIcon:SetLayoutOptionsFunction(function(self)
	return "click_through", {
		type = "toggle",
		name = L["Click-through"],
		desc = L["Disable capturing clicks on icons, allowing the click to fall through to the window underneath the icon."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).click_through
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).click_through = value

			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
				self:Update(frame)
			end
		end,
		order = 100,
	}
end)
