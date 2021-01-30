-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexellpro/

if CLIENT then return end
util.AddNetworkString("DispInfo.ServerData")
local cur_dis = "отсутствует"
local str_int = "Мин. интервал"
local cur_int = "1.45"

-- проверенные интервалы по картам
local map = game.GetMap()
if map:find("gm_smr_first_line") then cur_int = "3.00" end
if map:find("gm_mus_loopline") then cur_int = "3.00" end

function DispInfo.disp(ply)
	cur_dis = ply:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	hook.Run("DispInfoTookPost",cur_dis)
end

function DispInfo.setdisp(ply,target)
	cur_dis = target:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	hook.Run("DispInfoTookPost",cur_dis)
end

function DispInfo.undisp(ply)
	if cur_dis != "отсутствует" then
		if cur_dis == ply:Nick() then
			hook.Run("DispInfoFreedPost",cur_dis)
			local msg = "игрок "..cur_dis.." покинул пост Диспетчера."
			cur_dis = "отсутствует"
			str_int = "Мин. интервал"
			cur_int = "1.45"
			ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		else
			if (ply:IsAdmin()) then
				hook.Run("DispInfoFreedPost",cur_dis)
				local msg = ply:Nick().." снял игрока "..cur_dis.." с поста Диспетчера."
				cur_dis = "отсутствует"
				str_int = "Мин. интервал"
				cur_int = "1.45"
				ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
			else
				ply:PrintMessage(HUD_PRINTTALK,"Вы не можете покинуть пост, поскольку вы не на посту! Сейчас диспетчер "..cur_dis..".")
			end
		end
		
	else
		ply:PrintMessage(HUD_PRINTTALK,"Диспетчер на посту отсутствует!")
	end
end

function DispInfo.setint(ply,mins)
	if cur_dis == ply:Nick() then
		cur_int = string.Replace(mins,":",".")
		str_int = "Интервал движения"
		local msg = "Диспетчер "..cur_dis.." установил интервал движения "..cur_int
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		hook.Run("DispInfoSetInt",cur_dis,cur_int)
	else
		ply:PrintMessage(HUD_PRINTTALK,"Вы не можете изменить интервал, поскольку вы не на посту! Сейчас диспетчер "..cur_dis..".")
	end
end

hook.Add( "PlayerDisconnected", "PlyDisconnect", function(ply) --снимаем с поста при отключении
	if cur_dis == ply:Nick() then
		hook.Run("DispInfoFreedPost",cur_dis)
		cur_dis = "отсутствует"
		str_int = "Мин. интервал"
		cur_int = "1.45"
		local msg = "игрок "..ply:Nick().." покинул пост Диспетчера (отключился с сервера)."
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	end
end)

local function Updater()
	net.Start("DispInfo.ServerData")
		net.WriteString(cur_dis)
		net.WriteString(str_int)
		net.WriteString(cur_int)
	net.Broadcast()
end
timer.Create("UpdateCurValues",1,0,Updater)