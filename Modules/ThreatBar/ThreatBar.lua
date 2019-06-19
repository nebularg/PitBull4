
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local ThreatLib = LibStub("Threat-2.0", true)
if not ThreatLib then
	error("PitBull4_ThreatBar requires the library Threat-2.0 to be available.")
end

local EXAMPLE_VALUE = 0.6

local PitBull4_ThreatBar = PitBull4:NewModule("ThreatBar")

PitBull4_ThreatBar:SetModuleType("bar")
PitBull4_ThreatBar:SetName(L["Threat bar"])
PitBull4_ThreatBar:SetDescription(L["Show a threat bar."])
PitBull4_ThreatBar:SetDefaults({
	size = 1,
	position = 5,
	show_solo = false,
})

local threat_colors = {
	[0] = {0.69, 0.69, 0.69}, -- not tanking, lower threat than tank.
	[1] = {1, 1, 0.47},       -- not tanking, higher threat than tank.
	[2] = {1, 0.6, 0},        -- insecurely tanking, another unit have higher threat but not tanking.
	[3] = {1, 0, 0},          -- securely tanking, highest threat
}

function PitBull4_ThreatBar:OnEnable()
	ThreatLib.RegisterCallback(self, "Activate", "UpdateAll")
	ThreatLib.RegisterCallback(self, "ThreatUpdated", "UpdateAll")
	ThreatLib.RegisterCallback(self, "ThreatCleared", "UpdateAll")
	ThreatLib.RegisterCallback(self, "Deactivate", "UpdateAll")

	self:RegisterEvent("PLAYER_TARGET_CHANGED", "UpdateAll")
	self:RegisterEvent("GROUP_ROSTER_UPDATE")
	self:RegisterUnitEvent("UNIT_PET", nil, "player")

	self:GROUP_ROSTER_UPDATE()
end

local player_in_group = false

local ACCEPTABLE_CLASSIFICATIONS = {
	player = true,
	pet = true,
	party = true,
	raid = true,
	partypet = true,
	raidpet = true,
}

local function check_classification(frame)
	local classification = frame.is_singleton and frame.unit or frame.header.unit_group
	return ACCEPTABLE_CLASSIFICATIONS[classification]
end

function PitBull4_ThreatBar:GROUP_ROSTER_UPDATE()
	player_in_group = UnitExists("pet") or IsInGroup()

	self:UpdateAll()
end

function PitBull4_ThreatBar:UNIT_PET(_, unit)
	if unit == "player" then
		self:GROUP_ROSTER_UPDATE()
	end
end

function PitBull4_ThreatBar:GetValue(frame)
	if not ThreatLib:IsActive() or not check_classification(frame) or (not self:GetLayoutDB(frame).show_solo and not player_in_group) then
		return nil
	end

	local target_guid = UnitGUID(("%starget"):format(frame.unit))
	if not target_guid then
		return nil
	end

	local max = ThreatLib:GetMaxThreatOnTarget(target_guid)
	if max == 0 then
		return 0
	end
	local current = ThreatLib:GetThreat(frame.guid, target_guid)

	return current / max
end
function PitBull4_ThreatBar:GetExampleValue(frame)
	if frame and not check_classification(frame) then
		return nil
	end
	return EXAMPLE_VALUE
end

function PitBull4_ThreatBar:GetColor(frame, value)
	if frame.guid then
		if UnitCanAttack(frame.unit, ("%starget"):format(frame.unit)) and UnitIsFriend(frame.unit, ("%stargettarget"):format(frame.unit)) then
			local target_guid = UnitGUID(target_unit)
			local tank_guid = UnitGUID(tank_unit)
			if frame.guid == tank_guid then -- tanking
				local _, max_guid = ThreatLib:GetMaxThreatOnTarget(target_guid)
				if tank_guid == max_guid then
					return unpack(threat_colors[3]) -- highest threat
				else
					return unpack(threat_colors[2]) -- not highest threat
				end
			else
				local threat = ThreatLib:GetThreat(frame.guid, target_guid)
				local tank_threat = ThreatLib:GetThreat(tank_guid, target_guid)
				if threat > tank_threat then
					return unpack(threat_colors[1]) -- higher threat than tank
				end
			end
		end
	end
	return unpack(threat_colors[0])
end
function PitBull4_ThreatBar:GetExampleColor(frame, value)
	return unpack(threat_colors[0])
end

PitBull4_ThreatBar:SetLayoutOptionsFunction(function(self)
	return "show_solo", {
		name = L["Show when solo"],
		desc = L["Show the threat bar even if you not in a group."],
		type = "toggle",
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).show_solo
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).show_solo = value
			PitBull4.Options.UpdateFrames()
		end,
	}
end)
