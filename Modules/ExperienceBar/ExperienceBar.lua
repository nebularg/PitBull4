if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_ExperienceBar requires PitBull4")
end

local L = PitBull4.L

local PitBull4_ExperienceBar = PitBull4:NewModule("ExperienceBar", "AceEvent-3.0")

PitBull4_ExperienceBar:SetModuleType("bar")
PitBull4_ExperienceBar:SetName(L["Experience bar"])
PitBull4_ExperienceBar:SetDescription(L["Show an experience bar."])
PitBull4_ExperienceBar:SetDefaults({
	size = 1,
	position = 4,
})

function PitBull4_ExperienceBar:OnEnable()
	self:RegisterEvent("PLAYER_XP_UPDATE")
	self:RegisterEvent("UPDATE_EXHAUSTION")
	self:RegisterEvent("PLAYER_LEVEL_UP")
end

function PitBull4_ExperienceBar:GetValue(frame)
	local unit = frame.unit
	if unit ~= "player" and unit ~= "pet" then
		return nil
	end
	
	local level = UnitLevel(unit)
	local current, max, rest
	if unit == "player" then
		if level == MAX_PLAYER_LEVEL then
			return nil
		end
		
		current, max = UnitXP("player"), UnitXPMax("player")
		rest = GetXPExhaustion() 
		if rest == nil then
		    rest = 0
		end
		
	else -- pet
		if level == UnitLevel("player") then
			return nil
		end
		
		current, max = GetPetExperience()
		rest = 0
	end
	
	if max == 0 then
		current = 0
		max = 1
	end
	
	return current / max, rest / max
end
function PitBull4_ExperienceBar:GetExampleValue(frame)
	return 0.25
end

function PitBull4_ExperienceBar:GetColor(frame, value)
	return 0, 0, 1
end
PitBull4_ExperienceBar.GetExampleColor = PitBull4_ExperienceBar.GetColor

function PitBull4_ExperienceBar:GetExtraColor(frame, value)
	return 1, 0, 1
end
PitBull4_ExperienceBar.GetExampleExtraColor = PitBull4_ExperienceBar.GetExtraColor

function PitBull4_ExperienceBar:PLAYER_XP_UPDATE()
	-- Funky update mechanism to deal with the creation and removal
	-- of the bar depending on circumstances.  If the bar doesn't already
	-- exist we need to force the entire frame to be updated to create it
	-- and if the bar does exist we can just update our own frame, but
	-- if we end up removing it from our update we then have to force
	-- a full frame update.
	for frame in PitBull4:IterateFramesForUnitID("player", "pet") do
		if not frame.ExperienceBar then
			frame:Update()
		else
			self:Update(frame)
			if not frame.ExperienceBar then
				frame:Update()
			end
		end
	end
end

PitBull4_ExperienceBar.UPDATE_EXHAUSTION = PitBull4_ExperienceBar.PLAYER_XP_UPDATE
PitBull4_ExperienceBar.PLAYER_LEVEL_UP = PitBull4_ExperienceBar.PLAYER_XP_UPDATE
