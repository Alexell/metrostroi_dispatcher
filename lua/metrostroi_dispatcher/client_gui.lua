------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
local function DispatcherMenu(routes)
	-- основной фрейм
	local frame = vgui.Create("DFrame")
	frame:SetSize(450,200)
	frame:Center()
	frame:SetTitle("Metrostroi: Меню диспетчера")
	frame.btnMaxim:SetVisible(false)
	frame.btnMinim:SetVisible(false)
	frame:SetVisible(true)
	frame:SetSizable(false)
	frame:SetDeleteOnClose(true)
	frame:SetIcon("icon16/application_view_detail.png")
	frame:MakePopup()
	
	-- вкладки
	local tab = vgui.Create("DPropertySheet",frame)
	tab:SetSize(frame:GetWide(),frame:GetTall())
	tab:Dock(FILL)

	local disp_panel = vgui.Create("DPanel",tab)
	disp_panel:SetSize(tab:GetWide(),tab:GetTall())
	disp_panel:SetBackgroundColor(Color(0,0,0,0))
	tab:AddSheet("ДЦХ",disp_panel,"icon16/user_suit.png",false,false)

	local dscp_panel = vgui.Create("DPanel",tab)
	dscp_panel:SetSize(tab:GetWide(),tab:GetTall())
	dscp_panel:SetBackgroundColor(Color(0,0,0,0))
	tab:AddSheet("Блок-посты",dscp_panel,"icon16/user_go.png",false,false)
	
	local sched_panel = vgui.Create("DPanel",tab)
	sched_panel:SetSize(tab:GetWide(),tab:GetTall())
	sched_panel:SetBackgroundColor(Color(0,0,0,0))
	tab:AddSheet("Расписания",sched_panel,"icon16/table.png",false,false)
	
	frame.OnClose = function()
		tab:Remove()
	end
	
	-- ДЦХ
	local idisp = vgui.Create("DButton",disp_panel)
	idisp:SetPos(5,5)
	idisp:SetSize(140,25)
	idisp:SetText("Занять пост ДЦХ")
	idisp.DoClick = function()
		RunConsoleCommand("ulx","disp")
	end
	
	local undisp = vgui.Create("DButton",disp_panel)
	undisp:SetPos(5,40)
	undisp:SetSize(140,25)
	undisp:SetText("Освободить пост ДЦХ")
	undisp.DoClick = function()
		RunConsoleCommand("ulx","undisp")
	end
	
	local lbset = vgui.Create("DLabel",disp_panel)
	lbset:SetPos(170,5)
	lbset:SetSize(170,25)
	lbset:SetFont("MDispSmallTitle")
	lbset:SetColor(Color(255,255,255))
	lbset:SetText("Назначить на пост ДЦХ:")
	
	local setdispbox = vgui.Create("DComboBox",disp_panel)
	setdispbox:SetPos(170,40)
	setdispbox:SetSize(170,25)
	setdispbox:SetValue("Выберите игрока")
	for _,ply in pairs(player.GetAll()) do
		setdispbox:AddChoice(ply:Nick())
	end
	
	local setdisp = vgui.Create("DButton",disp_panel)
	setdisp:SetPos(350,40)
	setdisp:SetSize(70,25)
	setdisp:SetText("Назначить")
	setdisp:SetDisabled(true)
	setdisp.DoClick = function()
		RunConsoleCommand("ulx","setdisp",setdispbox:GetSelected())
	end
	setdispbox.OnSelect = function(self,index,value)
		setdisp:SetDisabled(false)
	end
	
	local lbint = vgui.Create("DLabel",disp_panel)
	lbint:SetPos(5,100)
	lbint:SetSize(140,25)
	lbint:SetFont("MDispSmallTitle")
	lbint:SetColor(Color(255,255,255))
	lbint:SetText("Интервал движения:")
	
	local int = vgui.Create("DTextEntry",disp_panel)
	int:SetPos(170,100)
	int:SetSize(40,25)
	int:SetPlaceholderText("1.45")
	
	local setint = vgui.Create("DButton",disp_panel)
	setint:SetPos(220,100)
	setint:SetSize(120,25)
	setint:SetText("Установить")
	setint:SetDisabled(true)
	setint.DoClick = function()
		RunConsoleCommand("ulx","setint",int:GetText())
	end
	int.OnChange = function()
		setint:SetDisabled(false)
	end
	
	-- Блок-посты
	local dscptitle = vgui.Create("DLabel",dscp_panel)
	dscptitle:SetPos(5,0)
	dscptitle:SetSize(230,25)
	dscptitle:SetFont("MDispSmallTitle")
	dscptitle:SetColor(Color(255,255,255))
	dscptitle:SetText("Быстрое перемещение к пультам:")

	if MDispatcher.ControlRooms then
		--if scroll_panel then scroll_panel:Clear() end
		local scroll_panel = vgui.Create("DScrollPanel",dscp_panel)
		scroll_panel:SetPos(5,30)
		local ht = 10
		for _,name in pairs(MDispatcher.ControlRooms) do
			local pnl = scroll_panel:Add("Panel")
			pnl:Dock(TOP)
			pnl:SetHeight(25)
			pnl:DockMargin(0,0,0,5)
			pnl.Paint = function(self,w,h)
				draw.RoundedBox(5,0,0,w,h,Color(134,137,140))
			end
			
			local plbl = vgui.Create("DLabel",pnl)
			plbl:SetPos(10,5)
			plbl:SetFont("MDispSmallTitle")
			plbl:SetColor(Color(255,255,255))
			plbl:SetCursor("hand")
			plbl:SetText(name)
			plbl:SizeToContents()
			plbl:SetMouseInputEnabled(true)
			
			plbl.DoClick = function()
				net.Start("MDispatcher.Commands")
					net.WriteString("cr-teleport")
					net.WriteString(name)
				net.SendToServer()
			end
			ht = ht + 30
			scroll_panel:SetSize(415,ht)
		end
	else
		local dscpempty = vgui.Create("DLabel",dscp_panel)
		dscpempty:SetPos(5,25)
		dscpempty:SetSize(230,25)
		dscpempty:SetColor(Color(255,0,0))
		dscpempty:SetText("Карта пока не поддерживается.")
	end

end

net.Receive("MDispatcher.DispatcherMenu",function()
	local ln = net.ReadUInt(32)
	local tbl = util.JSONToTable(util.Decompress(net.ReadData(ln)))
	DispatcherMenu(tbl)
	--PrintTable(MDispatcher.ControlRooms)
end)