if select(5, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
	error("PitBull4_RoleIcon requires PitBull4")
end

local L = PitBull4.L

local PitBull4_RoleIcon = PitBull4:NewModule("RoleIcon", "AceEvent-3.0")

PitBull4_RoleIcon:SetModuleType("indicator")
PitBull4_RoleIcon:SetName(L["Role icon"])
PitBull4_RoleIcon:SetDescription(L["Show an icon on the unit frame based on which Role it is."])
PitBull4_RoleIcon:SetDefaults({
	attach_to = "root",
	location = "edge_top_left",
	position = 1,
})

function PitBull4_RoleIcon:OnEnable()
	self:RegisterEvent("PLAYER_ROLES_ASSIGNED")
end

function PitBull4_RoleIcon:GetTexture(frame)
	local role = UnitGroupRolesAssigned(frame.unit)
	if role == "NONE" then
		return nil
	end
	
	return [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]]
end

function PitBull4_RoleIcon:GetExampleTexture(frame)
	return [[Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES]]
end

local tex_coords = {
	TANK = {0, 19/64, 22/64, 41/64},
	HEALER = {20/64, 39/64, 1/64, 20/64},
	DAMAGER = {20/64, 39/64, 22/64, 41/64},
}
-- for random examples
tex_coords[1] = tex_coords.TANK
tex_coords[2] = tex_coords.HEALER
tex_coords[3] = tex_coords.DAMAGER

function PitBull4_RoleIcon:GetTexCoord(frame)
	local role = UnitGroupRolesAssigned(frame.unit)
	local tex_coord = tex_coords[role]
	if not tex_coord then
		return nil
	end
	
	return tex_coord[1], tex_coord[2], tex_coord[3], tex_coord[4]
end

function PitBull4_RoleIcon:GetExampleTexCoord(frame)
	local role = UnitGroupRolesAssigned(frame.unit)
	local tex_coord = tex_coords[role] or tex_coords[math.random(1, 3)]
	
	return tex_coord[1], tex_coord[2], tex_coord[3], tex_coord[4]
end

function PitBull4_RoleIcon:PLAYER_ROLES_ASSIGNED()
	self:UpdateAll()
end
