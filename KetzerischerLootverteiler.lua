local ADDON, Addon = ...

KetzerischerLootverteilerData = {}

local function dbgprint(...)
  --print(...)
end

function Addon:initialize()
  Addon.ITEMS_PER_PAGE = 6
  if (Addon.itemList == nil) then
    Addon.itemList = {}
    Addon.fromList = {}
    Addon.itemNum = 0
  end
  Addon.currentPage = 1
  Addon.maxPages = 1
end

function Addon:getItemLink(index)
  if (index > Addon.itemNum) then
    return nil
  end
  return Addon.itemList[index]
end

function Addon:addItem(itemString, from)
  Addon.itemList[Addon.itemNum+1] = itemString:gsub("%s+", "")
  Addon.fromList[Addon.itemNum+1] = from
  Addon.itemNum = Addon.itemNum+1
end

function Addon:deleteItem(index)
  table.remove(Addon.itemList,id)
  table.remove(Addon.fromList,id)
  Addon.itemNum = Addon.itemNum-1
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
  dbgprint ("Updating button " .. index .. "with item #" .. itemIndex)

  local itemLink = Addon:getItemLink(itemIndex)

  if (itemLink == nil) then
    button:Hide()
    return
  end

  button.itemLink = itemLink
  button.itemDonor = Addon.fromList[itemIndex]
  dbgprint ("Button " .. button.itemLink)

  local from = _G["MyLootButton"..index.."FromText"];
  from:SetText(Addon.fromList[itemIndex]);

  local itemId = getItemIdFromLink(itemLink)

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice = GetItemInfo(itemLink)
  dbgprint (itemName)
  local locked = false;
  local isQuestItem = false;
  local questId = nil;
  local isActive = false;
	local text = _G["MyLootButton"..index.."Text"];

	if ( itemTexture ) then
	  local color = ITEM_QUALITY_COLORS[quality];
    dbgprint (itemTexture)
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

function KetzerischerLootverteilerFrame_OnUpdate(self)
  update()
end

-- Eventhandler

local function eventHandlerSystem(self, event, msg)
  local name, roll, minRoll, maxRoll = msg:match("^(.+) würfelt. Ergebnis: (%d+) %((%d+)%-(%d+)%)$")
  if (name and roll and minRoll and maxRoll) then
    dbgprint (name .. roll);
  end
end

local function eventHandlerLoot(self, event, message, sender)
  local LOOT_SELF_REGEX = gsub(LOOT_ITEM_SELF, "%%s", "(.+)")
  local LOOT_REGEX = gsub(LOOT_ITEM, "%%s", "(.+)")
  local _, _, sPlayer, itemlink = string.find(message, LOOT_REGEX)
  if not sPlayer then
    _, _, itemlink = string.find(message, LOOT_SELF_REGEX)
  else
    dbgprint(sPlayer)
  end
  if itemlink then
    local _, _, itemId = string.find(itemlink, "item:(%d+):")
    dbgprint(itemlink)
  end
end

local function eventHandlerItem(self, event, msg, from)
  for itemString in string.gmatch(msg, "item[%-?%d:]+") do
    Addon:addItem(itemString, from)
  end

  update()
end

local function eventHandlerEncounterEnd(self, event, encounterID, encounterName, difficultyID, raidSize, endStatus)
  if (endStatus == 1 and 14 <= difficultyID and difficultyID <= 16) then
    KetzerischerLootverteilerFrame:Show()
  end
end

local function eventHandlerLogout(self, event)
  KetzerischerLootverteilerData.itemList = Addon.itemList
  KetzerischerLootverteilerData.fromList = Addon.fromList
  KetzerischerLootverteilerData.itemNum = Addon.itemNum
end

local function eventHandlerAddonLoaded(self, event, addonName)
  if (addonName == ADDON) then
    if KetzerischerLootverteilerData.itemList then
      Addon.itemList = KetzerischerLootverteilerData.itemList
    end
    if KetzerischerLootverteilerData.fromList then
      Addon.fromList = KetzerischerLootverteilerData.fromList
    end
    if KetzerischerLootverteilerData.itemNum then
      Addon.itemNum = KetzerischerLootverteilerData.itemNum
    end
  end
end

local function eventHandler(self, event, ...)
  if event == "CHAT_MSG_WHISPER" then
    eventHandlerItem(self, event, ...)
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
  end
end

function KetzerischerLootverteilerToggle()
  if (KetzerischerLootverteilerFrame:IsVisible()) then
    KetzerischerLootverteilerFrame:Hide()
  else
    KetzerischerLootverteilerFrame:Show()
  end
end

-- Keybindings
BINDING_HEADER_KETZERISCHER_LOOTVERTEILER = "Ketzerischer Lootverteiler"
BINDING_NAME_KETZERISCHER_LOOTVERTEILER_TOGGLE = "Toggle window"

-- Slashcommands
SLASH_KetzerischerLootverteiler1, SLASH_KetzerischerLootverteiler2 = '/klv', '/kpm';
function SlashCmdList.KetzerischerLootverteiler(msg, editbox)
  KetzerischerLootverteilerToggle()
end

function KetzerischerLootverteilerFrame_OnLoad(self)
  Addon:initialize()
  KetzerischerLootverteilerFrame:SetScript("OnEvent", eventHandler);
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_WHISPER");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_SYSTEM");
  KetzerischerLootverteilerFrame:RegisterEvent("CHAT_MSG_LOOT");
  KetzerischerLootverteilerFrame:RegisterEvent("ENCOUNTER_END");
  KetzerischerLootverteilerFrame:RegisterEvent("ADDON_LOADED");
  KetzerischerLootverteilerFrame:RegisterEvent("PLAYER_LOGOUT");
	self:RegisterForDrag("LeftButton");
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
  local itemLink = Addon:getItemLink(self:GetID())
  if itemLink then
	  GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	  GameTooltip:SetHyperlink(itemLink);
	  CursorUpdate(self);
  end
end

function MyLootButton_OnClick(self, button)
  dbgprint(self.itemLink)
  if (button == "LeftButton") then
    local itemLink = select(2,GetItemInfo(self.itemLink))
    if ( IsModifiedClick() ) then
      HandleModifiedItemClick(itemLink);
    else
      local msg = self.itemDonor .. " bietet " .. itemLink .. " an";
      SendChatMessage(msg, "RAID")
    end
  elseif (button == "RightButton") then
    if ( IsModifiedClick() ) then
      local id = (Addon.currentPage - 1) * Addon.ITEMS_PER_PAGE + self:GetID()
      Addon:deleteItem(id)
    end
  end
end

--local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4,
--  Suffix, Unique, LinkLvl, reforging, Name = string.find(arg, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
--print("Got item" .. Id);
