local ADDON, Addon = ...

local Util = Addon.Util

HereticLootmasterData = {}

local function getActiveTab()
  local tab = PanelTemplates_GetSelectedTab(HereticLootmasterFrame)
  return HereticLootmasterFrame.tabView[tab]
end

function HereticTabView_Update(self)
  self.itemView:HereticUpdate()
end

function Addon:update(reason)
  Util.dbgprint("Updating UI (" .. reason ..")..")
  HereticTabView_Update(getActiveTab())
end

function HereticLootmasterShow()
  HereticLootmasterFrame:Show()
  Addon:update("show")
end

function HereticLootmasterToggle()
  if (HereticLootmasterFrame:IsVisible()) then
    HereticLootmasterFrame:Hide()
  else
    HereticLootmasterShow()
  end
end

-- This function assumes that there is at most one saved ID for each
-- instance name and difficulty.
function FindSavedInstanceID(instanceName, instanceDifficultyID)
  local numInstances = GetNumSavedInstances()
  for i = 1, numInstances do
    local savedInstanceName, id, reset, savedInstanceDifficultyID = GetSavedInstanceInfo(i)
    if savedInstanceName == instanceName and savedInstanceDifficultyID == instanceDifficultyID then
      return id
    end
  end
  return nil
end

function Addon:Initialize()
  Addon.MSG_PREFIX = "KTZR_LT_VERT";
  Addon.MSG_CLAIM_MASTER = "ClaimMaster";
  Addon.MSG_CHECK_MASTER = "CheckMaster";
  Addon.MSG_DELETE_LOOT = "DeleteLoot";
  Addon.MSG_DELETE_LOOT_PATTERN = "^%s+([^ ]+)%s+(.*)$";
  Addon.MSG_RENOUNCE_MASTER = "RenounceMaster";
  Addon.MSG_ANNOUNCE_LOOT = "LootAnnounce";
  Addon.MSG_ANNOUNCE_LOOT_PATTERN = "^%s+([^ ]+)%s+(.*)$";
  Addon.MSG_ANNOUNCE_WINNER = "Winner";
  Addon.MSG_ANNOUNCE_WINNER_PATTERN = "^%s+([^ ]+)%s+([^ ]+)%s+([^ ]+)%s+([^ ]+)%s+([^ ]+)$";
  Addon.TITLE_TEXT = "Heretic Lootmaster";
  Addon.itemList = HereticList:New("master");
  Addon.activeHistoryIndex = 1;
  Addon.master = nil;
  Addon.lootCount = {};
  Addon.rolls = {};
  C_ChatInfo.RegisterAddonMessagePrefix(Addon.MSG_PREFIX);
end

function Addon:GetActiveHistory()
  return HereticHistory:GetItemListByIndex(Addon.activeHistoryIndex)
end

function Addon:AnnouceLootCount()
  HereticHistory:ComputeLootCount(Addon.lootCount)
  local n = 0
  for k,v in pairs(Addon.lootCount) do
    n=n+1
    local line = Util.ShortenFullName(v.name)
    if (v.donations) then
      line = line .. " donated " .. v.donations .. ""
    end
    if (v.count) then
      if (v.donations) then line = line .. " and" end
      line = line ..  " received " .. Util.formatLootCountMono(v.count, true, true)
    end
    line = line .. "."
    SendChatMessage(line, "RAID")
  end
end

function Addon:CountLootFor(name, cat)
  local entry = Addon.lootCount[name] or {}
  local count = entry.count or {}
  if cat == nil then return count end
  return count[cat] or 0
end

function Addon:CountDonationsFor(name)
  local entry = Addon.lootCount[name] or {}
  local donations = entry.donations or 0
  return donations
end

function Addon:OnWinnerUpdate(entry, prevWinner)
  HereticHistory:ComputeLootCount(Addon.lootCount)
  Addon:update("on winner update")
  if (Addon:IsMaster()) then
    local msg = Addon.MSG_ANNOUNCE_WINNER .. " " .. entry.donator .. " " ..
      entry.itemLink .. " "

    if entry.winner then
      msg = msg .. entry.winner.name .. " " .. entry.winner.roll ..
        " " .. entry.winner.max
    else
      msg = msg .. "- - -"
    end

    Util.dbgprint ("Announcing winner: " .. msg)
    C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end
  HereticRollCollectorFrame_Update(HereticRollCollectorFrame)
end

function Addon:SetWinner(itemString, donator, sender, winnerName, rollValue, rollMax)
  local index = Addon:GetActiveHistory():GetEntryId(itemString, donator, sender)
  if not index then
    return
  end
  local entry = Addon:GetActiveHistory():GetEntry(index)
  local prevWinner = entry.winner
  rollValue, rollMax = tonumber(rollValue), tonumber(rollMax)
  if (winnerName == "-" or not rollValue or not rollMax) then
    entry.winner = nil
  else
    entry.winner = HereticRoll:New(winnerName, rollValue, rollMax)
  end
  Addon:OnWinnerUpdate(entry, prevWinner)
end

function Addon:CanModify(owner)
  return Addon:IsMaster()
    or (not Addon:HasMaster())
    or (owner ~= nil and owner ~= Addon.master)
end

local function showIfNotCombat()
  if not UnitAffectingCombat("player") then
    HereticLootmasterShow()
  end
end

function Addon:AddItem(itemString, from, sender)
  if (Addon:HasMaster() and sender ~= Addon.master) then return end
  itemString = itemString:match("item[%-?%d:]+")
  if (itemString == nil) then return end
  if (from == nil or from:gsub("%s+", "") == "") then return end
  from = from:gsub("%s+", "")
  itemString = itemString:gsub("%s+", "")

  -- Do not filter if the item comes from the lootmaster.
  if (sender ~= Addon.master or Addon:IsMaster()) then
    local quality = select(3,GetItemInfo(itemString))
    if (Addon.minRarity and quality < Addon.minRarity[1]) then
      return
    end
  end

  local item = HereticItem:New(itemString, from, sender)
  Addon.itemList:AddEntry(item)
  local itemList = HereticHistory:GetItemListForCurrentInstance()
  itemList:AddEntry(item)
  --PlaySound("igBackPackCoinSelect")
  PlaySound(SOUNDKIT.TELL_MESSAGE);
  --PlaySound("igMainMenuOptionCheckBoxOn")

  if Addon:IsMaster() then
    local msg = Addon.MSG_ANNOUNCE_LOOT .. " " .. from .. " " .. itemString
    Util.dbgprint("Announcing loot")
    C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  Addon:update("AddItem")
  showIfNotCombat()
end

function Addon:DeleteItem(index)
  local entry = Addon.itemList:GetEntry(index)
  entry.isCurrent = false

  if Addon:IsMaster() then
    local msg = Addon.MSG_DELETE_LOOT .. " " .. entry.donator .. " " .. entry.itemLink
    Util.dbgprint("Announcing loot deletion")
    C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  Addon.itemList:DeleteEntryAt(index)
  PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF);
  Addon:update("DeleteItem")
end

local function updateTitle()
  if (Addon.master) then
    local name, _ = Util.DecomposeName(Addon.master)
    HereticLootmasterTitleText:SetText(Addon.TITLE_TEXT .. ": "
      .. Util.GetPlayerLink(Addon.master, name))
  else
    HereticLootmasterTitleText:SetText(Addon.TITLE_TEXT)
  end
end

function Addon:ClearHistory()
  Addon.itemList:DeleteAllEntries()
  HereticHistory:Wipe();
  Addon.activeHistoryIndex = 1
  HereticTab_SetActiveTab(1)
  Addon:update("DeleteAllEntries")
end

function Addon:IsMaster()
  return Util.GetFullUnitName("player") == Addon.master
end

function Addon:HasMaster()
  return Addon.master ~= nil and not Addon:IsMaster()
end

function Addon:SetMaster(name)
  Addon.master = name
  updateTitle()
end

local function IsPlayerInPartyOrRaid()
  return GetNumGroupMembers(LE_PARTY_CATEGORY_HOME) > 0
end

function Addon:IsAuthorizedToClaimMaster(unitId)
  -- Reject master claims from instance groups.
  if not unitId then return false end
  if (Util.GetFullUnitName(unitId) == Util.GetFullUnitName("player")
      and not IsPlayerInPartyOrRaid()) then
    return true
  end
  return UnitIsGroupAssistant(unitId) or UnitIsGroupLeader(unitId)
end

function Addon:ClaimMaster()
  if Addon:IsAuthorizedToClaimMaster("player") then
    print ("You proclaim yourself Heretic Lootmaster.")
    C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "RAID")
    C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "WHISPER", Util.GetFullUnitName("player"))
  else
    print ("Only leader or assistant may become Heretic Lootmaster.")
  end
end

function Addon:GetItemLinkFromId(id)
  local itemIndex = Addon.itemListView:IdToIndex(id);
  return Addon.itemList:GetItemLinkByID(itemIndex)
end

function Addon:ProcessClaimMaster(name)
  if (name == nil) then return end
  if (Addon.master == name) then return end
  Util.dbgprint(name .. " claims lootmastership")

  local unitId = HereticRaidInfo:GetUnitId(name)
  if (Addon:IsAuthorizedToClaimMaster(unitId)) then
    Addon:SetMaster(name)
    print ("You accepted " .. name .. " as your Heretic Lootmaster.")
  end
end

function Addon:RenounceMaster()
  if (Addon.master ~= Util.GetFullUnitName("player")) then return end
  print ("You renounce your title of Heretic Lootmaster.")
  C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_RENOUNCE_MASTER, "RAID")
end

function Addon:ProcessRenounceMaster(name)
  if (Addon.master == name) then
    Addon:SetMaster(nil)
  end
end

function HereticLootmasterFrame_Update(self, elapsed)
  getActiveTab():Update()
end

function Addon:AddAllItems(itemStrings, from, sender)
  for itemString in string.gmatch(itemStrings, "item[%-?%d:]+") do
    Addon:AddItem(itemString, from, sender)
  end
end

function Addon:IsTrackedDifficulity(difficultyID)
  return 14 <= difficultyID and difficultyID <= 16
end

function Addon:OnAddonLoaded()
  HereticRaidInfo:Deserialize(HereticLootmasterData)
  HereticRaidInfo:Update()
  if HereticLootmasterData.histories then
    HereticHistory:Deserialize(HereticLootmasterData.histories)
  end
  if HereticLootmasterData.activeHistoryIndex then
    local deserialized = HereticLootmasterData.activeHistoryIndex
    Addon.activeHistoryIndex = math.min(deserialized, HereticHistory:NumberOfItemLists())
  end
  HereticHistory:ComputeLootCount(Addon.lootCount)
  if HereticLootmasterData.minRarity then
    Addon.minRarity = HereticLootmasterData.minRarity
  end
  if (HereticLootmasterData.isVisible == nil or
      HereticLootmasterData.isVisible == true) then
    HereticLootmasterShow()
  end
  if (HereticLootmasterData.master and IsPlayerInPartyOrRaid()) then
    C_ChatInfo.SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CHECK_MASTER, "WHISPER",
      HereticLootmasterData.master)
  end
  if HereticLootmasterData.activeTab then
    HereticTab_SetActiveTab(Util.toRange(HereticLootmasterFrame.tabView, HereticLootmasterData.activeTab))
  end
  Addon:update("addon loaded")
end

function Addon:Serialize()
  HereticLootmasterData.histories = HereticHistory.histories
  HereticLootmasterData.activeHistoryIndex = Addon.activeHistoryIndex
  HereticLootmasterData.isVisible = HereticLootmasterFrame:IsVisible()
  HereticLootmasterData.master = Addon.master
  HereticLootmasterData.minRarity = Addon.minRarity
  HereticLootmasterData.activeTab = PanelTemplates_GetSelectedTab(HereticLootmasterFrame)
  HereticRaidInfo:Serialize(HereticLootmasterData)
end

function Addon:OnEncounterEnd(event, encounterID, encounterName, difficultyID, raidSize, endStatus)
  if (endStatus == 1 and Addon:IsTrackedDifficulity(difficultyID) and
    (not Addon.minRarity or Addon.minRarity[1] < 1000)) then
    HereticLootmasterShow()
  end
  if (Addon:IsMaster() and Addon:IsAuthorizedToClaimMaster("player") ) then
    Addon:ClaimMaster()
  end
end


-- Keybindings
BINDING_HEADER_HERETIC_LOOTMASTER = "Heretic Lootmaster"
BINDING_NAME_HERETIC_LOOTMASTER_TOGGLE = "Toggle window"

StaticPopupDialogs["HERETIC_LOOT_MASTER_CONFIRM_DELETE_FROM_HISTORY"] = {
  text = "Are you sure you want to delete this item permanently from history?",
  button1 = "Yes",
  button2 = "No",
  OnAccept = function(self)
    self.data.list:DeleteEntryAt(self.data.index)
    Addon:update("delete from history")
  end,
  OnCancel = function()
    -- Do nothing and keep item.
  end,
  timeout = 10,
  whileDead = true,
  hideOnEscape = true,
  hasItemFrame = 1,
}

function MasterLootItem_OnClick(self, button, down, entry)
  if (button == "RightButton" and IsModifiedClick("SHIFT")) then
    if not Addon:CanModify(self.entry.sender) then return end
    if self.index then Addon:DeleteItem(self.index) end
    return true
  end
  if (button == "RightButton" and not IsModifiedClick()) then
    HereticRollCollectorFrame:Toggle()
    return true
  end
  if (button == "LeftButton" and IsModifiedClick("ALT")) then
    local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
    itemSubType, itemStackCount, itemEquipLoc, itemTexture,
    itemSellPrice, itemClassID, itemSubClassID = GetItemInfo(entry.itemLink);
    local moreInfo = Util.GetMoreItemInfo(itemLink)
    local text = itemLink .. " " .. itemLevel .. " " .. (moreInfo.isCorrupted or "") .. " (" .. Util.ShortenFullName(entry.donator) .. ")"
    SendChatMessage(text, "RAID")

    HereticRollCollectorFrame_BeginRollCollection(HereticRollCollectorFrame, entry)
    return true
  end
  return false
end

function HistoryLootItem_OnClick(self, button, down)
  if (button == "RightButton" and IsModifiedClick()) then
    if not Addon:CanModify(self.entry.sender) then return end
    if self.entry.isCurrent then
      print ("Refusing to delete item from history that is still on Master page.")
    elseif self.entry.winner then
      print ("Refusing to delete item from history that has a winner assigned.")
    else
      StaticPopup_Show("HERETIC_LOOT_MASTER_CONFIRM_DELETE_FROM_HISTORY", "", "",
        {useLinkForItemInfo = true, link = self.entry.itemLink, list = Addon:GetActiveHistory(), index = self.index})
    end
    return true
  end
  -- Disable whispering for history items.
  if (button == "RightButton") then return true end
  return false
end

function HereticLootmasterFrame_GetItemAtCursor(self)
  local frame = HereticHistoryScrollFrame_GetItemAtCursor(getActiveTab().itemView)
  if frame then return frame end
  frame = HereticRollCollectorFrame
  if (frame and frame:IsMouseOver() and frame:IsVisible()) then
    return frame
  end
  return nil
end

function HereticLootmasterFrame_OnLoad(self)
  Addon:Initialize()
  HereticRaidInfo:Initialize()
  Addon:InitializeEventHandlers(HereticLootmasterFrame);

  self:RegisterForDrag("LeftButton");

  HereticLootmasterFrame.tabView[1].itemView.HereticUpdate = HereticHistoryScrollFrame_Update
  HereticLootmasterFrame.tabView[1].itemView.itemList = Addon.itemList
  HereticLootmasterFrame.tabView[1].itemView.HereticOnItemClicked =  MasterLootItem_OnClick
  HereticLootmasterFrame.tabView[2].itemView.HereticUpdate =
    function (self)
      self.itemList = Addon:GetActiveHistory()
      HereticHistoryScrollFrame_Update(self)
    end
  HereticLootmasterFrame.tabView[2].itemView.itemList = HereticHistory.histories[1]
  HereticLootmasterFrame.tabView[2].itemView.HereticOnItemClicked = HistoryLootItem_OnClick
  HereticLootmasterFrame.tabView[3].itemView.HereticUpdate =
    function (self)
      HereticPlayerInfoScrollFrame_Update(self)
    end

  HereticLootmasterFrame.GetItemAtCursor = HereticLootmasterFrame_GetItemAtCursor
  PanelTemplates_SetNumTabs(HereticLootmasterFrame, #HereticLootmasterFrame.tabView);
  HereticTab_SetActiveTab(1)
end

function HereticLootmasterFrame_OnDragStart()
  HereticLootmasterFrame:StartMoving();
end

function HereticLootmasterFrame_OnDragStop()
  HereticLootmasterFrame:StopMovingOrSizing();
end

function HereticTab_SetActiveTab(id)
  PanelTemplates_SetTab(HereticLootmasterFrame, id);
  for i,tab in pairs(HereticLootmasterFrame.tabView) do
    if i == id then
      tab:Show();
    else
      tab:Hide();
    end
  end
  Addon:update("set active tab")
end

function HereticTab_OnClick(self)
  HereticTab_SetActiveTab(self:GetID())
end

function Addon:SetCurrentHistory(id)
  Addon.activeHistoryIndex = id
  HereticHistory:ComputeLootCount(Addon.lootCount)
  HereticRollCollectorFrame_Update(HereticRollCollectorFrame)
  Addon:update("change history")
end

function HereticLootmasterRollButton_OnClick(self)
   HereticRollCollectorFrame:Toggle()
end
