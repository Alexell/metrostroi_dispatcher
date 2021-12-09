--------------------- Disp-Info (addon for Metrostroi) ----------------------
-- Developer: Alexell | https://steamcommunity.com/profiles/76561198210303223
-- License: MIT
-- Source code: https://github.com/Alexell/disp-info
-----------------------------------------------------------------------------

if game.SinglePlayer() then return end
DispInfo = DispInfo or {}
if SERVER then
	AddCSLuaFile("disp-info/client.lua")
	include("disp-info/server.lua")
else
	include("disp-info/client.lua")
end