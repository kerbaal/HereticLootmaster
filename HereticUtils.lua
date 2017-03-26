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
  return Util.MergeFullName(name, realm)
end

function Util.GetItemIdFromLink(itemLink)
  local _, _, color, Ltype, itemId, Enchant, Gem1, Gem2, Gem3, Gem4,
  Suffix, Unique, LinkLvl, reforging, Name =
  string.find(itemLink,"|?c?f?f?(%x*)|?H?([^:]*):?(%d+):?(%d*):?(%d*):?(%d*):?(%d*):?(%d*):?(%-?%d*):?(%-?%d*):?(%d*):?(%d*)|?h?%[?([^%[%]]*)%]?|?h?|?r?")
  return itemId
end

function Util.pack(...)
  return {n = select("#", ...), ...}
end
function Util.unpack(t)
  return unpack(t, 1, t.n)
end

Addon.Util = Util
