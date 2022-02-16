------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
local cr_height = 0
local function DispatcherMenu(routes)
	-- основной фрейм
	local frame = vgui.Create("DFrame")
	frame:SetSize(400,355)
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
	
	tab.OnActiveTabChanged = function(self,old,new)
		if new:GetText() == "ДЦХ" then frame:SetSize(400,355) end
		if new:GetText() == "Блок-посты" then frame:SetSize(400,55+cr_height+3) end
		tab:SetSize(frame:GetWide(),frame:GetTall())
		tab:Dock(FILL)
	end
	
	frame.OnClose = function()
		tab:Remove()
	end
	
	-- ДЦХ
	local idisp = vgui.Create("DButton",disp_panel)
	idisp:SetPos(5,5)
	idisp:SetSize(170,25)
	idisp:SetText("Занять пост ДЦХ")
	idisp.DoClick = function()
		RunConsoleCommand("ulx","disp")
	end
	
	local undisp = vgui.Create("DButton",disp_panel)
	undisp:SetPos(5,35)
	undisp:SetSize(170,25)
	undisp:SetText("Освободить пост ДЦХ")
	undisp.DoClick = function()
		RunConsoleCommand("ulx","undisp")
	end
	
	local lbint = vgui.Create("DLabel",disp_panel)
	lbint:SetPos(200,5)
	lbint:SetSize(140,25)
	lbint:SetFont("MDispSmallTitle")
	lbint:SetColor(Color(255,255,255))
	lbint:SetText("Интервал движения:")
	
	local int = vgui.Create("DTextEntry",disp_panel)
	int:SetPos(200,35)
	int:SetSize(40,25)
	int:SetPlaceholderText("1.45")
	
	local setint = vgui.Create("DButton",disp_panel)
	setint:SetPos(250,35)
	setint:SetSize(120,25)
	setint:SetText("Установить")
	setint:SetDisabled(true)
	setint.DoClick = function()
		RunConsoleCommand("ulx","setint",int:GetText())
	end
	int.OnChange = function() -- + проверка на кол-во символов?
		setint:SetDisabled(false)
	end
	
	local tmp_panel = vgui.Create("DPanel",disp_panel)
	tmp_panel:SetPos(200,80)
	tmp_panel:SetSize(170,70)
	tmp_panel:SetBackgroundColor(Color(190,194,198,255))
	local tmp_lbl = vgui.Create("DLabel",tmp_panel)
	tmp_lbl:SetFont("MDispSmallTitle")
	tmp_lbl:SetColor(Color(255,255,255))
	tmp_lbl:SetText("Work in progress...")
	tmp_lbl:SizeToContents()
	tmp_lbl:SetPos((tmp_panel:GetWide()/2)-(tmp_lbl:GetWide()/2),tmp_panel:GetTall()-(tmp_panel:GetTall()/2)-(tmp_lbl:GetTall()/2))
	
	local hor_line = vgui.Create("DPanel",disp_panel)
	hor_line:SetPos(5,160)
	hor_line:SetSize(365,1)
	hor_line:SetBackgroundColor(Color(255,255,255,255))
	
	local lbset = vgui.Create("DLabel",disp_panel)
	lbset:SetPos(5,70)
	lbset:SetSize(170,25)
	lbset:SetFont("MDispSmallTitle")
	lbset:SetColor(Color(255,255,255))
	lbset:SetText("Назначить на пост ДЦХ:")
	
	local setdispbox = vgui.Create("DComboBox",disp_panel)
	setdispbox:SetPos(5,95)
	setdispbox:SetSize(170,25)
	setdispbox:SetValue("Выберите игрока")
	for _,ply in pairs(player.GetAll()) do
		setdispbox:AddChoice(ply:Nick())
	end
	
	local setdisp = vgui.Create("DButton",disp_panel)
	setdisp:SetPos(5,125)
	setdisp:SetSize(170,25)
	setdisp:SetText("Назначить")
	setdisp:SetDisabled(true)
	setdisp.DoClick = function()
		RunConsoleCommand("ulx","setdisp",setdispbox:GetSelected())
	end
	setdispbox.OnSelect = function(self,index,value)
		setdisp:SetDisabled(false)
	end
	
	local lb_dscpset = vgui.Create("DLabel",disp_panel)
	lb_dscpset:SetPos(5,165)
	lb_dscpset:SetSize(170,25)
	lb_dscpset:SetFont("MDispSmallTitle")
	lb_dscpset:SetColor(Color(255,255,255))
	lb_dscpset:SetText("Назначить на пост ДСЦП:")
	
	local st_dscp = vgui.Create("DComboBox",disp_panel)
	st_dscp:SetPos(5,190)
	st_dscp:SetSize(170,25)
	st_dscp:SetValue("Выберите блок-пост")
	st_dscp:AddChoice("Депо")
	for k,st in pairs(MDispatcher.ControlRooms) do
		if not st:find("Депо") and not st:find("депо") then
			st_dscp:AddChoice(st)
		end
	end
	
	local ply_dscp = vgui.Create("DComboBox",disp_panel)
	ply_dscp:SetPos(5,222)
	ply_dscp:SetSize(170,25)
	ply_dscp:SetValue("Выберите игрока")
	for _,ply in pairs(player.GetAll()) do
		ply_dscp:AddChoice(ply:Nick())
	end
	
	local set_dscp = vgui.Create("DButton",disp_panel)
	set_dscp:SetPos(5,255)
	set_dscp:SetSize(170,25)
	set_dscp:SetText("Назначить")
	set_dscp:SetDisabled(true)
	set_dscp.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("dscp-post-set")
			net.WriteString(st_dscp:GetSelected())
			net.WriteString(ply_dscp:GetSelected())
		net.SendToServer()
	end
	ply_dscp.OnSelect = function()
		if st_dscp:GetSelected() then
			set_dscp:SetDisabled(false)
		end
	end
	st_dscp.OnSelect = function()
		if ply_dscp:GetSelected() then
			set_dscp:SetDisabled(false)
		end
	end
	
	local lb_dscpunset = vgui.Create("DLabel",disp_panel)
	lb_dscpunset:SetPos(200,165)
	lb_dscpunset:SetSize(170,25)
	lb_dscpunset:SetFont("MDispSmallTitle")
	lb_dscpunset:SetColor(Color(255,255,255))
	lb_dscpunset:SetText("Снять с поста ДСЦП:")
	
	local st_dscp2 = vgui.Create("DComboBox",disp_panel)
	st_dscp2:SetPos(200,190)
	st_dscp2:SetSize(170,25)
	st_dscp2:SetValue("Выберите блок-пост")
	st_dscp2:AddChoice("Депо")
	for k,st in pairs(MDispatcher.ControlRooms) do
		if not st:find("Депо") and not st:find("депо") then
			st_dscp2:AddChoice(st)
		end
	end
	
	local unset_dscp = vgui.Create("DButton",disp_panel)
	unset_dscp:SetPos(200,222)
	unset_dscp:SetSize(170,25)
	unset_dscp:SetText("Снять")
	unset_dscp:SetDisabled(true)
	unset_dscp.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("dscp-post-unset")
			net.WriteString(st_dscp2:GetSelected())
		net.SendToServer()
	end
	st_dscp2.OnSelect = function()
		unset_dscp:SetDisabled(false)
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
		cr_height = 10
		if game.GetMap():find("gm_metro_kalinin") then
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
			plbl:SetText("Депо (оверлей)")
			plbl:SizeToContents()
			plbl:SetMouseInputEnabled(true)
			
			plbl.DoClick = function()
				frame_create() -- функция из Калининской
			end
			cr_height = cr_height + 30
			scroll_panel:SetSize(415,cr_height)
		end
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
			cr_height = cr_height + 30
			scroll_panel:SetSize(415,cr_height)
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