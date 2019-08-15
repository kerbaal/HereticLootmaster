local ADDON, Addon = ...

local Util = Addon.Util

function HereticLootButton_OnClick(self, button, down)
  local parent = self:GetParent():GetParent();
  if (parent.HereticOnClick and parent:HereticOnClick(button, down, parent.entry)) then
    return
  end

  if (button == "LeftButton") then
    local name, _ = Util.DecomposeName(parent.entry.donator)
    local itemLink = select(2, GetItemInfo(parent.entry.itemLink))
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

function HereticLootButtonItemType_OnEnter(self, motion)
  local lootButton = self:GetParent()
  local parent = lootButton:GetParent()
  local itemLink = parent.entry.itemLink
  if itemLink then
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT");

    local itemName, _, quality, itemLevel, itemMinLevel, itemType,
    itemSubType, itemStackCount, itemEquipLoc, itemTexture,
    itemSellPrice, itemClassID, itemSubClassID = GetItemInfo(itemLink)

    local tooltip = ""
    local notfirst = false
    for name,unitId in pairs(HereticRaidInfo.unitids) do
      if Util.CanWearArmorType(name, itemClassID, itemSubClassID) then
        if notfirst then
          tooltip = tooltip .. " "
        end
        notfirst = true
        tooltip = tooltip .. HereticRaidInfo:GetColoredPlayerName(name)
      end
    end
    GameTooltip:SetText(tooltip);
  end
end

function HereticLootButton_FromId(id)
  return _G["HereticLootFrame"..id.."Button"];
end

local GetMoreItemInfo
do
  local tooltipName = "PhanxScanningTooltip" .. random(100000, 10000000)

  local tooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "GameTooltipTemplate")
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")

  local textures = {}
  for i = 1, 10 do
    textures[i] = _G[tooltipName .. "Texture" .. i]
  end

  local cache = setmetatable({}, { __index = function(t, link)
    tooltip:SetHyperlink(link)
    local info = {tex = {}}
    for i = 1, 10 do
      if textures[i]:IsShown() then
        info.tex[i] = textures[i]:GetTexture()
      end
    end
    t[link] = info
    return info
  end })

  function GetMoreItemInfo(link)
    if not link then return nil end
    return cache[link]
  end
end

function HereticLootButton_Update(lootButton, entry)
  local button = lootButton.iconButton;
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
  itemSellPrice, 	itemClassID, itemSubClassID = GetItemInfo(entry.itemLink)
  local locked = false;
  local isQuestItem = false;
  local questId = nil;
  local isActive = false;
  local text = lootButton.itemName;

  if ( itemTexture ) then
    local color = ITEM_QUALITY_COLORS[quality];
    _G.SetItemButtonQuality(button, quality, itemId);
    button.icon:SetTexture(itemTexture);
    text:SetText(itemName);
    if( locked ) then
      --_G.SetItemButtonNameFrameVertexColor(button, 1.0, 0, 0);
      _G.SetItemButtonTextureVertexColor(button, 0.9, 0, 0);
      _G.SetItemButtonNormalTextureVertexColor(button, 0.9, 0, 0);
    else
      --_G.SetItemButtonNameFrameVertexColor(button, 0.5, 0.5, 0.5);
      _G.SetItemButtonTextureVertexColor(button, 1.0, 1.0, 1.0);
      _G.SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
    end

    local questTexture = lootButton.questTexture;
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
    local countString = button.Count;
    if ( itemStackCount > 1 ) then
      countString:SetText(itemStackCount);
      countString:Show();
    else
      countString:Hide();
    end
    button.quality = quality;

    local itemSlotText = lootButton.itemText.itemSlot;
    itemSlotText:SetText(""..(_G[itemEquipLoc] or ""));
    local itemTypeText = lootButton.itemText.itemType;
    if (itemSubClassID ~= 0 and itemClassID == 4) then
      itemTypeText:SetText(""..itemSubType);
    else
      itemTypeText:SetText("")
    end

    button:Enable();
  else
    text:SetText("");
    button.icon:SetTexture(nil);
    _G.SetItemButtonNormalTextureVertexColor(button, 1.0, 1.0, 1.0);
    LootFrame:SetScript("OnUpdate", LootFrame_OnUpdate);
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
    PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB);
  else
    PlaySound(SOUNDKIT.INTERFACE_SOUND_LOST_TARGET_UNIT);
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
  HereticLootFrame_SetWinner(frame:GetParent(), winner)
end

function HereticLootFrameWinnerFrame_HereticOnDrop(frame, button)
  local oldWinner = frame.entry.winner
  HereticLootFrame_SetWinner(frame, button.roll)
  return oldWinner
end

function HereticLootFrameWinnerFrame_OnRightClick(button)
  if button.roll then
    HereticRollCategoryMenu("cursor", 0 , 0, button);
  else
    HereticPlayerMenu("cursor", 0 , 0, button);
  end
end

function HereticDropButton_OnLoad(frame)
  frame.winnerFrame.slotText:SetText("|cFF333311Drag Roll Here|r");

  frame.winnerFrame.HereticOnDragStart = HereticLootFrameWinnerFrame_HereticOnDragStart
  frame.winnerFrame.HereticOnDragStop = HereticLootFrameWinnerFrame_HereticOnDragStop
  frame:GetParent().HereticOnDrop = HereticLootFrameWinnerFrame_HereticOnDrop
  frame.winnerFrame.HereticOnRightClick = HereticLootFrameWinnerFrame_OnRightClick
end

function HereticDropButton_Update(frame, entry)
  HereticRollFrame_SetRoll(frame.winnerFrame, entry.winner, true)
  local name, realm = Util.DecomposeName(entry.donator)
  frame.donatorText:SetText(HereticRaidInfo:GetColoredPlayerName(entry.donator));
  frame.dateText:SetText(date("%H:%M %d.%m.", entry.time));

  local itemName, itemLink, quality, itemLevel, itemMinLevel, itemType,
  itemSubType, itemStackCount, itemEquipLoc, itemTexture,
  itemSellPrice, 	itemClassID, itemSubClassID = GetItemInfo(entry.itemLink)

  frame.itemLevelText:SetText(""..(itemLevel or ""));

  local info = GetMoreItemInfo(itemLink);
  if info and info.tex[1] then
    frame.itemSocketTexture:SetTexture(info.tex[1])
    frame.itemSocketTexture:Show()
  else
    frame.itemSocketTexture:Hide()
  end
end

function HereticLootFrame_Update(frame)
  if frame.entry == nil then
    frame:Hide()
    return
  end
  HereticLootButton_Update(frame.itemButton, frame.entry)
  HereticDropButton_Update(frame.dropButton, frame.entry)
  frame:Show();
end

local HereticPlayerMenuFrame = CreateFrame("Frame", "HereticAssignMenuFrame", UIParent, "UIDropDownMenuTemplate")

function HereticPlayerMenu(anchor, x, y, button)
  UIDropDownMenu_Initialize(HereticPlayerMenuFrame, HereticPlayerMenu_Initialize, "MENU", nil, button);
  ToggleDropDownMenu(1, nil, HereticPlayerMenuFrame, anchor, x, y, button);
end

function HereticPlayerMenu_Initialize( frame, level, button )
  local title = { text = "Assign to Player", isTitle = true};
  UIDropDownMenu_AddButton(title);
  for name,unitId in pairs(HereticRaidInfo.unitids) do
    local coloredName = HereticRaidInfo:GetColoredPlayerName(name);
    local value =
      { text = coloredName,
        func = function() print("You've chosen " .. coloredName);
                 HereticLootFrame_SetWinner(button:GetParent():GetParent(), HereticRoll:New(name, 0, 0));
               end };
    UIDropDownMenu_AddButton( value, level );
  end
end

function HereticRollCategoryMenu(anchor, x, y, button)
  UIDropDownMenu_Initialize(HereticPlayerMenuFrame, HereticRollCategoryMenu_Initialize, "MENU", nil, button);
  ToggleDropDownMenu(1, nil, HereticPlayerMenuFrame, anchor, x, y, button);
end

function AnnounceLootWinner(entry)
  if entry.winner then
    local itemLink = select(2,GetItemInfo(entry.itemLink));
    local raidMsg = "Gz " .. Util.ShortenFullName(entry.winner.name) .. ", du kannst " .. itemLink .. " bei " .. Util.ShortenFullName(entry.donator) .. " abholen.";
    SendChatMessage(raidMsg, "RAID");
    --print(raidMsg)
  end
end

function HereticRollCategoryMenu_Initialize( frame, level, button )
  if not button.roll then
    Util.dbgprint("HereticRollCategoryMenu_Initialize called on button without roll")
    return
  end
  local titleChangeCategory = { text = "Change Category", isTitle = true};
  UIDropDownMenu_AddButton(titleChangeCategory);
  for category,max in pairs(HereticRoll.GetCategories()) do
    local coloredCategory = HereticRoll.GetColoredCategoryName(category);
    local value =
      { text = coloredCategory,
        func = function() print("You've chosen " .. coloredCategory);
                           button.roll.max = max;
                           HereticLootFrame_Update(button:GetParent():GetParent())
                           Addon:OnWinnerUpdate(button:GetParent():GetParent().entry)
               end };
    UIDropDownMenu_AddButton( value, level );
  end
  local titleActions = { text = "Actions", isTitle = true};
  UIDropDownMenu_AddButton(titleActions);
  local announceButton =
    { text = "Announce Winner",
      func = function()  print("You've chosen announcing winner");
               local entry = button:GetParent():GetParent().entry;
               AnnounceLootWinner(entry);
             end };
  UIDropDownMenu_AddButton( announceButton, level );
end
