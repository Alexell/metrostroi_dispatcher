-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexell/

if CLIENT then return end
cur_dis = "отсутствует"
cur_int = "2.00"

-- проверенные интервалы по картам
local map = game.GetMap()
if map:find("gm_jar_pll_remastered") then cur_int = "2.00" end
if map:find("gm_metro_jar_imagine_line") then cur_int = "2.20" end
if map:find("gm_mustox_neocrimson_line") then cur_int = "1.40" end
if map:find("gm_smr_first_line") then cur_int = "4.00" end
if map:find("gm_metro_crossline") then cur_int = "2.30" end
if map:find("gm_mus_loopline") then cur_int = "3.30" end
if map:find("gm_metro_surfacemetro") then cur_int = "1.45" end
if map:find("gm_mus_neoorange") then cur_int = "1.50" end
if map:find("gm_metro_virus_v1") then cur_int = "2.20" end

function dispinfo.disp(ply)
	cur_dis = ply:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	hook.Run("DispInfoTookPost",cur_dis)
end

function dispinfo.setdisp(ply,target)
	cur_dis = target:Nick()
	local msg = "игрок "..cur_dis.." заступил на пост Диспетчера."
	ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
	hook.Run("DispInfoTookPost",cur_dis)
end

function dispinfo.undisp(ply)
	if cur_dis != "отсутствует" then
		if cur_dis == ply:Nick() then
			hook.Run("DispInfoFreedPost",cur_dis)
			local msg = "игрок "..cur_dis.." покинул пост Диспетчера."
			cur_dis = "отсутствует"
			ULib.tsayColor(nil,false,Color(255, 0, 0), "Внимание, машинисты: ",Color(0, 148, 255),msg)
		else
			if (ply:IsAdmin()) then
				hook.Run("DispInfoFreedPost",cur_dis)
				local msg = ply:Nick().." снял игрока "..cur_dis.." с поста Диспетчера."
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
		local msg = "игрок "..ply:Nick().." покинул пост Диспетчера (отключился с сервера)."
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