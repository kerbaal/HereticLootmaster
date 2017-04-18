local ADDON, Addon = ...

local Util = Addon.Util


local PagedView = {};
PagedView.__index = PagedView;
function PagedView:New(itemsPerPage)
   local self = {};
   setmetatable(self, PagedView);

   self.itemsPerPage = itemsPerPage
   self.currentPage = 1
   self.maxPages = 1
   return self;
end

function PagedView:Next()
  self.currentPage = max(1, self.currentPage - 1)
end

function PagedView:Prev()
  self.currentPage = min(self.maxPages, self.currentPage + 1)
end

function PagedView:IdToIndex(id)
  return (self.currentPage - 1) * self.itemsPerPage + id
end

function PagedView:SetNumberOfItems(count)
  self.maxPages = max(ceil(count / self.itemsPerPage), 1);
end

function PagedView:GetNavigationStatus()
  return (self.currentPage ~= 1), (self.currentPage ~= self.maxPages), self.currentPage, self.maxPages
end


function HereticNavigationFrame_OnLoad()
end

local function HereticNavigationFrame_Update(self)
  self.pagination:SetNumberOfItems(Addon.itemList:Size())
  local prev, next, currentPage, maxPages = self.pagination:GetNavigationStatus()
  self.navigation.prevButton:SetEnabled(prev);
  self.navigation.nextButton:SetEnabled(next);
  self.navigation.pageText:SetFormattedText("%d / %d", currentPage, maxPages);
end

function HereticListView_Update(self)
  HereticNavigationFrame_Update(self)

  for i,frame in pairs(self.lootFrames) do
    local itemIndex = self.pagination:IdToIndex(i);
    HereticLootFrame_SetLoot(frame, itemIndex, Addon.itemList:GetEntry(itemIndex))
    HereticLootFrame_Update(frame)
  end
end

function HereticPrevPageButton_OnClick(self)
  local frame = self:GetParent():GetParent()
  frame.pagination:Next()
  HereticListView_Update(frame)
end

function HereticNextPageButton_OnClick(self)
  local frame = self:GetParent():GetParent()
  frame.pagination:Prev()
  HereticListView_Update(frame)
end

function HereticListView_OnLoad(self)
  self.pagination = PagedView:New(#self.lootFrames)
  for i,frame in pairs(self.lootFrames) do
    frame.HereticOnClick = LootItem_OnClick
  end
end
