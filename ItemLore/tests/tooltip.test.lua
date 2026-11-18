GetLocale=GetLocale or function() return 'zhCN' end
dofile('ItemLore/Locale.lua')
local callback
Enum={TooltipDataType={Item=0}}
TooltipDataProcessor={AddTooltipPostCall=function(kind,fn) callback=fn end}
local row={status='candidate',reason='known quests complete',completedQuests={'77 Test'}}
ItemLoreUI={Inspect=function() return row end}
local function tooltip()
 local t={lines={},hooks={},colors={},raw={},wrap={}}
 function t:AddLine(s,r,g,b,wrap) self.lines[#self.lines+1]=s:gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''); self.raw[#self.lines]=s; self.colors[#self.lines]={r,g,b}; self.wrap[#self.lines]=wrap end
 function t:HookScript(k,fn) self.hooks[k]=fn end
 function t:HasScript() return true end
 return t
end
dofile('ItemLore/Tooltip.lua')
local t=tooltip()
callback(t,{id=101}); assert(#t.lines==2,'completed quest and short recommendation only')
assert(t.lines[1]==ItemLoreLocale['物品秘笺：'] .. '77 Test' and t.lines[2]==ItemLoreLocale['任务已完成，建议删除'])
assert(t.wrap[2]==false,'recommendation stays on its own unbroken line')
assert(t.raw[1]:find('|cffffd34d',1,true) and t.raw[2]:find('|cffff5757',1,true),'gold brand and red recommendation')
assert(not t.lines[2]:find('按已知',1,true),'no qualifier in recommendation')
callback(t,{id=101}); assert(#t.lines==2,'no duplicates')
t.hooks.OnTooltipCleared(t); t.lines={}
row.completedQuests={'[77] First','[78] Second'}
callback(t,{id=101})
assert(#t.lines==3 and t.lines[3]==ItemLoreLocale['任务已完成，建议删除'],'multiple quests share one recommendation')
assert(t.lines[1]:find('[77]',1,true) and t.lines[2]:find('[78]',1,true),'all quest IDs retained')
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
assert(#t.lines==1 and t.lines[1]==ItemLoreLocale['物品秘笺：'] .. 'altar use','special use is one attributed line')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='keep',usage=ItemLoreLocale['未知用途'],completedQuests={}}
callback(t,{id=4639}); assert(t.lines[1]==ItemLoreLocale['物品秘笺：未知用途'])
print('PASS: tooltip completion, mixed uses, protection, duplicate suppression, clear and special usage')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='unknown',isRelevant=true,completedQuests={}}
callback(t,{id=283389}); assert(#t.lines==1 and t.lines[1]==ItemLoreLocale['物品秘笺：未知用途'])
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='unknown',isRelevant=false,completedQuests={}}
callback(t,{id=999}); assert(#t.lines==0,'ordinary unknown items are not annotated')
t.hooks.OnTooltipCleared(t); t.lines={}
row={status='keep',pendingSummary='[209] Test quest' .. ItemLoreLocale['（'] .. ItemLoreLocale['进行中'] .. ItemLoreLocale['）'],completedQuests={}}
callback(t,{id=1524})
assert(t.raw[1]:find('|cffaaaaaa[209]|r',1,true),'gray quest ID')
assert(t.raw[1]:find('|cffffffffTest quest|r',1,true),'white quest name')
assert(t.raw[1]:find('|cff80d8a6',1,true) and not t.raw[1]:find('|cffff5757',1,true),'active quest green, not deletion red')
