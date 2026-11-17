local L=ItemLoreLocale
ItemLoreEntries = {}
local E=ItemLoreEntries
local mini, questButton
BINDING_HEADER_ITEMLORE=L['物品秘笺']
BINDING_NAME_ITEMLORE_TOGGLE=L['打开 / 关闭物品秘笺']
local function tip(self,title,body)
    GameTooltip:SetOwner(self,'ANCHOR_LEFT')
    GameTooltip:SetText(title)
    if body then GameTooltip:AddLine(body,1,1,1,true) end
    GameTooltip:Show()
end
function E.SetMinimapShown(shown)
    ItemLoreDB=ItemLoreDB or {}
    ItemLoreDB.hideMinimap=not shown
    if mini then mini:SetShown(shown) end
end
local function position()
    local angle=math.rad(ItemLoreDB.minimapAngle or 220)
    mini:ClearAllPoints()
    mini:SetPoint('CENTER',Minimap,'CENTER',math.cos(angle)*80,math.sin(angle)*80)
end
function E.Initialize()
    if InCombatLockdown() then return end
    ItemLoreDB=ItemLoreDB or {}
    if Minimap and not mini then
        mini=CreateFrame('Button','ItemLoreMinimapButton',Minimap)
        mini:SetSize(32,32)
        mini:SetNormalTexture('Interface\\AddOns\\ItemLore\\Media\\Logo-eye.tga')
        mini:SetHighlightTexture('Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight')
        mini:RegisterForClicks('LeftButtonUp')
        mini:RegisterForDrag('LeftButton')
        mini:SetScript('OnClick',function(_,which)
            if which=='LeftButton' then ItemLoreUI.Toggle() end
        end)
        mini:SetScript('OnDragStart',function(self)
            self:SetScript('OnUpdate',function()
                local x,y=GetCursorPosition()
                local mx,my=Minimap:GetCenter()
                local scale=Minimap:GetEffectiveScale()
                ItemLoreDB.minimapAngle=math.deg(math.atan2(y/scale-my,x/scale-mx))
                position()
            end)
        end)
        mini:SetScript('OnDragStop',function(self) self:SetScript('OnUpdate',nil) end)
        mini:SetScript('OnEnter',function(self) tip(self,L['物品秘笺'],L['左键打开；拖动调整位置。显示开关位于主窗口右下角。']) end)
        mini:SetScript('OnLeave',function() GameTooltip:Hide() end)
    end
    if mini then position(); mini:SetShown(not ItemLoreDB.hideMinimap) end
    local parent=QuestLogExFrame or ClassicQuestLog or QuestLogFrame or QuestMapFrame
    if parent and not questButton then
        questButton=CreateFrame('Button','ItemLoreQuestLogButton',parent,'UIPanelButtonTemplate')
        questButton:SetSize(132,24)
        -- Outside the content area: do not replace abandon/share or quest tracking controls.
        questButton:SetPoint('TOPLEFT',parent,'BOTTOMLEFT',18,0)
        questButton:SetText(L['物品秘笺'])
        questButton:SetScript('OnClick',function() ItemLoreUI.Open() end)
        questButton:SetScript('OnEnter',function(self) tip(self,L['物品秘笺']) end)
        questButton:SetScript('OnLeave',function() GameTooltip:Hide() end)
    end
end
local events=CreateFrame('Frame')
events:RegisterEvent('PLAYER_LOGIN'); events:RegisterEvent('ADDON_LOADED'); events:RegisterEvent('PLAYER_REGEN_ENABLED')
events:SetScript('OnEvent',function(_,event)
    if event=='PLAYER_LOGIN' or (IsLoggedIn and IsLoggedIn()) then E.Initialize() end
end)
