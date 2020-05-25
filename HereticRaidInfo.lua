local ADDON, Addon = ...

local Util = Addon.Util

-- `HereticRaidInfo` implements a cache for player infos in raids. It's main
-- use is to provide class coloring for the addon. The class uses a timer
-- to continously index the players in the raid, which gets initialized in
-- `RequestReindexing`. HereticRaidInfo:Update iterates over all players in
-- the raid and records class information. The information may be persisted
-- via Serialize/Deserialize to a saved variable.

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
  local class, classFileName
  if not cacheEntry then
    local name = Util.ShortenFullName(fullName)
    class, classFileName = UnitClass(name)
    if class and classFileName then
      HereticRaidInfo.classCache[fullName] = {class, classFileName}
    end
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

function HereticRaidInfo:Serialize(obj)
  obj.HereticRaidInfo = {}
  obj.HereticRaidInfo.classCache = HereticRaidInfo.classCache
end

function HereticRaidInfo:Deserialize(obj)
  if not obj.HereticRaidInfo then return end
  if not obj.HereticRaidInfo.classCache then return end
  local cache = HereticRaidInfo.classCache
  for k,v in pairs(obj.HereticRaidInfo.classCache) do
    if (#v == 2) then
      cache[k] = v
    end
  end
end
