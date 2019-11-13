-- Disp-Info (addon for Metrostroi)
-- Автор: Alexell
-- Steam: https://steamcommunity.com/id/alexell/

surface.CreateFont("DispMain",{
font = "Trebuchet Bold",
extended = false,
size = 17,
weight = 600
})

local ply = LocalPlayer()
local dis_nick = "отсутствует"
local str_int = "Мин. интервал"
local dis_int = "1.45"

local function DispInfoInit()
	if DispInfo.Panel then
		DispInfo.Panel:Remove()
		DispInfo.Panel = nil
	end
	DispInfo.Panel = vgui.Create("DispInfoPanel")
	hook.Remove("InitPostEntity","DispInfo.Init")
end
hook.Add("InitPostEntity","DispInfo.Init",DispInfoInit)

net.Receive("DispInfo.ServerData",function()
	dis_nick = net.ReadString()
	str_int = net.ReadString()
	dis_int = net.ReadString()
	
	if DispInfo.Panel == nil or not IsValid(LocalPlayer()) then return end
	if (IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_camera") then
		DispInfo.Panel:SetVisible(false)
	else
		DispInfo.Panel:SetVisible(true)
	end
	if DispInfo.Panel then
		DispInfo.Panel.Disp:SetText("Диспетчер: "..dis_nick)
		DispInfo.Panel.Int:SetText(str_int..": "..dis_int)
	end
end)

local DP = {}

function DP:Init()
	self.Disp = vgui.Create("DLabel",self)
	self.Disp:SetFont("DispMain")
	self.Int = vgui.Create("DLabel",self)
	self.Int:SetFont("DispMain")
end

function DP:Paint(w,h)
	draw.RoundedBox(5,0,0,w,h,Color(0,0,0,150))
end

function DP:PerformLayout()
	self:SetSize(250,50)
	self:SetPos(ScrW() - self:GetWide() - 5,ScrH() - (ScrH()/2) - (self:GetTall()/2))
	self.Disp:SetPos(10,5)
	self.Disp:SetTextColor(Color(255,255,255,255))
	self.Disp:SetWide(240)
	self.Int:SetWide(240)
	self.Int:SetPos(10,25)
	self.Int:SetTextColor(Color(255,255,255,255))
end
vgui.Register("DispInfoPanel",DP,"Panel")
