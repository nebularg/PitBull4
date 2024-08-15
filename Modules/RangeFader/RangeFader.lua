
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local wow_cata = PitBull4.wow_cata
local GetSpellName = C_Spell.GetSpellName or _G.GetSpellInfo -- XXX wow_tww
local IsSpellInRange = C_Spell.IsSpellInRange or _G.IsSpellInRange -- XXX wow_tww

local PitBull4_RangeFader = PitBull4:NewModule("RangeFader")

PitBull4_RangeFader:SetModuleType("fader")
PitBull4_RangeFader:SetName(L["Range fader"])
PitBull4_RangeFader:SetDescription(L["Make the unit frame fade if out of range."])
PitBull4_RangeFader:SetDefaults({
	enabled = false,
	out_of_range_opacity = 0.6,
	check_method = "class",
})

function PitBull4_RangeFader:OnEnable()
	self:ScheduleRepeatingTimer("UpdateNonWacky", 0.7)
end

local enemy_spells = {}
local long_enemy_spells = {}
local pet_spells = {}
local friendly_spells = {}
local res_spells = {}

local function add_spell(t, id)
	local spell = GetSpellName(id)
	if spell then
		t[#t + 1] = spell
	elseif PitBull4.DEBUG then
		PitBull4_RangeFader:Printf("Invalid spell ID: %d", id)
	end
end

if wow_cata then
	local class = UnitClassBase("player")
	if class == "DEATHKNIGHT" then
		add_spell(enemy_spells, 45524)   -- Chains of Ice (20)
		add_spell(long_enemy_spells, 47541) -- Death Coil (30)
		add_spell(friendly_spells, 49016) -- Unholy Frenzy (30)
		add_spell(res_spells, 61999)     -- Raise Ally (30)
	elseif class == "DRUID" then
		add_spell(enemy_spells, 8921)    -- Moonfire (30)
		add_spell(friendly_spells, 8936) -- Regrowth (40)
		add_spell(res_spells, 20484)     -- Rebirth (30)
	elseif class == "HUNTER" then
		add_spell(enemy_spells, 75)      -- Auto Shot (5-35/35/35)
		add_spell(pet_spells, 136)       -- Mend Pet (20)
		-- add_spell(pet_spells, 2641) -- Dismiss Pet (10)
	elseif class == "MAGE" then
		add_spell(enemy_spells, 118)     -- Polymorph (30)
		add_spell(long_enemy_spells, 133) -- Fireball (35)
		-- add_spell(friendly_spells, 475) -- Remove Curse (40)
		add_spell(friendly_spells, 1459) -- Arcane Intellect (30)
	elseif class == "PALADIN" then
		add_spell(enemy_spells, 853)     -- Hammer of Justice (10)
		add_spell(long_enemy_spells, 879) -- Exorcism (30)
		add_spell(friendly_spells, 1044) -- Hand of Freedom (30)
		add_spell(friendly_spells, 635)  -- Holy Light (40)
		add_spell(res_spells, 7328)      -- Redemption (30)
	elseif class == "PRIEST" then
		add_spell(enemy_spells, 585)     -- Smite (30)
		add_spell(friendly_spells, 2061) -- Flash Heal (40)
		add_spell(res_spells, 2006)      -- Resurrection (30)
	elseif class == "ROGUE" then
		add_spell(enemy_spells, 2094)    -- Blind (10)
		add_spell(long_enemy_spells, 1725) -- Distract (30)
		add_spell(long_enemy_spells, 36554) -- Shadowstep (25)
		add_spell(friendly_spells, 57934) -- Tricks of the Trade (20)
	elseif class == "SHAMAN" then
		add_spell(enemy_spells, 8042)    -- Earth Shock (20/20/25)
		add_spell(long_enemy_spells, 403) -- Lightning Bolt (30)
		add_spell(friendly_spells, 1064) -- Chain Heal (40)
		add_spell(res_spells, 2008)      -- Ancestral Spirit (30)
	elseif class == "WARLOCK" then
		add_spell(enemy_spells, 5782)    -- Fear (20)
		add_spell(long_enemy_spells, 686) -- Shadow Bolt (30)
		add_spell(pet_spells, 755)       -- Health Funnel (20/20/45)
		add_spell(friendly_spells, 5697) -- Unending Breath (30)
		add_spell(res_spells, 20707)     -- Soulstone (30)
	elseif class == "WARRIOR" then
		add_spell(enemy_spells, 5246)    -- Intimidating Shout (8)
		-- add_spell(enemy_spells, 1161) -- Challenging Shout (10)
		add_spell(long_enemy_spells, 355) -- Taunt (30)
		add_spell(friendly_spells, 3411) -- Intervene (8-25)
	end
else
	local class = UnitClassBase("player")
	if class == "DEATHKNIGHT" then
		add_spell(enemy_spells, 47541)    -- Death Coil (30)
		add_spell(res_spells, 61999)      -- Raise Ally
	elseif class == "DEMONHUNTER" then
		add_spell(enemy_spells, 344862)   -- Chaos Strike (Melee)
		add_spell(long_enemy_spells, 185245) -- Torment (30)
	elseif class == "DRUID" then
		add_spell(enemy_spells, 5176)     -- Wrath (40)
		add_spell(friendly_spells, 8936)  -- Regrowth
		add_spell(res_spells, 50769)      -- Revive
	elseif class == "EVOKER" then
		add_spell(enemy_spells, 361469)   -- Living Flame (25)
		add_spell(friendly_spells, 355913) -- Emerald Blossom (25)
		add_spell(res_spells, 361227)     -- Return
	elseif class == "HUNTER" then
		add_spell(enemy_spells, 185358)   -- Arcane Shot (40)
		add_spell(pet_spells, 136)        -- Mend Pet
	elseif class == "MAGE" then
		-- add_spell(enemy_spells, 118) -- Polymorph (35)
		add_spell(enemy_spells, 116)      -- Frostbolt (40)
		add_spell(friendly_spells, 130)   -- Slow Fall
	elseif class == "MONK" then
		add_spell(enemy_spells, 115546)   -- Provoke (30)
		add_spell(long_enemy_spells, 117952) -- Crackling Jade Lightning (40)
		add_spell(friendly_spells, 116670) -- Vivify
		add_spell(res_spells, 115178)     -- Resuscitate
	elseif class == "PALADIN" then
		add_spell(enemy_spells, 62124)    -- Hand of Reckoning (30)
		add_spell(friendly_spells, 1044)  -- Hand of Freedom
		add_spell(res_spells, 7328)       -- Redemption
	elseif class == "PRIEST" then
		-- add_spell(enemy_spells, 528) -- Dispel Magic (30)
		add_spell(enemy_spells, 585)   -- Smite (40)
		add_spell(friendly_spells, 2061) -- Flash Heal
		add_spell(res_spells, 2006)    -- Resurrection
	elseif class == "ROGUE" then
		add_spell(enemy_spells, 185763) -- Pistol Shot (20 - Outlaw)
		add_spell(enemy_spells, 36554) -- Shadowstep (25)
		add_spell(enemy_spells, 1752)  -- Sinister Strike (Melee)
		add_spell(friendly_spells, 57934) -- Tricks of the Trade
	elseif class == "SHAMAN" then
		-- add_spell(enemy_spells, 57994) -- Wind Shear (30)
		add_spell(enemy_spells, 188196) -- Lightning Bolt (40)
		add_spell(friendly_spells, 8004) -- Healing Surge
		add_spell(res_spells, 2008)   -- Ancestral Spirit
	elseif class == "WARLOCK" then
		-- add_spell(enemy_spells, 5782) -- Fear (35)
		add_spell(enemy_spells, 686)   -- Shadow Bolt (40)
		add_spell(pet_spells, 755)     -- Health Funnel
		add_spell(friendly_spells, 5697) -- Unending Breath
		add_spell(res_spells, 20707)   -- Soulstone
	elseif class == "WARRIOR" then
		add_spell(enemy_spells, 100)   -- Charge (8-25)
		add_spell(enemy_spells, 1464)  -- Slam (Melee)
		add_spell(long_enemy_spells, 355) -- Taunt (30)
		add_spell(friendly_spells, 3411) -- Intervene
	end
end

local function friendly_is_in_range(unit)
	if UnitIsDeadOrGhost(unit) then
		for _, name in ipairs(res_spells) do
			if IsSpellInRange(name, unit) then
				return true
			end
		end

		-- Only check range for resurrection spells if the unit is dead.
		return false
	end

	for _, name in ipairs(friendly_spells) do
		if IsSpellInRange(name, unit) then
			return true
		end
	end

	return false
end

local function pet_is_in_range(unit)
	for _, name in ipairs(friendly_spells) do
		if IsSpellInRange(name, unit) then
			return true
		end
	end
	for _, name in ipairs(pet_spells) do
		if IsSpellInRange(name, unit) then
			return true
		end
	end

	return false
end

local function enemy_is_in_range(unit)
	if CheckInteractDistance(unit, 2) then
		return true
	end

	for _, name in ipairs(enemy_spells) do
		if IsSpellInRange(name, unit) then
			return true
		end
	end

	return false
end

local function enemy_is_in_long_range(unit)
	for _, name in ipairs(long_enemy_spells) do
		if IsSpellInRange(name, unit) then
			return true
		end
	end

	return false
end

function PitBull4_RangeFader:GetOpacity(frame)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)
	local check_method = db.check_method

	if UnitIsUnit(unit, "player") then
		return 1
	end

	if check_method == "custom_spell" and db.custom_spell then
		if IsSpellInRange(db.custom_spell, unit) then
			return 1
		else
			return db.out_of_range_opacity
		end
	elseif check_method == "helpful" then
		if UnitInRange(unit) then
			return 1
		else
			return db.out_of_range_opacity
		end
	elseif check_method == "visible" then
		if UnitIsVisible(unit) then
			return 1
		else
			return db.out_of_range_opacity
		end
	else -- class
		if UnitCanAttack("player", unit) then
			if enemy_is_in_range(unit) then
				return 1
			elseif enemy_is_in_long_range(unit) then
				return (db.out_of_range_opacity + frame.layout_db.opacity_max) / 2
			else
				return db.out_of_range_opacity
			end
		elseif UnitInRange(unit) then
			return 1
		elseif UnitIsUnit(unit, "pet") then
			if pet_is_in_range(unit) then
				return 1
			else
				return db.out_of_range_opacity
			end
		else
			if friendly_is_in_range(unit) then
				return 1
			else
				return db.out_of_range_opacity
			end
		end
	end
end

PitBull4_RangeFader:SetLayoutOptionsFunction(function(self)
	local get_spell_range
	local range_pattern = _G.SPELL_RANGE:gsub("%%s", ".-")
	if not wow_cata then
		function get_spell_range(spell_id)
			local data = C_TooltipInfo.GetSpellByID(spell_id, true)
			if not data then return end

			for _, line in next, data.lines do
				if line.type == 0 then
					if line.leftText and line.leftText:find(range_pattern) then
						return line.leftText
					elseif line.rightText and line.rightText:find(range_pattern) then
						return line.rightText
					end
				end
			end
			return _G.SPELL_RANGE:format("??")
		end
	else
		local tooltip = CreateFrame("GameTooltip", "PitBull4RangeFinderTooltip", nil, "GameTooltipTemplate")
		tooltip:SetOwner(UIParent, "ANCHOR_NONE")
		function get_spell_range(spell_id)
			tooltip:SetSpellByID(spell_id)
			for i = 1, tooltip:NumLines(), 1 do
				local text = _G["PitBull4RangeFinderTooltipTextLeft" .. i]:GetText()
				if text and text:find(range_pattern) then
					return text
				end
				text = _G["PitBull4RangeFinderTooltipTextRight" .. i]:GetText()
				if text and text:find(range_pattern) then
					return text
				end
			end
			return _G.SPELL_RANGE:format("??")
		end
	end

	local function get_spell_info(spell)
		-- XXX wow_tww
		local spell_id, icon, _
		if _G.GetSpellInfo then
			_, _, icon, _, _, _, spell_id = _G.GetSpellInfo(spell)
		else
			icon = C_Spell.GetSpellTexture(spell)
			spell_id = C_Spell.GetSpellIDForSpellIdentifier(spell)
		end
		return spell_id, icon
	end

	return 'out_of_range', {
		type = 'range',
		name = L["Out-of-range opacity"],
		desc = L["The opacity to display if the player is out of range of the unit."],
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.out_of_range_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.out_of_range_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}, 'check_method', {
		type = 'select',
		name = L["Range check method"],
		desc = L["Choose the method to determine if the unit is in range."],
		values = {
			helpful = L["Helpful spells (~40 yards)"],
			class = L["Class abilities"],
			custom_spell = L["Custom spell"],
			visible = L["Visible (~100 yards)"],
		},
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.check_method
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.check_method = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		width = 'double',
	}, 'class_spell_info', {
		type = "description",
		name = function(info)
			local desc = ""
			-- spells are the name, so they should only return info if known (hopefully similar to IsSpellInRange >.>)
			for _, spell in ipairs(enemy_spells) do
				local spell_id, icon = get_spell_info(spell)
				if spell_id then
					desc = desc .. ("%s: |T%s:16|t|cff71d5ff[%s]|h|r (%s)\n"):format(L["Hostile"], icon, spell, get_spell_range(spell_id))
					break
				end
			end
			for _, spell in ipairs(long_enemy_spells) do
				local spell_id, icon = get_spell_info(spell)
				if spell_id then
					desc = desc .. ("%s: |T%s:16|t|cff71d5ff[%s]|h|r (%s)\n"):format(L["Hostile, Long-range"], icon, spell, get_spell_range(spell_id))
					break
				end
			end
			for _, spell in ipairs(friendly_spells) do
				local spell_id, icon = get_spell_info(spell)
				if spell_id then
					desc = desc .. ("%s: |T%s:16|t|cff71d5ff[%s]|h|r (%s)\n"):format(L["Friendly"], icon, spell, get_spell_range(spell_id))
					break
				end
			end
			for _, spell in ipairs(pet_spells) do
				local spell_id, icon = get_spell_info(spell)
				if spell_id then
					desc = desc .. ("%s: |T%s:16|t|cff71d5ff[%s]|h|r (%s)\n"):format(L["Pet"], icon, spell, get_spell_range(spell_id))
					break
				end
			end
			return desc
		end,
		width = "full",
		hidden = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return not db.enabled or db.check_method ~= "class"
		end,
	}, 'custom_spell', {
		type = 'input',
		name = L["Custom spell"],
		desc = L["Enter the name of the spell you want use to check the range with."],
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.custom_spell
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.custom_spell = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		hidden = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.check_method ~= "custom_spell"
		end,
	}
end)
