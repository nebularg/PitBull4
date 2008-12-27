if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_CombatIcon requires PitBull4")
end

local PitBull4_DogTagTexts = PitBull4:NewModule("DogTagTexts")

local LibDogTag

PitBull4_DogTagTexts:SetModuleType("textprovider")
PitBull4_DogTagTexts:SetName("DogTag-3.0 Texts")
PitBull4_DogTagTexts:SetDescription("Show an icon based on whether or not the unit is in combat.")
PitBull4_DogTagTexts:SetDefaults({
	texts = {
		['**'] = {
			size = 1,
			attach_to = "root",
			location = "edge_top_left",
			position = 1,
			code = "",
		},
		n = 7,
		{
			name = "Name",
			code = "[Name] [(AFK or DND):Angle]",
			attach_to = "HealthBar",
			location = "left"
		},
		{
			name = "Health",
			code = "[Status or (if IsFriend then MissingHP:Hide(0):Short:Color('ff7f7f') else FractionalHP(known=true):Short or PercentHP:Percent)]",
			attach_to = "HealthBar",
			location = "right",
		},
		{
			name = "Class",
			code = "[Classification] [Level:DifficultyColor] [(if (IsPlayer or (IsEnemy and not IsPet)) then Class):ClassColor] [DruidForm:Paren] [SmartRace]",
			attach_to = "PowerBar",
			location = "left",
		},
		{
			name = "Power",
			code = "[if HasMP then FractionalMP]",
			attach_to = "PowerBar",
			location = "right",
		},
		{
			name = "Reputation",
			code = "[if IsMouseOver then ReputationName else if ReputationName then FractionalReputation ' ' PercentReputation:Percent:Paren]",
			attach_to = "ReputationBar",
			location = "center",
		},
		{
			name = "Cast",
			code = "[Alpha((-CastStopDuration or 0) + 1) CastStopMessage or (CastName ' ' CastTarget:Paren)]",
			attach_to = "CastBar",
			location = "left",
		},
		{
			name = "Cast time",
			code = "[if not CastStopDuration then Concatenate('+', CastDelay:Round(1):Hide(0)):Red ' ' [CastEndDuration >= 0 ? '%.1f':Format(CastEndDuration)]]",
			attach_to = "CastBar",
			location = "right",
		},
	},
})

local PROVIDED_CODES = function() return {
	["Class"] = {
		["Standard"]            = "[Classification] [Level:DifficultyColor] [(if (IsPlayer or (IsEnemy and not IsPet)) then Class):ClassColor] [DruidForm:Paren] [SmartRace]",
		["Player Classes Only"] = "[Classification] [Level:DifficultyColor] [(if IsPlayer then Class):ClassColor] [DruidForm:Paren] [SmartRace]",
		["Short"]               = "[(Level (if Classification then '+')):DifficultyColor] [SmartRace]",
	},
	["Health"] = {
		["Absolute"]       = "[Status or FractionalHP(known=true) or PercentHP:Percent]",
		["Absolute Short"] = "[Status or FractionalHP(known=true):Short or PercentHP:Percent]",
		["Difference"]     = "[Status or -MissingHP:Hide(0)]",
		["Percent"]        = "[Status or PercentHP:Percent]",
		["Mini"]           = "[HP:VeryShort]",
		["Smart"]          = "[Status or (if IsFriend then MissingHP:Hide(0):Short:Color('ff7f7f') else FractionalHP(known=true):Short or PercentHP:Percent)]",
		["Absolute and Percent"]  = "[Status or (FractionalHP:Short ' || ' PercentHP:Percent)]",
		["Informational"]  = "[Status or (Concatenate((if IsFriend then MissingHP:Hide(0):Short:Color('ff7f7f')), ' || ') FractionalHP:Short ' || ' PercentHP:Percent)]",
	},
	["Name"] = {
		["Standard"]             = "[Name] [(AFK or DND):Angle]",
		["Hostility Colored"]    = "[Name:HostileColor] [(AFK or DND):Angle]",
		["Class Colored"]        = "[Name:ClassColor] [(AFK or DND):Angle]",
		["Long"]                 = "[Level] [Name:ClassColor] [(AFK or DND):Angle]",
		["Long w/ Druid form"]   = "[Level] [Name:ClassColor] [DruidForm:Paren] [(AFK or DND):Angle]",
	},
	["Power"] = {
		["Absolute"]       = "[if HasMP then FractionalMP]",
		["Absolute Short"] = "[if HasMP then FractionalMP:Short]",
		["Difference"]     = "[-MissingMP]",
		["Percent"]        = "[PercentMP:Percent]",
		["Mini"]           = "[if HasMP then CurMP:VeryShort]",
		["Smart"]          = "[MissingMP:Hide(0):Short:Color('7f7fff')]",
	},
	["Druid mana"] = {
		["Absolute"]       = "[if not IsMana then FractionalDruidMP]",
		["Absolute Short"] = "[if not IsMana then FractionalDruidMP:Short]",
		["Difference"]     = "[if not IsMana then -MissingDruidMP]",
		["Percent"]        = "[if not IsMana then PercentDruidMP:Percent]",
		["Mini"]           = "[if not IsMana then DruidMP:VeryShort]",
		["Smart"]          = "[if not IsMana then MissingDruidMP:Hide(0):Short:Color('7f7fff')]",
	},
	["Threat"] = {
		["Percent"]            = "[PercentThreat:Short:Hide(0):Percent]",
		["RawPercent"]         = "[RawPercentThreat:Short:Hide(0):Percent]",
		["Colored Percent"]    = "[PercentThreat:Short:Hide(0):Percent:ThreatStatusColor(ThreatStatus)]",
		["Colored RawPercent"] = "[RawPercentThreat:Short:Hide(0):Percent:ThreatStatusColor(ThreatStatus)]",
	},
	["Cast"] = {
		["Standard Name"] = "[Alpha((-CastStopDuration or 0) + 1) CastStopMessage or (CastName ' ' CastTarget:Paren)]",
		["Standard Time"] = "[if not CastStopDuration then Concatenate('+', CastDelay:Round(1):Hide(0)):Red ' ' [CastEndDuration >= 0 ? '%.1f':Format(CastEndDuration)]]",
	},
	["Combo points"] = {
		["Standard"]       = playerClass == "DRUID" and "[if IsEnergy(unit='player') then Combos:Hide(0)]" or "[Combos:Hide(0)]",
	},
	["Experience"] = {
		["Standard"]       = "[FractionalXP] [PercentXP:Percent:Paren] [Concatenate('R: ', PercentRestXP:Hide(0):Percent)]",
		["On Mouse-over"]       = "[if IsMouseOver then FractionalXP ' ' PercentXP:Percent:Paren ' ' Concatenate('R: ', PercentRestXP:Hide(0):Percent)]",
	},
	["Reputation"] = {
		["Standard"]       = "[if IsMouseOver then ReputationName else if ReputationName then FractionalReputation ' ' PercentReputation:Percent:Paren]"
	},
} end

local function run_first()
	LibDogTag = LibStub("LibDogTag-3.0", true)
	if not LibDogTag then
		LoadAddOn("LibDogTag-3.0")
		LibDogTag = LibStub("LibDogTag-3.0", true)
		if not LibDogTag then
			error("PitBull4_DogTagTexts requires LibDogTag-3.0 to function.")
		end
	end
	local LibDogTag_Unit = LibStub("LibDogTag-Unit-3.0", true)
	if not LibDogTag_Unit then
		LoadAddOn("LibDogTag-Unit-3.0")
		LibDogTag_Unit = LibStub("LibDogTag-Unit-3.0", true)
		if not LibDogTag_Unit then
			error("PitBull4_DogTagTexts requires LibDogTag-Unit-3.0 to function.")
		end
	end
end

local unit_kwargs = setmetatable({}, {__mode='kv', __index=function(self, unit)
	self[unit] = { unit = unit }
	return self[unit]
end})

function PitBull4_DogTagTexts:RealHandleFontString(frame, font_string, data)
	LibDogTag:AddFontString(
		font_string,
		frame,
		data.code,
		"Unit",
		unit_kwargs[frame.unit])
	return true
end

function PitBull4_DogTagTexts:HandleFontString(...)
	run_first()
	
	self.HandleFontString = self.RealHandleFontString
	self.RealHandleFontString = nil
	
	return PitBull4_DogTagTexts:HandleFontString(...)
end

function PitBull4_DogTagTexts:RemoveFontString(font_string)
	LibDogTag:RemoveFontString(frame)
end

PitBull4_DogTagTexts:SetLayoutOptionsFunction(function(self)
	local values = {}
	local value_key_to_code = {}
	values[""] = "Custom"
	value_key_to_code[""] = ""
	for base, codes in pairs(PROVIDED_CODES()) do
		for name, code in pairs(codes) do
			local key = ("%s: %s"):format(base, name)
			values[key] = key
			value_key_to_code[key] = code
		end
	end
	PROVIDED_CODES = nil
	return 'code', {
		type = 'input',
		name = "Code",
		desc = "LibDogTag-3.0 code tags",
		get = function(info)
			return LibDogTag:CleanCode(PitBull4.Options.GetTextLayoutDB().code)
		end,
		set = function(info, value)
			PitBull4.Options.GetTextLayoutDB().code = LibDogTag:CleanCode(value)
			
			PitBull4.Options.UpdateFrames()
		end,
		multiline = true,
	}, 'default_codes', {
		type = 'select',
		name = "Code",
		desc = "Some codes provided for you",
		get = function(info)
			local code = PitBull4.Options.GetTextLayoutDB().code
			for k, v in pairs(value_key_to_code) do
				if v == code then
					return k
				end
			end
			return ""
		end,
		set = function(info, value)
			PitBull4.Options.GetTextLayoutDB().code = value_key_to_code[value]
			
			PitBull4.Options.UpdateFrames()
		end,
		values = values,
	}
end)
