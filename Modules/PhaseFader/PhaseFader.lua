local PitBull4 = _G.PitBull4
local L = PitBull4.L

local PitBull4_PhaseFader = PitBull4:NewModule("PhaseFader","AceEvent-3.0")

PitBull4_PhaseFader:SetModuleType("fader")
PitBull4_PhaseFader:SetName(L["Phase fader"])
PitBull4_PhaseFader:SetDescription(L["Make the unit frame fade depending on the unit's phase."])
PitBull4_PhaseFader:SetDefaults({
	enabled = true,
	phased_opacity = 0.6,
	nonphased_opacity = 1.0
})

function PitBull4_PhaseFader:OnEnable()
	self:RegisterEvent("UNIT_PHASE")
	self:RegisterEvent("UNIT_FLAGS", "UNIT_PHASE")
end

function PitBull4_PhaseFader:UNIT_PHASE(event, unit)
	self:UpdateForUnitID(unit)
end

function PitBull4_PhaseFader:GetOpacity(frame)
	local unit = frame.unit
	if not unit then return end

	local layout_db = self:GetLayoutDB(frame)

	if UnitPhaseReason(unit) then
		return layout_db.phased_opacity
	else
		return layout_db.nonphased_opacity
	end
end

PitBull4_PhaseFader:SetLayoutOptionsFunction(function(self)
	return 'nonphased_opacity', {
		type = 'range',
		name = L["Same phase opacity"],
		desc = L["The opacity to display if the unit is in the same phase."],
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)

			return db.nonphased_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)

			db.nonphased_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}, 'phased_opacity', {
		type = 'range',
		name = L["Different phase opacity"],
		desc = L["The opacity to display if the unit is in a different phase."],
		min = 0,
		max = 1,
		isPercent = true,
		get = function(info)
			local db = PitBull4.Options.GetLayoutDB(self)

			return db.phased_opacity
		end,
		set = function(info, value)
			local db = PitBull4.Options.GetLayoutDB(self)

			db.phased_opacity = value

			PitBull4.Options.UpdateFrames()
			PitBull4:RecheckAllOpacities()
		end,
		step = 0.01,
		bigStep = 0.05,
	}
end)
