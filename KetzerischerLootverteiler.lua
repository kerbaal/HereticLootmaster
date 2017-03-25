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

local function update()
  updatePageNavigation()

  for i=1,Addon.ITEMS_PER_PAGE do
    HereticLootButton_Update(i)
  end
end

function KetzerischerLootverteilerShow()
  update()
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



local ItemList = {};
ItemList.__index = ItemList;
function ItemList:New()
   local self = {};
   setmetatable(self, ItemList);

   self.items = {}
   self.donators = {}
   self.senders = {}
   self.size = 0
   return self;
end

function ItemList:Size()
  return self.size
end

function ItemList:Get(index)
  if (index < 1 or index > self.size) then return nil end
  return self.items[index], self.donators[index], self.senders[index]
end

function ItemList:GetItemLink(index)
  if (index > self.size) then return nil end
  return self.items[index]
end

function ItemList:Add(item, donator, sender)
  local n = self.size+1
  self.items[n] = item
  self.donators[n] = donator
  self.senders[n] = sender
  self.size = n
end

function ItemList:Delete(index)
  if index < 1 or index > self.size then return end
  table.remove(self.items, index)
  table.remove(self.donators, index)
  table.remove(self.senders, index)
  self.size = self.size-1
end

function ItemList:ItemById(item, donator, sender)
  for i=1,self.size do
    if (self.items[i] == item and
        self.donators[i] == donator and
        self.senders[i] == sender) then
      return i
    end
  end
  return nil
end

function ItemList:DeleteAllItems()
  wipe(self.items)
  wipe(self.donators)
  wipe(self.senders)
  self.size = 0
end

function ItemList:Validate()
  for i=self.size,1,-1 do
    if (self.items[i] == nil or
        self.donators[i] == nil or
        self.senders[i] == nil) then
      self:Delete(i)
    end
  end
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
  Addon.itemList = ItemList:New()
  Addon.itemListView = PagedView:New(Addon.ITEMS_PER_PAGE)
  Addon.master = nil;
  Addon.lastForcedUpdate = 0;
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

  Addon.itemList:Add(itemString, from, sender)

  if Addon:IsMaster() then
    local msg = Addon.MSG_ANNOUNCE_LOOT .. " " .. from .. " " .. itemString
    Util.dbgprint("Announcing loot")
    SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  update()
  showIfNotCombat()
end

function Addon:DeleteItem(index)
  item, donator, _ = Addon.itemList:Get(index)
  if Addon:IsMaster() then
    local msg = Addon.MSG_DELETE_LOOT .. " " .. donator .. " " .. item
    Util.dbgprint("Announcing loot deletion")
    SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  Addon.itemList:Delete(index)
  update()
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
  Addon.lastForcedUpdate = Addon.lastForcedUpdate + elapsed
  if (Addon.lastForcedUpdate > 10) then
    update()
    Addon.lastForcedUpdate = 0;
  end
end

-- Eventhandler

local function eventHandlerSystem(self, event, msg)
  local ROLL_REGEX = RANDOM_ROLL_RESULT
  ROLL_REGEX = gsub(ROLL_REGEX, "%(", "%%(")
  ROLL_REGEX = gsub(ROLL_REGEX, "%-", "%%-")
  ROLL_REGEX = gsub(ROLL_REGEX, "%)", "%%)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%1%$s", "(.+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%1%$s", "(.+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%2%$d", "(%%d+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%3%$d", "(%%d+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%4%$d", "(%%d+)")

  local name, roll, minRoll, maxRoll = msg:match(ROLL_REGEX)
  roll, minRoll, maxRoll = tonumber(roll), tonumber(minRoll), tonumber(maxRoll)

  if (name and roll and minRoll and maxRoll) then
    Util.dbgprint (name .. " " .. roll .. " range: " .. minRoll .. " - " .. maxRoll);
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

function Addon:AddAllItems(itemStrings, from, sender)
  for itemString in string.gmatch(itemStrings, "item[%-?%d:]+") do
    Addon:AddItem(itemString, from, sender)
  end
end

local function eventHandlerEncounterEnd(self, event, encounterID, encounterName, difficultyID, raidSize, endStatus)
  if (endStatus == 1 and 14 <= difficultyID and difficultyID <= 16) then
    KetzerischerLootverteilerShow()
  end
  if (Addon:IsMaster() and Addon:IsAuthorizedToClaimMaster("player") ) then
    Addon:ClaimMaster()
  end
end

local function eventHandlerLogout(self, event)
  KetzerischerLootverteilerData.itemList2 = Addon.itemList
  KetzerischerLootverteilerData.isVisible = KetzerischerLootverteilerFrame:IsVisible()
  KetzerischerLootverteilerData.master = Addon.master
  KetzerischerLootverteilerData.minRarity = Addon.minRarity
end

local function eventHandlerAddonLoaded(self, event, addonName)
   if (addonName == ADDON) then
    RaidInfo:Update()
    if KetzerischerLootverteilerData.itemList2 then
      for i,v in pairs(KetzerischerLootverteilerData.itemList2) do
        Addon.itemList[i] = v
      end
      Addon.itemList:Validate()
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
      local index = Addon.itemList:ItemById(itemString, donator, sender)
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
  elseif (event == "CHAT_MSG_SYSTEM") then
    eventHandlerSystem(self, event, ...)
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
    Addon.itemList:DeleteAllItems()
    update()
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

function KetzerischerLootverteilerFrame_OnLoad(self)
  Addon:Initialize()
  RaidInfo:Initialize()
  KetzerischerLootverteilerFrame:SetScript("OnEvent", eventHandler);
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_WHISPER");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_BN_WHISPER");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_SYSTEM");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_LOOT");
  KetzerischerLootverteilerFrame:RegisterEvent("ENCOUNTER_END");
  KetzerischerLootverteilerFrame:RegisterEvent("ADDON_LOADED");
  KetzerischerLootverteilerFrame:RegisterEvent("PLAYER_LOGOUT");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_ADDON");
  KetzerischerLootverteilerFrame:RegisterEvent("RAID_ROSTER_UPDATE");
  KetzerischerLootverteilerFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
  self:RegisterForDrag("LeftButton");
  update()
end

function KetzerischerLootverteilerFrame_OnDragStart()
  KetzerischerLootverteilerFrame:StartMoving();
end

function KetzerischerLootverteilerFrame_OnDragStop()
  KetzerischerLootverteilerFrame:StopMovingOrSizing();
end

function KetzerischerLootverteilerPrevPageButton_OnClick()
  Addon.itemListView:Next()
  update()
end

function KetzerischerLootverteilerNextPageButton_OnClick()
  Addon.itemListView:Prev()
  update()
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
  UIDropDownMenu_JustifyText(KetzerischerlootverteilerRarityDropDown, "LEFT")
  UIDropDownMenu_SetWidth(KetzerischerlootverteilerRarityDropDown, 100);
end

--local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4,
--  Suffix, Unique, LinkLvl, reforging, Name = string.find(arg, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
--print("Got item" .. Id);
-- _G["GameTooltipTextLeft14"]
