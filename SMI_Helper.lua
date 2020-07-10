script_name('MM-Helper')
script_authors('Cesare Carrizo')
script_description('Mass Media Helper.')
script_version("0.0.1")
script_properties("work-in-pause")

require 'lib.sampfuncs'
require 'lib.moonloader'
local inicfg = require 'inicfg'
local SE = require 'lib.samp.events'
local encoding = require 'encoding'
local requests = require 'requests'
local lanes = require('lanes').configure()
local vkeys = require 'vkeys'
local GK = require 'game.keys'
local weapons = require 'game.weapons'
local memory = require 'memory'
local imgui = require 'imgui'
local fa = require 'faIcons'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local ffi = require "ffi"
ffi.cdef[[
     void keybd_event(int keycode, int scancode, int flags, int extra);
]]

function EmulateKey(key, isDown)
    if not isDown then
        ffi.C.keybd_event(key, 0, 2, 0)
    else
        ffi.C.keybd_event(key, 0, 0, 0)
    end
end

local org = 'Без работный'
local porg = 'None'
local rang = 'Гражданин'
local rang_id = 0
local regDialog = false
ScriptUse = 3

local SET = {
 	settings = {
		rp_time = false,
		rp_give_rank = false,
		rp_uninvite = false,
		is_tag_f = false,
		tag_f = '',
		rp_radio = false
	}
}

local win_state = {}
win_state['menu'] = imgui.ImBool(false)
win_state['efir'] = imgui.ImBool(false)
local text_buffer = imgui.ImBuffer('', 20)

local SeleList = {"Главное меню", "Предпочтения", "Тест "} -- список менюшек для блока "информация"

-- это делалось если не ошибаюсь для выделения выбранного пункта
local SeleListBool = {}
for i = 1, #SeleList do
	SeleListBool[i] = imgui.ImBool(false)
end

function main()
	if not isSampLoaded() or not isSampfuncsLoaded() then return end
	while not isSampAvailable() do wait(100) end
	
	autoupdate("https://github.com/acarrizo228/mm-helper/blob/master/update.json", '['..string.upper(thisScript().name)..']: ', "https://github.com/acarrizo228/mm-helper/blob/master/SMI_Helper.lua")
	sampAddChatMessage('{046D63}[MM Helper]{FFFFFF} Скрипт подгружен в игру. Приятной игры!', -1)
	
	print("Подгружаем настройки скрипта")
	files_add() -- загрузка файлов и подгрузка текстур
	update() -- запуск обновлений
	while not UpdateNahuy do wait(0) end -- пока не проверит обновления тормозим работу
	load_settings()
	
	repeat wait(10) until sampIsLocalPlayerSpawned()
	
	_, myID = sampGetPlayerIdByCharHandle(PLAYER_PED)
	userNick = sampGetPlayerNickname(myID)
	nickName = userNick:gsub('_', ' ')
	
	print("Начинаем получение данных")
	-- регистрация данных статистики в скрипте
	regDialog = true
	wait(5000)
	sampSendChat("/stats")
	while ScriptUse == 3 do wait(0) end -- ожидаем окончания регистрации
	
	sampRegisterChatCommand("mm", cmd_mm)
	sampRegisterChatCommand("time", cmd_time)
	sampRegisterChatCommand("f", fradio)
	sampRegisterChatCommand("r", rradio)
	
	while true do
	wait(0)
		if win_state['menu'].v then
			imgui.Process = true
			imgui.ShowCursor = true
			imgui.LockPlayer = true
			displayHud(false)
			displayRadar(false)
		else
			imgui.Process = false
			imgui.ShowCursor = false
			imgui.LockPlayer = false
			displayHud(true)
			displayRadar(true)
		end
	end

end

function cmd_mm() -- функция открытия основного меню скрипта
		win_state['menu'].v = not win_state['menu'].v
		
		showSet = 1 -- сброс выбора в "информация"
end

function cmd_time() -- функция открытия основного меню скрипта
	lua_thread.create(function()
		if rp_time.v then
			sampSendChat('/me смотрит на свои часы.')
			wait(500)
		end
		sampSendChat ('/time')		
			
	end)
end

function fradio( args ) -- функция открытия основного меню скрипта
	lua_thread.create(function()
		if rp_radio.v then
			sampSendChat('/me приподносит ко рту рацию и что-то говорит.')
			wait(500)
		end
		sampSendChat('/f '..u8:decode(tag_f.v)..' '..args)			
	end)
end

function rradio( args ) -- функция открытия основного меню скрипта
	lua_thread.create(function()
		if rp_radio.v then
			sampSendChat('/me приподносит ко рту рацию и что-то говорит.')
			wait(500)
		end
		sampSendChat ('/r '..args)			
	end)
end

function imgui.ToggleButton(str_id, bool) -- функция хомяка

	local rBool = false
 
	if LastActiveTime == nil then
	   LastActiveTime = {}
	end
	if LastActive == nil then
	   LastActive = {}
	end
 
	local function ImSaturate(f)
	   return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
	end
  
	local p = imgui.GetCursorScreenPos()
	local draw_list = imgui.GetWindowDrawList()
 
	local height = imgui.GetTextLineHeightWithSpacing() + (imgui.GetStyle().FramePadding.y / 2)
	local width = height * 1.55
	local radius = height * 0.50
	local ANIM_SPEED = 0.15
 
	if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
	   bool.v = not bool.v
	   rBool = true
	   LastActiveTime[tostring(str_id)] = os.clock()
	   LastActive[str_id] = true
	end
 
	local t = bool.v and 1.0 or 0.0
 
	if LastActive[str_id] then
	   local time = os.clock() - LastActiveTime[tostring(str_id)]
	   if time <= ANIM_SPEED then
		  local t_anim = ImSaturate(time / ANIM_SPEED)
		  t = bool.v and t_anim or 1.0 - t_anim
	   else
		  LastActive[str_id] = false
	   end
	end
 
	local col_bg
	if imgui.IsItemHovered() then
	   col_bg = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.FrameBgHovered])
	else
	   col_bg = imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.FrameBg])
	end
 
	draw_list:AddRectFilled(p, imgui.ImVec2(p.x + width, p.y + height), col_bg, height * 0.5)
	draw_list:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 1.5, imgui.GetColorU32(bool.v and imgui.GetStyle().Colors[imgui.Col.ButtonActive] or imgui.GetStyle().Colors[imgui.Col.Button]))
 
	return rBool
end

function imgui.OnDrawFrame()
	local tLastKeys = {} -- это у нас для клавиш
	local sw, sh = getScreenResolution() -- получаем разрешение экрана
	local btn_size = imgui.ImVec2(-0.1, 0) -- а это "шаблоны" размеров кнопок
	local btn_size2 = imgui.ImVec2(160, 0)
	local btn_size3 = imgui.ImVec2(140, 0)
	
	if win_state['menu'].v then -- основное меню
		imgui.SetNextWindowPos(imgui.ImVec2(sw/2, sh/2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
		imgui.SetNextWindowSize(imgui.ImVec2(600, 300), imgui.Cond.FirstUseEver)
		imgui.Begin(u8'Основное меню', win_state['menu'], imgui.WindowFlags.NoResize + imgui.WindowFlags.MenuBar)
		if imgui.BeginMenuBar() then -- меню бар, используется в виде выпадающего списка, ибо горизонтальный с ума сходит и мерцает при клике по одному из пунктов
			if imgui.BeginMenu(u8("Основное")) then
				if imgui.MenuItem(u8("Информация")) then
					showSet = 1
				end
				imgui.EndMenu()
			elseif imgui.BeginMenu(u8("Навигация по настройкам")) then
				if imgui.MenuItem(u8("Настройки скрипта")) then
					showSet = 10
				elseif imgui.MenuItem(u8"Настройка эфиров") then
					showSet = 0
				end
				imgui.EndMenu()
			end
			imgui.EndMenuBar()
		end
		if showSet == 0 then 
			imgui.Text(u8("В разработке :)"))
		elseif showSet == 1 then 
			imgui.AlignTextToFramePadding(); imgui.TextColored(imgui.ImVec4(2.34, 1.99, 0.20, 1.0),u8("\t\t\t\t\t\t\t\t\t\t\tMM Helper приветствует вас, "..nickName.."!"))
			imgui.AlignTextToFramePadding(); imgui.TextColored(imgui.ImVec4(0, 0.62, 2.19, 1.0),u8("\t\t\t\t\t\t\t\t\t\t\t\t\t\t\tИгровые данные о игроке"));
			imgui.Separator()
			imgui.Columns(2, _, false)
			imgui.SetColumnWidth(-1, 350);
			imgui.AlignTextToFramePadding(); imgui.TextWrapped(u8("Ваш ник: "..nickName));
			imgui.AlignTextToFramePadding(); imgui.TextWrapped(u8("Ваша организация: "..org))
			imgui.AlignTextToFramePadding(); imgui.TextWrapped(u8("Ваш ID: "..myID))
			imgui.AlignTextToFramePadding(); imgui.TextWrapped(u8("Место работы / Должность: "..porg))	
			imgui.AlignTextToFramePadding(); imgui.TextWrapped(u8("Должность: "..rang.."("..rang_id..")"))
			imgui.NextColumn()
		elseif showSet == 10 then -- что-то типо закрытого меню с красивым названием, но ничего кроме смены стилей тут нет.
			imgui.Text(u8'\t\t\t\t\t\t\tВключение и отключение каких-либо настроек по поводу отыгровки.\n')
			imgui.Separator()
			imgui.Columns(4, _, false)
			imgui.SetColumnWidth(-1, 250);
			imgui.AlignTextToFramePadding(); imgui.Text(u8("Отыгровка /time"));
			imgui.AlignTextToFramePadding(); imgui.Text(u8("РП рация")); 
			
			imgui.NextColumn()
			imgui.SetColumnWidth(-1, 50);
			imgui.ToggleButton(u8'Отыгровка /time', rp_time)
			imgui.ToggleButton(u8'РП рация', rp_radio)
			
			imgui.NextColumn()
			imgui.SetColumnWidth(-1, 250);
			imgui.AlignTextToFramePadding(); imgui.Text(u8("Тэг в /f"));
			
			imgui.NextColumn()
			imgui.SetColumnWidth(-1, 50);
			imgui.ToggleButton(u8'Тэг в /f', is_tag_f)
			
			imgui.Columns(1, _, false)
			imgui.Separator()
			imgui.Text(' ')
			imgui.PushItemWidth(100)
			imgui.AlignTextToFramePadding(); imgui.Text(u8("Введите тэг для /f")); imgui.SameLine(); imgui.InputText(u8'', tag_f)
			imgui.PushItemWidth(0)
		
			
		elseif showSet == 11 then
			if imgui.Button(u8' Отыгровка эфира', btn_size) then efir(1) end
			if imgui.Button(u8' Начала простого эфира', btn_size) then efir(0) end
			if imgui.Button(u8' Начало "Приветы и Поздравления"', btn_size) then efir(2) end
			if imgui.Button(u8' Начало "Ваши объявления"', btn_size) then efir(3) end
			if imgui.Button(u8' Начало "Столицы"', btn_size) then efir(4) end
			if imgui.Button(u8' Начало "Анаграммы"', btn_size) then efir(6) end
			if imgui.Button(u8' Эфир с тектовика', btn_size) then efir(5) end
			if imgui.Button(u8' Закончить эфир ', btn_size) then endefir() end
		end
		
        imgui.End()
	end
end	

function SE.onShowDialog(dialogId, style, title, button1, button2, text)

	if regDialog and title:find('Статистика') then
		local text = sampGetDialogText()
		org = text:match("Организация: 			{0099ff}(.*)\n{FFFFFF}Рабо")
		rang_id = text:match("Ранг: 				{0099ff}(.*)\n{FFFFFF}Выго")
		porg, rang = text:match("Работа/Должность: 		{0099ff}(.*) / (.*)\n{FFFFFF}Ранг")
		print(org)
		print(rang)
		print(porg)
		print(rang_id)
		
		regDialog = false
		ScriptUse = 0
		
		lua_thread.create(function()
			wait(100)
			EmulateKey(VK_RETURN, true)
			wait(1)
			EmulateKey(VK_RETURN, false)
		end)
	end
end

function clearSeleListBool(var)
	for i = 1, #SeleList do
		SeleListBool[i].v = false
	end
	SeleListBool[var].v = true
end

function load_settings() -- загрузка настроек
	-- CONFIG CREATE/LOAD
	ini = inicfg.load(SET, getGameDirectory()..'\\moonloader\\config\\MM-Helper\\settings.ini')
	
	-- LOAD CONFIG INFO
	rp_time = imgui.ImBool(ini.settings.rp_time)
	rp_give_rank = imgui.ImBool(ini.settings.rp_give_rank)
	rp_uninvite = imgui.ImBool(ini.settings.rp_uninvite)
	is_tag_f = imgui.ImBool(ini.settings.is_tag_f)
	rp_radio = imgui.ImBool(ini.settings.rp_radio)
	tag_f = imgui.ImBuffer(u8(ini.settings.tag_f), 256)
	-- END CONFIG WORKING
end

function saveSettings(args, key) -- функция сохранения настроек, args 1 = при отключении скрипта, 2 = при выходе из игры, 3 = сохранение клавиш + текст key, 4 = обычное сохранение.

	ini.settings.rp_time = rp_time.v
	ini.settings.rp_uninvite = rp_uninvite.v
	ini.settings.rp_give_rank = rp_give_rank.v
	ini.settings.rp_radio = rp_radio.v
	
	ini.settings.is_tag_f = is_tag_f.v
	ini.settings.tag_f = u8:decode(tag_f.v)
	

	inicfg.save(SET, "/MM-Helper/settings.ini")
	if args == 1 then
		print("============== SCRIPT WAS TERMINATED ==============")
		print("Настройки и клавиши сохранены в связи.")
		print("MM Helper by Cesare Carrizo, version: "..thisScript().version)

		if doesFileExist(getWorkingDirectory() .. '\\MM-Helper\\files\\regst.data') then
			print("File regst.data is finded")
		else
			print("File regst.data not finded")
		end
		print("==================================================")
	elseif args == 2 then
		print("============== GAME WAS TERMINATED ===============")
		print("==================================================")
	elseif args == 3 and key ~= nil then
		print("============== "..key.." SAVED ==============")
	elseif args == 4 then
		print("============== SAVED ==============")
	end
end

function files_add() -- функция подгрузки медиа файлов
	print("Проверка целостности файлов")
	if not doesFileExist(getGameDirectory()..'\\moonloader\\config\\MM-Helper\\settings.ini') then 
		inicfg.save(SET, getGameDirectory()..'\\moonloader\\config\\MM-Helper\\settings.ini')
	end
end

function onScriptTerminate(script, quitGame) -- действия при отключении скрипта
	if script == thisScript() then
		showCursor(false)
		saveSettings(1)
		
		if quitGame == false then
			lockPlayerControl(false) -- снимаем блок персонажа на всякий
			sampTextdrawDelete(102) -- удаляем текстдрав от VK Int на всякий.

			if not reloadScript then -- выводим текст
				sampAddChatMessage("[MM-Helper]{FFFFFF} Произошла ошибка, скрипт завершил свою работу принудительно.", 0x046D63)
				sampAddChatMessage("[MM-Helper]{FFFFFF} Свяжитесь с разработчиком для уточнения деталей проблемы.", 0x046D63)
			end
		end
	end
end
function apply_custom_style()
	imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4

    style.WindowRounding = 2.0
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.84)
    style.ChildWindowRounding = 2.0
    style.FrameRounding = 2.0
    style.ItemSpacing = imgui.ImVec2(5.0, 4.0)
    style.ScrollbarSize = 13.0
    style.ScrollbarRounding = 0
    style.GrabMinSize = 8.0
    style.GrabRounding = 1.0

    colors[clr.FrameBg]                = ImVec4(0.16, 0.29, 0.48, 0.54)
    colors[clr.FrameBgHovered]         = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.FrameBgActive]          = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.TitleBg]                = ImVec4(0.04, 0.04, 0.04, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.16, 0.29, 0.48, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 0.51)
    colors[clr.CheckMark]              = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.SliderGrab]             = ImVec4(0.24, 0.52, 0.88, 1.00)
    colors[clr.SliderGrabActive]       = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Button]                 = ImVec4(0.26, 0.59, 0.98, 0.40)
    colors[clr.ButtonHovered]          = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.06, 0.53, 0.98, 1.00)
    colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
    colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
    colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.Separator]              = colors[clr.Border]
    colors[clr.SeparatorHovered]       = ImVec4(0.26, 0.59, 0.98, 0.78)
    colors[clr.SeparatorActive]        = ImVec4(0.26, 0.59, 0.98, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.26, 0.59, 0.98, 0.25)
    colors[clr.ResizeGripHovered]      = ImVec4(0.26, 0.59, 0.98, 0.67)
    colors[clr.ResizeGripActive]       = ImVec4(0.26, 0.59, 0.98, 0.95)
    colors[clr.TextSelectedBg]         = ImVec4(0.26, 0.59, 0.98, 0.35)
    colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.06, 0.06, 0.06, 0.94)
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 0.00)
    colors[clr.PopupBg]                = ImVec4(0.08, 0.08, 0.08, 0.94)
    colors[clr.ComboBg]                = colors[clr.PopupBg]
    colors[clr.Border]                 = ImVec4(0.43, 0.43, 0.50, 0.50)
    colors[clr.BorderShadow]           = ImVec4(0.00, 0.00, 0.00, 0.00)
    colors[clr.MenuBarBg]              = ImVec4(0.14, 0.14, 0.14, 1.00)
    colors[clr.ScrollbarBg]            = ImVec4(0.02, 0.02, 0.02, 0.53)
    colors[clr.ScrollbarGrab]          = ImVec4(0.31, 0.31, 0.31, 1.00)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.41, 0.41, 0.41, 1.00)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.51, 0.51, 0.51, 1.00)
    colors[clr.CloseButton]            = ImVec4(0.41, 0.41, 0.41, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.CloseButtonActive]      = ImVec4(0.98, 0.39, 0.36, 1.00)
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.80, 0.80, 0.80, 0.35)
end
apply_custom_style()
-- Фикс зеркального бага alt+tab(черный экран или же какая то хуйня в виде зеркал на экране после разворота в инте)
writeMemory(0x555854, 4, -1869574000, true)
writeMemory(0x555858, 1, 144, true)


-- функция быстрого прогруза игры, кепчик чтоль автор.. Не помню
function patch()
	if memory.getuint8(0x748C2B) == 0xE8 then
		memory.fill(0x748C2B, 0x90, 5, true)
	elseif memory.getuint8(0x748C7B) == 0xE8 then
		memory.fill(0x748C7B, 0x90, 5, true)
	end
	if memory.getuint8(0x5909AA) == 0xBE then
		memory.write(0x5909AB, 1, 1, true)
	end
	if memory.getuint8(0x590A1D) == 0xBE then
		memory.write(0x590A1D, 0xE9, 1, true)
		memory.write(0x590A1E, 0x8D, 4, true)
	end
	if memory.getuint8(0x748C6B) == 0xC6 then
		memory.fill(0x748C6B, 0x90, 7, true)
	elseif memory.getuint8(0x748CBB) == 0xC6 then
		memory.fill(0x748CBB, 0x90, 7, true)
	end
	if memory.getuint8(0x590AF0) == 0xA1 then
		memory.write(0x590AF0, 0xE9, 1, true)
		memory.write(0x590AF1, 0x140, 4, true)
	end
end
patch()

function autoupdate(json_url, prefix, url)
  local dlstatus = require('moonloader').download_status
  local json = getWorkingDirectory() .. '\\'..thisScript().name..'-version.json'
  if doesFileExist(json) then os.remove(json) end
  downloadUrlToFile(json_url, json,
    function(id, status, p1, p2)
      if status == dlstatus.STATUSEX_ENDDOWNLOAD then
        if doesFileExist(json) then
          local f = io.open(json, 'r')
          if f then
            local info = decodeJson(f:read('*a'))
            updatelink = info.updateurl
            updateversion = info.latest
            f:close()
            os.remove(json)
            if updateversion ~= thisScript().version then
              lua_thread.create(function(prefix)
                local dlstatus = require('moonloader').download_status
                local color = -1
                sampAddChatMessage((prefix..'Обнаружено обновление. Пытаюсь обновиться c '..thisScript().version..' на '..updateversion), color)
                wait(250)
                downloadUrlToFile(updatelink, thisScript().path,
                  function(id3, status1, p13, p23)
                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                      print(string.format('Загружено %d из %d.', p13, p23))
                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                      print('Загрузка обновления завершена.')
                      sampAddChatMessage((prefix..'Обновление завершено!'), color)
                      goupdatestatus = true
                      lua_thread.create(function() wait(500) thisScript():reload() end)
                    end
                    if status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                      if goupdatestatus == nil then
                        sampAddChatMessage((prefix..'Обновление прошло неудачно. Запускаю устаревшую версию..'), color)
                        update = false
                      end
                    end
                  end
                )
                end, prefix
              )
            else
              update = false
              print('v'..thisScript().version..': Обновление не требуется.')
            end
          end
        else
          print('v'..thisScript().version..': Не могу проверить обновление. Смиритесь или проверьте самостоятельно на '..url)
          update = false
        end
      end
    end
  )
  while update ~= false do wait(100) end
end