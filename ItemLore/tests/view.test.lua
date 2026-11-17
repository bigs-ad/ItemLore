local objects={}
local function object(name)
 local o={scripts={},shown=true,text='',height=400,width=900,scroll=0}
 function o:SetScript(k,v) self.scripts[k]=v end
 function o:GetScript(k) return self.scripts[k] end
 function o:HasScript(k) return true end
 function o:SetFocus() self.focused=true end
 function o:ClearFocus() self.focused=false end
 function o:SetText(v) self.text=v; if self.scripts.OnTextChanged then self.scripts.OnTextChanged(self,false) end end
 function o:GetText() return self.text end
 function o:SetSize(w,h) self.width=w; self.height=h end
 function o:SetHeight(h) self.height=h; self.heightWrites=(self.heightWrites or 0)+1 end
 function o:GetHeight() return self.height end
 function o:GetWidth() return self.width end
 function o:GetFont() return 'font',12 end
 function o:SetFont(path,size,flags) self.fontSize=size end
 function o:GetNumLines() return 4 end
 function o:GetStringHeight() return 24 end
 function o:SetEnabled(v) self.enabled=v end
 function o:SetChecked(v) self.checked=v end
 function o:GetChecked() return self.checked end
 function o:GetFrameLevel() return 1 end
 function o:SetFrameLevel(v) self.level=v end
 function o:SetFrameStrata(v) self.strata=v end
 function o:SetHighlightColor(...) self.highlight={...} end
 function o:SetJustifyH(v) self.justifyH=v end
 function o:IsEnabled() return self.enabled~=false end
 function o:SetShown(v) self.shown=v end
 function o:IsShown() return self.shown end
 function o:Show() self.shown=true end
 function o:Hide() self.shown=false end
 function o:SetVerticalScroll(v) self.scroll=v end
 function o:GetVerticalScroll() return self.scroll end
 function o:GetVerticalScrollRange() return 300 end
 function o:CreateTexture() return object() end
 function o:CreateFontString() return object() end
 for _,k in ipairs({'SetPoint','SetWidth','SetAllPoints','SetColorTexture','SetTexture','SetTextColor','SetJustifyV',
 'SetWordWrap','SetNonSpaceWrap','Raise','SetClampedToScreen','SetMovable','EnableMouse',
 'EnableMouseWheel','RegisterForDrag','StartMoving','StopMovingOrSizing','SetScrollChild','SetMultiLine',
 'SetAutoFocus','SetFontObject','SetTextInsets','SetCursorPosition','HighlightText','SetScale','ClearAllPoints'}) do o[k]=function() end end
 if name then objects[name]=o end
 return o
end
function CreateFrame(_,name) return object(name) end
UIParent=object(); UIParent:SetSize(1920,1080); UISpecialFrames={}; ChatFontNormal={}
ItemLoreDB={protected={}}
ItemLoreEntries={SetMinimapShown=function(v) ItemLoreDB.hideMinimap=not v end}
dofile('ItemLore/View.lua')
local deleted,protected=0,0
local deletedRow,protectedRow
local view=ItemLoreView.Create({scan=function() end,settings=function() end,
 protect=function(row) protected=protected+1; protectedRow=row end,delete=function(row) deleted=deleted+1; deletedRow=row end})
assert(view.frame.strata=='FULLSCREEN','separate main UI from other addon dialog subframes')
assert(not objects.ItemLoreInlineSettings and not objects.ItemLoreSettingsToggle,'no settings panel or button')
ItemLoreDB.hideMinimap=true
view:Show()
assert(view.frame.shown and objects.ItemLoreMinimapSetting.shown,'option directly visible')
assert(not objects.ItemLoreMinimapSetting.checked,'existing preference retained')
objects.ItemLoreMinimapSetting:SetChecked(true)
objects.ItemLoreMinimapSetting.scripts.OnClick(objects.ItemLoreMinimapSetting)
assert(not ItemLoreDB.hideMinimap,'inline toggle updates visibility')
ItemLoreDB.hideMinimap=true
view:Update({})
assert(not objects.ItemLoreMinimapSetting.checked,'refresh syncs saved visibility')
assert(objects.ItemLoreInlineDetails.highlight and objects.ItemLoreInlineDetails.highlight[4]>.5,'visible selection highlight')
assert(not objects.ItemLoreInlineDetails.scripts.OnMouseDown,'native mouse selection not overridden')
local a={bag=0,slot=1,id=1,link='Apple',count=1,status='candidate',reason='done',details='[77] Quest'}
local b={bag=0,slot=2,id=2,link='Book',count=1,status='keep',reason='keep',details='',usage='read'}
view:Update({a,b})
assert(view:VisibleCount()==2)
assert(objects.ItemLoreRow1.name.fontSize==18 and objects.ItemLoreRow1.reason.fontSize==16,'readable list text')
assert(objects.ItemLoreInlineDetails.fontSize==18 and objects.ItemLoreSearch.fontSize==18,'readable editable text')
assert(objects.ItemLoreRowProtect1.caption.fontSize==16 and objects.ItemLoreFilter1.caption.fontSize==16,'readable controls')
assert(objects.ItemLoreRowProtect1.width==objects.ItemLoreRowDelete1.width,'row actions have equal width')
assert(objects.ItemLoreRowProtect1.caption.justifyH=='CENTER' and objects.ItemLoreRowDelete1.caption.justifyH=='CENTER','row action labels centered')
assert(not objects.ItemLoreDelete and not objects.ItemLoreProtect,'actions belong to rows, not detail panel')
objects.ItemLoreRowProtect2.scripts.OnClick(); assert(protected==1 and protectedRow==b,'protect unselected row')
objects.ItemLoreRowDelete1.scripts.OnClick(); assert(deleted==1 and deletedRow==a,'delete unselected row')
objects.ItemLoreRow1.scripts.OnClick()
assert(not objects.ItemLoreInlineDetails.heightWrites,'multiline edit height remains native')
assert(objects.ItemLoreInlineDetails.text:find('[77]',1,true))
local detailBox=objects.ItemLoreInlineDetails
assert(not detailBox.focused,'item selection does not capture typing')
local original=detailBox.text
detailBox:SetFocus(); detailBox.scripts.OnCharComposition(detailBox,'bei')
assert(not detailBox.focused and detailBox.text==original,'IME composition exits copy-only field')
detailBox:SetFocus(); detailBox.text=original .. 'abc'; detailBox.scripts.OnTextChanged(detailBox,true)
assert(not detailBox.focused and detailBox.text==original,'typing and paste do not change details')
objects.ItemLoreSearch:SetText('Book'); assert(view:VisibleCount()==1)
assert(not objects.ItemLoreRowDelete1.enabled,'reused row updates delete permission')
objects.ItemLoreRowDelete1.scripts.OnClick(); assert(deleted==1)
objects.ItemLoreRowProtect1.scripts.OnClick(); assert(protected==2 and protectedRow==b)
objects.ItemLoreSearch:SetText('')
objects.ItemLoreFilter2.scripts.OnClick(); assert(view:VisibleCount()==1)
view:Update({b}); assert(view:VisibleCount()==0 and not objects.ItemLoreRow1.shown)
objects.ItemLoreFilter1.scripts.OnClick()
objects.ItemLoreSearch:SetText('77'); view:Update({a,b}); assert(view:VisibleCount()==1,'search task ID')
objects.ItemLoreSearch:SetText('')
local unknown={bag=0,slot=3,id=3,link='Odd',count=1,status='keep',usage='未知用途',reason='unknown',details=''}
view:Update({a,b,unknown}); objects.ItemLoreFilter5.scripts.OnClick(); assert(view:VisibleCount()==1)
objects.ItemLoreRow1.scripts.OnClick(); objects.ItemLoreRowDelete1.scripts.OnClick(); assert(deleted==1,'unknown cannot delete')
unknown.status='protected'; ItemLoreDB.protected[3]=true
objects.ItemLoreFilter6.scripts.OnClick(); view:Update({unknown}); assert(view:VisibleCount()==1)
objects.ItemLoreRow1.scripts.OnClick(); assert(objects.ItemLoreRowProtect1.caption.text=='取消保护')
objects.ItemLoreFilter1.scripts.OnClick(); a.locked=true; view:Update({a})
objects.ItemLoreRow1.scripts.OnClick(); assert(not objects.ItemLoreRowDelete1.enabled,'locked candidate disabled')
local task={id=4,bag=0,slot=4,link='Task item',count=1,status='keep',
 reason='[209] Quest（进行中）',pendingSummary='[209] Quest（进行中）',details='[209] Quest (进行中)'}
view:Update({task}); objects.ItemLoreRow1.scripts.OnClick()
local _,count=objects.ItemLoreInlineDetails.text:gsub('%[209%]','')
assert(count==1,'pending task shown only once')
task.reason='[209] Quest（进行中）；另 1 项'; task.pendingSummary=task.reason
task.details=task.details .. '\n[210] Other (未完成任务)'
view:Update({task})
local _,count=objects.ItemLoreInlineDetails.text:gsub('%[209%]','')
assert(count==1 and objects.ItemLoreInlineDetails.text:find('[210]',1,true),'all tasks retained without summary duplicate')
task.status='protected'; task.reason='已加入保护名单'
view:Update({task})
assert(objects.ItemLoreInlineDetails.text:find('已加入保护名单',1,true),'protection explanation retained')
print('PASS: custom UI search, categories, inline selection, actions and deduplicated details')
