dofile('ItemLore/UsageData.lua')
dofile('ItemLore/SpecialItems.lua')
local S=ItemLoreSpecialItems
local r={id=4639,status='candidate',reason='done',details='quests'}
assert(S.Apply(r,false))
assert(r.status=='keep' and r.usage and r.details:find('海誓祭坛',1,true))
assert(r.reason=='未知用途' and r.usage=='未知用途','short unknown label; deletion still blocked')
r.status='unknown'; assert(S.Apply(r,true)); assert(r.status=='protected')
assert(not S.Apply({id=999999,status='unknown'},false),'unknown IDs get no invented usage')
print('PASS: special item usage, deletion blocked, protection, unknown IDs')
local scroll={id=209848,status='candidate',details=''}
assert(S.Apply(scroll,false) and scroll.usage:find('78146',1,true))
assert(scroll.status=='keep','known purpose does not imply safe deletion')
