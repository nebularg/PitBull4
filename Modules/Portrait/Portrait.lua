
local PitBull4 = _G.PitBull4
local L = PitBull4.L

local CLASS_TEX_COORDS = {}
for k, v in pairs(_G.CLASS_ICON_TCOORDS) do
	-- zoom by 14%
	local left, right, top, bottom = unpack(v)
	left, right = left + (right - left) * 0.07, right - (right - left) * 0.07
	top, bottom = top + (bottom - top) * 0.07, bottom - (bottom - top) * 0.07
	CLASS_TEX_COORDS[k] = { left, right, top, bottom }
end

local PitBull4_Portrait = PitBull4:NewModule("Portrait")

local pirate_day, pirate_costumes
do
	local month = tonumber(date("%m"))
	local day = tonumber(date("%d"))
	if month == 9 and day == 19 then
		pirate_day = true
		pirate_costumes = {
			{ 2955, 6795, 9636, 6835, 6836, 3935 }, -- white
			{ 2955, 5202, 9636, 45848, 14174, 45848 }, -- orange
			{ 11735, 9782, 6795, 138419, 78259, 7282, 9776, 90030 }, -- eyepatch
			{ 2955, 6795, 9636, 6835, 6836, 3935 }, -- white
		}
	else
		pirate_day = nil
	end
end

PitBull4_Portrait:SetModuleType("indicator")
PitBull4_Portrait:SetName(L["Portrait"])
PitBull4_Portrait:SetDescription(L["Show a portrait of the unit."])
PitBull4_Portrait:SetDefaults({
	color = { 0, 0, 0, 0.25 },
	attach_to = "root",
	location = "out_left",
	position = 1,
	full_body = false,
	camera_distance = 1,
	style = "three_dimensional",
	fallback_style = "three_dimensional",
	side = "left",
	bar_size = 4,
	enabled = false,
}, {
	pirate = true
})
PitBull4_Portrait.can_set_side_to_center = true

function PitBull4_Portrait:OnEnable()
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
	-- self:RegisterEvent("UNIT_MODEL_CHANGED", "UNIT_PORTRAIT_UPDATE")
	if not pirate_day then
		-- Clear it so it turns on every pirate day and doesn't forever
		-- chew up a spot in the config file
		self.db.profile.global.pirate = nil
	end
end

local guid_demanding_update = nil

function PitBull4_Portrait:UNIT_PORTRAIT_UPDATE(event, unit)
	if not unit then return end
	local guid = UnitGUID(unit)
	guid_demanding_update = guid
	self:UpdateForGUID(guid)
	guid_demanding_update = nil
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
	portrait.full_body = nil
	frame.Portrait = portrait:Delete()

	return true
end

function PitBull4_Portrait:OnHide(frame)
	local portrait = frame.Portrait
	if portrait then
		portrait.guid = frame.guid
		if portrait.bg then
			portrait.bg:Hide()
		end
		portrait:Hide()
	end
end

local function portrait_OnModelLoaded(model)
	model:SetScript("OnUpdate", nil)

	-- >.> semi-persistent random costumes!
	local guid = UnitGUID(model:GetParent().unit or "")
	local id = guid and tostring(tonumber(select(3, strsplit("-", guid)), 16)):sub(-1)
	local costume = id and (math.floor(id / 3) + 1) or math.random(1, 4)

	model:Undress()
	for _,  item in next, pirate_costumes[costume] do
		model:TryOn(("item:%d"):format(item))
	end
end

function PitBull4_Portrait:UpdateFrame(frame)
	local layout_db = self:GetLayoutDB(frame)
	local style = layout_db.style
	local pirate = pirate_day and self.db.profile.global.pirate and not InCombatLockdown()
	local falling_back = false

	local unit = frame.unit

	if style == "class" then
		if not unit or not UnitIsPlayer(unit) then
			style = layout_db.fallback_style
			falling_back = true
		end
	else
		if not unit or (not UnitExists(unit) and not ShowBossFrameWhenUninteractable(unit)) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then
			style = layout_db.fallback_style
			falling_back = true
		end
	end

	if style == "hide" then
		return self:ClearFrame(frame)
	end

	if pirate and style == "three_dimensional" and not falling_back and UnitIsPlayer(unit) then
		style = "pirate"
	end

	local portrait = frame.Portrait

	if portrait and portrait.style ~= style then
		self:ClearFrame(frame)
		portrait = nil
	end

	local created = not portrait
	if created then
		portrait = PitBull4.Controls.MakeFrame(frame)
		frame.Portrait = portrait
		portrait:SetFrameLevel(frame:GetFrameLevel() + 5)
		portrait:SetWidth(60)
		portrait:SetHeight(60)
		portrait.height = 4
		portrait.style = style

		if style == "three_dimensional" then
			local model = PitBull4.Controls.MakePlayerModel(frame)
			model:SetFrameLevel(frame:GetFrameLevel() + 5)
			model:SetAllPoints(portrait)
			portrait.model = model
		elseif style == "pirate" then
			local model = PitBull4.Controls.MakeDressUpModel(frame)
			model:SetFrameLevel(frame:GetFrameLevel() + 5)
			model:SetAllPoints(portrait)
			portrait.model = model
		else -- two_dimensional or class
			local texture = PitBull4.Controls.MakeTexture(portrait, "ARTWORK")
			portrait.texture = texture
			texture:SetAllPoints(portrait)
		end

		local bg = PitBull4.Controls.MakeTexture(frame, "BACKGROUND")
		portrait.bg = bg
		bg:SetAllPoints(portrait)
		bg:SetColorTexture(unpack(layout_db.color))
	end

	if portrait.guid == frame.guid and guid_demanding_update ~= frame.guid then
		if portrait.bg then
			portrait.bg:Show()
		end
		portrait:Show()
		return false
	end

	local full_body = layout_db.full_body
	portrait.full_body = full_body
	portrait.guid = frame.guid
	if style == "three_dimensional" then
		portrait.model:ClearModel()
		if not falling_back then
			portrait.model:SetUnit(frame.unit)
			portrait.model:SetPortraitZoom(full_body and 0 or 1)
			portrait.model:SetPosition(0, 0, 0)
			portrait.model:SetCamDistanceScale(layout_db.camera_distance)
		else
			portrait.model:SetModelScale(1) -- the scale gets screwed up if not reset before SetModel
			portrait.model:SetModel([[Interface\Buttons\talktomequestionmark.mdx]])
			portrait.model:SetModelScale(3)
			portrait.model:SetPosition(0, 0, -0.15)
		end
	elseif style == "pirate" then
		portrait.model:ClearModel()
		portrait.model:SetUnit(frame.unit)
		portrait.model:SetScript("OnUpdate", portrait_OnModelLoaded)
		portrait.model:SetPortraitZoom(full_body and 0 or 1)
		portrait.model:SetPosition(0, 0, 0)
		portrait.model:SetCamDistanceScale(layout_db.camera_distance)
	elseif style == "two_dimensional" then
		portrait.texture:SetTexCoord(0.14644660941, 0.85355339059, 0.14644660941, 0.85355339059)
		if unit then
			SetPortraitTexture(portrait.texture, unit)
		else
			-- No unit so just use a blank portrait
			portrait.texture:SetTexture("")
		end
	elseif style == "blank" then
		portrait.texture:SetTexture("")
	else -- class
		local class, _
		if unit then
			_, class = UnitClass(unit)
		end
		if class then
			local tex_coord = CLASS_TEX_COORDS[class]
			portrait.texture:SetTexture([[Interface\Glues\CharacterCreate\UI-CharacterCreate-Classes]])
			portrait.texture:SetTexCoord(unpack(tex_coord))
		else
			-- Pets. Work out a better icon?
			portrait.texture:SetTexture([[Interface\Icons\Ability_Hunter_BeastCall]])
			portrait.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end
	end

	if portrait.bg then
		portrait.bg:Show()
	end
	portrait:Show()

	return created
end

if pirate_day then
	PitBull4_Portrait:SetGlobalOptionsFunction(function(self)
		return 'pirate', {
			type = "select",
			name = L["Pirate"],
			desc = L["Happy International Talk Like a Pirate Day!"],
			get = function(info)
				return self.db.profile.global.pirate and "pirate" or "~normal"
			end,
			set = function(info, value)
				self.db.profile.global.pirate = value == "pirate"
				self:UpdateAll()
			end,
			values = {
				["pirate"] = L["Yaaarrr"],
				["~normal"] = L["Land lubber"], -- ~ to force it after pirate
			},
		}
	end)
end


PitBull4_Portrait:SetLayoutOptionsFunction(function(self)
	return 'color', {
		type = 'color',
		name = L["Background color"],
		desc = L["Color that the background behind the portrait should be."],
		hasAlpha = true,
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).color
			color[1], color[2], color[3], color[4] = r, g, b, a

			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end,
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
			["blank"] = L["Blank"],
			["hide"] = L["Hide completely"],
		},
	}, 'camera_distance', {
		type = 'range', min = 0.5, softMax = 10, step = 0.1,
		name = L["Camera distance"],
		desc = L["Set the camera distance when in 3D mode."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).camera_distance
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).camera_distance = value

			for frame in PitBull4:IterateFrames() do
				self:Clear(frame)
			end
			self:UpdateAll()
		end,
		disabled = function(info)
			return PitBull4.Options.GetLayoutDB(self).style ~= "three_dimensional"
		end,
	}, 'full_body', {
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
		end,
		disabled = function(info)
			return PitBull4.Options.GetLayoutDB(self).style ~= "three_dimensional"
		end,
	}
end)
