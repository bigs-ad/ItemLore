GetLocale=GetLocale or function() return 'zhCN' end
dofile('ItemLore/Locale.lua')
dofile('ItemLore/UsageData.lua')
dofile('ItemLore/SpecialItems.lua')
local count=0
for id,record in pairs(ItemLoreUsageData) do
    assert(type(id)=='number' and record.summary and record.usage)
    assert(record.version=='Forever 1.60.1' and type(record.tested)=='boolean')
    assert(record.verification and #record.sources>0)
    for _,source in ipairs(record.sources) do assert(source.kind and source.reference) end
    local row={id=id,status='candidate',details=''}
    assert(ItemLoreSpecialItems.Apply(row,false) and row.status=='keep')
    assert(row.details:find('适用版本',1,true) and row.details:find('来源',1,true))
    count=count+1
end
assert(count==3)
assert(ItemLoreUsageData[283389].tested==false,'reading does not verify quest effects')
assert(ItemLoreUsageData[283389].summary:find('采购',1,true))
print('PASS: 3 structured records, sources, version, verification and deletion guard')
