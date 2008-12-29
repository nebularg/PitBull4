local _G = _G
local PitBull4 = _G.PitBull4

local CustomIndicatorModule = PitBull4:NewModuleType("custom_indicator", {
	size = 1,
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
	hidden = false,
})

--- Does nothing. This should be implemented by the module.
-- When implementing, this should return whether :UpdateLayout(frame) should be called.
-- If you want an indicator that would be a different height than what other indicators, you can specify .height on the frame you create, which will act as a multiplier.
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateFrame(frame)
-- @return false
function CustomIndicatorModule:UpdateFrame(frame)
	return false
end

--- Does nothing. This should be implemented by the module.
-- When implementing, this should return whether :UpdateLayout(frame) should be called.
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:ClearFrame(frame)
function CustomIndicatorModule:ClearFrame(frame)
	return false
end
