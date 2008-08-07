local _G = _G
local PitBull4 = _G.PitBull4
local PitBull4_Controls = {}
PitBull4.Controls = PitBull4_Controls

local cache = {}

local function frame_Delete(self)
	local kind = self:GetObjectType()
	
	if kind == "FontString" then
		self:SetText("")
		self:SetJustifyH("CENTER")
		self:SetJustifyV("MIDDLE")
		self:SetNonSpaceWrap(true)
		self:SetTextColor(1, 1, 1, 1)
		self:SetFontObject(nil)
	elseif kind == "Texture" then
		self:SetTexture([[Interface\Buttons\WHITE8X8]])
		self:SetVertexColor(0, 0, 0, 0)
		self:SetBlendMode("BLEND")
		self:SetDesaturated(false)
		self:SetTexCoord(0, 1, 0, 1)
		self:SetTexCoordModifiesRect(false)
	elseif kind == "StatusBar" then
		self:SetStatusBarColor(1, 1, 1, 1)
		self:SetStatusBarTexture(nil)
		self:SetValue(1)
		self:SetOrientation("HORIZONTAL")
	elseif kind == "Cooldown" then
		self:SetReverse(false)
	end
	
	--[[
	if kind ~= "Texture" and kind ~= "FontString" and not _G.OmniCC and customKind == kind and _G.UnitClassBase then
		if self:GetNumRegions() > 0 then
			error(("Deleting a frame of type %q that still has %d regions"):format(kind, self:GetNumRegions()), 2)
		elseif self:GetNumChildren() > 0 then
			error(("Deleting a frame of type %q that still has %d children"):format(kind, frame:GetNumChildren()), 2)
		end
	end
	]]
	
	self:ClearAllPoints()
	self:SetPoint("LEFT", UIParent, "RIGHT", 1e5, 0)
	self:Hide()
	if self.SetBackdrop then
		self:SetBackdrop(nil)
	end
	self:SetParent(UIParent)
	self:SetAlpha(0)
	self:SetHeight(0)
	self:SetWidth(0)
	local cache_kind = cache[kind]
	if cache_kind[self] then
		error(("Double-free frame syndrome of type %q"):format(kind), 2)
	end
	cache_kind[self] = true
	return nil
end

local function newFrame(kind, parent, ...)
	--@alpha@
	expect(kind, 'typeof', 'string')
	expect(parent, 'typeof', 'frame')
	--@end-alpha@
	
	local cache_kind = cache[kind]
	if not cache_kind then
		cache_kind = {}
		cache[kind] = cache_kind
	end
	
	local frame = next(cache_kind)
	if frame then
		cache_kind[frame] = nil
	else
		if kind == "Texture" then
			frame = UIParent:CreateTexture(nil, "BACKGROUND")
		elseif kind == "FontString" then
			frame = UIParent:CreateFontString(nil, "BACKGROUND")
		else
			frame = CreateFrame(kind, nil, UIParent)
		end
		frame.Delete = frame_Delete
	end	
	frame:SetParent(parent)
	frame:ClearAllPoints()
	frame:SetAlpha(1)
	if kind == "Texture" then
		frame:SetTexture(nil)
		frame:SetVertexColor(1, 1, 1, 1)
	end
	if kind == "Texture" or kind == "FontString" then
		frame:SetDrawLayer((...))
	end
	frame:Show()
	return frame
end

function PitBull4_Controls.MakeFrame(parent)
	return newFrame("Frame", parent)
end

function PitBull4_Controls.MakeTexture(parent, layer)
	return newFrame("Texture", parent, layer)
end
