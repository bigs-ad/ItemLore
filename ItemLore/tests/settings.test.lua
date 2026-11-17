GetLocale=GetLocale or function() return 'zhCN' end
dofile('ItemLore/Locale.lua')
local opened=0
function CreateFrame() error('Settings must not create or register a native addon panel') end
Settings={RegisterCanvasLayoutCategory=function() error('Native settings registration removed') end}
ItemLoreUI={OpenSettings=function() opened=opened+1 end}
dofile('ItemLore/Settings.lua')
ItemLoreSettings.Open()
assert(opened==1,'settings command routes to the main window')
print('PASS: settings use main window without native addon registration')
