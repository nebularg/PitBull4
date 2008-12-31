if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_HelloKittyIcon requires PitBull4")
end

local PitBull4_HelloKittyIcon = PitBull4:NewModule("HelloKittyIcon", "AceEvent-3.0", "AceTimer-3.0")

PitBull4_HelloKittyIcon:SetModuleType("icon")
PitBull4_HelloKittyIcon:SetName("Hello Kitty Icon")
PitBull4_HelloKittyIcon:SetDescription("Show an icon on the unit frame when the unit is female.")
PitBull4_HelloKittyIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
})

function PitBull4_HelloKittyIcon:GetTexture(frame)
	local unit = frame.unit
	
	gender_code = UnitSex(unit)

	if gender_code == 3 then
		return [[Interface\AddOns\PitBull4\Modules\HelloKittyIcon\hellokitty]]
	end
	
	return nil
end