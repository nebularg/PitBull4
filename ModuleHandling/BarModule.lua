local _G = _G
local PitBull4 = _G.PitBull4

local BarModule = PitBull4:NewModuleType("bar", {
	size = 2,
	reverse = false,
	deficit = false,
	alpha = 1,
	background_alpha = 1,
	position = 1,
	side = 'center',
	enabled = true,
	custom_color = nil,
})

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

--- Call the :GetValue function on the bar module regarding the given frame.
-- @param self the module
-- @param frame the frame to get the value of
-- @usage local value, extra = call_value_function(MyModule, someFrame)
-- @return nil or a number within [0, 1]
-- @return nil or a number within (0, 1 - value]
local function call_value_function(self, frame)
	if not self.GetValue then
		return nil, nil
	end
	local value, extra
	if frame.guid then
		value, extra = self:GetValue(frame)
	end
	
	if not value and PitBull4.config_mode and self.GetExampleValue then
		value, extra = self:GetExampleValue(frame)
	end
	if not value then
		return nil, nil
	end
	if value < 0 or value ~= value then -- NaN
		value = 0
	elseif value > 1 then
		value = 1
	end
	if not extra or extra <= 0 or extra ~= extra then -- NaN
		return value, nil
	end
	
	local max = 1 - value
	if extra > max then
		extra = max
	end
	
	return value, extra
end

--- Call the :GetColor function on the status bar module regarding the given frame.
--- Call the color function which the current status bar module has registered regarding the given frame.
-- @param self the module
-- @param frame the frame to get the color of
-- @param value the value as returned by call_value_function
-- @param extra the extra value as returned by call_value_function
-- @usage local r, g, b, a = call_color_function(MyModule, someFrame)
-- @return red value within [0, 1]
-- @return green value within [0, 1]
-- @return blue value within [0, 1]
-- @return alpha value within [0, 1]
local function call_color_function(self, frame, value, extra)
	local layout_db = self:GetLayoutDB(frame)
	local custom_color = layout_db.custom_color
	if custom_color then
		return unpack(custom_color)
	end
	
	if not self.GetColor then
		return 0.7, 0.7, 0.7, 1
	end
	local r, g, b, a = self:GetColor(frame, value, extra)
	if (not r or not g or not b) and PitBull4.config_mode and self.GetExampleColor then
		r, g, b, a = self:GetExampleColor(frame, value, extra)
	end
	if not r or not g or not b then
		return 0.7, 0.7, 0.7, a or 1
	end
	return r, g, b, a or 1
end

--- Call the :GetExtraColor function on the status bar module regarding the given frame.
--- Call the color function which the current status bar module has registered regarding the given frame.
-- @param self the module
-- @param frame the frame to get the color of
-- @param value the value as returned by call_value_function
-- @param extra the extra value as returned by call_value_function
-- @usage local r, g, b, a = call_extra_color_function(MyModule, someFrame)
-- @return red value within [0, 1]
-- @return green value within [0, 1]
-- @return blue value within [0, 1]
-- @return alpha value within [0, 1] or nil
local function call_extra_color_function(self, frame, value, extra)
	local layout_db = self:GetLayoutDB(frame)
	local custom_color = layout_db.custom_color
	if custom_color then
		local r, g, b, a = custom_color
		return (1 + 2*r) / 3, (1 + 2*g) / 3, (1 + 2*b) / 3, a
	end
	
	if not self.GetExtraColor then
		return 0.5, 0.5, 0.5, nil
	end
	local r, g, b, a = self:GetExtraColor(frame, value, extra)
	if (not r or not g or not b) and PitBull4.config_mode and self.GetExampleExtraColor then
		r, g, b, a = self:GetExampleExtraColor(frame, value, extra)
	end
	if not r or not g or not b then
		return 0.5, 0.5, 0.5, nil
	end
	return r, g, b, a
end

--- Clear the status bar for the current module if it exists.
-- @param frame the Unit Frame to clear
-- @usage local update_layout = MyModule:ClearFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function BarModule:ClearFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	local control = frame[id]
	if not control then
		return false
	end
	
	frame[id] = control:Delete()
	return true
end

--- Update the status bar for the current module
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateStatusBar(frame)
-- @return whether the update requires :UpdateLayout to be called
function BarModule:UpdateFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local value, extra = call_value_function(self, frame)
	if not value then
		return self:ClearFrame(frame)
	end
	
	local id = self.id
	local control = frame[id]
	local made_control = not control
	if made_control then
		control = PitBull4.Controls.MakeBetterStatusBar(frame)
		frame[id] = control
	end
	
	control:SetTexture(self:GetTexture(frame))
	
	control:SetValue(value)
	local r, g, b, a = call_color_function(self, frame, value, extra or 0)
	control:SetColor(r, g, b)
	control:SetAlpha(a)

	if extra then
		control:SetExtraValue(extra)
		
		local r, g, b, a = call_extra_color_function(self, frame, value, extra)
		control:SetExtraColor(r, g, b)
		control:SetExtraAlpha(a)
	else
		control:SetExtraValue(0)
	end
	
	return made_control
end

--- Return the texture path to use for the given frame.
-- @param frame the unit frame
-- @return the texture path
-- @usage local texture = MyModule:GetTexture(some_frame)
-- some_frame.MyModule:SetTexture(texture)
function BarModule:GetTexture(frame)
	local layout_db = self:GetLayoutDB(frame)
	local texture
	if LibSharedMedia then
		texture = LibSharedMedia:Fetch("statusbar", layout_db.texture or frame.layout_db.bar_texture or "Blizzard")
	end
	return texture or [[Interface\TargetingFrame\UI-StatusBar]]
end
