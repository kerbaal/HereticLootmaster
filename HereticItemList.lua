HereticItem = {}
HereticList = {}

HereticList.__index = HereticList
function HereticList:New(instanceID, master, entries)
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
    isCurrent = true
  }
  setmetatable(obj, self)
  return obj
end

function HereticList:GetEntry(pos)
  if (pos < 1 or pos > #self.entries) then return nil end
  return self.entries[pos]
end

function HereticList:DeleteEntryAt(pos)
  table.remove(self.entries, pos)
end

function HereticList:DeleteAllEntries()
  for i=0, #self.entries do
    self.entries[i]=nil
  end
end

function HereticItem:Validate()
  if (not self.itemLink or not self.donator or not self.sender) then
    return false
  end
  if (self.winner and not HereticRoll.Validate(self.winner)) then
    return false
  end
  setmetatable(self, HereticItem)
  return true
end

function HereticList:Validate()
  if (not self.instanceID or self.instanceID == 0 or
      not self.master or self.master == "" or
      not self.entries) then
    return false
  end
  setmetatable(self, HereticList)
  for i=#self.entries,1,-1 do
    if not HereticItem.Validate(self.entries[i]) then
      self:DeleteEntryAt(i)
    end
  end
  return true
end

function HereticList:GetItemLinkByID(pos)
  return self.entries[pos].itemLink
end

function HereticList:Size()
  return #self.entries
end

function HereticList:AddEntry(entry)
  table.insert(self.entries, entry)
end


function HereticList:GetEntryId(item, donator, sender)
  for i=1, #self.entries do
    if (self.entries[i].itemLink == item and
        self.entries[i].donator == donator and
        self.entries[i].sender == sender) then
      return i
    end
  end
  return nil
end
