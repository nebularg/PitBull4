
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_SummonIcon = PitBull4:NewModule("SummonIcon", "AceEvent-3.0")

PitBull4_SummonIcon:SetModuleType("indicator")
PitBull4_SummonIcon:SetName(L["Summon icon"])
PitBull4_SummonIcon:SetDescription(L["Show an icon if there is an incoming or pending summon."])
PitBull4_SummonIcon:SetDefaults({
	attach_to = "root",
	location = "in_center",
	size = 2,
	position = 1,
})

function PitBull4_SummonIcon:OnEnable()
	self:RegisterEvent("INCOMING_SUMMON_CHANGED", "UpdateAll")
end


function PitBull4_SummonIcon:GetTexture(frame)
	local unit = frame.unit
	if not unit or not C_IncomingSummon.HasIncomingSummon(unit) then
		return nil
	end

	return [[Interface\RaidFrame\RaidFrameSummon]]
end

function PitBull4_SummonIcon:GetTexCoord(frame)
	local unit = frame.unit
	if not unit or not C_IncomingSummon.HasIncomingSummon(unit) then
		return nil
	end

	local status = C_IncomingSummon.IncomingSummonStatus(unit)
	if status == 1 then -- pending
		return 0.539062, 0.789062, 0.015625, 0.515625
	elseif status == 2 then -- accepted
		return 0.0078125, 0.257812, 0.015625, 0.515625
	elseif status == 3 then -- declined
		return 0.273438, 0.523438, 0.015625, 0.515625
	end
end

function PitBull4_SummonIcon:GetExampleTexture(frame)
	return [[Interface\RaidFrame\RaidFrameSummon]]
end

function PitBull4_SummonIcon:GetExampleTexCoord(frame)
	return 0.539062, 0.789062, 0.015625, 0.515625
end
