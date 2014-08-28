------------------------------------------------------
-- #模块名：邮件仓库模块
-- #模块说明：增强邮件功能
------------------------------------------------------
local L = AH_Library.LoadLangPack()

_G["AH_MailBank_Loaded"] = true

AH_MailBank = {
	tItemCache = {},
	tSendCache = {},
	tMoneyCache = {},
	tMoneyPayCache = {},
	szDataPath = "\\Interface\\AH\\AH_Base\\data\\mail.jx3dat",
	szCurRole = nil,
	nCurIndex = 1,
	szCurKey = "",
	nFilterType = 1,
	bShowNoReturn = false,
	bAutoExange = false,
	bMail = true,
	dwMailNpcID = nil,
	szReceiver = nil,
	bPay = false,
}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/AH_Mailbank/AH_MailBank.ini"
local bMailHooked = false
local bBagHooked = false
local bInitMail = false
local tFilterType = {
	L("STR_MAILBANK_ITEMNAME"),
	L("STR_MAILBANK_MAILTITLE"),
	L("STR_MAILBANK_SENDER"),
	L("STR_MAILBANK_ENDDATE")
}

-- 将数据分页处理，每页98个数据，返回分页数据和页数
function AH_MailBank.GetPageMailData(tItemCache)
	--先对传入的表以邮件ID进行排序
	table.sort(tItemCache, function(a, b)
		local function max(t)
			local index = table.maxn(t)
			return t[index]
		end
		if max(a.tMailIDs) == max(b.tMailIDs) then
			return a.nUiId > b.nUiId
		else
			return max(a.tMailIDs) > max(b.tMailIDs) end
		end
	)
	local tItems, nIndex = {}, 1
	for k, v in ipairs(tItemCache) do
		tItems[nIndex] = tItems[nIndex] or {}
		table.insert(tItems[nIndex], v)
		nIndex = math.ceil(k / 97)
	end
	return tItems, nIndex
end

-- 是否离线邮件
local function IsOfflineMail()
	if GetClientPlayer().szName ~= AH_MailBank.szCurRole or not AH_MailBank.bMail then
		return true
	end
	return false
end

-- 按页加载该角色的物品数据
function AH_MailBank.LoadMailData(frame, szName, nIndex)
	local handle = frame:Lookup("", "")
	local hBg = handle:Lookup("Handle_Bg")
	local hBox = handle:Lookup("Handle_Box")

	--附加数据
	local tItemCache = AH_MailBank.bShowNoReturn and AH_MailBank.SaveItemCache(false) or AH_MailBank.tItemCache[szName]
	local tCache, nMax = AH_MailBank.GetPageMailData(tItemCache)
	local i = 0
	nIndex = math.max(1, nIndex)
	for k, v in ipairs(tCache[nIndex] or {}) do
		if v.szName == "money" then
			local img = hBg:Lookup(k - 1)
			local box = hBox:Lookup(k - 1)
			img:Show()
			box:Show()
			box.szType = "money"
			box.szName = L("STR_MAILBANK_MONEY")
			box.data = v
			box:SetObject(UI_OBJECT_NOT_NEED_KNOWN, 0)
			box:SetObjectIcon(582)
			box:SetAlpha(255)
			box:SetOverTextFontScheme(0, 15)
			box:SetOverText(0, "")
		else
			local img = hBg:Lookup(k - 1)
			local box = hBox:Lookup(k - 1)
			img:Show()
			box:Show()
			box.szType = "item"
			box.szName = v.szName
			box.data = v
			box:SetObject(UI_OBJECT_ITEM_ONLY_ID, v.nUiId, v.dwID, v.nVersion, v.dwTabType, v.dwIndex)
			box:SetObjectIcon(Table_GetItemIconID(v.nUiId))
			box:SetAlpha(255)
			box:SetOverTextFontScheme(0, 15)
			if not IsOfflineMail() then
				local item = GetItem(v.dwID)
				if item then
					UpdateItemBoxExtend(box, item.nGenre, item.nQuality, item.nStrengthLevel)
				end
				local mail = GetMailClient().GetMailInfo(v.tMailIDs[1])
				if mail then
					local nTime = mail.GetLeftTime()
					if nTime <= 86400 * 2 then
						box:SetOverText(1, L("STR_MAILBANK_WILLEND"))
					else
						box:SetOverText(1, "")
					end
				end
			end
			if v.nStack > 1 then
				box:SetOverText(0, v.nStack)
			else
				box:SetOverText(0, "")
			end
		end
		i = k
	end
	--隐藏其余box
	for j = i, 97, 1 do
		local img = hBg:Lookup(j)
		local box = hBox:Lookup(j)
		if box:IsVisible() then
			img:Hide()
			box:Hide()
		end
	end

	frame:Lookup("", ""):Lookup("Text_Account"):SetText(szName)
	-- 翻页处理
	local hPrev, hNext = frame:Lookup("Btn_Prev"), frame:Lookup("Btn_Next")
	local hPage = frame:Lookup("", ""):Lookup("Text_Page")
	if nMax > 1 then
		hPrev:Show()
		hNext:Show()
		hPage:Show()
		if nIndex == 1 then
			hPrev:Enable(false)
			hNext:Enable(true)
		elseif nIndex == nMax then
			hPrev:Enable(true)
			hNext:Enable(false)
		else
			hPrev:Enable(true)
			hNext:Enable(true)
		end
		hPage:SetText(string.format("%d/%d", nIndex, nMax))
	else
		hPrev:Hide()
		hNext:Hide()
		hPage:Hide()
	end
	--筛选处理
	frame:Lookup("", ""):Lookup("Text_Filter"):SetText(tFilterType[AH_MailBank.nFilterType])
	local hType = frame:Lookup("", ""):Lookup("Text_Type")
	if AH_MailBank.nFilterType == 4 then
		hType:SetText(L("STR_MAILBANK_LESSTHAN"))
	else
		hType:SetText(L("STR_MAILBANK_WITHIN"))
	end
	frame:Lookup("Btn_Filter"):Enable(not IsOfflineMail())
	frame:Lookup("Check_NotReturn"):Enable(not IsOfflineMail())
	local tColor = (not IsOfflineMail()) and {255, 255, 255} or {180, 180, 180}
	frame:Lookup("", ""):Lookup("Text_Filter"):SetFontColor(unpack(tColor))
	frame:Lookup("", ""):Lookup("Text_NotReturn"):SetFontColor(unpack(tColor))
end

-- 以邮件标题筛选
local function IsMailTitleExist(data, szKey)
	local MailClient = GetMailClient()
	for k, v in ipairs(data) do
		local mail = MailClient.GetMailInfo(v)
		if StringFindW(mail.szTitle, szKey) then
			return true
		end
	end
	return false
end

-- 以寄信人筛选
local function IsMailSenderNameExist(data, szKey)
	local MailClient = GetMailClient()
	for k, v in ipairs(data) do
		local mail = MailClient.GetMailInfo(v)
		if StringFindW(mail.szSenderName, szKey) then
			return true
		end
	end
	return false
end

-- 以剩余时间筛选
local function IsLessMailItemTime(data, szKey)
	local nLeft = 86400 * tonumber(szKey) or 0
	local MailClient = GetMailClient()
	for k, v in ipairs(data) do
		local mail = MailClient.GetMailInfo(v)
		if mail.GetLeftTime() < nLeft then
			return true
		end
	end
	return false
end

-- 过滤物品
function AH_MailBank.FilterMailItem(frame, szKey)
	local handle = frame:Lookup("", "")
	local hBox = handle:Lookup("Handle_Box")
	for i = 0, 97, 1 do
		local box = hBox:Lookup(i)
		if not box:IsEmpty() then
			local bExist = false
			if AH_MailBank.nFilterType == 1 then
				bExist = (StringFindW(box.szName, szKey) ~= nil)
			elseif AH_MailBank.nFilterType == 2 then
				bExist = IsMailTitleExist(box.data[6], szKey)
			elseif AH_MailBank.nFilterType == 3 then
				bExist = IsMailSenderNameExist(box.data[6], szKey)
			elseif AH_MailBank.nFilterType == 4 then
				bExist = IsLessMailItemTime(box.data[6], szKey)
			end
			if bExist then
				box:SetAlpha(255)
				box:SetOverTextFontScheme(0, 15)
			else
				box:SetAlpha(50)
				box:SetOverTextFontScheme(0, 30)
			end
		end
	end
end

-- 保存邮件物品数据，以物品nUiId为key的数据表，同种物品全部累加，每种物品包含所属邮件ID
function AH_MailBank.SaveItemCache(bAll)
	local MailClient = GetMailClient()
	local tMail = MailClient.GetMailList("all") or {}
	local tItems, tCount, tMailIDs, nMoney = {}, {}, {}, 0
	for _, dwID in ipairs(tMail) do
		local mail = MailClient.GetMailInfo(dwID)
		if mail then
			mail.RequestContent(AH_MailBank.dwMailNpcID)
		end
		if bAll or (not bAll and not (mail.GetType() == MAIL_TYPE.PLAYER and (mail.bMoneyFlag or mail.bItemFlag))) then
			local tItem = AH_MailBank.GetMailItem(mail)
			for k, v in pairs(tItem) do
				--存储物品所属邮件ID
				if not tMailIDs[k] then
					tMailIDs[k] = {dwID}
				else
					table.insert(tMailIDs[k], dwID)
				end
				--用无索引表存储物品数据，便于排序
				if k == "money" then
					--nMoney = MoneyOptAdd(nMoney, v)
					tItems = AH_MailBank.InsertData(tItems, {
						szName = "money",
						nMoney = v,
						nUiId = -1,
						tMailIDs = tMailIDs["money"]
					})
				else
					tItems = AH_MailBank.InsertData(tItems, {
						szName = k,
						dwID = v[1],
						nVersion = v[2],
						dwTabType = v[3],
						dwIndex = v[4],
						nStack = v[5],
						nUiId = v[6],
						tMailIDs = tMailIDs[k]
					})
				end
			end
		end
	end
	return tItems	--返回无索引的物品表
end

function AH_MailBank.InsertData(tItems, tData)
	local function _get(tItems, szName)
		for k, v in ipairs(tItems) do
			if v.szName == szName then
				return v
			end
		end
		return false
	end
	local v = _get(tItems, tData.szName)
	if not v then
		table.insert(tItems, tData)
	else
		if tData.szName == "money" then
			v.nMoney = MoneyOptAdd(v.nMoney, tData.nMoney)
		else
			v.nStack = v.nStack + tData.nStack
		end
	end
	return tItems
end

-- 获取单封邮件的所有物品数据，包括金钱，同种物品做个数累加处理
function AH_MailBank.GetMailItem(mail)
	local tItems, tCount = {}, {}
	if mail.bItemFlag then
		for i = 0, 7, 1 do
			local item = mail.GetItem(i)
			if item then
				local szKey = GetItemNameByItem(item)
				local nStack = (item.bCanStack) and item.nStackNum or 1
				tCount[szKey] = tCount[szKey] or 0	--邮箱内同种物品计数器
				if not tItems[szKey] then
					tCount[szKey] = nStack
					tItems[szKey] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, nStack, item.nUiId}
				else
					tCount[szKey] = tCount[szKey] + nStack
					tItems[szKey] = {item.dwID, item.nVersion, item.dwTabType, item.dwIndex, tCount[szKey], item.nUiId}
				end
			end
		end
	end
	if mail.bMoneyFlag and mail.nMoney ~= 0 then
		tItems["money"] = mail.nMoney
	end
	return tItems
end

function AH_MailBank.OnUpdate()
	local frame = Station.Lookup("Normal/MailPanel")
	if frame and frame:IsVisible() then
		if not bMailHooked then	--邮件界面添加按钮
			local page = frame:Lookup("PageSet_Total/Page_Receive")
			local temp = Wnd.OpenWindow("Interface\\AH\\AH_Base\\AH_Widget.ini")
			if not page:Lookup("Btn_MailBank") then
				local hBtnMailBank = temp:Lookup("Btn_MailBank")
				if hBtnMailBank then
					hBtnMailBank:ChangeRelation(page, true, true)
					hBtnMailBank:SetRelPos(50, 8)
					hBtnMailBank:Lookup("", ""):Lookup("Text_MailBank"):SetText(L("STR_MAILBANK_MAILTIP1"))
					hBtnMailBank.OnLButtonClick = function()
						if not AH_MailBank.IsPanelOpened() then
							AH_MailBank.bMail = true
							AH_MailBank.nFilterType = 1
							AH_MailBank.OpenPanel()
						else
							AH_MailBank.ClosePanel()
						end
					end
				end
				local hBtnLootAll = temp:Lookup("Btn_Loot")
				if hBtnLootAll then
					hBtnLootAll:ChangeRelation(page, true, true)
					hBtnLootAll:SetRelPos(680, 380)
					hBtnLootAll.OnLButtonClick = function()
						AH_MailBank.LootAllItem()
					end
					hBtnLootAll.OnMouseEnter = function()
						local x, y = this:GetAbsPos()
						local w, h = this:GetSize()
						local szTip = GetFormatText(L("STR_MAILBANK_LOOTALL"), 162)
						OutputTip(szTip, 400, {x, y, w, h})
					end
					hBtnLootAll.OnMouseLeave = function()
						HideTip()
					end
				end
			end
			page = frame:Lookup("PageSet_Total/Page_Send")
			if not page:Lookup("Check_AutoExange") then	--添加选择框
				local hCheck = temp:Lookup("Check_AutoExange")
				if hCheck then
					hCheck:ChangeRelation(page, true, true)
					hCheck:SetRelPos(400, 480)
					hCheck:Lookup("", ""):Lookup("Text_AutoExange"):SetText(L("STR_MAILBANK_AUTOEXANGE"))
					hCheck.OnCheckBoxCheck = function()
						AH_MailBank.bAutoExange = true
					end
					hCheck.OnCheckBoxUncheck = function()
						AH_MailBank.bAutoExange = false
					end
				end
			end
			local hBtnSend = page:Lookup("Btn_Deliver") --Hook发送按钮
			hBtnSend.OnLButtonDown = function()
				AH_MailBank.tSendCache = {}
				if AH_MailBank.bAutoExange then
					--收信人
					local szReceiver = page:Lookup("Edit_Name"):GetText()
					if szReceiver and szReceiver ~= AH_MailBank.szReceiver then
						AH_MailBank.szReceiver = szReceiver
					end
					--物品
					local handle = page:Lookup("", "Handle_Write")
					for i = 0, 7, 1 do
						local box = handle:Lookup("Box_Item"..i)
						if not box:IsEmpty() then
							local nUiId, dwBox, dwX = box:GetObjectData()
							local nCount = box:GetOverText(0)
							nCount = (nCount == "") and 1 or tonumber(nCount)
							table.insert(AH_MailBank.tSendCache, {nUiId, nCount})
						end
					end	
					--付费信件
					local bPay = page:Lookup("CheckBox_PayMail"):IsCheckBoxChecked()
					AH_MailBank.bPay = bPay
					if bPay then
						local szGoldPay = page:Lookup("Edit_GoldPay"):GetText()
						local szSilverPay = page:Lookup("Edit_SilverPay"):GetText()
						local szCopperPay = page:Lookup("Edit_CopperPay"):GetText()
						AH_MailBank.tMoneyPayCache = {
							nGoldPay = (szGoldPay ~= "") and tonumber(szGoldPay) or 0,
							nSilverPay = (szSilverPay ~= "") and tonumber(szSilverPay) or 0,
							nCopperPay = (szCopperPay ~= "") and tonumber(szCopperPay) or 0,
						}
					else	--寄出金钱
						local szGold = page:Lookup("Edit_Gold"):GetText()
						local szSilver = page:Lookup("Edit_Silver"):GetText()
						local szCopper = page:Lookup("Edit_Copper"):GetText()
						AH_MailBank.tMoneyCache = {
							nGold = (szGold ~= "") and tonumber(szGold) or 0,
							nSilver = (szSilver ~= "") and tonumber(szSilver) or 0,
							nCopper = (szCopper ~= "") and tonumber(szCopper) or 0,
						}
					end
				end
			end

			AH_MailBank.dwMailNpcID = Station.Lookup("Normal/Target").dwID

			Wnd.CloseWindow(temp)
			bMailHooked = true
		end
		--获取邮件
		if not bInitMail then
			local MailClient = GetMailClient()
			AH_Library.DelayCall(0.5 + GetPingValue() / 2000, function()
				local tMail = MailClient.GetMailList("all") or {}
				--local nIndex, nTol = 0, #tMail
				local nTol = #tMail
				for nIndex, dwID in ipairs(tMail) do
					--300毫秒请求一次服务器，防止邮件过多卡掉线
					AH_Library.DelayCall(0.3 * nIndex + GetPingValue() / 2000, function()
						local mail = MailClient.GetMailInfo(dwID)
						mail.RequestContent(AH_MailBank.dwMailNpcID)
						frame:Lookup("PageSet_Total/Page_Receive", "Text_ReceiveTitle"):SetText(L("STR_MAILBANK_REQUEST", nIndex, nTol))
					end)
				end
			end)
			bInitMail = true
		end
		if GetLogicFrameCount() % 4 == 0 then
			local szName = GetClientPlayer().szName
			AH_MailBank.tItemCache[szName] = AH_MailBank.SaveItemCache(true)
		end
	elseif not frame or not frame:IsVisible() then
		bMailHooked, bInitMail = false, false
	end

	local frame = Station.Lookup("Normal/BigBagPanel")
	if not bBagHooked and frame and frame:IsVisible() then --背包界面添加一个按钮
		local temp = Wnd.OpenWindow("Interface\\AH\\AH_Base\\AH_Widget.ini")
		if not frame:Lookup("Btn_Mail") then
			local hBtnMail = temp:Lookup("Btn_Mail")
			if hBtnMail then
				hBtnMail:ChangeRelation(frame, true, true)
				hBtnMail:SetRelPos(55, 0)
				hBtnMail.OnLButtonClick = function()
					if not AH_MailBank.IsPanelOpened() then
						AH_MailBank.bMail = false
						AH_MailBank.OpenPanel()
					else
						AH_MailBank.ClosePanel()
					end
				end
				hBtnMail.OnMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = GetFormatText(L("STR_MAILBANK_MAILTIP1"), 163) .. GetFormatText("\n" .. L("STR_MAILBANK_MAILTIP2"), 162)
					OutputTip(szTip, 400, {x, y, w, h})
				end
				hBtnMail.OnMouseLeave = function()
					HideTip()
				end
			end
		end
		Wnd.CloseWindow(temp)
		bBagHooked = true
	elseif not frame or not frame:IsVisible() then
		bBagHooked = false
	end
end

-- 附件剩余时间格式化
function AH_MailBank.FormatItemLeftTime(nTime)
	if nTime >= 86400 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_DAY, math.floor(nTime / 86400))
	elseif nTime >= 3600 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_HOURE, math.floor(nTime / 3600))
	elseif nTime >= 60 then
		return FormatString(g_tStrings.STR_MAIL_LEFT_MINUTE, math.floor(nTime / 60))
	else
		return g_tStrings.STR_MAIL_LEFT_LESS_ONE_M
	end
end

-- 取附件
function AH_MailBank.TakeMailItemToBag(fnAction, nCount)
	--限制距离取件
	if AH_MailBank.dwMailNpcID and GetNpc(AH_MailBank.dwMailNpcID) then
		local nDist = GetCharacterDistance(UI_GetClientPlayerID(), AH_MailBank.dwMailNpcID) / 64
		if nDist > 4 then
			return
		end
	end
	local tFreeBoxList = AH_Library.GetPlayerBagFreeBoxList()
	if nCount > #tFreeBoxList then
		AH_Library.Message(L("STR_MAILBANK_TIP2"))
		OutputWarningMessage("MSG_NOTICE_YELLOW", L("STR_MAILBANK_TIP2"), 2)
		return
	end
	pcall(fnAction)
end

function AH_MailBank.LootAllItem()
	local dwID = Station.Lookup("Normal/MailPanel"):Lookup("PageSet_Total/Page_Receive").dwShowID
	local MailClient = GetMailClient()
	local mailInfo = MailClient.GetMailInfo(dwID)
	if not mailInfo then
		return
	end
	if mailInfo.bMoneyFlag then
		mailInfo.TakeMoney()
	end
	if mailInfo.bItemFlag then
		for i = 0, 7, 1 do
			local item = mailInfo.GetItem(i)
			if item then	
				AH_Library.DelayCall(0.2 * i + GetPingValue() / 2000, function()
					mailInfo.TakeItem(i)
				end)
			end
		end
	end
end

-- 重新筛选
function AH_MailBank.ReFilter(frame)
	if AH_MailBank.szCurKey ~= "" then
		AH_MailBank.FilterMailItem(frame, AH_MailBank.szCurKey)
	end
end

-- 检查当前角色
function AH_MailBank.CheckCurRole(frame)
	AH_MailBank.nFilterType = 1
	frame:Lookup("", ""):Lookup("Text_Filter"):SetText(tFilterType[AH_MailBank.nFilterType])
	local bTrue = (AH_MailBank.szCurRole == GetClientPlayer().szName)
	frame:Lookup("Btn_Filter"):Enable(bTrue)
	frame:Lookup("Check_NotReturn"):Enable(bTrue)
end

local function GetItemBox(tCache)
	local player = GetClientPlayer()
	for nIndex = 6, 1, -1 do
		local dwBox = INVENTORY_INDEX.PACKAGE + nIndex - 1
		local dwSize = player.GetBoxSize(dwBox)
		if dwSize > 0 then
			for dwX = dwSize, 1, -1 do
				local box = GetUIItemBox(dwBox, dwX - 1, true)
				if box and box:IsObjectEnable() then
					local item = player.GetItem(dwBox, dwX - 1)
					if item and item.nUiId == tCache[1] then
						if not item.bCanStack or (item.bCanStack and item.nStackNum == tCache[2]) then
							local i, j = dwBox, dwX - 1
							return i, j
						end
					end
				end
			end
		end
	end
end

local function UpdateItemLock(handle)
	RemoveUILockItem("mail")
	if handle then
		for i = 0, 7, 1 do
			local box = handle:Lookup("Box_Item"..i)
			if not box:IsEmpty() then
				AddUILockItem("mail", box.nBag, box.nIndex)
			end
		end
	end
end

-- 自动放置上一次寄件的物品
function AH_MailBank.OnExchangeItem()
	local page = Station.Lookup("Normal/MailPanel/PageSet_Total/Page_Send")
	if not page then
		return
	end
	local handle = page:Lookup("", "Handle_Write")
	if not handle then
		return
	end

	--放置物品
	for nIndex, tCache in ipairs(AH_MailBank.tSendCache) do
		local dwBox, dwX = GetItemBox(tCache)
		local item = GetPlayerItem(GetClientPlayer(), dwBox, dwX)
		if item and not item.bBind then
			local box = handle:Lookup("Box_Item" .. nIndex - 1)
			if not box.bDisable and box:IsEmpty() then
				box:SetObject(UI_OBJECT_ITEM, item.nUiId, dwBox, dwX, item.nVersion, item.dwTabType, item.dwIndex)
				box:SetObjectIcon(Table_GetItemIconID(item.nUiId))
				UpdateItemBoxExtend(box, item)
				box.nBag = dwBox
				box.nIndex = dwX
				if item and item.bCanStack and item.nStackNum > 1 then
					box:SetOverText(0, item.nStackNum)
				else
					box:SetOverText(0, "")
				end
				UpdateItemLock(handle)
				local edit = page:Lookup("Edit_Title")
				if edit:GetText() == "" then
					edit:SetText(GetItemNameByItem(item))
				end
				page:Lookup("Edit_Name"):SetText(AH_MailBank.szReceiver)
			end
		end
	end
	if AH_MailBank.bPay then	--付费邮件
		page:Lookup("CheckBox_PayMail"):Check(true)
		for k, v in ipairs({"Edit_GoldPay", "Edit_SilverPay", "Edit_CopperPay"}) do
			local szKey = string.format("n%s", v:match("Edit_(%a+)"))
			page:Lookup(v):SetText(AH_MailBank.tMoneyPayCache[szKey])
		end
	else	--放置金钱
		for k, v in ipairs({"Edit_Gold", "Edit_Silver", "Edit_Copper"}) do
			local szKey = string.format("n%s", v:match("Edit_(%a+)"))
			page:Lookup(v):SetText(AH_MailBank.tMoneyCache[szKey])
		end
	end
end
------------------------------------------------------------
-- 回调函数
------------------------------------------------------------
function AH_MailBank.OnFrameCreate()
	local handle = this:Lookup("", "")
	handle:Lookup("Text_Title"):SetText(L("STR_MAILBANK_MAILTIP1"))
	handle:Lookup("Text_Tips"):SetText(L("STR_MAILBANK_TIP3"))
	handle:Lookup("Text_NotReturn"):SetText(L("STR_MAILBANK_NORETURN"))
	this:Lookup("Btn_Prev"):Lookup("", ""):Lookup("Text_Prev"):SetText(L("STR_MAILBANK_PREV"))
	this:Lookup("Btn_Next"):Lookup("", ""):Lookup("Text_Next"):SetText(L("STR_MAILBANK_NEXT"))

	local hBg = handle:Lookup("Handle_Bg")
	local hBox = handle:Lookup("Handle_Box")
	hBg:Clear()
	hBox:Clear()
	local nIndex = 0
	for i = 1, 7, 1 do
		for j = 1, 14, 1 do
			hBg:AppendItemFromString("<image>w=52 h=52 path=\"ui/Image/LootPanel/LootPanel.UITex\" frame=13 </image>")
			local img = hBg:Lookup(nIndex)
			hBox:AppendItemFromString("<box>w=48 h=48 eventid=304 </box>")
			local box = hBox:Lookup(nIndex)
			box.nIndex = nIndex
			box.bItemBox = true
			local x, y = (j - 1) * 52, (i - 1) * 52
			img:SetRelPos(x, y)
			box:SetRelPos(x + 2, y + 2)
			box:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
			box:SetOverTextFontScheme(0, 15)
			box:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
			box:SetOverTextFontScheme(1, 16)
			img:Hide()
			box:Hide()

			nIndex = nIndex + 1
		end
	end
	hBg:FormatAllItemPos()
	hBox:FormatAllItemPos()
end

function AH_MailBank.OnEditChanged()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Edit_Search" then
		AH_MailBank.szCurKey = this:GetText()
		AH_MailBank.FilterMailItem(frame, AH_MailBank.szCurKey)
	end
end

function AH_MailBank.OnCheckBoxCheck()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Check_NotReturn" then
		AH_MailBank.bShowNoReturn = true
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	end
end

function AH_MailBank.OnCheckBoxUncheck()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Check_NotReturn" then
		AH_MailBank.bShowNoReturn = false
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	end
end

function AH_MailBank.OnLButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if szName == "Btn_Close" then
		AH_MailBank.ClosePanel()
	elseif szName == "Btn_Account" then
		local hText = frame:Lookup("", ""):Lookup("Text_Account")
		local x, y = hText:GetAbsPos()
		local w, h = hText:GetSize()
		local menu = {}
		menu.nMiniWidth = w + 20
		menu.x = x
		menu.y = y + h
		for k, v in pairs(AH_MailBank.tItemCache) do
			local m = {
				szOption = k,
				fnAction = function()
					AH_MailBank.szCurRole = k
					AH_MailBank.LoadMailData(frame, k, 1)
					AH_MailBank.ReFilter(frame)
					AH_MailBank.CheckCurRole(frame)
				end
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Filter" then
		local hText = frame:Lookup("", ""):Lookup("Text_Filter")
		local x, y = hText:GetAbsPos()
		local w, h = hText:GetSize()
		local menu = {}
		menu.nMiniWidth = w + 20
		menu.x = x
		menu.y = y + h
		for k, v in ipairs(tFilterType) do
			local m = {
				szOption = v,
				fnAction = function()
					hText:SetText(v)
					AH_MailBank.nFilterType = k
					local hType = frame:Lookup("", ""):Lookup("Text_Type")
					if k == 4 then
						hType:SetText(L("STR_MAILBANK_LESSTHAN"))
					else
						hType:SetText(L("STR_MAILBANK_WITHIN"))
					end
					AH_MailBank.ReFilter(frame)
				end
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Setting" then
		local menu = {}
		for k, v in pairs(AH_MailBank.tItemCache) do
			local m = {
				szOption = k,
				{
					szOption = L("STR_MAILBANK_DELETE"),
					fnAction = function()
						AH_MailBank.tItemCache[k] = nil
					end
				}
			}
			table.insert(menu, m)
		end
		PopupMenu(menu)
	elseif szName == "Btn_Prev" then
		AH_MailBank.nCurIndex = AH_MailBank.nCurIndex - 1
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	elseif szName == "Btn_Next" then
		AH_MailBank.nCurIndex = AH_MailBank.nCurIndex + 1
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	elseif szName == "Btn_Refresh" then
		AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
		AH_MailBank.ReFilter(frame)
	end
end

function AH_MailBank.OnItemLButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local d = this.data
		if this.szType == "item" then
			local item = GetItem(d.dwID)
			if item then
				local MailClient = GetMailClient()
				local n = 0	--物品个数计数器
				for k, v in ipairs(d.tMailIDs) do
					local mail = MailClient.GetMailInfo(v)
					if mail.bItemFlag then
						for i = 0, 7, 1 do
							local item2 = mail.GetItem(i)
							if item2 and item2.nUiId == d.nUiId then
								n = n + 1
								AH_Library.DelayCall(0.2 * n + GetPingValue() / 2000, function()
									AH_MailBank.TakeMailItemToBag(function() mail.TakeItem(i) end, 1)
									if not mail.bReadFlag then
										mail.Read()
									end
								end)	--循环取附件得间隔一定时间，否则无法全部取出，需要加上延迟
							end
						end
					end
				end
				AH_Library.DelayCall(0.8 + 0.2 * n + GetPingValue() / 2000, function()
					AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
				end)
			end
		elseif this.szType == "money" then
			local MailClient = GetMailClient()
			local n = 0	--物品个数计数器
			for k, v in ipairs(d.tMailIDs) do
				local mail = MailClient.GetMailInfo(v)
				if mail.bMoneyFlag then
					n = n + 1
					AH_Library.DelayCall(0.2 * n + GetPingValue() / 2000, function()
						AH_MailBank.TakeMailItemToBag(function() mail.TakeMoney() end, 0)
						if not mail.bReadFlag then
							mail.Read()
						end
					end)
				end
			end
			AH_Library.DelayCall(0.8 + 0.2 * n + GetPingValue() / 2000, function()
				AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
			end)
		end
	end
end

function AH_MailBank.OnItemRButtonClick()
	local szName, frame = this:GetName(), this:GetRoot()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)
	local box = this
	if not this:IsEmpty() then
		local d = this.data
		if this.szType == "item" then
			local item = GetItem(d.dwID)
			if item then
				local menu = {}
				local MailClient = GetMailClient()
				for k, v in ipairs(d.tMailIDs) do
					local mail = MailClient.GetMailInfo(v)
					if mail.bItemFlag then
						local m = {
							szOption = string.format(" %s『%s』", mail.szSenderName, mail.szTitle),
							szIcon = "UI\\Image\\UICommon\\CommonPanel2.UITex",
							nFrame = 105,
							nMouseOverFrame = 106,
							szLayer = "ICON_LEFT",
							fnClickIcon = function()
								local n = 0
								for i = 0, 7, 1 do
									local item2 = mail.GetItem(i)
									if item2 and item2.nUiId == d.nUiId then
										n = n + 1
										AH_Library.DelayCall(0.2 * n + GetPingValue() / 2000, function()
											AH_MailBank.TakeMailItemToBag(function() mail.TakeItem(i) end, 1)
											if not mail.bReadFlag then
												mail.Read()
											end
										end)
									end
								end
								Wnd.CloseWindow("PopupMenuPanel")
								AH_Library.DelayCall(0.8 + 0.2 * n + GetPingValue() / 2000, function()
									AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
								end)
							end
						}
						for i = 0, 7, 1 do
							local item2 = mail.GetItem(i)
							if item2 and item2.nUiId == d.nUiId then
								local nStack = (item2.bCanStack) and item2.nStackNum or 1
								local m_1 = {
									szOption = string.format("%s x%d", GetItemNameByItem(item2), nStack),
									fnAction = function()
										AH_MailBank.TakeMailItemToBag(function() mail.TakeItem(i) end, 1)
										if not mail.bReadFlag then
											mail.Read()
										end
										AH_Library.DelayCall(0.8, function()
											AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
										end)
									end,
									fnAutoClose = function() return true end
								}
								table.insert(m, m_1)
							end
						end
						table.insert(menu, m)
					end
				end
				PopupMenu(menu)
			end
		elseif this.szType == "money" then
			local menu = {}
			local MailClient = GetMailClient()
			for k, v in ipairs(d.tMailIDs) do
				local mail = MailClient.GetMailInfo(v)
				if mail.bMoneyFlag then
					local m = {
						szOption = string.format("%s『%s』", mail.szSenderName, mail.szTitle),
						{
							szOption = GetMoneyPureText(FormatMoneyTab(mail.nMoney)),
							fnAction = function()
								AH_MailBank.TakeMailItemToBag(function() mail.TakeMoney() end, 0)
								if not mail.bReadFlag then
									mail.Read()
								end
								AH_Library.DelayCall(0.8, function()
									AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
								end)
							end,
							fnAutoClose = function() return true end
						}
					}
					table.insert(menu, m)
				end
			end
			PopupMenu(menu)
		end
	end
end

function AH_MailBank.OnItemMouseEnter()
	local szName = this:GetName()
	if not this.bItemBox then
		return
	end
	this:SetObjectMouseOver(1)

	if not this:IsEmpty() then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		local d = this.data
		if this.szType == "item" then
			if IsAltKeyDown() then
				local _, dwID = this:GetObjectData()
				OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, dwID, nil, nil, {x, y, w, h})
			else
				local item = GetItem(d.dwID)
				if item and not IsOfflineMail() then
					local szName = GetItemNameByItem(item)
					local szTip = "<Text>text=" .. EncodeComponentsString(szName) .. " font=60" .. GetItemFontColorByQuality(item.nQuality, true) .. " </text>"
					local MailClient = GetMailClient()
					for k, v in ipairs(d.tMailIDs) do
						local mail = MailClient.GetMailInfo(v)
						if mail then
							szTip = szTip .. GetFormatText(string.format("\n%s", mail.szSenderName), 164)
							szTip = szTip .. GetFormatText(string.format(" 『%s』", mail.szTitle), 163)
							local szLeft = AH_MailBank.FormatItemLeftTime(mail.GetLeftTime())
							szTip = szTip .. GetFormatText(L("STR_MAILBANK_LEFTTIME", szLeft), 162)
							local nCount = AH_MailBank.GetMailItem(mail)[szName][5]
							szTip = szTip .. GetFormatText(L("STR_MAILBANK_NUMBER", nCount), 162)
						else
							local szTip = GetFormatText(this.szName, 162)
							OutputTip(szTip, 800, {x, y, w, h})
						end
					end
					OutputTip(szTip, 800, {x, y, w, h})
				else
					local szTip = GetFormatText(this.szName, 162)
					OutputTip(szTip, 800, {x, y, w, h})
				end
			end
		elseif this.szType == "money" then
			local szTip = GetFormatText(g_tStrings.STR_MAIL_HAVE_MONEY, 101) .. GetMoneyTipText(d.nMoney, 106)
			local MailClient = GetMailClient()
			for k, v in ipairs(d.tMailIDs) do
				local mail = MailClient.GetMailInfo(v)
				if mail then
					szTip = szTip .. GetFormatText(string.format("\n%s", mail.szSenderName), 164)
					szTip = szTip .. GetFormatText(string.format(" 『%s』", mail.szTitle), 163)
					local szLeft = AH_MailBank.FormatItemLeftTime(mail.GetLeftTime())
					szTip = szTip .. GetFormatText(L("STR_MAILBANK_LEFTTIME", szLeft), 162)
					szTip = szTip .. GetFormatText(g_tStrings.STR_MAIL_HAVE_MONEY, 162) .. GetMoneyTipText(mail.nMoney, 106)
				end
			end
			OutputTip(szTip, 800, {x, y, w, h})
		end
	end
end

function AH_MailBank.OnItemMouseLeave()
	local szName = this:GetName()
	if not this.bItemBox then
		return
	end

	this:SetObjectMouseOver(0)
	HideTip()
end

function AH_MailBank.IsPanelOpened()
	local frame = Station.Lookup("Normal/AH_MailBank")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AH_MailBank.OpenPanel()
	local frame = Station.Lookup("Normal/AH_MailBank")
	if not frame then
		frame = Wnd.OpenWindow(szIniFile, "AH_MailBank")
	end
	frame:Show()
	frame:BringToTop()
	AH_MailBank.szCurRole = GetClientPlayer().szName
	if not AH_MailBank.tItemCache[AH_MailBank.szCurRole] then
		AH_MailBank.tItemCache[AH_MailBank.szCurRole] = {}
	end
	AH_MailBank.LoadMailData(frame, AH_MailBank.szCurRole, AH_MailBank.nCurIndex)
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function AH_MailBank.ClosePanel()
	local frame = Station.Lookup("Normal/AH_MailBank")
	if frame and frame:IsVisible() then
		frame:Hide()
	end
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

RegisterEvent("LOGIN_GAME", function()
	if IsFileExist(AH_MailBank.szDataPath) then
		AH_MailBank.tItemCache = LoadLUAData(AH_MailBank.szDataPath)
	end
end)

RegisterEvent("GAME_EXIT", function()
	SaveLUAData(AH_MailBank.szDataPath, AH_MailBank.tItemCache)
end)

RegisterEvent("PLAYER_EXIT_GAME", function()
	SaveLUAData(AH_MailBank.szDataPath, AH_MailBank.tItemCache)
end)

RegisterEvent("SEND_MAIL_RESULT", function()
	--Output(arg1)
	if AH_MailBank.bAutoExange and arg1 == MAIL_RESPOND_CODE.SUCCEED then
		AH_Library.DelayCall(0.05 + GetPingValue() / 2000, AH_MailBank.OnExchangeItem)	--需要延迟几秒放置
	end
end)

AH_Library.BreatheCall("ON_AH_MAILBANK_UPDATE", AH_MailBank.OnUpdate)
