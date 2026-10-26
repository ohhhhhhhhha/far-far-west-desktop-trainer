package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
package.path='FFWTools/src/FFWTrainer/Scripts/?.lua;'..package.path
local L,P,I,S=require('Locale'),require('Panel'),require('Inventory'),require('Spawner')
local checks=0
local function eq(a,b,m) checks=checks+1;assert(a==b,(m or '')..' expected '..tostring(b)..', got '..tostring(a)) end
local snapshot=I.fromSnapshot({selected={primary='itemLongRanger',secondary='itemPistol'},
    equipped={itemHero={'jokerLightWeight','jokerLightWeight'}},upgrades={},runtime={},
    inputs={buffGravity=0,heldItemName='itemLongRanger'}})
local chinese=P.description('jokerLightWeight',snapshot,nil,'pickup','重力 -5%')
L.setCulture('en-US')
local english=P.description('jokerLightWeight',snapshot,nil,'pickup',chinese)
eq(english:find('-5% gravity',1,true)~=nil,true,'stock original description follows language')
eq(english:find('1.15 → 1.1',1,true)~=nil,true)
eq(english:find('【奇术卡信息】',1,true),nil,'old-language append is removed')
eq(english:find('[Joker Info]',1,true)~=nil,true)
eq(english:find('重力',1,true),nil)
local once=P.description('jokerLightWeight',snapshot,nil,'pickup',english);eq(once,english)
local page=P.page(snapshot,1)
eq(page.title:find('LIGHTWEIGHT',1,true)~=nil,true)
eq(page.detail:find('叠加',1,true),nil,'full F7 rules are translated')
eq(S.entries('fight or flight')[1].id,'jokerFightOrFlight','official spaced English name is searchable')
eq(S.entries('或战或逃')[1].id,'jokerFightOrFlight','Chinese search works in English UI')
eq(S.page(snapshot,nil,nil,'轻盈').title:find('LIGHTWEIGHT',1,true)~=nil,true)
local floor={};for n=1,21 do floor[n]='jokerLightWeight' end
local noEffect=I.fromSnapshot({selected={primary='itemLongRanger'},equipped={itemHero=floor},upgrades={},runtime={},
    inputs={buffGravity=0,heldItemName='itemLongRanger'}})
local noBonus,style=P.description('jokerLightWeight',noEffect,nil,'pickup')
eq(noBonus:find('No bonus',1,true)~=nil,true);eq(style.noBonus,true)
L.setCulture('zh-Hans')
eq(S.entries('FIGHT OR FLIGHT')[1].id,'jokerFightOrFlight')
eq(P.description('jokerLightWeight',snapshot,nil,'pickup',english),chinese,'switching back restores one Chinese block')
print('joker_bilingual_test: '..checks..' checks passed')
