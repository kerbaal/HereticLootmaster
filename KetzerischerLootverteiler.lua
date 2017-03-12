local ADDON, Addon = ...


function Addon:getItemLink(index)
  if (index > Addon.itemNum) then
    return nil
  end
  return Addon.itemList[index]
end

local function eventHandlerSystem(self, event, msg)
  local name, roll, minRoll, maxRoll = msg:match("^(.+) würfelt. Ergebnis: (%d+) %((%d+)%-(%d+)%)$")
  if (name and roll and minRoll and maxRoll) then
    print (name .. roll);
  end
end

local function getItemIdFromLink(itemLink)
  local _, _, color, Ltype, itemId, Enchant, Gem1, Gem2, Gem3, Gem4,
  Suffix, Unique, LinkLvl, reforging, Name =
  string.find(itemLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
  return itemId
end


function MyLootItem_OnEnter(self, motion)
  local itemLink = Addon:getItemLink(self:GetID())
  if itemLink then
	  GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
	  GameTooltip:SetHyperlink(itemLink);
	  CursorUpdate(self);
  end
end

local function updateButton(index)

  local button = _G["MyLootButton"..index];
  if (button == nil) then
    return
  end
  local itemIndex = (Addon.currentPage - 1) * Addon.ITEMS_PER_PAGE + index;
  print ("Updating button " .. index .. "with item #" .. itemIndex)

  local itemLink = Addon:getItemLink(itemIndex)

  if (itemLink == nil) then
    button:Hide()
    return
  end

  button.itemLink = itemLink
  button.itemDonor = Addon.fromList[itemIndex]
  print ("Button " .. button.itemLink)

  local from = _G["MyLootButton"..index.."FromText"];
  from:SetText(Addon.fromList[itemIndex]);

  local itemId = getItemIdFromLink(itemLink)

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice = GetItemInfo(itemLink)
  print (itemName)
  local locked = false;
  local isQuestItem = false;
  local questId = nil;
  local isActive = false;
	local text = _G["MyLootButton"..index.."Text"];

	if ( itemTexture ) then
	  local color = ITEM_QUALITY_COLORS[quality];
    print (itemTexture)
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
		LootDonatorPrevPageButton:Disable();
	else
		LootDonatorPrevPageButton:Enable();
	end

	if ( Addon.currentPage == Addon.maxPages ) then
		LootDonatorNextPageButton:Disable();
	else
		LootDonatorNextPageButton:Enable();
	end

	LootDonatorPageText:SetFormattedText("%d / %d", Addon.currentPage, Addon.maxPages);
end

local function update()
  updatePageNavigation()

  for i=1,Addon.ITEMS_PER_PAGE do
    updateButton(i)
  end
end


local function eventHandlerItem(self, event, msg, from)
  for itemString in string.gmatch(msg, "item[%-?%d:]+") do
    Addon.itemList[Addon.itemNum+1] = itemString:gsub("%s+", "")
    Addon.fromList[Addon.itemNum+1] = from
    Addon.itemNum = Addon.itemNum+1
  end

  update()
end

function RaidDonatorFrame_OnUpdate(self)
  update()
end

local function eventHandlerEncounterEnd(self, event, encounterID, encounterName, difficultyID)
   if (14 <= difficultyID and difficultyID <= 16) then
     RaidDonatorFrame:Show()
   end
end

local function eventHandler(self, event, ...)
  if event == "CHAT_MSG_WHISPER" then
    eventHandlerItem(self, event, ...)
  elseif (event == "CHAT_MSG_SYSTEM") then
    eventHandlerSystem(self, event, ...)
  elseif (event == "ENCOUNTER_END") then
    eventHandlerEncounterEnd(self, event, ...)
  end
end

SLASH_RAIDDONATOR1 = '/klv';
function SlashCmdList.RAIDDONATOR(msg, editbox)
  if (RaidDonatorFrame:IsVisible()) then
    RaidDonatorFrame:Hide()
  else
    RaidDonatorFrame:Show()
  end
end

function RaidDonatorFrame_OnLoad(self)
  Addon.ITEMS_PER_PAGE = 6
  Addon.itemList = {}
  Addon.fromList = {}
  Addon.itemNum = 0
  Addon.currentPage = 1
  Addon.maxPages = 1
  RaidDonatorFrame:SetScript("OnEvent", eventHandler);
  RaidDonatorFrame:RegisterEvent("CHAT_MSG_WHISPER");
  RaidDonatorFrame:RegisterEvent("CHAT_MSG_SYSTEM");
  RaidDonatorFrame:RegisterEvent("ENCOUNTER_END");
	self:RegisterForDrag("LeftButton");
end

function RaidDonatorFrame_OnDragStart()
	RaidDonatorFrame:StartMoving();
end

function RaidDonatorFrame_OnDragStop()
	RaidDonatorFrame:StopMovingOrSizing();
end

function LootDonatorPrevPageButton_OnClick()
  Addon.currentPage = max(1, Addon.currentPage - 1)
  update()
end

function LootDonatorNextPageButton_OnClick()
  Addon.currentPage = min(Addon.maxPages, Addon.currentPage + 1)
  update()
end

function LootDonatorNavigationFrame_OnLoad()
end

function MyLootButton_OnClick(self, button)
  print(self.itemLink)
  if (button == "LeftButton") then
    local itemLink = select(2,GetItemInfo(self.itemLink))
    if ( IsModifiedClick() ) then
      HandleModifiedItemClick(itemLink);
    else
      local msg = self.itemDonor .. " bietet " .. itemLink .. " an";
      SendChatMessage(msg, RAID)
    end
  elseif (button == "RightButton") then
    if ( IsModifiedClick() ) then
      local id = (Addon.currentPage - 1) * Addon.ITEMS_PER_PAGE + self:GetID()
      table.remove(Addon.itemList,id)
      table.remove(Addon.fromList,id)
      Addon.numItems = Addon.itemNum-1
    end
  end
end
--local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4,
--  Suffix, Unique, LinkLvl, reforging, Name = string.find(arg, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
--print("Got item" .. Id);
