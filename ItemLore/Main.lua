local C = ItemLoreCore
local rows, page, frame, statusText = {}, 1
local reverseIndex, indexWorker, indexError, indexProgress
local labels = {candidate='疑似残留',keep='保留',unknown='无法确定',protected='已保护'}
local function say(s) DEFAULT_CHAT_FRAME:AddMessage('|cff80d8b0物品秘笺：|r' .. s) end
local function call(fn, ...)
    if type(fn) ~= 'function' then return nil end
    local ok, value = pcall(fn, ...)
    if ok then return value end
end
local function api(name)
    return C_Container and C_Container[name] or _G[name]
end
local function stack(bag, slot)
    local v = call(api('GetContainerItemInfo'), bag, slot)
    if type(v) ~= 'table' or not v.itemID then return nil end
    return {id=v.itemID,count=v.stackCount,link=v.hyperlink,locked=v.isLocked,bag=bag,slot=slot,icon=v.iconFileID}
end
local function provider()
    if not QuestieLoader then return nil end
    local ok, db = pcall(QuestieLoader.ImportModule, QuestieLoader, 'QuestieDB')
    if ok and db and db.QueryItemSingle and db.QueryQuestSingle then return db end
end
local function examine(row)
    local db = provider()
    local item = {questIDs={}}
    local seen, states, details = {}, {}, {}
    row.completedQuests={}
    local pendingTasks={}
    local info = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if info then
        local ok, _, _, _, _, _, classID = pcall(info, row.id)
        if ok then item.classID = classID end
    end
    local function add(id)
        if type(id)=='number' and id>0 and not seen[id] then
            seen[id]=true; item.questIDs[#item.questIDs+1]=id
        end
    end
    if db then
        local related = call(db.QueryItemSingle, row.id, 'relatedQuests')
        if type(related)=='table' then for _, id in ipairs(related) do add(id) end end
        add(call(db.QueryItemSingle, row.id, 'startQuest'))
    end
    if db and reverseIndex then
        for id in pairs(reverseIndex[row.id] or {}) do add(id) end
    end
    table.sort(item.questIDs)
    for _, id in ipairs(item.questIDs) do
        local special = call(db.QueryQuestSingle, id, 'specialFlags')
        local flags = call(db.QueryQuestSingle, id, 'questFlags')
        local name = call(db.QueryQuestSingle, id, 'name')
        local q = {}
        if name and type(special)=='number' and type(flags)=='number' then
            -- Unknown special flags are deliberately treated as reusable/event items.
            q.repeatable = special ~= 0 or (math.floor(flags/4096)%2==1)
                or (math.floor(flags/32768)%2==1) or (math.floor(flags/65536)%2==1)
            q.done = call(C_QuestLog and C_QuestLog.IsQuestFlaggedCompleted or IsQuestFlaggedCompleted, id)
            q.active = call(C_QuestLog and C_QuestLog.IsOnQuest, id)
        end
        states[id]=q
        if name and (q.active==true or q.done==false) then
            pendingTasks[#pendingTasks+1]={name=name,active=q.active==true,id=id}
        end
        if q.done==true then row.completedQuests[#row.completedQuests+1]='[' .. id .. '] ' .. (name or '?') end
        details[#details+1]='[' .. id .. '] ' .. (name or '?') .. ' (' ..
            (q.active and '进行中' or q.done==true and '已完成任务' or q.done==false and '未完成任务' or '未知') .. ')'
    end
    row.status, row.reason = C.Classify(item, states, ItemLoreDB.protected[row.id])
    if not db then row.status='unknown'; row.reason='Questie 数据库尚未就绪或未启用' end
    if not item.classID then row.status='unknown'; row.reason='物品分类接口未返回数据' end
    if not reverseIndex then
        row.status='unknown'
        row.reason=indexError and ('任务索引不可用：' .. indexError) or '正在建立任务关联索引，暂不允许删除'
    end
    row.details = table.concat(details, '\n')
    local special=ItemLoreSpecialItems and ItemLoreSpecialItems.Apply(row,ItemLoreDB.protected[row.id])
    row.sortStatus=row.status
    if row.status=='protected' then
        -- Protection changes actions, not the item's sorting priority.
        row.sortStatus=special and 'keep' or C.Classify(item,states,false)
    end
    if not special and row.status=='keep' and #pendingTasks>0 then
        table.sort(pendingTasks,function(a,b)
            if a.active~=b.active then return a.active end
            return a.id<b.id
        end)
        local first=pendingTasks[1]
        row.reason='[' .. first.id .. '] ' .. first.name .. '（' .. (first.active and '进行中' or '未完成') .. '）'
        if #pendingTasks>1 then row.reason=row.reason .. '；另 ' .. (#pendingTasks-1) .. ' 项' end
        row.pendingSummary=row.reason
    end
    local databaseClass=db and call(db.QueryItemSingle,row.id,'class')
    row.isRelevant=special or item.classID==12 or (not item.classID and databaseClass==12)
    return row.isRelevant
end
local refresh, scan, ensureIndex
local function destroy(expected)
    if InCombatLockdown() or GetCursorInfo() then say('战斗中或鼠标持有物品，已取消。'); return end
    local current = stack(expected.bag, expected.slot)
    if not C.SameStack(expected,current) then say('背包物品发生变化，已取消，请重新扫描。'); return end
    examine(current)
    if current.status~='candidate' then say('清理条件已改变，已取消。'); return end
    local pickup = api('PickupContainerItem')
    if type(pickup)~='function' or type(DeleteCursorItem)~='function' then say('客户端不支持删除接口。'); return end
    local ok = pcall(pickup,current.bag,current.slot)
    local kind, id, link = GetCursorInfo()
    if not ok or kind~='item' or id~=expected.id or link~=expected.link then
        if kind then ClearCursor() end
        say('未能确认拾取的物品，已取消。'); return
    end
    local deleted = pcall(DeleteCursorItem)
    if not deleted or GetCursorInfo() then ClearCursor(); say('删除未完成，可能受到客户端限制。')
    else say('已发送删除请求：' .. expected.link) end
    scan()
end
StaticPopupDialogs.ITEMLORE_DELETE = {
    text='删除整组 %s？\n\n仅依据 Questie 已收录的任务判断，不能排除遗漏用途。删除不能由本插件撤销。',
    button1='确认删除',button2='取消',timeout=0,whileDead=false,hideOnEscape=true,
    OnAccept=function(self,data) if data then destroy(data) end end,
    OnHide=function(self)
        if self.itemLorePreviousStrata then
            self:SetFrameStrata(self.itemLorePreviousStrata)
            self.itemLorePreviousStrata=nil
        end
    end,
}
local view
local function show()
    if not view then
        view=ItemLoreView.Create({
            scan=function() indexError=nil; scan() end,
            protect=function(row)
                ItemLoreDB.protected[row.id]=not ItemLoreDB.protected[row.id] or nil
                scan()
            end,
            delete=function(row)
                if row.status~='candidate' then return end
                local copy={}; for k,v in pairs(row) do copy[k]=v end
                local popup=StaticPopup_Show('ITEMLORE_DELETE',copy.link .. ' x' .. copy.count,nil,copy)
                if popup then
                    popup.itemLorePreviousStrata=popup:GetFrameStrata()
                    popup:SetFrameStrata('FULLSCREEN_DIALOG'); popup:Raise()
                end
            end,
        })
        frame=view.frame
    end
    view:Show()
end
refresh=function()
    if view then view:Update(rows,indexWorker and (indexProgress or 0) or nil) end
end
scan=function()
    ItemLoreDB=ItemLoreDB or {}; ItemLoreDB.protected=ItemLoreDB.protected or {}
    ensureIndex()
    rows={}
    if not C_Container or not C_Container.GetContainerItemInfo then
        say('当前客户端缺少结构化背包接口，已停止扫描。'); refresh(); return
    end
    for bag=0,4 do
        for slot=1,(call(api('GetContainerNumSlots'),bag) or 0) do
            local row=stack(bag,slot)
            if row and row.link and examine(row) then rows[#rows+1]=row end
        end
    end
    local rank={candidate=1,unknown=2,keep=3,protected=4}
    table.sort(rows,function(a,b)
        if rank[a.sortStatus]~=rank[b.sortStatus] then return rank[a.sortStatus]<rank[b.sortStatus] end
        if a.bag~=b.bag then return a.bag<b.bag end
        return a.slot<b.slot
    end)
    refresh()
end
ensureIndex=function()
    if reverseIndex or indexWorker or indexError then return end
    local db=provider()
    if not db or not db.QuestPointers or not next(db.QuestPointers) then
        indexError='Questie 尚未就绪，请稍后重新扫描'; return
    end
    indexWorker=coroutine.create(function() return C.BuildIndex(db) end)
    local function step()
        local ok,value=coroutine.resume(indexWorker)
        if not ok then
            indexWorker=nil; indexError=tostring(value); say('任务索引失败：' .. indexError); scan(); return
        end
        if coroutine.status(indexWorker)=='dead' then
            reverseIndex=value; indexWorker=nil; scan()
        else
            indexProgress=value; refresh(); C_Timer.After(0,step)
        end
    end
    C_Timer.After(0,step)
end
SLASH_ITEMLORE1='/itemlore'
SlashCmdList.ITEMLORE=function(command)
    if command and command:match('^%s*settings%s*$') then ItemLoreSettings.Open(); return end
    show(); scan()
end
ItemLoreUI={OpenSettings=function() show(); scan() end, Open=function() show(); scan() end, Toggle=function()
    if frame and frame:IsShown() then frame:Hide() else show(); scan() end
end, Inspect=function(itemID)
    ItemLoreDB=ItemLoreDB or {}; ItemLoreDB.protected=ItemLoreDB.protected or {}
    ensureIndex()
    local row={id=itemID}
    examine(row)
    return row
end}
local events=CreateFrame('Frame')
events:RegisterEvent('BAG_UPDATE_DELAYED'); events:RegisterEvent('QUEST_LOG_UPDATE')
events:SetScript('OnEvent',function() if frame and frame:IsShown() then scan() end end)
