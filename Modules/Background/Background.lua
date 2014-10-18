if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_Background requires PitBull4")
end

local PitBull4_Background = PitBull4:NewModule("Background", "AceEvent-3.0")
local L = PitBull4.L

local function model_OnUpdate(self, elapsed)
	local frame = self:GetParent()
	if not self.falling_back then
		self:SetUnit(frame.unit)
		self:SetPortraitZoom(1)
		self:SetPosition(0, 0, 0)
	else
		-- question mark or :ClearModel?
		self:SetModelScale(3)
		self:SetPosition(0, 0, 0)
		self:SetModel([[Interface\Buttons\talktomequestionmark.mdx]])
	end

	if type(self:GetModel()) == "string" then
		-- the portrait was set properly, we can stop trying to set the portrait
		self:SetScript("OnUpdate", nil)
	end
end

local guid_demanding_update = nil

PitBull4_Background:SetModuleType("custom")
PitBull4_Background:SetName(L["Background"])
PitBull4_Background:SetDescription(L["Show a flat background for your unit frames."])
PitBull4_Background:SetDefaults({
	portrait = false,
	color = { 0, 0, 0, 0.5 }
})

function PitBull4_Background:OnEnable()
	self:RegisterEvent("UNIT_PORTRAIT_UPDATE")
end

function PitBull4_Background:UNIT_PORTRAIT_UPDATE(event, unit)
	if not unit then
		return
	end

	local guid = UnitGUID(unit)
	guid_demanding_update = guid
	self:UpdateForGUID(guid)
	guid_demanding_update = nil
end

-- this is here to allow it to be overridden, by say an aggro module
function PitBull4_Background:GetColor(frame)
	return unpack(PitBull4_Background:GetLayoutDB(frame).color)
end

function PitBull4_Background:UpdateFrame(frame)
	local background = frame.Background
	if not background then
		background = PitBull4.Controls.MakeTexture(frame, "BACKGROUND")
		frame.Background = background
		background:SetAllPoints(frame)
	end
	
	background:Show()
	background:SetTexture(self:GetColor(frame))

	-- 3D Portrait
	local layout_db = self:GetLayoutDB(frame)
	if not layout_db.portrait then
		return false
	end

	local unit = frame.unit
	local falling_back = false
	if not unit or not UnitExists(unit) or not UnitIsConnected(unit) or not UnitIsVisible(unit) then
		falling_back = true
	end

	local portrait = frame.PortraitBG
	local created = not portrait
	if created then
		portrait = PitBull4.Controls.MakePlayerModel(frame)
		portrait:SetFrameLevel(frame:GetFrameLevel()) -- don't go above bars and indicators
		portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -2)
		portrait:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
		frame.PortraitBG = portrait
	end

	if portrait.guid == frame.guid and guid_demanding_update ~= frame.guid then
		portrait:Show()
		return false
	end

	portrait.falling_back = falling_back
	portrait.guid = frame.guid

	-- For 3d portraits we have to set the parameters later, doing
	-- it immediately after a model frame is created doesn't work
	-- reliably.
	portrait:SetScript("OnUpdate", model_OnUpdate)
	portrait:Show()

	return created
end

function PitBull4_Background:ClearFrame(frame)
	if frame.Background then
		frame.Background = frame.Background:Delete()
	end

	if frame.PortraitBG then
		local portrait = frame.PortraitBG
		portrait:SetScript("OnUpdate", nil)
		portrait.falling_back = nil
		portrait.guid = nil
		frame.PortraitBG = portrait:Delete()

		return true
	end

	return false
end

function PitBull4_Background:OnHide(frame)
	local background = frame.Background
	if background then
		background:Hide()
	end

	local portrait = frame.PortraitBG
	if portrait then
		portrait.guid = frame.guid
		portrait:Hide()
	end
end

PitBull4_Background:SetLayoutOptionsFunction(function(self)
	return 'color', {
		type = 'color',
		name = L["Color"],
		desc = L["Color that the background should be."],
		hasAlpha = true,
		get = function(info)
			return unpack(PitBull4.Options.GetLayoutDB(self).color)
		end,
		set = function(info, r, g, b, a)
			local color = PitBull4.Options.GetLayoutDB(self).color
			color[1], color[2], color[3], color[4] = r, g, b, a
			
			PitBull4.Options.UpdateFrames()
		end,
	}, 'portrait', {
		type = 'toggle',
		name = L["Portrait"],
		desc = L["Show a portrait of the unit."],
		get = function(info)
			return PitBull4.Options.GetLayoutDB(self).portrait
		end,
		set = function(info, value)
			PitBull4.Options.GetLayoutDB(self).portrait = value

			for frame in PitBull4:IterateFrames() do
				if self:GetLayoutDB(frame).enabled then
					self:Clear(frame)
					self:Update(frame)
				end
			end
		end,
	}
end)
