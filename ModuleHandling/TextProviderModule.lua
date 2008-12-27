local _G = _G
local PitBull4 = _G.PitBull4

local TextProviderModule = PitBull4:NewModuleType("text_provider", {
	texts = {
		['**'] = {
			size = 1,
			attach_to = "root",
			location = "edge_top_left",
			position = 1,
		},
		n = 1,
	},
	hidden = false,
})

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

local DEFAULT_FONT, DEFAULT_FONT_SIZE = ChatFontNormal:GetFont()

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
	
	for _, text in pairs(texts) do
		self:RemoveFontString(text)
		text.db = nil
		text:Delete()
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
	
	local db = self:GetLayoutDB(frame)
	if not frame.guid or db.hidden or db.texts.n == 0 then
		return self:ClearFrame(frame)
	end
	
	local texts = frame[self.id]
	if not texts then
		texts = new()
		frame[self.id] = texts
	end
	
	local changed = false
	
	-- get rid of any font strings not in the db
	local n = db.texts.n
	for k, font_string in pairs(texts) do
		if k > n then
			font_string.db = nil
			self:RemoveFontString(font_string)
			texts[k] = font_string:Delete()
			changed = true
		end
	end
	
	-- create or update texts
	for i = 1, db.texts.n do
		local text_db = db.texts[i]
		
		local font_string = texts[i]
		
		local attach_to = text_db.attach_to
		if attach_to == "root" or frame[text_db.attach_to] then
			-- what we're attaching to exists
			
			if not font_string then
				font_string = PitBull4.Controls.MakeFontString(frame.overlay, "OVERLAY")
				texts[i] = font_string
			end
			
			local font
			if LibSharedMedia then
				font = LibSharedMedia:Fetch("font", text_db.font or PitBull4.db.profile.layouts[frame.layout].font or "")
			end
			font_string:SetFont(font or DEFAULT_FONT, DEFAULT_FONT_SIZE * text_db.size)
			font_string.db = text_db
			if not self:HandleFontString(frame, font_string, text_db) then
				self:RemoveFontString(font_string)
				font_string.db = nil
				texts[i] = font_string:Delete()
			else
				changed = true
			end
		else
			-- TODO: see if this is a good idea
			if font_string then
				self:RemoveFontString(font_string)
				font_string.db = nil
				texts[i] = font_string:Delete()
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
