dofile('ItemLore/Core.lua')
local records={
 [1]={objectives={[3]={{101,5}}},startedBy={},requiredSourceItems={102},sourceItemId=103},
 [2]={objectives={[3]={{101,1}}},startedBy={[3]={104}},requiredSourceItems={}},
}
local db={QuestPointers={[1]=true,[2]=true},QueryQuestSingle=function(id,key) return records[id][key] end}
local co=coroutine.create(function() return ItemLoreCore.BuildIndex(db) end)
local ok,index=coroutine.resume(co)
assert(ok,index)
while coroutine.status(co)~='dead' do ok,index=coroutine.resume(co); assert(ok,index) end
assert(index[101][1] and index[101][2], 'objective items must link to all consuming quests')
assert(index[102][1] and index[103][1] and index[104][2], 'source and starter items')
assert(not index[999], 'no fabricated association')
db.QueryQuestSingle=function() error('database not ready') end
local bad=coroutine.create(function() return ItemLoreCore.BuildIndex(db) end)
assert(not coroutine.resume(bad),'partial index must not be accepted')
print('PASS: reverse objective/source/starter index and read failure')
