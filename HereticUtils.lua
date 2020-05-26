local ADDON, Addon = ...

local Util = {}

function Util.dbgprint(...)
  if HereticLootmasterData.debug then
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

local CLASS_TO_ARMOR_TYPE = {
  [0] = {}, -- None
  [1] = {[4] = true}, -- Warrior
  [2] = {[4] = true}, -- Paladin
  [3] = {[3] = true}, -- Hunter
  [4] = {[2] = true}, -- Rogue
  [5] = {[1] = true}, -- Priest
  [6] = {[4] = true}, -- DeathKnight
  [7] = {[3] = true}, -- Shaman
  [8] = {[1] = true}, -- Mage
  [9] = {[1] = true}, -- Warlock
  [10] = {[2] = true}, -- Monk
  [11] = {[2] = true}, -- Druid
  [12] = {[2] = true}, -- Demon Hunter
}

function Util.CanWearArmorType(fullPlayerName, itemClassID, itemSubClassID)
  local name = Util.ShortenFullName(fullPlayerName)
  local class, classFileName, classID = UnitClass(name)
  if (not classID or itemClassID ~= 4) then
    return true
  end
  return CLASS_TO_ARMOR_TYPE[classID][itemSubClassID] or false
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

function Util.formatLootCount(count, skip, verbose)
  local str = ""
  local sep = ""
  for i,cat in pairs(HereticRoll.GetCategories()) do
    if not skip or (count[i] and count[i] > 0) then
      local _, _, _, hex = HereticRoll.ColorForMax(cat)
      if verbose then
        str = colorCount(hex, HereticRoll.GetCategoryName(i)) .. sep .. str
        sep = " "
      end
      str = colorCount(hex, count[i]) .. sep .. str
      sep = " "
    end
  end
  local _, _, _, hex = HereticRoll.ColorForCategory(0)
  if not skip or (count[0] and count[0] > 0) then
    if verbose then
      str = HereticRoll.GetCategoryName(i) .. sep .. str
      sep = " "
    end
    str = str .. sep .. colorCount(hex, count[0])
  end
  return str
end

function Util.formatLootCountMono(count, skip, verbose)
  local str = ""
  local sep = ""
  for i,cat in pairs(HereticRoll.GetCategories()) do
    if not skip or (count[i] and count[i] > 0) then
      if verbose then
        str = HereticRoll.GetCategoryName(i) .. sep .. str
        sep = " "
      end
      str = count[i] .. sep .. str
      sep = " "
    end
  end
  if not skip or (count[0] and count[0] > 0) then
    if verbose then
      str = HereticRoll.GetCategoryName(i) .. sep .. str
      sep = " "
    end
    str = str .. sep .. count[0]
  end
  return str
end

local GetMoreItemInfo
do
  local tooltipName = "PhanxScanningTooltip" .. random(100000, 10000000)

  local tooltip = CreateFrame("GameTooltip", tooltipName, UIParent, "GameTooltipTemplate")
  tooltip:SetOwner(UIParent, "ANCHOR_NONE")

  local textures = {}
  for i = 1, 10 do
    textures[i] = _G[tooltipName .. "Texture" .. i]
  end

  local cache = setmetatable({}, { __index = function(t, link)
    tooltip:SetHyperlink(link)
    local info = {tex = {}, isCorrupted = false, hasSocket = false}
    for i = 1, 10 do
      if textures[i]:IsShown() then
        info.tex[i] = textures[i]:GetTexture()
      end
    end

    info.hasSocket = info.tex[1];

    local regions = {tooltip:GetRegions()};
    for i, region in ipairs(regions) do
      if region and region:GetObjectType() == "FontString" then
        local text = region:GetText()
        if text and text:find("%d Verderbnis") then
          info.isCorrupted = text;
          --print("" .. i .. name .. " " .. text)
        end
      end
    end

    t[link] = info
    return info
  end })

  function GetMoreItemInfo(link)
    if not link then return nil end
    return cache[link]
  end
end

Util.GetMoreItemInfo = GetMoreItemInfo;

Addon.Util = Util
