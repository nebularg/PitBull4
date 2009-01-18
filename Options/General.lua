local _G = _G
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LDB and LibStub("LibDBIcon-1.0", true)

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
		'minimapicon', {
			type = 'toggle',
			name = L["Minimap icon"],
			desc = L["Show a minimap icon"],
			get = function(info)
				return not PitBull4.db.profile.minimapicon.hide
			end,
			set = function(info, value)
				PitBull4.db.profile.minimapicon.hide = not value
				if LDBIcon and not IsAddOnLoaded("Broker2FuBar") then
					if value then LDBIcon:Show("PitBull4") else LDBIcon:Hide("PitBull4") end
				end
			end,
			hidden = function() return not LDBIcon or IsAddOnLoaded("Broker2FuBar") end,
		}
end
