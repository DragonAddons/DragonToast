-------------------------------------------------------------------------------
-- CurrencyListener_Retail.lua
-- Retail wrapper for the shared currency listener implementation
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

if not ns.CurrencyListenerShared or not ns.CurrencyListenerShared.Create then return end

ns.CurrencyListener = ns.CurrencyListenerShared.Create()
