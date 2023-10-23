------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
local SchedPanel = {}
local height = 50

local function ClearSchedule()
	if IsValid(MDispatcher.SPanel) then
		MDispatcher.SPanel:Remove()
		MDispatcher.SPanel = nil
	end
	height = 50
	MDispatcher.SPanel = vgui.Create("MDispatcher.SchedulePanel")
end

function SchedPanel:Init()
	self.Stations = vgui.Create("DScrollPanel",self)
	self.Times = vgui.Create("DScrollPanel",self)
	self.Holds = vgui.Create("DScrollPanel",self)
	self.Comment = vgui.Create("DLabel",self)
	self.Comment:SetPos(10,25)
	self.Comment:SetFont("MDispSmallIt")
	self.Comment:SetText("Нет активного расписания.")
	self.Comment:SetTextColor(Color(255,255,255))
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

	local sb1 = self.Stations:GetVBar()
	sb1:SetSize(0,0)
	local sb2 = self.Times:GetVBar()
	sb2:SetSize(0,0)
	local sb3 = self.Holds:GetVBar()
	sb3:SetSize(0,0)

	self.Comment:SetWide(230)
	self.Route:SetPos(10,5)
	self.Route:SetWide(110)
	self.Route:SetTextColor(Color(255,255,255))
	self.FTime:SetTextColor(Color(255,255,255))
	self.FTime:SetWide(130)
	self.FTime:SetPos(120,5)
end

local row_colors = {prev = Color(90,90,90), cur = Color(0,160,0), cur_late = Color(255,117,25), next = Color(0,148,255)}
function SchedPanel:AddRow(nm,tm,st,hl,sp)
	local lb1 = self.Stations:Add("DLabel")
	if not sp then lb1:SetFont("MDispSmall")
	else lb1:SetFont("MDispSmallTitle") end
	lb1:SetText(nm)
	lb1:SetTextColor(row_colors[st] or Color(255,255,255))
	lb1:Dock(TOP)
	if not sp then lb1:DockMargin(0,0,0,2)
	else lb1:DockMargin(0,-4,0,-4) end
	local lb2 = self.Times:Add("DLabel")
	lb2:SetFont("MDispSmall")
	lb2:SetText(tm)
	lb2:SetTextColor(row_colors[st] or Color(255,255,255))
	lb2:Dock(TOP)
	if not sp then lb2:DockMargin(0,0,0,2)
	else lb2:DockMargin(0,-4,0,-4) end
	if hl then
		local lb3 = self.Holds:Add("DLabel")
		lb3:SetFont("MDispSmall")
		local m,s
		if hl > 0 then
			if hl > 60 then
				m = math.floor(hl/60)
				s = hl-(60*m)
				if s < 10 then s = "0"..s end
				hl = m.."."..s
			elseif hl == 60 then
				hl = "1м"
			elseif hl < 60 then
				hl = hl.."с"
			end
			lb3:SetText(hl)
		else
			lb3:SetText("")
		end
		lb3:SetTextColor(Color(255,216,0))
		lb3:Dock(TOP)
		lb3:DockMargin(0,0,0,2)
	end
end

function SchedPanel:Update(schedule)
	local scrolls_y = 35
	self.Comment:SetVisible(false)
	height = 35
	if schedule.comm ~= "" then
		self.Comment:SetVisible(true)
		self.Comment:SetPos(10,30)
		self.Comment:SetText(schedule.comm)
		self.Comment:SetTextColor(Color(255,102,0))
		scrolls_y = 50
		height = 50
	end
	
	self.FTime:SetText("Время хода: "..os.date("%M:%S",schedule.ftime))
	self.Stations:Clear()
	self.Stations:SetPos(10,scrolls_y)
	self.Times:Clear()
	self.Holds:Clear()
	self.Holds:SetPos(220,scrolls_y)
	
	local hl = false
	for k,v in pairs(schedule.holds) do
		if v > 0 then hl = true break end
	end
	if hl then
		self.Times:SetPos(163,scrolls_y)
	else
		self.Times:SetPos(194,scrolls_y)
	end
	for k,v in pairs(schedule.table) do
		self:AddRow(v.Name, os.date("!%X", v.Time), v.State, hl and schedule.holds[v.ID] or false)
		height = height + 22
		self.Stations:SetSize(hl and 150 or 182,height)
		self.Times:SetSize(50,height)
		self.Holds:SetSize(hl and 30 or 0,hl and height or 0)
	end
	self:AddRow("", "", "", false, true)
	self:AddRow("Отправление", os.date("!%X", schedule.btime), "", false, true)
	height = height + 34
	self.Stations:SetSize(hl and 150 or 182,height)
	self.Times:SetSize(50,height)
	self.Holds:SetSize(hl and 30 or 0,hl and height or 0)
end
vgui.Register("MDispatcher.SchedulePanel",SchedPanel,"Panel")

net.Receive("MDispatcher.ScheduleData",function()
	local ln = net.ReadUInt(32)
	local tbl = util.JSONToTable(util.Decompress(net.ReadData(ln)))
	if not IsValid(MDispatcher.SPanel) then return end
	MDispatcher.SPanel:Update(tbl)
end)

net.Receive("MDispatcher.ClearSchedule",function()
	ClearSchedule()
end)