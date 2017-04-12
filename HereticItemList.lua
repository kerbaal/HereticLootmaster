HereticItem = {}
HereticList = {}

HereticList.__index = HereticList
function HereticList:New(instanceID, master)
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

function HereticList:GetEntry(pos)
	if (pos < 1 or pos > #self.entries) then return nil end
	return self.entries[pos].itemLink, self.entries[pos].donator, self.entries[pos].winner, self.entries[pos].rollActionID
end

function HereticList:DeleteEntryAt(pos)
	table.remove(self.entries, pos)
end

function HereticList:DeleteAllEntries() 
	for i=0, #self.entries do  
		self.entries[i]=nil
	end
end

function HereticList:Validate()
	setmetatable(self, HereticList)
	if (self.instanceID == 0 or 
		self.master == "") then
		return false
	elseif not self.entries then
		self.entries = {}
	else 
		return true
	end
end

function HereticList:GetItemLinkByID(pos)
	return self.entries[pos].itemLink
end

function HereticList:GetSize()
	return #self.entries
end

function HereticList:GetEntryId(item, donator)
  for i=1, #self.entries do
    if (self.entries[i].itemLink == item and
        self.entries[i].donator == donator) then
      return i
    end
  end
  return nil
end

function HereticList:AddEntry(itemLink, donator)
	local newEntry = HereticItem:New(itemLink, donator)
	table.insert(self.entries, newEntry)
	return true
end