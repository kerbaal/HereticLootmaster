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

function HereticRollCollectorFrame_OnLoad(self)
  self.rolls = {}
  self:RegisterForDrag("LeftButton");
  self:SetScript("OnEvent", eventHandler);
  self:RegisterEvent("CHAT_MSG_SYSTEM");
end

function HereticRollFrame_SetRoll(self, id, roll)
  local rollFrameName = self:GetName() .. "RollFrame" .. id
  local rollFrame = _G[rollFrameName]
  if not rollFrame then return end
  local nameText = _G[rollFrameName .. "Name"]
  nameText:SetText(Util.ShortenFullName(roll.name))
  local rollText = _G[rollFrameName .. "Roll"]
  rollText:SetText(""..roll.roll)
  rollFrame:Show()
end

function HereticRollCollectorFrame_Update(self)
  print("Rollcollector update")
  for i,roll in ipairs(self.rolls) do
    HereticRollFrame_SetRoll(self, i, roll)
  end
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
  button:SetAlpha(1.0);
	HereticRollDragFrame:StopMovingOrSizing();
  HereticRollDragFrame:ClearAllPoints();
  HereticRollDragFrame:Hide();
  HereticRollDragFrame:SetUserPlaced(false);
end
