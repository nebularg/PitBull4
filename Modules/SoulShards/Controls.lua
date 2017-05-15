
local PitBull4 = _G.PitBull4
local is_725 = _G.ClassNameplateBarWarlockShardMixin and true

-- CONSTANTS ----------------------------------------------------------------

local ICON_TEXTURE = [[Interface\AddOns\PitBull4\Modules\SoulShards\Shard]]
local SHINE_TEXTURE = [[Interface\AddOns\PitBull4\Modules\SoulShards\Shine]]

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2

local UNREADY_ALPHA = 0.6
local READY_ALPHA = 1

-----------------------------------------------------------------------------

local SoulShard = {}
local SoulShard_scripts = {}

-- Modified ClassNameplateBarWarlockShardMixin:Update to avoid having
-- to create a SoulShardContainer control with :TurnOn and :TurnOff
function SoulShard:Update(powerAmount)
	local fillAmount = min(max(powerAmount - self.shardIndex, 0), 1)
	local active = fillAmount >= 1

	if fillAmount ~= self.fillAmount then
		self.fillAmount = fillAmount

		if active then
			local alphaValue = self.ShardOn:GetAlpha()
			self.Fadein:Stop()
			self.Fadeout:Stop()
			self.ShardOn:SetAlpha(alphaValue)
			if alphaValue < 1 then
				if self.ShardOn:IsVisible() then
					self.Fadein.AlphaAnim:SetFromAlpha(alphaValue)
					self.Fadein:Play()
				else
					self.ShardOn:SetAlpha(1)
				end
			end
			self.PartialFill:SetValue(0)
		else
			local alphaValue = self.ShardOn:GetAlpha()
			self.Fadein:Stop()
			self.Fadeout:Stop()
			self.ShardOn:SetAlpha(alphaValue)
			if alphaValue > 0 then
				if self.ShardOn:IsVisible() then
					self.Fadeout.AlphaAnim:SetFromAlpha(alphaValue)
					self.Fadeout:Play()
				else
					self.ShardOn:SetAlpha(0)
				end
			end
			self.PartialFill:SetValue(fillAmount)
		end
		self:UpdateSpark(fillAmount)
	end
end

if not is_725 then
	function SoulShard:Setup(id)
		self.shardIndex = id
	end

	function SoulShard:Update(powerAmount)
		local fillAmount = min(max(powerAmount - self.shardIndex, 0), 1)
		local active = fillAmount >= 1

		if fillAmount ~= self.fillAmount then
			self.fillAmount = fillAmount
			self.shine.ag:Stop()
			self.shine:SetAlpha(0)
			if active then
				self.shine.ag:Play()
				self.texture:SetDesaturated(false)
				self.texture:SetAlpha(READY_ALPHA)
			else
				self.texture:SetDesaturated(true)
				self.texture:SetAlpha(UNREADY_ALPHA)
			end
		end
	end
end

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
	if not is_725 then
		local texture = PitBull4.Controls.MakeTexture(control, "ARTWORK")
		control.texture = texture
		texture:SetAllPoints(control)
		texture:SetTexture(ICON_TEXTURE)

		local shine = PitBull4.Controls.MakeAnimatedTexture(control, "OVERLAY")
		control.shine = shine
		shine:SetAllPoints(control)
		shine:SetTexture(SHINE_TEXTURE)
		shine:SetBlendMode("ADD")
		shine:SetVertexColor(unpack(PitBull4.PowerColors["SOUL_SHARDS"]))
		shine:SetAlpha(0)

		local fade_in = PitBull4.Controls.MakeAlpha(shine.ag)
		fade_in:SetDuration(SHINE_HALF_TIME)
		fade_in:SetFromAlpha(0)
		fade_in:SetToAlpha(1)
		fade_in:SetOrder(1)

		local fade_out = PitBull4.Controls.MakeAlpha(shine.ag)
		fade_out:SetDuration(SHINE_HALF_TIME)
		fade_out:SetFromAlpha(1)
		fade_out:SetToAlpha(0)
		fade_out:SetOrder(2)
	end

	for k, v in pairs(SoulShard) do
		control[k] = v
	end
	for k, v in pairs(SoulShard_scripts) do
		control:SetScript(k, v)
	end

end, function(control, id)
	-- onRetrieve
	control:Setup(id - 1)

end, function(control)
	-- onDelete
	control:Update(0)
	control.shardIndex = nil
	control.fillAmount = nil

end, is_725 and "ClassNameplateBarShardFrame")
