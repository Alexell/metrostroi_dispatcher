-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexell/

surface.CreateFont( "Font", {
font = "Trebuchet Bold",
extended = false,
size = 17,
weight = 600
} )

local ply = LocalPlayer()
local dis_nick = "отсутствует"
local dis_int = "2:00"

local function receivedata(um)
	dis_nick = um:ReadString()
	dis_int = um:ReadString()
end
usermessage.Hook("DispInfoUpdater", receivedata)

function DrawHUD()
	local ply = LocalPlayer()
    draw.RoundedBox(10, ScrW()-250, ScrH()-(ScrH()/2)-100,250,70,Color(0,0,0,80))
    draw.SimpleText("Диспетчер: " .. dis_nick,"Font",ScrW()-230,ScrH()-(ScrH()/2)-90,Color(255,255,255,255),TEXT_ALIGN_LEFT)
    draw.SimpleText("Интервал движения: " .. dis_int,"Font",ScrW()-230,ScrH()-(ScrH()/2)-60,Color(255,255,255,255),TEXT_ALIGN_LEFT)
end
hook.Add('HUDPaint','DisHUD',DrawHUD)
