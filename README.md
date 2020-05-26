# Heretic Lootmaster

A World of Warcraft addon that helps with distributing items in
raids without master loot. Lootverteiler captures all items whispered to
you and displays them in a convenient way, together with the person whispering.

Access the addon via slashcommand `/klv` or `/kpm`. The command `/klv master`
proclaims you as lootmaster to other addons of raid members. You must be lead
or assist to become lootmaster. Items added to your addon while you are
lootmaster broadcast to addons of other players in the raid and are displayed
there as well. To resign from lootmaster position, use `/klv master unset`.

The main window supports the following commands:
* Left-click posts the item to the raid chat.
* Shift-left click posts the item link as usual.
* Shift-right click removes the item from the list.

The addon now also supports a keybinding for show/hide toggle.

## Understanding the source code

Start reading the source code in `HereticLootmaster.lua` with the
function `HereticLootmasterFrame_OnLoad`. That function handles
initialization of the addon window.
