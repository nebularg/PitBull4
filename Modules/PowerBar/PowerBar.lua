
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local EXAMPLE_VALUE = 0.6
local PowerBarColor = _G.PowerBarColor

local PitBull4_PowerBar = PitBull4:NewModule("PowerBar")

PitBull4_PowerBar:SetModuleType("bar")
PitBull4_PowerBar:SetName(L["Power bar"])
PitBull4_PowerBar:SetDescription(L["Show a bar for your primary resource."])
PitBull4_PowerBar.allow_animations = true
PitBull4_PowerBar:SetDefaults({
	position = 2,
	hide_no_mana = false,
	hide_no_power = false,
	use_atlas = false,
})

local guids_to_update = {}
local frames_to_update = {}
local type_to_token = {
	"MANA", "RAGE", "FOCUS", "ENERGY", "CHI",
	"RUNES", "RUNIC_POWER", "SOUL_SHARDS", "LUNAR_POWER",
	"HOLY_POWER", "MAELSTROM", "INSANITY", "FURY", "PAIN"
}
local power_bar_atlas = {}
for power_token, info in next, PowerBarColor do
	if info.atlas then
		power_bar_atlas[power_token] = info.atlas
	end
end

local timerFrame = CreateFrame("Frame")
timerFrame:Hide()

function PitBull4_PowerBar:OnEnable()
	self:RegisterEvent("UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_MAXPOWER", "UNIT_POWER_FREQUENT")
	self:RegisterEvent("UNIT_DISPLAYPOWER")
	self:RegisterEvent("UNIT_POWER_BAR_SHOW", "UNIT_DISPLAYPOWER")
	self:RegisterEvent("UNIT_POWER_BAR_HIDE", "UNIT_DISPLAYPOWER")

	timerFrame:Show()
end

function PitBull4_PowerBar:OnDisable()
	timerFrame:Hide()
end

timerFrame:SetScript("OnUpdate", function()
	if next(frames_to_update) then
		for frame in pairs(frames_to_update) do
			PitBull4_PowerBar:Update(frame)
		end
		wipe(frames_to_update)
	end
end)

function PitBull4_PowerBar:GetValue(frame)
	local layout_db = self:GetLayoutDB(frame)
	
	if layout_db.hide_no_mana and frame.power_type ~= 0 then
		return nil
	elseif layout_db.hide_no_power and (frame.power_max or 0) <= 0 then
		return nil
	end

	-- Return cached normalized power value computed during event handling
	return frame.power_value or 0
end

function PitBull4_PowerBar:GetExampleValue(frame)
	return EXAMPLE_VALUE
end

function PitBull4_PowerBar:GetColor(frame, value)
	local unit = frame.unit
	local power_type, power_token, r, g, b = UnitPowerType(unit)
	local color = PitBull4.PowerColors[power_token]

	if not color then
		if not r then
			color = PitBull4.PowerColors[type_to_token[power_type]] or PitBull4.PowerColors.MANA
			r, g, b = color[1], color[2], color[3]
		end
	else
		r, g, b = color[1], color[2], color[3]
	end

	return r, g, b, nil, nil, self:GetLayoutDB(frame).use_atlas and power_bar_atlas[power_token]
end
function PitBull4_PowerBar:GetExampleColor(frame)
	return unpack(PitBull4.PowerColors.MANA)
end

function PitBull4_PowerBar:UNIT_POWER_FREQUENT(event, unit, power_type)
	if not unit then return end
	local _, power_token = UnitPowerType(unit)
	-- fix units that have a special power type but update as ENERGY
	if not PowerBarColor[power_token] then
		power_token = "ENERGY"
	end
	if power_token == power_type then
		for frame in PitBull4:IterateFrames() do
			if frame.unit == unit then
				self:CacheFramePowerValue(frame)
				frames_to_update[frame] = true
			end
		end
	end
end

function PitBull4_PowerBar:UNIT_DISPLAYPOWER(event, unit)
	if not unit then return end
	for frame in PitBull4:IterateFrames() do
		if frame.unit == unit then
			self:CacheFramePowerValue(frame)
			frames_to_update[frame] = true
		end
	end
end

function PitBull4_PowerBar:CacheFramePowerValue(frame)
	if not frame.unit then return end
	
	local power_type, power_token = UnitPowerType(frame.unit)
	local power_max = UnitPowerMax(frame.unit)
	local power_current = UnitPower(frame.unit)
	
	-- Cache the values for use in GetValue()
	frame.power_type = power_type
	frame.power_token = power_token
	frame.power_max = power_max
	
	-- Cache normalized value to avoid computation during frame rendering
	if power_max > 0 then
		frame.power_value = power_current / power_max
	else
		frame.power_value = 0
	end
end

PitBull4_PowerBar:SetLayoutOptionsFunction(function(self)
	local function get(info)
		return PitBull4.Options.GetLayoutDB(self)[info[#info]]
	end
	local function set(info, value)
		PitBull4.Options.GetLayoutDB(self)[info[#info]] = value
		PitBull4.Options.UpdateFrames()
	end

	return 'hide_no_mana', {
		name = L["Hide non-mana"],
		desc = L["Hides the power bar if the unit's current power is not mana."],
		type = "toggle",
		get = get,
		set = set,
	}, 'hide_no_power', {
		name = L["Hide non-power"],
		desc = L["Hides the power bar if the unit has no power."],
		type = "toggle",
		get = get,
		set = set,
	}, 'use_atlas', {
		name = L["Use power texture"],
		desc = L["Use the provided power-specific texture if available instead of the set texture."],
		type = "toggle",
		get = get,
		set = set,
	}
end)
