for _,locale in ipairs({'enUS','enGB','deDE','zhTW'}) do
    GetLocale=function() return locale end
    dofile('ItemLore/Locale.lua')
    local L=ItemLoreLocale
    assert(L['物品秘笺']=='ItemLore' and L['未知用途']=='Unknown use')
    dofile('ItemLore/Core.lua')
    local status,reason=ItemLoreCore.Classify({classID=12,questIDs={1}},{[1]={done=true,active=false,repeatable=false}},false)
    assert(status=='candidate' and not reason:find('[\128-\255]'),'English classification')
    dofile('ItemLore/UsageData.lua'); dofile('ItemLore/SpecialItems.lua')
    for id in pairs(ItemLoreUsageData) do
        local row={id=id,status='candidate',details='[77] Quest (Active)'}
        ItemLoreSpecialItems.Apply(row,false)
        assert(row.status=='keep' and not row.details:find('[\128-\255]'),'English usage and evidence')
        ItemLoreSpecialItems.Apply(row,true)
        assert(row.status=='protected' and row.reason=='Protected from deletion')
    end
end
GetLocale=function() return 'enUS' end
dofile('ItemLore/tests/view.test.lua')
ItemLoreDB={}
dofile('ItemLore/tests/entrypoints.test.lua')
ItemLoreDB={}
dofile('ItemLore/tests/integration.test.lua')
dofile('ItemLore/tests/tooltip.test.lua')
GetLocale=function() return 'zhCN' end
dofile('ItemLore/Locale.lua')
assert(ItemLoreLocale['保护']=='保护','Chinese remains unchanged')
print('PASS: English fallback, special uses, protection, English UI and Chinese locale')
