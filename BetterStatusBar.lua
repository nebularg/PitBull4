-- everything in here will be added to the controls verbatim
local BetterStatusBar = {
	value = 1,
	extraValue = 0,
	orientation = "HORIZONTAL",
	reverse = false,
	deficit = false,
	bgR = false,
	bgG = false,
	bgB = false,
	bgA = false,
	extraR = false,
	extraG = false,
	extraB = false,
	extraA = false,
}
-- every script in here will be added to the control through :SetScript
local BetterStatusBar_scripts = {}

local function OnUpdate(self)
	self:SetScript("OnUpdate", nil)
	self:SetValue(self.value)
end

--- Set the current value
-- @param value value between [0, 1]
-- @usage bar:SetValue(0.5)
function BetterStatusBar:SetValue(value)
	--@alpha@
	expect(value, 'typeof', 'number')
	expect(value, '>=', 0)
	expect(value, '<=', 1)
	--@end-alpha@
	
	self.value = value
	if self.deficit then
		value = 1 - value
	end
	if value <= 0 then
		value = 1e-5
	elseif value >= 1 then
		value = 1
	end
	local extraValue = self.extraValue
	if extraValue <= 0 then
		extraValue = 1e-5
	elseif extraValue+value >= 1 then
		extraValue = 1 - value
	end
	if self.orientation == "VERTICAL" then
		if self:GetHeight() == 0 then
			self:SetScript("OnUpdate", OnUpdate)
		end
		self.fg:SetHeight(self:GetHeight() * value)
		self.extra:SetHeight(self:GetHeight() * extraValue)
		if not self.reverse then
			self.fg:SetTexCoord(value, 0, 0, 0, value, 1, 0, 1)
			self.extra:SetTexCoord(value+extraValue, 0, value, 0, value+extraValue, 1, value, 1)
			self.bg:SetTexCoord(1, 0, value+extraValue, 0, 1, 1, value+extraValue, 1)
		else
			self.fg:SetTexCoord(0, 0, value, 0, 0, 1, value, 1)
			self.extra:SetTexCoord(value, 0, value+extraValue, 0, value, 1, value+extraValue, 1)
			self.bg:SetTexCoord(value+extraValue, 0, 1, 0, value+extraValue, 1, 1, 1)
		end
	else
		if self:GetWidth() == 0 then
			self:SetScript("OnUpdate", OnUpdate)
		end
		self.fg:SetWidth(self:GetWidth() * value)
		self.extra:SetWidth(self:GetWidth() * extraValue)
		if not self.reverse then
			self.fg:SetTexCoord(0, 0, 0, 1, value, 0, value, 1)
			self.extra:SetTexCoord(value, 0, value, 1, value+extraValue, 0, value+extraValue, 1)
			self.bg:SetTexCoord(value+extraValue, 0, value+extraValue, 1, 1, 0, 1, 1)
		else
			self.fg:SetTexCoord(value, 0, value, 1, 0, 0, 0, 1)
			self.extra:SetTexCoord(value+extraValue, 0, value+extraValue, 1, value, 0, value, 1)
			self.bg:SetTexCoord(1, 0, 1, 1, value+extraValue, 0, value+extraValue, 1)
		end
	end
end
--- Return the current value
-- @return the value between [0, 1]
-- @usage assert(bar:GetValue() == 0.5)
function BetterStatusBar:GetValue()
	return self.value
end

--- Set the extra value of a status bar
-- This is useful if you have a base value and an auxillary value,
-- such as experience and rested experience.
-- @param extraValue
-- @usage bar:SetExtraValue(0.25)
function BetterStatusBar:SetExtraValue(extraValue)
	--@alpha@
	expect(extraValue, 'typeof', 'number')
	expect(extraValue, '>=', 0)
	--@end-alpha@
	
	self.extraValue = extraValue
	self:SetValue(self.value)
end
--- Return the extra value
-- @return the extra value
-- @usage assert(bar:GetExtraValue() == 0.25)
function BetterStatusBar:GetExtraValue()
	return self.extraValue
end

-- readjust where all the texture are positioned, in case any settings have changed
local function fix_orientation(self)
	local orientation, reverse = self.orientation, self.reverse
	local fg, extra, bg = self.fg, self.extra, self.bg
	fg:ClearAllPoints()
	extra:ClearAllPoints()
	bg:ClearAllPoints()
	fg:SetWidth(0)
	fg:SetHeight(0)
	extra:SetWidth(0)
	extra:SetHeight(0)
	if orientation == "VERTICAL" then
		fg:SetHeight(1e-5)
		if not reverse then
			fg:SetPoint("BOTTOM")
			fg:SetPoint("LEFT")
			fg:SetPoint("RIGHT")
		
			extra:SetPoint("BOTTOM", fg, "TOP")
			extra:SetPoint("LEFT")
			extra:SetPoint("RIGHT")
		
			bg:SetPoint("BOTTOM", extra, "TOP")
			bg:SetPoint("LEFT")
			bg:SetPoint("RIGHT")
			bg:SetPoint("TOP")
		else
			fg:SetPoint("TOP")
			fg:SetPoint("LEFT")
			fg:SetPoint("RIGHT")
	
			extra:SetPoint("TOP", fg, "BOTTOM")
			extra:SetPoint("LEFT")
			extra:SetPoint("RIGHT")
	
			bg:SetPoint("TOP", extra, "BOTTOM")
			bg:SetPoint("LEFT")
			bg:SetPoint("RIGHT")
			bg:SetPoint("BOTTOM")
		end
	else
		fg:SetWidth(1e-5)
		if not reverse then
			fg:SetPoint("LEFT")
			fg:SetPoint("TOP")
			fg:SetPoint("BOTTOM")
		
			extra:SetPoint("LEFT", fg, "RIGHT")
			extra:SetPoint("TOP")
			extra:SetPoint("BOTTOM")
		
			bg:SetPoint("LEFT", extra, "RIGHT")
			bg:SetPoint("RIGHT")
			bg:SetPoint("TOP")
			bg:SetPoint("BOTTOM")
		else
			fg:SetPoint("RIGHT")
			fg:SetPoint("TOP")
			fg:SetPoint("BOTTOM")
	
			extra:SetPoint("RIGHT", fg, "LEFT")
			extra:SetPoint("TOP")
			extra:SetPoint("BOTTOM")
	
			bg:SetPoint("RIGHT", extra, "LEFT")
			bg:SetPoint("LEFT")
			bg:SetPoint("TOP")
			bg:SetPoint("BOTTOM")
		end
	end
	
	self:SetValue(self.value)
end

--- Set the orientation of the bar
-- @param orientation "HORIZONTAL" or "VERTICAL"
-- @usage bar:SetOrientation("VERTICAL")
function BetterStatusBar:SetOrientation(orientation)
	--@alpha@
	expect(orientation, 'inset', 'HORIZONTAL;VERTICAL')
	--@end-alpha@
	
	if self.orientation == orientation then
		return
	end
	self.orientation = orientation
	
	fix_orientation(self)
end
--- Get the current orientation of the bar
-- @usage assert(bar:GetOrientation() == "VERTICAL")
-- @return "HORIZONTAL" or "VERTICAL"
function BetterStatusBar:GetOrientation()
	return self.orientation
end

--- Set whether the bar is reversed
-- Reversal means the bar goes right-to-left instead of left-to-right
-- @param reverse whether the bar is reversed
-- @usage bar:SetReverse(true)
function BetterStatusBar:SetReverse(reverse)
	--@alpha@
	expect(reverse, 'typeof', 'boolean')
	--@end-alpha@
	
	reverse = not not reverse
	if self.reverse == reverse then
		return
	end
	self.reverse = reverse
	
	fix_orientation(self)
end
--- Get whether the bar is currently reversed
-- @usage assert(bar:GetReverse() == true)
-- @return whether the bar is reversed
function BetterStatusBar:GetReverse()
	return self.reverse
end

--- Set whether the bar is showing its deficit
-- Showing deficit means that if the value is set to 25%, it'd show 75%
-- @param deficit whether the bar shows its deficit
-- @usage bar:SetDeficit(true)
function BetterStatusBar:SetDeficit(deficit)
	--@alpha@
	expect(deficit, 'typeof', 'boolean')
	--@end-alpha@
	
	deficit = not not deficit
	if self.deficit == deficit then
		return
	end
	self.deficit = deficit
	
	self:SetValue(self.value)
end
--- Get whether the bar is showing its deficit
-- @usage assert(bar:GetDeficit() == true)
-- @return whether the bar is showing its deficit
function BetterStatusBar:GetDeficit()
	return self.deficit
end

--- Set the texture that the bar is currently using
-- @param texture the path to the texture
-- @usage bar:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
function BetterStatusBar:SetTexture(texture)
	--@alpha@
	expect(texture, 'typeof', 'string')
	--@end-alpha@
	
	self.fg:SetTexture(texture)
	self.extra:SetTexture(texture)
	self.bg:SetTexture(texture)
end
--- Get the texture that the bar is using
-- @usage assert(bar:GetTexture() == [[Interface\TargetingFrame\UI-StatusBar]])
-- @return the path to the texture
function BetterStatusBar:GetTexture()
	return self.fg:GetTexture()
end
BetterStatusBar.GetStatusBarTexture = BetterStatusBar.GetTexture

--- Set the color of the bar
-- If the background color or the extra color is not set,
-- they will take on a similar color to what is specified here
-- @param r the red value [0, 1]
-- @param g the green value [0, 1]
-- @param b the blue value [0, 1]
-- @usage bar:SetColor(1, 0.82, 0)
function BetterStatusBar:SetColor(r, g, b)
	--@alpha@
	expect(r, 'typeof', 'number')
	expect(r, '>=', 0)
	expect(r, '<=', 1)
	expect(g, 'typeof', 'number')
	expect(g, '>=', 0)
	expect(g, '<=', 1)
	expect(b, 'typeof', 'number')
	expect(b, '>=', 0)
	expect(b, '<=', 1)
	--@end-alpha@
	
	self.fg:SetVertexColor(r, g, b)
	if self.extraR then
		self.extra:SetVertexColor(self.extraR, self.extraG, self.extraB)
	else
		self.extra:SetVertexColor((r + 0.25)/1.5, (g + 0.25)/1.5, (b + 0.25)/1.5)
	end
	if self.bgR then
		self.bg:SetVertexColor(self.bgR, self.bgG, self.bgB)
	else
		self.bg:SetVertexColor((r + 0.2)/3, (g + 0.2)/3, (b + 0.2)/3)
	end
end

--- Get the color of the bar
-- @usage local r, g, b = bar:GetColor()
-- @return the red value [0, 1]
-- @return the green value [0, 1]
-- @return the blue value [0, 1]
function BetterStatusBar:GetColor()
	local r, g, b = self.fg:GetVertexColor()
	return r, g, b
end
BetterStatusBar.GetStatusBarColor = BetterStatusBar.GetColor

--- Set the alpha value of the bar
-- If the background or extra alpha is not set,
-- they will be the same as the alpha specified here
-- @param a the alpha value [0, 1]
-- @usage bar:SetNormalAlpha(0.7)
function BetterStatusBar:SetNormalAlpha(a)
	--@alpha@
	expect(a, 'typeof', 'number')
	expect(a, '>=', 0)
	expect(a, '<=', 1)
	--@end-alpha@
	
	self.fg:SetAlpha(a)
	if not self.extraA then
		self.extra:SetAlpha(a)
	end
	if not self.bgA then
		self.bg:SetAlpha(a)
	end
end
--- Get the alpha value of the bar
-- @usage local alpha = bar:GetNormalAlpha()
-- @return the alpha value [0, 1]
function BetterStatusBar:GetNormalAlpha()
	return self.fg:GetAlpha()
end

--- Set the background color of the bar
-- If you don't specify the colors, then it will come up with a good color
-- based on the normal color
-- @param br the red value [0, 1] or nil
-- @param bg the green value [0, 1] or nil
-- @param bb the blue value [0, 1] or nil
-- @usage bar:SetBackgroundColor(0.5, 0.41, 0)
-- @usage bar:SetBackgroundColor()
function BetterStatusBar:SetBackgroundColor(br, bg, bb)
	--@alpha@
	expect(br, 'typeof', 'number;nil')
	if type(br) == "number" then
		expect(br, '>=', 0)
		expect(br, '<=', 1)
		expect(bg, 'typeof', 'number')
		expect(bg, '>=', 0)
		expect(bg, '<=', 1)
		expect(bb, 'typeof', 'number')
		expect(bb, '>=', 0)
		expect(bb, '<=', 1)
	else
		expect(bg, 'typeof', 'nil')
		expect(bb, 'typeof', 'nil')
	end
	--@end-alpha@
	
	self.bgR, self.bgG, self.bgB = br or false, bg or false, bb or false
	if not br then
		local r, g, b = self.fg:GetVertexColor()
		self.bg:SetVertexColor((r + 0.2)/3, (g + 0.2)/3, (b + 0.2)/3)
	else
		self.bg:SetVertexColor(br, bg, bb)
	end
end

--- Get the background color of the bar
-- @usage local r, g, b = bar:GetBackgroundColor()
-- @return the red value [0, 1]
-- @return the green value [0, 1]
-- @return the blue value [0, 1]
function BetterStatusBar:GetBackgroundColor()
	local r, g, b = self.bg:GetVertexColor()
	return r, g, b
end

--- Set the alpha value of the bar's background
-- If you do not specify the alpha, it will be the same as the bar's normal
-- alpha
-- @param a the alpha value [0, 1] or nil
-- @usage bar:SetBackgroundAlpha(0.7)
-- @usage bar:SetBackgroundAlpha()
function BetterStatusBar:SetBackgroundAlpha(a)
	--@alpha@
	expect(a, 'typeof', 'number;nil')
	if a then
		expect(a, '>=', 0)
		expect(a, '<=', 1)
	end
	--@end-alpha@
	
	self.bgA = a or false
	if not a then
		a = self.fg:GetAlpha()
	end
	self.bg:SetAlpha(a)
end

--- Get the alpha value of the bar's background
-- @usage local alpha = bar:GetBackgroundAlpha()
-- @return the alpha value [0, 1]
function BetterStatusBar:GetBackgroundAlpha()
	return self.bgA or self.fg:GetAlpha()
end

--- Set the extra color of the bar
-- If you don't specify the colors, then it will come up with a good color
-- based on the normal color
-- @param er the red value [0, 1] or nil
-- @param eg the green value [0, 1] or nil
-- @param eb the blue value [0, 1] or nil
-- @usage bar:SetExtraColor(0.8, 0.6, 0)
-- @usage bar:SetExtraColor()
function BetterStatusBar:SetExtraColor(er, eg, eb)
	--@alpha@
	expect(er, 'typeof', 'number;nil')
	if type(er) == "number" then
		expect(er, '>=', 0)
		expect(er, '<=', 1)
		expect(eg, 'typeof', 'number')
		expect(eg, '>=', 0)
		expect(eg, '<=', 1)
		expect(eb, 'typeof', 'number')
		expect(eb, '>=', 0)
		expect(eb, '<=', 1)
	else
		expect(eg, 'typeof', 'nil')
		expect(eb, 'typeof', 'nil')
	end
	--@end-alpha@

	self.extraR, self.extraG, self.extraB = er or false, eg or false, eb or false
	if not er then
		local r, g, b = self.fg:GetVertexColor()
		self.extra:SetVertexColor((r + 0.25)/1.5, (g + 0.25)/1.5, (b + 0.25)/1.5)
	else
		self.extra:SetVertexColor(er, eg, eb)
	end
end

--- Get the extra color of the bar
-- @usage local r, g, b = bar:GetExtraColor()
-- @return the red value [0, 1]
-- @return the green value [0, 1]
-- @return the blue value [0, 1]
function BetterStatusBar:GetExtraColor()
	local r, g, b = self.extra:GetVertexColor()
	return r, g, b
end

--- Set the alpha value of the bar's extra portion
-- If you do not specify the alpha, it will be the same as the bar's normal
-- alpha
-- @param a the alpha value [0, 1] or nil
-- @usage bar:SetExtraAlpha(0.7)
-- @usage bar:SetExtraAlpha()
function BetterStatusBar:SetExtraAlpha(a)
	--@alpha@
	expect(a, 'typeof', 'number;nil')
	if a then
		expect(a, '>=', 0)
		expect(a, '<=', 1)
	end
	--@end-alpha@
	
	self.extraA = a or false
	if not a then
		a = self.fg:GetAlpha()
	end
	self.extra:SetAlpha(a)
end

--- Get the alpha value of the bar's extra portion
-- @usage local alpha = bar:SetExtraAlpha()
-- @return the alpha value [0, 1]
function BetterStatusBar:GetExtraAlpha()
	return self.extraA or self.fg:GetAlpha()
end

--- Return the minimum and maximum values of the bar
-- Since this can't be changed, it will always return 0, 1
-- @usage local min, max = bar:GetMinMaxValues()
-- @return the minimum value: 0
-- @return the maximum value: 1
function BetterStatusBar:GetMinMaxValues()
	return 0, 1
end

-- when the size changes, make sure to readjust the sizes of the inner textures
function BetterStatusBar_scripts:OnSizeChanged()
	self:SetValue(self.value)
end

--- Make a better status bar than what Blizzard provides
-- @class function
-- @name PitBull4.Controls.MakeBetterStatusBar
-- @param parent frame the status bar is parented to
-- @usage local bar = PitBull4.Controls.MakeBetterStatusBar(someFrame)
-- @return a BetterStatusBar object
PitBull4.Controls.MakeNewControlType("BetterStatusBar", "Frame", function(control)
	-- onCreate
	local control_fg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
	control.fg = control_fg
	control_fg:SetPoint("LEFT")
	control_fg:SetPoint("TOP")
	control_fg:SetPoint("BOTTOM")
	
	local control_extra = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
	control.extra = control_extra
	control_extra:SetPoint("LEFT", control_fg, "RIGHT")
	control_extra:SetPoint("TOP")
	control_extra:SetPoint("BOTTOM")
	
	local control_bg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
	control.bg = control_bg
	control_bg:SetPoint("LEFT", control_extra, "RIGHT")
	control_bg:SetPoint("RIGHT")
	control_bg:SetPoint("TOP")
	control_bg:SetPoint("BOTTOM")
	
	for k,v in pairs(BetterStatusBar) do
		control[k] = v
	end
	for k,v in pairs(BetterStatusBar_scripts) do
		control:SetScript(k, v)
	end
end, function(control)
	-- onRetrieve
	fix_orientation(control)
	control:SetColor(1, 1, 1)
	control:SetNormalAlpha(1)
end, function(control)
	-- onDelete
	control:SetScript("OnUpdate", nil)
end)
