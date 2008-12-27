local _G = _G
local PitBull4 = _G.PitBull4

local StatusBarModule = PitBull4:NewModuleType("status_bar", {
	size = 2,
	reverse = false,
	deficit = false,
	alpha = 1,
	background_alpha = 1,
	position = 1,
	side = 'center',
	hidden = false,
})

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

--- Clear the status bar for the current module if it exists.
-- @param frame the Unit Frame to clear
-- @usage local update_layout = MyModule:ClearFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function StatusBarModule:ClearFrame(frame)
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

--- Update the status bar for the current module
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateStatusBar(frame)
-- @return whether the update requires :UpdateLayout to be called
function StatusBarModule:UpdateFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	local layout_db = self:GetLayoutDB(frame)
	if not frame.guid or layout_db.hidden then
		return self:ClearFrame(frame)
	end
	
	local value = self:CallValueFunction(frame)
	if not value then
		return self:ClearFrame(frame)
	end
	
	local control = frame[id]
	local made_control = not control
	if made_control then
		control = PitBull4.Controls.MakeBetterStatusBar(frame)
		frame[id] = control
		control.id = id
	end
	local texture
	if LibSharedMedia then
		texture = LibSharedMedia:Fetch("statusbar", layout_db.texture or PitBull4.db.profile.layouts[frame.layout].status_bar_texture or "Blizzard")
	end
	control:SetTexture(texture or [[Interface\TargetingFrame\UI-StatusBar]])
	
	control:SetValue(value)
	local r, g, b, a = self:CallColorFunction(frame, value)
	control:SetColor(r, g, b)
	control:SetAlpha(a)
	
	return made_control
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
