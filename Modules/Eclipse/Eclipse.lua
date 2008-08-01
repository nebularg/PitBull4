if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

local PitBull4 = _G.PitBull4
if not PitBull4 then
  error("PitBull4_Eclipse requires PitBull4")
end

if select(2, UnitClass("player")) ~= "DRUID" or not PowerBarColor["ECLIPSE"] then
  return
end

-- CONSTANTS ----------------------------------------------------------------

-----------------------------------------------------------------------------

local L = PitBull4.L

local WIDTH = 216
local HEIGHT = 38

local LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
if not LibSharedMedia then
  LoadAddOn("LibSharedMedia-3.0")
  LibSharedMedia = LibStub("LibSharedMedia-3.0", true)
end

LoadAddOn("AceGUI-3.0-SharedMediaWidgets")
local AceGUI = LibStub("AceGUI-3.0")

local PitBull4_Eclipse= PitBull4:NewModule("Eclipse", "AceEvent-3.0")

PitBull4_Eclipse:SetModuleType("indicator")
PitBull4_Eclipse:SetName(L["Eclipse"])
PitBull4_Eclipse:SetDescription(L["Show Druid Eclipse Bar."])
PitBull4_Eclipse:SetDefaults({
  attach_to = "root",
  location = "out_top",
  position = 1,
  bar_size = 2,
  icons = true,
  orientation = "HORIZONTAL",
})
PitBull4_Eclipse.can_set_side_to_center = true

function PitBull4_Eclipse:UpdateFrame(frame)

  if frame.unit ~= "player" then
    return self:ClearFrame(frame)
  else
    local form = GetShapeshiftFormID()
    if (form and form ~= MOONKIN_FORM) or GetSpecialization() ~= 1 then
      return self:ClearFrame(frame)
    end
  end

  local eclipse = frame.Eclipse
  if not eclipse then
    eclipse = PitBull4.Controls.MakeEclipse(frame)
    frame.Eclipse = eclipse
    eclipse:SetFrameLevel(frame:GetFrameLevel() + 13)
  end

  local layout_db = self:GetLayoutDB(frame)

  eclipse:EnableIcons(layout_db.icons)

  if layout_db.side == "center" then
    -- When acting as a center bar let the layout engine determine our size,
    -- since we're treated as a normal bar.
    eclipse:SetSize(0,0)
  elseif layout_db.side then -- side is left or right
    -- left or right sides are treated as indicators but placed as bars,
    -- so we need to set our side
    eclipse:SetSize(HEIGHT,WIDTH)
    eclipse.height = WIDTH / HEIGHT 
  else
    -- Not positioned as a bar so we're on our own to update our anchors
    if layout_db.orientation == "VERTICAL" then
      eclipse:SetSize(HEIGHT,WIDTH)
      eclipse:SetOrientation("VERTICAL")
      eclipse.height = WIDTH / HEIGHT 
    else
      eclipse:SetSize(WIDTH,HEIGHT)
      eclipse:SetOrientation("HORIZONTAL")
      eclipse.height = 1
    end
  end

  local texture
  if LibSharedMedia then
    texture = LibSharedMedia:Fetch("statusbar", layout_db.texture or frame.layout_db.bar_texture or "Blizzard")
  end
 eclipse:SetTexture(texture or [[Interface\TargetingFrame\UI-StatusBar]])
  eclipse:SetLunarColor(unpack(PitBull4.PowerColors.BALANCE_NEGATIVE_ENERGY))
  eclipse:SetSolarColor(unpack(PitBull4.PowerColors.BALANCE_POSITIVE_ENERGY))

  eclipse:Show()

  return true
end

function PitBull4_Eclipse:ClearFrame(frame)
  local eclipse = frame.Eclipse
  if not eclipse then
    return false
  end
  frame.Eclipse = eclipse:Delete()

  return true
end

function PitBull4_Eclipse:UPDATE_SHAPESHIFT_FORM()
  for frame in PitBull4:IterateFramesForUnitID("player") do
    self:Update(frame)
  end
end
PitBull4_Eclipse.PLAYER_TALENT_UPDATE = PitBull4_Eclipse.UPDATE_SHAPESHIFT_FORM
PitBull4_Eclipse.MASTERY_UPDATE = PitBull4_Eclipse.UPDATE_SHAPESHIFT_FORM

function PitBull4_Eclipse:CheckForBuffs()
  local has_lunar, has_solar = false, false
  local i = 1
  while true do
    local name, _, _, _, _, _, _, _, _, _, spellID = UnitBuff("player", i)
    if not name then break end
    if spellID == ECLIPSE_BAR_SOLAR_BUFF_ID then
      has_solar = true
    elseif spellID == ECLIPSE_BAR_LUNAR_BUFF_ID then
      has_lunar = true
    end
    i = i + 1
  end
  return has_lunar, has_solar
end


function PitBull4_Eclipse:UNIT_AURA(event, unit)
  if unit == "player" then
    local has_lunar, has_solar = self:CheckForBuffs()
    for frame in PitBull4:IterateFramesForUnitID(unit) do
      local eclipse = frame.Eclipse
      if eclipse then
        eclipse:UpdateIcons(has_lunar, has_solar)
      end
    end
  end
end

function PitBull4_Eclipse:LibSharedMedia_Registered(event, mediatype, key)
  if mediatype == "statusbar" then
    self:UpdateAll()
  end
end

function PitBull4_Eclipse:OnEnable()
  self:RegisterEvent("UPDATE_SHAPESHIFT_FORM")
  self:RegisterEvent("PLAYER_TALENT_UPDATE")
  self:RegisterEvent("MASTERY_UPDATE")
  self:RegisterEvent("UNIT_AURA")
end

PitBull4_Eclipse:SetLayoutOptionsFunction(function (self)
  return 'texture', {
    type = 'select',
    name = L['Texture'],
    desc = L["What texture the status bar should use."] .. "\n" .. L["If you want more textures, you should install the addon 'SharedMedia'."],
    order = 1,
    get = function(info)
      return PitBull4.Options.GetLayoutDB(self).texture or PitBull4.Options.GetLayoutDB(false).bar_texture
    end,
    set = function(info, value)
      local default = PitBull4.Options.GetLayoutDB(false).bar_texture
      if value == default then
        value = nil
      end
      PitBull4.Options.GetLayoutDB(self).texture = value

      PitBull4.Options.UpdateFrames()
    end,
    values = function(info)
      return LibSharedMedia:HashTable("statusbar")
    end,
    hidden = function(info)
      return not LibSharedMedia
    end,
    dialogControl = AceGUI.WidgetRegistry["LSM30_Statusbar"] and "LSM30_Statusbar" or nil,
  }, 'icons', {
    type = 'toggle',
    name = L['Icons'],
    desc = L['Display icons for the eclipse buffs on the bar.'], 
    order = 2,
    get = function(info)
      return PitBull4.Options.GetLayoutDB(self).icons
    end,
    set = function(info, value)
      PitBull4.Options.GetLayoutDB(self).icons = value

      PitBull4.Options.UpdateFrames()
    end,
  }, 'orientation', {
    type = 'toggle',
    name = L['Vertical'],
    desc = L['Display the eclipse bar as a vertical bar instead of a horizontal bar.'],
    order = 3,
    get = function(info)
      return PitBull4.Options.GetLayoutDB(self).orientation == "VERTICAL"
    end,
    set = function(info, value)
      PitBull4.Options.GetLayoutDB(self).orientation = value and "VERTICAL" or "HORIZONTAL"

      PitBull4.Options.UpdateFrames()
    end,
    hidden = function(info, value)
      return not not PitBull4.Options.GetLayoutDB(self).side
    end,
  }
end)
