local _G = _G
local PitBull4 = _G.PitBull4

-- Constants -----------------------------------------------------------------
-- how long in seconds it would take to go from 100% to 0% opacity (or the other way around)
local FADE_TIME = 0.5

-- how many opacity points can change in one second
local OPACITY_POINTS_PER_SECOND = 1 / FADE_TIME
------------------------------------------------------------------------------

local FaderModule = PitBull4:NewModuleType("fader", {
	enabled = true,
})

-- a dictionary of module to a dictionary of frame to final opacity level
local module_to_frame_to_opacity = {}

-- a set of frames that should be checked for opacity changes
local changing_frames = {}

--- Return how opaque a frame will be once animation completes.
-- @param frame the Unit Frame to check.
-- @usage local opacity = PitBull4:GetFinalFrameOpacity(frame)
-- @return a number within [0, 1]
function PitBull4:GetFinalFrameOpacity(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local layout_db = frame.layout_db
	local unit = frame.unit
	
	local low = layout_db.opacity_max
	for module, frame_to_opacity in pairs(module_to_frame_to_opacity) do
		local opacity = frame_to_opacity[frame]
		if opacity and opacity < low then
			low = opacity
		end
	end
	return low
end

function PitBull4:RecheckAllOpacities()
	for frame in PitBull4:IterateFrames() do
		changing_frames[frame] = true
	end
end

local timerFrame = CreateFrame("Frame")
timerFrame:SetScript("OnUpdate", function(self, elapsed)
	local opacity_delta = elapsed * OPACITY_POINTS_PER_SECOND
	for frame in pairs(changing_frames) do
		if not frame:IsShown() then
			changing_frames[frame] = nil
		else
			local final_opacity = PitBull4:GetFinalFrameOpacity(frame)
			local current_opacity = frame:GetAlpha()
		
			if final_opacity ~= current_opacity then
				local result_opacity
				if final_opacity < current_opacity then
					result_opacity = current_opacity - opacity_delta
					if result_opacity < final_opacity then
						result_opacity = final_opacity
					end
				else
					result_opacity = current_opacity + opacity_delta
					if result_opacity > final_opacity then
						result_opacity = final_opacity
					end
				end
			
				frame:SetAlpha(result_opacity)
				if result_opacity == final_opacity then
					changing_frames[frame] = nil
				end
			else
				changing_frames[frame] = nil
			end
		end
	end
end)

--- Remove any opacity value for this module.
-- @param frame the Unit Frame to clear
-- @usage MyModule:ClearFrame(frame)
-- @return false, since :UpdateLayout isn't required for this type of module
function FaderModule:ClearFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local frame_to_opacity = module_to_frame_to_opacity[self]
	if not frame_to_opacity then
		return false
	end
	
	if frame_to_opacity[frame] then
		frame_to_opacity[frame] = nil
		changing_frames[frame] = true
	end
	
	return false
end

--- Update the opacity value for the current module
-- @param frame the Unit Frame to update
-- @usage MyModule:UpdateStatusBar(frame)
-- @return false, since :UpdateLayout isn't required for this type of module
function FaderModule:UpdateFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local frame_to_opacity = module_to_frame_to_opacity[self]
	if not frame_to_opacity then
		frame_to_opacity = {}
		module_to_frame_to_opacity[self] = frame_to_opacity
	end
	
	local opacity = self:CallOpacityFunction(frame)
	if not opacity then
		return self:ClearFrame(frame)
	end
	
	if frame_to_opacity[frame] ~= opacity then
		frame_to_opacity[frame] = opacity
		changing_frames[frame] = true
	end
	
	return false
end

--- Call the :GetValue function on the status bar module regarding the given frame.
-- @param frame the frame to get the value of
-- @usage local value, extra = MyModule:CallValueFunction(someFrame)
-- @return nil or a number within [0, 1)
function FaderModule:CallOpacityFunction(frame)
	if not self.GetOpacity then
		return nil, nil
	end
	
	local layout_db = frame.layout_db
	
	local opacity_min = layout_db.opacity_min
	local opacity_max = layout_db.opacity_max
	
	local value = self.guid and self:GetOpacity(frame)
	if not value or value >= opacity_max or value ~= value then
		return nil
	elseif value < opacity_min then
		return opacity_min
	else
		return value
	end
end
