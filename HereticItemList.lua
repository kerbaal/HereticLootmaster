local helpTable = {}
local HereticItemAllocation = {}

HereticItemAllocation.__index = HereticItemAllocation
function HereticItemAllocation:New()
	local obj = {
	itemLink = "",
	donator = "",
	winner = {},
	rollActionID = 0,
	size = 0
	}
	setmetatable(obj, self)
	return self
end

function HereticItemAllocation:Add(itemLink, donator, winner, rollActionID)
	self.itemLink = itemLink
	self.donators = donator
	self.winner = winner
	self.rollActionID = rollActionID
	--self.size = self.size + 1
return self
end


for i = 1, 5 do
local newObj = HereticItemAllocation:New()
local newObj = newObj:Add("Link"..i, "Donator"..i, {"Name"..i,i,i+i},"RollID"..i)
table.insert(helpTable, newObj)
print(newObj.itemLink)
end

--print(HereticItemAllocation.itemLink)

print(helpTable[1].itemLink)
print(helpTable[2].itemLink)

--[[
local HereticItemList = {
	instanceID = 0,
	master = "",
	entries = {},
	size = 0
}
]]
--[[

function HereticItemAllocation:Get(objID)
  if not objID then return nil end
  return self.itemLink, self.donator, self.winner
end

function HereticItemList:GetItemLink(index)
  if (index > self.size) then return nil end
  return self.items[index]
end

function HereticItemAllocation:Add(itemLink, donator, winner, rollActionID)
	self.itemLink = itemLink
	self.donators = donator
	self.winner = winner
	self.rollActionID = rollActionID
	self.size = self.size + 1
end

function HereticItemList:Delete(index)
  if index < 1 or index > self.size then return end
  table.remove(self.items, index)
  table.remove(self.donators, index)
  table.remove(self.senders, index)
  self.size = self.size-1
end

function HereticItemList:ItemById(item, donator, sender)
  for i=1,self.size do
    if (self.items[i] == item and
        self.donators[i] == donator and
        self.senders[i] == sender) then
      return i
    end
  end
  return nil
end

function HereticItemList:DeleteAllItems()
  wipe(self.items)
  wipe(self.donators)
  wipe(self.senders)
  self.size = 0
end

function HereticItemList:Validate()
  for i=self.size,1,-1 do
    if (self.items[i] == nil or
        self.donators[i] == nil or
        self.senders[i] == nil) then
      self:Delete(i)
    end
  end
end
]]
