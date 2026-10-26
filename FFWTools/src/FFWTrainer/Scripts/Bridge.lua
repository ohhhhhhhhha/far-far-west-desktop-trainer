-- Narrow local-file protocol. Only a fresh, explicit desktop command invokes execute.
local Json=require('Json')
local Bridge={}
function Bridge.readFile(path)
    local f=io.open(path,'rb');if not f then return nil end
    local text=f:read('a');f:close();return text
end
function Bridge.writeFile(path,text)
    local temp=path..'.tmp'
    local f,err=io.open(temp,'wb');if not f then return nil,err end
    local written,writeError=f:write(text);local closed,closeError=f:close()
    if not written or not closed then return nil,writeError or closeError end
    local ok,renameError=os.rename(temp,path);if ok then return true end
    -- Windows Lua cannot ReplaceFile. A brief absent destination is tolerated by
    -- readers; never expose a partially written JSON document.
    local backup=path..'.bak';os.remove(backup)
    local old=io.open(path,'rb');if not old then return nil,renameError end;old:close()
    local moved,moveError=os.rename(path,backup);if not moved then return nil,moveError end
    ok,renameError=os.rename(temp,path)
    if not ok then os.rename(backup,path);return nil,renameError end
    os.remove(backup);return true
end
local function decode(text)
    if type(text)~='string' then return nil end
    local ok,result=pcall(Json.decode,text)
    if ok and type(result)=='table' then return result end
end
local function stringValue(v) return type(v)=='string' and v~='' end
local function fresh(value,now,maxAge)
    return type(value)=='number' and value==value and value<=now+2 and now-value<=maxAge
end
local function validPayload(action,p)
    if type(p)~='table' then return false end
    if action=='setProgress' then return stringValue(p.id) and type(p.value)=='string'
    elseif action=='spawn' then return stringValue(p.id)
    elseif action=='setUnlimited' then return type(p.enabled)=='boolean' end
    return false
end
function Bridge.new(options)
    local self={directory=assert(options.directory),session=assert(options.session),
        clock=options.clock or os.time,read=options.read or Bridge.readFile,
        write=options.write or Bridge.writeFile,snapshot=assert(options.snapshot),
        execute=assert(options.execute),seen={},lastPublish=-math.huge}
    function self:readJson(name) return decode(self.read(self.directory..'/'..name..'.json')) end
    function self:writeJson(name,value) return self.write(self.directory..'/'..name..'.json',Json.encode(value)) end
    function self:tick()
        local now=self.clock()
        local client=self:readJson('client')
        local active=client and client.protocol==1 and stringValue(client.clientId) and fresh(client.updatedAt,now,6)
        local cmd=self:readJson('command');local changed=false
        if cmd and stringValue(cmd.requestId) and stringValue(cmd.clientId) then
            local identity=cmd.clientId..'\0'..cmd.requestId
            local result=self.seen[identity]
            if not result then
                result={requestId=cmd.requestId,success=false}
                -- Reserve before calling native code: exceptions or polling never retry.
                self.seen[identity]=result
                if not active or cmd.clientId~=client.clientId then
                    result.messageZh='窗口连接已过期，请重新操作。';result.messageEn='The desktop connection expired. Submit a new action.'
                elseif cmd.protocol~=1 or cmd.session~=self.session or not fresh(cmd.createdAt,now,10) then
                    result.messageZh='请求已过期，请重新操作。';result.messageEn='The request expired. Submit a new action.'
                elseif not validPayload(cmd.action,cmd.payload) then
                    result.messageZh='不支持的操作或参数。';result.messageEn='Unsupported action or payload.'
                else
                    local called,success,zh,en=pcall(self.execute,cmd.action,cmd.payload)
                    result.success=called and success==true
                    result.messageZh=called and (zh or '操作未完成。') or '游戏接口调用失败，请查看 UE4SS 日志。'
                    result.messageEn=called and (en or 'Action did not complete.') or 'Game API failed. See the UE4SS log.'
                    if not called then print('[FFWTrainer] command error: '..tostring(success)..'\n') end
                end
                changed=true
            end
            if self.lastResult~=result then self.lastResult=result;changed=true end
        end
        if active and (changed or now-self.lastPublish>=1 or self.lastClient~=client.clientId) then
            local state=self.snapshot(client)
            state.protocol=1;state.session=self.session;state.updatedAt=now;state.connected=true
            state.lastResult=self.lastResult
            local ok,err=self:writeJson('state',state)
            if not ok then error('Cannot publish trainer state: '..tostring(err)) end
            self.lastPublish=now;self.lastClient=client.clientId
        end
    end
    return self
end
return Bridge
