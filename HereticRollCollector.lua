local ADDON, Addon = ...

local Util = Addon.Util

local function eventHandlerSystem(self, event, msg)
  local ROLL_REGEX = RANDOM_ROLL_RESULT
  ROLL_REGEX = gsub(ROLL_REGEX, "%(", "%%(")
  ROLL_REGEX = gsub(ROLL_REGEX, "%-", "%%-")
  ROLL_REGEX = gsub(ROLL_REGEX, "%)", "%%)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%1%$s", "(.+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%1%$s", "(.+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%2%$d", "(%%d+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%3%$d", "(%%d+)")
  ROLL_REGEX = gsub(ROLL_REGEX, "%%4%$d", "(%%d+)")

  local name, roll, minRoll, maxRoll = msg:match(ROLL_REGEX)
  roll, minRoll, maxRoll = tonumber(roll), tonumber(minRoll), tonumber(maxRoll)
  if name and roll and minRoll and maxRoll then
    Util.dbgprint (name .. " " .. roll .. " range: " .. minRoll .. " - " .. maxRoll);
    table.insert(self.rolls, HereticRoll:New(Util.CompleteUnitName(name), roll, maxRoll))
    PlaySoundKitID(31579);  --UI_BonusLootRoll_Start
    PlaySoundKitID(31581);  --UI_BonusLootRoll_End
    HereticRollCollectorFrame_Update(self)
  end
end

local function eventHandler(self, event, ...)
  if (event == "CHAT_MSG_SYSTEM") then
    eventHandlerSystem(self, event, ...)
  end
end

function HereticRollFrame_SetRoll(rollFrame, roll, showDropTarget)
  if not rollFrame then return end
  if not roll and not showDropTarget == true then
    rollFrame:Hide()
    return
  end
  rollFrame.roll = roll
  local nameText = _G[rollFrame:GetName() .. "Name"]
  local rollText = _G[rollFrame:GetName() .. "Roll"]
  local itemCountText = _G[rollFrame:GetName() .. "ItemCount"]
  local slotText = _G[rollFrame:GetName() .. "SlotText"]
  if roll then
    nameText:SetText(Util.ShortenFullName(roll.name))
    nameText:Show()
    rollText:SetText(""..roll.roll)
    rollText:SetTextColor(roll:GetColor())
    rollText:Show()
    local count = Addon:CountLootFor(roll.name)
    itemCountText:SetText(Util.formatLootCount(count))
    itemCountText:Show()
    slotText:Hide()
  else
    rollText:Hide()
    nameText:Hide()
    itemCountText:Hide()
    slotText:Show()
  end
  rollFrame:Show()
end

function HereticRollCollectorFrame_Update(self, ...)
  local scrollBarName = self:GetName().."ScrollBar"
  local scrollBar = _G[scrollBarName]
  local numRolls = #self.rolls
  FauxScrollFrame_Update(scrollBar, numRolls, 8, 20,
    self:GetName() .. "RollFrame", 170, 190);
  local offset = FauxScrollFrame_GetOffset(scrollBar)
  table.sort(self.rolls, HereticRoll.CompareWithLootCount)
  for id=1,8 do
    local rollFrameName = self:GetName() .. "RollFrame" .. id
    local rollFrame = _G[rollFrameName]
    HereticRollFrame_SetRoll(rollFrame, self.rolls[id+offset])
  end
end

function HereticRollCollectorFrame_Toggle(self)
  if self:IsVisible() then
    self:Hide()
  else
    HereticRollCollectorFrame_Update(self)
    self:Show()
  end
end

function HereticRollCollectorFrame_BeginRollCollection(self, entry)
  if (self.entry == entry) then
    return  -- Don't start a new collection with the same item.
  end
  wipe(self.rolls)
  self.entry = entry
  HereticRollCollectorFrame_Update(self)
end

function HereticRollCollectorFrame_HereticOnDrop(self, button)
  if Util.table_contains(self.rolls, button.roll) then
    return
  end
  table.insert(self.rolls, button.roll)
  HereticRollCollectorFrame_Update(self)
end

function HereticRollCollectorFrame_OnLoad(self)
  self.rolls = {}
  self:RegisterForDrag("LeftButton");
  self:SetScript("OnEvent", eventHandler);
  self:RegisterEvent("CHAT_MSG_SYSTEM");
  HereticRollCollectorFrame_Update(self)
  self.Toggle = HereticRollCollectorFrame_Toggle
  HereticRollCollectorFrame.HereticOnDrop = HereticRollCollectorFrame_HereticOnDrop
end

function RollsScrollBar_Update(self)
  HereticRollCollectorFrame_Update(self:GetParent())
end

function HereticRollCollectorFrame_OnUpdate(self, elapsed)
end

function HereticRollCollectorFrame_OnDragStart()
  HereticRollCollectorFrame:StartMoving();
end

function HereticRollCollectorFrame_OnDragStop()
  HereticRollCollectorFrame:StopMovingOrSizing();
end

function HereticRollFrame_OnDragStart(button)
  if (not button.roll or not Addon:CanModify()) then return end
  local cursorX, cursorY = GetCursorPosition();
  local uiScale = UIParent:GetScale();
  button:SetAlpha(.5);
  HereticRollDragFrame:SetParent(button:GetParent());
  HereticRollDragFrame:SetPoint("CENTER", UIPARENT, "BOTTOMLEFT",
    cursorX / uiScale, cursorY / uiScale);
  HereticRollDragFrame:StartMoving();
  HereticRollDragFrame:ClearAllPoints();
  HereticRollFrame_SetRoll(HereticRollDragFrame, button.roll)
  if button.HereticOnDragStart then button:HereticOnDragStart(HereticRollDragFrame) end
  HereticRollDragFrame:Show()
end

function HereticRollFrame_OnDragStop(button)
  if not button.roll or not Addon:CanModify() then return end
  local dropFrame = KetzerischerLootverteilerFrame:GetItemAtCursor()
  local data = nil
  if dropFrame and dropFrame.HereticOnDrop then
    data = dropFrame:HereticOnDrop(button)
  end
  if button.HereticOnDragStop then
    button:HereticOnDragStop(HereticRollDragFrame, data)
  end

  button:SetAlpha(1.0);
  HereticRollDragFrame:StopMovingOrSizing();
  HereticRollDragFrame:ClearAllPoints();
  HereticRollDragFrame:Hide();
  HereticRollDragFrame:SetUserPlaced(false);
end

function HereticRollFrame_OnClick(button)
  if button.HereticOnRightClick then
    button:HereticOnRightClick()
  end
end
