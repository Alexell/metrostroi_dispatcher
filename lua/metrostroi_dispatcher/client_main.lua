------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
CreateClientConVar("disp_showpanel",1,true,false)
MDispatcher.Dispatcher = "отсутствует"
MDispatcher.Interval = "2.00"

surface.CreateFont("MDispMain",{
font = "Trebuchet Bold",
extended = false,
size = 16,
weight = 600
})

surface.CreateFont("MDispSmallTitle",{
font = "Trebuchet Bold",
extended = false,
size = 14,
weight = 600
})

surface.CreateFont("MDispSmall",{
font = "Trebuchet Bold",
extended = false,
size = 14,
weight = 500
})

local function DPanelSetData()
	if not IsValid(MDispatcher.DPanel) then return end
	MDispatcher.DPanel.Disp:SetText("Диспетчер: "..MDispatcher.Dispatcher)
	if MDispatcher.Dispatcher == "отсутствует" then
		MDispatcher.DPanel.Int:SetText("Интервал движения: "..MDispatcher.Interval.." (авто)")
	else
		MDispatcher.DPanel.Int:SetText("Интервал движения: "..MDispatcher.Interval)
		RunConsoleCommand("disp_showpanel",1)
	end
end

net.Receive("MDispatcher.InitialData",function()
	local ln = net.ReadUInt(32)
	MDispatcher.ControlRooms = util.JSONToTable(util.Decompress(net.ReadData(ln)))
	PrintTable(MDispatcher.ControlRooms)
	MDispatcher.Dispatcher = net.ReadString()
	MDispatcher.Interval = net.ReadString()
	local ln2 = net.ReadUInt(32)
	local nicks = util.JSONToTable(util.Decompress(net.ReadData(ln2)))

	if MDispatcher.DPanel then
		MDispatcher.DPanel:Remove()
		MDispatcher.DPanel = nil
	end
	MDispatcher.DPanel = vgui.Create("MDispatcher.DispPanel")
	DPanelSetData()
	
	if MDispatcher.SPanel then
		MDispatcher.SPanel:Remove()
		MDispatcher.SPanel = nil
	end
	MDispatcher.SPanel = vgui.Create("MDispatcher.SchedulePanel")

	if MDispatcher.DSCPPanel then
		MDispatcher.DSCPPanel:Remove()
		MDispatcher.DSCPPanel = nil
	end
	MDispatcher.DSCPPanel = vgui.Create("MDispatcher.DSCPPanel")
	MDispatcher.DSCPPanel:SetControlRooms()
	MDispatcher.DSCPPanel:Update(nicks)
end)

net.Receive("MDispatcher.DispData",function()
	MDispatcher.Dispatcher = net.ReadString()
	MDispatcher.Interval = net.ReadString()
	DPanelSetData()
end)

-- ДЦХ
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
	--self:SetPos(ScrW() - self:GetWide() - 5, ScrH() - (ScrH()/2) - self:GetTall() - 5)
	self:SetPos(ScrW() - self:GetWide() - 5, 200)
	self.Disp:SetPos(10,5)
	self.Disp:SetTextColor(Color(255,255,255,255))
	self.Disp:SetWide(240)
	self.Int:SetWide(240)
	self.Int:SetPos(10,25)
	self.Int:SetTextColor(Color(255,255,255,255))
end
vgui.Register("MDispatcher.DispPanel",DispPanel,"Panel")

local function GetRouteNumber(train)
	if not IsValid(train) then return end
	local rnum = train:GetNW2Int("RouteNumber",0)
	if table.HasValue({"gmod_subway_em508","gmod_subway_81-702","gmod_subway_81-703","gmod_subway_81-705_old","gmod_subway_ezh","gmod_subway_ezh3","gmod_subway_ezh3ru1","gmod_subway_81-717_mvm","gmod_subway_81-718","gmod_subway_81-720","gmod_subway_81-720_1","gmod_subway_81-720a","gmod_subway_81-717_freight"},train:GetClass()) then rnum = rnum / 10 end
	if rnum == 0 then
		rnum = train:GetNW2String("RouteNumbera","")
		if rnum == "" then rnum = 0 end
	end
	if rnum == 0 then
		rnum = train:GetNW2Int("RouteNumber:RouteNumber",0)
	end
	if rnum == 0 then
		rnum = train:GetNW2Int("ASNP:RouteNumber",0)
	end
	return rnum
end

timer.Create("MDispatcher.SetVisible",1,0,function()
	if (not IsValid(MDispatcher.DPanel) or not IsValid(MDispatcher.SPanel) or not IsValid(LocalPlayer())) then return end

	if (IsValid(LocalPlayer():GetActiveWeapon()) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_camera") then
		MDispatcher.DPanel:SetVisible(false)
		MDispatcher.SPanel:SetVisible(false)
	else
		if GetConVar("disp_showpanel"):GetBool() then
			MDispatcher.DPanel:SetVisible(true)
		else
			MDispatcher.DPanel:SetVisible(false)
		end
		if IsValid(LocalPlayer().InMetrostroiTrain) then
			MDispatcher.SPanel.Route:SetText("Маршрут: "..GetRouteNumber(LocalPlayer().InMetrostroiTrain))
			MDispatcher.SPanel:SetVisible(true)
		else
			MDispatcher.SPanel:SetVisible(false)
		end
	end
end)
