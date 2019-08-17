local ADDON, Addon = ...

local Util = Addon.Util

HereticHistory = {
  histories = { HereticList:New("default") }
}

function HereticHistory:GetItemListForInstanceID(instanceName, instanceDifficultyID, instanceID)
  local match_i, match_history, noid_i, noid_history
  for i,history in ipairs(HereticHistory.histories) do
    if instanceID and history.instanceID == instanceID and
       history.difficultyID == instanceDifficultyID and
       history.instanceName == instanceName then
      match_i, match_history = i, history
    end
    if history.instanceID == nil and
       history.difficultyID == instanceDifficultyID and
       history.instanceName == instanceName then
      noid_i, noid_history = i, history
    end
  end
  if match_i and match_history then
    return match_i, match_history
  end
  if noid_i and noid_history then
    noid_history.instanceID = instanceID
    return noid_i, noid_history
  end
  return nil
end

function HereticHistory:GetCurrentInstance()
  local instanceName, instanceType, instanceDifficultyID, difficultyName, maxPlayers, playerDifficulty, isDynamicInstance, mapID, instanceGroupSize = GetInstanceInfo()
  if (instanceType == "raid" or instanceType == "party") then
    local instanceID = FindSavedInstanceID(instanceName, instanceDifficultyID)
    return instanceName, instanceID, difficultyName, instanceDifficultyID
  end
  return nil
end

function HereticHistory:GetItemListForCurrentInstance()
  local instanceName, instanceID, difficultyName, instanceDifficultyID = HereticHistory:GetCurrentInstance()
  instanceID = 0
  if instanceName then
    local _, history = HereticHistory:GetItemListForInstanceID(instanceName, instanceDifficultyID, instanceID)
    if history then return history end
    local newHistory = HereticList:New(instanceName, instanceDifficultyID, instanceID)
    table.insert(HereticHistory.histories, 2, newHistory)
    return newHistory
  end
  return HereticHistory.histories[1]
end

function HereticHistory:GetItemListByIndex(index)
  return HereticHistory.histories[index]
end

function HereticHistory:Deserialize(serialized_histories)
  wipe(HereticHistory.histories)
  for i, history in pairs(serialized_histories) do
    if HereticList.Validate(history) then
      table.insert(HereticHistory.histories, history)
      for i,entry in pairs(history.entries) do
        if entry.isCurrent then
          Addon.itemList:AddEntry(entry)
        end
      end
    end
  end
  if #HereticHistory.histories == 0 then
    HereticHistory.histories = { HereticList:New("default") }
  end
end

function HereticHistory:NumberOfItemLists()
  return #HereticHistory.histories
end

function HereticHistory:ComputeLootCount(lootCount)
  wipe(lootCount)
  for i,entry in pairs(Addon:GetActiveHistory().entries) do
    if (entry.winner) then
      local cat = entry.winner:GetCategory()
      local record = lootCount[entry.winner.name] or {}
      lootCount[entry.winner.name] = record
      record.name = entry.winner.name
      local count = record.count or {}
      record.count = count
      count[cat] = (count[cat] or 0) + 1
    end
    if (entry.donator) then
      local record = lootCount[entry.donator] or {}
      lootCount[entry.donator] = record
      record.name = entry.donator
      local donations = record.donations or 0
      record.donations = donations + 1
    end
  end
end
