local _G = _G
local PitBull4 = _G.PitBull4

local CustomTextModule = PitBull4:NewModuleType("custom_text", {
	size = 1,
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
	hidden = false,
})

--- Does nothing. This should be implemented by the module.
-- When implementing, this should return whether :UpdateLayout(frame) should be called.
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:UpdateFrame(frame)
-- @return false
function CustomTextModule:UpdateFrame(frame)
	return false
end

--- Does nothing. This should be implemented by the module.
-- When implementing, this should return whether :UpdateLayout(frame) should be called.
-- @param frame the Unit Frame to update
-- @usage local update_layout = MyModule:ClearFrame(frame)
function CustomTextModule:ClearFrame(frame)
	return false
end

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
	LoadAddOn("LibSharedMedia-3.0")
	LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

local DEFAULT_FONT, DEFAULT_FONT_SIZE = ChatFontNormal:GetFont()

function CustomTextModule:GetFont(frame)
	local db = self:GetLayoutDB(frame)
	local font
	if LibSharedMedia then
		font = LibSharedMedia:Fetch("font", db.font or PitBull4.db.profile.layouts[frame.layout].font or "")
	end
	return font or DEFAULT_FONT, DEFAULT_FONT_SIZE * db.size
end
