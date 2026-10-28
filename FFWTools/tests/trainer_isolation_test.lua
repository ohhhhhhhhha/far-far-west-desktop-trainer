-- Separate Trainer instances must not share locale, pending commands or globals.
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..': '..tostring(a)..' != '..tostring(b)) end
local instances={}
for i=1,2 do
    local env=setmetatable({}, {__index=_G});env._G=env
    local callbacks,files={},{}
    env.RegisterKeyBind=function(key,fn) callbacks[key]=fn end
    env.LoopInGameThreadWithDelay=function() end
    env.ExecuteInGameThread=function(fn) fn() end
    env.StaticFindObject=function() return nil end
    env.FindAllOf=function() return {} end
    env.loadfile=function(path,mode,moduleEnv)
        if path:match('/UpgradeLimit%.lua$') then return function() return {new=function()
            return {tick=function() end,stop=function() end,status=function() return {enabled=false} end}
        end} end end
        local chunk,err=loadfile(path,mode,moduleEnv)
        if chunk and path:match('/Bridge%.lua$') then return function()
            local b=chunk()
            b.readFile=function(p) return files[p] end
            b.writeFile=function(p,text) files[p]=text;return true end
            return b
        end end
        return chunk,err
    end
    local mod=assert(loadfile('FFWTools/src/FFWTrainer/Scripts/main.lua','t',env))()
    mod.update()
    eq(next(callbacks),nil,'no keys registered when the host has no key API')
    eq(next(files),nil,'offline polling is read only')
    eq(env.FFWTrainer,mod)
    instances[i]=mod
end
local a,b=instances[1],instances[2]
eq(a~=b,true);eq(a.ui~=b.ui,true);eq(a.renderer~=b.renderer,true)
eq(a.Locale~=b.Locale,true,'private language state')
a.Locale.setCulture('en-US');eq(a.Locale.language(),'en');eq(b.Locale.language(),'zh')
eq(a.Progress~=b.Progress,true,'private progression module')
a.stop();eq(a.enabled,false);eq(b.enabled,true)
eq(_G.FFWTrainer,nil,'private entry points do not leak into global VM')
print('trainer_isolation_test: '..checks..' checks passed')
