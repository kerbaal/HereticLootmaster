# Heretic Lootmaster

A World of Warcraft addon that helps with distributing items in raids without master loot.
The addon assumes that there is one player in the raid that acts as lootmaster, and all other players whisper the items they want to share with the raid to that player.

The Heretic Lootmaster addon assists the lootmaster in his job.
It captures all items whispered to the lootmaster and displays them in a convenient list.

Each item displays the name of the item, the item level, the date the item was posted, the slot, the armor type.
Finally, there is the winner field where the winning roll can be dragged to record the winner.

The basic workflow is as follows:
 - After a bosskill, players whisper all items to the lootmaster, where they appear in the list.
 - The lootmaster announces each item via Alt+LeftClick on the item to the raid chat.
 - Each player rolls on the item.
   The lootmaster uses the roll collector which can be opened by clicking on the two dice icon in the main window.
 - The lootmaster drags the winning roll onto the winner field of the item to record the winner, and uses the small bubble item next to the winner field to announce the winner to the raid chat.

Access the addon via the slashcommand `/hlm`, or via a Hotkey that can be bound in the key bindings menu in the "Addons" section.

## Quick command overview

The main window supports the following commands on the item icons:
* Alt+LeftClick posts the item to the raid chat
* Shift+LeftClick posts the item link in an open chat window as usual
* Shift+RightClick removes the item from the list

Right clicking on the two dice icon in the main window opens the roll collector.

## Advanced features

The command `/hlm master` proclaims the issuing player as lootmaster to other addons of raid members.
This player must be lead or assist in the raid for this to work.
All items that are received in the lootmaster's addon are broadcast to the addons of the other players in the raid and are displayed there as well.
To resign from lootmaster position, use `/hlm master unset`.

## Understanding the source code

Start reading the source code in `HereticLootmaster.lua` with the
function `HereticLootmasterFrame_OnLoad`. That function handles
initialization of the addon window.
