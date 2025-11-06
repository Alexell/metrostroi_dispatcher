------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------

local debug_enabled = CreateConVar("mdispatcher_debug", 0, FCVAR_ARCHIVE, "Enable debug in server console")
util.AddNetworkString("MDispatcher.DispData")
util.AddNetworkString("MDispatcher.ScheduleData")
util.AddNetworkString("MDispatcher.ClearSchedule")
util.AddNetworkString("MDispatcher.Commands")
util.AddNetworkString("MDispatcher.InitialData")
util.AddNetworkString("MDispatcher.DSCPData")
util.AddNetworkString("MDispatcher.IntervalsData")

MDispatcher.ActiveDispatcher = false
MDispatcher.Dispatcher = "отсутствует"
MDispatcher.Interval = "2.00"
MDispatcher.Stations = {}
MDispatcher.SignalClass = "gmod_track_signal"
MDispatcher.Signals = {}
MDispatcher.ClientStations = {}
MDispatcher.ControlRooms = {}

function MDispatcher.Initialize()
	-- загрузка блок-постов
	if not file.Exists("mdispatcher_controlrooms.txt","DATA") then
		file.Write("mdispatcher_controlrooms.txt",MDispatcher.DefControlRooms)
	end
	MDispatcher.DefControlRooms = nil
	
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
	
	MDispatcher.GetSignalClass()
	
	-- изменения в сигналах
	local ENT = scripted_ents.GetStored(MDispatcher.SignalClass).t
	local ars_logic = ENT.ARSLogic
	function ENT:ARSLogic(tim)
		ars_logic(self, tim)
		if self.Routes[self.Route] then
			if self.Routes[self.Route].ARSCodes then
				local ARSCodes = self.Routes[self.Route].ARSCodes
				if self.NextSignalLink == nil and not self.Occupied then
					self.ARSSpeedLimit = self.InvationSignal and 1 or tonumber(ARSCodes[math.min(#ARSCodes, self.FreeBS+1)])
				end
			end
		end
	end
	
	-- загрузка сигналов, имеющих маршрут
	timer.Simple(2, function()
		for k, v in pairs(ents.FindByClass(MDispatcher.SignalClass)) do
			local routes = {}
			for id, info in pairs(v.Routes) do
				if info.RouteName and info.RouteName != "" and info.RouteName:upper() != "GERM" then
					table.insert(routes, info.RouteName:upper())
				end
			end
			if #routes > 0 then
				table.insert(MDispatcher.Signals, {Name = v.Name, Routes = routes})
			end
		end
	end)
end

hook.Add("InitPostEntity", "MDispatcher.Initialize", function()
	MDispatcher.Initialize()
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
	local stations = {}
	for k,v in pairs(MDispatcher.ControlRooms) do
		table.insert(crooms,v.Name)
	end
	for k,v in pairs(MDispatcher.DSCP) do
		table.insert(dscp,v[2])
	end
	for a,b in pairs(MDispatcher.Stations) do
		for c,d in pairs(b) do
			if c == 1 then
				for k,v in SortedPairsByMemberValue(d, "NodeID") do
					table.insert(stations,{ID = k, Name = v.Name})
				end
				break
			end
		end
		break
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
		
		stations = util.Compress(util.TableToJSON(stations))
		local ln3 = #stations
		net.WriteUInt(ln3,32)
		net.WriteData(stations,ln3)
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
				if (ply:IsAdmin()) then
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
	local routes = {}
	for train in pairs(Metrostroi.SpawnedTrains) do
		if not IsValid(train) then continue end
		if (train.FrontTrain and train.RearTrain) then continue end
		local owner = train.Owner
		if not IsValid(owner) then continue end
		local route = MDispatcher.GetRouteNumber(train)
		if not routes[owner:SteamID()] then routes[owner:SteamID()] = {Nick = owner:Nick(), Route = route} end
	end
	
	local next_signal = ""
	local train = ply:GetTrain()
	if IsValid(train) then
		local pos = Metrostroi.TrainPositions[train]
		if pos then pos = pos[1] end
		if pos then
			local sig,sigback = Metrostroi.GetARSJoint(pos.node1, pos.x, Metrostroi.TrainDirections[train], train)
			if sig then
				next_signal = sig.Name:upper()
			end
		end
	end

	net.Start("MDispatcher.Commands")
		net.WriteString("menu")
		local signals = util.Compress(util.TableToJSON(MDispatcher.Signals))
		local ln1 = #signals
		net.WriteUInt(ln1,32)
		net.WriteData(signals,ln1)
		net.WriteString(next_signal)
		
		routes = util.Compress(util.TableToJSON(routes))
		local ln2 = #routes
		net.WriteUInt(ln2,32)
		net.WriteData(routes,ln2)
		
		local stations = util.Compress(util.TableToJSON(MDispatcher.ClientStations))
		local ln3 = #stations
		net.WriteUInt(ln3,32)
		net.WriteData(stations,ln3)
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

local function GetRearTrain(train)
	return train.WagonList[#train.WagonList]
end

local function CheckSwitchesState(switches)
	local checked = true
	if not switches or switches == "" then return true end
	switches = string.Explode(",",switches)
	for k, v in pairs(switches) do
		local switchname = v:sub(1,-2)
		local statedesired = v:sub(-1,-1)
		local switchent = Metrostroi.GetSwitchByName(switchname)
		if not IsValid(switchent) then continue end
		local statereal = switchent.AlternateTrack and -1 or 1
		if statedesired == "+" and statereal != 1 then
			checked = false
		end
		if statedesired == "-" and statereal != -1 then
			checked = false
		end
	end
	return checked
end

local function SetSwitchesToRoute(switches)
	if not switches or switches == "" then return end
	switches = string.Explode(",",switches)
	for k, v in pairs(switches) do
		local statedesired = v:sub(-1,-1)
		local switchname = v:sub(1,-2)
		if switchname == "" then continue end
		local switchent = Metrostroi.GetSwitchByName(switchname)
		if not IsValid(switchent) then continue end
		local statereal = switchent.AlternateTrack and -1 or 1
		if statedesired == "+" and statereal != 1 then
			switchent:SendSignal("main", nil, true)
		end
		if statedesired == "-" and statereal != -1 then
			switchent:SendSignal("alt", nil, true)
		end
	end
end

function MDispatcher.SignalPass(ply,signal_name,route_name)
	if not IsValid(ply) then return end
	if MDispatcher.ActiveDispatcher and ply:Nick() ~= MDispatcher.Dispatcher then
		ply:ChatPrint("Диспетчер на посту!")
		return
	end
	local signal = Metrostroi.SignalEntitiesByName[string.upper(signal_name)]
	if not IsValid(signal) then
		ply:ChatPrint("Сигнал не найден.")
		return
	end
	if signal.Red and not signal.Occupied then
		if route_name and route_name != "" and signal.Routes then
			for k, v in pairs(signal.Routes) do
				if string.upper(v.RouteName) == string.upper(route_name) then
					if not CheckSwitchesState(v.Switches) then
						SetSwitchesToRoute(v.Switches)
					end
					ply.pasred = true
					if signal.GoodInvationSignal > 1 or signal.GoodInvationSignal == -1 then signal.InvationSignal = true end
					ulx.fancyLog("#s воспользовался автопроездом сигнала #s.", ply:Nick(), signal.Name)
					break
				end
			end
		elseif not route_name or route_name == "" then
			if not CheckSwitchesState(signal.Routes[signal.Route or 1].Switches) then
				SetSwitchesToRoute(signal.Routes[signal.Route or 1].Switches)
			end
			ply.pasred = true
			if signal.GoodInvationSignal > 1 or signal.GoodInvationSignal == -1 then signal.InvationSignal = true end
			ulx.fancyLog("#s воспользовался автопроездом сигнала #s.", ply:Nick(), signal.Name)
		end
	end
end

net.Receive("MDispatcher.Commands",function(ln,ply)
	if not IsValid(ply) then return end
	local comm = net.ReadString()
	if comm == "cr-teleport" then
		local name = net.ReadString()
		for k,v in pairs(MDispatcher.ControlRooms) do
			if v.Name == name then
				if IsValid(ply:GetVehicle()) then
					ply:ExitVehicle()
				end
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
		local hl = net.ReadTable()
		local cm = net.ReadString()
		local tar = player.GetBySteamID(sid)
		local train = tar:GetTrain()
		if not IsValid(train) then
			ply:ChatPrint("Поезд игрока не обнаружен!\nОтправить расписание можно только игроку в кресле машиниста.")
			return
		end
		local sched,ftime,btime,holds = MDispatcher.GenerateSimpleSched(start,path,nil,last,hl)
		local schedule = {table = sched, ftime = ftime, btime = btime, holds = holds, comm = cm}
		train.ScheduleData = schedule
		GetRearTrain(train).ScheduleData = schedule
		net.Start("MDispatcher.ScheduleData")
			local tbl = util.Compress(util.TableToJSON(schedule))
			local ln = #tbl
			net.WriteUInt(ln,32)
			net.WriteData(tbl,ln)
		net.Send(tar)
		net.Start("MDispatcher.Commands")
			net.WriteString("sched-send-ok")
		net.Send(ply)
	elseif comm == "ints" then
		local status = net.ReadBool()
		if status then
			ply:SetNW2Bool("MDispatcher.ShowIntervals",true)
			local ints = MDispatcher.GetIntervals()
			MDispatcher.SendIntervals(ply,ints)
		else
			ply:SetNW2Bool("MDispatcher.ShowIntervals",false)
		end
	elseif comm:find("routes") then
		local signal_name = net.ReadString()
		local route_name = net.ReadString()
		if comm:find("open") or comm:find("close") then
			if MDispatcher.ActiveDispatcher and ply:Nick() ~= MDispatcher.Dispatcher then
				ply:ChatPrint("Диспетчер на посту!")
				return
			end
			local signal = Metrostroi.SignalEntitiesByName[signal_name:upper()]
			for k, v in pairs(signal.Routes) do
				if v.RouteName:upper() == route_name:upper() then
					if comm:find("open") then
						signal:OpenRoute(k)
						ulx.fancyLog("#s открыл маршрут #s.", ply:Nick(), route_name)
					else
						signal:CloseRoute(k)
						ulx.fancyLog("#s закрыл маршрут #s.", ply:Nick(), route_name)
					end
					break
				end
			end
		elseif comm:find("pass") then
			MDispatcher.SignalPass(ply,signal_name,route_name)
		end
	end
end)

-- получаем ID последней станции в порядке следования
local function GetLastStationID(line_id,path)
	local i = 0
	for k,v in SortedPairsByMemberValue(MDispatcher.Stations[line_id][path],"NodeID") do
		i = i + 1
		if i == table.Count(MDispatcher.Stations[line_id][path]) then return k end
	end
end

-- получаем ко-во секунд в текущих сутках
local function ConvertTime()
	local tbl = os.date("!*t", Metrostroi.GetSyncTime())
	local converted_time = tbl.hour*3600 + tbl.min*60 + tbl.sec
	return converted_time
end

function MDispatcher.GetSchedule(ply)
	if not IsValid(ply) then return end
	if not Metrostroi.StationConfigurations then
		ply:ChatPrint("Карта не сконфигурирована!")
		return
	end
	if table.Count(MDispatcher.Stations) == 0 then
		ply:ChatPrint("Отсутствуют данные для создания расписания!")
		return
	end
	if MDispatcher.ActiveDispatcher then
		ply:ChatPrint("Вы не можете получить расписание, поскольку ДЦХ на посту!")
		return
	end
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
	local sched,ftime,btime,holds = MDispatcher.GenerateSimpleSched(station,path)
	if table.Count(sched) > 2 then
		local schedule = {table = sched, ftime = ftime, btime = btime, holds = holds, comm = ""}
		train.ScheduleData = schedule
		GetRearTrain(train).ScheduleData = schedule
		net.Start("MDispatcher.ScheduleData")
			local tbl = util.Compress(util.TableToJSON(schedule))
			local ln = #tbl
			net.WriteUInt(ln,32)
			net.WriteData(tbl,ln)
		net.Send(ply)
	else
		ply:ChatPrint("Недостаточно данных для создания расписания!")
		return
	end
end

function MDispatcher.ClearSchedule(ply)
	if not IsValid(ply) then return end
	local train = ply:GetTrain()
	if not IsValid(train) then
		ply:ChatPrint("Поезд не обнаружен!\nОчистить расписание можно только находясь в кресле машиниста.")
		return
	end
	if ply ~= train.Owner then
		ply:ChatPrint("Вы не можете очистить расписание чужого поезда.")
		return
	end
	train.ScheduleData = nil
	GetRearTrain(train).ScheduleData = nil
	net.Start("MDispatcher.ClearSchedule")
	net.Send(ply)
end

hook.Add("PlayerEnteredVehicle","MDispatcher.EnteredVehicle",function(ply,veh)
	local train = veh:GetNW2Entity("TrainEntity")
	if IsValid(train) then
		if train.ScheduleData then
			net.Start("MDispatcher.ScheduleData")
				local tbl = util.Compress(util.TableToJSON(train.ScheduleData))
				local ln = #tbl
				net.WriteUInt(ln,32)
				net.WriteData(tbl,ln)
			net.Send(ply)
		else
			net.Start("MDispatcher.ClearSchedule")
			net.Send(ply)
		end
	end
end)

local function UpdateTrainSchedule(train, station, arrived)
	if not IsValid(train) then return end
	local rear_train = GetRearTrain(train)
	if not IsValid(rear_train) then return end
	local clear_schedule = false
	local nxt = false
	local last = false
	local line_id = math.floor(station/100)
	local path = train:ReadCell(49168)
	local last_st = train.ScheduleData.table[#train.ScheduleData.table].ID
	if station == last_st then last = true end
	if arrived and train.ScheduleData.NeedRegenerate then
		local owner = train.Owner
		if IsValid(owner) and owner:GetInfoNum("mdispatcher_autochedule", 1) == 1 then
			if game.GetMap():find("neocrimson_line_a") 	and station == 551 then path = 1 end
			if game.GetMap():find("jar_pll_remastered") and station == 150 then path = 1 end
			if game.GetMap():find("jar_imagine_line") 	and station == 700 then path = 1 end
			local sched,ftime,btime,holds = MDispatcher.GenerateSimpleSched(station,path,train.ScheduleData.btime)
			if table.Count(sched) > 2 then
				local schedule = {table = sched, ftime = ftime, btime = btime, holds = holds, comm = ""}
				train.ScheduleData = schedule
				rear_train.ScheduleData = schedule
			end
		else
			train.ScheduleData = nil
			rear_train.ScheduleData = nil
			clear_schedule = true
		end
	end
	if train.ScheduleData then
		for k,v in pairs(train.ScheduleData.table) do
			if arrived then
				if v.ID == station then
					local result = v.Time - ConvertTime()
					if result > 20 then 
						v.State = "cur"
					else 
						v.State = "cur_late"
					end
					if (k > 1 and train.ScheduleData.table[k-1].State ~= "prev") then
						train.ScheduleData.table[k-1].State = "prev"
					end
					if last and result < -45 then 
						v.State = "prev"
					end
					if last and result < -120 then 
						train.ScheduleData.NeedRegenerate = true
					end
					break
				end
			else
				if v.ID == station then
					local driver = train:GetDriver()
					if IsValid(driver) then
						local result = math.abs(v.Time - ConvertTime())
						hook.Run("MDispatcher.Departure", train, driver, result < 20)
					end
				end
				if last then
					if v.ID == station then
						v.State = "prev"
						train.ScheduleData.NeedRegenerate = true
						break
					end
				else
					if v.ID == station then v.State = "prev" nxt = true end
					if v.ID ~= station and nxt then v.State = "next" break end
				end
			end
		end
	end
	local seats = {train.DriverSeat, train.InstructorsSeat, train.ExtraSeat1, train.ExtraSeat2, train.ExtraSeat3, rear_train.DriverSeat, rear_train.InstructorsSeat, rear_train.ExtraSeat1, rear_train.ExtraSeat2, rear_train.ExtraSeat3}
	for k,v in pairs(seats) do
		if not IsValid(v) then continue end
		local driver = v:GetDriver()
		if not IsValid(driver) then continue end
		if not clear_schedule then
			net.Start("MDispatcher.ScheduleData")
				local tbl = util.Compress(util.TableToJSON(train.ScheduleData))
				local ln = #tbl
				net.WriteUInt(ln,32)
				net.WriteData(tbl,ln)
			net.Send(driver)
		else
			MDispatcher.ClearSchedule(driver)
		end
	end
end

timer.Create("MDispatcher.Platforms",3,0,function()
	for k, v in pairs(ents.FindByClass("gmod_track_platform")) do
		if IsValid(v.CurrentTrain) and v.CurrentTrain.ScheduleData then
			if v.CurrentTrain.LeftDoorsOpen or v.CurrentTrain.RightDoorsOpen then
				v.CurrentTrain.Stopped = true
				UpdateTrainSchedule(v.CurrentTrain, v.StationIndex, true)
			end
			if v.CurrentTrain.Speed > 5 and v.CurrentTrain.Stopped then
				v.CurrentTrain.Stopped = false
				UpdateTrainSchedule(v.CurrentTrain, v.StationIndex, false)
			end
		end
	end
end)

local function EntWithinBoundsFromPos(pos, ent, dist)
	local distSQR = dist * dist
	return pos:DistToSqr(ent:GetPos()) < distSQR
end

-- собираем нужную инфу по станциям
local function BuildStationsTable()
	if game.GetMap():find("loopline_e") then return end
	if table.Count(Metrostroi.Paths) == 0 then return end
	if not Metrostroi.StationConfigurations then return end
	local distance = 500
	local LineID 
	local Path
	local StationID
	local StationPos
	local TrackPos
	local StationNode

	for a, ent in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(ent) then continue end
		-- ищем номер линии (вдруг их две)
		LineID = math.floor(ent.StationIndex/100)

		-- ищем путь
		Path = ent.PlatformIndex

		-- пропуск лишнего
		if game.GetMap():find("metrostroi_b50") then
			if LineID > 1 then continue end
		end
		if game.GetMap():find("jar_pll_remastered") then
			if Path > 2 then continue end
		end
		if game.GetMap():find("neoorange_e") then
			if Path > 2 then continue end
		end
		
		if MDispatcher.Stations[LineID] == nil then MDispatcher.Stations[LineID] = {} end
		-- проверяем и записываем данные о станции
		if MDispatcher.Stations[LineID][Path] == nil then MDispatcher.Stations[LineID][Path] = {} end
		StationID = ent.StationIndex
		if MDispatcher.Stations[LineID][Path][StationID] == nil then MDispatcher.Stations[LineID][Path][StationID] = {} end
		if not MDispatcher.Stations[LineID][Path][StationID].Name then
			MDispatcher.Stations[LineID][Path][StationID].Name = MDispatcher.StationNameByIndex(ent.StationIndex)
			
			StationPos = Metrostroi.GetPositionOnTrack(ent.PlatformEnd)
			if game.GetMap():find("neocrimson_line_a") then
				if LineID == 5 and Path == 2 and StationID == 551 then
					StationPos = Metrostroi.GetPositionOnTrack(ent.PlatformStart)
				end
			end
			if game.GetMap():find("surfacemetro_w") then
				if LineID == 1 and Path == 1 and StationID == 105 then
					StationPos = Metrostroi.GetPositionOnTrack(ent.PlatformStart)
				end
			end
			if game.GetMap():find("jar_imagine_line") then
				if LineID == 7 and StationID == 700 then
					StationPos = Metrostroi.GetPositionOnTrack(ent.PlatformStart)
				end
			end
			StationNode = StationPos[1] and StationPos[1].node1 or {}
			TrackPos = StationPos[1] and StationPos[1].node1.pos
			MDispatcher.Stations[LineID][Path][StationID].Node = StationNode
			MDispatcher.Stations[LineID][Path][StationID].NodeID = StationNode.id or -1
			
			-- запускаем цикл поиска часов			
			if game.GetMap():find("minsk_1984") then -- костыль для Минска
				distance = 750
				for b, ent2 in pairs(ents.FindByClass("gmod_track_clock_interval_minsk")) do
					if IsValid(ent2) and EntWithinBoundsFromPos(TrackPos, ent2, distance) then
						if MDispatcher.Stations[LineID][Path][StationID].Clock == nil then
							MDispatcher.Stations[LineID][Path][StationID].Clock = ent2
						end
					end
				end
			else
			-- для всех остальных карт двойной обход
				for b, ent2 in pairs(ents.FindByClass("gmod_track_clock_small")) do
					if IsValid(ent2) and EntWithinBoundsFromPos(TrackPos, ent2, distance) then
						if MDispatcher.Stations[LineID][Path][StationID].Clock == nil then
							MDispatcher.Stations[LineID][Path][StationID].Clock = ent2
						end
					end
				end
				distance = 750
				if game.GetMap():find("jar_pll_remastered") then 
					if LineID == 1 and StationID == 150 then
						distance = 500 
					end
				end
				if game.GetMap():find("neocrimson_line_a") then 
					if LineID == 5 and StationID == 551 then
						distance = 500 
					end
				end 
				if game.GetMap():find("jar_imagine_line") then
					if LineID == 7 and StationID == 700 then
						distance = 300
					end
				end
				if game.GetMap():find("surfacemetro_w") then distance = 1000 end
				for b, ent2 in pairs(ents.FindByClass("gmod_track_clock_interval")) do
					if IsValid(ent2) and EntWithinBoundsFromPos(TrackPos, ent2, distance) then
						if MDispatcher.Stations[LineID][Path][StationID].Clock == nil then
							MDispatcher.Stations[LineID][Path][StationID].Clock = ent2
						end
					end
				end
			end
			
			-- фикс для ПЛЛ
			if game.GetMap():find("jar_pll_remastered") then
				if LineID == 2 and Path == 1 and StationID == 257 then
					if MDispatcher.Stations[LineID][Path+1] == nil then MDispatcher.Stations[LineID][Path+1] = {} end
					if MDispatcher.Stations[LineID][Path+1][StationID] == nil then
						MDispatcher.Stations[LineID][Path+1][StationID] = table.Copy(MDispatcher.Stations[LineID][Path][StationID])
						MDispatcher.Stations[LineID][Path+1][StationID].Node = MDispatcher.Stations[LineID][Path][StationID].Node
						MDispatcher.Stations[LineID][Path+1][StationID].NodeID = 200
					end
				end
				if LineID == 1 and Path == 1 and StationID == 155 then
					MDispatcher.Stations[LineID][Path][StationID].NodeID = MDispatcher.Stations[LineID][Path][StationID].NodeID + 674
				end
				if LineID == 1 and Path == 1 and StationID == 156 then
					MDispatcher.Stations[LineID][Path][StationID].NodeID = MDispatcher.Stations[LineID][Path][StationID].NodeID + 674
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

-- Собираем интервалы
local function GetIntervalTime(ent)
	if not IsValid(ent) then return -1 end
	return math.floor(Metrostroi.GetSyncTime() - (ent:GetIntervalResetTime() + GetGlobalFloat("MetrostroiTY")))
end

function MDispatcher.GetIntervals()
	local Intervals = {}
	for a,b in pairs(MDispatcher.Stations) do
		for c,d in pairs(b) do
			if c == 1 then
				for k,v in SortedPairsByMemberValue(d, "NodeID") do
					local int_p1 = GetIntervalTime(v.Clock)
					local int_p2 = GetIntervalTime(MDispatcher.Stations[a][2][k].Clock)
					Intervals[k] = {int_p1, int_p2}
				end
				break
			end
		end
		break
	end
	return Intervals
end

function MDispatcher.SendIntervals(ply,ints)
	if not IsValid(ply) then return end
	net.Start("MDispatcher.IntervalsData")
		local tab = util.Compress(util.TableToJSON(ints))
		local ln = #tab
		net.WriteUInt(ln,32)
		net.WriteData(tab,ln)
	net.Send(ply)
end

timer.Create("MDispatcher.Intervals", 5, 0, function()
	local need_plys = {}
	for k,v in ipairs(player.GetAll()) do
		if v:GetNW2Bool("MDispatcher.ShowIntervals",false) then
			table.insert(need_plys,v)
		end
	end
	if table.Count(need_plys) > 0 then
		local intervals = MDispatcher.GetIntervals()
		for k,v in ipairs(need_plys) do
			MDispatcher.SendIntervals(v,intervals)
		end
	end
end)

-- получить интервал движения в секундах
local function GetIntervalSec()
	local int = MDispatcher.Interval:Split(".")
	return (tonumber(int[1])*60) + tonumber(int[2])
end

-- генерируем расписание
function MDispatcher.GenerateSimpleSched(station_start,path,back_time, station_last,holds)
	if table.Count(MDispatcher.Stations) == 0 then return end
	local line_id = math.floor(station_start/100)
	local init_node_id = MDispatcher.Stations[line_id][path][station_start].NodeID
	local init_clock = IsValid(MDispatcher.Stations[line_id][path][station_start].Clock) and MDispatcher.Stations[line_id][path][station_start].Clock
	local prev_node
	local last_node_id = station_last and MDispatcher.Stations[line_id][path][station_last].NodeID or MDispatcher.Stations[line_id][path][GetLastStationID(line_id,path)].NodeID
	local sched_massiv = {}
	local station_time = 40
	local init_time = back_time and back_time - 10 or MDispatcher.RoundSeconds(ConvertTime()) + (station_time/2)
	if init_clock != nil and GetIntervalTime(init_clock) > 0 and GetIntervalTime(init_clock) < GetIntervalSec() then
		init_time = init_time + MDispatcher.RoundSeconds((GetIntervalSec() - GetIntervalTime(init_clock)))
	end
	local travel_time
	local hold_time
	local full_time
	local back_time
	
	for k, v in SortedPairsByMemberValue(MDispatcher.Stations[line_id][path], "NodeID") do
		if v.NodeID < init_node_id then continue end
		if v.NodeID == init_node_id then
			travel_time = 10
			full_time = travel_time
			table.insert(sched_massiv, {ID = k, Name = v.Name, Time = MDispatcher.RoundSeconds(init_time + full_time), State = "cur"})
			prev_node = v.Node
			continue
		end
		if v.NodeID > init_node_id and v.NodeID < last_node_id then
			if holds and holds[k] then hold_time = holds[k] else hold_time = 0 end
			travel_time = Metrostroi.GetTravelTime(prev_node,v.Node) + station_time + hold_time
			full_time = MDispatcher.RoundSeconds(full_time + travel_time)
		end
		if v.NodeID == last_node_id then
			travel_time = Metrostroi.GetTravelTime(prev_node,v.Node) + (station_time/2)
			full_time = MDispatcher.RoundSeconds(full_time + travel_time)
			table.insert(sched_massiv, {ID = k, Name = v.Name, Time = MDispatcher.RoundSeconds(init_time + full_time), State = ""})
			break
		end
		table.insert(sched_massiv, {ID = k, Name = v.Name, Time = MDispatcher.RoundSeconds(init_time + full_time), State = ""})
		prev_node = v.Node
	end
	back_time = MDispatcher.RoundSeconds(init_time + full_time + 240)
	full_time = MDispatcher.RoundSeconds(full_time - 10)
	return sched_massiv, full_time, back_time, holds and holds or {}
end

-- Определяем класс сигналов на карте
function MDispatcher.GetSignalClass()
	local defaultClass = MDispatcher.SignalClass
	for k, v in pairs(scripted_ents.GetList()) do
		if v.t.ClassName:find(defaultClass) and not v.t.ClassName:find("controller") and not v.t.ClassName:find("msa") then
			if v.t.ClassName ~= defaultClass then
				MDispatcher.SignalClass = v.t.ClassName
				break
			end
		end
	end
end

-- Дебаг в консоль сервера
local function PrintDebugInfo()
	if debug_enabled:GetInt() == 0 then return end
	if table.Count(MDispatcher.Stations) == 0 then return end
	if not Metrostroi.StationConfigurations then return end
	print("")
	print("===== MDispatcher Debug START =====")
	print("")
	print("--------------")
	print("Stations Table:")
	print("--------------")
	print("")
	for a,b in pairs(MDispatcher.Stations) do
		print("Line: "..a.."\n")
		for c,d in pairs(b) do
			print("Path: "..c)
			for k,v in SortedPairsByMemberValue(d, "NodeID") do
				print("ID: "..k.."| Name: "..v.Name.." | Node: "..v.NodeID.." | Clock: "..(IsValid(v.Clock) and v.Clock:EntIndex() or "Not Founded"))
			end
			print("")
		end
	end
	print("---------------------")
	print("StationConfigurations:")
	print("---------------------")
	print("")
	local stationstable = {}
	for k,v in pairs(Metrostroi.StationConfigurations) do
		table.insert(stationstable,{id = tostring(k), name = tostring(v.names[1])})
	end 
	table.SortByMember(stationstable, "id",true)
	for k,v in pairs(stationstable) do
		print(v.id.." - "..v.name)
	end
	print("---------------------")
	print("")
	print("===== MDispatcher Debug END =====")
	print("")
end

-- фиксы на картах
local function PLLFix()
	local already_fixed = false -- фикс повторной сработки во время игры
	for _, ent in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(ent) then continue end
		
		-- фикс координат на 158/2
		if ent.StationIndex == 158 and ent.PlatformIndex == 2 then
			ent:SetPos(ent:GetPos()+Vector(0,-100,0))
			ent.PlatformStart = Vector(28.43,14169.9,-6786.97)
			ent:SetNW2Vector("PlatformStart",ent.PlatformStart)
			ent.PlatformEnd = Vector(4955.4,14174.3,-6786.97)
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

local function CrosslineFix()
	for _, ent in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(ent) then continue end
		if ent.StationIndex == 112 then
			if ent.PlatformIndex == 2 then
					ent.PlatformIndex = 3
					ent:SetNWInt("PlatformIndex",ent.PlatformIndex)
					ent:SetPos(Vector(-22.049999,-14800,-13601.968750))
			end
			if ent.PlatformIndex == 4 then
				ent.PlatformIndex = 2
				ent:SetNWInt("PlatformIndex",ent.PlatformIndex)
			end
		end
	end
end

local function CrosslineReduxFix()
	for _, ent in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(ent) then continue end
		if ent.StationIndex > 107 then
			ent.StationIndex = ent.StationIndex - 9
			ent:SetNWInt("StationIndex",ent.StationIndex)
		end
	end
end

local function NVLFix()
	local already_fixed = false -- фикс повторной сработки во время игры
	for _, ent in pairs(ents.FindByClass("gmod_track_platform")) do
		if not IsValid(ent) then continue end
		-- отделяем 2 линию
		if ent.StationIndex > 900 then already_fixed = 1 break end
		if ent.StationIndex > 810 then
			ent.StationIndex = ent.StationIndex+100
			ent:SetNWInt("StationIndex",ent.StationIndex)
		end
	end
	
	if already_fixed then return end
	local StationConfig = {}
	for k,v in pairs(Metrostroi.StationConfigurations) do
		if not tonumber(k) or k <= 810 then StationConfig[k] = v continue end
		if k > 810 then StationConfig[k+100] = v end
	end
	Metrostroi.StationConfigurations = StationConfig
	StationConfig = nil
end

hook.Add("Initialize", "MDispatcher_MapInitialize", function()
	if game.GetMap():find("jar_pll_remastered") then timer.Simple(1,PLLFix) end
	if game.GetMap():find("crossline_n") then timer.Simple(1,CrosslineFix) end
	if game.GetMap():find("crossline_r199h") then timer.Simple(1,CrosslineReduxFix) end
	if game.GetMap():find("metronvl") then timer.Simple(1,NVLFix) end
end)

-- запуск сбора данных
timer.Simple(10,BuildStationsTable)
timer.Simple(10+2,PrintDebugInfo)
