local ADDON, Addon = ...

local Util = Addon.Util

function HereticLootButton_OnClick(self, button, down)
  if (self.HereticOnClick and self:HereticOnClick(button, down)) then
    return
  end

  if (button == "LeftButton") then
    local name, _ = Util.DecomposeName(self.donator)
    local itemLink = select(2,GetItemInfo(self.itemLink))
    if ( IsModifiedClick() ) then
      HandleModifiedItemClick(itemLink);
    else
      local msg = itemLink .. " (" .. name .. ")";
      SendChatMessage(msg, "RAID")
    end
  elseif (button == "RightButton") then
    if ( not IsModifiedClick() ) then
      ChatFrame_OpenChat("/w " .. self.donator .. " ")
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

function HereticLootButton_SetLoot(id, index, itemLink, donator, sender)
  local button = _G["HereticLootButton"..id];
  button.index = index
  button.itemLink = itemLink
  button.donator = donator
  button.sender = sender
end

function HereticLootButton_Update(id)
  local button = _G["HereticLootButton"..id];
  if (button == nil) then
    return
  end

  if (button.itemLink == nil or button.donator == nil) then
    button:Hide()
    return
  end

  local name, realm = Util.DecomposeName(button.donator)
  local from = _G["HereticLootButton"..id.."FromText"];
  from:SetText(name);

  local itemId = Util.GetItemIdFromLink(button.itemLink)

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice = GetItemInfo(button.itemLink)
  local locked = false;
  local isQuestItem = false;
  local questId = nil;
  local isActive = false;
  local text = _G["HereticLootButton"..id.."Text"];

  if ( itemTexture ) then
    local color = ITEM_QUALITY_COLORS[quality];
    SetItemButtonQuality(button, quality, itemId);
    _G["HereticLootButton"..id.."IconTexture"]:SetTexture(itemTexture);
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

    local questTexture = _G["HereticLootButton"..id.."IconQuestTexture"];
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
    local countString = _G["HereticLootButton"..id.."Count"];
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
    _G["HereticLootButton"..id.."IconTexture"]:SetTexture(nil);
    SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
    --LootFrame:SetScript("OnUpdate", LootFrame_OnUpdate);
    button:Disable();
  end
  button:Show();
end
