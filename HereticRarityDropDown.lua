local ADDON, Addon = ...

local Util = Addon.Util

local function HereticRarityDropDown_OnClick(self)
  UIDropDownMenu_SetSelectedID(HereticRarityDropDown, self:GetID())
  Addon.minRarity = { self.value, self:GetID() }
end

function HereticRarityDropDown_Initialize(self, level)
 for i = 0, 5 do
   local r, g, b, hex = GetItemQualityColor(i)
   local info = UIDropDownMenu_CreateInfo()
   info.text = "|c" .. hex .. _G["ITEM_QUALITY" .. i .. "_DESC"] .. "|r"
   info.value = i
   info.func = HereticRarityDropDown_OnClick
   UIDropDownMenu_AddButton(info, level)
 end
 local info = UIDropDownMenu_CreateInfo()
 info.text = "|cFFFF0000" .. DISABLE .. "|r"
 info.value = 1000
 info.func = HereticRarityDropDown_OnClick
 UIDropDownMenu_AddButton(info, level)
 UIDropDownMenu_JustifyText(self, "LEFT")
 UIDropDownMenu_SetWidth(self, 100);
end

function HereticRarityDropDown_OnShow(self)
  UIDropDownMenu_Initialize(self, HereticRarityDropDown_Initialize);
  if not Addon.minRarity then return end
  UIDropDownMenu_SetSelectedID(self, Addon.minRarity[2])
end
