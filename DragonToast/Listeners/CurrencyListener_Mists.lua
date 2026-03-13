-------------------------------------------------------------------------------
-- CurrencyListener_Mists.lua
-- MoP wrapper for the shared currency listener implementation
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

if not ns.CurrencyListenerShared or not ns.CurrencyListenerShared.Create then return end

ns.CurrencyListener = ns.CurrencyListenerShared.Create()
