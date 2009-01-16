-- Options.lua : Options config

if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local _G = getfenv(0)
local PitBull4 = _G.PitBull4
local PitBull4_Aura= PitBull4:GetModule("Aura")
local L = PitBull4.L

PitBull4_Aura:SetDefaults({
	-- Layout defaults
	enabled_buffs = true,
	enabled_debuffs = true,
	enabled_weapons = true,
	buff_size = 16,
	debuff_size = 16,
	--  TODO: max_buffs and max_debuffs are set low
	--  by default since this is for all frames
	--  until we have pre-defined layouts for frames.
	max_buffs = 6,
	max_debuffs = 6,
	zoom_aura = false,
	cooldown = {
		my_buffs = true,
		my_debuffs = true,
		other_buffs = true,
		other_debuffs = true,
		weapon_buffs = true
	},
	cooldown_text = {
		my_buffs = false,
		my_debuffs = false,
		other_buffs = false,
		other_debuffs = false,
		weapon_buffs = false
	},
	border = {
		my_buffs = true,
		my_debuffs = true,
		other_buffs = true,
		other_debuffs = true,
		weapon_buffs = true
	},
	layout = {
		buff = {
			size = 16,
			anchor = "BOTTOMLEFT",
			side = "BOTTOM",
			offset_x = 0,
			offset_y = 0,
			width_type = "percent",
			width = 100,
			width_percent = 0.50,
			growth = "right_down",
			reverse = false,
			row_spacing = 0,
			col_spacing = 0,
		},
		debuff = {
			size = 16,
			anchor = "BOTTOMRIGHT",
			side = "BOTTOM",
			offset_x = 0,
			offset_y = 0,
			width_type = "percent",
			width = 100,
			width_percent = 0.50,
			growth = "left_down",
			reverse = false,
			col_spacing = 0,
			row_spacing = 0,
		},
	},
},
{
	-- Global defaults
	colors = {
		friend = {
			my = {0, 1, 0, 1},
			other = {1, 0, 0, 1}
		},
		weapon = {
			weapon = {1, 0, 0, 1},
			quality_color = true
		},
		enemy = {
			Poison = {0, 1, 0, 1},
			Magic = {0, 0, 1, 1},
			Disease = {.55, .15, 0, 1},
			Curse = {5, 0, 5, 1},
			Enrage = {1, .55, 0, 1},
			["nil"] = {1, 0, 0, 1},
		},
	},
	guess_weapon_enchant_icon = true,
})

-- tables of options for the selection options

local anchor_values = {
	TOPLEFT_TOP        = L['Top-left on top'],
	TOPRIGHT_TOP       = L['Top-right on top'],
	TOPLEFT_LEFT       = L['Top-left on left'],
	TOPRIGHT_RIGHT     = L['Top-right on right'],
	BOTTOMLEFT_BOTTOM  = L['Bottom-left on bottom'],
	BOTTOMRIGHT_BOTTOM = L['Bottom-right on bottom'],
	BOTTOMLEFT_LEFT    = L['Bottom-left on left'],
	BOTTOMRIGHT_RIGHT  = L['Bottom-right on right']
}

local growth_values = {
	left_up    = L["Left then up"],
	left_down  = L["Left then down"],
	right_up   = L["Right then up"],
	right_down = L["Right then down"], 
	up_left    = L["Up then left"], 
	up_right   = L["Up then right"], 
	down_left  = L["Down then left"], 
	down_right = L["Down then right"] 
}

local width_type_values = {
	percent = L['Percentage of side'],
	fixed   = L['Fixed size']
}

local show_when_values = {
	my_buffs = L['My own buffs'],
	my_debuffs = L['My own debuffs'],
	other_buffs = L["Others' buffs"],
	other_debuffs = L["Others' debuffs"],
	weapon_buffs = L["Weapon buffs"]
}

-- table to decide if the width option is actuually
-- representing width or height
local is_height = {
	down_right = true,
	down_left  = true,
	up_right   = true,
	up_left    = true
}

PitBull4_Aura:SetColorOptionsFunction(function(self)
	local function get(info)
		local group = info[#info - 1]
		local id = info[#info]
		return unpack(self.db.profile.global.colors[group][id])
	end
	local function set(info, r, g, b, a)
		local group = info[#info - 1]
		local id = info[#info]
		self.db.profile.global.colors[group][id] = {r, g, b, a} 
		self:UpdateAll()	
	end
	return 'friend', {
		type = 'group',
		name = L['Friendly auras'],
		inline = true,
		args = {
			my = {
				type = 'color',
				name = L['Own'],
				desc = L['Color for own buffs.'],
				get = get,
				set = set,
				order = 0
			},
			other = {
				type = 'color',
				name = L['Others'],
				desc = L["Color of others' buffs."],
				get = get,
				set = set,
				order = 1
			}
		}
	},
	'weapon', {
		type = 'group',
		name = L['Weapon auras'],
		inline = true,
		args = {
			weapon = {
				type = 'color',
				name = L['Weapon enchants'],
				desc = L['Color for temporary weapon enchants.'],
				get = get,
				set = set,
				disabled = function(info)
					return self.db.profile.global.colors.weapon.quality_color
				end,
				order = 3
			},
			quality_color = {
				type = 'toggle',
				name = L['Color by quality'],
				desc = L['Color temporary weapon enchants by weapon quality.'],
				get = function(info)
					return self.db.profile.global.colors.weapon.quality_color
				end,
				set = function(info, value)
					self.db.profile.global.colors.weapon.quality_color = value
					self:UpdateAll()
				end,
			},
		}
		
	},
	'enemy', {
		type = 'group',
		name = L['Unfriendly auras'],
		inline = true,
		args = {
			Poison = {
				type = 'color',
				name = L['Poison'],
				desc = L["Color for poison."],
				get = get, 
				set = set, 
				order = 0
			},
			Magic = {
				type = 'color',
				name = L['Magic'],
				desc = L["Color for magic."],
				get = get,
				set = set,
				order = 1
			},
			Disease = {
				type = 'color',
				name = L['Disease'],
				desc = L["Color for disease."],
				get = get,
				set = set,
				order = 2
			},
			Curse = {
				type = 'color',
				name = L['Curse'],
				desc = L["Color for curse."],
				get = get, 
				set = set, 
				order = 3
			},
			Enrage = {
				type = 'color',
				name = L['Enrage'],
				desc = L["Color for enrage."],
				get = get, 
				set = set, 
				order = 4
			},
			["nil"] = {
				type = 'color',
				name = L['Other'],
				desc = L["Color for other auras without a type."],
				get = get,
				set = sett,
				order = 5
			}
		}
	}
end)


PitBull4_Aura:SetGlobalOptionsFunction(function(self)
	return 'guess_weapon_enchant_icon', {
		type = 'toggle',
		name = L['Use spell icon'],
		desc = L['Use the spell icon for the weapon enchant rather than the icon for the weapon.'],
		get = function(info)
			return self.db.profile.global.guess_weapon_enchant_icon
		end,
		set = function(info, value)
			self.db.profile.global.guess_weapon_enchant_icon = value
			self:UpdateWeaponEnchants(true)
		end,
	}
end)

PitBull4_Aura:SetLayoutOptionsFunction(function(self)

	-- Functions for use in the options
	local function get(info)
		local id = info[#info]
		return PitBull4.Options.GetLayoutDB(self)[id]
	end
	local function set(info, value)
		local id = info[#info]
		PitBull4.Options.GetLayoutDB(self)[id] = value
		PitBull4.Options.UpdateFrames()
	end
	local function get_multi(info, key)
		local id = info[#info]
		return PitBull4.Options.GetLayoutDB(self)[id][key]
	end
	local function set_multi(info, key, value)
		local id = info[#info]
		PitBull4.Options.GetLayoutDB(self)[id][key] = value
		PitBull4.Options.UpdateFrames()
	end
	local function get_layout(info)
		local id = info[#info]
		local group = info[#info - 1]
		return PitBull4.Options.GetLayoutDB(self).layout[group][id]
	end
	local function set_layout(info, value)
		local id = info[#info]
		local group = info[#info - 1]
		PitBull4.Options.GetLayoutDB(self).layout[group][id] = value
		PitBull4.Options.UpdateFrames()
	end
	local function get_layout_anchor(info)
		local group = info[#info - 1]
		local db = PitBull4.Options.GetLayoutDB(self).layout[group]
		return db.anchor .. "_" .. db.side
	end
	local function set_layout_anchor(info, value)
		local group = info[#info - 1]
		local db = PitBull4.Options.GetLayoutDB(self).layout[group]
		db.anchor, db.side = string.match(value, "(.*)_(.*)")
		PitBull4.Options.UpdateFrames()
	end
	local function is_aura_disabled(info)
		return not PitBull4.Options.GetLayoutDB(self).enabled
	end

	-- Layout configuration.  It's used for both buffs and debuffs
	local layout = {
		type = 'group',
		name = function(info)
			local group = info[#info]
			if group == 'buff' then
				return L['Buff layout']
			else
				return L['Debuff layout']
			end
		end,
		args = {
			size = {
				type = 'range',
				name = L['Icon size'],
				desc = L['Set size of the aura icons.'],
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled, 
				min = 4,
				max = 48,
				step = 1,
				order = 0 
			},
			anchor = {
				-- Anchor option actually sets 2 values, we do the split here so we don't have to do it in a more time sensitive place
				type = 'select',
				name = L['Start at'],
				desc = L['Set the corner and side to start auras from.'],
				get = get_layout_anchor,
				set = set_layout_anchor,
				disabled = is_aura_disabled, 
				values = anchor_values,
				order = 1,
			},
			growth = {
				type = 'select',
				name = L['Growth direction'],
				desc = L['Direction that the auras will grow.'],
				get = get_layout,
				set = set_layout, 
				disabled = is_aura_disabled,
				values = growth_values,
				order = 2
			},
			offset_x = {
				type = 'range',
				name = L['Horizontal offset'],
				desc = L['Number of pixels to offset the auras from the start point horizontally.'],
				get = get_layout,
				set = set_layout, 
				disabled = is_aura_disabled, 
				min = -200,
				max = 200,
				step = 1,
				bigStep = 5,
				order = 3,
			},
			offset_y = {
				type = 'range',
				name = L['Vertical offset'],
				desc = L['Number of pixels to offset the auras from the start point vertically.'],
				get = get_layout, 
				set = set_layout, 
				disabled = is_aura_disabled, 
				min = -200,
				max = 200,
				step = 1,
				bigStep = 5,
				order = 4,
			},
			reverse = {
				type = 'toggle',
				name = L['Reverse'],
				desc = L['Reverse order in which auras are displayed.'],
				get = get_layout, 
				set = set_layout, 
				disabled = is_aura_disabled,
				order = 5,
			},
			width_type = {
				type = 'select',
				name = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Height type']
					else
						return L['Width type']
					end
				end,
				desc = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Select how to configure the height setting.']
					else
						return L['Select how to configure the width setting.']
					end
				end,
				get = get_layout,
				set = set_layout, 
				disabled = is_aura_disabled,
				values = width_type_values,
				order = 6,
			},
			width = {
				type = 'range',
				name = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Height']
					else
						return L['Width']
					end
				end,
				desc = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Set how tall the auras will be allowed to grow in pixels.']
					else
						return L['Set how wide the auras will be allowed to grow in pixels.']
					end
				end,
				get = get_layout,
				set = set_layout, 
				disabled = is_aura_disabled, 
				hidden = function(info)
					local group = info[#info - 1]
					return PitBull4.Options.GetLayoutDB(self).layout[group].width_type ~= "fixed"
				end,
				min = 20,
				max = 400,
				step = 1,
				bigStep = 5,
				order = 7,
			},
			width_percent = {
				type = 'range',
				name = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Height']
					else
						return L['Width']
					end
				end,
				desc = function(info)
					local group = info[#info - 1]
					local db = PitBull4.Options.GetLayoutDB(self).layout[group]
					if is_height[db.growth] then
						return L['Set how tall the auras will be allowed to grow as a percentage of the height of the frame they are attached to.']
					else
						return L['Set how wide the auras will be allowed to grow as a percentage of the width of the frame they are attached to.']
					end
				end,
				get = get_layout,
				set = set_layout,
				disabled = is_aura_disabled,
				hidden = function(info)
					local group = info[#info - 1]
					return PitBull4.Options.GetLayoutDB(self).layout[group].width_type ~= "percent"
				end,
				min = 0.01,
				max = 1.0,
				step = 0.01,
				isPercent = true,
				order = 8,
			},
			row_spacing = {
				type = 'range',
				name = L['Row spacing'],
				desc = L['Set the number of pixels between each row of auras.'],
				get = get_layout, 
				set = set_layout, 
				disabled = is_arua_disabled,
				min = 0,
				max = 10,
				step = 1,
				order = 9,
			},
			col_spacing = {
				type = 'range',
				name = L['Column spacing'],
				desc = L['Set the number of pixels between each column of auras.'],
				get = get_layout, 
				set = set_layout,
				disabled = is_aura_disabled,
				min = 0,
				max = 10,
				step = 1,
				order = 10,
			}
		}
	}
	return 	true, 'display', {
		type = 'group',
		name = 'Display',
		args = {
			enabled_buffs = {
				type = 'toggle',
				name = L['Buffs'],
				desc = L['Enable display of buffs.'],
				get = get,
				set = set,
				disabled = is_aura_disabled, 
				order = 0
			},
			enabled_weapons = {
				type = 'toggle',
				name = L['Weapon enchants'],
				desc = L['Enable display of temporary weapon enchants.'],
				get = function(info)
					local db = PitBull4.Options.GetLayoutDB(self)
					return db.enabled_buffs and db.enabled_weapons
				end,
				set = set,
				disabled = function(info)
					return is_aura_disabled(info) or not PitBull4.Options.GetLayoutDB(self).enabled_buffs
				end,
				order = 1
			},
			enabled_debuffs = {
				type = 'toggle',
				name = L['Debuffs'],
				desc = L['Enable display of debuffs.'],
				get = get,
				set = set,
				disabled = is_aura_disabled,
				order = 2
			},
			max = {
				type = 'group',
				name = L['Limit number of displayed auras.'],
				inline = true,
				order = 3,
				args = {
					max_buffs = {
						type = 'range',
						name = L['Buffs'],
						desc = L['Set the maximum number of buffs to display.'],
						get = get, 
						set = set, 
						disabled = is_aura_disabled,
						min = 1,
						max = 80,
						step = 1,
						order = 0 
					},
					max_debuffs = {
						type = 'range',
						name = L['Debuffs'],
						desc = L['Set the maximum number of debuffs to display.'],
						get = get,
						set = set,
						disabled = is_aura_disabled,
						min = 1,
						max = 80,
						step = 1,
						order = 1 
					},
				}
			},
			border = {
				type = 'multiselect',
				name = L['Border'],
				desc = L['Set when the border shows.'],
				values = show_when_values,
				get = get_multi,
				set = set_multi,
				disabled = is_aura_disabled,
				order = 5 
			},
			cooldown = {
				type = 'multiselect',
				name = L['Time remaining spiral'],
				desc = L['Set when the time remaining spiral shows.'],
				values = show_when_values,
				get = get_multi,
				set = set_multi,
				disabled = is_aura_disabled,
				order = 6 
			},
			cooldown_text = {
				type = 'multiselect',
				name = L['Time remaining text'],
				desc = L['Set when the time remaining text shows.'],
				values = show_when_values, 
				get = get_multi,
				set = set_multi,
				disabled = is_aura_disabled,
				order = 7 
			},
			zoom_aura = {
				type = 'toggle',
				name = L['Zoom icon'],
				desc = L['Zoom in on aura icons slightly.'],
				get = get,
				set = set,
				disabled = is_aura_disabled, 
				order = 8
			},
		}
	}, 
	'buff', layout,
	'debuff', layout
end)
