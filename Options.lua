local _G = _G
local PitBull4 = _G.PitBull4

local AceConfig = LibStub and LibStub("AceConfig-3.0", true)
if not AceConfig then
	LoadAddOn("Ace3")
	AceConfig = LibStub and LibStub("AceConfig-3.0", true)
	if not LibSimpleOptions then
		message(("PitBull4 requires the library %q and will not work without it."):format("AceConfig-3.0"))
		error(("PitBull4 requires the library %q and will not work without it."):format("AceConfig-3.0"))
	end
end
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local OpenConfig

AceConfig:RegisterOptionsTable("PitBull4_Bliz", {
	name = "PitBull Unit Frames 4.0",
	handler = PitBull4,
	type = 'group',
	args = {
		config = {
			name = "Standalone config",
			desc = "Open a standlone config window, allowing you to actually configure PitBull Unit Frames 4.0.",
			type = 'execute',
			func = function()
				OpenConfig()
			end
		}
	},
})
AceConfigDialog:AddToBlizOptions("PitBull4_Bliz", "PitBull Unit Frames 4.0")

do
	for i, cmd in ipairs { "/PitBull4", "/PitBull", "/PB4", "/PB", "/PBUF", "/Pit" } do
		_G["SLASH_PITBULLFOUR" .. (i*2 - 1)] = cmd
		_G["SLASH_PITBULLFOUR" .. (i*2)] = cmd:lower()
	end

	_G.hash_SlashCmdList["PITBULLFOUR"] = nil
	_G.SlashCmdList["PITBULLFOUR"] = function()
		return OpenConfig()
	end
end

function OpenConfig()
	-- redefine it so that we just open up the pane next time
	function OpenConfig()
		AceConfigDialog:Open("PitBull4")
	end
	
	local options = {
		name = "PitBull",
		handler = PitBull4,
		type = 'group',
		args = {
		},
	}

	local CURRENT_LAYOUT = "Normal"
	
	local function getLayoutDB()
		return PitBull4.db.layouts[CURRENT_LAYOUT]
	end
	
	local function updateFrames()
		PitBull4.UpdateForLayout(CURRENT_LAYOUT)
	end

	local layout_options = {
		type = 'group',
		name = "Layout editor",
		args = {},
		childGroups = "tab",
	}
	options.args.layout_options = layout_options

	layout_options.args.current_layout = {
		name = "Current layout",
		type = 'select',
		order = 1,
		values = function(info)
			local t = {}
			t["Normal"] = "Normal"
			return t
		end,
		get = function(info)
			return CURRENT_LAYOUT
		end,
		set = function(info, value)
			CURRENT_LAYOUT = value
		end
	}

	layout_options.args.bars = {
		name = "Bars",
		type = 'group',
		childGroups = "tab",
		args = {}
	}

	layout_options.args.icons = {
		name = "Icons",
		type = 'group',
		args = {}
	}

	layout_options.args.texts = {
		name = "Texts",
		type = 'group',
		args = {}
	}

	layout_options.args.other = {
		name = "Other",
		type = 'group',
		args = {}
	}
	
	for id, module in PitBull4.IterateModulesOfType("statusbar") do
		layout_options.args.bars.args[id] = {
			name = module.name,
			desc = module.description,
			type = 'group',
			args = {
				enable = {
					type = 'toggle',
					name = "Enable",
					order = 1,
					get = function(info)
						return not getLayoutDB()[info[3]].hidden
					end,
					set = function(info, value)
						local db = getLayoutDB()[info[3]]
						db.hidden = not value
						
						updateFrames()
					end
				},
				side = {
					type = 'select',
					name = "Side",
					order = 2,
					get = function(info)
						return getLayoutDB()[info[3]].side
					end,
					set = function(info, value)
						local db = getLayoutDB()[info[3]]
						db.side = value

						updateFrames()
					end,
					values = {
						center = "Center",
						left = "Left",
						right = "Right",
					}
				},
				position = {
					type = 'select',
					name = "Position",
					order = 3,
					values = function(info)
						local db = getLayoutDB()
						local side = db[info[3]].side
						local t = {}
						for other_id, other_module in PitBull4.IterateModulesOfType("statusbar", true) do
							if side == db[other_id].side then
								local position = db[other_id].position
								while t[position] do
									position = position + 1e-5
									db[other_id].position = position
								end
								t[position] = other_module.name
							end
						end
						return t
					end,
					get = function(info)
						local id = info[3]
						return getLayoutDB()[id].position
					end,
					set = function(info, new_position)
						local db = getLayoutDB()
						local id = info[3]
						
						local id_to_position = {}
						local bars = {}
						
						local old_position = db[id].position
						
						for other_id, other_module in PitBull4.IterateModulesOfType("statusbar", false) do
							local other_position = db[other_id].position
							if other_id == id then
								other_position = new_position
							elseif other_position >= old_position and other_position <= new_position then
								other_position = other_position - 1
							elseif other_position <= old_position and other_position >= new_position then
								other_position = other_position + 1
							end
							
							id_to_position[other_id] = other_position
							bars[#bars+1] = other_id
						end
						
						table.sort(bars, function(alpha, bravo)
							return id_to_position[alpha] < id_to_position[bravo]
						end)
						
						for position, bar_id in ipairs(bars) do
							db[bar_id].position = position
						end
						
						updateFrames()
					end
				},
				size = {
					type = 'range',
					name = function(info)
						if getLayoutDB()[info[3]].side == "center" then
							return "Height"
						else
							return "Width"
						end
					end,
					order = 4,
					get = function(info)
						return getLayoutDB()[info[3]].size
					end,
					set = function(info, value)
						local db = getLayoutDB()[info[3]]
						db.size = value

						updateFrames()
					end,
					min = 1,
					max = 12,
					step = 1,
				},
				deficit = {
					type = 'toggle',
					name = "Deficit",
					desc = "Drain the bar instead of filling it.",
					order = 5,
					get = function(info)
						return getLayoutDB()[info[3]].deficit
					end,
					set = function(info, value)
						local db = getLayoutDB()[info[3]]
						db.deficit = value

						updateFrames()
					end,
				},
				reverse = {
					type = 'toggle',
					name = "Reverse",
					desc = "Reverse the direction of the bar, filling from right-to-left instead of left-to-right",
					order = 6,
					get = function(info)
						return getLayoutDB()[info[3]].reverse
					end,
					set = function(info, value)
						local db = getLayoutDB()[info[3]]
						db.reverse = value

						updateFrames()
					end,
				},
				alpha = {
					type = 'range',
					name = "Full opacity",
					order = 7,
					get = function(info)
						return getLayoutDB()[info[3]].alpha
					end,
					set = function(info, value)
						local db = getLayoutDB()[info[3]]
						db.alpha = value

						updateFrames()
					end,
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.05,
					isPercent = true,
				},
				bgAlpha = {
					type = 'range',
					name = "Empty opacity",
					order = 8,
					get = function(info)
						return getLayoutDB()[info[3]].bgAlpha
					end,
					set = function(info, value)
						local db = getLayoutDB()[info[3]]
						db.bgAlpha = value

						updateFrames()
					end,
					min = 0,
					max = 1,
					step = 0.01,
					bigStep = 0.05,
					isPercent = true,
				},
			}
		}
	end
	
	AceConfig:RegisterOptionsTable("PitBull4", options)
	
	return OpenConfig()
end

function print(...) Rock("LibRockConsole-1.0"):PrintLiteral(...) end