-- Execute the real module. In-game secure/taint validation remains necessary.
local root, passed = arg[1] or "PitBull4/", 0
local function check(v,label) assert(v,label); passed=passed+1 end
local function fixture(classic,expansion,options)
    local e=setmetatable({},{__index=_G}); e._G=e; e.LE_EXPANSION_CATACLYSM=3
    e.ClassicExpansionAtLeast=function(n) return expansion>=n end
    e.InCombatLockdown=function() return e.combat end
    e.UnregisterUnitWatch=function() error("unit watch removed") end
    e.CompactRaidFrameManager_SetSetting=function() error("raid settings overwritten") end
    local frames,hooks,notices,registered={},{},{},{}
    local function make(parent,shown)
        local f={parent=parent,shown=shown~=false,alpha=1,mouse=true,events={UNIT_HEALTH=true},hooks={},scripts={}}
        frames[#frames+1]=f
        function f:Post(n,...) for _,cb in ipairs(self.hooks[n] or {}) do cb(self,...) end end
        function f:Guard() assert(not e.combat or e.native,"protected mutation in combat") end
        function f:GetParent() return self.parent end
        function f:IsShown() return self.shown end
        function f:IsVisible() return self.shown and (not self.parent or self.parent:IsVisible()) end
        function f:SetParent(p)
            self:Guard(); local before=self:IsVisible(); self.parent=p
            local n=self:IsVisible() and "OnShow" or "OnHide"
            if before~=self:IsVisible() and self.scripts[n] then self.scripts[n](self) end
            self:Post("SetParent",p)
        end
        function f:Show() self.shown=true end
        function f:Hide() self.shown=false end
        function f:SetShown(v) self.shown=v end
        function f:GetAlpha() return self.alpha end
        function f:SetAlpha(v) self.alpha=v; self:Post("SetAlpha",v) end
        function f:IsMouseEnabled() return self.mouse end
        function f:EnableMouse(v) self:Guard(); self.mouse=v; self:Post("EnableMouse",v) end
        function f:SetScript(n,cb) self.scripts[n]=cb end
        function f:HookScript() error("permanent visibility-script hook") end
        function f:RegisterEvent(n) self.events[n]=true end
        function f:UnregisterEvent(n) self.events[n]=nil end
        function f:UnregisterAllEvents() error("native events removed") end
        return f
    end
    e.CreateFrame=function() return make(nil) end; e.UIParent=make(nil)
    e.hooksecurefunc=function(v,n,cb)
        if type(v)=="string" then
            cb=n; hooks[v]=(hooks[v] or 0)+1; local original=assert(e[v])
            e[v]=function(...) local r={original(...)}; cb(...); return (table.unpack or unpack)(r) end
        else
            assert(type(v[n])=="function"); v.hooks[n]=v.hooks[n] or {}; v.hooks[n][#v.hooks[n]+1]=cb
        end
    end
    local m={enabled=true}
    function m:SetModuleType() end
    function m:SetName() end
    function m:SetDescription() end
    function m:SetDefaults(_,defaults)
        self.db={profile={global={}}}
        for n in pairs(defaults) do self.db.profile.global[n]=false end
        for n,v in pairs(options or {}) do self.db.profile.global[n]=v end
    end
    function m:SetGlobalOptionsFunction(cb) self.options=cb end
    function m:IsEnabled() return self.enabled end
    function m:RegisterEvent(n,method) registered[n]=method or n end
    function m:Print(v) notices[#notices+1]=v end
    function m:SetOption(n,v) self.db.profile.global[n]=v; self:UpdateFrames() end
    e.PitBull4={wow_classic=classic,L=setmetatable({},{__index=function(_,k) return k end}),NewModule=function() return m end}
    local chunk,msg
    if _VERSION=="Lua 5.1" then chunk,msg=loadfile(root.."Modules/HideBlizzard/HideBlizzard.lua"); if chunk then setfenv(chunk,e) end
    else chunk,msg=loadfile(root.."Modules/HideBlizzard/HideBlizzard.lua","t",e) end
    assert(chunk,msg); chunk()
    local function leave()
        e.combat=false
        for _,f in ipairs(frames) do if f.events.PLAYER_REGEN_ENABLED then f.scripts.OnEvent(f,"PLAYER_REGEN_ENABLED") end end
    end
    return m,e,make,leave,hooks,notices,registered,frames
end
local function retained(f)
    check(f.events.UNIT_HEALTH,"native events retained")
    check(#(f.hooks.SetParent or {})==1 and #(f.hooks.SetAlpha or {})==1,"hooks installed once")
end
-- Optional second argument: the supplied Blizzard_UnitFrame source directory.
-- With it, execute the original ClassPowerBar and Warlock combat callbacks;
-- otherwise exercise the same documented parent-chain contract locally.
local function load_source(path,e)
    local chunk,msg
    if _VERSION=="Lua 5.1" then chunk,msg=loadfile(path); if chunk then setfenv(chunk,e) end
    else chunk,msg=loadfile(path,"t",e) end
    assert(chunk,msg); chunk()
end
local resource_names={"RuneFrame","WarlockPowerFrame","MonkHarmonyBarFrame",
    "PaladinPowerBarFrame","MageArcaneChargesFrame","EssencePlayerFrame"}
for _,client in ipairs({"Retail","Forever"}) do
    for _,hide_player in ipairs({false,true}) do
        local m,e,make,leave=fixture(false,11,{player=hide_player,runebar=true})
        e.PlayerFrame=make(e.UIParent); e.PlayerFrame.unit="player"
        local container=make(e.PlayerFrame)
        function container:GetFrameLevel() return 3 end
        if arg[2] then
            for _,name in ipairs({"ClassPowerBar.lua","ClassResourceBarTemplate.lua","ShardBar.lua"}) do
                load_source(arg[2].."/"..name,e)
            end
        else
            e.ClassPowerBar={GetUnit=function(self)
                local unit=self.unit or self:GetParent():GetParent().unit
                return unit or "player"
            end}
        end
        for _,name in ipairs(resource_names) do
            local f=make(container); e[name]=f; f.alpha=0.65
            f.GetUnit=e.ClassPowerBar.GetUnit
        end
        local bar=e.WarlockPowerFrame
        if arg[2] then
            for _,mixin in ipairs({e.ClassPowerBar,e.ClassResourceBarMixin,e.WarlockPowerBar}) do
                for name,method in pairs(mixin) do if type(method)=="function" then bar[name]=method end end
            end
            e.SPEC_WARLOCK_DESTRUCTION=3
            e.C_SpecializationInfo={GetSpecialization=function() return e.spec or 1 end}
            e.UnitAffectingCombat=function() return e.combat end
            e.UnitPower=function(unit) e.last_power_unit=unit; return 30 end
            e.UnitPowerMax=function(unit) e.last_max_unit=unit; return 5 end
            e.UnitPowerDisplayMod=function() return 10 end
            e.UnitClass=function() return "Tester",e.class or "WARLOCK" end
            e.UnitLevel=function() return 80 end
            e.UnitInVehicle=function() return false end
            bar.class="WARLOCK"; bar.powerType=7; bar.requiredShownLevel=10
            bar.resourceBarMixin=e.ClassPowerBar; bar.usePooledResourceButtons=true
            bar.maxUsablePoints=5; bar.classResourceButtonTable={true,true,true,true,true}
            bar.classResourceButtonPool={EnumerateActive=function() return function() end end,
                ReleaseAll=function() error("unchanged resource pool released") end}
            function bar:RegisterUnitEvent(event,unit) self.events[event]=unit end
            function bar:GetPoint() return "TOP",container,"BOTTOM",5,0 end
            function bar:SetFrameLevel(level) self.level=level end
        end
        m:OnEnable()
        -- No cached .unit: this is the failing path in the reported locals.
        check(bar:GetUnit()=="player",client.." uncached native GetUnit succeeds")
        for _,name in ipairs(resource_names) do
            local f=e[name]
            check(f.parent==container and f:IsShown(),name.." native parent/shown state preserved")
            check(f.alpha==0 and not f.mouse,name.." rendering/input suppressed")
            retained(f); check(#f.hooks.EnableMouse==1,name.." one mouse hook")
        end
        local pool,points=bar.classResourceButtonPool,bar.classResourceButtonTable
        if arg[2] then
            e.combat=true; bar:OnEvent("PLAYER_REGEN_DISABLED")
            check(e.last_power_unit=="player",client.." original combat-entry callback succeeds")
            leave(); bar:OnEvent("PLAYER_REGEN_ENABLED")
            check(e.last_power_unit=="player",client.." original combat-exit callback succeeds")
            bar:Setup(); check(bar.unit=="player",client.." original Setup resolves native parent")
            bar.unit=nil; bar:UpdateMaxPower()
            check(bar.unit=="player" and e.last_max_unit=="player",client.." original UpdateMaxPower resolves parent")
            e.class="MAGE"; bar.unit=nil; bar:Setup()
            check(not bar:IsShown() and bar.unit==nil,client.." inactive class remains natively hidden")
            e.combat=true; bar:OnEvent("PLAYER_REGEN_DISABLED")
            check(e.last_power_unit=="player",client.." inactive Warlock combat callback succeeds")
            leave(); bar:OnEvent("PLAYER_REGEN_ENABLED")
            check(bar.classResourceButtonPool==pool and bar.classResourceButtonTable==points,
                client.." Blizzard resource pool/table preserved")
            e.class="WARLOCK"; bar:Setup(); bar.unit=nil
        end
        e.PlayerFrame.unit="vehicle"
        check(bar:GetUnit()=="vehicle",client.." native vehicle unit preserved without addon cache")
        e.PlayerFrame.unit="player"
        local next_container=make(e.PlayerFrame)
        bar:SetParent(next_container); bar:SetAlpha(0.4); bar:EnableMouse(true)
        check(bar.parent==next_container and bar.alpha==0 and not bar.mouse,client.." native reparent/fade stays suppressed")
        e.combat=true; m:SetOption("runebar",false)
        check(bar.alpha==0,client.." combat restoration deferred")
        leave()
        check(bar.parent==next_container and bar.alpha==0.4 and bar.mouse,client.." latest native parent/alpha/mouse restored")
        for _,name in ipairs(resource_names) do
            local f=e[name]
            if f~=bar then check(f.parent==container and f.alpha==0.65 and f.mouse,name.." immediate restoration") end
        end
        m:SetOption("runebar",true); bar:Hide(); m:SetOption("runebar",false)
        check(not bar:IsShown() and bar.alpha==0.4,client.." inactive resource not forced shown")
        bar:Show(); m:SetOption("runebar",true); e.combat=true; m:OnDisable(); leave()
        check(bar.parent==next_container and bar.alpha==0.4 and bar.mouse,client.." disabled-module restoration completes")
    end
end
for _,c in ipairs({{"Era",true,0},{"TBC",true,1},{"Cata",true,3},{"Mists",true,4},{"Forever",false,0},{"Retail",false,11}}) do
    local m,e,make,_,_,notices,registered=fixture(c[2],c[3])
    local cases={{"player","PlayerFrame"},{"player","PetFrame"},{"target","TargetFrame"},{"target","ComboFrame"},
        {"target","TargetFrameToT"},{"focus","FocusFrame"},{"focus","FocusFrameToT"},{"party","PartyFrame"},
        {"party","CompactPartyFrame"},{"raid","CompactRaidFrameManager"},{"raid","CompactRaidFrameContainer"},
        {"aura","BuffFrame"},{"aura","DebuffFrame"},{"boss","Boss1TargetFrame"},
        {"arena","ArenaEnemyFrames"},{"arena","ArenaPrepFrames"},{"arena","CompactArenaFrame"}}
    if c[3]>=3 then cases[#cases+1]={"player","PlayerFrameAlternateManaBar"}; cases[#cases+1]={"runebar","RuneFrame"} end
    for _,v in ipairs(cases) do e[v[2]]=make(e.UIParent) end
    m:OnEnable()
    check(registered.ADDON_LOADED and registered.PLAYER_ENTERING_WORLD and registered.GROUP_ROSTER_UPDATE,c[1].." events")
    for _,v in ipairs(cases) do
        local f,label=e[v[2]],c[1].." "..v[2]
        m:SetOption(v[1],true)
        if v[1]=="runebar" and not c[2] then
            check(f.parent==e.UIParent and f.alpha==0 and not f.mouse and f:IsShown(),label.." native-parent suppression")
        else check(not f:IsVisible() and f:IsShown(),label.." ancestor suppression") end
        retained(f)
        m:SetOption(v[1],false); check(f.parent==e.UIParent and f:IsVisible(),label.." immediate restore")
        f:Hide(); m:SetOption(v[1],true); m:SetOption(v[1],false); check(not f:IsShown(),label.." absent stays hidden")
        f:Show(); check(f:IsVisible(),label.." stale hooks inert")
    end
    check(#notices==0,"no reload notices")
    local opts={m.options(m)}; for i=1,#opts,2 do check(opts[i]~="reloadui" and opts[i]~="sep","reload controls removed") end
end
for expansion=0,4 do
    local m=fixture(true,expansion,{player=true,runebar=true,party=true,raid=true,target=true,focus=true,
        castbar=true,aura=true,altpower=true,boss=true,arena=true})
    m:OnEnable(); m:OnProfileChanged(); check(true,"sparse optional frames accepted")
end
do
    local m,e,make=fixture(true,4,{runebar=true})
    e.MonkHarmonyBar,e.PaladinPowerBar=make(e.UIParent),make(e.UIParent)
    m:OnEnable(); check(not e.MonkHarmonyBar:IsVisible() and not e.PaladinPowerBar:IsVisible(),"Mists aliases hidden")
    m:SetOption("runebar",false); check(e.MonkHarmonyBar:IsVisible() and e.PaladinPowerBar:IsVisible(),"aliases restored")
    e.MonkHarmonyBarFrame,e.PaladinPowerBarFrame=make(e.UIParent),make(e.UIParent)
    m:SetOption("runebar",true); check(not e.MonkHarmonyBarFrame:IsVisible() and not e.PaladinPowerBarFrame:IsVisible(),"modern aliases preferred")
    check(e.MonkHarmonyBar:IsVisible() and e.PaladinPowerBar:IsVisible(),"old aliases released")
end
do local m,e=fixture(false,11,{runebar=true}); e.PaladinPowerBar={}; m:OnEnable(); check(true,"mixin not treated as frame") end
do
    local m,e,make=fixture(false,11,{party=true,raid=true})
    e.PartyFrame=make(e.UIParent); local child=make(e.PartyFrame); e.CompactPartyFrame=make(e.PartyFrame)
    e.PartyFrame.PartyMemberFramePool={ReleaseAll=function() error("pool released") end}
    m:OnEnable(); check(not child:IsVisible() and child.parent==e.PartyFrame,"descendants retain parents")
    check(child.events.UNIT_HEALTH and e.UIParent.events.UNIT_HEALTH,"child/UIParent events retained")
    m:SetOption("party",false); check(child:IsVisible() and not e.CompactPartyFrame:IsVisible(),"raid retains shared suppression")
    m:SetOption("raid",false); check(e.CompactPartyFrame:IsVisible(),"last owner releases frame")
    m:SetOption("party",true); m:SetOption("raid",true); m:SetOption("raid",false)
    check(not e.CompactPartyFrame:IsVisible(),"party retains shared suppression"); m:SetOption("party",false); retained(e.CompactPartyFrame)
end
do
    local m,e,make=fixture(true,1,{party=true}); for i=1,4 do e["PartyMemberFrame"..i]=make(e.UIParent) end
    m:OnEnable(); m:SetOption("party",false); for i=1,4 do check(e["PartyMemberFrame"..i]:IsVisible(),"legacy party restores") end
end
do
    local m,e,make=fixture(false,11,{arena=true})
    local names={"ArenaEnemyFramesContainer","ArenaEnemyPrepFramesContainer","ArenaEnemyMatchFramesContainer"}
    for _,n in ipairs(names) do e[n]=make(e.UIParent) end
    m:OnEnable(); m:SetOption("arena",false); for _,n in ipairs(names) do check(e[n]:IsVisible(),"modern arena restores") end
end
do
    local m,e,make=fixture(false,11,{target=true}); e.TargetFrame=make(e.UIParent,false)
    m:OnEnable(); e.TargetFrame:Show(); check(not e.TargetFrame:IsVisible(),"unit-watch Show stays suppressed")
    local next_parent=make(e.UIParent); e.TargetFrame:SetParent(next_parent); check(not e.TargetFrame:IsVisible(),"reparent suppressed")
    m:SetOption("target",false); check(e.TargetFrame.parent==next_parent and e.TargetFrame:IsVisible(),"latest parent/state restored")
    m:SetOption("target",true); e.TargetFrame:Hide(); m:SetOption("target",false); check(not e.TargetFrame:IsShown(),"lost target stays hidden")
end
for _,name in ipairs({"PlayerCastingBarFrame","CastingBarFrame","PetCastingBarFrame"}) do
    local m,e,make,leave=fixture(false,11,{castbar=true}); local f=make(e.UIParent,false); e[name]=f; f.alpha=0.7
    local show,parent=f.Show,f.SetParent; m:OnEnable()
    check(f.parent==e.UIParent and f.Show==show and f.SetParent==parent,"castbar native methods retained")
    check(f.alpha==0 and not f.mouse and not f:IsShown(),"idle castbar suppressed")
    f:Show(); f:SetAlpha(0.5); check(f:IsShown() and f.alpha==0,"cast state updates while suppressed")
    e.combat=true; f:SetAlpha(0.8); m:SetOption("castbar",false); check(f.alpha==0,"combat restore deferred")
    leave(); check(f.alpha==0.8 and f.mouse and f:IsShown(),"active cast/latest alpha restored")
    m:SetOption("castbar",true); f:Hide(); m:SetOption("castbar",false); check(not f:IsShown(),"completed cast not forced shown")
    retained(f); check(#f.hooks.EnableMouse==1,"one mouse hook"); f:SetAlpha(0.3); check(f.alpha==0.3,"disabled fade hook inert")
end
do
    local m,e,make=fixture(false,11,{castbar=true}); local f=make(e.UIParent); e.PlayerCastingBarFrame=f; f.mouse=false
    m:OnEnable(); f:EnableMouse(true); check(not f.mouse,"mouse request suppressed")
    m:SetOption("castbar",false); check(f.mouse,"latest mouse state restored")
    f.mouse=false; m:SetOption("castbar",true); m:SetOption("castbar",false); check(not f.mouse,"disabled mouse retained")
    local secret=setmetatable({},{__lt=function() error("secret comparison") end,__add=function() error("secret arithmetic") end,
        __tostring=function() error("secret conversion") end})
    f.alpha=secret; m:SetOption("castbar",true); m:SetOption("castbar",false); check(rawequal(f.alpha,secret),"opaque alpha untouched")
end
do
    local m,e,make,leave,_,_,_,frames=fixture(false,11,{target=true}); e.TargetFrame=make(e.UIParent); e.combat=true
    m:OnEnable(); check(e.TargetFrame:IsVisible() and not e.TargetFrame.hooks.SetParent,"combat login defers all mutations")
    leave(); check(not e.TargetFrame:IsVisible(),"combat login applied afterward")
    e.combat=true; for _=1,20 do m:SetOption("target",false); m:SetOption("target",true) end
    m:SetOption("target",false); check(not e.TargetFrame:IsVisible(),"combat suppression retained")
    leave(); check(e.TargetFrame:IsVisible(),"latest combat toggle wins")
    for _,f in ipairs(frames) do check(not f.events.PLAYER_REGEN_ENABLED,"combat listener disarmed") end
    m:SetOption("target",true); e.combat=true; m:OnDisable()
    check(not e.TargetFrame:IsVisible(),"disable defers restore"); leave(); check(e.TargetFrame:IsVisible(),"disabled module restore completes")
    e.TargetFrame:SetParent(e.UIParent); check(e.TargetFrame:IsVisible(),"disabled parent hook inert")
    m.enabled=true; m:OnEnable(); check(not e.TargetFrame:IsVisible(),"module re-enable hides"); retained(e.TargetFrame)
end
do
    local m,e,make,leave=fixture(false,11,{altpower=true}); local f=make(e.UIParent); e.PlayerPowerBarAlt=f; f.alpha=0.6
    local next_parent=make(e.UIParent)
    f.scripts.OnHide=function(self) self:SetParent(next_parent) end
    m:OnEnable(); check(f.parent==e.UIParent and f:IsShown(),"alternate power native lifecycle retained")
    e.combat,e.native=true,true; f:SetParent(next_parent); e.native=false
    check(f.alpha==0,"native combat reparent suppressed"); f:SetAlpha(0.4); check(f.alpha==0,"combat fade suppressed")
    m:SetOption("altpower",false); leave(); check(f.parent==next_parent and f.alpha==0.4,"combat parent/alpha restored")
end
do
    local m,e,make,_,hooks=fixture(false,11,{arena=true,raid=true,party=true})
    e.CompactArenaFrame_Generate=function() e.CompactArenaFrame=e.CompactArenaFrame or make(e.UIParent); return e.CompactArenaFrame end
    e.CompactPartyFrame_Generate=function() e.CompactPartyFrame=e.CompactPartyFrame or make(e.UIParent); return e.CompactPartyFrame end
    m:OnEnable(); local arena,party=e.CompactArenaFrame_Generate(),e.CompactPartyFrame_Generate()
    check(not arena:IsVisible() and not party:IsVisible(),"lazy frames suppressed at generation")
    e.CompactRaidFrameManager,e.CompactRaidFrameContainer=make(e.UIParent),make(e.UIParent)
    m:ADDON_LOADED("ADDON_LOADED","Blizzard_CompactRaidFrames"); check(not e.CompactRaidFrameManager:IsVisible(),"late raid addon hidden")
    m:OnProfileChanged(); check(hooks.CompactArenaFrame_Generate==1 and hooks.CompactPartyFrame_Generate==1,"one generation hook each")
    m.enabled=false; m:OnDisable(); check(arena:IsVisible() and party:IsVisible() and e.CompactRaidFrameManager:IsVisible(),"lazy frames restore")
    e.CompactArenaFrame_Generate(); check(arena:IsVisible(),"disabled generation hook inert")
end
do
    local m,e,make=fixture(false,11,{player=true,target=true}); e.PlayerFrame,e.TargetFrame=make(e.UIParent),make(e.UIParent)
    m:OnEnable(); e.PlayerFrame.scripts.OnShow=function() m:UpdateFrames() end
    m.db.profile.global={player=false,target=false}; m:OnProfileChanged()
    check(e.PlayerFrame:IsVisible() and e.TargetFrame:IsVisible(),"profile restore handles re-entrant OnShow")
    m.db.profile.global={player=true}; m:OnProfileChanged()
    check(not e.PlayerFrame:IsVisible() and e.TargetFrame:IsVisible(),"new profile selects correct frames")
end
print(("HideBlizzard regression assertions passed: %d"):format(passed))
