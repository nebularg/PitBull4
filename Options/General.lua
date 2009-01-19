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
		},
		'minimap_icon', {
			type = 'toggle',
			name = L["Minimap icon"],
			desc = L["Show an icon on the minimap to open the PitBull config."],
			get = function(info)
				return not PitBull4.db.profile.minimap_icon.hide
			end,
			set = function(info, value)
				PitBull4.db.profile.minimap_icon.hide = not value
				
				if value then
					LibStub("LibDBIcon-1.0"):Show("PitBull4")
				else
					LibStub("LibDBIcon-1.0"):Hide("PitBull4")
				end
			end,
			hidden = function()
				return not LibStub("LibDataBroker-1.1", true) or not LibStub("LibDBIcon-1.0", true) or IsAddOnLoaded("Broker2FuBar")
			end,
		}
end
