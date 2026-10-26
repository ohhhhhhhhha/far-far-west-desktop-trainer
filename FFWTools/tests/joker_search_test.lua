package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
local S,I=require('Spawner'),require('Inventory')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local snapshot=I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},equipped={},upgrades={},runtime={},
    inputs={buffGravity=0,heldItemName='itemLongRanger'}})
local all=S.entries()
local found=S.entries('轻盈')
eq(#found,1,'Chinese card-name substring filters the catalog');eq(found[1].id,'jokerLightWeight')
eq(S.entries('  JOKERLIGHTWEIGHT  ')[1].id,'jokerLightWeight','ID search ignores case and surrounding whitespace')
eq(#S.entries('jokerUpgrade'),0,'permanent upgrades stay outside pickup search')
eq(#S.entries('['),0,'query text is literal, not a Lua pattern')
eq(#S.entries(''),#all,'clearing the query restores all collectible cards')
local page=S.page(snapshot,nil,nil,'轻盈')
eq(page.searchable,true);eq(page.query,'轻盈');eq(page.count,1);eq(page.index,1)
eq(page.selected.id,'jokerLightWeight');eq(page.entries[1].id,page.selected.id)
eq(page.list:find('轻盈体态',1,true)~=nil,true)
eq(S.page(snapshot,100,nil,'轻盈').index,1,'selection wraps within filtered results')
eq(S.page(snapshot,-4,nil,'轻盈').index,1)
local empty=S.page(snapshot,40,nil,'没有这张卡_xyz')
eq(empty.index,0);eq(empty.count,0);eq(empty.selected,nil)
eq(empty.title:find('无匹配',1,true)~=nil,true)
eq(empty.detail:find('清空',1,true)~=nil,true)
local cdr=S.entries('cdr');eq(#cdr,6,'ID fragments locate all six element cooldown cards')
eq(S.page(snapshot,#cdr+1,nil,'cdr').selected.id,cdr[1].id)
eq(S.page(snapshot,nil).selected.id,'jokerLightWeight','unfiltered initial selection is retained')
print('joker_search_test: '..checks..' checks passed')
