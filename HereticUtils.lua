local ADDON, Addon = ...

local Util = {}

function Util.dbgprint(...)
  if KetzerischerLootverteilerData.debug then
    print(...)
  end
end

function FormatLink(linkType, linkDisplayText, ...)
  local linkFormatTable = { ("|H%s"):format(linkType), ... };
  return table.concat(linkFormatTable, ":") .. ("|h%s|h"):format(linkDisplayText);
end

function Util.GetPlayerLink(characterName, linkDisplayText, lineID, chatType, chatTarget)
  -- Use simplified link if possible.
  if lineID or chatType or chatTarget then
    return FormatLink("player", linkDisplayText, characterName, lineID or 0, chatType or 0, chatTarget or "");
  else
    return FormatLink("player", linkDisplayText, characterName);
  end
end

function Util.DecomposeName(name)
  return name:match("^([^-]*)-?(.*)$")
end

function Util.MergeFullName(name, realm)
  if (realm == nil or realm == "") then
    realm = GetRealmName():gsub("%s+", "")
  end
  return name .. "-" .. realm
end

function Util.CompleteUnitName(unitName)
  local name, realm = Util.DecomposeName(unitName)
  return Util.MergeFullName(name, realm)
end

function Util.GetFullUnitName(unitId)
  local name, realm = UnitName(unitId)
  if (not name) then return nil end
  return Util.MergeFullName(name, realm)
end

function Util.ShortenFullName(fullName)
  local name, realm = Util.DecomposeName(fullName)
  if (realm == GetRealmName():gsub("%s+", "")) then
    return name
  end
  return fullName
end

function Util.GetItemIdFromLink(itemLink)
  local _, _, color, Ltype, itemId, Enchant, Gem1, Gem2, Gem3, Gem4,
  Suffix, Unique, LinkLvl, reforging, Name =
  string.find(itemLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
  return itemId
end

function Util.GetColoredPlayerName(fullPlayerName)
  local name = Util.ShortenFullName(fullPlayerName)
  local class, classFileName = UnitClass(name)
  local color = RAID_CLASS_COLORS[classFileName]
  if not color then return name end
  return "|c" .. color.colorStr  .. name .. "|r"
end

function Util.pack(...)
  return {n = select("#", ...), ...}
end

function Util.unpack(t)
  return unpack(t, 1, t.n)
end

function Util.toRange(self, n)
  if n < 1 then
    return 1
  elseif n > #self then
    return #self
  end
  return n
end

function Util.table_contains(t, x)
  for i,v in pairs(t) do
    if (x == v) then
      return true
    end
  end
  return false
end

local function colorCount(hex, count)
  local v = count or 0
  if v == 0 then hex = "00000000" end
  return "|c" .. hex .. v .. "|r"
end

function Util.formatLootCount(count)
  local str = ""
  local sep = ""
  for i,cat in pairs(HereticRoll.GetCategories()) do
    local _, _, _, hex = HereticRoll.ColorForMax(cat)
    str = colorCount(hex, count[i]) .. sep .. str
    sep = " "
  end
  local _, _, _, hex = HereticRoll.ColorForCategory(0)
  str = str .. sep .. colorCount(hex, count[0])
  return str
end

Addon.Util = Util
