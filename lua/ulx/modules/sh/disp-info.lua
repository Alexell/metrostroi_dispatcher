-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexellpro/

local CATEGORY_NAME = "Metrostroi"

function ulx.disp(calling_ply)
	DispInfo.disp(calling_ply)
end
local disp = ulx.command(CATEGORY_NAME,"ulx disp",ulx.disp,"!disp")
disp:defaultAccess(ULib.ACCESS_SUPERADMIN)
disp:help("Занять пост ДЦХ.")

function ulx.setdisp(calling_ply,target_ply)
	DispInfo.setdisp(calling_ply,target_ply)
end
local setdisp = ulx.command(CATEGORY_NAME,"ulx setdisp",ulx.setdisp,"!setdisp")
setdisp:addParam{type=ULib.cmds.PlayerArg}
setdisp:defaultAccess(ULib.ACCESS_SUPERADMIN)
setdisp:help("Назначить на пост ДЦХ.")

function ulx.undisp(calling_ply)
	DispInfo.undisp(calling_ply)
end
local undisp = ulx.command(CATEGORY_NAME,"ulx undisp",ulx.undisp,"!undisp")
undisp:defaultAccess(ULib.ACCESS_SUPERADMIN)
undisp:help("Освободить пост ДЦХ.")

function ulx.setint(calling_ply,interval)
	DispInfo.setint(calling_ply,interval)
end
local setint = ulx.command(CATEGORY_NAME,"ulx setint",ulx.setint,"!int")
setint:addParam{type=ULib.cmds.StringArg,hint="2.30",ULib.cmds.optional}
setint:defaultAccess(ULib.ACCESS_SUPERADMIN)
setint:help("Установить интервал движения. Формат - мин.сек")
