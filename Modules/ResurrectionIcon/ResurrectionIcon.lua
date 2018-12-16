
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_ResurrectionIcon = PitBull4:NewModule("ResurrectionIcon", "AceEvent-3.0")

PitBull4_ResurrectionIcon:SetModuleType("indicator")
PitBull4_ResurrectionIcon:SetName(L["Resurrection icon"])
PitBull4_ResurrectionIcon:SetDescription(L["Show an icon if there is an incoming resurrection."])
PitBull4_ResurrectionIcon:SetDefaults({
	attach_to = "root",
	location = "in_center",
	size = 2,
	position = 1,
})

function PitBull4_ResurrectionIcon:OnEnable()
	self:RegisterEvent("INCOMING_RESURRECT_CHANGED", "UpdateAll")
end


function PitBull4_ResurrectionIcon:GetTexture(frame)
	local unit = frame.unit
	if not unit or not UnitHasIncomingResurrection(unit) then
		return nil
	end

	return [[Interface\RaidFrame\Raid-Icon-Rez]]
end

function PitBull4_ResurrectionIcon:GetExampleTexture(frame)
	return [[Interface\RaidFrame\Raid-Icon-Rez]]
end
