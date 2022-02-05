--------------------------- Metrostroi Dispatcher --------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
local CATEGORY_NAME = "Metrostroi Dispatcher"

function ulx.disp(calling_ply)
	MDispatcher.Disp(calling_ply)
end
local disp = ulx.command(CATEGORY_NAME,"ulx disp",ulx.disp,"!disp")
disp:defaultAccess(ULib.ACCESS_SUPERADMIN)
disp:help("Занять пост ДЦХ.")

function ulx.setdisp(calling_ply,target_ply)
	MDispatcher.SetDisp(calling_ply,target_ply)
end
local setdisp = ulx.command(CATEGORY_NAME,"ulx setdisp",ulx.setdisp,"!setdisp")
setdisp:addParam{type=ULib.cmds.PlayerArg}
setdisp:defaultAccess(ULib.ACCESS_SUPERADMIN)
setdisp:help("Назначить на пост ДЦХ.")

function ulx.undisp(calling_ply)
	MDispatcher.UnDisp(calling_ply)
end
local undisp = ulx.command(CATEGORY_NAME,"ulx undisp",ulx.undisp,"!undisp")
undisp:defaultAccess(ULib.ACCESS_SUPERADMIN)
undisp:help("Освободить пост ДЦХ.")

function ulx.setint(calling_ply,interval)
	MDispatcher.SetInt(calling_ply,interval)
end
local setint = ulx.command(CATEGORY_NAME,"ulx setint",ulx.setint,"!int")
setint:addParam{type=ULib.cmds.StringArg,hint="2.30",ULib.cmds.optional}
setint:defaultAccess(ULib.ACCESS_SUPERADMIN)
setint:help("Установить интервал движения. Формат - мин.сек")

function ulx.getsched(calling_ply)
	if not IsValid(calling_ply) then return end
    local train = calling_ply:GetTrain()
	if not IsValid(train) then
		calling_ply:ChatPrint("Поезд не обнаружен!\nПолучить расписание можно только находясь в кресле машиниста.")
		return
	end
	local station = train:ReadCell(49160)
	if not Metrostroi.StationConfigurations[station] then
		calling_ply:ChatPrint("Станция не обнаружена!\nПолучить расписание можно только находясь на станции.")
		return
	end
	local path = train:ReadCell(49168)
	if path == 0 then
		calling_ply:ChatPrint("Не удалось получить номер пути!")
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
	net.Send(calling_ply)
end
local getsched = ulx.command(CATEGORY_NAME,"ulx getsched",ulx.getsched,"!sget")
getsched:defaultAccess(ULib.ACCESS_ALL)
getsched:help("Получить расписание")