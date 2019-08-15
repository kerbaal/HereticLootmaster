local ADDON, Addon = ...

local Util = Addon.Util

SLASH_KetzerischerLootverteiler1, SLASH_KetzerischerLootverteiler2 = '/klv', '/kpm';
function SlashCmdList.KetzerischerLootverteiler(msg, editbox)
  if (msg == "" or msg:match("^%s*toggle%s*$")) then
    KetzerischerLootverteilerToggle()
  elseif (msg:match("^%s*show%s*$")) then
    KetzerischerLootverteilerShow()
  elseif (msg:match("^%s*hide%s*$")) then
    KetzerischerLootverteilerFrame:Hide()
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
    Addon.itemList:DeleteAllEntries()
    wipe(Addon.histories)
    Addon.histories[1] = HereticList:New("default")
    Addon.activeHistoryIndex = 1
    HereticTab_SetActiveTab(1)
    Addon:update("clearall")
  elseif (msg:match("^%s*debug%s*$")) then
    KetzerischerLootverteilerData.debug = not KetzerischerLootverteilerData.debug
    if KetzerischerLootverteilerData.debug then
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
