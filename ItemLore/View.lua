local L=ItemLoreLocale
ItemLoreView={}
local colors={candidate={1,.34,.34},unknown={1,.78,.3},keep={.5,.83,.65},protected={.64,.7,.78}}
local labels={candidate=L['建议删除'],unknown=L['未知用途'],keep=L['保留'],protected=L['已保护']}
local function plain(s)
    return (tostring(s or ''):gsub('|c%x%x%x%x%x%x%x%x',''):gsub('|r',''):gsub('|H.-|h(.-)|h','%1'))
end
local function fill(parent,r,g,b)
    local t=parent:CreateTexture(nil,'BACKGROUND'); t:SetAllPoints(); t:SetColorTexture(r,g,b,1); return t
end
local function fontSize(region,size)
    local path,_,flags=region:GetFont()
    if path then region:SetFont(path,size,flags) end
end
local function text(parent,value,x,y,width,style)
    local t=parent:CreateFontString(nil,'OVERLAY',style or 'GameFontHighlight')
    fontSize(t,style=='GameFontNormalLarge' and 20 or style=='GameFontHighlightSmall' and 16 or 18)
    t:SetPoint('TOPLEFT',x,y); t:SetWidth(width); t:SetJustifyH('LEFT'); t:SetText(value)
    return t
end
local function button(parent,name,label,x,y,w,action)
    local b=CreateFrame('Button',name,parent); b:SetSize(w,32); b:SetPoint('TOPLEFT',x,y)
    b.bg=fill(b,.19,.20,.22)
    b.caption=text(b,label,6,-7,w-12,'GameFontHighlightSmall')
    b.caption:ClearAllPoints(); b.caption:SetPoint('CENTER',b,'CENTER',0,0); b.caption:SetJustifyH('CENTER')
    b:SetScript('OnClick',function() if b:IsEnabled() then action() end end)
    b:SetScript('OnEnter',function() if b:IsEnabled() then b.bg:SetColorTexture(.27,.29,.31,1) end end)
    b:SetScript('OnLeave',function() b.bg:SetColorTexture(.19,.20,.22,1) end)
    return b
end
local function scroll(parent,name,x,y,w,h)
    local s=CreateFrame('ScrollFrame',name,parent); s:SetPoint('TOPLEFT',x,y); s:SetSize(w,h)
    s:EnableMouseWheel(true)
    s:SetScript('OnMouseWheel',function(self,delta)
        self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-delta*40)))
    end)
    button(parent,nil,'^',x+w+3,y,22,function() s:GetScript('OnMouseWheel')(s,3) end)
    button(parent,nil,'v',x+w+3,y-h+32,22,function() s:GetScript('OnMouseWheel')(s,-3) end)
    return s
end
function ItemLoreView.Create(actions)
    local frame=CreateFrame('Frame','ItemLoreWindow',UIParent)
    frame:SetSize(940,570); frame:SetPoint('CENTER'); frame:SetFrameStrata('FULLSCREEN')
    frame:SetClampedToScreen(true); frame:SetMovable(true); frame:EnableMouse(true)
    fill(frame,.12,.13,.15)
    UISpecialFrames[#UISpecialFrames+1]='ItemLoreWindow'
    local drag=CreateFrame('Frame',nil,frame); drag:SetSize(710,38); drag:SetPoint('TOPLEFT')
    drag:EnableMouse(true); drag:RegisterForDrag('LeftButton')
    drag:SetScript('OnDragStart',function() frame:StartMoving() end)
    drag:SetScript('OnDragStop',function() frame:StopMovingOrSizing() end)
    local logo=frame:CreateTexture(nil,'ARTWORK')
    logo:SetSize(36,36); logo:SetPoint('TOPLEFT',12,-2)
    logo:SetTexture('Interface\\AddOns\\ItemLore\\Media\\Logo-eye.tga')
    text(frame,L['物品秘笺'],54,-13,170,'GameFontNormalLarge')
    button(frame,nil,'X',890,-6,32,function() frame:Hide() end)
    local searchBg=CreateFrame('Frame',nil,frame); searchBg:SetSize(270,28); searchBg:SetPoint('TOPLEFT',520,-6); fill(searchBg,.075,.08,.09)
    text(frame,L['搜索'],452,-14,62,'GameFontHighlightSmall')
    local search=CreateFrame('EditBox','ItemLoreSearch',searchBg)
    search:SetSize(258,24); search:SetPoint('TOPLEFT',6,-2); search:SetAutoFocus(false); search:SetFontObject(ChatFontNormal)
    fontSize(search,18)
    search:EnableMouse(true); search:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    local data,visible,pool,selected={}, {}, {}, nil
    local category,query,detailText=1,'',''
    local categories={L['全部'],L['建议删除'],L['任务相关'],L['特殊用途'],L['未知用途'],L['已保护']}
    local tabs={}
    local render
    local status=text(frame,'',18,-91,890,'GameFontHighlightSmall')
    local list=scroll(frame,'ItemLoreListScroll',14,-116,470,390)
    local child=CreateFrame('Frame',nil,list); child:SetSize(470,390); list:SetScrollChild(child)
    local divider=frame:CreateTexture(nil,'ARTWORK'); divider:SetSize(1,390); divider:SetPoint('TOPLEFT',518,-116); divider:SetColorTexture(.27,.29,.31,1)
    local title=text(frame,L['选择物品'],540,-116,360,'GameFontNormal')
    local detail=scroll(frame,'ItemLoreDetailScroll',536,-146,360,320)
    local edit=CreateFrame('EditBox','ItemLoreInlineDetails',detail)
    edit:SetMultiLine(true); edit:SetAutoFocus(false); edit:SetFontObject(ChatFontNormal); edit:SetWidth(356)
    fontSize(edit,18)
    edit:SetTextInsets(4,4,4,4); edit:EnableMouse(true)
    edit:SetHighlightColor(.08,.42,.78,.9)
    local function rejectInput(self)
        self:ClearFocus()
        if self:GetText()~=detailText then self:SetText(detailText) end
    end
    edit:SetScript('OnChar',rejectInput)
    if edit:HasScript('OnCharComposition') then edit:SetScript('OnCharComposition',rejectInput) end
    edit:SetScript('OnTextChanged',function(self,user)
        if user and self:GetText()~=detailText then rejectInput(self) end
        -- Multiline EditBox owns its height; resizing it here breaks mouse hit-testing on some clients.
    end)
    edit:SetScript('OnEscapePressed',function(self) self:ClearFocus() end)
    detail:SetScrollChild(edit)
    button(frame,nil,L['全选'],540,-477,100,function() edit:SetFocus(); edit:HighlightText() end)
    local minimap=CreateFrame('CheckButton','ItemLoreMinimapSetting',frame)
    minimap:SetPoint('BOTTOMRIGHT',-18,12); minimap:SetSize(220,32)
    local box=fill(minimap,.27,.29,.31)
    box:ClearAllPoints(); box:SetPoint('LEFT',0,0); box:SetSize(24,24)
    local mark=text(minimap,'X',5,-6,20,'GameFontHighlightSmall')
    text(minimap,L['显示小地图按钮'],36,-6,184)
    local function syncMinimap()
        local shown=not (ItemLoreDB and ItemLoreDB.hideMinimap)
        minimap:SetChecked(shown); mark:SetShown(shown)
    end
    minimap:SetScript('OnClick',function(self)
        ItemLoreEntries.SetMinimapShown(self:GetChecked()); syncMinimap()
    end)
    local function detailUpdate()
        title:SetText(selected and L['物品详情'] or L['选择物品'])
        local lines={}
        if selected then
            lines={plain(selected.link),L['物品 ID：'] .. selected.id,L['数量：'] .. selected.count}
            local reason,details=selected.reason or '',selected.details or ''
            -- The full task list already includes the compact pending-task summary.
            if reason~='' and not (details~='' and reason==selected.pendingSummary) then
                lines[#lines+1]=''; lines[#lines+1]=reason
            end
            if details~='' then lines[#lines+1]=''; lines[#lines+1]=details end
        end
        detailText=table.concat(lines,'\n')
        detailText=plain(detailText)
        if edit:GetText()~=detailText then
            edit:SetText(detailText); edit:SetCursorPosition(0); detail:SetVerticalScroll(0)
            edit:ClearFocus()
        end
    end
    local function matches(r)
        if category==2 and r.status~='candidate' then return false end
        if category==3 and r.usage then return false end
        if category==4 and not r.usage then return false end
        if category==5 and r.status~='unknown' and r.usage~=L['未知用途'] then return false end
        if category==6 and r.status~='protected' then return false end
        local hay=plain(r.link) .. ' ' .. r.id .. ' ' .. (r.reason or '') .. ' ' .. (r.details or '')
        return query=='' or hay:lower():find(query,1,true)~=nil
    end
    render=function()
        visible={}
        local retained
        for _,r in ipairs(data) do
            if matches(r) then
                visible[#visible+1]=r
                if selected and r.id==selected.id and r.bag==selected.bag and r.slot==selected.slot then retained=r end
            end
        end
        selected=retained
        local offset=0
        for i,r in ipairs(visible) do
            local b=pool[i]
            if not b then
                b=CreateFrame('Button','ItemLoreRow' .. i,child); b:SetWidth(466); b.bg=fill(b,.15,.16,.18)
                b.icon=b:CreateTexture(nil,'ARTWORK'); b.icon:SetSize(32,32); b.icon:SetPoint('TOPLEFT',8,-10)
                b.name=text(b,'',50,-9,216); b.name:SetWordWrap(true); b.name:SetNonSpaceWrap(true)
                b.reason=text(b,'',50,-32,402,'GameFontHighlightSmall'); b.reason:SetWordWrap(true); b.reason:SetNonSpaceWrap(true)
                b:SetScript('OnClick',function() selected=b.row; render() end)
                b.protect=button(b,'ItemLoreRowProtect' .. i,L['保护'],274,-7,92,function()
                    if b.row then actions.protect(b.row) end
                end)
                b.delete=button(b,'ItemLoreRowDelete' .. i,L['删除'],370,-7,92,function()
                    if b.row and b.row.status=='candidate' and not b.row.locked then actions.delete(b.row) end
                end)
                for _,control in ipairs({b.protect,b.delete}) do
                    control.caption:ClearAllPoints()
                    control.caption:SetPoint('CENTER',control,'CENTER',0,0)
                    control.caption:SetJustifyH('CENTER')
                end
                pool[i]=b
            end
            b.row=r; b:Show(); b:ClearAllPoints(); b:SetPoint('TOPLEFT',0,-offset)
            b.icon:SetTexture(r.icon); b.name:SetText(plain(r.link) .. ' x' .. r.count); b.name:SetHeight(0)
            b.protect.caption:SetText(ItemLoreDB.protected[r.id] and L['取消保护'] or L['保护'])
            local can=r.status=='candidate' and not r.locked
            b.delete:SetEnabled(can)
            b.delete.caption:SetTextColor(can and 1 or .45,can and .35 or .45,can and .35 or .45)
            local nh=math.max(30,b.name:GetStringHeight())
            b.name:SetHeight(nh); b.reason:ClearAllPoints(); b.reason:SetPoint('TOPLEFT',50,-nh-13)
            local reason=r.usage or r.reason
            if r.status=='candidate' then reason=(r.completedQuests and r.completedQuests[1] or '') .. L[' 已完成，建议删除'] end
            b.reason:SetText((labels[r.status] or '') .. L['：'] .. (reason or ''))
            local c=(r.usage==L['未知用途'] and r.status~='protected') and colors.unknown or (colors[r.status] or colors.unknown)
            b.reason:SetTextColor(c[1],c[2],c[3]); b.reason:SetHeight(0)
            local rh=math.max(18,b.reason:GetStringHeight()); b.reason:SetHeight(rh)
            local height=nh+rh+26; b:SetHeight(height); offset=offset+height+3
            if selected==r then b.bg:SetColorTexture(.20,.27,.26,1) else b.bg:SetColorTexture(.15,.16,.18,1) end
        end
        for i=#visible+1,#pool do pool[i]:Hide() end
        child:SetHeight(math.max(390,offset))
        list:SetVerticalScroll(math.min(list:GetVerticalScroll(),math.max(0,offset-390)))
        status:SetText(#visible==0 and L['没有符合条件的物品'] or (L['显示 '] .. #visible .. ' / ' .. #data .. L[' 组物品']))
        detailUpdate()
    end
    for i,label in ipairs(categories) do
        local index=i
        tabs[i]=button(frame,'ItemLoreFilter' .. i,label,16+(i-1)*112,-49,104,function()
            category=index; list:SetVerticalScroll(0); render()
            for j,b in ipairs(tabs) do b.caption:SetTextColor(j==category and .5 or .8,j==category and .9 or .8,j==category and .7 or .8) end
        end)
    end
    search:SetScript('OnTextChanged',function(self) query=self:GetText():lower(); list:SetVerticalScroll(0); render() end)
    button(frame,nil,L['重新扫描'],16,-526,100,actions.scan)
    frame:SetScript('OnHide',function() search:ClearFocus(); edit:ClearFocus() end)
    local view={frame=frame}
    function view:Show()
        syncMinimap()
        frame:SetScale(math.min(1,(UIParent:GetWidth()-30)/940,(UIParent:GetHeight()-30)/570))
        frame:Show(); frame:Raise()
    end
    function view:Update(rows,progress)
        syncMinimap()
        data=rows; render()
        if progress then status:SetText(L['正在读取任务关联：'] .. progress) end
    end
    function view:VisibleCount() return #visible end
    view:Show(); detailUpdate()
    return view
end
