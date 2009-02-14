if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
  error("PitBull4_Banzai requires PitBull4")
end
local L = PitBull4.L

local PitBull4_HealthBar = PitBull4:GetModule("HealthBar", true)
if not PitBull4_HealthBar then
	error(L["PitBull4_Banzai requires the HealthBar module"])
end

local banzai

local PitBull4_Banzai = PitBull4:NewModule("Banzai", "AceEvent-3.0", "AceHook-3.0")
PitBull4_Banzai:SetModuleType("custom")
PitBull4_Banzai:SetName(L["Banzai"])
PitBull4_Banzai:SetDescription(L["Adds aggro coloring to PitBull4"])
PitBull4_Banzai:SetDefaults({},{aggro_color = {1, 0, 0, 1}})
PitBull4_Banzai:SetLayoutOptionsFunction(function(self) end)

local function callback(aggro, name, unit)
	for frame in PitBull4:IterateFramesForGUID(UnitGUID(unit)) do
		if frame and PitBull4_Banzai:GetLayoutDB(frame).enabled then
			PitBull4_HealthBar:UpdateFrame(frame)
		end
	end
end

function PitBull4_Banzai:OnEnable()
	banzai = LibStub("LibBanzai-2.0")
	if not banzai then
		error(L["PitBull4_Banzai requires the library LIbBanzai-2.0 to be available."])
	end

	banzai:RegisterCallback(callback)
	self:RawHook(PitBull4_HealthBar, "GetColor")
end

function PitBull4_Banzai:OnDisable()
	banzai:UnregisterCallback(callback)
end

function PitBull4_Banzai:GetColor(module, frame, value)
	local unit = frame.unit
	local HealthBar = frame.HealthBar
	if not HealthBar or (unit and not UnitIsFriend("player",unit)) then
		if not value then
			value = HealthBar and HealthBar.value or 0
		end
		return self.hooks[module].GetColor(module, frame, value)
	end
	local db = self:GetLayoutDB(frame)
	if db.enabled then
		local aggro = banzai:GetUnitAggroByUnitId(unit)
		if aggro then
			return unpack(self.db.profile.global.aggro_color)
		end
	end
	if not value then
		value = HealthBar and HealthBar.value or 0
	end
	return self.hooks[module].GetColor(module, frame, value)
end

PitBull4_Banzai:SetColorOptionsFunction(function(self)
	return 'aggro_color', {
		type = 'color',
		name = L['Aggro'],
		desc = L['Sets which color to use on the health bar of units that have aggro.'],
		get = function(info)
			return unpack(self.db.profile.global.aggro_color)
		end,
		set = function(info, r, g, b, a)
			self.db.profile.global.aggro_color = {r, g, b, a}
			self:UpdateAll()
		end,
	},
	function(info)
		self.db.profile.global.aggro_color = {1, 0, 0, 1}
	end
end)
