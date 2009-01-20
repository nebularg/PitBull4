local _G = _G
local PitBull4 = _G.PitBull4

local TextProviderModule = PitBull4:NewModuleType("text_provider", {
	elements = {
		['**'] = {
			size = 1,
			attach_to = "root",
			location = "edge_top_left",
			position = 1,
			exists = false,
		},
	},
	enabled = true,
})

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

local new, del = PitBull4.new, PitBull4.del

--- Clear the texts for the current module if it exists.
-- @param frame the Unit Frame to clear
-- @usage local update_layout = MyModule:ClearFrame(frame)
-- @return whether the update requires :UpdateLayout to be called
function TextProviderModule:ClearFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@

	local id = self.id
	local texts = frame[id]
	if not texts then
		return false
	end
	
	for name, text in pairs(texts) do
		self:RemoveFontString(text)
		text.db = nil
		text:Delete()
		frame[id .. ";" .. name] = nil
	end
	frame[id] = del(texts)
	
	return true
end

--- Update the texts for the current module
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateIcon(frame)
-- @return whether the update requires :UpdateLayout to be called
function TextProviderModule:UpdateFrame(frame)
	--@alpha@
	expect(frame, 'typeof', 'frame')
	--@end-alpha@
	
	local layout_db = self:GetLayoutDB(frame)
	if not next(layout_db.elements) then
		return self:ClearFrame(frame)
	end
	
	local texts = frame[self.id]
	if not texts then
		texts = new()
		frame[self.id] = texts
	end
	
	local changed = false
	
	-- get rid of any font strings not in the db
	for name, font_string in pairs(texts) do
		if not rawget(layout_db.elements, name) then
			self:RemoveFontString(font_string)
			font_string.db = nil
			texts[name] = font_string:Delete()
			frame[self.id .. ";" .. name] = nil
			changed = true
		end
	end
	
	-- create or update bars
	for name, text_db in pairs(layout_db.elements) do
		local font_string = texts[name]
		
		local attach_to = text_db.attach_to
		
		local has_attach_to = false
		if attach_to == "root" then
			has_attach_to = true
		elseif frame[attach_to] then
			has_attach_to = true
		end
		
		if has_attach_to then
			-- what we're attaching to exists
			
			if not font_string then
				font_string = PitBull4.Controls.MakeFontString(frame.overlay, "OVERLAY")
				texts[name] = font_string
				frame[self.id .. ";" .. name] = font_string
				font_string:SetShadowColor(0, 0, 0, 1)
				font_string:SetShadowOffset(0.8, -0.8)
				font_string:SetNonSpaceWrap(false)
			end
			
			local font, size = frame:GetFont(text_db.font, text_db.size)
			local _, _, modifier = font_string:GetFont()
			font_string:SetFont(font, size, modifier)
			font_string.db = text_db
			if not self:AddFontString(frame, font_string, name, text_db) then
				self:RemoveFontString(font_string)
				font_string.db = nil
				texts[name] = font_string:Delete()
				frame[self.id .. ";" .. name] = nil
			else
				changed = true
			end
		else
			-- TODO: see if this is a good idea
			if font_string then
				self:RemoveFontString(font_string)
				font_string.db = nil
				texts[name] = font_string:Delete()
				frame[self.id .. ";" .. name] = nil
				changed = true
			end
		end
	end
	if next(texts) == nil then
		frame[self.id] = del(texts)
		texts = nil
	end
	
	return changed
end
