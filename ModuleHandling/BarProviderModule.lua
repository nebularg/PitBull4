local _G = _G
local PitBull4 = _G.PitBull4

local DEBUG = PitBull4.DEBUG
local expect = PitBull4.expect

local BarProviderModule = PitBull4:NewModuleType("bar_provider", {
	enabled = true,
	elements = {
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
}, true)

local new, del = PitBull4.new, PitBull4.del

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

--- Call the :GetValue function on the status bar module regarding the given frame.
-- @param self the module
-- @param frame the frame to get the value of
-- @param bar_db the layout db for the specific bar
-- @usage local value, extra = call_value_function(MyModule, someFrame)
-- @return nil or a number within [0, 1]
-- @return nil or a number within (0, 1 - value]
local function call_value_function(self, frame, bar_db)
	if not self.GetValue then
		return nil, nil
	end
	local value, extra
	if frame.guid then
		value, extra = self:GetValue(frame, bar_db)
	end
	
	if not value and frame.force_show and self.GetExampleValue then
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
-- @param self the module
-- @param frame the frame to get the color of
-- @param bar_db the layout db for the specific bar
-- @param value the value as returned by :call_value_function
-- @param extra the extra value as returned by :call_value_function
-- @usage local r, g, b, a = call_color_function(MyModule, someFrame)
-- @return red value within [0, 1]
-- @return green value within [0, 1]
-- @return blue value within [0, 1]
-- @return alpha value within [0, 1]
local function call_color_function(self, frame, bar_db, value, extra)
	local custom_color = bar_db.custom_color

	if not self.GetColor then
		if custom_color then
			return custom_color[1], custom_color[2], custom_color[3], bar_db.alpha 
		else
			return 0.7, 0.7, 0.7, bar_db.alpha 
		end
	end
	local r, g, b, a, override
	if frame.guid then
		r, g, b, a, override = self:GetColor(frame, bar_db, value, extra)
	end
	if not override and custom_color then
		return custom_color[1], custom_color[2], custom_color[3], a or bar_db.alpha 
	end
	if (not r or not g or not b) and frame.force_show and self.GetExampleColor then
		r, g, b, a = self:GetExampleColor(frame, bar_db, value, extra)
	end
	if not r or not g or not b then
		return 0.7, 0.7, 0.7, a or bar_db.alpha 
	end
	return r, g, b, a or bar_db.alpha 
end

--- Call the :GetExtraColor function on the status bar module regarding the given frame.
--- Call the color function which the current status bar module has registered regarding the given frame.
-- @param self the module
-- @param frame the frame to get the color of
-- @param bar_db the layout db for the specific bar
-- @param value the value as returned by :call_value_function
-- @param extra the extra value as returned by :call_value_function
-- @usage local r, g, b, a = call_extra_color_function(MyModule, someFrame)
-- @return red value within [0, 1]
-- @return green value within [0, 1]
-- @return blue value within [0, 1]
-- @return alpha value within [0, 1] or nil
local function call_extra_color_function(self, frame, bar_db, value, extra)
	local custom_color = bar_db.custom_color
	if custom_color then
		local r, g, b = custom_color[1], custom_color[2], custom_color[3]
		return (1 + 2*r) / 3, (1 + 2*g) / 3, (1 + 2*b) / 3, 1 
	end
	
	if not self.GetExtraColor then
		return 0.5, 0.5, 0.5, nil
	end
	local r, g, b, a
	if frame.guid then
		r, g, b, a = self:GetExtraColor(frame, value, extra)
	end
	if (not r or not g or not b) and frame.force_show and self.GetExampleExtraColor then
		r, g, b, a = self:GetExampleExtraColor(frame, value, extra)
	end
	if not r or not g or not b then
		return 0.5, 0.5, 0.5, nil
	end
	return r, g, b, a
end

--- Handle the frame being hidden
-- @param frame the Unit Frame hidden.
-- @usage MyModule:OnHide(frame)
function BarProviderModule:OnHide(frame)
	if DEBUG then
		expect(frame, 'typeof', 'frame')
	end

	local id = self.id
	local bars = frame[id]
	if not bars then
		return
	end

	for name, bar in pairs(bars) do
		bar:Hide()
	end
end

--- Clear the status bar for the current module if it exists.
-- @param frame the Unit Frame to clear
-- @usage local update_layout = MyModule:ClearFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function BarProviderModule:ClearFrame(frame)
	if DEBUG then
		expect(frame, 'typeof', 'frame')
	end
	
	local id = self.id
	local bars = frame[id]
	if not bars then
		return false
	end
	
	for name, bar in pairs(bars) do
		bar.db = nil
		bar:Delete()
		frame[id .. ";" .. name] = nil
	end
	frame[id] = del(bars)
	
	return true
end

--- Update the status bar for the current module
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateStatusBar(frame)
-- @return whether the update requires :UpdateLayout to be called
function BarProviderModule:UpdateFrame(frame)
	if DEBUG then
		expect(frame, 'typeof', 'frame')
	end
	
	local layout_db = self:GetLayoutDB(frame)
	if not next(layout_db.elements) then
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
		if not rawget(layout_db.elements, name) then
			bar.db = nil
			bars[name] = bar:Delete()
			frame[self.id .. ";" .. name] = nil
			changed = true
		end
	end
	
	-- create or update bars
	for name, bar_db in pairs(layout_db.elements) do
		local bar = bars[name]
		
		local value, extra = call_value_function(self, frame, bar_db)
		if not value then
			if bar then
				bar.db = nil
				bars[name] = bar:Delete()
				frame[self.id .. ";" .. name] = nil
				changed = true
			end
		else
			if not bar then
				bar = PitBull4.Controls.MakeBetterStatusBar(frame)
				bars[name] = bar
				frame[self.id .. ";" .. name] = bar
				bar.db = bar_db
				changed = true
			end
			
			local texture
			if LibSharedMedia then
				texture = LibSharedMedia:Fetch("statusbar", bar_db.texture or frame.layout_db.bar_texture or "Blizzard")
			end
			bar:SetTexture(texture or [[Interface\TargetingFrame\UI-StatusBar]])
			bar:SetValue(value)
			
			local r, g, b, a = call_color_function(self, frame, bar_db, value, extra or 0)
			bar:SetColor(r, g, b)
			bar:SetAlpha(a)
			
			if extra then
				bar:SetExtraValue(extra)

				local r, g, b, a = call_extra_color_function(self, frame, bar_db, value, extra)
				bar:SetExtraColor(r, g, b)
				bar:SetExtraAlpha(a)
			else
				bar:SetExtraValue(0)
			end

			bar:Show()
		end
	end
	
	if next(bars) == nil then
		frame[self.id] = del(bars)
		bars = nil
	end
	
	return changed
end
