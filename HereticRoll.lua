local ADDON, Addon = ...

local Util = Addon.Util

HereticRoll = {};
HereticRoll.__index = HereticRoll;
function HereticRoll:New(name, roll, max)
   local self = {};
   setmetatable(self, HereticRoll);
   self.name = name
   self.roll = roll
   self.max = max
   return self;
end

function HereticRoll.GetCategories()
  return {25, 50, 100}
end

function HereticRoll.CategoryForMax(max)
  local categories = HereticRoll.GetCategories()
  local n = #categories
  for i=1,#categories do
    if max == categories[i] then
      return i
    end
  end
  return 0
end

function HereticRoll:GetCategory()
  return HereticRoll.CategoryForMax(self.max)
end

function HereticRoll.ColorForCategory(category)
  if (category == 0) then
    return 1.0, 0, 0, "FFFF0000"
  end
  return GetItemQualityColor(category)
end

function HereticRoll.ColorForMax(max)
  local category = HereticRoll.CategoryForMax(max)
  return GetItemQualityColor(category)
end

function HereticRoll:GetColor()
  local category = self:GetCategory()
  return HereticRoll.ColorForCategory(category)
end

-- Returns true if rollA should be before rollB.
function HereticRoll.Compare(rollA, rollB)
  local catA = rollA:GetCategory()
  local catB = rollB:GetCategory()
  if catA == catB then
    return rollA.roll > rollB.roll
  end
  return catA > catB
end

function HereticRoll.__tostring(self)
  return "" .. self.name .. " rolled " .. self.roll .. " / " .. self.max;
end

function HereticRoll:Validate()
  if not self.name or not self.roll or not self.max then
    return false
  end
  setmetatable(self, HereticRoll)
  return true
end
