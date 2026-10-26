package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
local Json=require('Json')
local Bridge=require('Bridge')
local count=0
local function eq(a,b,m) count=count+1;assert(a==b,(m or 'value')..': '..tostring(a)..' != '..tostring(b)) end
local files,now,calls,reads={},100,{},0
local function make(session)
    return Bridge.new{directory='data',session=session,clock=function() return now end,
        read=function(path) return files[path] end,
        write=function(path,text) files[path]=text;return true end,
        snapshot=function(client) reads=reads+1;return {language='zh',entries={{id='gold',value=5}},selected=client.selectedCardId} end,
        execute=function(action,payload) calls[#calls+1]={action,payload};return true,'完成','Done' end}
end
local b=make('session-a')
local function heartbeat(id,time) files['data/client.json']=Json.encode{protocol=1,clientId=id or 'one',updatedAt=time or now,selectedCardId='jokerLightWeight'} end
local function command(id,action,payload,session,time,client)
    files['data/command.json']=Json.encode{protocol=1,clientId=client or 'one',session=session or 'session-a',
        requestId=id,createdAt=time or now,action=action or 'setProgress',payload=payload or {id='gold',value='6'}}
end
local function state() return Json.decode(assert(files['data/state.json'])) end
b:tick();eq(reads,0,'closed GUI does not scan game');eq(#calls,0)
heartbeat();b:tick();eq(reads,1);eq(state().session,'session-a');eq(state().selected,'jokerLightWeight')
b:tick();eq(reads,1,'no extra snapshot within second')
command('first');b:tick();eq(#calls,1);eq(state().lastResult.requestId,'first');eq(state().lastResult.success,true)
b:tick();eq(#calls,1,'no repeated write');eq(state().lastResult.success,true)
command('bad-action','executeLua',{});b:tick();eq(#calls,1);eq(state().lastResult.success,false)
command('bad-type','setUnlimited',{enabled='yes'});b:tick();eq(#calls,1)
command('old',nil,nil,nil,now-11);b:tick();eq(#calls,1);eq(state().lastResult.success,false)
command('future',nil,nil,nil,now+4);b:tick();eq(#calls,1)
command('old-session',nil,nil,'session-before');b:tick();eq(#calls,1)
command('other-client',nil,nil,nil,nil,'two');b:tick();eq(#calls,1)
command('toggle','setUnlimited',{enabled=true});b:tick();eq(#calls,2);eq(calls[2][2].enabled,true)
command('spawn','spawn',{id='jokerLightWeight'});b:tick();eq(#calls,3)
-- Requests seen during a lost heartbeat cannot run when that client returns.
now=107;command('lost');b:tick();eq(#calls,3)
heartbeat();b:tick();eq(#calls,3,'no reconnect replay')
command('after-reconnect');b:tick();eq(#calls,4)
-- Restart creates a new session; old files never invoke progression.
local b2=make('session-b');b2:tick();eq(#calls,4);eq(state().session,'session-b')
command('new-session',nil,nil,'session-b');b2:tick();eq(#calls,5)
-- Older completed IDs cannot execute twice even after another request.
command('first');b:tick();eq(#calls,5)
files['data/command.json']='{"broken":';b:tick();eq(#calls,5)
heartbeat('two');command('two-request',nil,nil,'session-a',nil,'two');b:tick();eq(#calls,6)
-- Exceptions acknowledge failure once; polling does not retry a mutation.
local errors=0
local failing=Bridge.new{directory='bad',session='fail',clock=function() return now end,
    read=function(path) return files[path:gsub('bad/','data/')] end,
    write=function(path,text) files[path]=text;return true end,
    snapshot=function() return {} end,execute=function() errors=errors+1;error('native failure') end}
command('throws',nil,nil,'fail',nil,'two');failing:tick();failing:tick();eq(errors,1)
eq(Json.decode(files['bad/state.json']).lastResult.success,false)
-- A restart/constructor is read only; settings are not commands.
eq(#calls,6)
print('trainer_bridge_test: '..count..' checks passed')
