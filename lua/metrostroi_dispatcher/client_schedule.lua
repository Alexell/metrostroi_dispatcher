local SchedPanel = {}
local height = 50

function SchedPanel:Init()
	self.Stations = vgui.Create("DScrollPanel",self)
	self.Times = vgui.Create("DScrollPanel",self)
	self.Default = vgui.Create("DLabel",self)
	self.Default:SetFont("MDispSmallTitle")
	self.Route = vgui.Create("DLabel",self)
	self.Route:SetFont("MDispSmallTitle")
	self.Route:SetText("")
	self.FTime = vgui.Create("DLabel",self)
	self.FTime:SetFont("MDispSmallTitle")
	self.FTime:SetText("")
end
function SchedPanel:Paint(w,h)
	draw.RoundedBox(5,0,0,w,h,Color(0,0,0,150))
end
function SchedPanel:PerformLayout()
	self:SetSize(250,height)
	self:SetPos(ScrW() - self:GetWide() - 5, ScrH() - (ScrH()/2) + 5)
	
	self.Stations:SetPos(10,35)
	self.Times:SetPos(194,35)
	local sb1 = self.Stations:GetVBar()
	sb1:SetSize(0,0)
	local sb2 = self.Times:GetVBar()
	sb2:SetSize(0,0)	

	self.Default:SetPos(10,25)
	self.Default:SetWide(200)
	self.Default:SetText("Нет активного расписания.")
	self.Route:SetPos(10,5)
	self.Route:SetWide(110)
	self.FTime:SetPos(120,5)
	self.FTime:SetWide(130)
	
end

function SchedPanel:AddRow(nm,tm,sp)
	local lb1 = self.Stations:Add("DLabel")
	if not sp then lb1:SetFont("MDispSmall")
	else lb1:SetFont("MDispSmallTitle") end
	lb1:SetText(nm)
	lb1:Dock(TOP)
	if not sp then lb1:DockMargin(0,0,0,2)
	else lb1:DockMargin(0,-4,0,-4) end
	local lb2 = self.Times:Add("DLabel")
	lb2:SetFont("MDispSmall")
	lb2:SetText(tm)
	lb2:Dock(TOP)
	if not sp then lb2:DockMargin(0,0,0,2)
	else lb2:DockMargin(0,-4,0,-4) end
end

function SchedPanel:Update(sched,ftime,btime)
	self.Default:SetVisible(false)
	self.FTime:SetText("Время хода: "..os.date("%M:%S",ftime))
	self.Stations:Clear()
	self.Times:Clear()
	height = 35
	for k,v in pairs(sched) do
		self:AddRow(v.Name,v.Time)
		height = height + 22
		self.Stations:SetSize(110,height)
		self.Times:SetSize(110,height)
	end
	self:AddRow("","",true)
	self:AddRow("Отправление",btime,true)
	height = height + 34
	self.Stations:SetSize(110,height)
	self.Times:SetSize(110,height)
	timer.Remove("MDispatcher.ResetSchedule")
	timer.Create("MDispatcher.ResetSchedule",ftime+60,1,function()
		MDispatcher.SPanel:Remove()
		MDispatcher.SPanel = nil
		height = 50
		timer.Simple(1,function()
			MDispatcher.SPanel = vgui.Create("MDispatcher.SchedulePanel")
		end)
	end)
end
vgui.Register("MDispatcher.SchedulePanel",SchedPanel,"Panel")

net.Receive("MDispatcher.ScheduleData",function()
	local ln = net.ReadUInt(32)
	local tbl = util.JSONToTable(util.Decompress(net.ReadData(ln)))
	local ft = net.ReadString()
	local bt = net.ReadString()
	MDispatcher.SPanel:Update(tbl,ft,bt)
end)