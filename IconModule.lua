local _G = _G
local PitBull4 = _G.PitBull4

local IconModule = PitBull4:NewModuleType("icon", {
	size = 1,
})

local texture_funcs = {}

--- Add the function to specify the current percentage of the status bar
-- @param func function that returns a number within [0, 1]
-- @usage MyModule:SetValueFunction(function(frame)
--     return UnitHealth(frame.unit) / UnitHealthMax(frame.unit)
-- end)
function IconModule:SetTextureFunction(func)
	--@alpha@
	expect(func, 'typeof', 'function;string')
	if type(func) == "string" then
		expect(self[func], 'typeof', 'function')
	end
	expect(texture_funcs[self], 'typeof', 'nil')
	--@end-alpha@
	
	texture_funcs[self] = PitBull4.Utils.ConvertMethodToFunction(self, func)
end

-- handle the case where there is no value returned, i.e. the module returned nil
local function handle_icon_nonvalue(module, frame)
	local id = module.id
	local control = frame[id]
	if control then
		frame.id = nil
		frame[id] = control:Delete()
		return true
	end
	return false
end

--- Update the icon for the current module
-- @param frame the Unit Frame to update
-- @usage local updateLayout = MyModule:UpdateIcon(frame)
-- @return whether the update requires UpdateLayout to be called
function IconModule:UpdateIcon(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	if frame.layoutDB[id].hidden or not frame.guid then
		return handle_icon_nonvalue(self, frame)
	end
	
	local tex, c1, c2, c3, c4 = self:CallTextureFunction(frame)
	if not tex then
		return handle_icon_nonvalue(self, frame)
	end
	
	local control = frame[id]
	local made_control = not control
	if made_control then
		control = PitBull4.Controls.MakeIcon(frame)
		frame[id] = control
		control.id = id
	end
	
	control:SetTexture(tex)
	control:SetTexCoord(c1, c2, c3, c4)
	
	return made_control
end

--- Update the icon for current module for the given frame and handle any layout changes
-- @param frame the Unit Frame to update
-- @param returnChanged whether to return if the update should change the layout. If this is false, it will call :UpdateLayout() automatically.
-- @usage MyModule:Update(frame)
-- @return whether the update requires UpdateLayout to be called if returnChanged is specified
function IconModule:Update(frame, returnChanged)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	expect(returnChanged, 'typeof', 'nil;boolean')
	--@end-alpha@
	
	local changed = self:UpdateIcon(frame)
	
	if returnChanged then
		return changed
	end
	if changed then
		frame:UpdateLayout()
	end
end

--- Update the icon for current module for all units of the given unitID
-- @param unitID the unitID in question to update
-- @usage MyModule:UpdateForUnitID(frame)
function IconModule:UpdateForUnitID(unitID)
	--@alpha@
	expect(unitID, 'typeof', 'string')
	--@end-alpha@
	
	local id = self.id
	for frame in PitBull4.IterateFramesForUnitID(unitID) do
		if frame[id] then
			self:Update(frame)
		end
	end
end

--- Update the icon for the current module for all frames that have the icon.
-- @usage MyModule:UpdateAll()
function IconModule:UpdateAll()
	local id = self.id
	for frame in PitBull4.IterateFrames(true) do
		if frame[id] then
			self:Update(frame)
		end
	end
end

--- Call the texture function which the given icon module has registered regarding the given frame.
-- @param frame the frame to get the texture of
-- @usage local tex, c1, c2, c3, c4 = MyModule:CallTextureFunction(someFrame)
-- @return texture the path to the texture to show
-- @return left TexCoord for left within [0, 1]
-- @return right TexCoord for right within [0, 1]
-- @return top TexCoord for top within [0, 1]
-- @return bottom TexCoord for bottom within [0, 1]
function IconModule:CallTextureFunction(frame)
	local tex, c1, c2, c3, c4 = texture_funcs[self](frame)
	if not tex then
		return nil
	end
	
	if not c1 then
		c1, c2, c3, c4 = 0, 1, 0, 1
	end
	
	return tex, c1, c2, c3, c4
end
