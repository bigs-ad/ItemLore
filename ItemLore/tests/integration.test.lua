local buttons, popup, deleted, picked = {}, nil, 0, 0
local window, renderedRows
local bagItem={itemID=101,stackCount=2,hyperlink='item:101',isLocked=false}
local cursor, combat, completed, active, special = nil,false,true,false,0
local function obj()
    local o={scripts={},shown=true}
    function o:SetScript(k,v) self.scripts[k]=v end
    function o:SetText(t) self.text=t end
    function o:SetEnabled(v) self.enabled=v end
    function o:SetChecked(v) self.checked=v end
    function o:SetShown(v) self.shown=v end
    function o:Show() self.shown=true end
    function o:Hide() self.shown=false end
    function o:IsShown() return self.shown end
    function o:SetFrameStrata(s) self.strata=s end
    function o:Raise() self.raised=(self.raised or 0)+1 end
    function o:CreateFontString() return obj() end
    function o:CreateTexture() return obj() end
    function o:GetStringHeight() return 36 end
    for _,k in ipairs({'SetSize','SetPoint','SetClampedToScreen','SetMovable','EnableMouse','RegisterForDrag',
        'StartMoving','StopMovingOrSizing','SetWidth','SetHeight','SetJustifyH','SetTexture','RegisterEvent',
        'SetWordWrap','SetNonSpaceWrap','SetScrollChild','ClearAllPoints'}) do o[k]=function() end end
    return o
end
function CreateFrame(kind,name)
    local o=obj(); o.TitleText=obj()
    if name=='ItemLoreWindow' then window=o end
    if kind=='Button' then buttons[#buttons+1]=o end
    return o
end
UIParent={}; UISpecialFrames={}; SlashCmdList={}; StaticPopupDialogs={}
DEFAULT_CHAT_FRAME={AddMessage=function() end}
C_Container={
    GetContainerNumSlots=function(b) return b==0 and 1 or 0 end,
    GetContainerItemInfo=function() return bagItem end,
    PickupContainerItem=function() picked=picked+1; cursor={bagItem.itemID,bagItem.hyperlink} end,
}
C_Item={GetItemInfoInstant=function(id) return id,'Quest','',nil,1,12 end}
C_QuestLog={IsOnQuest=function() return active end, IsQuestFlaggedCompleted=function() return completed end}
local timers={}
C_Timer={After=function(_,fn) timers[#timers+1]=fn end}
QuestieLoader={ImportModule=function() return {
    QuestPointers={[77]=true},
    QueryItemSingle=function() return nil end,
    QueryQuestSingle=function(id,key)
        if key=='name' then return 'Test quest' elseif key=='specialFlags' then return special
        elseif key=='questFlags' then return 0
        elseif key=='objectives' then return {[3]={{101,2}}}
        elseif key=='startedBy' or key=='requiredSourceItems' then return {} end
    end,
} end}
function InCombatLockdown() return combat end
function GetCursorInfo() if cursor then return 'item',cursor[1],cursor[2] end end
function ClearCursor() cursor=nil end
function DeleteCursorItem() deleted=deleted+1; cursor=nil; bagItem=nil end
function StaticPopup_Show(key,text,unused,data) popup={key=key,data=data} end
ItemLoreView={Create=function(actions)
    local f=CreateFrame('Frame','ItemLoreWindow'); f:SetFrameStrata('DIALOG')
    local current
    for i=1,3 do buttons[i]=obj() end
    buttons[1].scripts.OnClick=function() if current then actions.protect(current) end end
    buttons[2].scripts.OnClick=function() if current then actions.delete(current) end end
    return {frame=f,Show=function() f:Show(); f:Raise() end,Update=function(_,rows)
        renderedRows=rows
        current=rows[1]
        buttons[2]:SetShown(current~=nil)
        buttons[2]:SetEnabled(current and current.status=='candidate' and not current.locked)
    end}
end}
dofile('ItemLore/Core.lua'); dofile('ItemLore/Main.lua')
local function open()
    SlashCmdList.ITEMLORE()
    while #timers>0 do table.remove(timers,1)() end
end
local function request()
    open(); assert(buttons[2].enabled,'candidate must enable delete')
    buttons[2].scripts.OnClick(); assert(popup)
end
local function accept() StaticPopupDialogs[popup.key].OnAccept(nil,popup.data) end
request(); assert(deleted==0 and picked==0,'scan and popup never destroy')
assert(window.strata=='DIALOG' and window.raised,'window must open in foreground')
local raises=window.raised
ItemLoreUI.Open()
assert(window.shown and window.raised>raises,'open visible window raises rather than hides')
combat=true; accept(); assert(picked==0); combat=false
cursor={909,'item:909'}; accept(); assert(picked==0 and cursor[1]==909); cursor=nil
bagItem.stackCount=3; accept(); assert(picked==0); bagItem.stackCount=2
bagItem.itemID=202; accept(); assert(picked==0); bagItem.itemID=101
bagItem.isLocked=true; accept(); assert(picked==0); bagItem.isLocked=false
completed=false; accept(); assert(picked==0); completed=true
active=true; accept(); assert(picked==0); active=false
special=1; accept(); assert(picked==0); special=0
ItemLoreDB.protected[101]=true; accept(); assert(picked==0); ItemLoreDB.protected[101]=nil
local loader=QuestieLoader; QuestieLoader=nil; accept(); assert(picked==0); QuestieLoader=loader
request(); accept(); assert(deleted==1 and picked==1,'confirmed stable candidate deleted once')
accept(); assert(deleted==1,'stale confirmation cannot repeat deletion')
assert(#ItemLoreUI.Inspect(101).completedQuests==1,'inspect exposes rewarded quest')
completed=false
assert(#ItemLoreUI.Inspect(101).completedQuests==0,'unrewarded quests never labeled handed in')
completed=true; active=true
local inspected=ItemLoreUI.Inspect(101)
assert(inspected.status=='keep' and #inspected.completedQuests==1,'active repeat pickup remains protected')
print('PASS: UI scan, confirmation, 10 refusal paths, deletion and stale confirmation')
dofile('ItemLore/UsageData.lua')
dofile('ItemLore/SpecialItems.lua')
completed=true; active=false
bagItem={itemID=4639,stackCount=1,hyperlink='item:4639',isLocked=false}
open()
assert(buttons[2].shown and not buttons[2].enabled,'special item included but deletion disabled')
assert(ItemLoreUI.Inspect(4639).usage,'special usage exposed in item inspection')
print('PASS: special item scanned without quest association and never deletable')
for _,classID in ipairs({0,5,7}) do
    C_Item.GetItemInfoInstant=function(id) return id,'Ordinary','',nil,1,classID end
    bagItem={itemID=101,stackCount=1,hyperlink='item:101',isLocked=false}
    open()
    assert(not buttons[2].shown,'ordinary items excluded despite quest association')
    assert(#ItemLoreUI.Inspect(101).completedQuests==1,'tooltip still receives quest associations')
end
bagItem={itemID=4639,stackCount=1,hyperlink='item:4639',isLocked=false}
open(); assert(buttons[2].shown and not buttons[2].enabled,'catalogued special item remains visible regardless of class')
print('PASS: ordinary categories filtered; tooltip and special item coverage retained')
C_Item.GetItemInfoInstant=function(id) return id,'Quest','',nil,1,12 end
completed=false; active=true
local pending=ItemLoreUI.Inspect(101)
assert(pending.reason=='[77] Test quest（进行中）')
active=false
assert(ItemLoreUI.Inspect(101).reason=='[77] Test quest（未完成）')
completed=true
assert(ItemLoreUI.Inspect(101).status=='candidate','display change cannot affect classification')
print('PASS: unfinished task names and state shown; classification unchanged')
local inventory={
 {itemID=101,stackCount=1,hyperlink='item:101',isLocked=false},
 {itemID=4639,stackCount=1,hyperlink='item:4639',isLocked=false},
}
C_Container.GetContainerNumSlots=function(b) return b==0 and #inventory or 0 end
C_Container.GetContainerItemInfo=function(_,slot) return inventory[slot] end
open()
assert(renderedRows[1].id==101 and renderedRows[2].id==4639)
buttons[1].scripts.OnClick()
assert(renderedRows[1].id==101 and renderedRows[1].status=='protected','protect must preserve position')
open()
assert(renderedRows[1].id==101,'rescan must preserve protected item priority')
buttons[1].scripts.OnClick()
assert(renderedRows[1].id==101 and renderedRows[1].status=='candidate','unprotect must preserve position')
print('PASS: protection and rescanning preserve item ordering')
ItemLoreUI.OpenSettings()
assert(window.shown,'settings command opens the main view')
