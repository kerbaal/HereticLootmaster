local ADDON, Addon = ...

KetzerischerLootverteilerData = {}
local RaidInfo = {}

local function dbgprint(...)
  if KetzerischerLootverteilerData.debug then
    print(...)
  end
end

local function FormatLink(linkType, linkDisplayText, ...)
  local linkFormatTable = { ("|H%s"):format(linkType), ... };
  return table.concat(linkFormatTable, ":") .. ("|h%s|h"):format(linkDisplayText);
end

local function GetPlayerLink(characterName, linkDisplayText, lineID, chatType, chatTarget)
  -- Use simplified link if possible.
  if lineID or chatType or chatTarget then
    return FormatLink("player", linkDisplayText, characterName, lineID or 0, chatType or 0, chatTarget or "");
  else
    return FormatLink("player", linkDisplayText, characterName);
  end
end

local function DecomposeName(name)
  return name:match("^([^-]*)-?(.*)$")
end

local function MergeFullName(name, realm)
  if (realm == nil or realm == "") then
    realm = GetRealmName():gsub("%s+", "")
  end
  return name .. "-" .. realm
end

local function CompleteUnitName(unitName)
  local name, realm = DecomposeName(unitName)
  return MergeFullName(name, realm)
end

local function GetFullUnitName(unitId)
  local name, realm = UnitName(unitId)
  return MergeFullName(name, realm)
end

local function getItemIdFromLink(itemLink)
  local _, _, color, Ltype, itemId, Enchant, Gem1, Gem2, Gem3, Gem4,
  Suffix, Unique, LinkLvl, reforging, Name =
  string.find(itemLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
  return itemId
end

local function updateButton(index)
  local button = _G["MyLootButton"..index];
  if (button == nil) then
    return
  end
  local itemIndex = (Addon.currentPage - 1) * Addon.ITEMS_PER_PAGE + index;
  local itemLink = Addon:GetItemLink(itemIndex)

  if (itemLink == nil) then
    button:Hide()
    return
  end

  button.itemLink = itemLink
  button.itemDonor = Addon.fromList[itemIndex]
  local donor, realm = DecomposeName(Addon.fromList[itemIndex])
  local from = _G["MyLootButton"..index.."FromText"];
  from:SetText(donor);

  local itemId = getItemIdFromLink(itemLink)

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice = GetItemInfo(itemLink)
  local locked = false;
  local isQuestItem = false;
  local questId = nil;
  local isActive = false;
  local text = _G["MyLootButton"..index.."Text"];

  if ( itemTexture ) then
    local color = ITEM_QUALITY_COLORS[quality];
    SetItemButtonQuality(button, quality, itemId);
    _G["MyLootButton"..index.."IconTexture"]:SetTexture(itemTexture);
    text:SetText(itemName);
    if( locked ) then
      SetItemButtonNameFrameVertexColor(button, 1.0, 0, 0);
      SetItemButtonTextureVertexColor(button, 0.9, 0, 0);
      SetItemButtonNormalTextureVertexColor(button, 0.9, 0, 0);
    else
      SetItemButtonNameFrameVertexColor(button, 0.5, 0.5, 0.5);
      SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
      SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
    end

    local questTexture = _G["MyLootButton"..index.."IconQuestTexture"];
    if ( questId and not isActive ) then
      questTexture:SetTexture(TEXTURE_ITEM_QUEST_BANG);
      questTexture:Show();
    elseif ( questId or isQuestItem ) then
      questTexture:SetTexture(TEXTURE_ITEM_QUEST_BORDER);
      questTexture:Show();
    else
      questTexture:Hide();
    end

    text:SetVertexColor(color.r, color.g, color.b);
    local countString = _G["MyLootButton"..index.."Count"];
    if ( itemStackCount > 1 ) then
      countString:SetText(itemStackCount);
      countString:Show();
    else
      countString:Hide();
    end
    button.quality = quality;
    button:Enable();
  else
    text:SetText("");
    _G["MyLootButton"..index.."IconTexture"]:SetTexture(nil);
    SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
    --LootFrame:SetScript("OnUpdate", LootFrame_OnUpdate);
    button:Disable();
  end
  button:Show();
end

local function updatePageNavigation()
  Addon.maxPages = max(ceil(Addon.itemNum / Addon.ITEMS_PER_PAGE), 1);

  if ( Addon.currentPage == 1 ) then
    KetzerischerLootverteilerPrevPageButton:Disable();
  else
    KetzerischerLootverteilerPrevPageButton:Enable();
  end

  if ( Addon.currentPage == Addon.maxPages ) then
    KetzerischerLootverteilerNextPageButton:Disable();
  else
    KetzerischerLootverteilerNextPageButton:Enable();
  end

  KetzerischerLootverteilerPageText:SetFormattedText("%d / %d", Addon.currentPage, Addon.maxPages);
end

local function update()
  updatePageNavigation()

  for i=1,Addon.ITEMS_PER_PAGE do
    updateButton(i)
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
  dbgprint("Reindexing Raid through timer...")
  RaidInfo:Update()
end

function RaidInfo:ProvideReindexing()
  if RaidInfo.timer then RaidInfo.timer:Cancel() end
  RaidInfo.timer = nil
end

function RaidInfo:RequestReindexing()
  if (RaidInfo.timer == nil) then
    dbgprint("Request Reindexing...")
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
  local fullName = GetFullUnitName(unitId)
  local first, _ = DecomposeName(fullName)
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
  dbgprint ("New players (" .. table.getn(RaidInfo.newPlayers) .. "):" .. players)
end

function RaidInfo:GetNewPlayers()
  return RaidInfo.newPlayers
end

function RaidInfo:Update()
  RaidInfo:ProvideReindexing()

  RaidInfo:markStale()
  wipe(RaidInfo.newPlayers)
  RaidInfo.unitids [GetFullUnitName("player")] = "player";
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
  for index,value in pairs(RaidInfo.unitids) do dbgprint(index," ",value) end
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
  if (Addon.itemList == nil) then
    Addon.itemList = {}
    Addon.fromList = {}
    Addon.itemNum = 0
  end
  Addon.currentPage = 1
  Addon.maxPages = 1
  Addon.master = nil;
  Addon.lastForcedUpdate = 0;
  RegisterAddonMessagePrefix(Addon.MSG_PREFIX)
end

function Addon:GetItemLink(index)
  if (index > Addon.itemNum) then
    return nil
  end
  return Addon.itemList[index]
end

function Addon:IsItemPresent(from, itemString)
  for i=1,Addon.ITEMS_PER_PAGE do
    if (Addon.itemList[i] == itemString and
        Addon.fromList[i] == from) then
      return true
    end
  end
  return false
end

local function showIfNotCombat()
  if not UnitAffectingCombat("player") then
    KetzerischerLootverteilerShow()
  end
end

function Addon:AddItem(itemString, from, source)
  itemString = itemString:match("item[%-?%d:]+")
  if (itemString == nil) then return end
  if (from == nil or from:gsub("%s+", "") == "") then return end
  from = from:gsub("%s+", "")
  itemString = itemString:gsub("%s+", "")

  -- Do not filter if the item comes from the lootmaster.
  if (source ~= Addon.master or Addon:IsMaster()) then
    local quality = select(3,GetItemInfo(itemString))
    if (Addon.minRarity and quality < Addon.minRarity[1]) then
      return
    end
  end

  Addon.itemList[Addon.itemNum+1] = itemString
  Addon.fromList[Addon.itemNum+1] = from
  Addon.itemNum = Addon.itemNum+1
  if Addon:IsMaster() then
    local msg = Addon.MSG_ANNOUNCE_LOOT .. " " .. from .. " " .. itemString
    dbgprint("Announcing loot")
    SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  update()
  showIfNotCombat()
end

function Addon:DeleteItem(index)
  if Addon:IsMaster() then
    local msg = Addon.MSG_DELETE_LOOT .. " " .. Addon.fromList[index] .. " " .. Addon.itemList[index]
    dbgprint("Announcing loot deletion")
    SendAddonMessage(Addon.MSG_PREFIX, msg, "RAID")
  end

  table.remove(Addon.itemList, index)
  table.remove(Addon.fromList, index)
  Addon.itemNum = Addon.itemNum-1
  update()
end

function Addon:ItemById(itemString, from)
  for i=1,Addon.itemNum do
    if (Addon.itemList[i] == itemString and
        Addon.fromList[i] == from) then
      return i
    end
  end
  return nil
end

function Addon:DeleteItemById(itemString, from)
  local index = Addon:ItemById(itemString, from)
  if (index) then
    Addon:DeleteItem(index)
  end
end

function Addon:DeleteAllItems()
  wipe(Addon.itemList)
  wipe(Addon.fromList)
  Addon.itemNum = 0
  update()
end

local function updateTitle()
  if (Addon.master) then
    local name, _ = DecomposeName(Addon.master)
    KetzerischerLootverteilerTitleText:SetText(Addon.TITLE_TEXT .. ": " .. GetPlayerLink(Addon.master, name))
  else
    KetzerischerLootverteilerTitleText:SetText(Addon.TITLE_TEXT)
  end
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
  if (GetFullUnitName(unitId) == GetFullUnitName("player")
      and not IsPlayerInPartyOrRaid()) then
    return true
  end
  return UnitIsGroupAssistant(unitId) or UnitIsGroupLeader(unitId)
end

function Addon:ClaimMaster()
  if Addon:IsAuthorizedToClaimMaster("player") then
    print ("You proclaim yourself Ketzerischer Lootverteiler.")
    SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "RAID")
    SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_CLAIM_MASTER, "WHISPER", GetFullUnitName("player"))
  else
    print ("Only leader or assistant may become Ketzerischer Lootverteiler.")
  end
end

function Addon:ProcessClaimMaster(name)
  if (name == nil) then return end
  if (Addon.master == name) then return end
  dbgprint(name .. " claims lootmastership")

  local unitId = RaidInfo:GetUnitId(name)
  if (Addon:IsAuthorizedToClaimMaster(unitId)) then
    Addon:SetMaster(name)
    print("You accepted " .. name .. " as your Ketzerischer Lootverteiler.")
  end
end

function Addon:RenounceMaster()
  if (Addon.master ~= GetFullUnitName("player")) then return end
  print ("You renounce your title of Ketzerischer Lootverteiler.")
  SendAddonMessage(Addon.MSG_PREFIX, Addon.MSG_RENOUNCE_MASTER, "RAID")
end

function Addon:ProcessRenounceMaster(name)
  if (Addon.master == name) then
    Addon:SetMaster(nil)
  end
end


function Addon:IsMaster()
  local fullName = GetFullUnitName("player")
  return fullName == Addon.master
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
  -- LOOT_ROLL_ROLLED  LOOT_ROLL_ROLLED_SELF
  local name, roll, minRoll, maxRoll = msg:match("^(.+) würfelt. Ergebnis: (%d+) %((%d+)%-(%d+)%)$")
  if (name and roll and minRoll and maxRoll) then
    dbgprint (name .. " " .. roll);
  end
end

local function eventHandlerLoot(self, event, message, sender)
  local LOOT_SELF_REGEX = gsub(LOOT_ITEM_SELF, "%%s", "(.+)")
  local LOOT_REGEX = gsub(LOOT_ITEM, "%%s", "(.+)")
  local _, _, sPlayer, itemlink = string.find(message, LOOT_REGEX)
  if not sPlayer then
    _, _, itemlink = string.find(message, LOOT_SELF_REGEX)
    sPlayer = GetFullUnitName("player")
  else
    sPlayer = CompleteUnitName(sPlayer)
  end
  if itemlink then
    local _, _, itemId = string.find(itemlink, "item:(%d+):")
    dbgprint(sPlayer .. " got " .. itemlink)
  end
end

function Addon:AddAllItems(itemStrings, from, source)
  for itemString in string.gmatch(itemStrings, "item[%-?%d:]+") do
    Addon:AddItem(itemString, from, source)
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
  KetzerischerLootverteilerData.itemList = Addon.itemList
  KetzerischerLootverteilerData.fromList = Addon.fromList
  KetzerischerLootverteilerData.itemNum = Addon.itemNum
  KetzerischerLootverteilerData.isVisible = KetzerischerLootverteilerFrame:IsVisible()
  KetzerischerLootverteilerData.master = Addon.master
  KetzerischerLootverteilerData.minRarity = Addon.minRarity
end

local function eventHandlerAddonLoaded(self, event, addonName)
   if (addonName == ADDON) then
    RaidInfo:Update()
    if KetzerischerLootverteilerData.itemList then
      Addon.itemList = KetzerischerLootverteilerData.itemList
    end
    if KetzerischerLootverteilerData.fromList then
      Addon.fromList = KetzerischerLootverteilerData.fromList
    end
    if KetzerischerLootverteilerData.itemNum then
      Addon.itemNum = KetzerischerLootverteilerData.itemNum
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
  dbgprint ("Addon message: " .. type)
  if (type == Addon.MSG_CLAIM_MASTER) then
    Addon:ProcessClaimMaster(sender)
  elseif (type == Addon.MSG_RENOUNCE_MASTER) then
    Addon:ProcessRenounceMaster(sender)
  elseif (type == Addon.MSG_ANNOUNCE_LOOT) then
    if not msg then return end
    local from, itemString = msg:match(Addon.MSG_ANNOUNCE_LOOT_PATTERN)
    dbgprint ("Announcement: " .. from .. " " .. itemString)
    if (sender == Addon.master and not Addon:IsMaster()) then
      Addon:AddItem(itemString, from, sender)
    end
  elseif (type == Addon.MSG_DELETE_LOOT) then
    if not msg then return end
    local from, itemString = msg:match(Addon.MSG_DELETE_LOOT_PATTERN)
    dbgprint ("Deletion: " .. from .. " " .. itemString)
    if (sender == Addon.master and not Addon:IsMaster()) then
      Addon:DeleteItemById(itemString, from)
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

local function eventHandlerItem(self, event, msg, from)
  Addon:AddAllItems(msg, from, from)
end

local function eventHandlerBNChat(self, event, msg, sender, u1, u2, u3, u4, u5, u6, u7, u8, cnt, u9, bnetIDAccount)
  local bnetIDGameAccount = select(6,BNGetFriendInfoByID(bnetIDAccount))
  local _, name, client, realm = BNGetGameAccountInfo(bnetIDGameAccount)
  dbgprint("BN: " .. sender .. " " .. bnetIDAccount .. " " .. name .. "-" .. realm)

  Addon:AddAllItems(msg, name .. "-" .. realm, sender)
end

local function eventHandler(self, event, ...)
  if event == "CHAT_MSG_WHISPER" then
    eventHandlerItem(self, event, ...)
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
    Addon:DeleteAllItems()
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
  Addon.currentPage = max(1, Addon.currentPage - 1)
  update()
end

function KetzerischerLootverteilerNextPageButton_OnClick()
  Addon.currentPage = min(Addon.maxPages, Addon.currentPage + 1)
  update()
end

function KetzerischerLootverteilerNavigationFrame_OnLoad()
end


function MyLootItem_OnEnter(self, motion)
  local itemLink = Addon:GetItemLink(self:GetID())
  if itemLink then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetHyperlink(itemLink);
    CursorUpdate(self);
  end
end

function MyLootButton_OnClick(self, button)
  if (button == "LeftButton") then
    local donor, _ = DecomposeName(self.itemDonor)
    local itemLink = select(2,GetItemInfo(self.itemLink))
    if ( IsModifiedClick() ) then
      HandleModifiedItemClick(itemLink);
    else
      local msg = itemLink .. " (" .. donor .. ")";
      SendChatMessage(msg, "RAID")
    end
  elseif (button == "RightButton") then
    if ( IsModifiedClick() ) then
      local id = (Addon.currentPage - 1) * Addon.ITEMS_PER_PAGE + self:GetID()
      Addon:DeleteItem(id)
    else
      ChatFrame_OpenChat("/w " .. self.itemDonor .. " ")
    end
  end
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
