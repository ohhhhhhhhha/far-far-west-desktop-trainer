-- Game-native trainer. No desktop client, command polling or background progress writes.
local directory=debug.getinfo(1,'S').source:sub(2):gsub('\\','/'):match('^(.*)/')
assert(directory,'FFWTrainer needs a file-backed entry point')
local shared={Cards=true,Effects=true,Inventory=true,Panel=true,HeroRules=true,WeaponRules=true,UpgradeRules=true}
local allowed={Spawner=true,Progress=true,Bridge=true,UpgradeLimit=true,Json=true,Locale=true,TrainerUI=true,TrainerView=true,CanvasView=true,MousePanel=true}
local modules,environment={},nil;local globalRequire=require
 environment=setmetatable({require=function(name)
    if not shared[name] and not allowed[name] then return globalRequire(name) end
    if not modules[name] then
        local chunk,err=loadfile(directory..'/'..name..'.lua','t',environment)
        if not chunk and shared[name] then chunk,err=loadfile(directory..'/../../FFWJokerInfo/Scripts/'..name..'.lua','t',environment) end
        if not chunk and (name=='Json' or name=='CanvasView' or name=='MousePanel') then chunk,err=loadfile(directory..'/../../Common/'..name..'.lua','t',environment) end
        modules[name]=assert(chunk,err)()
    end
    return modules[name]
end},{__index=_G})
local function module(name) return environment.require(name) end
local Progress,Spawner,Inventory=module('Progress'),module('Spawner'),module('Inventory')
local L,Bridge,Json=module('Locale'),module('Bridge'),module('Json')
local S={enabled=true,visible=false,errors=0,Progress=Progress,Locale=L};_G.FFWTrainer=S
local function log(m) print('[FFWTrainer] '..tostring(m)..'\n') end
local function protected(fn)
    local ok,err=pcall(fn)
    if not ok then S.errors=S.errors+1;if S.lastError~=tostring(err) then S.lastError=tostring(err);log(err) end end
    return ok,err
end
S.limit=module('UpgradeLimit').new()
local settingsPath=directory..'/../Data/settings.json'
local restoreUnlimited=false
local saved=Bridge.readFile(settingsPath)
if saved then local ok,value=pcall(Json.decode,saved);restoreUnlimited=ok and type(value)=='table' and value.unlimited==true end
local function setUnlimited(enabled)
    local previous=S.limit:status().enabled
    local ok,zh,en=S.limit:setEnabled(enabled);if not ok then return ok,zh,en end
    local written,err=Bridge.writeFile(settingsPath,Json.encode({unlimited=enabled}))
    if not written then
        S.limit:setEnabled(previous);log(err)
        return false,'设置未保存，已恢复原状态。','Settings could not be saved; the previous state was restored.'
    end
    return true,zh,en
end
S.ui=module('TrainerUI').new{read=Progress.read,inventory=Inventory.read,apply=Progress.apply,spawn=Spawner.spawn,
    canSpawn=Spawner.canSpawn,getUnlimited=function() return S.limit:status() end,setUnlimited=setUnlimited}
local function inputs()
    if not S.ui.visible or not S.renderer.attached then return end
    local query=S.renderer:input('query');if query and S.ui.section~='settings' then S.ui:setQuery(query) end
    if S.ui.section~='jokers' and S.ui.section~='settings' then
        local target=S.renderer:input('target')
        local entry=S.renderer.inputs and S.renderer.inputs.target
        if target and entry and entry.resetKey==S.ui.inputRevision then S.ui:setTarget(target) end
    end
end
local function render() S.visible=S.ui.visible;S.renderer:render(S.ui:model()) end
local spawnPending=false
function S.action(action,value)
    if not S.enabled then return end
    local spawning=action=='spawn'
    local selectedId=S.ui.selectedId
    if spawning then
        if spawnPending or not S.ui.visible or S.ui.section~='jokers' then return end
        spawnPending=true
    end
    -- Keep one outstanding spawn intent. A slow frame must not turn repeated
    -- F3/click input into actors queued for later, after the cooldown expires.
    local scheduled=protected(function() ExecuteInGameThread(function()
        protected(function()
            if not S.enabled then return end
            inputs()
            if spawning and (S.ui.section~='jokers' or S.ui.selectedId~=selectedId) then return end
            S.ui:action(action,value);render()
        end)
        if spawning then spawnPending=false end
    end) end)
    if not scheduled and spawning then spawnPending=false end
end
S.renderer=module('CanvasView').new{getController=function() return require('UEHelpers').GetPlayerController() end,
    layout=module('TrainerView').layout,onAction=S.action,zOrder=9960}
function S.toggle(section)
    ExecuteInGameThread(function() protected(function() inputs();L.refresh();S.ui:toggle(section);render() end) end)
end
function S.hide()
    if not S.visible then return end
    ExecuteInGameThread(function() protected(function() S.ui.visible=false;render() end) end)
end
local lastTick=-math.huge
function S.update()
    if not S.enabled then return end
    if restoreUnlimited then restoreUnlimited=false;S.limit:setEnabled(true) end
    inputs()
    local now=os.time()
    if now~=lastTick then S.limit:tick();L.refresh();S.ui:refresh();lastTick=now end
    if S.visible then render() end
end
function S.stop() S.enabled=false;S.ui.visible=false;S.visible=false;S.renderer:hide();S.limit:stop() end
local function bind(key,fn) if Key and Key[key] then RegisterKeyBind(Key[key],fn) end end
bind('F2',function() S.toggle() end)
bind('F4',function() S.toggle('jokers') end)
bind('F1',function() S.action('apply') end)
bind('F3',function() S.action('spawn') end)
for _,entry in ipairs({{'F5',-1},{'F6',1}}) do bind(entry[1],function()
    if S.visible then ExecuteInGameThread(function() protected(function() inputs();S.ui:move(entry[2]);render() end) end) end
end) end
bind('F7',S.hide);bind('F8',S.hide)
LoopInGameThreadWithDelay(250,function() if S.enabled then protected(S.update) end end)
log('in-game trainer loaded: F2 toolkit, F4 joker search, F1 apply, F3 spawn. Desktop commands are disabled.')
return S
