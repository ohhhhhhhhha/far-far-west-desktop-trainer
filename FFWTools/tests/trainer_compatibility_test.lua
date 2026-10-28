local realLoad=loadfile
local nativeCalls=0
RegisterKeyBind=function() nativeCalls=nativeCalls+1 end
ExecuteInGameThread=function() nativeCalls=nativeCalls+1 end
LoopInGameThreadWithDelay=nil
loadfile=function() error('startup guard must run before loading dependencies') end
local mod=assert(realLoad('FFWTools/src/FFWTrainer/Scripts/main.lua'))()
assert(mod.enabled==false and mod.compatibilityError,'unsupported UE4SS must be disabled with an actionable message')
assert(nativeCalls==0,'unsupported startup must not register callbacks')
assert(mod.compatibilityError:find('1181',1,true),'name the verified UE4SS build')
loadfile=realLoad
print('trainer_compatibility_test: missing runtime API handled before native calls')
