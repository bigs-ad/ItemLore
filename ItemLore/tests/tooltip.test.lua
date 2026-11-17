local callback
Enum={TooltipDataType={Item=0}}
TooltipDataProcessor={AddTooltipPostCall=function(kind,fn) callback=fn end}
local row={status='candidate',reason='known quests complete',completedQuests={'77 Test'}}
ItemLoreUI={Inspect=function() return row end}
local function tooltip()
 local t={lines={},hooks={},colors={}}
 function t:AddLine(s,r,g,b) self.lines[#self.lines+1]=s; self.colors[#self.lines]={r,g,b} end
 function t:HookScript(k,fn) self.hooks[k]=fn end
 function t:HasScript() return true end
 return t
end
dofile('ItemLore/Tooltip.lua')
local t=tooltip()
callback(t,{id=101}); assert(#t.lines==2,'completed quest and short recommendation only')
assert(t.lines[1]=='物品秘笺：' and t.lines[2]=='任务《77 Test》已完成，建议删除')
assert(t.colors[1][1]==1 and t.colors[1][2]==0.25 and t.colors[2][2]==0.25,'candidate uses red')
assert(not t.lines[2]:find('按已知',1,true),'no qualifier in recommendation')
callback(t,{id=101}); assert(#t.lines==2,'no duplicates')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='keep',reason='another quest needs item',completedQuests={'77 Test'}}
callback(t,{id=101}); assert(t.lines[3]:find('another quest',1,true),'mixed uses warn')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='keep',completedQuests={}}
callback(t,{id=101}); assert(#t.lines==0,'not handed in means no completed label')
row={status='protected',reason='protected',completedQuests={'77 Test'}}
callback(t,{id=101}); assert(t.lines[3]:find('protected',1,true))
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='keep',reason='keep special',completedQuests={},usage='altar use',usageEvidence='in-game tooltip'}
callback(t,{id=4639})
assert(#t.lines==1 and t.lines[1]=='物品秘笺：altar use','special use is one attributed line')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='keep',usage='未知用途',completedQuests={}}
callback(t,{id=4639}); assert(t.lines[1]=='物品秘笺：未知用途')
print('PASS: tooltip completion, mixed uses, protection, duplicate suppression, clear and special usage')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='unknown',isRelevant=true,completedQuests={}}
callback(t,{id=283389}); assert(#t.lines==1 and t.lines[1]=='物品秘笺：未知用途')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='unknown',isRelevant=false,completedQuests={}}
callback(t,{id=999}); assert(#t.lines==0,'ordinary unknown items are not annotated')
