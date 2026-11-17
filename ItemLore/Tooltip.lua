local hooked=setmetatable({}, {__mode='k'})
local function append(tooltip,itemID)
    if not tooltip or type(itemID)~='number' or not tooltip.AddLine then return end
    if not hooked[tooltip] then
        if not tooltip.HasScript or not tooltip:HasScript('OnTooltipCleared') then return end
        tooltip:HookScript('OnTooltipCleared',function(self) self.questCleanupItem=nil end)
        hooked[tooltip]=true
    end
    if tooltip.questCleanupItem==itemID then return end
    local row=ItemLoreUI.Inspect(itemID)
    if not row then return end
    local hasCompleted=row.completedQuests and #row.completedQuests>0
    if not row.usage and not hasCompleted then
        if row.pendingSummary then
            tooltip.questCleanupItem=itemID
            tooltip:AddLine('物品秘笺：' .. row.pendingSummary,1,0.82,0,true)
        elseif row.isRelevant and row.status=='unknown' then
            tooltip.questCleanupItem=itemID
            tooltip:AddLine('物品秘笺：未知用途',1,0.82,0,true)
        end
        return
    end
    tooltip.questCleanupItem=itemID
    if row.status=='candidate' and not row.usage and hasCompleted then
        tooltip:AddLine('物品秘笺：',1,0.25,0.25,true)
        for _,name in ipairs(row.completedQuests) do
            tooltip:AddLine('任务《' .. name .. '》已完成，建议删除',1,0.25,0.25,true)
        end
        return
    end
    if row.usage then
        tooltip:AddLine('物品秘笺：' .. row.usage .. (row.status=='protected' and '（已保护）' or ''),1,0.82,0,true)
        return
    end
    if hasCompleted then
        tooltip:AddLine('物品秘笺：已完成任务',1,0.82,0,true)
        for _,name in ipairs(row.completedQuests) do tooltip:AddLine(name,0.5,1,0.65,true) end
    end
    local reason=row.status=='candidate' and '疑似残留；不能排除数据库未收录的其他用途。' or row.reason
    tooltip:AddLine(reason or '其他用途尚未确认，请勿仅凭任务完成标记删除。',1,0.82,0,true)
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item,function(tooltip,data)
        if data then append(tooltip,data.id) end
    end)
else
    for _,tooltip in ipairs({GameTooltip,ItemRefTooltip}) do
        if tooltip.HasScript and tooltip:HasScript('OnTooltipSetItem') then
            tooltip:HookScript('OnTooltipSetItem',function(self)
                local _,link=self:GetItem()
                local id=link and tonumber(link:match('item:(%d+)'))
                append(self,id)
            end)
        end
    end
end
