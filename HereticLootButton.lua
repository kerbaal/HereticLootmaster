local ADDON, Addon = ...

local Util = Addon.Util

function HereticLootButton_OnClick(self, button)
  if (button == "LeftButton") then
    local name, _ = Util.DecomposeName(self.itemDonor)
    local itemLink = select(2,GetItemInfo(self.itemLink))
    if ( IsModifiedClick() ) then
      HandleModifiedItemClick(itemLink);
    else
      local msg = itemLink .. " (" .. name .. ")";
      SendChatMessage(msg, "RAID")
    end
  elseif (button == "RightButton") then
    if ( IsModifiedClick() ) then
      local index = Addon.itemListView:IdToIndex(self:GetID())
      Addon:DeleteItem(index)
    else
      ChatFrame_OpenChat("/w " .. self.itemDonor .. " ")
    end
  end
end

function HereticLootButton_OnEnter(self, motion)
  local itemLink = Addon.itemList:GetItemLink(self:GetID())
  if itemLink then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetHyperlink(itemLink);
    CursorUpdate(self);
  end
end

function HereticLootButton_Update(index)
  local button = _G["HereticLootButton"..index];
  if (button == nil) then
    return
  end
  local itemIndex = Addon.itemListView:IdToIndex(index);
  local itemLink, donator, _ = Addon.itemList:Get(itemIndex)

  if (itemLink == nil) then
    button:Hide()
    return
  end

  button.itemLink = itemLink
  button.itemDonor = donator
  local name, realm = Util.DecomposeName(donator)
  local from = _G["HereticLootButton"..index.."FromText"];
  from:SetText(name);

  local itemId = Util.GetItemIdFromLink(itemLink)

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice = GetItemInfo(itemLink)
  local locked = false;
  local isQuestItem = false;
  local questId = nil;
  local isActive = false;
  local text = _G["HereticLootButton"..index.."Text"];

  if ( itemTexture ) then
    local color = ITEM_QUALITY_COLORS[quality];
    SetItemButtonQuality(button, quality, itemId);
    _G["HereticLootButton"..index.."IconTexture"]:SetTexture(itemTexture);
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

    local questTexture = _G["HereticLootButton"..index.."IconQuestTexture"];
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
    local countString = _G["HereticLootButton"..index.."Count"];
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
    _G["HereticLootButton"..index.."IconTexture"]:SetTexture(nil);
    SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
    --LootFrame:SetScript("OnUpdate", LootFrame_OnUpdate);
    button:Disable();
  end
  button:Show();
end
