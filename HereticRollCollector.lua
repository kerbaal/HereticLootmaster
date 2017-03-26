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
  button.dragSavedPoint = Util.pack(button:GetPoint())
	button:StartMoving();
	button:ClearAllPoints();
	button:SetPoint("CENTER", UIPARENT, "BOTTOMLEFT", cursorX / uiScale, cursorY / uiScale);
end

function HereticRollFrame_OnDragStop(button)
	button:StopMovingOrSizing();
  button:ClearAllPoints();
	button:SetPoint(Util.unpack(button.dragSavedPoint));
  button:SetUserPlaced(false)
end
