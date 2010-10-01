if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass("player")) ~= "DRUID" or not PowerBarColor["ECLIPSE"] then
  return
end

-- CONSTANTS ----------------------------------------------------------------

local EPSILON = 1e-5

local border_path
do
  local module_path = _G.debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z0-9]-%.lua")
  border_path = "Interface\\AddOns\\" .. module_path .. "\\border"
end

-----------------------------------------------------------------------------

local L = PitBull4.L

local Eclipse = {}
local Eclipse_scripts = {}

-- if bg color is not set, it'll take on this variance of the normal color
local function normal_to_bg_color(r, g, b)
  return (r + 0.2)/3, (g + 0.2)/3, (b + 0.2)/3
end

function Eclipse:SetLunarColor(r, g, b)
  self.lunar_fg:SetVertexColor(r, g, b)
  local bgR, bgG, bgB = self.lunar_bgR, self.lunar_bgG, self.lunar_bgB
  if not bgR or not bgG or not bgB then
    bgR, bgG, bgB = normal_to_bg_color(r, g, b)
  end
  self.lunar_bg:SetVertexColor(bgR, bgG, bgB)
end

function Eclipse:GetLunarColor()
  local r, g, b = self.lunar_fg:GetVertexColor()
  return r, g, b
end

function Eclipse:SetLunarBackgroundColor(r, g, b)
  self.lunar_bgR, self.lunar_bgG, self.lunar_bgB = r or false, g or false, b or false
  self:SetLunarColor(self:GetLunarColor())
end

function Eclipse:GetLunarBackgroundColor()
  local r, g, b = self.lunar_bg:GetVertexColor()
  return r, g, b
end

function Eclipse:SetSolarColor(r, g, b)
  self.solar_fg:SetVertexColor(r, g, b)
  local bgR, bgG, bgB = self.solar_bgR, self.solar_bgG, self.solar_bgB
  if not bgR or not bgG or not bgB then
    bgR, bgG, bgB = normal_to_bg_color(r, g, b)
  end
  self.solar_bg:SetVertexColor(bgR, bgG, bgB)
end

function Eclipse:GetSolarColor()
  local r, g, b = self.solar_fg:GetVertexColor()
  return r, g, b
end

function Eclipse:SetSolarBackgroundColor(r, g, b)
  self.solar_bgR, self.solar_bgG, self.solar_bgB = r or false, g or false, b or false
  self:SetSolarColor(self:GetSolarColor())
end

function Eclipse:GetSolarBackgroundColor()
  local r, g, b = self.solar_bg:GetVertexColor()
  return r, g, b
end

function Eclipse:SetValue(value)
  local lunar_value, solar_value

  self.value = value

  if value == 0 then
    lunar_value, solar_value = EPSILON, EPSILON
    self.marker:SetPoint("CENTER")
  elseif value < 0 then
    lunar_value = value / -2
    solar_value = EPSILON
    self.marker:SetPoint("CENTER",self.lunar_fg,"LEFT")
  else -- value > 0
    lunar_value = EPSILON
    solar_value = value / 2
    self.marker:SetPoint("CENTER",self.solar_fg,"RIGHT")
  end

  local direction = GetEclipseDirection()
  if direction then
    self.marker:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS[direction]))
  end


  local width = self:GetWidth()
  self.lunar_fg:SetWidth(width * lunar_value)
  self.lunar_bg:SetTexCoord(0, 0, 0, 1, 1 - lunar_value, 0, 1 - lunar_value, 1)
  self.lunar_fg:SetTexCoord(1 - lunar_value, 0, 1 - lunar_value, 1, 0.5, 0, 0.5, 1)
  self.solar_fg:SetWidth(width * solar_value)
  self.solar_bg:SetTexCoord(0.5, 0, 0.5, 1, 1 - solar_value, 0, 1 - solar_value, 1)
  self.solar_bg:SetTexCoord(1 - solar_value, 0, 1 - solar_value, 1, 1, 0, 1, 1)
end

function Eclipse:GetValue()
  return self.value
end

function Eclipse:SetTexture(texture)
  self.lunar_fg:SetTexture(texture)
  self.lunar_bg:SetTexture(texture)
  self.solar_fg:SetTexture(texture)
  self.solar_bg:SetTexture(texture)
end

function Eclipse:GetTexture(texture)
  return self.lunar_fg:GetTexture()
end

function Eclipse:SetNormalAlpha(a)
  self.solar_fg:SetAlpha(a)
  self.lunar_fg:SetAlpha(a)
  if not self.bgA then
    self.solar_bg:SetAlpha(a)
    self.lunar_bg:SetAlpha(a)
  end
end

function Eclipse:GetNormalAlpha()
  return self.solar_fg:GetAlpha()
end

function Eclipse:SetBackgroundAlpha(a)
  self.bgA = a or false
  if not a then
    a = self.solar_fg:GetAlpha()
  end
  self.solar_bg:SetAlpha(a)
  self.lunar_bg:SetAlpha(a)
end

function Eclipse:GetBackgroundAlpha()
  return self.bgA or self.solar_fg:GetAlpha()
end

-- wrapper to do desaturation if SetDesaturated isn't supported.
local function set_desaturated(texture, desaturate)
  if not texture:SetDesaturated(desaturate) then
    if desaturate then
      texture:SetVertexColor(0.5, 0.5, 0.5)
    else
      texture:SetVertexColor(1, 1, 1)
    end
  end
end

function Eclipse:UpdateIcons(has_lunar, has_solar)
  if has_lunar then
    set_desaturated(self.solar_icon,true)
    self.solar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
    set_desaturated(self.solar_icon_border,true)
    set_desaturated(self.lunar_icon,false)
    self.lunar_icon_border:SetVertexColor(self:GetLunarColor())
  elseif has_solar then
    set_desaturated(self.solar_icon,false)
    self.solar_icon_border:SetVertexColor(self:GetSolarColor())
    set_desaturated(self.lunar_icon,true)
    self.lunar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
  else
    set_desaturated(self.solar_icon,true)
    self.solar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
    set_desaturated(self.lunar_icon,true)
    self.lunar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
  end
end

function Eclipse_scripts:OnUpdate()
  self:SetValue(UnitPower("player", SPELL_POWER_ECLIPSE)/UnitPowerMax("player",SPELL_POWER_ECLIPSE))
end

PitBull4.Controls.MakeNewControlType("Eclipse", "Frame", function(control)
  -- onCreate
  local lunar_fg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.lunar_fg = lunar_fg
  lunar_fg:SetPoint("RIGHT",control,"CENTER")
  lunar_fg:SetPoint("TOP")
  lunar_fg:SetPoint("BOTTOM")

  local lunar_bg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.lunar_bg = lunar_bg
  lunar_bg:SetPoint("RIGHT",lunar_fg,"LEFT")
  lunar_bg:SetPoint("TOP")
  lunar_bg:SetPoint("BOTTOM")
  lunar_bg:SetPoint("LEFT")

  local lunar_icon = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.lunar_icon = lunar_icon
  lunar_icon:SetPoint("RIGHT",control,"LEFT")
  lunar_icon:SetPoint("TOP")
  lunar_icon:SetPoint("BOTTOM")
  lunar_icon:SetTexture(GetSpellTexture(ECLIPSE_BAR_LUNAR_BUFF_ID))
  lunar_icon:SetWidth(38)
  lunar_icon:SetDesaturated(true)

  local lunar_icon_border = PitBull4.Controls.MakeTexture(control, "OVERLAY")
  control.lunar_icon_border = lunar_icon_border
  lunar_icon_border:SetAllPoints(lunar_icon)
  lunar_icon_border:SetTexture(border_path)

  local solar_fg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.solar_fg = solar_fg
  solar_fg:SetPoint("LEFT",control,"CENTER")
  solar_fg:SetPoint("TOP")
  solar_fg:SetPoint("BOTTOM")

  local solar_bg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.solar_bg = solar_bg
  solar_bg:SetPoint("LEFT",solar_fg,"RIGHT")
  solar_bg:SetPoint("TOP")
  solar_bg:SetPoint("BOTTOM")
  solar_bg:SetPoint("RIGHT")

  local solar_icon = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.solar_icon = solar_icon
  solar_icon:SetPoint("LEFT",control,"RIGHT")
  solar_icon:SetPoint("TOP")
  solar_icon:SetPoint("BOTTOM")
  solar_icon:SetTexture(GetSpellTexture(ECLIPSE_BAR_SOLAR_BUFF_ID))
  solar_icon:SetWidth(38)
  solar_icon:SetDesaturated(true)

  local solar_icon_border = PitBull4.Controls.MakeTexture(control, "OVERLAY")
  control.solar_icon_border = solar_icon_border
  solar_icon_border:SetAllPoints(solar_icon)
  solar_icon_border:SetTexture(border_path)

  local marker = PitBull4.Controls.MakeTexture(control, "OVERLAY")
  control.marker = marker
  marker:SetSize(38,38)
  marker:SetTexture([[Interface\PlayerFrame\UI-DruidEclipse]])
  marker:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS[GetEclipseDirection()]))
  marker:SetBlendMode("ADD")
  marker:ClearAllPoints()
  marker:SetPoint("CENTER",lunar_fg,"RIGHT",-2,0)

  for k, v in pairs(Eclipse) do
    control[k] = v
  end
  for k, v in pairs(Eclipse_scripts) do
    control:SetScript(k, v)
  end
end, function(control, id)
  -- onRetrieve
  control:SetLunarBackgroundColor()
  control:SetLunarColor(unpack(PitBull4.PowerColors.BALANCE_NEGATIVE_ENERGY))
  control:SetSolarBackgroundColor()
  control:SetSolarColor(unpack(PitBull4.PowerColors.BALANCE_POSITIVE_ENERGY))
  control:SetBackgroundAlpha()
  control:SetNormalAlpha(1)
end, function(control)
  -- onDelete
end)
