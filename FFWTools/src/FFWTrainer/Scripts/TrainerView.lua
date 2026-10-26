local L=require('Locale')
local V={}
function V.layout(m,vp)
    local w,h=math.min(1120,vp.width-48),math.min(700,vp.height-48)
    local s={width=w,height=h,margin=24,dpiScale=vp.dpiScale or 1,commands={}};local c=s.commands
    local function bar(x,y,bw,bh,color) c[#c+1]={kind='bar',x=x,y=y,width=bw,height=bh,fraction=1,color=color} end
    local function text(t,x,y,bw,size,color) c[#c+1]={kind='text',text=t or '',x=x,y=y,width=bw,height=size*1.6,size=size,color=color or '#F4E7CA'} end
    local function button(id,t,x,y,bw,bh,action,value,selected,enabled)
        c[#c+1]={kind='button',id=id,text=t,x=x,y=y,width=bw,height=bh,size=15,action=action or id,value=value,
            selected=selected,enabled=enabled~=false,backgroundColor=selected and '#B48B49' or '#44363B',textColor=selected and '#17141D' or '#F4E7CA'}
    end
    local function input(id,t,key,hint,x,y,bw)
        c[#c+1]={kind='input',id=id,text=t,resetKey=key,hint=hint,x=x,y=y,width=bw,height=42,size=16}
    end
    bar(0,0,w,h,'#17141D');bar(2,2,w-4,h-4,'#9A7349');bar(6,6,w-12,h-12,'#28232D')
    bar(6,6,w-12,52,'#563E2E');bar(6,58,w-12,2,'#E2B969')
    text(L.choose('荒野工具箱','Frontier Toolkit'),24,12,w-160,23)
    button('close',L.choose('关闭','Close'),w-116,14,92,36)
    local tw=(w-48-5*8)/6
    for i,t in ipairs(m.tabs) do button('section-'..t.id,t.label,24+(i-1)*(tw+8),72,tw,38,'section',t.id,t.selected) end
    local left=math.floor(w*.34);local right=left+42;local rw=w-right-24
    if m.section=='settings' then
        text(m.heading,24,138,w-48,21,'#E2B969')
        button('unlimited',m.unlimited and L.choose('[开] 总点数解限','[ON] Unlimited total budget') or L.choose('[关] 总点数解限','[OFF] Unlimited total budget'),24,192,math.min(w-48,470),44,'unlimited')
        c[#c+1]={kind='scrollText',id='detail',text=m.detail,resetKey='settings',x=24,y=258,width=w-48,height=h-398,size=17}
    else
        input('query',m.query,m.queryKey,L.choose('搜索中文 / English','Search Chinese / English'),24,126,left)
        local rowHeight=math.min(44,math.floor((h-280)/8))
        for i,r in ipairs(m.rows) do
            button('row-'..i,r.name..(r.value~=nil and '   '..tostring(r.value) or ''),24,180+(i-1)*rowHeight,left,rowHeight-2,'select',r.id,r.selected)
        end
        if #m.rows==0 then text(L.choose('无匹配结果','No matches'),24,184,left,16,'#BCB1A3') end
        button('previousPage','<',24,h-92,60,36,nil,nil,false,m.page>1)
        text(string.format('%d / %d',m.page,m.pageCount),96,h-86,left-150,14,'#BCB1A3')
        button('nextPage','>',left-36,h-92,60,36,nil,nil,false,m.page<m.pageCount)
        bar(right-16,126,1,h-238,'#51444B')
        text(m.heading,right,130,rw,20,'#E2B969')
        local detailTop=184
        if m.section~='jokers' then
            text(L.choose('当前值：','Current: ')..(m.current or '—'),right,182,rw,17)
            input('target',m.inputValue,m.inputKey,L.choose('输入目标整数','Target whole number'),right,220,rw-150)
            button('apply',L.choose('应用 / F1','Apply / F1'),w-162,220,138,42,nil,nil,true,m.canApply and m.selected~=nil)
            detailTop=282
        end
        c[#c+1]={kind='scrollText',id='detail',text=m.detail or '',resetKey=m.selected and m.selected.id or m.section,
            x=right,y=detailTop,width=rw,height=math.max(48,h-168-detailTop),size=16}
        if m.section=='jokers' then button('spawn',L.choose('生成一张 / F3','Spawn one / F3'),right,h-126,rw,42,nil,nil,true,m.canSpawn and m.selected~=nil) end
    end
    if m.section~='jokers' then text(m.status,24,h-138,w-48,13,'#BCB1A3') end
    bar(6,h-52,w-12,46,'#17141D')
    text(m.message or L.choose('F2 开关 · F4 奇术卡 · 鼠标选择与翻页 · 详情可滚动','F2 toggle · F4 jokers · Click to select / page · Scroll details'),
        24,h-43,w-48,13,m.message and (m.success and '#83C6A4' or '#F28B82') or '#BCB1A3')
    return s
end
return V
