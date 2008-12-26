local _G = _G
local PitBull4 = _G.PitBull4

local StatusBarModule = PitBull4:NewModuleType("statusbar", {
	size = 2,
	reverse = false,
	deficit = false,
	alpha = 1,
	background_alpha = 1,
	position = 1,
	side = 'center',
})

local value_funcs = {}
local color_funcs = {}

-- handle the case where there is no value returned, i.e. the module returned nil
local function handle_statusbar_nonvalue(module, frame)
	local id = module.id
	local control = frame[id]
	if control then
		frame.id = nil
		frame[id] = control:Delete()
		return true
	end
	return false
end

--- Update the status bar for the current module
-- @param frame the Unit Frame to update
-- @usage local updateLayout = MyModule:UpdateStatusBar(frame)
-- @return whether the update requires UpdateLayout to be called
function StatusBarModule:UpdateStatusBar(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	if self:GetLayoutDB(frame).hidden then
		return handle_statusbar_nonvalue(self, frame)
	end
	
	local value = frame.guid and self:CallValueFunction(frame)
	if not value then
		return handle_statusbar_nonvalue(self, frame)
	end
	
	local control = frame[id]
	local made_control = not control
	if made_control then
		control = PitBull4.Controls.MakeBetterStatusBar(frame)
		frame[id] = control
		control.id = id
		control:SetTexture([[Interface\TargetingFrame\UI-StatusBar]])
	end
	
	control:SetValue(value)
	local r, g, b, a = self:CallColorFunction(frame, value)
	control:SetColor(r, g, b)
	control:SetAlpha(a)
	
	return made_control
end

--- Update the status bar for current module for the given frame and handle any layout changes
-- @param frame the Unit Frame to update
-- @param returnChanged whether to return if the update should change the layout. If this is false, it will call :UpdateLayout() automatically.
-- @usage MyModule:Update(frame)
-- @return whether the update requires UpdateLayout to be called if returnChanged is specified
function StatusBarModule:Update(frame, returnChanged)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	expect(returnChanged, 'typeof', 'nil;boolean')
	--@end-alpha@
	
	local changed = self:UpdateStatusBar(frame)
	
	if returnChanged then
		return changed
	end
	if changed then
		frame:UpdateLayout()
	end
end

--- Update the status bar for current module for all units of the given UnitID
-- @param unit the UnitID in question to update
-- @usage MyModule:UpdateForUnitID("player")
function StatusBarModule:UpdateForUnitID(unit)
	--@alpha@
	expect(unit, 'typeof', 'string')
	--@end-alpha@
	
	local id = self.id
	for frame in PitBull4:IterateFramesForUnitID(unit) do
		if frame[id] then
			self:Update(frame)
		end
	end
end

--- Update the status bar for the current module for all frames that have the status bar.
-- @usage MyModule:UpdateAll()
function StatusBarModule:UpdateAll()
	local id = self.id
	for frame in PitBull4:IterateFrames(true) do
		if frame[id] then
			self:Update(frame)
		end
	end
end

--- Call the :GetValue function on the status bar module regarding the given frame.
-- @param frame the frame to get the value of
-- @usage local value = MyModule:CallValueFunction(someFrame)
-- @return a number within [0, 1]
function StatusBarModule:CallValueFunction(frame)
	if not self.GetValue then
		return nil
	end
	local value = self:GetValue(frame)
	if not value then
		return nil
	end
	if value < 0 or value ~= value then -- NaN
		return 0
	end
	if value > 1 then
		return 1
	end
	return value
end

--- Call the :GetColor function on the status bar module regarding the given frame.
--- Call the color function which the current status bar module has registered regarding the given frame.
-- @param frame the frame to get the color of
-- @param value the value as returned by :CallValueFunction
-- @usage local r, g, b, a = MyModule:CallColorFunction(someFrame)
-- @return red value within [0, 1]
-- @return green value within [0, 1]
-- @return blue value within [0, 1]
-- @return alpha value within [0, 1]
function StatusBarModule:CallColorFunction(frame, value)
	if not self.GetColor then
		return 0.7, 0.7, 0.7
	end
	local r, g, b, a = self:GetColor(frame, value)
	if not r or not g or not b then
		return 0.7, 0.7, 0.7, a or 1
	end
	return r, g, b, a or 1
end
