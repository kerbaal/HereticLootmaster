local ADDON, Addon = ...

local Util = Addon.Util

SLASH_HereticLootmaster1, SLASH_HereticLootmaster2 = '/klv', '/kpm';
function SlashCmdList.HereticLootmaster(msg, editbox)
  if (msg == "" or msg:match("^%s*toggle%s*$")) then
    HereticLootmasterToggle()
  elseif (msg:match("^%s*show%s*$")) then
    HereticLootmasterShow()
  elseif (msg:match("^%s*hide%s*$")) then
    HereticLootmasterFrame:Hide()
  elseif (msg:match("^%s*master.*$")) then
    local action, argument = msg:match("^%s*master%s+([^ ]*) ?([^ ]*)$")
    if (action == nil or action == "set") then
      Addon:ClaimMaster();
    elseif (action == "unset") then
      Addon:RenounceMaster();
    end
  elseif (msg:match("^%s*clear%s*$")) then
    Addon.itemList:DeleteAllEntries()
    Addon:update("clear")
  elseif (msg:match("^%s*list%s*$")) then
    Addon:AnnouceLootCount()
  elseif (msg:match("^%s*clearall%s*$")) then
    Addon:ClearHistory()
  elseif (msg:match("^%s*debug%s*$")) then
    HereticLootmasterData.debug = not HereticLootmasterData.debug
    if HereticLootmasterData.debug then
      print ("Debug is now on.")
    else
      print ("Debug is now off.")
    end
  elseif (msg:match("^%s*raid%s*$")) then
    HereticRaidInfo:DebugPrint()
  else
    print ("Unknown option.")
  end
end
