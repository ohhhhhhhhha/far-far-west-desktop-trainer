-- Keep the desktop's offline search catalog identical to the collectible set.
local root=arg[1] or 'FFWTools'
package.path=root..'/src/FFWTrainer/Scripts/?.lua;'..root..'/src/FFWTrainer/Scripts/?.lua;'..package.path
local Cards,Json=require('Cards'),require('Json')
local Text=dofile(root..'/src/FFWTrainer/Scripts/CardText.lua')
local rarity={['E_Rarity::NewEnumerator0']=true,['E_Rarity::NewEnumerator1']=true,
    ['E_Rarity::NewEnumerator2']=true,['E_Rarity::NewEnumerator4']=true,
    ['E_Rarity::NewEnumerator5']=true,['E_Rarity::NewEnumerator6']=true}
local rows={}
for _,c in ipairs(Cards.all()) do
    if c.enabled and not c.id:lower():find('jokerupgrade',1,true) and rarity[c.rarity] then
        local t=assert(Text[c.id],c.id)
        rows[#rows+1]={id=c.id,nameZh=t.zhName,nameEn=t.enName,
            descriptionZh=t.zhDescription,descriptionEn=t.enDescription}
    end
end
table.sort(rows,function(a,b) return a.id<b.id end)
local f=assert(io.open(root..'/src/FFWTrainerGui/catalog.json','wb'))
assert(f:write(Json.encode(rows)));assert(f:close())
print('Desktop bilingual catalog: '..#rows..' collectible cards')
