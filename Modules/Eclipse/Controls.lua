if select(6, GetAddOnInfo("PitBull4_" .. (debugstack():match("[o%.][d%.][u%.]les\\(.-)\\") or ""))) ~= "MISSING" then return end

if select(2, UnitClass("player")) ~= "DRUID" or not PowerBarColor["ECLIPSE"] then
  return
end

-- CONSTANTS ----------------------------------------------------------------

local EPSILON = 1e-5

local border_path, shine_path
do
  local module_path = _G.debugstack():match("[d%.][d%.][O%.]ns\\(.-)\\[A-Za-z0-9]-%.lua")
  border_path = "Interface\\AddOns\\" .. module_path .. "\\border"
  shine_path = "Interface\\AddOns\\" .. module_path .. "\\shine"
end

local SHINE_TIME = 1
local SHINE_HALF_TIME = SHINE_TIME / 2
local INVERSE_SHINE_HALF_TIME = 1 / SHINE_HALF_TIME

-----------------------------------------------------------------------------

local L = PitBull4.L
local PitBull4_Eclipse = PitBull4:GetModule("Eclipse")

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

local function rotate_to_vert(left, right, top, bottom)
  return left, bottom, right, bottom, left, top, right, top
end

local SetValue_orientation = {}
function SetValue_orientation:VERTICAL(value, direction, lunar_value, solar_value)
  if value == 0 then
    self.marker:SetPoint("CENTER")
  elseif value < 0 then
    self.marker:SetPoint("CENTER",self.lunar_fg,"TOP")
  else -- value > 0
    self.marker:SetPoint("CENTER",self.solar_fg,"BOTTOM")
  end

  local height = self:GetHeight()
  if self.icons then
    height = height - self:GetWidth() * 2
  end
  self.lunar_fg:SetHeight(height * lunar_value)
  self.lunar_bg:SetTexCoord(0, 1, 0.5 - lunar_value, 1, 0, 0, 0.5 - lunar_value, 0)
  self.lunar_fg:SetTexCoord(0.5 - lunar_value, 1, 0.5, 1, 0.5 - lunar_value, 0, 0.5, 0)
  self.solar_fg:SetHeight(height * solar_value)
  self.solar_fg:SetTexCoord(0.5, 1, 0.5 + solar_value, 1, 0.5, 0, 0.5 + solar_value, 0)
  self.solar_bg:SetTexCoord(0.5 + solar_value, 1, 1, 1, 0.5 + solar_value, 0, 1, 0)

  if direction then
    self.marker:SetTexCoord(rotate_to_vert(unpack(ECLIPSE_MARKER_COORDS[direction])))
  end
end

function SetValue_orientation:HORIZONTAL(value, direction, lunar_value, solar_value)
  if value == 0 then
    self.marker:SetPoint("CENTER")
  elseif value < 0 then
    self.marker:SetPoint("CENTER",self.lunar_fg,"LEFT")
  else -- value > 0
    self.marker:SetPoint("CENTER",self.solar_fg,"RIGHT")
  end

  local width = self:GetWidth()
  if self.icons then
    width = width - self:GetHeight() * 2
  end
  self.lunar_fg:SetWidth(width * lunar_value)
  self.lunar_bg:SetTexCoord(0, 0, 0, 1, 0.5 - lunar_value, 0, 0.5 - lunar_value, 1)
  self.lunar_fg:SetTexCoord(0.5 - lunar_value, 0, 0.5 - lunar_value, 1, 0.5, 0, 0.5, 1)
  self.solar_fg:SetWidth(width * solar_value)
  self.solar_fg:SetTexCoord(0.5, 0, 0.5, 1, 0.5 + solar_value, 0, 0.5 + solar_value, 1)
  self.solar_bg:SetTexCoord(0.5 + solar_value, 0, 0.5 + solar_value, 1, 1, 0, 1, 1)

  if direction then
    self.marker:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS[direction]))
  end
end

function Eclipse:SetValue(value)
  local lunar_value, solar_value
  local direction = GetEclipseDirection()

  self.value = value

  if value == 0 then
    lunar_value, solar_value = EPSILON, EPSILON
  elseif value < 0 then
    lunar_value = value / -2
    solar_value = EPSILON
  else -- value > 0
    lunar_value = EPSILON
    solar_value = value / 2
  end

  SetValue_orientation[self.orientation or "HORIZONTAL"](self, value, direction, lunar_value, solar_value)
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

function Eclipse:Shine(icon, r, g, b)
  local shine = self.shine
  if not shine then
    shine = PitBull4.Controls.MakeTexture(self, "OVERLAY")
    self.shine = shine
    shine:SetDrawLayer("OVERLAY",-1)
    shine:SetTexture(shine_path)
    shine:SetBlendMode("ADD")
    shine:SetAlpha(0)
    shine:SetAllPoints(icon)
    shine:SetVertexColor(r, g, b)
  end
  self.shine_time = 0
end

function Eclipse:UpdateIcons(has_lunar, has_solar)
  local solar_icon, lunar_icon = self.solar_icon, self.lunar_icon
  if not solar_icon or not lunar_icon then return end
  if self.has_lunar == has_lunar and self.has_solar == has_solar then return end
  self.has_lunar = has_lunar
  self.has_solar = has_solar
  local solar_icon_border = self.solar_icon_border
  local lunar_icon_border = self.lunar_icon_border
  if has_lunar then
    set_desaturated(solar_icon,true)
    solar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
    set_desaturated(solar_icon_border,true)
    set_desaturated(lunar_icon,false)
    lunar_icon_border:SetVertexColor(self:GetLunarColor())
    self:Shine(lunar_icon,self:GetLunarColor())
  elseif has_solar then
    set_desaturated(solar_icon,false)
    solar_icon_border:SetVertexColor(self:GetSolarColor())
    self:Shine(solar_icon,self:GetSolarColor())
    set_desaturated(lunar_icon,true)
    lunar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
  else
    set_desaturated(solar_icon,true)
    solar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
    set_desaturated(lunar_icon,true)
    lunar_icon_border:SetVertexColor(0.5, 0.5, 0.5)
  end
end

function Eclipse:EnableIcons(state)
  self.icons = state
  if state then
    self:CreateIcons()
    self:UpdateIcons(PitBull4_Eclipse:CheckForBuffs())
    self.solar_icon:Show()
    self.solar_icon_border:Show()
    self.lunar_icon:Show()
    self.lunar_icon_border:Show()
  else
    if self.solar_icon then
      self.solar_icon:Hide()
    end
    if self.solar_icon_border then
      self.solar_icon_border:Hide()
    end
    if self.lunar_icon then
      self.lunar_icon:Hide()
    end
    if self.lunar_icon_border then
      self.lunar_icon_border:Hide()
    end
  end
  self:SetOrientation(self.orientation or "HORIZONTAL")
end

function Eclipse:CreateIcons()
  local solar_icon = self.solar_icon
  if not solar_icon then
    solar_icon = PitBull4.Controls.MakeTexture(self, "BACKGROUND")
    self.solar_icon = solar_icon
    solar_icon:SetTexture(GetSpellTexture(ECLIPSE_BAR_SOLAR_BUFF_ID))
    solar_icon:SetDesaturated(true)
  end

  local solar_icon_border = self.solar_icon_border
  if not solar_icon_border then
    solar_icon_border = PitBull4.Controls.MakeTexture(self, "OVERLAY")
    self.solar_icon_border = solar_icon_border
    solar_icon_border:SetAllPoints(solar_icon)
    solar_icon_border:SetTexture(border_path)
  end

  local lunar_icon = self.lunar_icon
  if not lunar_icon then
    lunar_icon = PitBull4.Controls.MakeTexture(self, "BACKGROUND")
    self.lunar_icon = lunar_icon
    lunar_icon:SetTexture(GetSpellTexture(ECLIPSE_BAR_LUNAR_BUFF_ID))
    lunar_icon:SetDesaturated(true)
  end

  local lunar_icon_border = self.lunar_icon_border
  if not lunar_icon_border then
    lunar_icon_border = PitBull4.Controls.MakeTexture(self, "OVERLAY")
    self.lunar_icon_border = lunar_icon_border
    lunar_icon_border:SetAllPoints(lunar_icon)
    lunar_icon_border:SetTexture(border_path)
  end
end

local set_orientation_helper = {}

function set_orientation_helper:VERTICAL()
  if self.orientation ~= "VERTICAL" then
    local lunar_fg = self.lunar_fg
    lunar_fg:SetPoint("BOTTOM",self,"CENTER")
    lunar_fg:SetPoint("RIGHT")
    lunar_fg:SetPoint("LEFT")
    self.marker:SetPoint("CENTER",lunar_fg,"BOTTOM",0,-2)

    local lunar_bg = self.lunar_bg
    lunar_bg:SetPoint("BOTTOM",lunar_fg,"TOP")
    lunar_bg:SetPoint("RIGHT")
    lunar_bg:SetPoint("LEFT")

    local solar_fg = self.solar_fg
    solar_fg:SetPoint("TOP",self,"CENTER")
    solar_fg:SetPoint("RIGHT")
    solar_fg:SetPoint("LEFT")

    local solar_bg = self.solar_bg
    solar_bg:SetPoint("TOP",solar_fg,"BOTTOM")
    solar_bg:SetPoint("RIGHT")
    solar_bg:SetPoint("LEFT")
  end

  local width = self:GetWidth()
  self.marker:SetSize(width,width)
  if self.icons then
    local lunar_icon = self.lunar_icon
    lunar_icon:SetPoint("TOP")
    lunar_icon:SetPoint("RIGHT")
    lunar_icon:SetPoint("LEFT")
    self.lunar_icon:SetHeight(width)
    self.lunar_bg:SetPoint("TOP",self.lunar_icon,"BOTTOM")

    local solar_icon = self.solar_icon
    solar_icon:SetPoint("BOTTOM")
    solar_icon:SetPoint("RIGHT")
    solar_icon:SetPoint("LEFT")
    self.solar_icon:SetHeight(width)
    self.solar_bg:SetPoint("BOTTOM",self.solar_icon,"TOP")
  else
    self.lunar_bg:SetPoint("TOP")
    self.solar_bg:SetPoint("BOTTOM")
  end
end

function set_orientation_helper:HORIZONTAL()
  if self.orientation ~= "HORIZONTAL" then
    local lunar_fg = self.lunar_fg
    lunar_fg:SetPoint("RIGHT",self,"CENTER")
    lunar_fg:SetPoint("TOP")
    lunar_fg:SetPoint("BOTTOM")
    self.marker:SetPoint("CENTER",lunar_fg,"RIGHT",-2,0)

    local lunar_bg = self.lunar_bg
    lunar_bg:SetPoint("RIGHT",lunar_fg,"LEFT")
    lunar_bg:SetPoint("TOP")
    lunar_bg:SetPoint("BOTTOM")

    local solar_fg = self.solar_fg
    solar_fg:SetPoint("LEFT",self,"CENTER")
    solar_fg:SetPoint("TOP")
    solar_fg:SetPoint("BOTTOM")

    local solar_bg = self.solar_bg
    solar_bg:SetPoint("LEFT",solar_fg,"RIGHT")
    solar_bg:SetPoint("TOP")
    solar_bg:SetPoint("BOTTOM")
  end

  local height = self:GetHeight()
  self.marker:SetSize(height,height)
  if self.icons then
    local lunar_icon = self.lunar_icon
    lunar_icon:SetPoint("LEFT")
    lunar_icon:SetPoint("TOP")
    lunar_icon:SetPoint("BOTTOM")
    lunar_icon:SetWidth(height)
    self.lunar_bg:SetPoint("LEFT",lunar_icon,"RIGHT")

    local solar_icon = self.solar_icon
    solar_icon:SetPoint("RIGHT")
    solar_icon:SetPoint("TOP")
    solar_icon:SetPoint("BOTTOM")
    solar_icon:SetWidth(height)
    self.solar_bg:SetPoint("RIGHT",solar_icon,"LEFT")
  else
    self.lunar_bg:SetPoint("LEFT")
    self.solar_bg:SetPoint("RIGHT")
  end
end

function Eclipse:SetOrientation(orientation)
  if self.orientation ~= orientation then
    self.lunar_fg:ClearAllPoints()
    self.lunar_bg:ClearAllPoints()
    self.solar_fg:ClearAllPoints()
    self.solar_bg:ClearAllPoints()
    self.marker:ClearAllPoints()
  end
  if self.icons then
    self.lunar_icon:ClearAllPoints()
    self.solar_icon:ClearAllPoints()
  end
  set_orientation_helper[orientation](self)
  self.orientation = orientation
end

function Eclipse_scripts:OnUpdate(elapsed)
  local max = UnitPowerMax("player",SPELL_POWER_ECLIPSE)
  if max ~= 0 then
    self:SetValue(UnitPower("player", SPELL_POWER_ECLIPSE)/max)
  else
    self:SetValue(0)
  end

  if self.shine_time then
    local shine_time = self.shine_time + elapsed

    if shine_time > SHINE_TIME then
      self.shine_time = nil
      self.shine = self.shine:Delete()
      return
     end
     self.shine_time = shine_time

     if shine_time < SHINE_HALF_TIME then
       self.shine:SetAlpha(shine_time * INVERSE_SHINE_HALF_TIME)
     else
       self.shine:SetAlpha((SHINE_TIME - shine_time) * INVERSE_SHINE_HALF_TIME)
     end
  end
end

PitBull4.Controls.MakeNewControlType("Eclipse", "Frame", function(control)
  -- onCreate
  local lunar_fg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.lunar_fg = lunar_fg
  control.lunar_bg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.solar_fg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")
  control.solar_bg = PitBull4.Controls.MakeTexture(control, "BACKGROUND")

  local marker = PitBull4.Controls.MakeTexture(control, "OVERLAY")
  control.marker = marker
  marker:SetTexture([[Interface\PlayerFrame\UI-DruidEclipse]])
  marker:SetTexCoord(unpack(ECLIPSE_MARKER_COORDS[GetEclipseDirection() or "none"]))
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
  control:EnableIcons(false)
end, function(control)
  -- onDelete
end)
