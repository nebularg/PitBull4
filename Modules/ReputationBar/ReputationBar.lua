
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.3
local FRIENDSHIP_REACTION_MAP = {
	[1] = 1, -- Hated (Red)
	[2] = 3, -- Hostile (Orange)
	[3] = 4, -- Neutral (Yellow)
	[4] = 5, -- Friendly (Green)
}

local PitBull4_ReputationBar = PitBull4:NewModule("ReputationBar")

PitBull4_ReputationBar:SetModuleType("bar")
PitBull4_ReputationBar:SetName(L["Reputation bar"])
PitBull4_ReputationBar:SetDescription(L["Show a reputation bar."])
PitBull4_ReputationBar:SetDefaults({
	size = 1,
	position = 3,
})

function PitBull4_ReputationBar:OnEnable()
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function PitBull4_ReputationBar:PLAYER_ENTERING_WORLD()
	self:UpdateForUnitID("player")
end

function PitBull4_ReputationBar:GetValue(frame)
	if frame.unit ~= "player" then
		return nil
	end

	local name, reaction, min, max, value, faction_id
	if GetWatchedFactionInfo then
		name, reaction, min, max, value, faction_id = GetWatchedFactionInfo()
	else -- XXX wow_tww
		local watchedFactionData = C_Reputation.GetWatchedFactionData()
		if watchedFactionData then
			name = watchedFactionData.name
			reaction =  watchedFactionData.reaction
			min = watchedFactionData.currentReactionThreshold
			max = watchedFactionData.nextReactionThreshold
			value = watchedFactionData.currentStanding
			faction_id = watchedFactionData.factionID
		end
	end
	if not name or faction_id == 0 then
		return nil
	end

	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		local rep_info = C_GossipInfo.GetFriendshipReputation(faction_id)
		local friendship_id = rep_info.friendshipFactionID

		if C_Reputation.IsFactionParagon(faction_id) then
			local paragon_value, threshold, _, has_reward = C_Reputation.GetFactionParagonInfo(faction_id)
			min, max = 0, threshold
			value = paragon_value % threshold
			if has_reward then
				value = value + threshold
			end
		elseif C_Reputation.IsMajorFaction(faction_id) then
			local faction_info = C_MajorFactions.GetMajorFactionData(faction_id)
			min, max = 0, faction_info.renownLevelThreshold
		elseif friendship_id > 0 then
			if rep_info.nextThreshold then
				min, max, value = rep_info.reactionThreshold, rep_info.nextThreshold, rep_info.standing
			else -- max rank: show a full bar
				min, max, value = 0, 1, 1
			end
		elseif reaction == 8 then -- max rank: show a full bar
			min, max, value = 0, 1, 1
		end
	end

	-- Normalize values
	max = max - min
	value = value - min
	min = 0
	if max == 0 then
		return 0
	end
	return (value - min) / max
end
function PitBull4_ReputationBar:GetExampleValue(frame)
	if frame and frame.unit ~= "player" then
		return nil
	end
	return EXAMPLE_VALUE
end

function PitBull4_ReputationBar:GetColor(frame, value)
	local reaction, faction_id, _
	if GetWatchedFactionInfo then
		_, reaction, _, _, _, faction_id = GetWatchedFactionInfo()
	else -- XXX wow_tww
		local watchedFactionData = C_Reputation.GetWatchedFactionData()
		if watchedFactionData then
			reaction =  watchedFactionData.reaction
			faction_id = watchedFactionData.factionID
		end
	end

	if ClassicExpansionAtLeast(LE_EXPANSION_MISTS_OF_PANDARIA) then
		local rep_info = faction_id and C_GossipInfo.GetFriendshipReputation(faction_id)
		if C_Reputation.IsFactionParagon(faction_id) then
			reaction = "paragon"
		elseif rep_info and rep_info.friendshipFactionID > 0 then
			-- span the distinct reaction colors across however many ranks
			local color_index = rep_info.overrideColor
			if not color_index then
				local rank_info = C_GossipInfo.GetFriendshipReputationRanks(rep_info.friendshipFactionID)
				local num_colors = #FRIENDSHIP_REACTION_MAP
				color_index = _G.NPCFriendshipStatusBarMixin:GetColorIndex(rank_info.currentLevel, rank_info.maxLevel, num_colors)
				if rep_info.reversedColor then
					color_index = (num_colors + 1) - color_index
				end
			end
			reaction = FRIENDSHIP_REACTION_MAP[color_index]
		end
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

do
	local function Update()
		if PitBull4_ReputationBar:IsEnabled() and IsPlayerInWorld() then
			for frame in PitBull4:IterateFramesForUnitID("player") do
				local layout_db = PitBull4_ReputationBar:GetLayoutDB(frame)
				if layout_db then -- make sure we're initialized
					PitBull4_ReputationBar:Update(frame)
				end
			end
		end
	end
	if _G.MainMenuBar_UpdateExperienceBars then -- removed in Shadowlands
		hooksecurefunc("MainMenuBar_UpdateExperienceBars", Update)
	else
		hooksecurefunc(StatusTrackingBarManager, "UpdateBarsShown", Update)
	end
end
