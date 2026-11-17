local L=ItemLoreLocale
ItemLoreSpecialItems = {}
function ItemLoreSpecialItems.Apply(row,protected)
    local record=ItemLoreUsageData and ItemLoreUsageData[row.id]
    if not record then return false end
    row.usage=record.summary
    local evidence={
        L['物品 ID：'] .. row.id,
        L['适用版本：'] .. record.version,
        L['用途实测：'] .. (record.tested and L['已实测'] or L['未完整实测']),
        record.verification,
    }
    for _,source in ipairs(record.sources) do
        evidence[#evidence+1]=L['来源（'] .. source.kind .. L['）：'] .. source.reference
    end
    row.usageEvidence=table.concat(evidence,'\n')
    row.status=protected and 'protected' or 'keep'
    row.reason=protected and L['已加入保护名单'] or record.summary
    row.details=record.usage .. '\n' .. row.usageEvidence ..
        ((row.details and row.details~='') and (L['\n关联任务：\n'] .. row.details) or '')
    return true
end
