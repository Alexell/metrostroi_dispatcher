--------------------------- Metrostroi Dispatcher --------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------

--if game.SinglePlayer() then return end
MDispatcher = MDispatcher or {}
if SERVER then
	AddCSLuaFile("metrostroi_dispatcher/client_main.lua")
	AddCSLuaFile("metrostroi_dispatcher/client_schedule.lua")
	AddCSLuaFile("metrostroi_dispatcher/client_gui.lua")
	include("metrostroi_dispatcher/server.lua")
	include("metrostroi_dispatcher/def_controlrooms.lua")
else
	include("metrostroi_dispatcher/client_main.lua")
	include("metrostroi_dispatcher/client_schedule.lua")
	include("metrostroi_dispatcher/client_gui.lua")
end