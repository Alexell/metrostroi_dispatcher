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
disp:defaultAccess(ULib.ACCESS_ADMIN)
disp:help("Занять пост ДЦХ.")

function ulx.setdisp(calling_ply,target_ply)
	MDispatcher.SetDisp(calling_ply,target_ply)
end
local setdisp = ulx.command(CATEGORY_NAME,"ulx setdisp",ulx.setdisp,"!setdisp")
setdisp:addParam{type=ULib.cmds.PlayerArg}
setdisp:defaultAccess(ULib.ACCESS_ADMIN)
setdisp:help("Назначить на пост ДЦХ.")

function ulx.undisp(calling_ply)
	MDispatcher.UnDisp(calling_ply)
end
local undisp = ulx.command(CATEGORY_NAME,"ulx undisp",ulx.undisp,"!undisp")
undisp:defaultAccess(ULib.ACCESS_ADMIN)
undisp:help("Освободить пост ДЦХ.")

function ulx.setint(calling_ply,interval)
	MDispatcher.SetInt(calling_ply,interval)
end
local setint = ulx.command(CATEGORY_NAME,"ulx setint",ulx.setint,"!int")
setint:addParam{type=ULib.cmds.StringArg,hint="2.30",ULib.cmds.optional}
setint:defaultAccess(ULib.ACCESS_ADMIN)
setint:help("Установить интервал движения. Формат - мин.сек")

function ulx.getsched(calling_ply)
	MDispatcher.GetSchedule(calling_ply)
end
local getsched = ulx.command(CATEGORY_NAME,"ulx getsched",ulx.getsched,"!sget")
getsched:defaultAccess(ULib.ACCESS_ALL)
getsched:help("Получить расписание")

function ulx.clearsched(calling_ply)
	MDispatcher.ClearSchedule(calling_ply)
end
local clearsched = ulx.command(CATEGORY_NAME,"ulx clearsched",ulx.clearsched,"!sclear")
clearsched:defaultAccess(ULib.ACCESS_ALL)
clearsched:help("Очистить расписание")

function ulx.dispmenu(calling_ply)
	MDispatcher.DispatcherMenu(calling_ply)
end
local dispmenu = ulx.command(CATEGORY_NAME,"ulx dispmenu",ulx.dispmenu,"!dmenu")
dispmenu:defaultAccess(ULib.ACCESS_ADMIN)
dispmenu:help("Меню диспетчера")