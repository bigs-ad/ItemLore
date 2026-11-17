local objects={}
local function object()
 local o={scripts={},shown=true}
 function o:SetScript(k,v) self.scripts[k]=v end
 function o:CreateTexture() return object() end
 function o:SetShown(v) self.shown=v end
 function o:SetChecked(v) self.checked=v end
 function o:GetChecked() return self.checked end
 function o:SetNormalTexture(v) self.normalTexture=v end
 for _,k in ipairs({'SetSize','SetPoint','SetText','SetTexture','SetTexCoord','RegisterForClicks','RegisterForDrag','RegisterEvent','SetHighlightTexture','ClearAllPoints'}) do o[k]=function() end end
 return o
end
function CreateFrame(_,name,parent)
 local o=object(); o.parent=parent; if name then objects[name]=o end; return o
end
UIParent=object(); Minimap=object(); QuestLogFrame=object()
local opened=0
ItemLoreUI={Toggle=function() opened=opened+1 end}
ItemLoreUI.Open=function() opened=opened+1 end
function InCombatLockdown() return false end
dofile('ItemLore/EntryPoints.lua')
ItemLoreEntries.Initialize()
assert(objects.ItemLoreMinimapButton.shown)
assert(objects.ItemLoreMinimapButton.normalTexture=='Interface\\AddOns\\ItemLore\\Media\\Logo-eye.tga','custom logo texture')
objects.ItemLoreMinimapButton.scripts.OnClick(nil,'LeftButton')
assert(opened==1)
objects.ItemLoreMinimapButton.scripts.OnClick(nil,'RightButton')
assert(objects.ItemLoreMinimapButton.shown and not ItemLoreDB.hideMinimap,'right click must not hide')
assert(opened==1,'right click does nothing')
objects.ItemLoreQuestLogButton.scripts.OnClick()
assert(opened==2)
ItemLoreEntries.SetMinimapShown(false)
assert(not objects.ItemLoreMinimapButton.shown and ItemLoreDB.hideMinimap)
ItemLoreEntries.Initialize()
assert(not objects.ItemLoreMinimapButton.shown,'hidden setting persists')
ItemLoreEntries.SetMinimapShown(true)
assert(objects.ItemLoreMinimapButton.shown)
assert(objects.ItemLoreQuestLogButton.parent==QuestLogFrame)
print('PASS: minimap and quest log entrypoints, saved visibility')
