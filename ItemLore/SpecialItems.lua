ItemLoreSpecialItems = {}
function ItemLoreSpecialItems.Apply(row,protected)
    local record=ItemLoreUsageData and ItemLoreUsageData[row.id]
    if not record then return false end
    row.usage=record.summary
    local evidence={
        '物品 ID：' .. row.id,
        '适用版本：' .. record.version,
        '用途实测：' .. (record.tested and '已实测' or '未完整实测'),
        record.verification,
    }
    for _,source in ipairs(record.sources) do
        evidence[#evidence+1]='来源（' .. source.kind .. '）：' .. source.reference
    end
    row.usageEvidence=table.concat(evidence,'\n')
    row.status=protected and 'protected' or 'keep'
    row.reason=protected and '已加入保护名单' or record.summary
    row.details=record.usage .. '\n' .. row.usageEvidence ..
        ((row.details and row.details~='') and ('\n关联任务：\n' .. row.details) or '')
    return true
end
