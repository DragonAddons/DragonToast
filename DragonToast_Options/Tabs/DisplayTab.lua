-------------------------------------------------------------------------------
-- DisplayTab.lua
-- Display settings tab: layout, toast size, content, padding, anchor
--
-- Supported versions: Retail, MoP Classic, TBC Anniversary, Cata, Classic
-------------------------------------------------------------------------------

local ADDON_NAME, ns = ...
local LC = ns.LayoutConstants

-------------------------------------------------------------------------------
-- Cached globals
-------------------------------------------------------------------------------

local math_abs = math.abs

-------------------------------------------------------------------------------
-- Localization
-------------------------------------------------------------------------------

local L = ns.L

-------------------------------------------------------------------------------
-- Namespace references
-------------------------------------------------------------------------------

local dtns

-------------------------------------------------------------------------------
-- Static dropdown values
-------------------------------------------------------------------------------

local GROW_DIRECTION_VALUES = {
    { value = "UP", text = L["DIRECTION_UP"] },
    { value = "DOWN", text = L["DIRECTION_DOWN"] },
}

local GOLD_FORMAT_VALUES = {
    { value = "icons", text = L["GOLD_FORMAT_ICONS"] },
    { value = "short", text = L["GOLD_FORMAT_SHORT"] },
    { value = "long", text = L["GOLD_FORMAT_LONG"] },
}

-------------------------------------------------------------------------------
-- Section builders
-------------------------------------------------------------------------------

local function CreateLayoutSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    local header = W.CreateHeader(parent, L["HEADER_LAYOUT"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local maxToasts = W.CreateSlider(parent, {
        label = L["MAX_TOASTS"],
        tooltip = L["TOOLTIP_MAX_TOASTS"],
        min = 1, max = 15, step = 1,
        get = function() return db.profile.display.maxToasts end,
        set = function(value) db.profile.display.maxToasts = value end,
    })
    LC.AnchorWidget(maxToasts, parent, yOffset)
    yOffset = yOffset - maxToasts:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local growDirection = W.CreateDropdown(parent, {
        label = L["GROW_DIRECTION"],
        tooltip = L["TOOLTIP_GROW_DIRECTION"],
        values = GROW_DIRECTION_VALUES,
        get = function() return db.profile.display.growDirection end,
        set = function(value)
            db.profile.display.growDirection = value
            dtns.ToastManager:UpdatePositions()
        end,
    })
    LC.AnchorWidget(growDirection, parent, yOffset)
    yOffset = yOffset - growDirection:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local spacing = W.CreateSlider(parent, {
        label = L["SPACING"],
        tooltip = L["TOOLTIP_SPACING"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.spacing end,
        set = function(value)
            db.profile.display.spacing = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(spacing, parent, yOffset)
    yOffset = yOffset - spacing:GetHeight()

    return yOffset
end

local function CreateSizeSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_TOAST_SIZE"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local toastWidth = W.CreateSlider(parent, {
        label = L["TOAST_WIDTH"],
        tooltip = L["TOOLTIP_TOAST_WIDTH"],
        min = 200, max = 600, step = 10,
        get = function() return db.profile.display.toastWidth end,
        set = function(value)
            db.profile.display.toastWidth = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(toastWidth, parent, yOffset)
    yOffset = yOffset - toastWidth:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local toastHeight = W.CreateSlider(parent, {
        label = L["TOAST_HEIGHT"],
        tooltip = L["TOOLTIP_TOAST_HEIGHT"],
        min = 32, max = 80, step = 2,
        get = function() return db.profile.display.toastHeight end,
        set = function(value)
            db.profile.display.toastHeight = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(toastHeight, parent, yOffset)
    yOffset = yOffset - toastHeight:GetHeight()

    return yOffset
end

local function CreateContentSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_CONTENT"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local showIcon = W.CreateToggle(parent, {
        label = L["SHOW_ICON"],
        tooltip = L["TOOLTIP_SHOW_ICON"],
        get = function() return db.profile.display.showIcon end,
        set = function(value)
            db.profile.display.showIcon = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(showIcon, parent, yOffset)
    yOffset = yOffset - showIcon:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showItemLevel = W.CreateToggle(parent, {
        label = L["SHOW_ITEM_LEVEL"],
        tooltip = L["TOOLTIP_SHOW_ITEM_LEVEL"],
        get = function() return db.profile.display.showItemLevel end,
        set = function(value) db.profile.display.showItemLevel = value end,
    })
    LC.AnchorWidget(showItemLevel, parent, yOffset)
    yOffset = yOffset - showItemLevel:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showItemType = W.CreateToggle(parent, {
        label = L["SHOW_ITEM_TYPE"],
        tooltip = L["TOOLTIP_SHOW_ITEM_TYPE"],
        get = function() return db.profile.display.showItemType end,
        set = function(value) db.profile.display.showItemType = value end,
    })
    LC.AnchorWidget(showItemType, parent, yOffset)
    yOffset = yOffset - showItemType:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showQuantity = W.CreateToggle(parent, {
        label = L["SHOW_QUANTITY"],
        tooltip = L["TOOLTIP_SHOW_QUANTITY"],
        get = function() return db.profile.display.showQuantity end,
        set = function(value) db.profile.display.showQuantity = value end,
    })
    LC.AnchorWidget(showQuantity, parent, yOffset)
    yOffset = yOffset - showQuantity:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local showLooter = W.CreateToggle(parent, {
        label = L["SHOW_LOOTER"],
        tooltip = L["TOOLTIP_SHOW_LOOTER"],
        get = function() return db.profile.display.showLooter end,
        set = function(value) db.profile.display.showLooter = value end,
    })
    LC.AnchorWidget(showLooter, parent, yOffset)
    yOffset = yOffset - showLooter:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local goldFormat = W.CreateDropdown(parent, {
        label = L["GOLD_FORMAT"],
        tooltip = L["TOOLTIP_GOLD_FORMAT"],
        values = GOLD_FORMAT_VALUES,
        get = function() return db.profile.display.goldFormat end,
        set = function(value) db.profile.display.goldFormat = value end,
    })
    LC.AnchorWidget(goldFormat, parent, yOffset)
    yOffset = yOffset - goldFormat:GetHeight()

    return yOffset
end

local function CreatePaddingSection(parent, yOffset)
    local W = ns.Widgets
    local db = dtns.Addon.db

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_PADDING"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local vertPadding = W.CreateSlider(parent, {
        label = L["VERTICAL_PADDING"],
        tooltip = L["TOOLTIP_VERTICAL_PADDING"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingV end,
        set = function(value)
            db.profile.display.textPaddingV = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(vertPadding, parent, yOffset)
    yOffset = yOffset - vertPadding:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local horzPadding = W.CreateSlider(parent, {
        label = L["HORIZONTAL_PADDING"],
        tooltip = L["TOOLTIP_HORIZONTAL_PADDING"],
        min = 0, max = 20, step = 1,
        get = function() return db.profile.display.textPaddingH end,
        set = function(value)
            db.profile.display.textPaddingH = value
            dtns.ToastManager:UpdateLayout()
        end,
    })
    LC.AnchorWidget(horzPadding, parent, yOffset)
    yOffset = yOffset - horzPadding:GetHeight()

    return yOffset
end

local function CreateAnchorSection(parent, yOffset)
    local W = ns.Widgets

    yOffset = yOffset - LC.SPACING_BETWEEN_SECTIONS

    local header = W.CreateHeader(parent, L["HEADER_ANCHOR"])
    LC.AnchorWidget(header, parent, yOffset)
    yOffset = yOffset - header:GetHeight() - LC.SPACING_AFTER_HEADER

    local unlockAnchor = W.CreateToggle(parent, {
        label = L["UNLOCK_ANCHOR"],
        tooltip = L["TOOLTIP_UNLOCK_ANCHOR"],
        get = function()
            local anchor = _G["DragonToastAnchor"]
            return anchor and anchor.overlay and anchor.overlay:IsShown() or false
        end,
        set = function() dtns.ToastManager:ToggleLock() end,
    })
    LC.AnchorWidget(unlockAnchor, parent, yOffset)
    yOffset = yOffset - unlockAnchor:GetHeight() - LC.SPACING_BETWEEN_WIDGETS

    local resetButton = W.CreateButton(parent, {
        text = L["RESET_POSITION"],
        tooltip = L["TOOLTIP_RESET_POSITION"],
        onClick = function()
            dtns.ToastManager:SetAnchor("RIGHT", -20, 0)
            dtns.Print(L["ANCHOR_POSITION_RESET"])
        end,
    })
    LC.AnchorWidget(resetButton, parent, yOffset)
    yOffset = yOffset - resetButton:GetHeight()

    return yOffset
end

-------------------------------------------------------------------------------
-- Build the Display tab content
-------------------------------------------------------------------------------

local function CreateContent(parent)
    dtns = ns.dtns
    local yOffset = LC.PADDING_TOP

    yOffset = CreateLayoutSection(parent, yOffset)
    yOffset = CreateSizeSection(parent, yOffset)
    yOffset = CreateContentSection(parent, yOffset)
    yOffset = CreatePaddingSection(parent, yOffset)
    yOffset = CreateAnchorSection(parent, yOffset)

    parent:SetHeight(math_abs(yOffset) + LC.PADDING_BOTTOM)
end

-------------------------------------------------------------------------------
-- Register tab
-------------------------------------------------------------------------------

ns.Tabs = ns.Tabs or {}
ns.Tabs[#ns.Tabs + 1] = {
    id = "display",
    label = L["TAB_DISPLAY"],
    order = 3,
    createFunc = CreateContent,
}
