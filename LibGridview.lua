

local addonName, addon = ...;

--[[

*** note, at the moment this gridview widget will create a frame for EACH item added, it is therefore not suited to large numbers of items ***

GridView

create a gridview widget that will scale with a resizable UI,

frames added can use the following methods

:SetDataBinding, this method is called when an item is added to the gridview

:ResetDataBinding, this method is called before SetDataBinding if you want to tidy up any frame elements

:UpdateLayout, this method is called last and can be used to update the size and layout of elements within the frame

specifically of note is that :UpdateLayout will be called on each frame when calling :UpdateLayout on the gridview itself


==========================================================================================================================
example snippet


========
foo.xml
========
-- create a template for gridview items, this is best (and mostly only) done with xml
-- add the mixin attribute to your template
<Ui>
    <Frame name="MyGridviewItemTemplate" mixin="MyGridviewItemMixin" virtual="true">
        <Layers>
            <Layer level="OVERLAY">
                <FontString parentKey="title"/>
            </Layer>
        </Layers>
    </Frame>
</Ui>


========
foo.lua
========
-- in a lua file write the template mixin and add the method to set binding
MyGridviewItemMixin = {}
function MyGridviewItemMixin:SetDataBinding(binding)
    self.title:SetText(binding.title)
end


========
main.lua
========
local name, addon = ...;

-- get a ref to the lib
local LibGridview = addon.LibGridview;

-- create the gridview
local gridview = LibGridview:CreateGridview(parent)

-- init the frame pool passing in the frame type and template name
gridview:InitFramePool("FRAME", "GridviewItemTemplate")

-- set the min/max item sizes (this is isnt exactly perfect science as the gridview will size items to best fit the full width)
gridview:SetMinMaxSize(300, 400)

-- create an item to add
local item = {
    title = "foo",
}

-- add the item to the gridview
gridview:Insert(item)
==========================================================================================================================


]]







GridviewMixin = {}
function GridviewMixin:OnLoad()
    self.data = {}
    self.frames = {}
    self.itemMinWidth = 0
    self.itemMaxWidth = 0
    self.itemSize = 0
    self.colIndex = 0
    self.rowIndex = 0
    self.numItemsPerRow = 1
end

---set the frame pool and a template to use
---@param type string the frame type
---@param template string the template name
function GridviewMixin:InitFramePool(type, template)
    self.framePool = CreateFramePool(type, self.scrollChild, template);
end

---set the size for the gridview items, note this doesnt provide an accurate size but allows the gridview to work out how many items per row to display
---@param min number
---@param max number
function GridviewMixin:SetMinMaxSize(min, max)
    self.itemMinWidth = min;
    self.itemMaxWidth = max;
end

---insert an item, each item should have a data model (table)
---@param info table the data model for the item
function GridviewMixin:Insert(info)
    table.insert(self.data, info)

    local f = self.framePool:Acquire()
    f:SetID(#self.data)

    if f.SetDataBinding then
        f:SetDataBinding(self.data[#self.data])
    end

    f:Show()
    table.insert(self.frames, f)

    self:UpdateLayout()
end

---remove an item
---@param frame any the frame to be removed
function GridviewMixin:RemoveFrame(frame)
    local key;
    for k, f in ipairs(self.frames) do
        if f:GetID() == frame:GetID() then
            if f.ResetDataBinding then
                f:ResetDataBinding()
            end
            key = k;
            self.framePool:Release(f)
        end
    end
    if type(key) == "number" then
        table.remove(self.frames, key)
    end
    self:UpdateLayout()
end

function GridviewMixin:InsertTable(tbl)

end

---remove all items
function GridviewMixin:Flush()
    self.data = {}
    for k, f in ipairs(self.frames) do
        if f.ResetDataBinding then
            f:ResetDataBinding()
        end
        f:Hide()
    end
    self.frames = {}
    self.framePool:ReleaseAll()
end

---this function will work out how many items per row should be displayed based on the min/max sizes
function GridviewMixin:GetItemSize()
    local width = self:GetWidth()

    local numItemsPerRowMinWidth = width / self.itemMinWidth;
    local numItemsPerRowMaxWidth = width / self.itemMaxWidth;

    self.numItemsPerRow =  math.ceil(((numItemsPerRowMinWidth + numItemsPerRowMaxWidth) / 2))

    self.itemSize = (width / self.numItemsPerRow)

    --[[
        this next bit was a first attempt to fix the min/max sizes
        however having a fixed size means the items wont always 
        adjust to fill each row, so leaving the older math in place
    ]]

    --self.numItemsPerRow =  math.ceil(width / self.itemMinWidth)

    -- if self.itemSize < self.itemMinWidth then
    --     self.itemSize = (width / (self.numItemsPerRow - 1))
    -- end
    -- if self.itemSize > self.itemMaxWidth then
    --     self.itemSize = self.itemMaxWidth
    --     self.numItemsPerRow =  math.floor(width / self.itemMaxWidth)
    -- end
end

---update the gridview layout, use this in an OnUpdate if your UI size changes
function GridviewMixin:UpdateLayout()
    self:GetItemSize()

    self.colIndex = 0;
    self.rowIndex = 0;

    self.scrollChild:SetHeight(self:GetHeight())
    self.scrollChild:SetWidth(self:GetWidth())

    for k, f in ipairs(self.frames) do
        f:ClearAllPoints()
        f:SetSize(self.itemSize, self.itemSize)
        f:SetPoint("TOPLEFT", self.itemSize * self.colIndex, -(self.itemSize * self.rowIndex))
        if k < (self.numItemsPerRow * (self.rowIndex + 1)) then
            self.colIndex = self.colIndex + 1
        else
            self.colIndex = 0
            self.rowIndex = self.rowIndex + 1
        end
        if f.UpdateLayout then
            f:UpdateLayout()
        end
        f:Show()
    end
end

---return the gridviews frames
---@return table frames a table of frames used by the gridview
function GridviewMixin:GetFrames()
    return self.frames;
end



local LibGridview = {
    gridviewIter = 0,
}

function LibGridview:CreateGridview(parent)

    self.gridviewIter = self.gridviewIter + 1;
    
    local f = CreateFrame("ScrollFrame", string.format("%s_Gridview_%s", addonName, self.gridviewIter), parent, "UIPanelScrollFrameTemplate")
    f:EnableMouse(true)

    f.scrollChild = CreateFrame("FRAME", nil, f)
    f.scrollChild:EnableMouse(true)
    f.scrollChild:SetPoint("LEFT", 0, 0)
    f.scrollChild:SetPoint("RIGHT", 0, 0)

    f:SetScrollChild(f.scrollChild)

    Mixin(f, GridviewMixin)
    return f;

end

addon.LibGridview = LibGridview;