
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_RangeFader = PitBull4:NewModule("RangeFader")

local wow_classic_era = PitBull4.wow_classic_era

local DEBUG = PitBull4.DEBUG

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

local check_method_to_dist_index = {
	inspect = 1,
	trade = 2,
	duel = 3,
	follow = 4,
}

local function add_spell(t, id)
	local spell = GetSpellInfo(id)
	if spell then
		t[#t+1] = spell
	elseif DEBUG then
		PitBull4_RangeFader:Printf("Invalid spell ID: %d", id)
	end
end

local friendly_is_in_range, pet_is_in_range, enemy_is_in_range, enemy_is_in_long_range
do
	local enemy_spells = {}
	local long_enemy_spells = {}
	local pet_spells = {}
	local friendly_spells = {}
	local res_spells = {}

	local class = UnitClassBase("player")
	if class == "DEATHKNIGHT" then
		add_spell(enemy_spells, 45524) -- Chains of Ice (20)
		add_spell(long_enemy_spells, 47541) -- Death Coil (30)
		add_spell(friendly_spells, 49016) -- Unholy Frenzy (30)
		add_spell(res_spells, 61999) -- Raise Ally (30)
	elseif class == "DRUID" then
		add_spell(enemy_spells, 8921) -- Moonfire (30)
		add_spell(friendly_spells, 8936) -- Regrowth (40)
		add_spell(res_spells, 20484) -- Rebirth (30)
	elseif class == "HUNTER" then
		if wow_classic_era then
			-- for less than 5 yards
			add_spell(enemy_spells, 3044) -- Arcane Shot (10)
		end
		add_spell(enemy_spells, 75) -- Auto Shot (5-35/35/35)
		add_spell(pet_spells, 136) -- Mend Pet (20)
		-- add_spell(pet_spells, 2641) -- Dismiss Pet (10)
	elseif class == "MAGE" then
		add_spell(enemy_spells, 118) -- Polymorph (30)
		add_spell(long_enemy_spells, 133) -- Fireball (35)
		-- add_spell(friendly_spells, 475) -- Remove Curse (40)
		add_spell(friendly_spells, 1459) -- Arcane Intellect (30)
	elseif class == "PALADIN" then
		add_spell(enemy_spells, 853) -- Hammer of Justice (10)
		add_spell(long_enemy_spells, 879) -- Exorcism (30)
		add_spell(friendly_spells, 1044) -- Hand of Freedom (30)
		add_spell(friendly_spells, 635) -- Holy Light (40)
		add_spell(res_spells, 7328) -- Redemption (30)
	elseif class == "PRIEST" then
		add_spell(enemy_spells, 585) -- Smite (30)
		add_spell(friendly_spells, 2061) -- Flash Heal (40)
		add_spell(res_spells, 2006) -- Resurrection (30)
	elseif class == "ROGUE" then
		add_spell(enemy_spells, 2094) -- Blind (10)
		add_spell(long_enemy_spells, 1725) -- Distract (30)
		if not wow_classic_era then
			add_spell(long_enemy_spells, 36554) -- Shadowstep (25)
			add_spell(friendly_spells, 57934) -- Tricks of the Trade (20)
		end
	elseif class == "SHAMAN" then
		add_spell(enemy_spells, 8042) -- Earth Shock (20/20/25)
		add_spell(long_enemy_spells, 403) -- Lightning Bolt (30)
		add_spell(friendly_spells, 1064) -- Chain Heal (40)
		add_spell(res_spells, 2008) -- Ancestral Spirit (30)
	elseif class == "WARLOCK" then
		add_spell(enemy_spells, 5782) -- Fear (20)
		add_spell(long_enemy_spells, 686) -- Shadow Bolt (30)
		add_spell(pet_spells, 755) -- Health Funnel (20/20/45)
		add_spell(friendly_spells, 5697) -- Unending Breath (30)
		add_spell(res_spells, 20707) -- Soulstone (30)
	elseif class == "WARRIOR" then
		add_spell(enemy_spells, 5246) -- Intimidating Shout (8)
		-- add_spell(enemy_spells, 1161) -- Challenging Shout (10)
		add_spell(long_enemy_spells, 355) -- Taunt (30)
		if not wow_classic_era then
			add_spell(friendly_spells, 3411) -- Intervene (8-25)
		end
	end

	function friendly_is_in_range(unit)
		if CheckInteractDistance(unit, 1) then
			return true
		end

		if UnitIsDeadOrGhost(unit) then
			for _, name in ipairs(res_spells) do
				if IsSpellInRange(name, unit) == 1 then
					return true
				end
			end

			-- Only check range for resurrection spells if the
			-- unit is dead.
			return false
		end

		for _, name in ipairs(friendly_spells) do
			if IsSpellInRange(name, unit) == 1 then
				return true
			end
		end

		return false
	end

	function pet_is_in_range(unit)
		if CheckInteractDistance(unit, 2) then
			return true
		end

		for _, name in ipairs(friendly_spells) do
			if IsSpellInRange(name, unit) == 1 then
				return true
			end
		end
		for _, name in ipairs(pet_spells) do
			if IsSpellInRange(name, unit) == 1 then
				return true
			end
		end

		return false
	end

	function enemy_is_in_range(unit)
		if CheckInteractDistance(unit, 2) then
			return true
		end

		for _, name in ipairs(enemy_spells) do
			if IsSpellInRange(name, unit) == 1 then
				return true
			end
		end

		return false
	end

	function enemy_is_in_long_range(unit)
		for _, name in ipairs(long_enemy_spells) do
			if IsSpellInRange(name, unit) == 1 then
				return true
			end
		end

		return false
	end
end

function PitBull4_RangeFader:GetOpacity(frame)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)
	local check_method = db.check_method

	if UnitIsUnit(unit, "player") then
		return 1
	end

	if check_method == "follow" or check_method == "trade" or check_method == "duel" or check_method == "follow" then
		if CheckInteractDistance(unit, check_method_to_dist_index[check_method]) then
			return 1
		else
			return db.out_of_range_opacity
		end
	elseif check_method == "custom_spell" and db.custom_spell then
		if IsSpellInRange(db.custom_spell, unit) == 1 then
			return 1
		else
			return db.out_of_range_opacity
		end
	elseif check_method == "custom_item" and db.custom_item then
		if IsItemInRange(db.custom_item, unit) == 1 then
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
			follow = L["Follow (~28 yards)"],
			trade = L["Trade (~11 yards)"],
			duel = L["Duel (~10 yards)"],
			custom_spell = L["Custom spell"],
			custom_item = L["Custom item"],
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
	}, 'custom_item', {
		type = 'input',
		name = L["Custom item"],
		desc = L["Enter the name of the item you want use to check the range with."],
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.custom_item
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)
			db.custom_item = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		hidden = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)
			return db.check_method ~= "custom_item"
		end,
	}
end)
