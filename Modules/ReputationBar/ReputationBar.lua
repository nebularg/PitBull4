if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ReputationBar requires PitBull4")
end

local EXAMPLE_VALUE = 0.3

local L = PitBull4.L

local PitBull4_ReputationBar = PitBull4:NewModule("ReputationBar")

PitBull4_ReputationBar:SetModuleType("bar")
PitBull4_ReputationBar:SetName(L["Reputation bar"])
PitBull4_ReputationBar:SetDescription(L["Show a reputation bar."])
PitBull4_ReputationBar:SetDefaults({
	size = 1,
	position = 3,
})

function PitBull4_ReputationBar:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end
	
	local name, _, min, max, value, id = GetWatchedFactionInfo()
	if not name then
		return nil
	end
	-- Rather than doing the sane thing Blizzard had to invent a new system that makes things overly complex
	-- Apparently something was wrong with using the existing min, max, values
	local fs_id, fs_rep, _, _, _, _, _, fs_threshold, next_fs_threshold = GetFriendshipReputation(id)
	if fs_id then
		if next_fs_threshold then
			min, max, value = fs_threshold, next_fs_threshold, fs_rep
		else
			-- max rank, make it look like a full bar
			min, max, value = 0, 1, 1
		end
	end
	-- Normalize values
	max = max - min
	value = value - min
	min = 0
	local y = max - min
	if y == 0 then
		return 0
	end
	return (value - min) / y
end
function PitBull4_ReputationBar:GetExampleValue(frame)
	if frame and frame.unit ~= "player" then
		return nil
	end
	return EXAMPLE_VALUE
end

function PitBull4_ReputationBar:GetColor(frame, value)
	local _, reaction, _, _, _, id = GetWatchedFactionInfo()
	if GetFriendshipReputation(id) then
		reaction = 5 -- always color friendships "green"
	end
	local color = PitBull4.ReactionColors[reaction]
	if color then
		return color[1], color[2], color[3]
	end
end
function PitBull4_ReputationBar:GetExampleColor(frame)
	local color = PitBull4.ReactionColors[5]
	return color[1], color[2], color[3]
end

hooksecurefunc("ReputationWatchBar_Update", function()
	if not PitBull4_ReputationBar:IsEnabled() then
		return
	end
	for frame in PitBull4:IterateFramesForUnitID("player") do
		PitBull4_ReputationBar:Update(frame)
	end
end)
