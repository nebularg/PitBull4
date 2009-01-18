if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_BlankSpace requires PitBull4")
end

local L = PitBull4.L

local PitBull4_BlankSpace = PitBull4:NewModule("BlankSpace")

PitBull4_BlankSpace:SetModuleType("status_bar_provider")
PitBull4_BlankSpace:SetName(L["Blank space"])
PitBull4_BlankSpace:SetDescription(L["Provide empty bars for spacing."])
PitBull4_BlankSpace:SetDefaults({
	enabled = false,
	first = true,
})

function PitBull4_BlankSpace:OnNewLayout(layout)
	local layout_db = self.db.profile.layouts[layout]
	
	if layout_db.first then
		layout_db.first = false
		local default_bar = layout_db.bars[L["Default"]]
		default_bar.exists = true
	end
	
	local index = getmetatable(layout_db.bars).__index
	getmetatable(layout_db.bars).__index = function(self, key)
		print("__index", self, key)
		return index(self, key)
	end
end

function PitBull4_BlankSpace:GetValue(frame, bar_db)
	return 1
end

function PitBull4_BlankSpace:GetExampleValue(frame, bar_db)
	return 1
end

function PitBull4_BlankSpace:GetColor(frame, bar_db, value)
	return 0, 0, 0
end

PitBull4_BlankSpace:SetLayoutOptionsFunction(function(self)
	return
		'deficit', nil,
		'background_alpha', nil
end)
