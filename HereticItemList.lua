HereticItem = {}
HereticItemList = {}

HereticItemList.__index = HereticItemList
function HereticItemList:New(instanceID, master, entries)
	local obj = {
	instanceID = instanceID,
	master = master,
	entries = {},
	}
	setmetatable(obj, self)
	return obj
end

HereticItem.__index = HereticItem
function HereticItem:New(itemLink, donator, winner, rollActionID)
	local obj = {
	itemLink = itemLink or "",
	donator = donator or "",
	winner = winner or {},
	rollActionID = rollActionID or 0,
	}
	setmetatable(obj, self)
	return obj
end

function HereticItemList:GetEntry(pos)
	if (pos < 1 or pos > #self.entries) then return nil end
	return self.entries[pos].itemLink--, self.entries[pos].donator, self.entries[pos].winner, self.entries[pos].rollActionID
end

function HereticItemList:DeleteEntryAt(pos)
	table.remove(self.entries, pos)
end

function HereticItemList:DeleteAllEntries() 
	for i=0, #self.entries do  
		self.entries[i]=nil
	end
end

function HereticItemList:Validate()
	setmetatable(self, HereticItemList)
	if (self.instanceID == 0 or 
		self.master == "") then
		return false
	elseif not self.entries then
		self.entries = {}
	else 
		return true
	end
end

function HereticItemList:GetItemLinkByID(pos)
	return self.entries[pos].itemLink
end

function HereticItemList:Size()
	return #self.entries
end

function HereticItemList:GetEntryId(item, donator)
  for i=1, #self.entries do
    if (self.entries[i].itemLink == item and
        self.entries[i].donator == donator) then
      return i
    end
  end
  return nil
end
--[[local ADDON, Addon = ...

local Util = Addon.Util

ItemList = {};
ItemList.__index = ItemList;
function ItemList:New()
   local self = {};
   setmetatable(self, ItemList);

   self.items = {}
   self.donators = {}
   self.senders = {}
   self.size = 0
   return self;
end

function ItemList:Size()
  return self.size
end

function ItemList:Get(index)
  if (index < 1 or index > self.size) then return nil end
  return self.items[index], self.donators[index], self.senders[index]
end

function ItemList:GetItemLink(index)
  if (index > self.size) then return nil end
  return self.items[index]
end

function ItemList:Add(item, donator, sender)
  local n = self.size+1
  self.items[n] = item
  self.donators[n] = donator
  self.senders[n] = sender
  self.size = n
end

function ItemList:Delete(index)
  if index < 1 or index > self.size then return end
  table.remove(self.items, index)
  table.remove(self.donators, index)
  table.remove(self.senders, index)
  self.size = self.size-1
end

function ItemList:ItemById(item, donator, sender)
  for i=1,self.size do
    if (self.items[i] == item and
        self.donators[i] == donator and
        self.senders[i] == sender) then
      return i
    end
  end
  return nil
end

function ItemList:DeleteAllItems()
  wipe(self.items)
  wipe(self.donators)
  wipe(self.senders)
  self.size = 0
end

function ItemList:Validate()
  for i=self.size,1,-1 do
    if (self.items[i] == nil or
        self.donators[i] == nil or
        self.senders[i] == nil) then
      self:Delete(i)
    end
  end
end
]]
