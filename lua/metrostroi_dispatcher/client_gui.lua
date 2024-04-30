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
	lbdesc1:SetText("1. Переместитесь в нужный блок-пост любым способом.\n2. Отключите режим полета и подойдие ближе к пульту.\n3. Заполните ниже название блок-поста и нажмите Добавить.\n3.1 Будут сохранены ваши координаты и угол зрения.\n4. Закройте это окно и перемещайтесь в следующий блок-пост.\n\nВАЖНО: Не нажимайте кнопку Сохранить, пока не заполните\nвсе блок-посты! Повторное заполнение будет недоступно.")
	
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

local function SchedulePreiewForm(ply_tbl,stations,path,start,last)
	local frm = vgui.Create("DFrame")
	frm:SetSize(280,280)
	frm:Center()
	frm:SetTitle("Меню диспетчера: подготовка расписания")
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
	lbhead:SetFont("MDispSmallTitle")
	lbhead:SetColor(Color(255,255,255))
	lbhead:SetText("Маршрут № "..ply_tbl.Route.." | Игрок: "..ply_tbl.Nick)
	lbhead:SetSize(260,25)
	
	local hor_line = vgui.Create("DPanel",pan)
	hor_line:SetPos(5,25)
	hor_line:SetSize(260,1)
	hor_line:SetBackgroundColor(Color(255,255,255,255))
	
	local lbhead1 = vgui.Create("DLabel",pan)
	lbhead1:SetPos(5,30)
	lbhead1:SetFont("MDispSmallTitle")
	lbhead1:SetColor(Color(255,255,255))
	lbhead1:SetText("Станция")
	lbhead1:SizeToContents()
	local lbhead2 = vgui.Create("DLabel",pan)
	lbhead2:SetPos(160,30)
	lbhead2:SetFont("MDispSmallTitle")
	lbhead2:SetColor(Color(255,255,255))
	lbhead2:SetText("Выдержка (сек)")
	lbhead2:SizeToContents()
	
	local stationspan = vgui.Create("DScrollPanel",pan)
	local holdspan = vgui.Create("DScrollPanel",pan)
	stationspan:SetPos(5,45)
	holdspan:SetPos(160,45)
	local ht = 0
	
	local line = math.floor(start/100)
	local init_nid = stations[line][path][start].NodeID
	local last_nid = stations[line][path][last].NodeID
	for k,v in SortedPairsByMemberValue(stations[line][path],"NodeID") do
		if v.NodeID < init_nid then continue end
		if v.NodeID >= init_nid and v.NodeID <= last_nid then
			local lb1 = stationspan:Add("DLabel")
			lb1:SetText(v.Name)
			lb1:SetTextColor(Color(255,255,255))
			lb1:Dock(TOP)
			lb1:DockMargin(0,5,20,0)
			
			local hold = holdspan:Add("DTextEntry")
			hold:SetNumeric(true)
			hold:SetValue(0)
			hold:Dock(TOP)
			hold:DockMargin(50,5,0,0)
			hold.station = k
			if v.NodeID == init_nid or v.NodeID == last_nid then
				hold:SetEnabled(false)
			end
			ht = ht+25
			stationspan:SetSize(160,ht)
			holdspan:SetSize(100,ht)
		end
	end
	
	ht = ht + 55
	local lbfoot = vgui.Create("DLabel",pan)
	lbfoot:SetPos(5,ht)
	lbfoot:SetFont("MDispSmallTitle")
	lbfoot:SetColor(Color(255,255,255))
	lbfoot:SetText("Комментарий:")
	lbfoot:SizeToContents()
	
	ht = ht + 20
	local comm = vgui.Create("DTextEntry",pan)
	comm:SetPos(5,ht)
	comm:SetSize(256,25)
	comm:SetPlaceholderText("До ст. Новогиреево под оборот")
	comm.AllowInput = function()
		if utf8.len(comm:GetText()) == 30 then
			return true
		end
	end
	
	ht = ht + 35
	local send = vgui.Create("DButton",pan)
	send:SetSize(100,25)
	send:SetPos((pan:GetWide()/2),ht)
	send:SetText("Отправить")
	send.DoClick = function()
		local holds = {}
		for k,cbox in pairs(holdspan:GetCanvas():GetChildren()) do
			if not holds[cbox.station] then holds[cbox.station] = MDispatcher.RoundSeconds(tonumber(cbox:GetInt()) and cbox:GetInt() or 0) end -- защита от пустого поля
		end
		net.Start("MDispatcher.Commands")
			net.WriteString("sched-send")
			net.WriteString(ply_tbl.SID)
			net.WriteInt(path,3)
			net.WriteInt(start,11)
			net.WriteInt(last,11)
			net.WriteTable(holds)
			net.WriteString(comm:GetText())
		net.SendToServer()
		frm:Close()
	end
	local cancel = vgui.Create("DButton",pan)
	cancel:SetSize(100,25)
	cancel:SetPos((pan:GetWide()/2)+105,ht)
	cancel:SetText("Отменить")
	cancel.DoClick = function()
		frm:Close()
	end
	frm:SetSize(280,80+ht-15)
end

local function DispatcherMenu(signals,next_signal,routes,stations)
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

	local user_panel = vgui.Create("DPanel",tab)
	user_panel:SetSize(tab:GetWide(),tab:GetTall())
	user_panel:SetBackgroundColor(Color(0,0,0,0))
	user_panel:SetVisible(true)
	tab:AddSheet("Маршруты",user_panel,"icon16/arrow_branch.png",false,false)
	user_panel:SetVisible(true)

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
	dscp_panel:SetVisible(false)
	if LocalPlayer():query("ulx disp") or LocalPlayer():GetNW2Bool("MDispatcher") or LocalPlayer():GetNW2Bool("MDSCP") then
		tab:AddSheet("Блок-посты",dscp_panel,"icon16/user_go.png",false,false)
		dscp_panel:SetVisible(true)
	end
	
	local sched_panel = vgui.Create("DPanel",tab)
	sched_panel:SetSize(tab:GetWide(),tab:GetTall())
	sched_panel:SetBackgroundColor(Color(0,0,0,0))
	sched_panel:SetVisible(false)
	if LocalPlayer():query("ulx disp") or LocalPlayer():GetNW2Bool("MDispatcher") then
		tab:AddSheet("Расписания",sched_panel,"icon16/table.png",false,false)
		sched_panel:SetVisible(true)
	end
	
	tab.OnActiveTabChanged = function(self,old,new)
		if new:GetText() == "Машинист" then frame:SetSize(400,355) end
		if new:GetText() == "ДЦХ" then frame:SetSize(400,355) end
		if new:GetText() == "Блок-посты" then frame:SetSize(400,85+cr_height+3) end
		if new:GetText() == "Расписания" then frame:SetSize(400,300) end
		tab:SetSize(frame:GetWide(),frame:GetTall())
		tab:Dock(FILL)
	end
	
	frame.OnClose = function()
		tab:Remove()
	end
	
	-- Маршруты
	local lbuser = vgui.Create("DLabel",user_panel)
	lbuser:SetPos(5,5)
	lbuser:SetFont("MDispSmallTitle")
	lbuser:SetColor(Color(255,255,255))
	lbuser:SetText("Действия с сигналами и маршрутами:")
	lbuser:SizeToContents()
	
	local siglist = vgui.Create("DListView",user_panel)
	siglist:SetMultiSelect(false)
	siglist:AddColumn("Сигналы")
	siglist:SetPos(5,25)
	siglist:SetSize(170,255)
	
	local routelist = vgui.Create("DListView",user_panel)
	routelist:SetMultiSelect(false)
	routelist:AddColumn("Маршруты")
	routelist:SetPos(188,25)
	routelist:SetSize(180,160)
	
	local ropen = vgui.Create("DButton",user_panel)
	ropen:SetPos(188,195)
	ropen:SetSize(180,25)
	ropen:SetText("Открыть маршрут")
	ropen:SetEnabled(false)
	ropen.DoClick = function()
		local selected = siglist:GetSelected()[1]
		local signal = selected:GetValue(1)
		selected = routelist:GetSelected()[1]
		local route = selected:GetValue(1)
		net.Start("MDispatcher.Commands")
			net.WriteString("routes-open")
			net.WriteString(signal)
			net.WriteString(route)
		net.SendToServer()
	end
	
	local rclose = vgui.Create("DButton",user_panel)
	rclose:SetPos(188,225)
	rclose:SetSize(180,25)
	rclose:SetText("Закрыть маршрут")
	rclose:SetEnabled(false)
	rclose.DoClick = function()
		local selected = siglist:GetSelected()[1]
		local signal = selected:GetValue(1)
		selected = routelist:GetSelected()[1]
		local route = selected:GetValue(1)
		net.Start("MDispatcher.Commands")
			net.WriteString("routes-close")
			net.WriteString(signal)
			net.WriteString(route)
		net.SendToServer()
	end
	
	local spass = vgui.Create("DButton",user_panel)
	spass:SetPos(188,255)
	spass:SetSize(180,25)
	spass:SetText("Проезд запрещающего сигнала")
	spass:SetEnabled(false)
	spass.DoClick = function()
		local selected = siglist:GetSelected()[1]
		local signal = selected:GetValue(1)
		selected = routelist:GetSelected()[1]
		local route = selected:GetValue(1)
		net.Start("MDispatcher.Commands")
			net.WriteString("routes-pass")
			net.WriteString(signal)
			net.WriteString(route)
		net.SendToServer()
	end
	
	local function scroll_to(line)
		if siglist.VBar then
			local list_height = siglist:GetTall()
			local line_index = line:GetID()
			-- local line_size = line:GetTall() -- выдает завышенный размер строки
			local line_size = 18
			local y = line_size * (line_index - 1) + line_size / 2 - list_height / 2
			siglist.VBar:AnimateTo(y, 0.3, 0, 0.5)
		end
	end
	
	local function show_routes(signal)
		routelist:Clear()
		for key, val in pairs(signals) do
			if val.Name == signal then
				for k,v in pairs(val.Routes) do
					routelist:AddLine(v)
				end
				ropen:SetEnabled(true)
				rclose:SetEnabled(true)
				spass:SetEnabled(true)
				break
			end
		end
		routelist:SelectFirstItem()
	end
	
	local selected_line
	for k, v in SortedPairsByMemberValue(signals, "Name") do
		local line = siglist:AddLine(v.Name)
		if next_signal == v.Name then
			line:SetSelected(true)
			selected_line = line
			show_routes(next_signal)
		end
	end
	if selected_line ~= nil then scroll_to(selected_line) end
	siglist.OnRowSelected = function(list,index,row)
		show_routes(row:GetValue(1))
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
	
	local lbintstitle = vgui.Create("DLabel",disp_panel)
	lbintstitle:SetPos(200,70)
	lbintstitle:SetSize(170,25)
	lbintstitle:SetFont("MDispSmallTitle")
	lbintstitle:SetColor(Color(255,255,255))
	lbintstitle:SetText("Интервалы на станциях:")
	
	local showints = vgui.Create("DButton",disp_panel)
	showints:SetPos(200,95)
	showints:SetSize(170,25)
	showints:SetText("Показать/скрыть")
	showints.DoClick = function()
		if not IsValid(LocalPlayer()) then return end
		if LocalPlayer():GetNW2Bool("MDispatcher.ShowIntervals") then
			net.Start("MDispatcher.Commands")
				net.WriteString("ints")
				net.WriteBool(false)
			net.SendToServer()
		else
			net.Start("MDispatcher.Commands")
				net.WriteString("ints")
				net.WriteBool(true)
			net.SendToServer()
		end
	end

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
	for _,ply in ipairs(player.GetAll()) do
		setdispbox:AddChoice(ply:Nick(),ply:SteamID())
	end
	if not LocalPlayer():query("ulx disp") then setdispbox:SetEnabled(false) end
	
	local setdisp = vgui.Create("DButton",disp_panel)
	setdisp:SetPos(5,125)
	setdisp:SetSize(170,25)
	setdisp:SetText("Назначить")
	setdisp:SetEnabled(false)
	setdisp.DoClick = function()
		local _,sid = setdispbox:GetSelected()
		net.Start("MDispatcher.Commands")
			net.WriteString("set-disp")
			net.WriteString(sid)
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
	for _,ply in ipairs(player.GetAll()) do
		if not ply:GetNW2Bool("MDispatcher") then
			ply_dscp:AddChoice(ply:Nick(),ply:SteamID())
		end
	end
	
	local set_dscp = vgui.Create("DButton",disp_panel)
	set_dscp:SetPos(5,255)
	set_dscp:SetSize(170,25)
	set_dscp:SetText("Назначить")
	set_dscp:SetEnabled(false)
	set_dscp.DoClick = function()
		local _,sid = ply_dscp:GetSelected()
		net.Start("MDispatcher.Commands")
			net.WriteString("dscp-post-set")
			net.WriteString(st_dscp:GetSelected())
			net.WriteString(sid)
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
	
	-- Расписания
	local sched_lb = vgui.Create("DLabel",sched_panel)
	sched_lb:SetPos(5,5)
	sched_lb:SetColor(Color(255,255,255))
	sched_lb:SetText("Здесь вы можете отправить расписание машинисту.")
	sched_lb:SetFont("MDispSmallTitle")
	sched_lb:SizeToContents()
	
	local sched_player_lb = vgui.Create("DLabel",sched_panel)
	sched_player_lb:SetPos(5,30)
	sched_player_lb:SetSize(100,25)
	sched_player_lb:SetColor(Color(255,255,255))
	sched_player_lb:SetText("Маршрут:")
	sched_player_lb:SetFont("MDispSmallTitle")
	sched_player_lb:SizeToContents()
	
	local sched_player = vgui.Create("DComboBox",sched_panel)
	sched_player:SetPos(5,50)
	sched_player:SetSize(170,25)
	sched_player:SetValue("Выберите маршрут")
	local ply
	for k,v in pairs(routes) do
		ply = player.GetBySteamID(k)
		if not ply:GetNW2Bool("MDispatcher") then
			sched_player:AddChoice(v.Route.." | "..v.Nick,{SID=k,Nick=v.Nick,Route=v.Route})
		end
	end
	
	local hor_line2 = vgui.Create("DPanel",sched_panel)
	hor_line2:SetPos(5,83)
	hor_line2:SetSize(365,1)
	hor_line2:SetBackgroundColor(Color(255,255,255,255))
	
	local sched_line_lb = vgui.Create("DLabel",sched_panel)
	sched_line_lb:SetPos(5,90)
	sched_line_lb:SetSize(100,25)
	sched_line_lb:SetColor(Color(255,255,255))
	sched_line_lb:SetText("Линия:")
	sched_line_lb:SetFont("MDispSmallTitle")
	sched_line_lb:SizeToContents()
	
	local sched_line = vgui.Create("DComboBox",sched_panel)
	sched_line:SetPos(5,110)
	sched_line:SetSize(170,25)
	sched_line:SetEnabled(false)
	sched_line:SetValue("Выберите линию")
	
	for k,v in pairs(stations) do
		sched_line:AddChoice(k)
	end
	
	local sched_path_lb = vgui.Create("DLabel",sched_panel)
	sched_path_lb:SetPos(200,90)
	sched_path_lb:SetSize(100,25)
	sched_path_lb:SetColor(Color(255,255,255))
	sched_path_lb:SetText("Путь:")
	sched_path_lb:SetFont("MDispSmallTitle")
	sched_path_lb:SizeToContents()
	
	local sched_path = vgui.Create("DComboBox",sched_panel)
	sched_path:SetPos(200,110)
	sched_path:SetSize(170,25)
	sched_path:SetEnabled(false)
	sched_path:SetValue("Выберите путь")
	
	local sched_start_lb = vgui.Create("DLabel",sched_panel)
	sched_start_lb:SetPos(5,145)
	sched_start_lb:SetSize(100,25)
	sched_start_lb:SetColor(Color(255,255,255))
	sched_start_lb:SetText("Начальная станция:")
	sched_start_lb:SetFont("MDispSmallTitle")
	sched_start_lb:SizeToContents()
	
	local sched_start = vgui.Create("DComboBox",sched_panel)
	sched_start:SetPos(5,165)
	sched_start:SetSize(170,25)
	sched_start:SetEnabled(false)
	sched_start:SetSortItems(false)
	sched_start:SetValue("Выберите станцию")
	
	local sched_last_lb = vgui.Create("DLabel",sched_panel)
	sched_last_lb:SetPos(200,145)
	sched_last_lb:SetSize(100,25)
	sched_last_lb:SetColor(Color(255,255,255))
	sched_last_lb:SetText("Конечная станция:")
	sched_last_lb:SetFont("MDispSmallTitle")
	sched_last_lb:SizeToContents()
	
	local sched_last = vgui.Create("DComboBox",sched_panel)
	sched_last:SetPos(200,165)
	sched_last:SetSize(170,25)
	sched_last:SetEnabled(false)
	sched_last:SetSortItems(false)
	sched_last:SetValue("Выберите станцию")
	
	local sched_get = vgui.Create("DButton",sched_panel)
	sched_get:SetSize(150,25)
	sched_get:SetPos((sched_panel:GetWide()/2)-(sched_get:GetWide()/2)-12,200)
	sched_get:SetEnabled(false)
	sched_get:SetText("Показать")
	sched_get.DoClick = function()
		local _,tab = sched_player:GetSelected()
		local _,start = sched_start:GetSelected()
		local _,last = sched_last:GetSelected()
		SchedulePreiewForm(tab,stations,sched_path:GetSelected(),start,last)
	end
	
	-- динамическое заполнение и блокировки
	sched_player.OnSelect = function()
		sched_line:SetEnabled(true)
	end
	sched_line.OnSelect = function()
		sched_path:Clear()
		sched_path:SetValue("Выберите путь")
		for k,v in pairs(stations[tonumber(sched_line:GetSelected())]) do
			sched_path:AddChoice(k)
		end
		sched_path:SetEnabled(true)
		sched_start:SetEnabled(false)
		sched_last:SetEnabled(false)
		sched_get:SetEnabled(false)
	end
	sched_path.OnSelect = function()
		sched_start:Clear()
		sched_start:SetValue("Выберите станцию")
		for k,v in SortedPairsByMemberValue(stations[tonumber(sched_line:GetSelected())][tonumber(sched_path:GetSelected())],"NodeID") do
			sched_start:AddChoice(v.Name,k)
		end
		sched_start:SetEnabled(true)
		sched_last:SetEnabled(false)
		sched_get:SetEnabled(false)
	end
	sched_start.OnSelect = function()
		sched_last:Clear()
		sched_last:SetValue("Выберите станцию")
		for k,v in SortedPairsByMemberValue(stations[tonumber(sched_line:GetSelected())][tonumber(sched_path:GetSelected())],"NodeID") do
			if v.Name ~= sched_start:GetSelected() then
				sched_last:AddChoice(v.Name,k)
			end
		end
		sched_last:SetEnabled(true)
		sched_get:SetEnabled(false)
	end
	sched_last.OnSelect = function()
		if LocalPlayer():GetNW2Bool("MDispatcher") then
			sched_get:SetEnabled(true)
		end
	end
end

net.Receive("MDispatcher.Commands",function()
	local comm = net.ReadString()
	if comm == "menu" then
		local ln1 = net.ReadUInt(32)
		local signals = util.JSONToTable(util.Decompress(net.ReadData(ln1)))
		local next_signal = net.ReadString()
		local ln2 = net.ReadUInt(32)
		local routes = util.JSONToTable(util.Decompress(net.ReadData(ln2)))
		local ln3 = net.ReadUInt(32)
		local stations = util.JSONToTable(util.Decompress(net.ReadData(ln3)))
		DispatcherMenu(signals,next_signal,routes,stations)
	elseif comm == "cr-add" then
		local cr_name = net.ReadString()
		local cr_pos = net.ReadVector()
		local cr_ang = net.ReadAngle()
		table.insert(MDispatcher.FillControlRooms,{Name = cr_name,Pos = cr_pos,Ang = cr_ang})
		FillDSCPMenu()
	elseif comm == "cr-save-ok" then
		Derma_Message("Блок-посты сохранены успешно! Чтобы увидеть изменения, пожалуйста перезайдите на сервер.", "Меню диспетчера", "OK")
	elseif comm == "sched-send-ok" then
		Derma_Message("Расписание успешно отправлено!", "Меню диспетчера", "OK")
	end
end)