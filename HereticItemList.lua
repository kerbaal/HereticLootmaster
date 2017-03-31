local HereticItem = {}
local HereticItemList = {}

HereticItemList.__index = HereticItemList
function HereticItemList:New(instanceID, master, entries)
	local obj = {
	instanceID = instanceID,
	master = master,
	entries = entries,
	}
	setmetatable(obj, self)
	return obj
end

HereticItem.__index = HereticItem
function HereticItem:New(itemLink, donator, winner, rollActionID)
	local obj = {
	itemLink = itemLink,
	donator = donator,
	winner = winner,
	rollActionID = rollActionID,
	}
	setmetatable(obj, self)
	return obj
end

function HereticItem:EntryTest()
	local helpTable = {}
	for i = 1, 5 do
		local newObj = HereticItem:New("Link"..i, "Donator"..i, {"Name"..i,i,i+i},"RollID"..i)
		table.insert(helpTable, newObj)
		print(newObj)
	end
	print(helpTable[1].itemLink)
	print(helpTable[2].itemLink)
end

function HereticItemList:EntryTest()
	local helpTable = {}
	for i = 1, 5 do
		local newEntry = HereticItem:New("Link"..i, "Donator"..i, {"Name"..i,i,i+i},"RollID"..i)
		local newObj = HereticItemList:New(10000+i, "Nagisa-DieAldor", newEntry)
		table.insert(helpTable, newObj)
		print(newObj.entries.itemLink)
	end
end

--[[

function HereticItem:Get(objID)
  if not objID then return nil end
  return self.itemLink, self.donator, self.winner
end

function HereticItem:GetItemLink(index)
  if (index > self.size) then return nil end
  return self.items[index]
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

function HereticItem:Validate()
  for i=self.size,1,-1 do
    if (self.items[i] == nil or
        self.donators[i] == nil or
        self.senders[i] == nil) then
      self:Delete(i)
    end
  end
end
]]
