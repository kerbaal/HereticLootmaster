local ADDON, Addon = ...

local Util = Addon.Util

KetzerischerLootverteilerData = {}
local RaidInfo = {}

local function updatePageNavigation()
  Addon.itemListView:SetNumberOfItems(Addon.itemList:Size())
  local prev, next, currentPage, maxPages = Addon.itemListView:GetNavigationStatus()
  KetzerischerLootverteilerPrevPageButton:SetEnabled(prev);
  KetzerischerLootverteilerNextPageButton:SetEnabled(next);
  KetzerischerLootverteilerPageText:SetFormattedText("%d / %d", currentPage, maxPages);
end

local function update(reason)
  Util.dbgprint("Updating UI... (" .. (reason or "") .. ")")
  updatePageNavigation()

  for i=1,Addon.ITEMS_PER_PAGE do
    local itemIndex = Addon.itemListView:IdToIndex(i);
    HereticLootFrame_SetLoot(i, itemIndex, Addon.itemList:GetEntry(itemIndex))
    HereticLootFrame_Update(i)
  end
end

function KetzerischerLootverteilerShow()
  update("show")
  KetzerischerLootverteilerFrame:Show()
end

function KetzerischerLootverteilerToggle()
  if (KetzerischerLootverteilerFrame:IsVisible()) then
    KetzerischerLootverteilerFrame:Hide()
  else
    KetzerischerLootverteilerShow()
  end
end

function RaidInfo:Initialize()
  RaidInfo.unitids = {}
  RaidInfo.newPlayers = {}
  RaidInfo.stale = "stale"
  RaidInfo.timer = nil
end

local function RaidInfoUpdate()
  Util.dbgprint("Reindexing Raid through timer...")
  RaidInfo:Update()
end

function RaidInfo:ProvideReindexing()
  if RaidInfo.timer then RaidInfo.timer:Cancel() end
  RaidInfo.timer = nil
end

function RaidInfo:RequestReindexing()
  if (RaidInfo.timer == nil) then
    Util.dbgprint("Request Reindexing...")
    RaidInfo.timer = C_Timer.NewTimer(2, RaidInfoUpdate)
  end
end

function RaidInfo:markStale()
  for i,v in pairs(RaidInfo.unitids) do
    RaidInfo.unitids[i] = RaidInfo.stale
  end
end

function RaidInfo:clearStale()
  for i,v in pairs(RaidInfo.unitids) do
    if (v == RaidInfo.stale ) then
      RaidInfo.unitids[i] = nil
    end
  end
end

function RaidInfo:recordByUnitId(unitId)
  local fullName = Util.GetFullUnitName(unitId)
  if (not fullName) then return end
  local first, _ = Util.DecomposeName(fullName)
  if (first == UNKNOWNOBJECT) then
     RaidInfo:RequestReindexing()
     return
   end
  if RaidInfo.unitids[fullName] == nil then
    table.insert(RaidInfo.newPlayers, fullName)
  end
  RaidInfo.unitids[fullName] = unitId
end

function RaidInfo:printNewPlayers(unitId)
  local players = ""
  for i,v in pairs(RaidInfo.newPlayers) do
    players = players .. " " .. v
  end
  Util.dbgprint ("New players (" .. table.getn(RaidInfo.newPlayers) .. "):" .. players)
end

function RaidInfo:GetNewPlayers()
  return RaidInfo.newPlayers
end

function RaidInfo:Update()
  RaidInfo:ProvideReindexing()

  RaidInfo:markStale()
  wipe(RaidInfo.newPlayers)
  RaidInfo.unitids [Util.GetFullUnitName("player")] = "player";
  local numMembers = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
  if (numMembers > 0) then
    local prefix = "raid"
    if ( not IsInRaid(LE_PARTY_CATEGORY_HOME) ) then
      prefix = "party"
      -- Party ids don't include the player, hence decrement.
      numMembers = numMembers - 1
    end

    for index = 1, numMembers do
      local unitId = prefix .. index
      RaidInfo:recordByUnitId(unitId)
    end
  end
  RaidInfo:printNewPlayers()
  RaidInfo:clearStale()
end

function RaidInfo:GetUnitId(name)
  local id = RaidInfo.unitids[name]
  if id then return id end

  local realm = GetRealmName():gsub("%s+", "")
  return RaidInfo.unitids[name .. "-" .. realm]
end

function RaidInfo:DebugPrint()
  for index,value in pairs(RaidInfo.unitids) do Util.dbgprint(index," ",value) end
end

local PagedView = {};
PagedView.__index = PagedView;
function PagedView:New(itemsPerPage)
   local self = {};
   setmetatable(self, PagedView);

   self.itemsPerPage = itemsPerPage
   self.currentPage = 1
   self.maxPages = 1
   return self;
end

function PagedView:Next()
  self.currentPage = max(1, self.currentPage - 1)
end

function PagedView:Prev()
  self.currentPage = min(self.maxPages, self.currentPage + 1)
end

function PagedView:IdToIndex(id)
  return (self.currentPage - 1) * self.itemsPerPage + id
end

function PagedView:SetNumberOfItems(count)
  self.maxPages = max(ceil(count / self.itemsPerPage), 1);
end

function PagedView:GetNavigationStatus()
  return (self.currentPage ~= 1), (self.currentPage ~= self.maxPages), self.currentPage, self.maxPages
end

function Addon:Initialize()
  Addon.ITEMS_PER_PAGE = 6
  Addon.MSG_PREFIX = "KTZR_LT_VERT"
  Addon.MSG_CLAIM_MASTER = "ClaimMaster"
  Addon.MSG_CHECK_MASTER = "CheckMaster"
  Addon.MSG_DELETE_LOOT = "DeleteLoot"
  Addon.MSG_DELETE_LOOT_PATTERN = "^%s+([^ ]+)%s+(.*)$"
  Addon.MSG_RENOUNCE_MASTER = "RenounceMaster"
  Addon.MSG_ANNOUNCE_LOOT = "LootAnnounce"
  Addon.MSG_ANNOUNCE_LOOT_PATTERN = "^%s+([^ ]+)%s+(.*)$"
  Addon.TITLE_TEXT = "Ketzerischer Lootverteiler"
  Addon.itemList = HereticItemList:New(999888777, "Nagisa-DieAldor") -- FixME hardcoded data
  Addon.itemListView = PagedView:New(Addon.ITEMS_PER_PAGE)
  Addon.master = nil;
  Addon.rolls = {};
  RegisterAddonMessagePrefix(Addon.MSG_PREFIX)
end

local function showIfNotCombat()
  if not UnitAffectingCombat("player") then
    KetzerischerLootverteilerShow()
  end
end

function Addon:AddItem(itemString, from, sender)
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

  Addon.itemList:AddEntry(HereticItem:New(itemString, from, sender))
  --PlaySound("igBackPackCoinSelect")
  PlaySound("TellMessage");
  --PlaySound("igMainMenuOptionCheckBoxOn")

  if Addon:IsMaster() then
    local msg = Addon.MSG_ANNOUNCE_LOOT .. " " .. from .. " " .. itemString
    Util.dbgprint("Announcing loot")
    SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  update("AddItem")
  showIfNotCombat()
end

function Addon:DeleteItem(index)
  local entry = Addon.itemList:GetEntry(index)
  if Addon:IsMaster() then
    local msg = Addon.MSG_DELETE_LOOT .. " " .. entry.donator .. " " .. entry.itemLink
    Util.dbgprint("Announcing loot deletion")
    SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  Addon.itemList:DeleteEntryAt(index)
  PlaySound("igMainMenuOptionCheckBoxOff");
  update("DeleteItem")
end

local function updateTitle()
  if (Addon.master) then
    local name, _ = Util.DecomposeName(Addon.master)
    KetzerischerLootverteilerTitleText:SetText(Addon.TITLE_TEXT .. ": "
      .. Util.GetPlayerLink(Addon.master, name))
  else
    KetzerischerLootverteilerTitleText:SetText(Addon.TITLE_TEXT)
  end
end

function Addon:IsMaster()
  return Util.GetFullUnitName("player") == Addon.master
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
    print ("You proclaim yourself Ketzerischer Lootverteiler.")
    SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "RAID")
    SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "WHISPER", Util.GetFullUnitName("player"))
  else
    print ("Only leader or assistant may become Ketzerischer Lootverteiler.")
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

  local unitId = RaidInfo:GetUnitId(name)
  if (Addon:IsAuthorizedToClaimMaster(unitId)) then
    Addon:SetMaster(name)
    print("You accepted " .. name .. " as your Ketzerischer Lootverteiler.")
  end
end

function Addon:RenounceMaster()
  if (Addon.master ~= Util.GetFullUnitName("player")) then return end
  print ("You renounce your title of Ketzerischer Lootverteiler.")
  SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_RENOUNCE_MASTER, "RAID")
end

function Addon:ProcessRenounceMaster(name)
  if (Addon.master == name) then
    Addon:SetMaster(nil)
  end
end

function KetzerischerLootverteilerFrame_OnUpdate(self, elapsed)
end

-- Eventhandler

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

function Addon:AddAllItems(itemStrings, from, sender)
  for itemString in string.gmatch(itemStrings, "item[%-?%d:]+") do
    Addon:AddItem(itemString, from, sender)
  end
end

local function eventHandlerEncounterEnd(self, event, encounterID, encounterName, difficultyID, raidSize, endStatus)
  if (endStatus == 1 and 14 <= difficultyID and difficultyID <= 16 and
      (not Addon.minRarity or Addon.minRarity[1] < 1000)) then
    KetzerischerLootverteilerShow()
  end
  if (Addon:IsMaster() and Addon:IsAuthorizedToClaimMaster("player") ) then
    Addon:ClaimMaster()
  end
end

local function eventHandlerLogout(self, event)
  KetzerischerLootverteilerData.itemList3 = Addon.itemList
  KetzerischerLootverteilerData.isVisible = KetzerischerLootverteilerFrame:IsVisible()
  KetzerischerLootverteilerData.master = Addon.master
  KetzerischerLootverteilerData.minRarity = Addon.minRarity
end

local function eventHandlerAddonLoaded(self, event, addonName)
   if (addonName == ADDON) then
    RaidInfo:Update()
    if KetzerischerLootverteilerData.itemList3
      and HereticItemList.Validate(KetzerischerLootverteilerData.itemList3) then
      Addon.itemList = KetzerischerLootverteilerData.itemList3
    end
    if KetzerischerLootverteilerData.minRarity then
      Addon.minRarity = KetzerischerLootverteilerData.minRarity
      UIDropDownMenu_SetSelectedID(KetzerischerlootverteilerRarityDropDown, Addon.minRarity[2])
    end
    if (KetzerischerLootverteilerData.isVisible == nil or
        KetzerischerLootverteilerData.isVisible == true) then
      KetzerischerLootverteilerShow()
    end
    if (KetzerischerLootverteilerData.master and IsPlayerInPartyOrRaid()) then
      SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CHECK_MASTER, "WHISPER",
        KetzerischerLootverteilerData.master)
    end
  end
end

local function eventHandlerAddonMessage(self, event, prefix, message, channel, sender)
  if (prefix ~= Addon.MSG_PREFIX) then return end
  local type, msg = message:match("^%s*([^ ]+)(.*)$")
  if (type == nil) then return end
  Util.dbgprint ("Addon message: " .. type)
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
  elseif (type == Addon.MSG_CHECK_MASTER) then
    SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "WHISPER", sender)
  end
end

local function eventHandlerRaidRosterUpdate(self, event, arg)
  RaidInfo:Update()
  if Addon:IsMaster() then
    if Addon:IsAuthorizedToClaimMaster("player") then
      for i,v in pairs(RaidInfo:GetNewPlayers()) do
        SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "WHISPER", v)
      end
    else
      Addon:RenounceMaster()
    end
  end
end

local function eventHandlerWhisper(self, event, msg, from)
  Addon:AddAllItems(msg, from, from)
end

local function eventHandlerBNChat(self, event, msg, sender, u1, u2, u3, u4, u5, u6, u7, u8, cnt, u9, bnetIDAccount)
  local bnetIDGameAccount = select(6,BNGetFriendInfoByID(bnetIDAccount))
  local _, name, client, realm = BNGetGameAccountInfo(bnetIDGameAccount)
  Util.dbgprint("BN: " .. sender .. " " .. bnetIDAccount .. " " .. name .. "-" .. realm)

  Addon:AddAllItems(msg, name .. "-" .. realm, sender)
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
    update("ItemInfoReceived")
  end
end


-- Keybindings
BINDING_HEADER_KETZERISCHER_LOOTVERTEILER = "Ketzerischer Lootverteiler"
BINDING_NAME_KETZERISCHER_LOOTVERTEILER_TOGGLE = "Toggle window"

-- Slashcommands
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
    update("DeleteAllItems")
  elseif (msg:match("^%s*debug%s*$")) then
    KetzerischerLootverteilerData.debug = not KetzerischerLootverteilerData.debug
    if KetzerischerLootverteilerData.debug then
      print("Debug is now on.")
    else
      print("Debug is now off.")
    end
  elseif (msg:match("^%s*raid%s*$")) then
    RaidInfo:DebugPrint()
  end
end

function LootItem_OnClick(self, button, down)
  if (button == "RightButton" and IsModifiedClick()) then
    if self.index then Addon:DeleteItem(self.index) end
    return true
  end
  if (button == "RightButton" and not IsModifiedClick()) then
    HereticRollCollectorFrame:Toggle()
    return true
  end
  return false
end

function KetzerischerLootverteilerFrame_GetItemAtCursor()
  for id=1,Addon.ITEMS_PER_PAGE do
    local frame = HereticLootFrame_FromId(id)
    if (frame and frame:IsMouseOver() and frame:IsVisible()) then
      return frame
    end
  end
  return nil
end

function KetzerischerLootverteilerFrame_OnDropRoll(self, roll)
  local frame = KetzerischerLootverteilerFrame_GetItemAtCursor()
  if frame then
    HereticLootFrame_SetWinner(frame, roll)
  end
end

function KetzerischerLootverteilerFrame_OnLoad(self)
  Addon:Initialize()
  RaidInfo:Initialize()
  KetzerischerLootverteilerFrame:SetScript("OnEvent", eventHandler);
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_WHISPER");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_BN_WHISPER");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_LOOT");
  KetzerischerLootverteilerFrame:RegisterEvent("ENCOUNTER_END");
  KetzerischerLootverteilerFrame:RegisterEvent("ADDON_LOADED");
  KetzerischerLootverteilerFrame:RegisterEvent("PLAYER_LOGOUT");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_ADDON");
  KetzerischerLootverteilerFrame:RegisterEvent("RAID_ROSTER_UPDATE");
  KetzerischerLootverteilerFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
  KetzerischerLootverteilerFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");

  for id=1,Addon.ITEMS_PER_PAGE do
    local frame = HereticLootFrame_FromId(id)
    frame.HereticOnClick = LootItem_OnClick
  end

  self:RegisterForDrag("LeftButton");
  update("Load")

  KetzerischerLootverteilerFrame.OnDropRoll = KetzerischerLootverteilerFrame_OnDropRoll
end

function KetzerischerLootverteilerFrame_OnDragStart()
  KetzerischerLootverteilerFrame:StartMoving();
end

function KetzerischerLootverteilerFrame_OnDragStop()
  KetzerischerLootverteilerFrame:StopMovingOrSizing();
end

function KetzerischerLootverteilerPrevPageButton_OnClick()
  Addon.itemListView:Next()
  update("PrevPage")
end

function KetzerischerLootverteilerNextPageButton_OnClick()
  Addon.itemListView:Prev()
  update("NextPage")
end

function KetzerischerLootverteilerNavigationFrame_OnLoad()
end

local function KetzerischerlootverteilerRarityDropDown_OnClick(self)
   UIDropDownMenu_SetSelectedID(KetzerischerlootverteilerRarityDropDown, self:GetID())
   Addon.minRarity = { self.value, self:GetID() }
end

function KetzerischerlootverteilerRarityDropDown_Initialize(self, level)
  for i = 0, 5 do
    local r, g, b, hex = GetItemQualityColor(i)
    local info = UIDropDownMenu_CreateInfo()
    info.text = "|c" .. hex .. _G["ITEM_QUALITY" .. i .. "_DESC"] .. "|r"
    info.value = i
    info.func = KetzerischerlootverteilerRarityDropDown_OnClick
    UIDropDownMenu_AddButton(info, level)
  end
  local info = UIDropDownMenu_CreateInfo()
  info.text = "|cFFFF0000" .. DISABLE .. "|r"
  info.value = 1000
  info.func = KetzerischerlootverteilerRarityDropDown_OnClick
  UIDropDownMenu_AddButton(info, level)
  UIDropDownMenu_JustifyText(KetzerischerlootverteilerRarityDropDown, "LEFT")
  UIDropDownMenu_SetWidth(KetzerischerlootverteilerRarityDropDown, 100);
  UIDropDownMenu_SetSelectedID(KetzerischerlootverteilerRarityDropDown, 1)
  Addon.minRarity = { 0, 1 }
end


--local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4,
--  Suffix, Unique, LinkLvl, reforging, Name = string.find(arg, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
--print("Got item" .. Id);
-- _G["GameTooltipTextLeft14"]
