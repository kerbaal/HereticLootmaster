local ADDON, Addon = ...

local Util = Addon.Util

HereticRoll = {};
HereticRoll.__index = HereticRoll;
function HereticRoll:New(name, roll, min, max)
   local self = {};
   setmetatable(self, HereticRoll);

   self.name = name
   self.roll = roll
   self.min = min
   self.max = max
   return self;
end
