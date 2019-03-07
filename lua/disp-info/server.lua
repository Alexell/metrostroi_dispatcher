﻿﻿-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexell/

if CLIENT then return end
cur_dis = "отсутствует"
cur_int = "2.00"

function dispinfo.disp(ply)
	cur_dis = ply:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера в "..os.date("%H:%M").."."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
end

function dispinfo.setdisp(ply,target)
	cur_dis = target:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера в "..os.date("%H:%M").."."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
end

function dispinfo.undisp(ply)
	if cur_dis != "отсутствует" then
		if cur_dis == ply:Nick() then
			local msg = "игрок "..cur_dis.." покинул пост Диспетчера в "..os.date("%H:%M").."."
			cur_dis = "отсутствует"
			ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		else
			if (ply:IsAdmin()) then
				local msg = ply:Nick().." снял игрока "..cur_dis.." с поста Диспетчера в "..os.date("%H:%M").."."
				cur_dis = "отсутствует"
				ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
			else
				ply:PrintMessage(HUD_PRINTTALK,"Вы не можете покинуть пост, поскольку вы не на посту! Сейчас диспетчер "..cur_dis..".")
			end
		end
	else
		ply:PrintMessage(HUD_PRINTTALK,"Диспетчер на посту отсутствует!")
	end
end

function dispinfo.setint(ply,mins)
	if cur_dis == ply:Nick() then
		cur_int = string.Replace(mins,":",".")
		local msg = "Диспетчер установил интервал движения "..cur_int
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	else
		ply:PrintMessage(HUD_PRINTTALK,"Вы не можете изменить интервал, поскольку вы не на посту! Сейчас диспетчер "..cur_dis..".")
	end
end

hook.Add( "PlayerDisconnected", "PlyDisconnect", function(ply) --снимаем с поста при отключении
	if cur_dis == ply:Nick() then
		cur_dis = "отсутствует"
		local msg = "игрок "..ply:Nick().." покинул пост Диспетчера в "..os.date("%H:%M").." (отключился с сервера)."
		ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	end
end)

function dispinfo.updater(ply)
	for k,v in pairs(player.GetAll()) do
		if (not ply or ply == v) then
			umsg.Start("DispInfoUpdater",v)
				umsg.String(cur_dis)
				umsg.String(cur_int)
			umsg.End()
		end
	end
end
timer.Create("UpdateCurValues",1,0,dispinfo.updater)