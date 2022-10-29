------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
local IntervalsPanel = {}
local height = 50

function IntervalsPanel:Init()
	self.Stations = vgui.Create("DScrollPanel",self)
	self.Path1 = vgui.Create("DScrollPanel",self)
	self.Path2 = vgui.Create("DScrollPanel",self)
	self.Title1 = vgui.Create("DLabel",self)
	self.Title1:SetFont("MDispSmallTitle")
	self.Title1:SetText("Станция")
	self.Title2 = vgui.Create("DLabel",self)
	self.Title2:SetFont("MDispSmallTitle")
	self.Title2:SetText("п. 1 | п. 2")
end
function IntervalsPanel:Paint(w,h)
	draw.RoundedBox(5,0,0,w,h,Color(0,0,0,150))
end
function IntervalsPanel:PerformLayout()
	self:SetSize(250,height)
	self:SetPos(ScrW() - self:GetWide() - 5, ScrH() - (ScrH()/2) + 5)

	local sb = self.Stations:GetVBar()
	sb:SetSize(0,0)
	local pb1 = self.Path1:GetVBar()
	pb1:SetSize(0,0)
	local pb2 = self.Path2:GetVBar()
	pb2:SetSize(0,0)

	self.Title1:SetPos(10,5)
	self.Title1:SetWide(90)
	self.Title1:SetTextColor(Color(255,255,255))
	self.Title2:SetTextColor(Color(255,255,255))
	self.Title2:SetWide(70)
	self.Title2:SetPos(173,5)
end

function IntervalsPanel:AddStation(name)
	local lb1 = self.Stations:Add("DLabel")
	lb1:SetFont("MDispSmall")
	lb1:SetText(name)
	lb1:SetTextColor(Color(255,255,255))
	lb1:Dock(TOP)
	lb1:DockMargin(0,0,0,2)
end

function IntervalsPanel:SetStations()
	self.Stations:Clear()
	self.Stations:SetPos(10,35)
	for k,v in pairs(MDispatcher.Stations) do
		self:AddStation(v.Name)
		height = height + 22
		self.Stations:SetSize(160,height)
	end
end

local function FormatInterval(int)
	if int < 0 or int > 599 then int = 0 end
	local mins = math.floor(int / 60)
	local secs = math.floor(int) - mins * 60
	if mins == 0 and secs == 0 then return " -.--" end
	if secs < 10 then secs = "0"..secs end
	return mins.."."..secs
end

function IntervalsPanel:AddInterval(station,int_p1,int_p2)
	local lb1 = self.Path1:Add("DLabel")
	lb1:SetFont("MDispSmall")
	lb1:SetText(FormatInterval(int_p1))
	lb1:SetTextColor(Color(255,255,255))
	lb1:Dock(TOP)
	lb1:DockMargin(0,0,0,2)
	
	local lb2 = self.Path2:Add("DLabel")
	lb2:SetFont("MDispSmall")
	lb2:SetText(FormatInterval(int_p2))
	lb2:SetTextColor(Color(255,255,255))
	lb2:Dock(TOP)
	lb2:DockMargin(0,0,0,2)
end

function IntervalsPanel:UpdateIntervals()
	if not IsValid(LocalPlayer()) then return end
	if not LocalPlayer():GetNW2Bool("MDispatcher.ShowIntervals",false) then return end
	if table.Count(MDispatcher.Intervals) == 0 then return end
	for k,v in pairs(MDispatcher.Intervals) do
		local p1,p2
		if v[1] >= 0 then
			p1 = v[1]+1
		else
			p1 = v[1]
		end
		if v[2] >= 0 then
			p2 = v[2]+1
		else
			p2 = v[2]
		end
		MDispatcher.Intervals[k] = {p1, p2}
	end
	self.Path1:Clear()
	self.Path1:SetPos(175,35)
	self.Path2:Clear()
	self.Path2:SetPos(217,35)
	for k,v in pairs(MDispatcher.Stations) do
		self:AddInterval(
			MDispatcher.Intervals[v.ID],
			MDispatcher.Intervals[v.ID][1],
			MDispatcher.Intervals[v.ID][2]
		)
		self.Path1:SetSize(25,height)
		self.Path2:SetSize(25,height)
	end
end
vgui.Register("MDispatcher.IntervalsPanel",IntervalsPanel,"Panel")

timer.Create("MDispatcher.UpdateIntervals",1,0,function()
	if IsValid(MDispatcher.IPanel) then
		MDispatcher.IPanel:UpdateIntervals()
	end
end)

net.Receive("MDispatcher.IntervalsData",function()
	local ln = net.ReadUInt(32)
	local tbl = util.JSONToTable(util.Decompress(net.ReadData(ln)))
	MDispatcher.Intervals = tbl
end)
