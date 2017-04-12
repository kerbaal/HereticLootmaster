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
function HereticItem:New(itemLink, donator, sender, winner, rollActionID)
  local obj = {
    itemLink = itemLink,
    donator = donator,
    sender = sender,
    winner = winner,
    rollActionID = rollActionID,
  }
  setmetatable(obj, self)
  return obj
end

function HereticItemList:GetEntry(pos)
  if (pos < 1 or pos > #self.entries) then return nil end
  return self.entries[pos]
end

function HereticItemList:DeleteEntryAt(pos)
  table.remove(self.entries, pos)
end

function HereticItemList:DeleteAllEntries()
  for i=0, #self.entries do
    self.entries[i]=nil
  end
end

function HereticItem:Validate()
  if (not self.itemLink or not self.donator) then
    return false
  end
  if (self.winner and not HereticRoll.Validate(self.winner)) then
    return false
  end
  setmetatable(self, HereticItem)
  return true
end

function HereticItemList:Validate()
  if (not self.instanceID or self.instanceID == 0 or
      not self.master or self.master == "" or
      not self.entries) then
    return false
  end
  setmetatable(self, HereticItemList)
  for i=#self.entries,1,-1 do
    if not HereticItem.Validate(self.entries[i]) then
      self:DeleteEntryAt(i)
    end
  end
  return true
end

function HereticItemList:GetItemLinkByID(pos)
  return self.entries[pos].itemLink
end

function HereticItemList:Size()
  return #self.entries
end

function HereticItemList:AddEntry(entry)
  table.insert(self.entries, entry)
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