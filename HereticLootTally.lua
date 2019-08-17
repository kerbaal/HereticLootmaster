function HereticLootTally_OnEnter(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
  local categories = ""
  local first = true
  for category,max in pairs(HereticRoll.GetCategories()) do
    local coloredCategory = HereticRoll.GetColoredCategoryName(category);
    categories = coloredCategory .. (first and " " or ", ") .. categories
    first = false
  end
  local text = "Shows items |cff00ccffdonated|r and received in categories "
  GameTooltip:SetText(text .. categories);
end

function HereticLootTally_SetFromPlayer(self, name)
  local donations = Addon:CountDonationsFor(name)
  if donations > 0 then
    self.donated:SetFormattedText("|cff00ccff%d|r /", donations);
  else
    self.donated:SetText("");
  end
  local count = Addon:CountLootFor(name)
  self.received:SetText(Util.formatLootCount(count))
end

function HereticPlayerInfo_OnClick(self)
  Util.dbgprint("clicked")
end

function HereticPlayerInfo_OnEnter(self)

end

function HereticPlayerInfoScrollFrame_OnLoad(self)
  HybridScrollFrame_OnLoad(self);
  self.update = HereticPlayerInfoScrollFrame_Update;
  self.scrollBar.doNotHide = true
  self.dynamic =
    function (offset)
      return math.floor(offset / 20), offset % 20
    end
  HybridScrollFrame_CreateButtons(self, "HereticPlayerInfoTemplate");
end

function HereticPlayerInfoScrollFrame_Update(self)
  local scrollFrame = KetzerischerLootverteilerFrameTabView3Container
  local offset = HybridScrollFrame_GetOffset(scrollFrame);
  local buttons = scrollFrame.buttons;
  local numButtons = #buttons;
  local buttonHeight = buttons[1]:GetHeight();

  local playernames={}
  local n=0

  for k,v in pairs(Addon.lootCount) do
    n=n+1
    playernames[n]=k
  end

  for i=1, numButtons do
    local frame = buttons[i];
    local index = i + offset;
    if (index <= n) then
      frame:SetID(index);
      frame.name:SetText(HereticRaidInfo:GetColoredPlayerName(playernames[index]));
      HereticLootTally_SetFromPlayer(frame.lootTally, playernames[index])
      frame:Show()
    else
      frame:Hide()
    end
  end
  HybridScrollFrame_Update(scrollFrame, n * buttonHeight, scrollFrame:GetHeight());
end
