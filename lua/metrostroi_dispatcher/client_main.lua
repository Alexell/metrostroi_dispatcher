--------------------------- Metrostroi Dispatcher --------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
CreateClientConVar("disp_showpanel",1,true,false)

surface.CreateFont("MDispMain",{
font = "Trebuchet Bold",
extended = false,
size = 17,
weight = 600
})

local dis_nick = "отсутствует"
local str_int = "Мин. интервал"
local dis_int = "1.45"

local function MDispatcherSetData()
	if not IsValid(MDispatcher.DPanel) then return end
	MDispatcher.DPanel.Disp:SetText("Диспетчер: "..dis_nick)
	MDispatcher.DPanel.Int:SetText(str_int..": "..dis_int)
	
	if dis_nick ~= "отсутствует" then RunConsoleCommand("disp_showpanel",1) end
end

local function MDispatcherInit()
	if MDispatcher.DPanel then
		MDispatcher.DPanel:Remove()
		MDispatcher.DPanel = nil
	end
	MDispatcher.DPanel = vgui.Create("MDispatcher.DispPanel")
	MDispatcherSetData()
	hook.Remove("InitPostEntity","MDispatcher.Init")
end
hook.Add("InitPostEntity","MDispatcher.Init",MDispatcherInit)

net.Receive("MDispatcher.MainData",function()
	dis_nick = net.ReadString()
	str_int = net.ReadString()
	dis_int = net.ReadString()
	MDispatcherSetData()
end)

cvars.AddChangeCallback("disp_showpanel",function(cvar,old,new)
	if (old == new) then return end
	if (dis_nick ~= "отсутствует" and not tobool(new)) then
		LocalPlayer():PrintMessage(HUD_PRINTTALK,"Нельзя скрывать панель, когда диспетчер на посту!")
		RunConsoleCommand("disp_showpanel",1)
	end
	MDispatcher.DPanel:SetVisible(tobool(new))
end)

local DispPanel = {}

function DispPanel:Init()
	self.Disp = vgui.Create("DLabel",self)
	self.Disp:SetFont("MDispMain")
	self.Int = vgui.Create("DLabel",self)
	self.Int:SetFont("MDispMain")
end

function DispPanel:Paint(w,h)
	draw.RoundedBox(5,0,0,w,h,Color(0,0,0,150))
end

function DispPanel:PerformLayout()
	self:SetSize(250,50)
	self:SetPos(ScrW() - self:GetWide() - 5,ScrH() - (ScrH()/2) - (self:GetTall()/2))
	self.Disp:SetPos(10,5)
	self.Disp:SetTextColor(Color(255,255,255,255))
	self.Disp:SetWide(240)
	self.Int:SetWide(240)
	self.Int:SetPos(10,25)
	self.Int:SetTextColor(Color(255,255,255,255))
end
vgui.Register("MDispatcher.DispPanel",DispPanel,"Panel")

timer.Create("MDispatcher.SetVisible",1,0,function()
	if (not IsValid(MDispatcher.DPanel) or not IsValid(LocalPlayer())) then return end
	if ((not GetConVar("disp_showpanel"):GetBool()) or (IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_camera")) then
		MDispatcher.DPanel:SetVisible(false)
	else
		MDispatcher.DPanel:SetVisible(true)
	end
end)
