--- A Unit Frame created by PitBull4
-- @class table
-- @name UnitFrame
-- @field is_singleton whether the Unit Frame is a singleton or member
-- @field classification the classification of the Unit Frame
-- @field classificationDB the database table for the unit frame's classification
-- @field unitID the unitID of the Unit Frame. Can be nil.
-- @field guid the current GUID of the Unit Frame. Can be nil.
local UnitFrame = {}

local UnitFrame__scripts = {}

--- Add the proper functions and scripts to a SecureUnitButton
-- @param frame a Button which inherits from SecureUnitButton
-- @usage PitBull4.ConvertIntoUnitFrame(frame)
function PitBull4.ConvertIntoUnitFrame(frame)
	--@debug@
	if type(frame) ~= "table" or type(frame[0]) ~= "userdata" or type(frame.IsObjectType) ~= "function" then
		error(("Bad argument #1 to `ConvertIntoUnitFrame'. Expected %q, got %q."):format("frame", type(frame)))
	end
	if not frame:IsObjectType("Button") then
		error(("Bad argument #1 to `ConvertIntoUnitFrame'. Expected %q, got %q."):format("Button", frame:GetObjectType()))
	end
	--@end-debug@
	
	for k, v in pairs(UnitFrame__scripts) do
		frame:SetScript(k, v)
	end
	
	for k, v in pairs(UnitFrame) do
		frame[k] = v
	end
end

--- Update all details about the UnitFrame, possibly after a GUID change
-- @param sameGUID whether the previous GUID is the same as the current, at which point is less crucial to update
-- @usage frame:Update()
-- @usage frame:Update(true)
function UnitFrame:Update(sameGUID)
	-- TODO
	DEFAULT_CHAT_FRAME:AddMessage(("%s: Update(%s)"):format(self.unitID, tostring(sameGUID)))
end

--- Check the guid of the UnitFrame, if it is changed, then update the frame.
-- @param guid result from UnitGUID(unitID)
-- @param forceUpdate force an update even if the guid isn't changed, but is non-nil
-- @usage frame:UpdateGUID(UnitGUID(frame.unitID))
-- @usage frame:UpdateGUID(UnitGUID(frame.unitID), true)
function UnitFrame:UpdateGUID(guid)
	-- if the guids are the same, cut out, but don't if it's a wacky unit that has a guid.
	if self.guid == guid and not (guid and self.is_wacky) then
		return
	end
	local previousGUID = self.guid
	self.guid = guid
	self:Update(previousGUID == guid)
end
