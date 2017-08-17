local ADDON, Addon = ...

local Util = Addon.Util

function HereticLootButton_OnClick(self, button, down)
  local parent = self:GetParent()
  if (parent.HereticOnClick and parent:HereticOnClick(button, down, parent.entry)) then
    return
  end

  if (button == "LeftButton") then
    local name, _ = Util.DecomposeName(parent.entry.donator)
    local itemLink = select(2,GetItemInfo(parent.entry.itemLink))
    if ( IsModifiedClick() ) then
      HandleModifiedItemClick(itemLink);
    else
      ShowUIPanel(ItemRefTooltip);
      if ( not ItemRefTooltip:IsShown() ) then
        ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE");
      end
      ItemRefTooltip:SetHyperlink(parent.entry.itemLink);
      ItemRefTooltipTextRight1:SetText(name .. " ")
      ItemRefTooltipTextRight1:SetTextColor(FRIENDS_BNET_NAME_COLOR.r, FRIENDS_BNET_NAME_COLOR.g, FRIENDS_BNET_NAME_COLOR.b);
      ItemRefTooltipTextRight1:Show()
      ItemRefTooltip:Show();
    end
  elseif (button == "RightButton") then
    if ( not IsModifiedClick() ) then
      ChatFrame_OpenChat("/w " .. parent.entry.donator .. " ")
    end
  end
end

function HereticLootButton_OnEnter(self, motion)
  local parent = self:GetParent()
  local itemLink = parent.entry.itemLink
  if itemLink then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
    GameTooltip:SetHyperlink(itemLink);
    CursorUpdate(self);
  end
end

function HereticLootButton_FromId(id)
  return _G["HereticLootFrame"..id.."Button"];
end

function HereticLootButton_Update(parent, entry)
  local button = _G[parent:GetName() .. "Button"]
  if (button == nil) then
    return
  end

  if (entry == nil) then
    button:Hide()
    return
  end

  local itemId = Util.GetItemIdFromLink(entry.itemLink)

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice = GetItemInfo(entry.itemLink)
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

function HereticLootFrame_FromId(self, id)
  return _G[self:GetName().."HereticLootFrame"..id];
end

function HereticLootFrame_SetLoot(self, index, entry)
  self.index = index
  self.entry = entry
end

function HereticLootFrame_SetWinner(frame, roll)
  if roll then
    PlaySound("igCharacterInfoTab");
  else
    PlaySound("INTERFACESOUND_LOSTTARGETUNIT");
  end
  local prevWinner = frame.entry.winner
  frame.entry.winner = roll
  HereticLootFrame_Update(frame)
  Addon:OnWinnerUpdate(frame.entry, prevWinner)
end

function HereticLootFrameWinnerFrame_HereticOnDragStart(self,dragFrame)
end

function HereticLootFrameWinnerFrame_HereticOnDragStop(self,dragFrame,winner)
  local frame = self:GetParent()
  HereticLootFrame_SetWinner(frame, winner)
end

function HereticLootFrameWinnerFrame_HereticOnDrop(frame, button)
  local oldWinner = frame.entry.winner
  HereticLootFrame_SetWinner(frame, button.roll)
  return oldWinner
end

function HereticLootFrame_OnLoad(frame)
  local slotText = _G[frame:GetName() .. "WinnerFrameSlotText"];
  slotText:SetText("|cFF333311Drag Roll Here|r");

  local winnerFrame = _G[frame:GetName() .. "WinnerFrame"];
  winnerFrame.HereticOnDragStart = HereticLootFrameWinnerFrame_HereticOnDragStart
  winnerFrame.HereticOnDragStop = HereticLootFrameWinnerFrame_HereticOnDragStop
  frame.HereticOnDrop = HereticLootFrameWinnerFrame_HereticOnDrop
end

function HereticLootFrame_Update(frame)
  if frame.entry == nil then
    frame:Hide()
    return
  end
  HereticLootButton_Update(frame, frame.entry)
  local name, realm = Util.DecomposeName(frame.entry.donator)
  local from = _G[frame:GetName() .. "FromButtonText"];
  from:SetText(Util.GetColoredPlayerName(frame.entry.donator));
  local dateText = _G[frame:GetName() .. "FromButtonDate"];
  dateText:SetText(date("%H:%M %d.%m.", frame.entry.time));
  frame:Show();
  local winnerFrame = _G[frame:GetName() .. "WinnerFrame"];
  HereticRollFrame_SetRoll(winnerFrame, frame.entry.winner, true)
end
