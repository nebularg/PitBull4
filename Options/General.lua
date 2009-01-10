local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

function PitBull4.Options.get_general_options()
	local options = {
		type = 'group',
		name = L["General"],
		desc = L["Options that apply to PitBull in general and/or all its unit frames."],
		args = {}
	}
	
	options.args.config_mode = PitBull4.Options.get_config_mode_options()
	PitBull4.Options.get_config_mode_options = nil
	options.args.config_mode.order = 1
	
	options.args.lock_movement = {
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
	
	return options
end
