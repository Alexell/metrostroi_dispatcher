------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------

util.AddNetworkString("MDispatcher.DispData")
util.AddNetworkString("MDispatcher.ScheduleData")
util.AddNetworkString("MDispatcher.ClearSchedule")
util.AddNetworkString("MDispatcher.Commands")
util.AddNetworkString("MDispatcher.InitialData")
util.AddNetworkString("MDispatcher.DSCPData")

MDispatcher.ActiveDispatcher = false
MDispatcher.Dispatcher = "отсутствует"
MDispatcher.Interval = "2.00"
MDispatcher.Stations = {}
MDispatcher.ClientStations = {}
MDispatcher.ControlRooms = {}

function MDispatcher.Initialize()
	-- загрузка блок-постов
	if not file.Exists("mdispatcher_controlrooms.txt","DATA") then
		file.Write("mdispatcher_controlrooms.txt",MDispatcher.DefControlRooms)
		MDispatcher.DefControlRooms = nil
	end
	
	local fl = file.Read("mdispatcher_controlrooms.txt","DATA")
	local tab = fl and util.JSONToTable(fl) or {}
	MDispatcher.ControlRooms = tab[game.GetMap()] or {}
	MDispatcher.DSCP = {}
	table.insert(MDispatcher.DSCP,{"Депо","отсутствует"})
	for k,v in pairs(MDispatcher.ControlRooms) do
		if not v.Name:find("Депо") and not v.Name:find("депо") then
			table.insert(MDispatcher.DSCP,{v.Name,"отсутствует"})
		end
	end
end
timer.Create("MDispatcher.Init",1,1,function()
	MDispatcher.Initialize()
	timer.Remove("MDispatcher.Init")
end)

-- проверенные интервалы по картам
local map = game.GetMap()
if map:find("gm_smr_first_line") then MDispatcher.Interval = "3.00" end
if map:find("gm_mus_loopline") then MDispatcher.Interval = "3.00" end

local function DispDataToClients()
	net.Start("MDispatcher.DispData")
		net.WriteString(MDispatcher.Dispatcher)
		net.WriteString(MDispatcher.Interval)
	net.Broadcast()
end

hook.Add("PlayerInitialSpawn","MDispatcher.InitPlayer",function(ply) -- отправляем данные клиенту
	if not IsValid(ply) then return end
	local crooms = {}
	local dscp = {}
	for k,v in pairs(MDispatcher.ControlRooms) do
		table.insert(crooms,v.Name)
	end
	for k,v in pairs(MDispatcher.DSCP) do
		table.insert(dscp,v[2])
	end
	net.Start("MDispatcher.InitialData")
		crooms = util.Compress(util.TableToJSON(crooms))
		local ln = #crooms
		net.WriteUInt(ln,32)
		net.WriteData(crooms,ln)
		net.WriteString(MDispatcher.Dispatcher)
		net.WriteString(MDispatcher.Interval)
		
		dscp = util.Compress(util.TableToJSON(dscp))
		local ln2 = #dscp
		net.WriteUInt(ln2,32)
		net.WriteData(dscp,ln2)
	net.Send(ply)
end)

hook.Add("PlayerDisconnected","MDispatcher.Disconnect",function(ply) -- снимаем с поста при отключении
	if not IsValid(ply) then return end
	MDispatcher.UnDisp(false,ply)
	MDispatcher.DSCPUnset(false,false,ply)
end)

function MDispatcher.Disp(ply)
	if not IsValid(ply) then return end
	if not MDispatcher.ActiveDispatcher then
		MDispatcher.Dispatcher = ply:Nick()
		ply:SetNW2Bool("MDispatcher",true)
		local msg = "игрок "..MDispatcher.Dispatcher.." заступил на пост Диспетчера."
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		DispDataToClients()
		MDispatcher.ActiveDispatcher = true
		hook.Run("MDispatcher.TookPost",MDispatcher.Dispatcher)
	else
		ply:ChatPrint("Пост диспетчера уже занят.")
	end
end

function MDispatcher.SetDisp(ply,sid)
	if not IsValid(ply) then return end
	if not ply:query("ulx disp") then
		ply:ChatPrint("У вас нет права на это действие.")
		return
	end
	if not MDispatcher.ActiveDispatcher then
		local tar = player.GetBySteamID(sid)
		MDispatcher.Dispatcher = tar:Nick()
		tar:SetNW2Bool("MDispatcher",true)
		local msg
		if ply:Nick() == tar:Nick() then
			msg = "игрок "..MDispatcher.Dispatcher.." заступил на пост Диспетчера."
		else
			msg = "игрок "..ply:Nick().." назначил игрока "..MDispatcher.Dispatcher.." на пост Диспетчера."
		end
		DispDataToClients()
		MDispatcher.ActiveDispatcher = true
		hook.Run("MDispatcher.TookPost",MDispatcher.Dispatcher)
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	else
		ply:ChatPrint("Пост диспетчера уже занят.")
	end
end

function MDispatcher.UnDisp(ply,target)
	if MDispatcher.ActiveDispatcher then
		if not target then
			for k,v in ipairs(player.GetAll()) do
				if v:Nick() == MDispatcher.Dispatcher then
					target = v
					break
				end
			end
		end
		if MDispatcher.Dispatcher ~= target:Nick() then return end
		
		local msg = "игрок "..MDispatcher.Dispatcher.." покинул пост Диспетчера."
		if IsValid(ply) then
			if ply:Nick() ~= target:Nick() then
				if (ply:query("ulx disp")) then
					msg = ply:Nick().." снял игрока "..MDispatcher.Dispatcher.." с поста Диспетчера."
					target:SetNW2Bool("MDispatcher",false)
				else
					ply:ChatPrint("У вас нет права на это действие.")
					return
				end
			else
				ply:SetNW2Bool("MDispatcher",false)
			end
		else
			msg = "игрок "..target:Nick().." покинул пост Диспетчера (отключился с сервера)."
		end
		MDispatcher.ActiveDispatcher = false
		hook.Run("MDispatcher.FreedPost",MDispatcher.Dispatcher)
		MDispatcher.Dispatcher = "отсутствует"
		MDispatcher.Interval = "2.00"
		DispDataToClients()
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	end
end

function MDispatcher.SetInt(ply,mins)
	if not IsValid(ply) then return end
	if ply:GetNW2Bool("MDispatcher") then
		MDispatcher.Interval = string.Replace(mins,":",".")
		local msg = "Диспетчер "..MDispatcher.Dispatcher.." установил интервал движения "..MDispatcher.Interval
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		DispDataToClients()
		hook.Run("MDispatcher.SetInt",MDispatcher.Dispatcher,MDispatcher.Interval)
	else
		ply:ChatPrint("Вы не можете изменить интервал, поскольку вы не на посту!\nСейчас диспетчер "..MDispatcher.Dispatcher..".")
	end
end

function MDispatcher.DispatcherMenu(ply)
	if not IsValid(ply) then return end
	if not ply:query("ulx disp") and not ply:GetNW2Bool("MDispatcher") and not ply:GetNW2Bool("MDSCP") then
		ply:ChatPrint("У вас нет доступа к меню диспетчера.")
		return
	end
	local routes = {}
	for train in pairs(Metrostroi.SpawnedTrains) do
		if not IsValid(train) then continue end
		if (train.FrontTrain and train.RearTrain) then continue end
		local driver = train.Owner
		local route = MDispatcher.GetRouteNumber(train)
		if not routes[driver:SteamID()] then routes[driver:SteamID()] = {Nick = driver:Nick(), Route = route} end
	end
	net.Start("MDispatcher.Commands")
		net.WriteString("menu")
		routes = util.Compress(util.TableToJSON(routes))
		local ln = #routes
		net.WriteUInt(ln,32)
		net.WriteData(routes,ln)
		
		local stations = util.Compress(util.TableToJSON(MDispatcher.ClientStations))
		local ln2 = #stations
		net.WriteUInt(ln2,32)
		net.WriteData(stations,ln2)
	net.Send(ply)
end

concommand.Add("disp_menu",function(ply,cmd,args)
	if not IsValid(ply) then return end
	MDispatcher.DispatcherMenu(ply)
end)
hook.Add("PlayerSay","MDispatcher.SayHook",function(ply,text)
	if not IsValid(ply) then return end
	if (text:lower() == "!dmenu") then
		MDispatcher.DispatcherMenu(ply)
	end
end)

function MDispatcher.DSCPSet(ply,station,target_sid)
	if not IsValid(ply) then return end
	if not ply:GetNW2Bool("MDispatcher") then
		ply:ChatPrint("Вы не можете назначить ДСЦП, поскольку вы не на посту ДЦХ!\nСейчас ДЦХ "..MDispatcher.Dispatcher..".")
		return
	end
	local dscp = {}
	for k,v in pairs(MDispatcher.DSCP) do
		if v[1] == station then
			if v[2] == "отсутствует" then
				local tar = player.GetBySteamID(target_sid)
				msg = "Игрок "..tar:Nick().." назначен на пост ДСЦП '"..station.."'."
				tar:SetNW2Bool("MDSCP",true)
				v[2] = tar:Nick()
			else
				ply:ChatPrint("Блок-пост уже занят.")
				return
			end
		end
		table.insert(dscp,v[2])
	end
	hook.Run("MDispatcher.DSCPSet",msg)
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	net.Start("MDispatcher.DSCPData")
		dscp = util.Compress(util.TableToJSON(dscp))
		local ln = #dscp
		net.WriteUInt(ln,32)
		net.WriteData(dscp,ln)
	net.Broadcast()
end

function MDispatcher.DSCPUnset(ply,station,tagret)
	if IsValid(ply) and not ply:GetNW2Bool("MDispatcher") then
		ply:ChatPrint("Вы не можете снять ДСЦП, поскольку вы не на посту ДЦХ!\nСейчас ДЦХ "..MDispatcher.Dispatcher..".")
		return
	end
	local dscp = {}
	local freed_st
	local founded = false
	local msg = ""
	if not station then
		if not IsValid(tagret) then return end
		for k,v in pairs(MDispatcher.DSCP) do
			if v[2] == tagret:Nick() then
				founded = true
				msg = "Игрок "..tagret:Nick().." покинул пост(ы) ДСЦП (отключился с сервера)."
				v[2] = "отсутствует"
			end
			table.insert(dscp,v[2])
		end
	else
		local tar
		for k,v in pairs(MDispatcher.DSCP) do
			if v[1] == station then
				for a,b in ipairs(player.GetAll()) do
					if b:Nick() == v[2] then
						tar = b
						break
					end
				end
				msg = "Игрок "..v[2].." снят с поста ДСЦП '"..v[1].."'."
				tar:SetNW2Bool("MDSCP",false)
				v[2] = "отсутствует"
			end
			table.insert(dscp,v[2])
		end
		if table.HasValue(dscp,tar:Nick()) then tar:SetNW2Bool("MDSCP",true) end
	end
	if not station and not founded then dscp = nil return end
	hook.Run("MDispatcher.DSCPUnset",msg)
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	net.Start("MDispatcher.DSCPData")
		dscp = util.Compress(util.TableToJSON(dscp))
		local ln = #dscp
		net.WriteUInt(ln,32)
		net.WriteData(dscp,ln)
	net.Broadcast()
end

local function AddControlRoom(ply,name)
    local pos = ply:GetPos()+Vector(0,0,10)
	local ang = ply:EyeAngles()
	net.Start("MDispatcher.Commands")
		net.WriteString("cr-add")
		net.WriteString(name)
		net.WriteVector(pos)
		net.WriteAngle(ang)
	net.Send(ply)
end

local function SaveControlRooms(ply,tab)
	local fl = file.Read("mdispatcher_controlrooms.txt","DATA")
	local crooms = fl and util.JSONToTable(fl) or {}
	crooms[game.GetMap()] = tab
	file.Write("mdispatcher_controlrooms.txt",util.TableToJSON(crooms,true))
	timer.Create("MDispatcher.ReInit",0.2,1,function()
		MDispatcher.Initialize()
		timer.Remove("MDispatcher.ReInit")
		net.Start("MDispatcher.Commands")
			net.WriteString("cr-save-ok")
		net.Send(ply)
	end)
end

net.Receive("MDispatcher.Commands",function(ln,ply)
	if not IsValid(ply) then return end
	local comm = net.ReadString()
	if comm == "cr-teleport" then
		local name = net.ReadString()
		for k,v in pairs(MDispatcher.ControlRooms) do
			if v.Name == name then
				ply:SetPos(v.Pos)
				ply:SetEyeAngles(v.Ang)
				ply:SetMoveType(2)
				break
			end
		end
	elseif comm == "dscp-post-set" then
		local st = net.ReadString()
		local tar = net.ReadString()
		MDispatcher.DSCPSet(ply,st,tar)
	elseif comm == "dscp-post-unset" then
		local st = net.ReadString()
		MDispatcher.DSCPUnset(ply,st)
	elseif comm == "set-int" then
		local mins = net.ReadString()
		MDispatcher.SetInt(ply,mins)
	elseif comm == "set-disp" then
		local sid = net.ReadString()
		MDispatcher.SetDisp(ply,sid)
	elseif comm == "cr-add" then
		local cr_name = net.ReadString()
		AddControlRoom(ply,cr_name)
	elseif comm == "cr-save" then
		local tab = net.ReadTable()
		SaveControlRooms(ply,tab)
	elseif comm == "sched-send" then
		local sid = net.ReadString()
		local path = net.ReadInt(3)
		local start = net.ReadInt(11)
		local last = net.ReadInt(11)
		local holds = net.ReadTable()
		PrintTable(holds)
		local tar = player.GetBySteamID(sid)
		local sched,ftime,btime = MDispatcher.GenerateSimpleSched(start,path,last,holds)
		net.Start("MDispatcher.ScheduleData")
			local tbl = util.Compress(util.TableToJSON(sched))
			local ln = #tbl
			net.WriteUInt(ln,32)
			net.WriteData(tbl,ln)
			net.WriteString(ftime)
			net.WriteString(btime)
			net.WriteTable(holds)
		net.Send(tar)
		net.Start("MDispatcher.Commands")
			net.WriteString("sched-send-ok")
		net.Send(ply)
	end
end)

function MDispatcher.GetSchedule(ply)
	if not IsValid(ply) then return end
    local train = ply:GetTrain()
	if not IsValid(train) then
		ply:ChatPrint("Поезд не обнаружен!\nПолучить расписание можно только находясь в кресле машиниста.")
		return
	end
	local station = train:ReadCell(49160)
	if not Metrostroi.StationConfigurations[station] then
		ply:ChatPrint("Станция не обнаружена!\nПолучить расписание можно только находясь на станции.")
		return
	end
	local path = train:ReadCell(49168)
	if path == 0 then
		ply:ChatPrint("Не удалось получить номер пути!")
		return
	end
	local sched,ftime,btime = MDispatcher.GenerateSimpleSched(station,path)
	net.Start("MDispatcher.ScheduleData")
		local tbl = util.Compress(util.TableToJSON(sched))
		local ln = #tbl
		net.WriteUInt(ln,32)
		net.WriteData(tbl,ln)
		net.WriteString(ftime)
		net.WriteString(btime)
	net.Send(ply)
end

function MDispatcher.ClearSchedule(ply)
	net.Start("MDispatcher.ClearSchedule")
	net.Send(ply)
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
			MDispatcher.Stations[LineID][Path][StationID].Name = MDispatcher.StationNameByIndex(ent.StationIndex)
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
	
	-- версия таблицы для клиента без нод
	MDispatcher.ClientStations = table.Copy(MDispatcher.Stations)
	for c,d in pairs(MDispatcher.ClientStations) do
		for e,f in pairs(d) do
			for g,h in pairs(f) do
				h.Node = nil
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

-- генерируем расписание
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
			table.insert(sched_massiv, {ID = k, Name = v.Name, Time = os.date("%X",RoundSeconds(init_time + full_time))})
			break
		end
		table.insert(sched_massiv, {ID = k, Name = v.Name, Time = os.date("%X",RoundSeconds(init_time + full_time))})
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
