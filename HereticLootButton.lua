local ADDON, Addon = ...

local Util = Addon.Util

function HereticLootButton_OnClick(self, button, down)
  local parent = self:GetParent()
  if (parent.HereticOnClick and parent:HereticOnClick(button, down)) then
    return
  end

  if (button == "LeftButton") then
    local name, _ = Util.DecomposeName(parent.donator)
    local itemLink = select(2,GetItemInfo(parent.itemLink))
    if ( IsModifiedClick() ) then
      HandleModifiedItemClick(itemLink);
    else
      ShowUIPanel(ItemRefTooltip);
      if ( not ItemRefTooltip:IsShown() ) then
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
      end
      ItemRefTooltip:SetHyperlink(parent.itemLink);
      ItemRefTooltipTextRight1:SetText(name .. " ")
      ItemRefTooltipTextRight1:SetTextColor(FRIENDS_BNET_NAME_COLOR.r, FRIENDS_BNET_NAME_COLOR.g, FRIENDS_BNET_NAME_COLOR.b);
      ItemRefTooltipTextRight1:Show()
      ItemRefTooltip:Show();
    end
  elseif (button == "RightButton") then
    if ( not IsModifiedClick() ) then
      ChatFrame_OpenChat("/w " .. parent.donator .. " ")
    end
  end
end

function HereticLootButton_OnEnter(self, motion)
  local itemLink = Addon.itemList:GetItemLink(self:GetParent():GetID())
  if itemLink then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetHyperlink(itemLink);
    CursorUpdate(self);
  end
end

function HereticLootButton_FromId(id)
  return _G["HereticLootFrame"..id.."Button"];
end

function HereticLootButton_Update(parent)
  local button = _G[parent:GetName() .. "Button"]
  if (button == nil) then
    return
  end

  if (parent == nil or parent.itemLink == nil or parent.donator == nil) then
    button:Hide()
    return
  end

  local itemId = Util.GetItemIdFromLink(parent.itemLink)

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice = GetItemInfo(parent.itemLink)
  local locked = false;
  local isQuestItem = false;
  local questId = nil;
  local isActive = false;
  local text = _G[parent:GetName() .. "ButtonText"];

  if ( itemTexture ) then
    local color = ITEM_QUALITY_COLORS[quality];
    SetItemButtonQuality(button, quality, itemId);
    _G[parent:GetName() .. "ButtonIconTexture"]:SetTexture(itemTexture);
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

    local questTexture = _G[parent:GetName() .. "ButtonIconQuestTexture"];
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
    local countString = _G[parent:GetName() .. "ButtonCount"];
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
    _G[parent:GetName() .. "ButtonIconTexture"]:SetTexture(nil);
    SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
    --LootFrame:SetScript("OnUpdate", LootFrame_OnUpdate);
    button:Disable();
  end
  button:Show();
end

function HereticLootFrame_FromId(id)
  return _G["HereticLootFrame"..id];
end

function HereticLootFrame_SetLoot(id, index, itemLink, donator, sender)
  local frame = HereticLootFrame_FromId(id);
  frame.index = index
  frame.itemLink = itemLink
  frame.donator = donator
  frame.sender = sender
end

function HereticLootFrame_SetWinner(frame, roll)
  frame.winner = roll
  HereticLootFrame_UpdateFrame(frame)
end

function HereticLootFrame_UpdateFrame(frame)
  if frame.donator == nil then
    frame:Hide()
    return
  end
  HereticLootButton_Update(frame)
  local name, realm = Util.DecomposeName(frame.donator)
  local from = _G[frame:GetName() .. "FromButtonText"];
  from:SetText(name);
  frame:Show();
  local from = _G[frame:GetName() .. "SlotButton"];
  local fromText = _G[frame:GetName() .. "SlotButtonText"];
  local winner = _G[frame:GetName() .. "WinnerFrame"];
  if (frame.winner == nil) then
    winner:Hide()
    from:Show()
    fromText:SetText("|cFF333311Drag Roll Here|r");
    fromText:SetJustifyH("CENTER")
  else
    from:Hide()
    HereticRollFrame_SetRoll(winner, frame.winner)
  end
end

function HereticLootFrame_Update(id)
  local frame = HereticLootFrame_FromId(id);
  if frame == nil then return end

  HereticLootFrame_UpdateFrame(frame)
end
