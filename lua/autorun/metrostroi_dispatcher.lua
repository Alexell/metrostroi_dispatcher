--------------------------- Metrostroi Dispatcher ---------------------------
-- Developer: Alexell | https://steamcommunity.com/profiles/76561198210303223
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
-----------------------------------------------------------------------------

if game.SinglePlayer() then return end
MDispatcher = MDispatcher or {}
if SERVER then
	AddCSLuaFile("metrostroi_dispatcher/client.lua")
	include("metrostroi_dispatcher/server.lua")
else
	include("metrostroi_dispatcher/client.lua")
end