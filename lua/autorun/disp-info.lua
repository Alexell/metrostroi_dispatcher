-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexell/

if game.SinglePlayer() then return end
DispInfo = DispInfo or {}
if SERVER then
	AddCSLuaFile("disp-info/client.lua")
	include("disp-info/server.lua")
else
	include("disp-info/client.lua")
end