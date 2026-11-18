local L=ItemLoreLocale
local palette={brand='ffffd34d',id='ffaaaaaa',name='ffffffff',keep='ff80d8a6',candidate='ffff5757',unknown='ffffc74d',protected='ff9ecfff'}
local function color(kind,value)
    return '|c' .. palette[kind] .. tostring(value) .. '|r'
end
local function task(value,state)
    local id,body=value:match('^(%[%d+%])%s*(.*)$')
    body=body or value
    local at=body:find(L['（'],1,true)
    local name=at and body:sub(1,at-1) or body
    local suffix=at and body:sub(at) or ''
    return (id and (color('id',id) .. ' ') or '') .. color('name',name) .. (suffix~='' and color(state,suffix) or '')
end
local function brand() return color('brand',L['物品秘笺：']) end
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
            tooltip:AddLine(brand() .. task(row.pendingSummary,'keep'),1,1,1,true)
        elseif row.isRelevant and row.status=='unknown' then
            tooltip.questCleanupItem=itemID
            tooltip:AddLine(brand() .. color('unknown',L['未知用途']),1,1,1,true)
        end
        return
    end
    tooltip.questCleanupItem=itemID
    if row.status=='candidate' and not row.usage and hasCompleted then
        for i,name in ipairs(row.completedQuests) do
            tooltip:AddLine((i==1 and brand() or '') .. task(name,'candidate'),1,1,1,true)
        end
        tooltip:AddLine(color('candidate',L['任务已完成，建议删除']),1,1,1,false)
        return
    end
    if row.usage then
        tooltip:AddLine(brand() .. color(row.usage==L['未知用途'] and 'unknown' or 'keep',row.usage) .. (row.status=='protected' and color('protected',L['（已保护）']) or ''),1,1,1,true)
        return
    end
    if hasCompleted then
        tooltip:AddLine(brand() .. color('name',L['已完成任务']),1,1,1,true)
        for _,name in ipairs(row.completedQuests) do tooltip:AddLine(task(name,'keep'),1,1,1,true) end
    end
    local reason=row.status=='candidate' and L['疑似残留；不能排除数据库未收录的其他用途。'] or row.reason
    tooltip:AddLine(color(row.status=='protected' and 'protected' or row.status=='keep' and 'keep' or 'unknown',reason or L['其他用途尚未确认，请勿仅凭任务完成标记删除。']),1,1,1,true)
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
