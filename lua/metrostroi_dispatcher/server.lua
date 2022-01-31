--------------------------- Metrostroi Dispatcher --------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------

util.AddNetworkString("MDispatcher.MainData")
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
