
local PitBull4 = _G.PitBull4

-----------------------------------------------------------------------------

local SoulShard = {}
local SoulShard_scripts = {}

SoulShard.widthByFillAmount = {
	[0] = 0,
	[1] = 6,
	[2] = 12,
	[3] = 14,
	[4] = 18,
	[5] = 22,
	[6] = 22,
	[7] = 24,
	[8] = 20,
	[9] = 18,
	[10] = 0,
}

function SoulShard_scripts:OnEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(_G.SOUL_SHARDS_POWER)
	GameTooltip:AddLine(_G.SOUL_SHARDS_TOOLTIP, nil, nil, nil, true)
	GameTooltip:Show()
end

function SoulShard_scripts:OnLeave()
	GameTooltip:Hide()
end

PitBull4.Controls.MakeNewControlType("SoulShard", "Frame", function(control)
	-- onCreate
	for k, v in pairs(SoulShard) do
		control[k] = v
	end
	for k, v in pairs(SoulShard_scripts) do
		control:SetScript(k, v)
	end

end, function(control, id)
	-- onRetrieve
	control.layoutIndex = id

end, function(control)
	-- onDelete
	control:Update(0)
	control.layoutIndex = nil

end, "ShardTemplate")
