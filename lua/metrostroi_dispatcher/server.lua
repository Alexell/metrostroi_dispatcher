--------------------------- Metrostroi Dispatcher --------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------

util.AddNetworkString("MDispatcher.MainData")
util.AddNetworkString("MDispatcher.ScheduleData")
MDispatcher.Stations = {}

local cur_dis = "отсутствует"
local str_int = "Мин. интервал"
local cur_int = "1.45"

-- проверенные интервалы по картам
local map = game.GetMap()
if map:find("gm_smr_first_line") then cur_int = "3.00" end
if map:find("gm_mus_loopline") then cur_int = "3.00" end

local function SendToClients()
	net.Start("MDispatcher.MainData")
		net.WriteString(cur_dis)
		net.WriteString(str_int)
		net.WriteString(cur_int)
	net.Broadcast()
end

function MDispatcher.Disp(ply)
	cur_dis = ply:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	SendToClients()
	hook.Run("MDispatcher.TookPost",cur_dis)
end

function MDispatcher.SetDisp(ply,target)
	cur_dis = target:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	SendToClients()
	hook.Run("MDispatcher.TookPost",cur_dis)
end

function MDispatcher.UnDisp(ply)
	if cur_dis != "отсутствует" then
		if cur_dis == ply:Nick() then
			hook.Run("MDispatcher.FreedPost",cur_dis)
			local msg = "игрок "..cur_dis.." покинул пост Диспетчера."
			cur_dis = "отсутствует"
			str_int = "Мин. интервал"
			cur_int = "1.45"
			ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		else
			if (ply:IsAdmin()) then
				hook.Run("MDispatcher.FreedPost",cur_dis)
				local msg = ply:Nick().." снял игрока "..cur_dis.." с поста Диспетчера."
				cur_dis = "отсутствует"
				str_int = "Мин. интервал"
				cur_int = "1.45"
				ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
			else
				ply:PrintMessage(HUD_PRINTTALK,"Вы не можете покинуть пост, поскольку вы не на посту! Сейчас диспетчер "..cur_dis..".")
			end
		end
		SendToClients()
	else
		ply:PrintMessage(HUD_PRINTTALK,"Диспетчер на посту отсутствует!")
	end
end

function MDispatcher.SetInt(ply,mins)
	if cur_dis == ply:Nick() then
		cur_int = string.Replace(mins,":",".")
		str_int = "Интервал движения"
		local msg = "Диспетчер "..cur_dis.." установил интервал движения "..cur_int
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		SendToClients()
		hook.Run("MDispatcher.SetInt",cur_dis,cur_int)
	else
		ply:PrintMessage(HUD_PRINTTALK,"Вы не можете изменить интервал, поскольку вы не на посту! Сейчас диспетчер "..cur_dis..".")
	end
end

local function PLLFix()
	local already_fixed = false -- фикс повторной сработки во время игры
	for _, ent in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(ent) then continue end
		
		-- фикс координат на 158/2
		if ent.StationIndex == 158 and ent.PlatformIndex == 2 then
			ent:SetPos(ent:GetPos()+Vector(0,-100,0))
			ent.PlatformStart = Vector(28.43,14169.9,-6721.3)
			ent:SetNW2Vector("PlatformStart",ent.PlatformStart)
			ent.PlatformEnd = Vector(4955.4,14174.3,-6722.9)
			ent:SetNW2Vector("PlatformEnd",ent.PlatformEnd)
		end
		
		-- отделяем 2 линию
		if ent.StationIndex > 200 then already_fixed = 1 break end
		if ent.StationIndex > 156 then
			ent.StationIndex = ent.StationIndex+100
			ent:SetNWInt("StationIndex",ent.StationIndex)
		end
	end
	
	if already_fixed then return end
	local StationConfig = {}
	for k,v in pairs(Metrostroi.StationConfigurations) do
		if not tonumber(k) or k <= 156 then StationConfig[k] = v continue end
		if k > 156 then StationConfig[k+100] = v end
	end
	Metrostroi.StationConfigurations = StationConfig
	StationConfig = nil
end

-- название станции по индексу
local function StationNameByIndex(index)
	if not Metrostroi.StationConfigurations then return end
	local StationName
	for k,v in pairs(Metrostroi.StationConfigurations) do
		local CurIndex = tonumber(k)
		if not CurIndex or not istable(v) or not v.names or not istable(v.names) or table.Count(v.names) < 1 then StationName = k else StationName = v.names[1] end
		if CurIndex == index then return StationName end
	end
	return
end

-- собираем нужную инфу по станциям
local function BuildStationsTable()
	local distance = 600
	local LineID 
	local Path
	local StationID
	local StationNode

	for a, ent in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(ent) then continue end
		-- ищем номер линии (вдруг их две)
		LineID = math.floor(ent.StationIndex/100)
		if MDispatcher.Stations[LineID] == nil then MDispatcher.Stations[LineID] = {} end
		-- ищем путь
		Path = ent.PlatformIndex
		-- проверяем и записываем данные о станции
		if MDispatcher.Stations[LineID][Path] == nil then MDispatcher.Stations[LineID][Path] = {} end
		StationID = ent.StationIndex
		if MDispatcher.Stations[LineID][Path][StationID] == nil then MDispatcher.Stations[LineID][Path][StationID] = {} end
		if not MDispatcher.Stations[LineID][Path][StationID].Name then
			MDispatcher.Stations[LineID][Path][StationID].Name = StationNameByIndex(ent.StationIndex)
			StationNode = Metrostroi.GetPositionOnTrack(LerpVector(0.5, ent.PlatformStart, ent.PlatformEnd))
			StationNode = StationNode[1] and StationNode[1].node1 or {}
			MDispatcher.Stations[LineID][Path][StationID].Node = StationNode
			MDispatcher.Stations[LineID][Path][StationID].NodeID = StationNode.id or -1
			
			-- фикс для ПЛЛ
			if game.GetMap():find("jar_pll_remastered") then
				if LineID == 2 and Path == 1 and StationID == 257 then
					if MDispatcher.Stations[LineID][Path+1] == nil then MDispatcher.Stations[LineID][Path+1] = {} end
					if MDispatcher.Stations[LineID][Path+1][StationID] == nil then
						MDispatcher.Stations[LineID][Path+1][StationID] = MDispatcher.Stations[LineID][Path][StationID]
					end
				end
			end
		end
	end
end

-- получаем ко-во секунд в текущих сутках
local function ConvertTime()
	local tbl = os.date("!*t")
	local converted_time = tbl.hour*3600 + tbl.min*60 + tbl.sec
	--print(os.date("%X", converted_time))
	return converted_time
end

-- округление секунд до 0 и 5
local function RoundSeconds(number)
    local mod = number % 10
    if mod < 5 then number = number + (5 - mod) end
    if mod > 5 then number = number + (10 - mod) end
    return number
end

-- получаем ID последней станции в порядке следования
local function GetLastStationID(line_id,path)
	local i = 0
	for k,v in SortedPairsByMemberValue(MDispatcher.Stations[line_id][path],"NodeID") do
		i = i + 1
		if i == table.Count(MDispatcher.Stations[line_id][path]) then return k end
	end
end

-- генерируем расписание (NEW)
function MDispatcher.GenerateSimpleSched(station_start,path,station_last,holds)
	local line_id = math.floor(station_start/100)
	local init_node = MDispatcher.Stations[line_id][path][station_start].Node
	local prev_node
	local last_node = station_last and MDispatcher.Stations[line_id][path][station_last].Node or MDispatcher.Stations[line_id][path][GetLastStationID(line_id,path)].Node
	local sched_massiv = {}
	local station_time = 40
	local init_time = ConvertTime() + (station_time/2)
	local travel_time
	local hold_time
	local full_time
	local back_time
	
	for k, v in SortedPairsByMemberValue(MDispatcher.Stations[line_id][path], "NodeID") do
		if v.NodeID < init_node.id then continue end
		if v.NodeID == init_node.id then
			travel_time = 0
			full_time = travel_time
		end
		if v.NodeID > init_node.id and v.NodeID < last_node.id then
			if holds and holds[k] then hold_time = holds[k] else hold_time = 0 end
			travel_time = Metrostroi.GetTravelTime(prev_node,v.Node) + station_time + hold_time
			full_time = full_time + travel_time
		end
		if v.NodeID == last_node.id then
			travel_time = Metrostroi.GetTravelTime(prev_node,v.Node) + (station_time/2)
			full_time = full_time + travel_time
			table.insert(sched_massiv, {Name = v.Name, Time = os.date("%X",RoundSeconds(init_time + full_time))})
			break
		end
		table.insert(sched_massiv, {Name = v.Name, Time = os.date("%X",RoundSeconds(init_time + full_time))})
		prev_node = v.Node
	end
	back_time = os.date("%X", RoundSeconds(init_time + full_time + 120))
	full_time = RoundSeconds(full_time)
	return sched_massiv, full_time, back_time
end

-- Временный дебаг
local function PrintDebugInfo()
	---- DEBUG START ----
	for a,b in pairs(MDispatcher.Stations) do
		print("Line: "..a.."\n")
		for c,d in pairs(b) do
			print("Path: "..c)
			for k,v in SortedPairsByMemberValue(d, "NodeID") do
				print("ID: "..k.."| Name: "..v.Name.." | Node: "..v.NodeID--[[.." | Clock: "..(v.Clock or "Not Founded")]])
			end
			print("")
		end
		print("------------\n")
	end

	--[[print("StationConfigurations:")
	local stationstable = {}
	for k,v in pairs(Metrostroi.StationConfigurations) do
		if v.names[name_num] then
			table.insert(stationstable,{id = tostring(k), name = tostring(v.names[name_num])})
		else
			table.insert(stationstable,{id = tostring(k), name = tostring(v.names[1])})
		end
	end 
	table.SortByMember(stationstable, "id",true)
	timer.Simple(0.1, function() 
		for k,v in pairs(stationstable) do
			print(v.id.." - "..v.name)
		end
	end)
	print("------------\n")
	local tab = MDispatcher.GenerateSimpleSched(802, 1)
	for k, v in pairs(tab) do
		human_time = os.date("%X", v.Time)
		print(v.Name:sub(1,18)..": "..human_time)
	end]]
	---- DEBUG END ----
end

-- таймеры
if game.GetMap():find("jar_pll_remastered") then timer.Simple(0.1,PLLFix) end
timer.Simple(4,BuildStationsTable)
timer.Simple(6,PrintDebugInfo)


hook.Add("PlayerDisconnected","MDispatcher.Disconnect",function(ply) -- снимаем с поста при отключении
	if cur_dis == ply:Nick() then
		hook.Run("MDispatcher.FreedPost",cur_dis)
		cur_dis = "отсутствует"
		str_int = "Мин. интервал"
		cur_int = "1.45"
		SendToClients()
		local msg = "игрок "..ply:Nick().." покинул пост Диспетчера (отключился с сервера)."
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	end
end)




