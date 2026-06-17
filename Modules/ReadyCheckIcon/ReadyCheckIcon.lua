
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_ReadyCheckIcon = PitBull4:NewModule("ReadyCheckIcon")

PitBull4_ReadyCheckIcon:SetModuleType("indicator")
PitBull4_ReadyCheckIcon:SetName(L["Ready check icon"])
PitBull4_ReadyCheckIcon:SetDescription(L["Show a ready check icon on the unit frame based on their response."])
PitBull4_ReadyCheckIcon:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_right",
	position = 1,
})

function PitBull4_ReadyCheckIcon:OnEnable()
	self:RegisterEvent("READY_CHECK")
	self:RegisterEvent("READY_CHECK_CONFIRM")
	self:RegisterEvent("READY_CHECK_FINISHED")
end

local status_to_texture = {
	ready = [[Interface\RAIDFRAME\ReadyCheck-Ready]],
	notready = [[Interface\RAIDFRAME\ReadyCheck-NotReady]],
	waiting = [[Interface\RAIDFRAME\ReadyCheck-Waiting]],
}

local tracked_units = {}
local unit_to_status = {}

local function SafeUnitIsUnit(unit_a, unit_b)
	if not unit_a or not unit_b then
		return false
	end

	local ok, result = pcall(UnitIsUnit, unit_a, unit_b)
	return ok and result and true or false
end

local function GetFrameUnit(frame)
	if frame.best_unit then
		return frame.best_unit
	end
	return frame.unit
end

function PitBull4_ReadyCheckIcon:GetTexture(frame)
	local frame_unit = GetFrameUnit(frame)
	if not frame_unit then
		return nil
	end

	local direct_status = GetReadyCheckStatus(frame_unit)
	if direct_status then
		return status_to_texture[direct_status]
	end

	for i = 1, #tracked_units do
		local unit = tracked_units[i]
		if SafeUnitIsUnit(frame_unit, unit) then
			return status_to_texture[unit_to_status[unit]]
		end
	end

	return nil
end

local EXAMPLE_CLASSIFICATIONS = {
	player = true,
	party = true,
	raid = true,
}
function PitBull4_ReadyCheckIcon:GetExampleTexture(frame)
	if frame.is_singleton then
		if not EXAMPLE_CLASSIFICATIONS[frame.classification] then
			return nil
		end
	elseif not EXAMPLE_CLASSIFICATIONS[frame.header.unit_group] then
		return nil
	end

	local unit = frame.unit or frame:GetName()
	local index = unit:match(".*(%d+)")
	if index then
		index = index+0
	else
		index = 0
	end
	index = index + #unit + unit:byte()

	index = index % 3

	local status
	if index == 0 then
		status = "ready"
	elseif index == 1 then
		status = "notready"
	else
		status = "waiting"
	end

	return status_to_texture[status]
end

function PitBull4_ReadyCheckIcon:CacheRaidCheckStatuses()
	wipe(unit_to_status)
	wipe(tracked_units)

	if UnitInRaid("player") then
		for i = 1, MAX_RAID_MEMBERS do
			local unit = "raid" .. i
			if UnitExists(unit) then
				tracked_units[#tracked_units + 1] = unit
				unit_to_status[unit] = GetReadyCheckStatus(unit)
			end
		end
	elseif UnitInParty("player") then
		tracked_units[1] = "player"
		unit_to_status.player = GetReadyCheckStatus("player")

		for i = 1, MAX_PARTY_MEMBERS do
			local unit = "party" .. i
			if UnitExists(unit) then
				tracked_units[#tracked_units + 1] = unit
				unit_to_status[unit] = GetReadyCheckStatus(unit)
			end
		end
	end
end

function PitBull4_ReadyCheckIcon:StartFadeOut()
	-- TODO: actually make it have a fade out effect
	self:READY_CHECK()
end

function PitBull4_ReadyCheckIcon:READY_CHECK()
	self:CacheRaidCheckStatuses()
	self:UpdateAll()
end
PitBull4_ReadyCheckIcon.READY_CHECK_CONFIRM = PitBull4_ReadyCheckIcon.READY_CHECK
function PitBull4_ReadyCheckIcon:READY_CHECK_FINISHED()
	self:ScheduleTimer("StartFadeOut", 8.5)
end
