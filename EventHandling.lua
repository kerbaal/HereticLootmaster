local ADDON, Addon = ...

local Util = Addon.Util

local function eventHandlerWhisper(self, event, msg, from)
  Addon:AddAllItems(msg, from, from)
end

local function eventHandlerBNChat(self, event, msg, sender, u1, u2, u3, u4, u5, u6, u7, u8, cnt, u9, bnetIDAccount)
  local bnetIDGameAccount = select(6, BNGetFriendInfoByID(bnetIDAccount))
  local _, name, client, realm = BNGetGameAccountInfo(bnetIDGameAccount)
  Util.dbgprint("BN: " .. sender .. " " .. bnetIDAccount .. " " .. name .. "-" .. realm)

  Addon:AddAllItems(msg, name .. "-" .. realm, sender)
end

local function eventHandlerEncounterEnd(self, event, encounterID, encounterName, difficultyID, raidSize, endStatus)
  if (endStatus == 1 and Addon:IsTrackedDifficulity(difficultyID) and
      (not Addon.minRarity or Addon.minRarity[1] < 1000)) then
    KetzerischerLootverteilerShow()
  end
  if (Addon:IsMaster() and Addon:IsAuthorizedToClaimMaster("player") ) then
    Addon:ClaimMaster()
  end
end

local function eventHandlerLoot(self, event, message, sender)
  local LOOT_SELF_REGEX = gsub(LOOT_ITEM_SELF, "%%s", "(.+)")
  local LOOT_REGEX = gsub(LOOT_ITEM, "%%s", "(.+)")
  local _, _, sPlayer, itemlink = string.find(message, LOOT_REGEX)
  if not sPlayer then
    _, _, itemlink = string.find(message, LOOT_SELF_REGEX)
    sPlayer = Util.GetFullUnitName("player")
  else
    sPlayer = Util.CompleteUnitName(sPlayer)
  end
  if itemlink then
    local _, _, itemId = string.find(itemlink, "item:(%d+):")
    Util.dbgprint(sPlayer .. " got " .. itemlink)
  end
end

local function eventHandlerLogout(self, event)
  KetzerischerLootverteilerData.histories = Addon.histories
  KetzerischerLootverteilerData.activeHistoryIndex = Addon.activeHistoryIndex
  KetzerischerLootverteilerData.isVisible = KetzerischerLootverteilerFrame:IsVisible()
  KetzerischerLootverteilerData.master = Addon.master
  KetzerischerLootverteilerData.minRarity = Addon.minRarity
  KetzerischerLootverteilerData.activeTab = PanelTemplates_GetSelectedTab(KetzerischerLootverteilerFrame)
  HereticRaidInfo:Serialize(KetzerischerLootverteilerData)
end

local function eventHandlerAddonLoaded(self, event, addonName)
  if (addonName == ADDON) then
   Addon:OnAddonLoaded()
 end
end

local function eventHandlerAddonMessage(self, event, prefix, message, channel, sender)
  if (prefix ~= Addon.MSG_PREFIX) then return end
  local type, msg = message:match("^%s*([^ ]+)(.*)$")
  if (type == nil) then return end
  Util.dbgprint ("Received: " .. type)
  if (type == Addon.MSG_CLAIM_MASTER) then
    Addon:ProcessClaimMaster(sender)
  elseif (type == Addon.MSG_RENOUNCE_MASTER) then
    Addon:ProcessRenounceMaster(sender)
  elseif (type == Addon.MSG_ANNOUNCE_LOOT) then
    if not msg then return end
    local from, itemString = msg:match(Addon.MSG_ANNOUNCE_LOOT_PATTERN)
    Util.dbgprint ("Announcement: " .. from .. " " .. itemString)
    if (sender == Addon.master and not Addon:IsMaster()) then
      Addon:AddItem(itemString, from, sender)
    end
  elseif (type == Addon.MSG_DELETE_LOOT) then
    if not msg then return end
    local donator, itemString = msg:match(Addon.MSG_DELETE_LOOT_PATTERN)
    Util.dbgprint ("Deletion: " .. donator .. " " .. itemString)
    if (sender == Addon.master and not Addon:IsMaster()) then
      local index = Addon.itemList:GetEntryId(itemString, donator, sender)
      if (index) then Addon:DeleteItem(index) end
    end
  elseif (type == Addon.MSG_ANNOUNCE_WINNER) then
    if not msg then return end
    local from, itemString, winnerName, roll, rollMax = msg:match(Addon.MSG_ANNOUNCE_WINNER_PATTERN)
    Util.dbgprint ("Winner: " .. from .. " " .. itemString .. " "
      .. winnerName .. " " .. roll .. " " .. rollMax)
    if (sender == Addon.master and not Addon:IsMaster()) then
      Addon:SetWinner(itemString, from, sender, winnerName, roll, rollMax)
    end
  elseif (type == Addon.MSG_CHECK_MASTER) then
    C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "WHISPER", sender)
  end
end

local function eventHandlerRaidRosterUpdate(self, event, arg)
  HereticRaidInfo:Update()
  if Addon:IsMaster() then
    if Addon:IsAuthorizedToClaimMaster("player") then
      for i,v in pairs(HereticRaidInfo:GetNewPlayers()) do
        C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "WHISPER", v)
      end
    else
      Addon:RenounceMaster()
    end
  end
end

local function eventHandler(self, event, ...)
  if event == "CHAT_MSG_WHISPER" then
    eventHandlerWhisper(self, event, ...)
  elseif event == "CHAT_MSG_BN_WHISPER" then
    eventHandlerBNChat(self, event, ...)
  elseif (event == "ENCOUNTER_END") then
    eventHandlerEncounterEnd(self, event, ...)
  elseif (event == "CHAT_MSG_LOOT") then
    eventHandlerLoot(self, event, ...)
  elseif (event == "PLAYER_LOGOUT") then
    eventHandlerLogout(self, event, ...)
  elseif (event == "ADDON_LOADED") then
    eventHandlerAddonLoaded(self, event, ...)
  elseif (event == "CHAT_MSG_ADDON") then
    eventHandlerAddonMessage(self, event, ...)
  elseif (event == "GROUP_ROSTER_UPDATE") then
    eventHandlerRaidRosterUpdate(self, event, ...)
  elseif (event == "GET_ITEM_INFO_RECEIVED") then
    Addon:update("ItemInfoReceived")
  elseif (event == "RAID_INSTANCE_WELCOME") then
    Util.dbgprint("RaidInstanceWelcome: " .. (select(1, ...) .. " " .. select(2, ...)))
  elseif (event == "UPDATE_INSTANCE_INFO") then
    Util.dbgprint("UpdateInstanceInfo")
  end
end

function Addon:InitializeEventHandlers(frame)
  frame:SetScript("OnEvent", eventHandler);
  frame:RegisterEvent("CHAT_MSG_WHISPER");
  frame:RegisterEvent("CHAT_MSG_BN_WHISPER");
  frame:RegisterEvent("CHAT_MSG_LOOT");
  frame:RegisterEvent("ENCOUNTER_END");
  frame:RegisterEvent("ADDON_LOADED");
  frame:RegisterEvent("PLAYER_LOGOUT");
  frame:RegisterEvent("CHAT_MSG_ADDON");
  frame:RegisterEvent("RAID_ROSTER_UPDATE");
  frame:RegisterEvent("GROUP_ROSTER_UPDATE");
  frame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
end
