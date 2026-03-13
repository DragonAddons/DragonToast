-------------------------------------------------------------------------------
-- HonorListener_Mists.lua
-- MoP wrapper for the shared honor listener implementation
--
-- Supported versions: MoP Classic
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on MoP Classic
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_MISTS_CLASSIC = WOW_PROJECT_MISTS_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_MISTS_CLASSIC then return end

if not ns.HonorListenerShared or not ns.HonorListenerShared.Create then return end

local MISTS_ALLIANCE_HONOR_ICON = 463450
local MISTS_HORDE_HONOR_ICON = 463451

ns.HonorListener = ns.HonorListenerShared.Create({
    iconByFaction = {
        Alliance = MISTS_ALLIANCE_HONOR_ICON,
        Horde = MISTS_HORDE_HONOR_ICON,
    },
    iconFallback = MISTS_ALLIANCE_HONOR_ICON,
})
