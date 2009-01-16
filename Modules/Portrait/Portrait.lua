if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local CLASS_TEX_COORDS = {
	WARRIOR     = {0, 0.25, 0, 0.25},
	MAGE        = {0.25, 0.49609375, 0, 0.25},
	ROGUE       = {0.49609375, 0.7421875, 0, 0.25},
	DRUID       = {0.7421875, 0.98828125, 0, 0.25},
	HUNTER      = {0, 0.25, 0.25, 0.5},
	SHAMAN      = {0.25, 0.49609375, 0.25, 0.5},
	PRIEST      = {0.49609375, 0.7421875, 0.25, 0.5},
	WARLOCK     = {0.7421875, 0.98828125, 0.25, 0.5},
	PALADIN     = {0, 0.25, 0.5, 0.75},
	DEATHKNIGHT = {0.25, 0.49609375, 0.5, 0.75},
}

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Portrait requires PitBull4")
end

local L = PitBull4.L

local PitBull4_Portrait = PitBull4:NewModule("Portrait", "AceEvent-3.0")

PitBull4_Portrait:SetModuleType("custom_indicator")
PitBull4_Portrait:SetName(L["Portrait"])
PitBull4_Portrait:SetDescription(L["Show a portrait of the unit."])
PitBull4_Portrait:SetDefaults({
	attach_to = "root",
	location = "out_left",
	position = 1,
	full_body = false,
	style = "three_dimensional",
	fallback_style = "three_dimensional",
	enabled = false,
})

function PitBull4_Portrait:OnEnable()
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
end

function PitBull4_Portrait:OnDisable()
end

function PitBull4_Portrait:UNIT_PORTRAIT_UPDATE(event, unit)
	self:UpdateForUnitID(unit)
end

function PitBull4_Portrait:ClearFrame(frame)
	if not frame.Portrait then
		return false
	end
	
	local portrait = frame.Portrait
	
	if portrait.model then
		portrait.model:SetScript("OnUpdate", nil)
		portrait.model = portrait.model:Delete()
	end
	if portrait.texture then
		portrait.texture = portrait.texture:Delete()
	end
	
	portrait.bg = portrait.bg:Delete()
	
	portrait.style = nil
	portrait.height = nil
	portrait.guid = nil
	portrait.falling_back = nil
	frame.Portrait = portrait:Delete()
	
	return true
end

local function model_OnUpdate(self, elapsed)
	self:SetScript("OnUpdate", nil)
	self:SetCamera(0)
end

function PitBull4_Portrait:UpdateFrame(frame)
	local layout_db = self:GetLayoutDB(frame)
	local style = layout_db.style
	local falling_back = false
	
	local unit = frame.unit
	
	if style == "class" then
		if not UnitIsPlayer(unit) then
			style = layout_db.fallback_style
			falling_back = true
		end
	else
		if not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then
			style = layout_db.fallback_style
			falling_back = true
		end
	end
	
	local portrait = frame.Portrait
	
	if portrait and (portrait.style ~= style or portrait.falling_back ~= falling_back) then
		self:ClearFrame(frame)
		portrait = nil
	end
	
	local created = not portrait
	if created then
		portrait = PitBull4.Controls.MakeFrame(frame)
		frame.Portrait = portrait
		portrait:SetWidth(60)
		portrait:SetHeight(60)
		portrait.height = 4
		portrait.style = style
		portrait.falling_back = falling_back
		
		if style == "three_dimensional" then
			local model = PitBull4.Controls.MakePlayerModel(frame)
			portrait.model = model
			model:SetAllPoints(portrait)
		else -- two_dimensional or class
			local texture = PitBull4.Controls.MakeTexture(frame, "ARTWORK")
			portrait.texture = texture
			texture:SetAllPoints(portrait)
		end
		
		local bg = PitBull4.Controls.MakeTexture(frame, "BACKGROUND")
		portrait.bg = bg
		bg:SetAllPoints(portrait)
		bg:SetTexture(0, 0, 0, 0.25)
	end
	
	if portrait.guid == frame.guid then
		return false
	end
	
	portrait.guid = frame.guid
	if style == "three_dimensional" then
		if not falling_back then
			portrait.model:SetUnit(unit)
			portrait.model:SetCamera(1)
			if not layout_db.full_body then
				portrait.model:SetScript("OnUpdate", model_OnUpdate)
			end
		else	
			portrait.model:SetModelScale(4.25)
			portrait.model:SetPosition(0, 0, -1.5)
			portrait.model:SetModel([[Interface\Buttons\talktomequestionmark.mdx]])
		end
	elseif style == "two_dimensional" then
		portrait.texture:SetTexCoord(0.14644660941, 0.85355339059, 0.14644660941, 0.85355339059)
		SetPortraitTexture(portrait.texture, unit)
	else -- class	
		local _, class = UnitClass(unit)
		if class then
			local tex_coord = CLASS_TEX_COORDS[class]
			portrait.texture:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]])
			portrait.texture:SetTexCoord(tex_coord[1], tex_coord[2], tex_coord[3], tex_coord[4])
		else
			-- Pets. Work out a better icon?
			portrait.texture:SetTexture([[Interface\Icons\Ability_Hunter_BeastCall]])
			portrait.texture:SetTexCoord(0, 1, 0, 1)
		end
	end
	
	return created
end

PitBull4_Portrait:SetLayoutOptionsFunction(function(self)
	return 'full_body', {
		type = 'toggle',
		name = L["Full body"],
		desc = L["Show the full body of the unit when in 3D mode."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).full_body
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).full_body = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end
	}, 'style', {
		type = 'select',
		name = L["Style"],
		desc = L["Set the portrait style."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).style
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).style = value
			
			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end,
		values = {
			["two_dimensional"] = L["2D"],
			["three_dimensional"] = L["3D"],
			["class"] = L["Class"],
		},
	}, 'fallback_style', {
		type = 'select',
		name = L["Fallback style"],
		desc = L["Set the portrait style for when the normal style can't be shown, such as if they are out of visibility."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).fallback_style
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).fallback_style = value

			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end,
		values = {
			["two_dimensional"] = L["2D"],
			["three_dimensional"] = L["3D question mark"],
			["class"] = L["Class"],
		},
	}
end)