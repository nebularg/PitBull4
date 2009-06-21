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
PitBull4_Aggro:SetDescription(L["Add aggro coloring to the unit frame."])
PitBull4_Aggro:SetDefaults({
	kind = "HealthBar",
},{aggro_color = {1, 0, 0, 1}})

local PitBull4_HealthBar
local PitBull4_Border
local PitBull4_Background

local function callback(aggro, name, unit)
	for frame in PitBull4:IterateFramesForGUID(UnitGUID(unit)) do
		local db = PitBull4_Aggro:GetLayoutDB(frame)
		if db.enabled then
			if db.kind == "HealthBar" then
				if PitBull4_HealthBar then
					PitBull4_HealthBar:UpdateFrame(frame)
				end
			elseif db.kind == "Border" then
				if PitBull4_Border then
					PitBull4_Border:UpdateFrame(frame)
				end
			elseif db.kind == "Background" then
				if PitBull4_Background then
					PitBull4_Background:UpdateFrame(frame)
				end
			end
		end
	end
end

function PitBull4_Aggro:OnEnable()
	LibBanzai = LibStub("LibBanzai-2.0", true)
	if not LibBanzai then
		error(L["PitBull4_Aggro requires the library LibBanzai-2.0 to be available."])
	end

	LibBanzai:RegisterCallback(callback)
	
	PitBull4_HealthBar = PitBull4:GetModule("HealthBar", true)
	if PitBull4_HealthBar then
		self:RawHook(PitBull4_HealthBar, "GetColor", "HealthBar_GetColor")
	end
	-- TODO: set up system where the lack of HealthBar is handled sanely
	
	PitBull4_Border = PitBull4:GetModule("Border", true)
	if PitBull4_Border then
		self:RawHook(PitBull4_Border, "GetTextureAndColor", "Border_GetTextureAndColor")
	end
	-- TODO: set up system where the lack of Border is handled sanely
	
	PitBull4_Background = PitBull4:GetModule("Background", true)
	if PitBull4_Background then
		self:RawHook(PitBull4_Background, "GetColor", "Background_GetColor")
	end
	-- TODO: set up system where the lack of Border is handled sanely
end

function PitBull4_Aggro:OnDisable()
	LibBanzai:UnregisterCallback(callback)
end

function PitBull4_Aggro:HealthBar_GetColor(module, frame, value)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)
	if unit and db.enabled and db.kind == "HealthBar" and UnitIsFriend("player", unit) and LibBanzai:GetUnitAggroByUnitId(unit) then
		return unpack(self.db.profile.global.aggro_color)
	end
	
	return self.hooks[module].GetColor(module, frame, value)
end

function PitBull4_Aggro:Border_GetTextureAndColor(module, frame)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)
	
	local texture, r, g, b, a = self.hooks[module].GetTextureAndColor(module, frame)
	
	if unit and db.enabled and db.kind == "Border" and UnitIsFriend("player", unit) and LibBanzai:GetUnitAggroByUnitId(unit) then
		r, g, b, a = unpack(self.db.profile.global.aggro_color)
		if texture == "None" then
			texture = "Blizzard Tooltip"
		end
	end
	
	return texture, r, g, b, a
end

function PitBull4_Aggro:Background_GetColor(module, frame)
	local unit = frame.unit
	local db = self:GetLayoutDB(frame)
	
	local r, g, b, a = self.hooks[module].GetColor(module, frame)
	
	if unit and db.enabled and db.kind == "Background" and UnitIsFriend("player", unit) and LibBanzai:GetUnitAggroByUnitId(unit) then
		local a2
		r, g, b, a2 = unpack(self.db.profile.global.aggro_color)
		a = a * a2
	end
	
	return r, g, b, a
end

PitBull4_Aggro:SetLayoutOptionsFunction(function(self)
	return 'kind', {
		type = 'select',
		name = L["Display"],
		desc = L["How to display the aggro indication."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).kind
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).kind = value
			
			PitBull4.Options.UpdateFrames()
		end,
		values = function(info)
			local t = {}
			if PitBull4_HealthBar then
				t.HealthBar = L["Health bar"]
			end
			if PitBull4_Border then
				t.Border = L["Border"]
			end
			if PitBull4_Background then
				t.Background = L["Background"]
			end
			return t
		end
	}
end)

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
