-------------------------------------------------------------------------------
-- HonorListener_Retail.lua
-- Retail wrapper for the shared honor listener implementation
--
-- Supported versions: Retail
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on Retail
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MAINLINE = WOW_PROJECT_MAINLINE

if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then return end

if not ns.HonorListenerShared or not ns.HonorListenerShared.Create then return end

local RETAIL_ALLIANCE_HONOR_ICON = 463450
local RETAIL_HORDE_HONOR_ICON = 463451

ns.HonorListener = ns.HonorListenerShared.Create({
    iconByFaction = {
        Alliance = RETAIL_ALLIANCE_HONOR_ICON,
        Horde = RETAIL_HORDE_HONOR_ICON,
    },
    iconFallback = RETAIL_ALLIANCE_HONOR_ICON,
})
