local ADDON, Addon = ...

local Util = Addon.Util

local function HereticHistoryDropDown_OnClick(self)
  UIDropDownMenu_SetSelectedID(HereticHistoryDropDown, self:GetID())
  Addon:SetCurrentHistory(self:GetID())
end

local function DifficultyIDToString(difficultyID)
  return GetDifficultyInfo(difficultyID)
end

function HereticHistoryDropDown_Initialize(self, level)
  UIDropDownMenu_SetWidth(self, 200);
  UIDropDownMenu_JustifyText(self, "LEFT")
  if not HereticHistory.histories
     or not Addon.activeHistoryIndex
     or HereticHistory.NumberOfItemLists() < 1 then
    return
  end

  for i, h in ipairs(HereticHistory.histories or {}) do
    local info = UIDropDownMenu_CreateInfo()
    info.text = h.instanceName .. " " .. ((h.difficultyID and "(".. DifficultyIDToString(h.difficultyID) .. ")") or "") .. " " .. (h.instanceID or "")
    info.value = i
    info.func = HereticHistoryDropDown_OnClick
    UIDropDownMenu_AddButton(info, level)
  end
end

function HereticHistoryDropDown_OnShow(self)
  UIDropDownMenu_Initialize(self, HereticHistoryDropDown_Initialize);
  UIDropDownMenu_SetSelectedID(self, Addon.activeHistoryIndex)
end
