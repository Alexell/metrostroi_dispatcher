------------------------ Metrostroi Dispatcher -----------------------
-- Developers:
-- Alexell | https://steamcommunity.com/profiles/76561198210303223
-- Agent Smith | https://steamcommunity.com/profiles/76561197990364979
-- License: MIT
-- Source code: https://github.com/Alexell/metrostroi_dispatcher
----------------------------------------------------------------------
local cr_height = 0

local function FillDSCPMenu()
	-- фрейм заполнения блок-постов
	if not MDispatcher.FillControlRooms then MDispatcher.FillControlRooms = {} end
	
	local frm = vgui.Create("DFrame")
	frm:SetSize(400,355)
	frm:Center()
	frm:SetTitle("Меню диспетчера: заполнить блок-посты")
	frm.btnMaxim:SetVisible(false)
	frm.btnMinim:SetVisible(false)
	frm:SetVisible(true)
	frm:SetSizable(false)
	frm:SetDeleteOnClose(true)
	frm:SetIcon("icon16/table_gear.png")
	frm:MakePopup()
	
	local pan = vgui.Create("DPanel",frm)
	pan:SetBackgroundColor(Color(0,0,0,0))
	pan:Dock(FILL)
	
	local lbhead = vgui.Create("DLabel",pan)
	lbhead:SetPos(5,0)
	lbhead:SetSize(100,25)
	lbhead:SetFont("MDispSmallTitle")
	lbhead:SetColor(Color(255,255,255))
	lbhead:SetText("Инструкция:")
	
	local lbdesc1 = vgui.Create("DLabel",pan)
	lbdesc1:SetPos(5,20)
	lbdesc1:SetSize(380,115)
	lbdesc1:SetColor(Color(255,255,255))
	lbdesc1:SetFont("MDispSmall")
	lbdesc1:SetText("1. Переместитесь в нужную диспетчерскую любым способом.\n2. Отключите режим полета и подойдие ближе к пульту.\n3. Заполните ниже название блок-поста и нажмите Добавить.\n3.1 Будут сохранены ваши координаты и угол зрения.\n4. Закройте это окно и перемещайтесь в следующий блок-пост.\n\nВАЖНО: Не нажимайте кнопку Сохранить, пока не заполните\nвсе блок-посты! Повторное заполнение будет недоступно.")
	
	local crlist = vgui.Create("DListView",pan)
	crlist:SetMultiSelect(false)
	crlist:AddColumn("Название")
	crlist:AddColumn("Координаты")
	crlist:AddColumn("Углы")
	crlist:SetPos(5,150)
	crlist:SetSize(380,100)

	for k,v in pairs(MDispatcher.FillControlRooms) do
		crlist:AddLine(v.Name,tostring(v.Pos),tostring(v.Ang))
	end
	
	local crname = vgui.Create("DTextEntry",pan)
	crname:SetPos(5,255)
	crname:SetSize(188,25)
	crname:SetPlaceholderText("Название блок-поста")
	
	local cradd = vgui.Create("DButton",pan)
	cradd:SetPos(198,255)
	cradd:SetSize(187,25)
	cradd:SetText("Добавить")
	cradd:SetEnabled(false)
	cradd.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("cr-add")
			net.WriteString(crname:GetText())
		net.SendToServer()
		frm:Close()
	end
	crname.OnChange = function()
		if #crname:GetText() > 3 then
			cradd:SetEnabled(true)
		else
			cradd:SetEnabled(false)
		end
	end
	
	local crsave = vgui.Create("DButton",pan)
	crsave:SetSize(170,25)
	crsave:SetPos((pan:GetWide()/2)+85,290)
	crsave:SetText("СОХРАНИТЬ")
	crsave.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("cr-save")
			net.WriteTable(MDispatcher.FillControlRooms)
		net.SendToServer()
		frm:Close()
		MDispatcher.FillControlRooms = nil
	end
	if #crlist:GetLines() > 0 then
		crsave:SetEnabled(true)
	else
		crsave:SetEnabled(false)
	end
end

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
	disp_panel:SetVisible(false)
	if LocalPlayer():query("ulx disp") or LocalPlayer():GetNW2Bool("MDispatcher") then
		tab:AddSheet("ДЦХ",disp_panel,"icon16/user_suit.png",false,false)
		disp_panel:SetVisible(true)
	end
	
	local dscp_panel = vgui.Create("DPanel",tab)
	dscp_panel:SetSize(tab:GetWide(),tab:GetTall())
	dscp_panel:SetBackgroundColor(Color(0,0,0,0))
	tab:AddSheet("Блок-посты",dscp_panel,"icon16/user_go.png",false,false)
	
	
	local sched_panel = vgui.Create("DPanel",tab)
	sched_panel:SetSize(tab:GetWide(),tab:GetTall())
	sched_panel:SetBackgroundColor(Color(0,0,0,0))
	sched_panel:SetVisible(false)
	if LocalPlayer():query("ulx disp") or LocalPlayer():GetNW2Bool("MDispatcher") then
		tab:AddSheet("Расписания",sched_panel,"icon16/table.png",false,false)
		sched_panel:SetVisible(true)
	end
	
	tab.OnActiveTabChanged = function(self,old,new)
		if new:GetText() == "ДЦХ" then frame:SetSize(400,355) end
		if new:GetText() == "Блок-посты" then frame:SetSize(400,85+cr_height+3) end
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
	if MDispatcher.Dispatcher ~= "отсутствует" then idisp:SetEnabled(false) end
	
	local undisp = vgui.Create("DButton",disp_panel)
	undisp:SetPos(5,35)
	undisp:SetSize(170,25)
	undisp:SetText("Освободить пост ДЦХ")
	
	idisp.DoClick = function()
		RunConsoleCommand("ulx","disp")
		idisp:SetEnabled(false)
		undisp:SetEnabled(true)
	end
	undisp.DoClick = function()
		RunConsoleCommand("ulx","undisp")
		idisp:SetEnabled(true)
		undisp:SetEnabled(false)
	end
	
	if MDispatcher.Dispatcher == "отсутствует" then undisp:SetEnabled(false) end
	
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
	setint:SetEnabled(false)
	setint.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("set-int")
			net.WriteString(int:GetText())
		net.SendToServer()
	end
	int.OnChange = function()
		if #int:GetText() > 3 then
			setint:SetEnabled(true)
		else
			setint:SetEnabled(false)
		end
	end
	
	------------------- временно ---------------------
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
	---------------------------------------------------
	
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
	if not LocalPlayer():query("ulx disp") then setdispbox:SetEnabled(false) end
	
	local setdisp = vgui.Create("DButton",disp_panel)
	setdisp:SetPos(5,125)
	setdisp:SetSize(170,25)
	setdisp:SetText("Назначить")
	setdisp:SetEnabled(false)
	setdisp.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("set-disp")
			net.WriteString(setdispbox:GetSelected())
		net.SendToServer()
		idisp:SetEnabled(false)
		setdisp:SetEnabled(false)
		undisp:SetEnabled(true)
	end
	setdispbox.OnSelect = function(self,index,value)
		if MDispatcher.Dispatcher == "отсутствует" then
			setdisp:SetEnabled(true)
		else
			setdisp:SetEnabled(false)
		end
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
	for k,st in pairs(MDispatcher.DSCPCRooms) do
		if MDispatcher.DSCPPlayers[k] == "отсутствует" then
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
	set_dscp:SetEnabled(false)
	set_dscp.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("dscp-post-set")
			net.WriteString(st_dscp:GetSelected())
			net.WriteString(ply_dscp:GetSelected())
		net.SendToServer()
		frame:Close()
	end
	ply_dscp.OnSelect = function()
		if st_dscp:GetSelected() then
			set_dscp:SetEnabled(true)
		end
	end
	st_dscp.OnSelect = function()
		if ply_dscp:GetSelected() then
			set_dscp:SetEnabled(true)
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
	for k,st in pairs(MDispatcher.DSCPCRooms) do
		if MDispatcher.DSCPPlayers[k] ~= "отсутствует" then
			st_dscp2:AddChoice(st)
		end
	end
	
	local unset_dscp = vgui.Create("DButton",disp_panel)
	unset_dscp:SetPos(200,222)
	unset_dscp:SetSize(170,25)
	unset_dscp:SetText("Снять")
	unset_dscp:SetEnabled(false)
	unset_dscp.DoClick = function()
		net.Start("MDispatcher.Commands")
			net.WriteString("dscp-post-unset")
			net.WriteString(st_dscp2:GetSelected())
		net.SendToServer()
		frame:Close()
	end
	st_dscp2.OnSelect = function()
		unset_dscp:SetEnabled(true)
	end
	
	-- Блок-посты
	local dscptitle = vgui.Create("DLabel",dscp_panel)
	dscptitle:SetPos(5,0)
	dscptitle:SetSize(230,25)
	dscptitle:SetFont("MDispSmallTitle")
	dscptitle:SetColor(Color(255,255,255))
	dscptitle:SetText("Быстрое перемещение к пультам:")

	if #MDispatcher.ControlRooms > 0 then
		local scroll_panel = vgui.Create("DScrollPanel",dscp_panel)
		scroll_panel:SetPos(5,30)
		cr_height = 10
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
				if game.GetMap():find("gm_metro_kalinin") and name == "Депо" then
					timer.Simple(1,frame_create) -- функция из Калининской
				end
			end
			cr_height = cr_height + 30
			scroll_panel:SetSize(365,cr_height)
		end
		if tab:GetActiveTab():GetText() == "Блок-посты" then -- нужно, если меню открывает ДСЦП без прав ДЦХ
			frame:SetSize(400,85+cr_height+3)
		end
	else
		local dscpempty = vgui.Create("DLabel",dscp_panel)
		dscpempty:SetPos(5,20)
		dscpempty:SetSize(230,25)
		dscpempty:SetColor(Color(255,0,0))
		dscpempty:SetText("Блок-посты на этой карте не заполнены.")
		local fill_dscp = vgui.Create("DButton",dscp_panel)
		fill_dscp:SetPos(5,45)
		fill_dscp:SetSize(170,25)
		fill_dscp:SetText("Заполнить блок-посты")
		fill_dscp:SetEnabled(false)
		fill_dscp.DoClick = function()
			FillDSCPMenu()
			frame:Close()
		end
		if LocalPlayer():query("ulx disp") then fill_dscp:SetEnabled(true) end
		cr_height = 55
		if tab:GetActiveTab():GetText() == "Блок-посты" then -- нужно, если меню открывает ДСЦП без прав ДЦХ
			frame:SetSize(400,85+cr_height+3)
		end
	end
end

net.Receive("MDispatcher.Commands",function()
	local comm = net.ReadString()
	if comm == "menu" then
		local ln = net.ReadUInt(32)
		local tbl = util.JSONToTable(util.Decompress(net.ReadData(ln)))
		DispatcherMenu(tbl)
	elseif comm == "cr-add" then
		local cr_name = net.ReadString()
		local cr_pos = net.ReadVector()
		local cr_ang = net.ReadAngle()
		table.insert(MDispatcher.FillControlRooms,{Name = cr_name,Pos = cr_pos,Ang = cr_ang})
		FillDSCPMenu()
	elseif comm == "cr-save-ok" then
		Derma_Message("Блок-посты сохранены успешно!\nЧтобы увидеть изменения, пожалуйста перезайдите на сервер.", "Меню диспетчера", "OK")
	end
end)