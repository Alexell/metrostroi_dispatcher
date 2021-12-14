--------------------------- Metrostroi Dispatcher ---------------------------
-- Developer: Alexell | https://steamcommunity.com/profiles/76561198210303223
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
-----------------------------------------------------------------------------
local CATEGORY_NAME = "Metrostroi"

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
