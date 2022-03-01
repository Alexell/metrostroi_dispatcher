------------------------ Metrostroi Dispatcher -----------------------
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
	AddCSLuaFile("metrostroi_dispatcher/client_dscp.lua")
	AddCSLuaFile("metrostroi_dispatcher/client_schedule.lua")
	AddCSLuaFile("metrostroi_dispatcher/client_gui.lua")
	include("metrostroi_dispatcher/server.lua")
	include("metrostroi_dispatcher/def_controlrooms.lua")
else
	include("metrostroi_dispatcher/client_main.lua")
	include("metrostroi_dispatcher/client_dscp.lua")
	include("metrostroi_dispatcher/client_schedule.lua")
	include("metrostroi_dispatcher/client_gui.lua")
end

-- получить номер маршрута с поезда
function MDispatcher.GetRouteNumber(train)
	if not IsValid(train) then return end
	local rnum = train:GetNW2Int("RouteNumber",0)
	if table.HasValue({"gmod_subway_em508","gmod_subway_81-702","gmod_subway_81-703","gmod_subway_81-705_old","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720","gmod_subway_81-720_1","gmod_subway_81-720a","gmod_subway_81-717_freight","gmod_subway_81-717_5a"},train:GetClass()) then rnum = rnum / 10 end
	if rnum == 0 then
		rnum = train:GetNW2String("RouteNumbera","")
		if rnum == "" then rnum = 0 end
	end
	if rnum == 0 then
		rnum = train:GetNW2Int("RouteNumber:RouteNumber",0)
	end
	if rnum == 0 then
		rnum = train:GetNW2Int("ASNP:RouteNumber",0)
	end
	return rnum
end

-- название станции по индексу
function MDispatcher.StationNameByIndex(index)
	if not Metrostroi.StationConfigurations then return end
	local StationName
	for k,v in pairs(Metrostroi.StationConfigurations) do
		local CurIndex = tonumber(k)
		if not CurIndex or not istable(v) or not v.names or not istable(v.names) or table.Count(v.names) < 1 then StationName = k else StationName = v.names[1] end
		if CurIndex == index then return StationName end
	end
end

-- индекс станции по названию
function MDispatcher.StationIndexByName(name)
	if not Metrostroi.StationConfigurations then return end
	for k,v in pairs(Metrostroi.StationConfigurations) do
		if not tonumber(k) or not istable(v) or not v.names or not istable(v.names) or table.Count(v.names) < 1 then continue end
		if table.HasValue(v.names,name) or k == name then return k end
	end
end
