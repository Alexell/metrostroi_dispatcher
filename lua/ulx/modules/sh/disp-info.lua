-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexell/

timer.Simple(1,function()
	if dispinfo then
		local disp = ulx.command(dispinfo.category, "ulx disp", dispinfo.disp, "!disp")
		disp:defaultAccess(ULib.ACCESS_SUPERADMIN)
		disp:help("Занять пост ДЦХ.")
		
		local setdisp = ulx.command(dispinfo.category, "ulx setdisp", dispinfo.setdisp, "!setdisp")
		setdisp:addParam{ type=ULib.cmds.PlayerArg }
		setdisp:defaultAccess(ULib.ACCESS_SUPERADMIN)
		setdisp:help("Назначить на пост ДЦХ.")
	
		local undisp = ulx.command(dispinfo.category, "ulx undisp", dispinfo.undisp, "!undisp")
		undisp:defaultAccess(ULib.ACCESS_SUPERADMIN)
		undisp:help("Освободить пост ДЦХ.")

		local setint = ulx.command(dispinfo.category, "ulx setint", dispinfo.setint, "!int")
		setint:addParam{ type=ULib.cmds.StringArg, hint="2.30",ULib.cmds.optional}
		setint:defaultAccess(ULib.ACCESS_SUPERADMIN)
		setint:help("Установить интервал движения. Формат - мин.сек")
	end
end)