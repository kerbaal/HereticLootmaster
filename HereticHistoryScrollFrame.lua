local ADDON, Addon = ...

local Util = Addon.Util

function HereticHistoryScrollFrame_OnLoad(self)
  HybridScrollFrame_OnLoad(self);
  self.update = HereticHistoryScrollFrame_Update;
  self.scrollBar.doNotHide = true
  --self.dynamic =
  --  function (offset)
  --    return math.floor(offset / 20), offset % 20
  --  end
  HybridScrollFrame_CreateButtons(self, "HereticLootFrame");
end

function HereticHistoryScrollFrame_Update(self)
  if not self or not self.itemList then return end
  local scrollFrame = self
  local offset = HybridScrollFrame_GetOffset(scrollFrame);
  local buttons = scrollFrame.buttons;
  local numButtons = #buttons;
  local buttonHeight = buttons[1]:GetHeight();
  local itemList = self.itemList
  local n = itemList:Size();
  Util.dbgprint("update history list")
  for i=1, numButtons do
    local frame = buttons[i];
    local index = i + offset;
    HereticLootFrame_SetLoot(frame, index, itemList:GetEntry(index))
    HereticLootFrame_Update(frame)
    frame.HereticOnClick = scrollFrame.HereticOnItemClicked
  end
  HybridScrollFrame_Update(scrollFrame, n * buttonHeight, scrollFrame:GetHeight());
end

function HereticHistoryScrollFrame_GetItemAtCursor(self)
  if not self or not self.itemList then return nil end
  local buttons = self.buttons;
  local numButtons = #buttons;
  for i=1, numButtons do
    local frame = buttons[i];
    if (frame and frame:IsMouseOver() and frame:IsVisible()) then
      return frame
    end
  end
  return nil
end
