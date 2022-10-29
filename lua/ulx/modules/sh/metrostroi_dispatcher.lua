------------------------ Metrostroi Dispatcher -----------------------
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

function ulx.undisp(calling_ply)
	MDispatcher.UnDisp(calling_ply,false)
end
local undisp = ulx.command(CATEGORY_NAME,"ulx undisp",ulx.undisp,"!undisp")
undisp:defaultAccess(ULib.ACCESS_ADMIN)
undisp:help("Освободить пост ДЦХ.")

local wait = 30
local last = -wait
function ulx.getsched(calling_ply)
    if last + wait > CurTime() then
		calling_ply:ChatPrint("Пожалуйста, подождите еще "..math.Round(last + wait - CurTime()).." секунд(ы), перед запросом расписания!")
        return
    end
    last = CurTime()
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

function ulx.autosched(calling_ply)
	if calling_ply:GetInfoNum("mdispatcher_autochedule", 0) == 1 then
		calling_ply:ConCommand("mdispatcher_autochedule 0")
		calling_ply:ChatPrint("Автоматическая перевыдача расписания после оборота выключена")
	else
		calling_ply:ConCommand("mdispatcher_autochedule 1")
		calling_ply:ChatPrint("Автоматическая перевыдача расписания после оборота включена")
	end
end
local autosched = ulx.command(CATEGORY_NAME,"ulx autosched",ulx.autosched,"!sauto")
autosched:defaultAccess(ULib.ACCESS_ALL)
autosched:help("Вкл/выкл авто-перевыдачу раписания")
