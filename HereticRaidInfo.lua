local ADDON, Addon = ...

local Util = Addon.Util

HereticRaidInfo = {}

function HereticRaidInfo:Initialize()
  HereticRaidInfo.unitids = {}
  HereticRaidInfo.newPlayers = {}
  HereticRaidInfo.stale = "stale"
  HereticRaidInfo.timer = nil
  HereticRaidInfo.classCache = {}
end

local function RaidInfoUpdate()
  Util.dbgprint("Reindexing Raid through timer...")
  HereticRaidInfo:Update()
end

function HereticRaidInfo:ProvideReindexing()
  if HereticRaidInfo.timer then HereticRaidInfo.timer:Cancel() end
  HereticRaidInfo.timer = nil
end

function HereticRaidInfo:RequestReindexing()
  if (HereticRaidInfo.timer == nil) then
    Util.dbgprint("Request Reindexing...")
    HereticRaidInfo.timer = C_Timer.NewTimer(2, RaidInfoUpdate)
  end
end

function HereticRaidInfo:markStale()
  for i,v in pairs(HereticRaidInfo.unitids) do
    HereticRaidInfo.unitids[i] = HereticRaidInfo.stale
  end
end

function HereticRaidInfo:clearStale()
  for i,v in pairs(HereticRaidInfo.unitids) do
    if (v == HereticRaidInfo.stale ) then
      HereticRaidInfo.unitids[i] = nil
    end
  end
end

function HereticRaidInfo:recordByUnitId(unitId)
  local fullName = Util.GetFullUnitName(unitId)
  if (not fullName) then return end
  local first, _ = Util.DecomposeName(fullName)
  if (first == UNKNOWNOBJECT) then
     HereticRaidInfo:RequestReindexing()
     return
   end
  if HereticRaidInfo.unitids[fullName] == nil then
    table.insert(HereticRaidInfo.newPlayers, fullName)
  end
  HereticRaidInfo.unitids[fullName] = unitId
  if HereticRaidInfo.classCache[fullName] == nil then
    table.insert(HereticRaidInfo.classCache, fullName)
  end
  local class, classFileName = UnitClass(unitId)
  HereticRaidInfo.classCache[fullName] = {class, classFileName}
end

function HereticRaidInfo:GetPlayerClassColor(fullName)
  local cacheEntry = HereticRaidInfo.classCache[fullName]
  local classFileName
  if not cacheEntry then
    local name = Util.ShortenFullName(fullName)
    _, classFileName = UnitClass(name)
  else
    classFileName = cacheEntry[2]
  end
  local color = RAID_CLASS_COLORS[classFileName]
  return (color and color.colorStr)
end

function HereticRaidInfo:GetColoredPlayerName(fullName)
  local name = Util.ShortenFullName(fullName)
  local color = HereticRaidInfo:GetPlayerClassColor(fullName)
  if color then
    return "|c" .. color  .. name .. "|r"
  else
    return name
  end
end

function HereticRaidInfo:printNewPlayers(unitId)
  local players = ""
  for i,v in pairs(HereticRaidInfo.newPlayers) do
    players = players .. " " .. v
  end
  Util.dbgprint ("New players (" .. table.getn(HereticRaidInfo.newPlayers) .. "):" .. players)
end

function HereticRaidInfo:GetNewPlayers()
  return HereticRaidInfo.newPlayers
end

function HereticRaidInfo:Update()
  HereticRaidInfo:ProvideReindexing()

  HereticRaidInfo:markStale()
  wipe(HereticRaidInfo.newPlayers)
  HereticRaidInfo.unitids [Util.GetFullUnitName("player")] = "player";
  local numMembers = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
  if (numMembers > 0) then
    local prefix = "raid"
    if ( not IsInRaid(LE_PARTY_CATEGORY_HOME) ) then
      prefix = "party"
      -- Party ids don't include the player, hence decrement.
      numMembers = numMembers - 1
    end

    for index = 1, numMembers do
      local unitId = prefix .. index
      HereticRaidInfo:recordByUnitId(unitId)
    end
  end
  HereticRaidInfo:printNewPlayers()
  HereticRaidInfo:clearStale()
end

function HereticRaidInfo:GetUnitId(name)
  local id = HereticRaidInfo.unitids[name]
  if id then return id end

  local realm = GetRealmName():gsub("%s+", "")
  return HereticRaidInfo.unitids[name .. "-" .. realm]
end

function HereticRaidInfo:DebugPrint()
  for index,value in pairs(HereticRaidInfo.unitids) do Util.dbgprint(index," ",value) end
end
