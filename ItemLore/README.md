# ItemLore / 物品秘笺 0.7.2-beta

Cleanup tooltips place quest information above a separate, unbroken recommendation line.
清理提示将任务信息与红色删除建议分行显示，多任务只显示一次建议。

Tooltip text now uses inline colors for branding, quest IDs, quest names and status. Deletion rules are unchanged.
悬停提示采用分段配色；任务编号灰色、名称白色、状态单独着色，删除判断不变。

Item purposes, linked quests and manual cleanup suggestions for World of Warcraft Forever 1.60.1 (Interface 16001).

## Install

Exit the game. Extract the `ItemLore` folder into `_forever_/Interface/AddOns/`.
The final path must be `Interface/AddOns/ItemLore/ItemLore.toc`.
Enable ItemLore and a Forever-compatible version of Questie. Questie is not included.
Quest-based cleanup is unavailable until the database and quest index are ready.

## Use

- Open via the minimap icon, quest-window button, `/itemlore`, or a key binding.
- Search by item name, item ID, quest ID or purpose. Select an item for copyable details.
- Protect items you want to keep. Eligible stacks can be deleted only after confirmation.
- Toggle the minimap icon at the bottom right of the window; drag the icon to move it.
- Simplified Chinese clients use Chinese. All other client languages use English interface text.
- Item and quest names come from the game or Questie and may remain in their original language.

## Limitations

Only the current character's carried bags are scanned, not banks or other characters.
Scanning covers quest-classified items and catalogued special items, not every item type.
The special-use catalogue currently contains only Enchanted Sea Kelp (4639), Goaz Scrolls (209848), and Skonk's List (283389).
Their full uses have not been verified in-game. Sources and verification scope appear in details.
Hidden quests and custom uses may be missing. A cleanup suggestion does not prove an item has no other uses.
There is no automatic mass deletion, and ItemLore cannot undo a deletion.
Settings and protection are saved per character; existing saves are preserved.

## Feedback

Report the addon/client version, item and quest IDs, screenshots, reproduction steps, and full Lua errors at:
https://github.com/bigs-ad/ItemLore/issues

This addon is not an official Questie project. It reads the installed Questie database at runtime; Questie data is not bundled.

## 中文说明

适用于 Forever 无限服 1.60.1。退出游戏后，将压缩包中的 `ItemLore` 文件夹放入 `_forever_/Interface/AddOns/`。
任务关联查询和清理判断需要启用兼容版本的 Questie，本包不包含 Questie。

点击小地图图标、任务界面按钮，或输入 `/itemlore` 打开。左侧可搜索、保护物品和确认删除，右侧详情可选字复制。
小地图图标显示开关位于窗口右下角。简体中文客户端显示中文，其他语言客户端默认英文。
任务名由数据库提供，缺少翻译时保留原名和编号。现有保护名单和设置保持不变。

仅扫描当前角色随身背包中的任务分类物品和已收录特殊物品。
用途资料尚未完整覆盖隐藏任务及自定义用途；建议删除不保证没有其他用途，重要物品请先保护。
三条特殊用途资料均未完整实测，具体来源及核实范围见详情。删除不可由本插件撤销。

## 0.7.0-beta

- Added English UI, tooltips, confirmation messages and special-use descriptions.
- Kept Simplified Chinese UI and existing protection data.
- Widened action buttons and adjusted text layout for English.
- Added English fallback and bilingual regression tests; live English-client testing is still needed.
