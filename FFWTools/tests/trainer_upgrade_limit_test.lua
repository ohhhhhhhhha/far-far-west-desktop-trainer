package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local loaded,U=pcall(require,'UpgradeLimit')
assert(loaded,'original-menu upgrade budget controller is not implemented: '..tostring(U))

-- This engine boundary follows the decoded 0.3.0.7 blueprints. The code under
-- test must change the native eligibility without buying, confirming or saving.
local hookPath='/Game/Interfaces/Equipment/UI_Equipment_Item.UI_Equipment_Item_C:F_UpdatePriceAndUpgradesAmount'
local hooks,queued,widgets={}, {}, {}
local inAsync=false
local available=true
local registrationFails=false
local functionAddress=101
local registrations,removals,scans=0,0,0
local function remote(v) return {get=function() return v end} end
local function obj(address,full)
    return {alive=true,IsValid=function(self) return self.alive end,
        GetAddress=function() return address end,GetFullName=function() return full or 'Object' end}
end
local function map(values)
    local m={values=values}
    function m:ForEach(fn) for k,v in pairs(self.values) do fn(remote(k),remote(v)) end end
    return m
end
local function copy(t) local c={};for k,v in pairs(t) do c[k]=v end;return c end
local function sum(t) local n=0;for _,v in pairs(t) do n=n+v end;return n end
-- UE4SS FText is a callable userdata (LuaFText.cpp), not a Lua function.
-- A callable table exercises that boundary in the standalone Lua interpreter.
FText=setmetatable({}, {__call=function(_,v) return {ToString=function() return v end} end})
ExecuteAsync=function(fn) queued[#queued+1]=fn end
StaticFindObject=function(path)
    eq(path,hookPath,'only the original menu refresh is hooked')
    if available then return obj(functionAddress,'Function '..path) end
    return obj(0,'missing')
end
local originalFind=StaticFindObject
StaticFindObject=function(path)
    local value=originalFind(path);if not available then value.alive=false end;return value
end
RegisterHook=function(path,callback,post)
    assert(inAsync,'registration is scheduled outside the game callback')
    eq(path,hookPath);eq(post,nil,'Blueprint hooks use their single post callback')
    if registrationFails then error('registration failed') end
    registrations=registrations+1;hooks[registrations]=callback
    return registrations,registrations
end
UnregisterHook=function(path,pre,post)
    eq(path,hookPath);eq(pre,post);hooks[pre]=nil;removals=removals+1
end
FindAllOf=function(class)
    assert(not inAsync,'widget traversal stays on the game thread')
    eq(class,'UI_Equipment_Item_C');scans=scans+1;return widgets
end
local function pump()
    local pending=queued;queued={};inAsync=true
    for _,fn in ipairs(pending) do fn() end
    inAsync=false
end
local nextAddress=1000
local function fixture(values,level,extra)
    nextAddress=nextAddress+1
    local ui=obj(nextAddress,'UI_Equipment_Item_C /Engine/Transient.Widget_'..nextAddress)
    ui.bufferCurrentTweaks=map(copy(values or {health=10,shield=10,damage=0}))
    ui.bufferNewTweaks=map(copy(ui.bufferCurrentTweaks.values))
    ui.upgradePrice=0;ui.level=level or 100;ui.extra=extra or 0;ui.prestige=0
    ui.amountAvailableUpgrades=sum(ui.bufferNewTweaks.values);ui.maxUpgradesAvailable=20+ui.extra
    ui.gold=1000;ui.saved=copy(ui.bufferCurrentTweaks.values);ui.confirmCalls=0;ui.saveCalls=0
    ui.generatedSlots=0;ui.visible=true
    ui.controller=obj(500,'Local player controller')
    ui.controller.Pawn=obj(501,'BP_Player_Lobby_C /Game/Levels/L_Lobby.L_Lobby:PersistentLevel.Player')
    function ui.controller:IsLocalPlayerController() return true end
    function ui:GetOwningPlayer() return self.controller end
    function ui:IsVisible() return self.visible end
    ui.UpgradesAvailableMax=obj(600,'TextBlock')
    function ui.UpgradesAvailableMax:SetText(value)
        assert(not inAsync,'text updates stay on the game thread')
        self.text=value:ToString()
    end
    function ui:F_UpdatePriceAndUpgradesAmount(amount)
        self.upgradePrice=self.upgradePrice+amount
        self.amountAvailableUpgrades=sum(self.bufferNewTweaks.values)
        self.maxUpgradesAvailable=20+self.extra
        self.UpgradesAvailableMax:SetText(FText(self.amountAvailableUpgrades..'/'..self.maxUpgradesAvailable))
        -- @3739 uses the MAXIMUM field as a loop bound, never the spent field.
        self.generatedSlots=self.maxUpgradesAvailable
        for _,callback in pairs(hooks) do callback(remote(self),remote(amount)) end
    end
    function ui:plus(key,max,price)
        local amount=self.bufferNewTweaks.values[key] or 0
        if amount>=max then return false,'per-stat limit' end
        if not (self.amountAvailableUpgrades<math.floor(self.level/2)+self.extra or self.prestige>0) then
            return false,'level budget'
        end
        if not (self.amountAvailableUpgrades<self.maxUpgradesAvailable) then return false,'total budget' end
        self.bufferNewTweaks.values[key]=math.min(max,math.max(0,amount+1))
        self:F_UpdatePriceAndUpgradesAmount(-price)
        return true
    end
    function ui:minus(key,price)
        local amount=self.bufferNewTweaks.values[key] or 0
        if amount<=0 then return false end
        self.bufferNewTweaks.values[key]=amount-1;self:F_UpdatePriceAndUpgradesAmount(price);return true
    end
    function ui:confirm()
        self.confirmCalls=self.confirmCalls+1
        if self.upgradePrice<=0 and self.gold<math.abs(self.upgradePrice) then return false end
        self.gold=self.gold+self.upgradePrice
        self.saved=copy(self.bufferNewTweaks.values)
        self.bufferCurrentTweaks=map(copy(self.saved));self.upgradePrice=0
        self:F_UpdatePriceAndUpgradesAmount(0);return true
    end
    function ui:close()
        self.saveCalls=self.saveCalls+1;self.visible=false
    end
    return ui
end
local function enable(controller)
    eq(controller:setEnabled(true),true)
    pump();controller:tick();pump()
end
local c=U.new()
local s=c:status();eq(s.enabled,false);eq(s.active,false)
eq(registrations,0,'loading does not hook or change the game');eq(scans,0)
local menu=fixture();widgets={menu}
eq(menu:plus('damage',10,30),false,'native budget is exhausted at twenty')
enable(c)
eq(c:status().enabled,true);eq(c:status().active,true)
eq(menu:plus('damage',10,30),true,'native plus button can allocate point twenty-one')
eq(menu.bufferNewTweaks.values.damage,1);eq(menu.saved.damage,0,'allocation is still pending native confirmation')
eq(menu.gold,1000);eq(menu.confirmCalls,0);eq(menu.saveCalls,0)
eq(menu.upgradePrice,-30,'native price is retained');eq(menu.generatedSlots,20,'no enlarged widget loop')
eq(menu.UpgradesAvailableMax.text,'21/∞','actual spent amount is displayed')
eq(menu:plus('health',10,30),false,'native per-stat cap remains enforced')
menu.gold=10;eq(menu:confirm(),false,'native confirmation rejects insufficient gold')
eq(menu.saved.damage,0);eq(menu.gold,10)
menu.gold=1000;eq(menu:confirm(),true);eq(menu.gold,970);eq(menu.saved.damage,1)
menu:close();eq(menu.saveCalls,1,'only the original close path saves')

-- Reopen/rebuild callbacks must apply immediately, before the next timer tick.
local reopened=fixture(menu.saved);widgets={reopened}
reopened:F_UpdatePriceAndUpgradesAmount(0)
eq(reopened:plus('damage',10,30),true)
eq(reopened.UpgradesAvailableMax.text,'22/∞');eq(reopened.generatedSlots,20)
eq(c:setEnabled(false),true)
eq(c:status().enabled,false);eq(c:status().active,false)
eq(reopened.amountAvailableUpgrades,22);eq(reopened.UpgradesAvailableMax.text,'22/20')
eq(reopened:plus('damage',10,30),false,'disable restores native total eligibility')
eq(reopened.bufferNewTweaks.values.damage,2,'disable does not discard pending points')
eq(reopened.saved.damage,1,'disable never rewrites saved points')
eq(reopened.upgradePrice,-30,'disable retains pending native cost')
eq(reopened:minus('damage',30),true,'native removal still works above the native cap')
eq(reopened.amountAvailableUpgrades,21)
eq(reopened:confirm(),true,'the native confirm path accepts existing over-budget allocation')
eq(reopened.saved.damage,1)

-- The independent earned-level budget is also a total budget, not a stat cap.
local low=fixture({damage=0},1);widgets={low}
eq(low:plus('damage',10,30),false)
enable(c);eq(low:plus('damage',10,30),true)
for _=1,9 do eq(low:plus('damage',10,30),true) end
eq(low:plus('damage',10,30),false);eq(low.generatedSlots,20)
eq(low.UpgradesAvailableMax.text,'10/∞')

local many={};for i=1,1000 do many['stat'..i]=10 end
local large=fixture(many,100,3);widgets={large}
large:F_UpdatePriceAndUpgradesAmount(0)
eq(large.generatedSlots,23,'large saved totals never become the slot loop bound')
eq(large.UpgradesAvailableMax.text,'10000/∞');eq(sum(large.saved),10000)
eq(c:setEnabled(false),true);eq(large.amountAvailableUpgrades,10000)
eq(sum(large.saved),10000);eq(large.saveCalls,0)

-- Invalid/non-local/non-saloon objects and class defaults are never patched.
local bad={fixture(),fixture(),fixture(),fixture()}
bad[1].alive=false
bad[2].controller.IsLocalPlayerController=function() return false end
bad[3].controller.Pawn=obj(909,'BP_Player_C /Game/Levels/L_Map_FarWest.L_Map_FarWest:PersistentLevel.Player')
bad[4].GetFullName=function() return 'UI_Equipment_Item_C Default__UI_Equipment_Item_C' end
widgets=bad;enable(c)
for _,ui in ipairs(bad) do
    ui:F_UpdatePriceAndUpgradesAmount(0)
    eq(ui.amountAvailableUpgrades,20,'ineligible UI stays native')
end
c:tick();eq(c:status().active,false)

-- Lazy hook setup and registration failures must be visible, and retryable.
c:stop();pump();widgets={};hooks={};available=false
local delayed=U.new();enable(delayed);eq(delayed:status().enabled,true);eq(delayed:status().active,false)
available=true;registrationFails=true;delayed:tick();pump();eq(delayed:status().active,false)
registrationFails=false;local late=fixture();widgets={late};delayed:tick();pump();delayed:tick();pump()
eq(late:plus('damage',10,30),true,'late-loaded original menu gets the patch')
local beforeRegister=registrations
delayed:tick();pump();delayed:tick();pump();eq(registrations,beforeRegister,'stable UFunction is not hooked repeatedly')
functionAddress=102;delayed:tick();pump();delayed:tick();pump()
eq(registrations,beforeRegister+1,'a reloaded function is re-hooked')
eq(late:plus('damage',10,30),true)
local spent=sum(late.bufferNewTweaks.values)
delayed:stop();pump();eq(late.amountAvailableUpgrades,spent)
eq(late:plus('damage',10,30),false);eq(late.saveCalls,0);eq(late.confirmCalls,0)
eq(delayed:status().enabled,false);eq(delayed:status().active,false)

local noAsync=ExecuteAsync;ExecuteAsync=nil
local missing=U.new();eq(missing:setEnabled(true),false,'missing hook scheduling cannot claim enabled')
eq(missing:status().enabled,false);ExecuteAsync=noAsync
local invalid=U.new();eq(invalid:setEnabled('true'),false,'toggle must be an explicit boolean')
eq(invalid:status().enabled,false)
print('trainer_upgrade_limit_test: '..checks..' checks passed')
