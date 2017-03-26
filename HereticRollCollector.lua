local ADDON, Addon = ...

local Util = Addon.Util

function HereticRollCollectorFrame_OnLoad(self)
  self:RegisterForDrag("LeftButton");
end

function HereticRollFrame_SetRoll(id, name, roll, min, max)
  local nameText = _G["HereticRollFrame" .. id .. "Name"]
  nameText:SetText(name)
  local rollText = _G["HereticRollFrame" .. id .. "Roll"]
  rollText:SetText(""..roll)
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
  HereticRollDragFrame:StartMoving();
	HereticRollDragFrame:ClearAllPoints();
  HereticRollDragFrame:SetParent(button:GetParent());
	HereticRollDragFrame:SetPoint("CENTER", UIPARENT, "BOTTOMLEFT",
    cursorX / uiScale, cursorY / uiScale);
  HereticRollDragFrame:Show()
end

function HereticRollFrame_OnDragStop(button)
  button:SetAlpha(1.0);
	HereticRollDragFrame:StopMovingOrSizing();
  HereticRollDragFrame:ClearAllPoints();
  HereticRollDragFrame:Hide();
  HereticRollDragFrame:SetUserPlaced(false);
end
