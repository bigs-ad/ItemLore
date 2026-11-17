GetLocale=GetLocale or function() return 'zhCN' end
dofile('ItemLore/Locale.lua')
dofile('ItemLore/Core.lua')
local C = ItemLoreCore
local n = 0
local function check(expected, item, quests, protected)
    local status = C.Classify(item, quests, protected)
    assert(status == expected, tostring(status) .. ' ~= ' .. expected)
    n = n + 1
end
local item = {classID=12, questIDs={11,12}}
local done = { [11]={done=true,active=false,repeatable=false}, [12]={done=true,active=false,repeatable=false} }
check('candidate', item, done)
check('protected', item, done, true)
check('unknown', item, {})
check('unknown', {classID=12,questIDs={}}, done)
check('keep', {classID=7,questIDs={11}}, done)
done[12].done=false; check('keep', item, done)
done[12].done=true; done[12].active=true; check('keep', item, done)
done[12].active=false; done[12].repeatable=true; check('keep', item, done)
done[12].repeatable=nil; check('unknown', item, done)
done[12].repeatable=false; done[12].done=nil; check('unknown', item, done)
done[12].done=true; done[12].active=nil; check('unknown', item, done)
assert(C.SameStack({id=1,count=2,link='a'}, {id=1,count=2,link='a'}))
assert(not C.SameStack({id=1,count=2,link='a'}, {id=2,count=2,link='b'}))
assert(not C.SameStack({id=1,count=2,link='a'}, {id=1,count=3,link='a'}))
assert(not C.SameStack({id=1,count=2,link='a'}, {id=1,count=2,link='a',locked=true}))
print('PASS: ' .. n .. ' classification cases and 4 stack guards')
