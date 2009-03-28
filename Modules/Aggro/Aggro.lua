if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
  error("PitBull4_Aggro requires PitBull4")
end
local L = PitBull4.L

local LibBanzai

local PitBull4_Aggro = PitBull4:NewModule("Aggro", "AceEvent-3.0", "AceHook-3.0")
PitBull4_Aggro:SetModuleType("custom")
PitBull4_Aggro:SetName(L["Aggro"])
PitBull4_Aggro:SetDescription(L["Adds aggro coloring to PitBull4"])
PitBull4_Aggro:SetDefaults({},{aggro_color = {1, 0, 0, 1}})
PitBull4_Aggro:SetLayoutOptionsFunction(function(self) end)

local PitBull4_HealthBar

local function callback(aggro, name, unit)
	for frame in PitBull4:IterateFramesForGUID(UnitGUID(unit)) do
		if frame and PitBull4_Aggro:GetLayoutDB(frame).enabled then
			PitBull4_HealthBar:UpdateFrame(frame)
		end
	end
end

function PitBull4_Aggro:OnEnable()
	PitBull4_HealthBar = PitBull4:GetModule("HealthBar", true)
	if not PitBull4_HealthBar then
		error(L["PitBull4_Aggro requires the HealthBar module"])
	end
	
	LibBanzai = LibStub("LibBanzai-2.0", true)
	if not LibBanzai then
		error(L["PitBull4_Aggro requires the library LibBanzai-2.0 to be available."])
	end

	LibBanzai:RegisterCallback(callback)
	self:RawHook(PitBull4_HealthBar, "GetColor")
end

function PitBull4_Aggro:OnDisable()
	LibBanzai:UnregisterCallback(callback)
end

function PitBull4_Aggro:GetColor(module, frame, value)
	local unit = frame.unit
	if unit and self:GetLayoutDB(frame).enabled and UnitIsFriend("player", unit) and LibBanzai:GetUnitAggroByUnitId(unit) then
		return unpack(self.db.profile.global.aggro_color)
	end
	
	return self.hooks[module].GetColor(module, frame, value)
end

PitBull4_Aggro:SetColorOptionsFunction(function(self)
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
