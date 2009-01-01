local ICON_SIZE = 15

local _G = _G
local PitBull4 = _G.PitBull4

local IconModule = PitBull4:NewModuleType("icon", {
	size = 1,
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
	enabled = true,
})

--- Clear the icon for the current module if it exists.
-- @param frame the Unit Frame to clear
-- @usage local update_layout = MyModule:ClearFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function IconModule:ClearFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	local control = frame[id]
	if not control then
		return false
	end
	
	control.id = nil
	frame[id] = control:Delete()
	return true
end

--- Update the icon for the current module.
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function IconModule:UpdateFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	if not frame.guid or not self:GetLayoutDB(frame).enabled then
		return self:ClearFrame(frame)
	end
	
	local tex = self:CallTextureFunction(frame)
	if not tex then
		return self:ClearFrame(frame)
	end
	
	local control = frame[id]
	local made_control = not control
	if made_control then
		control = PitBull4.Controls.MakeIcon(frame)
		frame[id] = control
		control.id = id
		control:SetWidth(ICON_SIZE)
		control:SetHeight(ICON_SIZE)
	end
	
	control:SetTexture(tex)
	
	control:SetTexCoord(self:CallTexCoordFunction(frame, tex))
	
	return made_control
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