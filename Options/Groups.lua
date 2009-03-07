local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_group_options()
	local group_options = {
		type = 'group',
		name = L["Groups"],
		desc = L["Change settings for unit groups."],
		args = {},
		childGroups = "tree",
	}
	
	local next_order
	do
		local current = 0
		function next_order()
			current = current + 1
			return current
		end
	end
	
	local args = {}
	
	args.enable = {
		name = L["Enable"],
		desc = L["Enable this unit group."],
		type = 'toggle',
		order = next_order(),
		get = function(info)
			local name = info[2]
			
			return PitBull4.db.profile.groups[name].enabled
		end,
		set = function(info, value)
			local name = info[2]
			
			PitBull4.db.profile.groups[name].enabled = value
			
			if value then
				PitBull4:MakeGroupHeader(name, nil)
			else
				for header in PitBull4:IterateHeadersForName(name) do
					header:Hide()
				end
			end
			
			PitBull4:RecheckConfigMode()
		end,
		disabled = function(info)
			return InCombatLockdown()
		end,
	}
	
	return group_options
end