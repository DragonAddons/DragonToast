-------------------------------------------------------------------------------
-- ReputationListener_TBC.lua
-- TBC wrapper for the shared reputation listener implementation
--
-- Supported versions: TBC Anniversary
-------------------------------------------------------------------------------

local _, ns = ...

-------------------------------------------------------------------------------
-- Version guard: only run on TBC Anniversary
-------------------------------------------------------------------------------

local WOW_PROJECT_ID = WOW_PROJECT_ID
local WOW_PROJECT_BURNING_CRUSADE_CLASSIC = WOW_PROJECT_BURNING_CRUSADE_CLASSIC

if WOW_PROJECT_ID ~= WOW_PROJECT_BURNING_CRUSADE_CLASSIC then return end

if not ns.ReputationListenerShared or not ns.ReputationListenerShared.Create then return end

ns.ReputationListener = ns.ReputationListenerShared.Create()
