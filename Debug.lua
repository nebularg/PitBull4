--@alpha@
local function ptostring(value)
	if type(value) == "string" then
		return ("%q"):format(value)
	end
	return tostring(value)
end

local conditions = {}
local function helper(alpha, ...)
	for i = 1, select('#', ...) do
		if alpha == select(i, ...) then
			return true
		end
	end
	return false
end
conditions['inset'] = function(alpha, bravo)
	if type(bravo) == "table" then
		return bravo[alpha] ~= nil
	elseif type(bravo) == "string" then
		return helper(alpha, (";"):split(bravo))
	else
		error(("Bad argument #3 to `expect'. Expected %q or %q, got %q"):format("table", "string", type(bravo)))
	end
end
conditions['typeof'] = function(alpha, bravo)
	local type_alpha = type(alpha)
	if type_alpha == "table" and type(rawget(alpha, 0)) == "userdata" and type(alpha.IsObjectType) == "function" then
		type_alpha = 'frame'
	end
	return conditions['inset'](type_alpha, bravo)
end
conditions['frametype'] = function(alpha, bravo)
	if type(bravo) ~= "string" then
		error(("Bad argument #3 to `expect'. Expected %q, got %q"):format("string", type(bravo)), 3)
	end
	return type(alpha) == "table" and type(rawget(alpha, 0)) == "userdata" and type(alpha.IsObjectType) == "function" and alpha:IsObjectType(bravo)
end
conditions['match'] = function(alpha, bravo)
	if type(alpha) ~= "string" then
		error(("Bad argument #1 to `expect'. Expected %q, got %q"):format("string", type(alpha)), 3)
	end
	if type(bravo) ~= "string" then
		error(("Bad argument #3 to `expect'. Expected %q, got %q"):format("string", type(bravo)), 3)
	end
	return alpha:match(bravo)
end
conditions['=='] = function(alpha, bravo)
	return alpha == bravo
end
conditions['~='] = function(alpha, bravo)
	return alpha ~= bravo
end
conditions['>'] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha > bravo
end
conditions['>='] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha >= bravo
end
conditions['<'] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha < bravo
end
conditions['<='] = function(alpha, bravo)
	return type(alpha) == type(bravo) and alpha <= bravo
end

local t = {}
for k, v in pairs(conditions) do
	t[#t+1] = k
end
for _, k in ipairs(t) do
	conditions["not_" .. k] = function(alpha, bravo)
		return not conditions[k](alpha, bravo)
	end
end

function _G.expect(alpha, condition, bravo)
	if not conditions[condition] then
		error(("Unknown condition %s"):format(ptostring(condition)), 2)
	end
	if not conditions[condition](alpha, bravo) then
		error(("Expectation failed: %s %s %s"):format(ptostring(alpha), condition, ptostring(bravo)), 2)
	end
end
--@end-alpha@
