local _G = _G
local PitBull4 = _G.PitBull4

PitBull4.L = setmetatable({}, {__index=function(self, key)
	self[key] = key
	return key
end})
