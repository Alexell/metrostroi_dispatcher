------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------

-- ДСЦП
local DSCPPanel = {}
local height = 22
function DSCPPanel:Init()
	self.Title = vgui.Create("DLabel",self)
	self.Title:SetFont("MDispMain")
	self.Title:SetText("Блок-посты")
	self.CRooms = vgui.Create("DScrollPanel",self)
	self.DSCP = vgui.Create("DScrollPanel",self)
end

function DSCPPanel:Paint(w,h)
	draw.RoundedBox(5,0,0,w,h,Color(0,0,0,150))
end

function DSCPPanel:PerformLayout()
	self:SetSize(250,height)
	self:SetPos(ScrW() - self:GetWide() - 5, 255)
	
	self.Title:SizeToContents()
	self.Title:SetPos((self:GetWide()/ 2) - (self.Title:GetWide() / 2), 5)
	self.Title:SetTextColor(Color(255,255,255))
	
	self.CRooms:SetPos(10,22)
	self.DSCP:SetPos(150,22)
	local sb1 = self.CRooms:GetVBar()
	sb1:SetSize(0,0)
	local sb2 = self.DSCP:GetVBar()
	sb2:SetSize(0,0)
end

function DSCPPanel:AddCRoom(st)
	local lb1 = self.CRooms:Add("DLabel")
	lb1:SetFont("MDispSmallTitle")
	lb1:SetText(st)
	lb1:SetTextColor(Color(255,255,255))
	lb1:Dock(TOP)
end
function DSCPPanel:AddNick(nick)
	local lb2 = self.DSCP:Add("DLabel")
	lb2:SetFont("MDispSmall")
	lb2:SetText(nick)
	lb2:SizeToContents()
	if lb2:GetWide() < 90 then
		lb2:SetPos(90-lb2:GetWide(),height-20)
	else
		lb2:SetPos(0,height-20)
		lb2:SetSize(90,20)
	end
	lb2:SetTextColor(Color(255,255,255))
end

function DSCPPanel:SetControlRooms()
	height = 22
	for k,st in pairs(MDispatcher.DSCPCRooms) do
		self:AddCRoom(st)
		height = height + 20
		self.CRooms:SetSize(130,height)
	end
	height = height + 5
	self.CRooms:SetSize(130,height)
end

function DSCPPanel:Update(nicks)
	height = 22
	self.DSCP:Clear()
	for _,nick in pairs(nicks) do
		self:AddNick(nick)
		height = height + 20
		self.DSCP:SetSize(90,height)
	end
	height = height + 5
	self.DSCP:SetSize(90,height)
	MDispatcher.DSCPPlayers = nicks
end
vgui.Register("MDispatcher.DSCPPanel",DSCPPanel,"Panel")

net.Receive("MDispatcher.DSCPData",function()
	local ln = net.ReadUInt(32)
	local tbl = util.JSONToTable(util.Decompress(net.ReadData(ln)))
	MDispatcher.DSCPPanel:Update(tbl)
end)