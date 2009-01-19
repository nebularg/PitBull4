local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_general_options()
	local config_mode = PitBull4.Options.get_config_mode_options()
	PitBull4.Options.get_config_mode_options = nil
	
	return
		'config_mode', config_mode, 
		'lock_movement', {
		type = 'toggle',
		name = L["Lock frames"],
		desc = L["Lock the frames so they cannot be accidentally moved."],
		get = function(info)
			return PitBull4.db.profile.lock_movement
		end,
		set = function(info, value)
			PitBull4.db.profile.lock_movement = value
		end,
	}
end
