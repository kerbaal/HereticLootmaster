local ADDON, Addon = ...

local Util = Addon.Util

local function eventHandlerSystem(self, event, msg)
  -- Don't track rolls if collector frame is invisible.
  if not self:IsVisible() then return end
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
    table.insert(self.rolls, HereticRoll:New(Util.CompleteUnitName(name), roll, minRoll, maxRoll))
    HereticRollCollectorFrame_Update(self)
  end
end

local function eventHandler(self, event, ...)
  if (event == "CHAT_MSG_SYSTEM") then
    eventHandlerSystem(self, event, ...)
  end
end

function HereticRollFrame_SetRoll(self, id, roll)
  local rollFrameName = self:GetName() .. "RollFrame" .. id
  local rollFrame = _G[rollFrameName]
  if not rollFrame then return end
  if not roll then
    rollFrame:Hide()
    return
  end
  rollFrame.roll = roll
  local nameText = _G[rollFrameName .. "Name"]
  nameText:SetText(Util.ShortenFullName(roll.name))
  local rollText = _G[rollFrameName .. "Roll"]
  rollText:SetText(""..roll.roll)
  rollText:SetTextColor(roll:GetColor())
  rollFrame:Show()
end

function HereticRollCollectorFrame_Update(self, ...)
  local scrollBarName = self:GetName().."ScrollBar"
  local scrollBar = _G[scrollBarName]
  local numRolls = #self.rolls
  FauxScrollFrame_Update(scrollBar, numRolls, 8, 20,
    self:GetName() .. "RollFrame", 170, 190);
  local offset = FauxScrollFrame_GetOffset(scrollBar)
  table.sort(self.rolls, HereticRoll.Compare)
  for id=1,8 do
    HereticRollFrame_SetRoll(self, id, self.rolls[id+offset])
  end
end

function HereticRollCollectorFrame_Toggle(self)
  if self:IsVisible() then return end
  wipe(self.rolls)
  HereticRollCollectorFrame_Update(self)
  self:Show()
end

function HereticRollCollectorFrame_OnLoad(self)
  self.rolls = {}
  self:RegisterForDrag("LeftButton");
  self:SetScript("OnEvent", eventHandler);
  self:RegisterEvent("CHAT_MSG_SYSTEM");
  HereticRollCollectorFrame_Update(self)
  self.Toggle = HereticRollCollectorFrame_Toggle
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
  local cursorX, cursorY = GetCursorPosition();
  local uiScale = UIParent:GetScale();
  button:SetAlpha(.5);
  HereticRollDragFrame:SetParent(button:GetParent());
  HereticRollDragFrame:SetPoint("CENTER", UIPARENT, "BOTTOMLEFT",
    cursorX / uiScale, cursorY / uiScale);
  HereticRollDragFrame:StartMoving();
  HereticRollDragFrame:ClearAllPoints();
  HereticRollDragFrame:Show()
end

function HereticRollFrame_OnDragStop(button)
  KetzerischerLootverteilerFrame:OnDropRoll(button.roll)
  button:SetAlpha(1.0);
  HereticRollDragFrame:StopMovingOrSizing();
  HereticRollDragFrame:ClearAllPoints();
  HereticRollDragFrame:Hide();
  HereticRollDragFrame:SetUserPlaced(false);
end
