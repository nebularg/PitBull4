
local PitBull4 = _G.PitBull4

-----------------------------------------------------------------------------

local Essence = {}
local Essence_scripts = {}

function Essence_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G.POWER_TYPE_ESSENCE)
	GameTooltip:AddLine(_G.ESSENCE_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

function Essence_scripts:OnLeave()
	GameTooltip:Hide()
end

PitBull4.Controls.MakeNewControlType("EssenceIcon", "Frame", function(control)
	-- onCreate
	for k, v in pairs(Essence) do
		control[k] = v
	end
	for k, v in pairs(Essence_scripts) do
		control:SetScript(k, v)
	end

end, function(control, id)
	-- onRetrieve
	control.layoutIndex = id

end, function(control)
	-- onDelete
	control.layoutIndex = nil

end, "EssencePointButtonTemplate")
