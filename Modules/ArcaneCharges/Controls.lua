
local PitBull4 = _G.PitBull4

local ArcaneCharge = {}
local ArcaneCharge_scripts = {}

function ArcaneCharge:Activate()
	if not self.active then
		self.active = true
		self.TurnOn:Stop()
		self.TurnOff:Stop()
		self.TurnOn:Play()
	end
end

function ArcaneCharge:Deactivate()
	if self.active then
		self.active = nil
		self.TurnOn:Stop()
		self.TurnOff:Stop()
		self.TurnOff:Play()
	end
end

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

	for k, v in pairs(ArcaneCharge) do
		control[k] = v
	end
	for k, v in pairs(ArcaneCharge_scripts) do
		control:SetScript(k, v)
	end
end, function(control, id)
	-- onRetrieve

end, function(control)
	-- onDelete

	control.active = nil
	control.TurnOn:Stop()
	control.TurnOff:Stop()
end, "ArcaneChargeTemplate")
