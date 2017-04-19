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

function HereticRoll:GetCategory()
  local categories = {25, 50, 100}
  local n = #categories
  for i=1,#categories do
    if self.max == categories[i] then
      return i
    end
  end
  return 0
end

function HereticRoll:GetColor()
  local category = self:GetCategory()
  if (category == 0) then
    return 1.0, 0, 0
  end
  local r, g, b, _ = GetItemQualityColor(category)
  return r, g, b
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
