
local PitBull4 = _G.PitBull4

local ArcaneCharge_scripts = {}

function ArcaneCharge_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G.ARCANE_CHARGES)
	GameTooltip:AddLine(_G.ARCANE_CHARGES_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

function ArcaneCharge_scripts:OnLeave()
	GameTooltip:Hide()
end

PitBull4.Controls.MakeNewControlType("ArcaneCharge", "Frame", function(control)
	-- onCreate

	for k, v in pairs(ArcaneCharge_scripts) do
		control:SetScript(k, v)
	end
end, function(control, id)
	-- onRetrieve
	control:Setup()

end, function(control)
	-- onDelete
	control:ResetVisuals()
	control:Hide()
	control:ClearAllPoints()

end, "ArcaneChargeTemplate")
