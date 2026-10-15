local _, namespace = ...
local Compat = namespace.Compat
local SpecProfiles = {}
namespace.SpecProfiles = SpecProfiles

local Controller = {}
Controller.__index = Controller
local saved_namespace = "LibDualSpec-1.0"
local in_combat = InCombatLockdown
local seasons = C_Seasons
local specs = C_SpecializationInfo or {}
local get_class = UnitClass
local get_class_base = UnitClassBase
local get_count = specs.GetNumSpecializationsForClassID or GetNumSpecializationsForClassID
local get_info = specs.GetSpecializationInfoForClassID or GetSpecializationInfoForClassID
local get_player_count = specs.GetNumSpecializations or GetNumSpecializations
local get_player_info = specs.GetSpecializationInfo or GetSpecializationInfo
local can_use_talents = specs.CanPlayerUseTalentSpecUI

local function readable_number(value)
	return Compat.IsValueAccessible(value) and type(value) == "number" and value >= 0
end

function Controller:UpdateSpecializations()
	if not Compat.UsesSpecializations then
		self.count = 2
		self.names[1] = TALENT_SPEC_PRIMARY or "Primary"
		self.names[2] = TALENT_SPEC_SECONDARY or "Secondary"
		return
	end
	local class_id
	if get_class_base then
		local _
		_, class_id = get_class_base("player")
	elseif get_class then
		local _
		_, _, class_id = get_class("player")
	end
	local count
	if get_count and readable_number(class_id) then
		count = get_count(class_id)
	elseif get_player_count then
		count = get_player_count()
	end
	self.count = readable_number(count) and math.floor(count) or 0
	for index = 1, self.count do
		local name
		if get_info and readable_number(class_id) then
			local _
			_, name = get_info(class_id, index)
		elseif get_player_info then
			local _
			_, name = get_player_info(index)
		end
		self.names[index] = Compat.IsValueAccessible(name) and type(name) == "string"
			and name or self.addon.L["Specialization %d"]:format(index)
	end
end

function Controller:IsEnabled()
	return self.current > 0 and self.settings.enabled == true
end

function Controller:GetProfile(index)
	return self.settings[index or self.current] or self.db:GetCurrentProfile()
end

function Controller:Apply()
	if not self:IsEnabled() then
		self.pending = nil
		return
	end
	if in_combat and in_combat() then
		self.pending = true
		return
	end
	self.pending = nil
	local profile = self:GetProfile()
	if type(profile) == "string" and profile ~= self.db:GetCurrentProfile() then
		self.db:SetProfile(profile)
	end
end

function Controller:Refresh()
	local previous_count = self.count
	self:UpdateSpecializations()
	local current = self.get_current()
	if not readable_number(current) or current < 1 or current > self.count
		or current ~= math.floor(current) then
		current = 0
	end
	if can_use_talents then
		local usable = can_use_talents()
		if not Compat.IsValueAccessible(usable) or usable ~= true then
			current = 0
		end
	end
	self.current = current
	if self.options and previous_count ~= self.count then
		self:EnhanceOptions(self.options)
	end
	-- Reuse the original saved namespace without loading or changing its library.
	if current > 0 and type(self.settings.profile) == "string" then
		for index = 1, self.count do
			self.settings[index] = index == current and self.db:GetCurrentProfile()
				or self.settings.profile
		end
		self.settings.profile = nil
		self.settings.specGroup = nil
	end
	self:Apply()
	if self.OnChanged then
		self:OnChanged()
	end
end

function Controller:SetEnabled(enabled)
	enabled = enabled == true
	self.settings.enabled = enabled
	local profile = self.db:GetCurrentProfile()
	for index = 1, self.count do
		self.settings[index] = enabled and (self.settings[index] or profile) or nil
	end
	self:Apply()
end

function Controller:SetProfile(profile, index)
	index = index or self.current
	if type(profile) ~= "string" or profile == "" or not readable_number(index)
		or index < 1 or index > self.count or index ~= math.floor(index) then
		return
	end
	self.settings[index] = profile
	self:Apply()
end

function Controller:OnDatabaseReset(_, database)
	if database ~= self.db then return end
	local store = database:GetNamespace(saved_namespace, true)
		or database:RegisterNamespace(saved_namespace)
	self.settings = store.char
	self:Refresh()
end

function Controller:OnProfileDeleted(_, database, profile)
	if database ~= self.db then return end
	for index = 1, self.count do
		if self.settings[index] == profile then
			self.settings[index] = database:GetCurrentProfile()
		end
	end
end

function Controller:EnhanceOptions(options)
	local L = self.addon.L
	local args = options.args
	if self.options ~= options then
		self.options = options
		local old_choose_disabled = args.choose.disabled
		args.choose.disabled = function(info)
			if (in_combat and in_combat()) or self:IsEnabled() then return true end
			if type(old_choose_disabled) == "function" then return old_choose_disabled(info) end
			if type(old_choose_disabled) == "string" then
				return options.handler[old_choose_disabled](options.handler, info)
			end
			return old_choose_disabled
		end
		args.new.set = function(_, profile)
			if self:IsEnabled() then
				self:SetProfile(profile)
			else
				self.db:SetProfile(profile)
			end
		end
		args.spec_profiles_enabled = {
			type = "toggle", order = 41, width = "full", descStyle = "inline",
			name = L["Enable spec profiles"],
			desc = L["When enabled, your profile changes with your specialization."],
			get = function() return self:IsEnabled() end,
			set = function(_, enabled) self:SetEnabled(enabled) end,
			disabled = function() return self.current == 0 or (in_combat and in_combat()) end,
		}
	end
	for key in pairs(args) do
		local index = type(key) == "string" and tonumber(key:match("^specProfile(%d+)$"))
		if index and index > self.count then args[key] = nil end
	end
	for index = 1, self.count do
		local spec_index = index
		args["specProfile" .. index] = {
			type = "select", order = 42 + index, values = "ListProfiles", arg = "common",
			name = function()
				local name = self.names[spec_index]
				return self.current == spec_index and L["%s - Active"]:format(name) or name
			end,
			get = function() return self:GetProfile(spec_index) end,
			set = function(_, profile) self:SetProfile(profile, spec_index) end,
			disabled = function() return not self:IsEnabled() or (in_combat and in_combat()) end,
		}
	end
end

function SpecProfiles.Attach(addon, database)
	if Compat.IsEra then
		local active = seasons and seasons.GetActiveSeason and seasons.GetActiveSeason()
		if active ~= 2 and active ~= 11 and active ~= 12 then return end
	end
	local getter
	if Compat.UsesSpecializations then getter = Compat.GetSpecialization
	else getter = Compat.GetActiveSpecGroup end
	if type(getter) ~= "function" then return end
	local store = database:GetNamespace(saved_namespace, true)
		or database:RegisterNamespace(saved_namespace)
	local self = setmetatable({
		addon = addon, db = database, settings = store.char,
		get_current = getter, current = 0, count = 0, names = {},
	}, Controller)
	database.RegisterCallback(self, "OnDatabaseReset")
	database.RegisterCallback(self, "OnProfileDeleted")
	local frame = CreateFrame("Frame")
	self.frame = frame
	frame:SetScript("OnEvent", function(_, event, unit)
		if event == "PLAYER_SPECIALIZATION_CHANGED" and unit ~= "player" then return end
		self:Refresh()
	end)
	frame:RegisterEvent("PLAYER_ENTERING_WORLD")
	frame:RegisterEvent("PLAYER_REGEN_ENABLED")
	local event = Compat.UsesSpecializations and "PLAYER_SPECIALIZATION_CHANGED"
		or "ACTIVE_TALENT_GROUP_CHANGED"
	if Compat.IsEventValid(event) then
		if Compat.UsesSpecializations then
			frame:RegisterUnitEvent(event, "player")
		else
			frame:RegisterEvent(event)
		end
	end
	if Compat.IsEventValid("PLAYER_LEVEL_CHANGED") then
		frame:RegisterEvent("PLAYER_LEVEL_CHANGED")
	end
	self:Refresh()
	return self
end
