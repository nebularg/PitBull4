local _G = _G
local PitBull4 = _G.PitBull4

local IconModule = PitBull4:NewModuleType("icon", {
	size = 1,
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
	hidden = false,
})

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
-- @usage local update_layout = MyModule:UpdateIcon(frame)
-- @return whether the update requires :UpdateLayout to be called
function IconModule:UpdateIcon(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	if not frame.guid or self:GetLayoutDB(frame).hidden then
		return handle_icon_nonvalue(self, frame)
	end
	
	local tex = self:CallTextureFunction(frame)
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
	
	control:SetTexCoord(self:CallTexCoordFunction(frame, tex))
	
	return made_control
end

--- Update the icon for current module for the given frame and handle any layout changes
-- @param frame the Unit Frame to update
-- @param return_changed whether to return if the update should change the layout. If this is false, it will call :UpdateLayout() automatically.
-- @usage MyModule:Update(frame)
-- @return whether the update requires UpdateLayout to be called if return_changed is specified
function IconModule:Update(frame, return_changed)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	expect(return_changed, 'typeof', 'nil;boolean')
	--@end-alpha@
	
	local changed = self:UpdateIcon(frame)
	
	if return_changed then
		return changed
	end
	if changed then
		frame:UpdateLayout()
	end
end

--- Update the icon for current module for all units of the given UnitID
-- @param unit the UnitID in question to update
-- @usage MyModule:UpdateForUnitID(frame)
function IconModule:UpdateForUnitID(unit)
	--@alpha@
	expect(unit, 'typeof', 'string')
	--@end-alpha@
	
	local id = self.id
	for frame in PitBull4:IterateFramesForUnitID(unit) do
		self:Update(frame)
	end
end

--- Update the icon for the current module for all frames.
-- @usage MyModule:UpdateAll()
function IconModule:UpdateAll()
	local id = self.id
	for frame in PitBull4:IterateFrames() do
		self:Update(frame)
	end
end

--- Call the :GetTexture function on the icon module regarding the given frame.
-- @param frame the frame to get the texture of
-- @usage local tex, c1, c2, c3, c4 = MyModule:CallTextureFunction(someFrame)
-- @return texture the path to the texture to show
function IconModule:CallTextureFunction(frame)
	if not self.GetTexture then
		-- no function, let's just return
		return nil
	end
	local tex = self:GetTexture(frame)
	if not tex then
		return nil
	end
	
	return tex
end

--- Call the :GetTexCoord function on the icon module regarding the given frame.
-- @param frame the frame to get the TexCoord of
-- @param texture the texture as returned by :CallTextureFunction
-- @usage local c1, c2, c3, c4 = MyModule:CallTexCoordFunction(someFrame, "SomeTexture")
-- @return left TexCoord for left within [0, 1]
-- @return right TexCoord for right within [0, 1]
-- @return top TexCoord for top within [0, 1]
-- @return bottom TexCoord for bottom within [0, 1]
function IconModule:CallTexCoordFunction(frame, texture)
	if not self.GetTexCoord then
		-- no function, let's just return the defaults
		return 0, 1, 0, 1
	end
	local c1, c2, c3, c4 = self:GetTexCoord(frame, texture)
	if not c4 then
		return 0, 1, 0, 1
	end
	
	return c1, c2, c3, c4
end