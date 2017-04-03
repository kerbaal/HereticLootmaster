local HereticItem = {}
local HereticItemList = {}

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
	itemLink = itemLink,
	donator = donator,
	winner = winner,
	rollActionID = rollActionID,
	}
	setmetatable(obj, self)
	return obj
end

function HereticItem:GetItemLink()
	return self.itemLink
end

function HereticItem:Get()
	return self.itemLink, self.donator, self.winner, self.rollActionID
end

function HereticItemList:DeleteEntry(obj)
	for i = 1, #self.entries do
		if self.entries[i] == obj then
			table.remove(self.entries, i)
			break
		end
	end
end

function HereticItemList:GetEntryObject(itemLink, donator)
	for i=1, #self.entries do
		if (self.entries[i].itemLink == itemLink and
			self.entries[i].donator == donator) then
			return self.entries[i]
		end
	end
	return nil
end

function HereticItemList:DeleteEntryTest()
	testList = HereticItemList:New(8888889, "Nagisa-DieAldor")
	for i = 1, 5 do
		newEntry = HereticItem:New("Link"..i*i, "Donator"..i, {"Name"..i,i,i+i},"RollID"..i)
		table.insert(testList.entries, newEntry)
	end
	for k,v in ipairs(testList.entries) do
		print(v.itemLink .. " posted by " .. v.donator .. " rolledID: " .. v.rollActionID)
	end
	testList:DeleteEntry(testList:GetEntryObject("Link16", "Donator4"))
	print("--- Entry4: Link16 posted by Donator4 rolledID: RollID4 should be removed ---")
	for k,v in ipairs(testList.entries) do
		print(v.itemLink .. " posted by " .. v.donator .. " rolledID: " .. v.rollActionID)
	end
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
	for i = 1, 5 do
		newObj = HereticItemList:New(10000+i, "Nagisa-DieAldor")
		for j = 1, 5 do
			newEntry = HereticItem:New("Link"..i*j, "Donator"..j, {"Name"..j,j,j+j},"RollID"..j)
			table.insert(newObj.entries, newEntry)
		end
		for k,v in ipairs(newObj.entries) do
		print(v.itemLink .. " posted by " .. v.donator .. " rolledID: " .. v.rollActionID)
		end
	end
	print(newEntry:GetItemLink())
	print(newEntry:Get())
end

--[[
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
