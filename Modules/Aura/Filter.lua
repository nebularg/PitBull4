-- Filter.lua : Code to handle Filtering the Auras.

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _g = getfenv(0)
local PitBull4 = _G.PitBull4
local PitBull4_Aura = PitBull4:GetModule("Aura")

local _,player_class = UnitClass('player')
local can_dispel

-- Return true if the talent matching the name of the spell given by
-- spellid has at least one point spent in it or nil otherwise
local function scan_for_known_talent(spellid) 
	local wanted_name = GetSpellInfo(spellid)
	if not wanted_name then return nil end
	local num_tabs = GetNumTalentTabs()
	for t=1, num_tabs do
		local num_talents = GetNumTalents(t)
		for i=1, num_talents do
			local name_talent, _, _, _, current_rank = GetTalentInfo(t,i)
			if name_talent and (name_talent == wanted_name) then
				if current_rank and (current_rank > 0) then
					return true
				else
					return nil
				end
			end
		end
	end
	return nil
end

-- Handle CHARACTER_POINTS_CHANGED events.  If the points aren't changed
-- due to leveling, rescan the talents for the relevent talents that change
-- what we can dispel.
function PitBull4_Aura:CHARACTER_POINTS_CHANGED(event, count, levels)
	if levels > 0 then return end -- Not interested in gained points from leveling
	can_dispel['Curse'] = scan_for_known_talent(51886)
end

if player_class == 'DEATHKNIGHT' then
elseif player_class == 'DRUID' then
	can_dispel = {
		Curse = true,
		Poison = true,
	}
elseif player_class == 'HUNTER' then
	can_dispel = {
		Magic = true,
		Enrage = true,
	}
elseif player_class == 'MAGE' then
	can_dispel = {
		Curse = true,
	}
elseif player_class == 'PALADIN' then
	can_dispel = {
		Magic = true,
		Poison = true,
		Disease = true,
	}
elseif player_class == 'PRIEST' then
	can_dispel = {
		Magic = true,
		Disease = true,
	}
elseif player_class == 'ROGUE' then
	can_dispel = {
		Enrage = true,
	}
elseif player_class == 'SHAMAN' then
	can_dispel = {
		Poison = true,
		Disease = true,
		Curse = scan_for_known_talent(51886),
	}
elseif player_class == 'WARLOCK' then
	can_dispel = {
		Magic = true
	}
elseif player_class == 'WARRIOR' then
	can_dispel = {
		Magic = true
	}
end

if not can_dispel then
	can_dispel = {}
end
PitBull4_Aura.can_dispel = can_dispel
