local _G = _G
local PitBull4 = _G.PitBull4

local StatusBarProviderModule = PitBull4:NewModuleType("status_bar_provider", {
	enabled = true,
	bars = {
		['**'] = {
			size = 2,
			reverse = false,
			deficit = false,
			alpha = 1,
			background_alpha = 1,
			position = 10,
			side = 'center',
			custom_color = nil,
			exists = false,
		}
	}
})

local new, del = PitBull4.new, PitBull4.del

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

--- Clear the status bar for the current module if it exists.
-- @param frame the Unit Frame to clear
-- @usage local update_layout = MyModule:ClearFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function StatusBarProviderModule:ClearFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local id = self.id
	local bars = frame[id]
	if not bars then
		return false
	end
	
	for _, bar in pairs(bars) do
		bar.db = nil
		bar:Delete()
	end
	frame[id] = del(bars)
	
	return true
end

--- Update the status bar for the current module
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateStatusBar(frame)
-- @return whether the update requires :UpdateLayout to be called
function StatusBarProviderModule:UpdateFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local layout_db = self:GetLayoutDB(frame)
	if not next(layout_db.bars) then
		return self:ClearFrame(frame)
	end
	
	local bars = frame[self.id]
	if not bars then
		bars = new()
		frame[self.id] = bars
	end
	
	local changed = false
	
	-- get rid of any bars not in the db
	for name, bar in pairs(bars) do
		if not rawget(layout_db.bars, name) then
			bar.db = nil
			bars[name] = bar:Delete()
			changed = true
		end
	end
	
	-- create or update bars
	for name, bar_db in pairs(layout_db.bars) do
		local bar = bars[name]
		
		local value, extra = self:CallValueFunction(frame, bar_db)
		if not value then
			if bar then
				bar.db = nil
				bars[name] = bar:Delete()
				changed = true
			end
		else
			if not bar then
				bar = PitBull4.Controls.MakeBetterStatusBar(frame)
				bars[name] = bar
				bar.db = bar_db
				changed = true
			end
			
			local texture
			if LibSharedMedia then
				texture = LibSharedMedia:Fetch("statusbar", bar_db.texture or frame.layout_db.bar_texture or "Blizzard")
			end
			bar:SetTexture(texture or [[Interface\TargetingFrame\UI-StatusBar]])
			bar:SetValue(value)
			
			local r, g, b, a = self:CallColorFunction(frame, bar_db, value, extra or 0)
			bar:SetColor(r, g, b)
			bar:SetAlpha(a)
			
			if extra then
				bar:SetExtraValue(extra)

				local r, g, b, a = self:CallExtraColorFunction(frame, bar_db, value, extra)
				bar:SetExtraColor(r, g, b)
				bar:SetExtraAlpha(a)
			else
				bar:SetExtraValue(0)
			end
		end
	end
	
	if next(bars) == nil then
		frame[self.id] = del(bars)
		bars = nil
	end
	
	return changed
end

--- Call the :GetValue function on the status bar module regarding the given frame.
-- @param frame the frame to get the value of
-- @param bar_db the layout db for the specific bar
-- @usage local value, extra = MyModule:CallValueFunction(someFrame)
-- @return nil or a number within [0, 1]
-- @return nil or a number within (0, 1 - value]
function StatusBarProviderModule:CallValueFunction(frame, bar_db)
	if not self.GetValue then
		return nil, nil
	end
	local value, extra
	if frame.guid then
		value, extra = self:GetValue(frame, bar_db)
	end
	
	if not value and PitBull4.config_mode and self.GetExampleValue then
		value, extra = self:GetExampleValue(frame, bar_db)
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
-- @param frame the frame to get the color of
-- @param bar_db the layout db for the specific bar
-- @param value the value as returned by :CallValueFunction
-- @param extra the extra value as returned by :CallValueFunction
-- @usage local r, g, b, a = MyModule:CallColorFunction(someFrame)
-- @return red value within [0, 1]
-- @return green value within [0, 1]
-- @return blue value within [0, 1]
-- @return alpha value within [0, 1]
function StatusBarProviderModule:CallColorFunction(frame, bar_db, value, extra)
	local custom_color = bar_db.custom_color
	if custom_color then
		return unpack(custom_color)
	end
	
	if not self.GetColor then
		return 0.7, 0.7, 0.7, 1
	end
	local r, g, b, a = self:GetColor(frame, bar_db, value, extra)
	if (not r or not g or not b) and PitBull4.config_mode and self.GetExampleColor then
		r, g, b, a = self:GetExampleColor(frame, bar_db, value, extra)
	end
	if not r or not g or not b then
		return 0.7, 0.7, 0.7, a or 1
	end
	return r, g, b, a or 1
end

--- Call the :GetExtraColor function on the status bar module regarding the given frame.
--- Call the color function which the current status bar module has registered regarding the given frame.
-- @param frame the frame to get the color of
-- @param bar_db the layout db for the specific bar
-- @param value the value as returned by :CallValueFunction
-- @param extra the extra value as returned by :CallValueFunction
-- @usage local r, g, b, a = MyModule:CallColorFunction(someFrame)
-- @return red value within [0, 1]
-- @return green value within [0, 1]
-- @return blue value within [0, 1]
-- @return alpha value within [0, 1] or nil
function StatusBarProviderModule:CallExtraColorFunction(frame, bar_db, value, extra)
	local custom_color = bar_db.custom_color
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
