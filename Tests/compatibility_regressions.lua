local root = arg[1] or 'PitBull4/'
local passed = 0
local function check(condition, message)
    assert(condition, message)
    passed = passed + 1
end
local function equal(actual, expected, message)
    check(actual == expected, message or 'unexpected value')
end
local function close(actual, expected, message)
    check(type(actual) == 'number' and math.abs(actual - expected) < 1e-8, message or 'unexpected number')
end
local function load_in(path, env, ...)
    local chunk, message = loadfile(path, 't', env)
    assert(chunk, message)
    return chunk(...)
end
local function environment(project, expansion)
    local env = setmetatable({}, { __index = _G })
    env._G = env
    env.unpack = table.unpack
    env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC = 1, 2
    env.WOW_PROJECT_BURNING_CRUSADE_CLASSIC, env.WOW_PROJECT_WRATH_CLASSIC = 5, 11
    env.WOW_PROJECT_CATACLYSM_CLASSIC, env.WOW_PROJECT_MISTS_CLASSIC = 14, 19
    env.WOW_PROJECT_CAMELOT, env.WOW_PROJECT_ID = 18, project
    env.LE_EXPANSION_CLASSIC, env.LE_EXPANSION_MISTS_OF_PANDARIA = 0, 4
    env.LE_EXPANSION_CATACLYSM, env.LE_EXPANSION_WRATH_OF_THE_LICH_KING = 3, 2
    env.LE_EXPANSION_SHADOWLANDS = 8
    env.ClassicExpansionAtMost = function(level) return expansion <= level end
    env.ClassicExpansionAtLeast = function(level) return expansion >= level end
    env.GetClassicExpansionLevel = function() return expansion end
    env.GetExpansionLevel = function() return 11 end
    env.UnitName = function() return 'Tester' end
    env.Enum = { AddOnRestrictionType = { Combat = 0 }, AddOnRestrictionState = { Activating = 1, Active = 2 }, StatusBarInterpolation = { Immediate = 0, ExponentialEaseOut = 1 }, PowerType = { Mana = 0 } }
    env.C_RestrictedActions = { GetAddOnRestrictionState = function() return 2 end }
    env.C_EventUtils = { IsEventValid = function(event) return event ~= 'UNKNOWN_EVENT' and event ~= 'UNIT_HEALTH_FREQUENT' end }
    env.canaccessvalue = function(value) return not (type(value) == 'table' and value.opaque) end
    env.CurveConstants = { Reverse = { reverse = true } }
    return env
end
local function load_compat(env)
    local namespace = {}
    load_in(root .. 'Compat.lua', env, 'PitBull4', namespace)
    return namespace.Compat, namespace
end

for _, case in ipairs({ { 1, 11, 'mainline', false }, { 2, 0, 'vanilla', true }, { 5, 1, 'tbc', true }, { 14, 3, 'cata', true }, { 19, 4, 'mists', true }, { 18, 11, 'camelot', false }, { 999, 11, 'unknown', false } }) do
    local compat = load_compat(environment(case[1], case[2]))
    equal(compat.Client, case[3], 'client identity')
    equal(compat.IsClassic, case[4], 'Classic classification')
    if case[1] == 18 then
        equal(compat.ExpansionLevel, 0, 'Camelot gameplay routing')
        check(compat.HasRestrictionState, 'Camelot restriction capability')
    end
end

local env = environment(2, 0)
env.C_Spell = { GetSpellInfo = function() return { name = 'PartialNative', iconID = 12, spellID = 7 } end }
local compat = load_compat(env)
equal(compat.Spell.GetSpellName(7), 'PartialNative', 'partial namespace fallback')
equal(env.C_Spell.GetSpellName, nil, 'native namespaces remain untouched')
env.C_Spell.GetSpellName = function() return 'LaterMutation' end
equal(compat.Spell.GetSpellName(7), 'PartialNative', 'captured native function references')
local legacy_args, native_args
local legacy = environment(2, 0)
legacy.GetSpellInfo = function() return 'Legacy', '', 44, 1500, 0, 40, 123, 55 end
legacy.IsSpellInRange = function() return 0 end
legacy.GetSpellCooldown = function() return 10, 2, 1, 0.9 end
legacy.GetAddOnEnableState = function(...) legacy_args = { ... }; return 2 end
local private = load_compat(legacy)
equal(private.Spell.IsSpellInRange('Legacy', 'target'), false, 'numeric zero is out of range')
local cd = private.Spell.GetSpellCooldown(123)
equal(cd.startTime, 10, 'cooldown table start')
equal(cd.duration, 2, 'cooldown table duration')
equal(cd.isEnabled, true, 'cooldown enabled flag')
equal(cd.modRate, 0.9, 'cooldown rate')
equal(private.Spell.GetSpellIDForSpellIdentifier('Legacy'), 123, 'legacy spell ID')
equal(private.AddOns.GetAddOnEnableState('PitBull4', 'Character'), 2)
equal(legacy_args[1], 'Character', 'legacy addon argument order')
equal(legacy_args[2], 'PitBull4', 'legacy addon argument order')
local native = environment(1, 11)
native.C_AddOns = { GetAddOnEnableState = function(...) native_args = { ... }; return 1 end }
local nc = load_compat(native)
equal(nc.AddOns.GetAddOnEnableState('PitBull4', 'Character'), 1)
equal(native_args[1], 'PitBull4', 'native addon argument order')
equal(native_args[2], 'Character', 'native addon argument order')
local event_calls = 0
check(not nc.RegisterOptionalEvent({ RegisterEvent = function() event_calls = event_calls + 1 end }, 'UNKNOWN_EVENT'))
equal(event_calls, 0, 'invalid optional event was not registered')
check(nc.RegisterOptionalEvent({ RegisterEvent = function() event_calls = event_calls + 1 end }, 'UNIT_HEALTH'))
equal(event_calls, 1, 'valid optional event registered')

local Methods = {}
local function widget(parent)
    return setmetatable({ parent = parent, width = 200, height = 20, alpha = 1, points = {}, scripts = {}, color = {1,1,1,1}, shown = true }, { __index = Methods })
end
function Methods:GetWidth() return self.all_points and self.all_points:GetWidth() or self.width end
function Methods:GetHeight() return self.all_points and self.all_points:GetHeight() or self.height end
function Methods:SetWidth(v) self.width = v end
function Methods:SetHeight(v) self.height = v end
function Methods:SetSize(w,h) self.width,self.height=w,h; if self.scripts.OnSizeChanged then self.scripts.OnSizeChanged(self,w,h) end end
function Methods:GetParent() return self.parent end
function Methods:SetParent(p) self.parent = p end
function Methods:SetAllPoints(p) self.all_points = p end
function Methods:SetPoint(...) self.points[#self.points+1] = { ... } end
function Methods:ClearAllPoints() self.points = {}; self.all_points=nil end
function Methods:SetScript(k,v) self.scripts[k]=v end
function Methods:Show() self.shown=true end
function Methods:Hide() self.shown=false end
function Methods:SetAlpha(v) self.alpha=v end
function Methods:GetAlpha() return self.alpha end
function Methods:SetTexture(v) self.texture=v; self.atlas=nil end
function Methods:GetTexture() return self.texture end
function Methods:SetAtlas(v)
    assert(type(v)=='string' and v~='', 'Texture:SetAtlas requires a nonempty atlas name')
    self.atlas=v
    self.texture='AtlasAsset:'..v
end
function Methods:GetAtlas() return self.atlas end
function Methods:SetVertexColor(...) self.color={...} end
function Methods:GetVertexColor() return table.unpack(self.color) end
function Methods:SetMinMaxValues(minimum,maximum) self.native_min,self.native_max=minimum,maximum end
function Methods:SetValue(v, interpolation) self.native_value=v; self.native_interpolation=interpolation end
function Methods:GetValue() return self.native_value end
function Methods:SetStatusBarColor(...) self.native_color={...} end
function Methods:GetStatusBarColor() return table.unpack(self.native_color or {1,1,1,1}) end
function Methods:SetStatusBarTexture(v) self.native_texture=v end
function Methods:SetOrientation(v) self.native_orientation=v end
function Methods:SetReverseFill(v) self.native_reverse=v end
function Methods:Delete() if self.on_delete then self.on_delete(self) end; self.deleted=true; return nil end
function Methods:Play() self.playing=true end
function Methods:Stop() self.playing=false end
function Methods:IsPlaying() return self.playing or false end
function Methods:GetProgress() return 0 end
function Methods:GetDuration() return self.duration or 0 end
function Methods:SetDuration(v) self.duration=v end
function Methods:GetAnimations() end
function Methods:CreateAnimation() return widget(self) end
function Methods:CreateAnimationGroup() return widget(self) end
for _, name in ipairs({'EnableMouse','SetTexCoord','SetDrawLayer','SetClipsChildren','SetDesaturated','SetHorizTile','SetVertTile','SetBlendMode','SetLooping','SetOrder','SetSmoothing','SetStartDelay','SetEndDelay','SetFromAlpha','SetToAlpha','RegisterEvent','RegisterUnitEvent','UnregisterEvent','UnregisterAllEvents'}) do
    Methods[name] = function() end
end

local function addon_environment(project, expansion)
    local e = environment(project or 1, expansion or 11)
    e.CreateFrame = function(_,_,parent) return widget(parent) end
    e.wipe = function(t) for k in pairs(t) do t[k] = nil end end
    e.GetTime = function() return 0 end
    local c = load_compat(e)
    local pb = { Compat = c, Controls = {}, Utils = {}, modules = {}, world_ready = true, wow_retail = c.IsRetail }
    e.PitBull4 = pb
    pb.L = setmetatable({}, { __index = function(_,k) return k end })
    pb.Utils.IsValueAccessible = c.IsValueAccessible
    pb.Utils.SafeNumber = function(v, default) if not c.IsValueAccessible(v) then return default end; return type(v)=='number' and v or default end
    pb.Utils.FrameHasUnit = function(f) return f.guid ~= nil or f.unit_identity_token ~= nil end
    pb.Utils.SafeGUID = function(v) return c.IsValueAccessible(v) and v or nil end
    pb.Utils.SafeBoolean = function(v,default) if not c.IsValueAccessible(v) then return default end; return type(v)=='boolean' and v or default end
    pb.new = function() return {} end
    pb.del = function() return nil end
    function pb:IsInConfigMode() return self.config_mode or false end
    function pb:HasRestrictedUnitData() return self.restricted or false end
    local Module = {}
    function Module:SetDefaults(layout,global) self.layout = layout or {}; self.db={profile={global=global or {}}} end
    function Module:GetLayoutDB() return self.layout end
    for _, name in ipairs({'SetModuleType','SetName','SetDescription','SetColorOptionsFunction','SetLayoutOptionsFunction','RegisterEvent','UpdateAll','UpdateForUnitID','RegisterUnitEvent'}) do Module[name]=function() end end
    function pb:NewModule(name) local m=setmetatable({id=name},{__index=Module}); self.modules[name]=m; return m end
    function pb:GetModule(name) return self.modules[name] end
    local control = pb.Controls
    function control.MakeTexture(parent) return widget(parent) end
    function control.MakeAnimatedTexture(parent) local w=widget(parent); w.ag=widget(w); return w end
    function control.MakeAlpha(parent) return widget(parent) end
    function control.MakeAnimation(parent) return widget(parent) end
    function control.MakeNewControlType(name, kind, create, retrieve, delete)
        control['Make'..name]=function(parent)
            local w=widget(parent); w.kind=name
            create(w); w.on_delete=delete; w.on_retrieve=retrieve
            if retrieve then retrieve(w) end
            return w
        end
    end
    return e,pb
end

local e,pb = addon_environment()
load_in(root..'Controls/BetterStatusBar.lua',e)
local bar=pb.Controls.MakeLiveStatusBar(widget())
equal(bar:GetTexture(), [[Interface\TargetingFrame\UI-StatusBar]], 'native control texture contract')
bar:SetColor(0.2,0.3,0.4)
local r,g,b=bar:GetColor(); close(r,0.2);close(g,0.3);close(b,0.4)
local nr,ng,nb=bar:GetStatusBarColor();close(nr,r);close(ng,g);close(nb,b)
bar:SetRawValue(50,100)
check(bar.public_values and bar.public_bar.shown, 'public renderer is selected')
close(bar:GetValue(),0.5)
close(bar.fg:GetWidth(),100,'public fill endpoint')
bar:SetDeficit(true)
bar:SetRawValue(25,100)
close(bar.fg:GetWidth(),150,'public deficit fill')
bar:SetReverse(true);equal(bar.public_bar.reverse,true,'public reverse')
bar:SetOrientation('VERTICAL');equal(bar.public_bar.orientation,'VERTICAL')
bar:SetAnimated(true);equal(bar.public_bar:GetAnimated(),true)
bar:SetFade(true);equal(bar.public_bar:GetFade(),true)
bar:SetAnimDuration(0.25);close(bar.public_bar:GetAnimDuration(),0.25)
bar:SetExtraValue(0.1);close(bar:GetExtraValue(),0.1)
bar:SetIcon(77);bar:SetSize(18,100);equal(bar.icon:GetWidth(),18,'icon size follows vertical thickness')
local operations=0
local opaque=setmetatable({opaque=true},{__tostring=function() operations=operations+1;error('opaque tostring') end,__div=function() operations=operations+1;error('opaque division') end,__add=function() operations=operations+1;error('opaque add') end,__lt=function() operations=operations+1;error('opaque compare') end,__le=function() operations=operations+1;error('opaque compare') end})
local requested_deficit
bar.raw_module={GetNativeValue=function(_,_,deficit) requested_deficit=deficit;return opaque end}
bar.raw_frame={unit='target'}
bar:SetRawValue(opaque,opaque)
check(not bar.public_values and not bar.public_bar.shown and bar.barTexture.shown, 'opaque native renderer')
equal(bar.native_value,opaque,'opaque value sent directly to native sink')
equal(bar.native_max,1,'native deficit is normalized by API')
equal(requested_deficit,true,'native reverse curve requested')
equal(bar.native_interpolation,1,'native interpolation')
equal(operations,0,'no opaque arithmetic/formatting')
bar:SetDeficit(false)
equal(requested_deficit,false,'native ordinary fraction requested')
bar.raw_module=nil
bar:SetRawValue(opaque,opaque)
equal(bar.native_max,opaque,'raw native maximum retained')
bar:SetRawValue(75,100)
check(bar.public_values,'returns to public geometry')
equal(bar.public_bar:GetAnimated(),true,'animation settings recover after protection')
equal(bar.public_bar:GetFade(),true,'fade settings recover after protection')
close(bar:GetValue(),0.75)
bar:Delete();equal(bar.raw_current,nil,'pooled raw values cleared');equal(bar.raw_frame,nil,'pooled frame reference cleared')

-- Era's native texture API rejects nil atlas names. Exercise resets and reuse.
for _, project in ipairs({2, 1, 19, 18}) do
    local te,tpb=addon_environment(project,project==2 and 0 or 11)
    load_in(root..'Controls/BetterStatusBar.lua',te)
    local normal=tpb.Controls.MakeBetterStatusBar(widget())
    normal:SetTexture('CustomBar')
    normal:SetAtlas('UnitHealth')
    equal(normal:GetAtlas(),'UnitHealth','public atlas retained')
    normal:SetAtlas(nil)
    equal(normal:GetAtlas(),nil,'public atlas cleared through texture API')
    equal(normal:GetTexture(),'CustomBar','public custom texture restored')
    equal(normal.bg:GetTexture(),'CustomBar','background texture preserved')
    normal:SetTexture('AtlasAsset:UnitHealth')
    normal:SetAtlas('UnitHealth')
    normal:SetTexture('AtlasAsset:UnitHealth')
    equal(normal:GetAtlas(),nil,'matching underlying asset still clears atlas')
    normal:SetAtlas('UnitHealth')
    normal.on_retrieve(normal)
    equal(normal:GetAtlas(),nil,'pooled public atlas cleared safely')
    equal(normal:GetTexture(),'AtlasAsset:UnitHealth','pooled public texture restored')

    local live_bar=tpb.Controls.MakeLiveStatusBar(widget())
    live_bar:SetTexture('CustomBar')
    live_bar:SetAtlas('UnitHealth')
    equal(live_bar.barTexture:GetAtlas(),'UnitHealth','native atlas retained')
    equal(live_bar.public_bar:GetAtlas(),'UnitHealth','public native-wrapper atlas retained')
    live_bar:SetAtlas(nil)
    equal(live_bar.barTexture:GetAtlas(),nil,'native-wrapper atlas cleared')
    equal(live_bar.public_bar:GetTexture(),'CustomBar','native-wrapper public texture restored')
    equal(live_bar.barTexture:GetTexture(),'CustomBar','native-wrapper native texture restored')
    live_bar:SetAtlas('UnitHealth')
    live_bar:SetTexture('OtherBar')
    equal(live_bar.public_bar:GetAtlas(),nil,'new texture clears public atlas')
    equal(live_bar.barTexture:GetAtlas(),nil,'new texture clears native atlas')
    live_bar:SetAtlas('UnitHealth')
    live_bar:SetRawValue(opaque,opaque)
    equal(live_bar.barTexture:GetAtlas(),'UnitHealth','atlas survives protected transition')
    live_bar:SetRawValue(50,100)
    equal(live_bar.public_bar:GetAtlas(),'UnitHealth','atlas survives readable transition')
    live_bar.on_retrieve(live_bar)
    equal(live_bar.barTexture:GetAtlas(),nil,'pooled live atlas cleared safely')
    equal(live_bar.public_bar:GetTexture(),[[Interface\TargetingFrame\UI-StatusBar]],'pooled live texture restored')
end

local he,hpb=addon_environment()
local state={current=100,maximum=100,percent=1,dead=false,connected=true}
he.UnitHealth=function() return state.current end
he.UnitHealthMax=function() return state.maximum end
he.UnitHealthPercent=function(_,_,curve) if curve then return opaque end;return state.percent end
he.UnitIsConnected=function() return state.connected end
he.UnitIsDeadOrGhost=function() return state.dead end
he.UnitIsTapDenied=function() return false end
load_in(root..'Modules/HealthBar/HealthBar.lua',he)
local health=hpb:GetModule('HealthBar')
local frame={unit='target',guid='public'}
close(health:GetValue(frame),1,'full health fraction')
state.current,state.percent=50,0.5
close(health:GetValue(frame),0.5,'half health fraction')
local hr,hg,hb=health:GetColor(frame,health:GetValue(frame));close(hr,1);close(hg,1);close(hb,0)
state.current,state.percent=0,0
close(health:GetValue(frame),0,'zero health fraction')
state.current,state.maximum,state.percent=opaque,opaque,opaque
equal(health:GetValue(frame),nil,'unknown health is not reported as full')
equal(operations,0,'health does not format or divide opaque values')
local hc,hm=health:GetRawValue(frame);equal(hc,opaque);equal(hm,opaque)
equal(health:GetNativeValue(frame,true),opaque,'native reversed health fraction')
state.dead=true
local dc,dm=health:GetRawValue(frame);equal(dc,1);equal(dm,1)
equal(health:GetValue(frame),1,'dead state remains visible')
local dr,dg,db=health:GetColor(frame,1);close(dr,0.6);close(dg,0.6);close(db,0.6)
state.dead=false;state.connected=false
local cc,cm=health:GetRawValue(frame);equal(cc,1);equal(cm,1)
local cr,cg,cb=health:GetColor(frame,1);close(cr,0.7);close(cg,0.7);close(cb,0.7)

local ve,vpb=addon_environment()
ve.UnitHealth=function() return 50 end;ve.UnitHealthMax=function() return 100 end
ve.UnitGetIncomingHeals=function(_,who) return who and 10 or 30 end
ve.UnitGetTotalAbsorbs=function() return 15 end
load_in(root..'Controls/BetterStatusBar.lua',ve)
load_in(root..'Modules/VisualHeal/VisualHeal.lua',ve)
local visual=vpb:GetModule('VisualHeal')
local vf={unit='target',guid='guid'}
vf.HealthBar=vpb.Controls.MakeLiveStatusBar(widget())
vf.HealthBar:SetRawValue(50,100)
vpb.config_mode=true
check(visual:UpdateFrame(vf),'VisualHeal configuration example')
check(vf.VisualHeal~=nil,'configuration overlay created')
vpb.config_mode=false
check(visual:UpdateFrame(vf),'VisualHeal live overlay')
close(vf.VisualHeal:GetValue(),0.2,'other-player healing fraction')
close(vf.VisualHeal:GetExtraValue(),0.1,'player healing fraction')
close(vf.VisualHeal:GetExtra2Value(),0.15,'absorb fraction')
local anchor=vf.VisualHeal.points[#vf.VisualHeal.points]
equal(anchor[2],vf.HealthBar.fg,'overlay attaches to fill endpoint')
vf.HealthBar:SetRawValue(opaque,opaque)
check(visual:UpdateFrame(vf),'protected overlay is cleared')
equal(vf.VisualHeal,nil,'overlay skips opaque geometry')
vf.HealthBar:SetRawValue(40,100)
check(visual:UpdateFrame(vf),'overlay recovers after protected transition')
local old=vf.VisualHeal
vf.HealthBar=vpb.Controls.MakeLiveStatusBar(widget())
vf.HealthBar:SetRawValue(50,100)
check(visual:UpdateFrame(vf),'overlay survives control replacement')
check(old.deleted,'old overlay parent is released')
equal(vf.VisualHeal:GetParent(),vf.HealthBar,'overlay is reparented to replacement')

-- Execute the real shared update handler with the health module.
local ie,ipb=addon_environment()
local live={current=50,maximum=100,percent=0.5,dead=false}
ie.UnitHealth=function() return live.current end
ie.UnitHealthMax=function() return live.maximum end
ie.UnitHealthPercent=function() return live.percent end
ie.UnitIsConnected=function() return true end
ie.UnitIsDeadOrGhost=function() return live.dead end
ie.UnitIsTapDenied=function() return false end
ie.UnitIsPlayer=function() return false end
ie.UnitInPartyIsAI=function() return false end
ie.LibStub=function() return nil end
ipb.module_types={}
function ipb:NewModuleType(name,defaults)
    local proto={defaults=defaults}
    self.module_types[name]=proto
    return proto
end
load_in(root..'Controls/BetterStatusBar.lua',ie)
load_in(root..'ModuleHandling/BarModules.lua',ie)
load_in(root..'Modules/HealthBar/HealthBar.lua',ie)
local ih=ipb:GetModule('HealthBar')
local proto=ipb.module_types.bar
ih.GetTexture,ih.ClearFrame=proto.GetTexture,proto.ClearFrame
setmetatable(ih.layout,{__index=proto.defaults})
ih.layout.hostility_color_npcs=false
ih.layout.hostility_color=false
ih.layout.color_by_class=false
local inf={unit='target',guid='guid',layout_db={}}
check(proto.UpdateFrame(ih,inf),'shared handler creates a stable raw control')
local stable=inf.HealthBar
close(stable:GetValue(),0.5,'handler retains health fraction')
local sr,sg,sb=stable:GetColor();close(sr,1);close(sg,1);close(sb,0)
live.current,live.maximum,live.percent=opaque,opaque,opaque
ipb.restricted=true
proto.UpdateFrame(ih,inf)
equal(inf.HealthBar,stable,'same control during protected transition')
check(not stable.public_values,'shared handler selects native display')
equal(stable.native_value,opaque,'shared handler passes opaque percent to sink')
live.dead=true
proto.UpdateFrame(ih,inf)
equal(inf.HealthBar,stable,'same control during death')
check(stable.public_values,'readable death placeholder')
close(stable:GetValue(),1,'death placeholder visible')
live.dead=false;live.current,live.maximum,live.percent=100,100,1
ipb.restricted=false
proto.UpdateFrame(ih,inf)
equal(inf.HealthBar,stable,'same control during resurrection')
close(stable:GetValue(),1,'resurrected fraction')
ipb.config_mode=true
proto.UpdateFrame(ih,inf)
close(stable:GetValue(),0.8,'configuration uses example without querying opaque arithmetic')
equal(operations,0,'shared bar handler never formatted opaque values')

local pe,ppb=addon_environment()
local ps={current=60,maximum=100,type=0}
pe.PowerBarColor={MANA={r=0,g=0,b=1}}
ppb.PowerColors={MANA={0,0,1}}
pe.UnitPowerType=function() return ps.type,'MANA' end
pe.UnitPower=function() return ps.current end
pe.UnitPowerMax=function() return ps.maximum end
pe.UnitPowerPercent=function(_,power_type,_,curve) check(power_type==nil and curve~=nil,'native power percentage request');return opaque end
load_in(root..'Modules/PowerBar/PowerBar.lua',pe)
local power=ppb:GetModule('PowerBar')
local pf={unit='player',guid='guid'}
close(power:GetValue(pf),0.6,'public power ratio')
power.layout.hide_no_power=true;ps.maximum=0
local pc,pm=power:GetRawValue(pf);equal(pc,nil);equal(pm,nil,'hide-no-power raw path')
ps.maximum=100;ps.type=3;power.layout.hide_no_mana=true
pc,pm=power:GetRawValue(pf);equal(pc,nil,'hide-non-mana raw path')
ps.type=0;ps.current,ps.maximum=opaque,opaque
ppb.restricted=true
pc,pm=power:GetRawValue(pf);equal(pc,opaque);equal(pm,opaque)
equal(power:GetNativeValue(pf,true),opaque,'native power deficit')
equal(operations,0,'power does not stringify opaque values')

local ae,apb=addon_environment(2,0)
ae.UnitClassBase=function() return 'DRUID',11 end
local mana={current=50,maximum=100}
ae.UnitPowerType=function() return 3 end
ae.UnitPower=function() return mana.current end
ae.UnitPowerMax=function() return mana.maximum end
ae.UnitHasVehiclePlayerFrameUI=function() return false end
apb.PowerColors={MANA={0,0,1}}
load_in(root..'Modules/AltManaBar/AltManaBar.lua',ae)
local alt=apb:GetModule('DruidManaBar')
alt.layout.hide_if_full=true
local ac,am=alt:GetRawValue(pf);equal(ac,50);equal(am,100)
mana.current=100
ac,am=alt:GetRawValue(pf);equal(ac,nil,'full alternate mana hidden in raw path');equal(am,nil)
equal(alt:GetValue(pf),nil,'full alternate mana hidden in public path')
mana.current=90
ac,am=alt:GetRawValue(pf);equal(ac,90,'alternate mana returns after use')

local af=assert(io.open(root..'Modules/Aura/Update.lua','rb'))
local aura_source=af:read('*a');af:close()
local normalize=assert(aura_source:match('(local function normalize_aura_entry%(.-\n\treturn entry\nend)'))
local legacy_aura_calls=0
local normalization_env={_G={UnitAura=function() legacy_aura_calls=legacy_aura_calls+1;error('deprecation fallback disabled') end},safe_boolean=function(v) return v end,safe_number=function(v) return v end,safe_string=function(v) return v end,safe_dispel_name=function(v) return v end,is_aura_mine=function() return false end,SafeBoolean=function(v,default) if v==nil then return default end;return v end}
local normalize_fn=assert(load(normalize..'\nreturn normalize_aura_entry','native aura normalization','t',normalization_env))()
local aura={name='Aura',spellId=42,points={true}}
normalize_fn(aura,'player',1,'HELPFUL',true)
equal(legacy_aura_calls,0,'aura normalization does not call optional UnitAura')
equal(aura.shouldConsolidate,false,'aura points are not consolidation flags')
local preserved={name='Aura',spellId=42,shouldConsolidate=true}
normalize_fn(preserved,'player',1,'HELPFUL',true)
equal(preserved.shouldConsolidate,true,'native consolidation flag preserved')

-- Execute the real aura filter initializer and saved-profile migration.
local function load_aura_filters(project, expansion, legacy_api)
    local fe,fpb=addon_environment(project,expansion)
    local absent=project==2 and {[28880]=true,[34976]=true} or {}
    local missing_name_calls, warnings=0,0
    local function spell_name(id)
        if absent[id] then
            missing_name_calls=missing_name_calls+1
            error('name lookup for unavailable spell '..id)
        end
        return 'Spell'..id
    end
    if legacy_api then
        fe.C_Spell=nil
        fe.GetSpellInfo=function(id)
            if not absent[id] then return spell_name(id),'',44,0,0,40,id end
        end
    else
        fe.C_Spell={DoesSpellExist=function(id) return not absent[id] end,GetSpellName=spell_name}
    end
    fpb.Compat=load_compat(fe)
    fpb.DEBUG=true
    fpb.db={global={}}
    fe.UnitClassBase=function() return 'WARRIOR' end
    fe.UnitRace=function() return 'Human','Human' end
    fe.UnitFactionGroup=function() return 'Alliance' end
    fe.LE_EXPANSION_BURNING_CRUSADE=1
    fe.LE_EXPANSION_LEGION,fe.LE_EXPANSION_BATTLE_FOR_AZEROTH,fe.LE_EXPANSION_DRAGONFLIGHT=6,7,9
    fe.CLASS_SORT_ORDER={'WARRIOR','DRUID','HUNTER','MAGE','PALADIN','PRIEST','ROGUE','SHAMAN','WARLOCK'}
    fe.LibStub=function() return nil end
    local filter=fpb:NewModule('Aura')
    filter.OnProfileChanged_funcs={}
    filter.db={profile={global={filters={Example={name_list={[28880]=true,[34976]=true,[139]=true}}}}}}
    function filter:Printf() warnings=warnings+1 end
    load_in(root..'Modules/Aura/Filter.lua',fe)
    equal(filter.friend_buffs.Human.Spell23333,true,'available aura filter retained')
    for _, callback in ipairs(filter.OnProfileChanged_funcs) do callback(filter) end
    local migrated=filter.db.profile.global.filters.Example.name_list
    equal(migrated.Spell139,true,'available saved spell ID converted to name')
    equal(migrated[139],nil,'saved numeric spell ID removed after migration')
    equal(missing_name_calls,0,'unavailable spells never reach native name lookup')
    equal(warnings,0,'shared cross-client spell lists do not print invalid ID warnings')
    if project==2 then
        equal(filter.friend_buffs.Draenei.Spell28880,nil,'Era omits unavailable racial aura')
        equal(filter.extra_buffs.Spell34976,nil,'Era omits unavailable Netherstorm aura')
        equal(migrated.Spell28880,nil,'Era migration skips unavailable racial aura')
        equal(migrated.Spell34976,nil,'Era migration skips unavailable Netherstorm aura')
    else
        equal(filter.friend_buffs.Draenei.Spell28880,true,'supported client retains racial aura')
        equal(filter.extra_buffs.Spell34976,true,'supported client retains Netherstorm aura')
        equal(migrated.Spell28880,true,'supported profile retains racial aura')
        equal(migrated.Spell34976,true,'supported profile retains Netherstorm aura')
    end
end
load_aura_filters(2,0,false)
load_aura_filters(2,0,true)
load_aura_filters(5,1,false)
load_aura_filters(19,4,false)
load_aura_filters(1,11,false)

print('PASS '..passed..' focused regression assertions (Lua '.._VERSION..').')
