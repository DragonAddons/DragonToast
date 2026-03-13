-------------------------------------------------------------------------------
-- ReputationListener_Retail.lua
-- Retail wrapper for the shared reputation listener implementation
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

if not ns.ReputationListenerShared or not ns.ReputationListenerShared.Create then return end

ns.ReputationListener = ns.ReputationListenerShared.Create()
