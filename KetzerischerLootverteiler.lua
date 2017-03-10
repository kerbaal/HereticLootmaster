local ADDON, Addon = ...

RaidDonatorFrame:RegisterEvent("CHAT_MSG_WHISPER");
RaidDonatorFrame:RegisterEvent("CHAT_MSG_SYSTEM");

function Addon:getItemList()
  if (Addon.itemList == nil) then
    Addon.itemList = {}
    Addon.fromList = {}
    Addon.itemNum = 0
  end
  return Addon.itemList
end

function Addon:getItemLink(index)
  Addon:getItemList();
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
  print ("Updating button " .. index)
  local itemLink = Addon:getItemLink(index)

  if (itemLink == nil) then
    button:Hide()
    return
  end

  button.itemLink = itemLink
  print ("Button " .. button.itemLink)

  local from = _G["MyLootButton"..index.."FromText"];
  from:SetText(Addon.fromList[index]);

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

local function eventHandlerItem(self, event, msg, from)
  Addon:getItemList()
  for itemString in string.gmatch(msg, "item[%-?%d:]+") do
    Addon.itemList[Addon.itemNum+1] = itemString
    Addon.fromList[Addon.itemNum+1] = from
    Addon.itemNum = Addon.itemNum+1
  end

  for i=1,Addon.itemNum do
    print (Addon.itemList[i])
    updateButton(i)
  end

end

local function eventHandler(self, event, ...)
  if event == "CHAT_MSG_WHISPER" then
    eventHandlerItem(self, event, ...)
  elseif (event == "CHAT_MSG_SYSTEM") then
    eventHandlerSystem(self, event, ...)
  end
end

RaidDonatorFrame:SetScript("OnEvent", eventHandler);

--local _, _, Color, Ltype, Id, Enchant, Gem1, Gem2, Gem3, Gem4,
--  Suffix, Unique, LinkLvl, reforging, Name = string.find(arg, "|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
--print("Got item" .. Id);
