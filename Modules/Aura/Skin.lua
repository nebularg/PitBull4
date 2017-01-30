
local PitBull4 = _G.PitBull4
local PitBull4_Aura = PitBull4:GetModule("Aura")

local MSQ = LibStub("Masque", true)

-- Called from UpdateFrame to set the layout group and catch layout changes
function PitBull4_Aura:UpdateSkin(frame)
	if not MSQ then return end

	if not self.db.profile.global.skin then
		frame.masque_group = nil
		return
	end
	-- if the layout changed, remove the auras from the old group
	if frame.masque_group and frame.masque_group.Group ~= frame.layout then
		self:ClearAuras(frame)
		frame.masque_group = nil
	end
	if not frame.masque_group then
		frame.masque_group = MSQ:Group("PitBull4 Aura", frame.layout)
	end
end

function PitBull4_Aura:UpdateSkins()
	if not MSQ then return end

	MSQ:Group("PitBull4 Aura"):Delete()
	if self.db.profile.global.skin then
		-- Pre-populate the Masque groups so they're all available in
		-- options without opening the config/going into config mode.
		for layout_name in next, PitBull4.db.profile.layouts do
			MSQ:Group("PitBull4 Aura", layout_name)
		end
	end
end

if MSQ then
	-- Add skins similar to what PitBull uses without Masque.
	-- You can't raise the cooldown frame above the border, but that
	-- should be the only difference between using Masque or not.
	-- Too bad you can't set a default skin when registering a group :|
	MSQ:AddSkin("PitBull", {
		Template = "Blizzard",
		Icon = { TexCoords = {0, 1, 0, 1} },
		Normal = { Hide = true },
		Border = { Texture = [[Interface\AddOns\PitBull4\Modules\Aura\border]] },
	})
	MSQ:AddSkin("PitBull Zoomed", {
		Template = "Zoomed",
		Icon = { TexCoords = {0.07, 0.93, 0.07, 0.93} },
		Border = { Texture = [[Interface\AddOns\PitBull4\Modules\Aura\border]] },
	})

	PitBull4_Aura.OnProfileChanged_funcs[#PitBull4_Aura.OnProfileChanged_funcs+1] = PitBull4_Aura.UpdateSkins
end
