if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HappinessIcon requires PitBull4")
end

local L = PitBull4.L

local PitBull4_HappinessIcon = PitBull4:NewModule("HappinessIcon", "AceEvent-3.0")

PitBull4_HappinessIcon:SetModuleType("icon")
PitBull4_HappinessIcon:SetName(L["Happiness icon"])
PitBull4_HappinessIcon:SetDescription(L["Show an icon on the pet frame to indicate its happiness."])
PitBull4_HappinessIcon:SetDefaults({
	attach_to = "root",
	location = "edge_bottom_right",
	position = 1,
})

function PitBull4_HappinessIcon:OnEnable()
	self:RegisterEvent("UNIT_HAPPINESS")
end

function PitBull4_HappinessIcon:GetTexture(frame)
	if frame.unit ~= "pet" then
		return nil
	end
	
	local happiness = GetPetHappiness()
	if not happiness then
		return nil
	end
	
	return [[Interface\PetPaperDollFrame\UI-PetHappiness]]
end

function PitBull4_HappinessIcon:GetExampleTexture(frame)
	if frame.unit ~= "pet" then
		return nil
	end
	
	return [[Interface\PetPaperDollFrame\UI-PetHappiness]]
end

local tex_coords = {
	-- unhappy
	{0.375, 0.5625, 0, 0.359375},
	
	-- content
	{0.1875, 0.375, 0, 0.359375},
	
	-- happy
	{0, 0.1875, 0, 0.359375},
}

function PitBull4_HappinessIcon:GetTexCoord(frame, texture)
	local happiness = GetPetHappiness()
	local tex_coord = tex_coords[happiness] or tex_coords[3]
	
	return tex_coord[1], tex_coord[2], tex_coord[3], tex_coord[4]
end

function PitBull4_HappinessIcon:UNIT_HAPPINESS()
	self:UpdateForUnitID("pet")
end
