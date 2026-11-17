ItemLoreCore = {}
local C = ItemLoreCore
function C.BuildIndex(db)
    assert(type(db.QuestPointers)=='table' and next(db.QuestPointers), 'quest list unavailable')
    local index, count = {}, 0
    local function add(itemID, questID)
        if type(itemID)=='number' and itemID>0 then
            index[itemID]=index[itemID] or {}; index[itemID][questID]=true
        end
    end
    for id in pairs(db.QuestPointers) do
        local objectives=db.QueryQuestSingle(id,'objectives')
        local starters=db.QueryQuestSingle(id,'startedBy')
        assert(type(objectives)=='table' and type(starters)=='table', 'quest record unavailable: ' .. id)
        for _, objective in pairs(objectives[3] or {}) do add(objective[1],id) end
        for _, itemID in pairs(starters[3] or {}) do add(itemID,id) end
        for _, itemID in pairs(db.QueryQuestSingle(id,'requiredSourceItems') or {}) do add(itemID,id) end
        add(db.QueryQuestSingle(id,'sourceItemId'),id)
        count=count+1
        if count%100==0 then coroutine.yield(count) end
    end
    return index
end
function C.Classify(item, quests, protected)
    if protected then return 'protected', '已加入保护名单' end
    if item.classID ~= 12 then return 'keep', '非专用任务物品，不建议清理' end
    if not item.questIDs or #item.questIDs == 0 then return 'unknown', '数据库没有任务关联' end
    local unknown, keep
    for _, id in ipairs(item.questIDs) do
        local q = quests[id]
        if not q or q.done == nil or q.active == nil or q.repeatable == nil then
            unknown = true
        elseif q.active or q.repeatable or not q.done then
            keep = true
        end
    end
    if keep then return 'keep', '关联任务仍在进行、尚未交付或可重复' end
    if unknown then return 'unknown', '任务状态或重复属性无法确认' end
    return 'candidate', '数据库已知关联任务均已完成，且非重复任务；可能存在未收录用途'
end
function C.SameStack(a, b)
    return a and b and a.id == b.id and a.count == b.count and a.link == b.link and not b.locked
end
