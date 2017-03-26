local ADDON, Addon = ...

local Util = Addon.Util

function HereticRollCollectorFrame_OnLoad(self)
  self:RegisterForDrag("LeftButton");
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

function HereticRollCollectorFrame_OnUpdate(self, elapsed)
  self.lastUpdate = (self.lastUpdate or 0) + elapsed
  if (self.lastUpdate > 1) then
    self.lastUpdate = 0
    print("Rollcollector update")
    for i,roll in ipairs(Addon.rolls) do
      HereticRollFrame_SetRoll(self, i, roll)
    end
  end
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
