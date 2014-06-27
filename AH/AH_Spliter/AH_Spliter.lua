------------------------------------------------------
-- #模块名：物品拆分堆叠模块
-- #模块说明：为批量寄售提供拆分功能
------------------------------------------------------
local L = AH_Library.LoadLangPack()

AH_Spliter = {
	tItemHistory = {},
}

local szIniFile = "Interface/AH/AH_Spliter/AH_Spliter.ini"

--存储拆分方案
RegisterCustomData("AH_Spliter.tItemHistory")

local function PlayTipSound(szSound)
	local szFile = "ui\\sound\\female\\"..szSound..".wav"
	PlaySound(SOUND.UI_SOUND, szFile)
end

function AH_Spliter.StackItem()
	AH_Library.Message(L("STR_SPLITER_BEGINSTACK"))
	local player = GetClientPlayer()
	local tBoxTable = {}
	for i = 1, 6 do
		for j = 0, player.GetBoxSize(i) - 1 do
			local itemLoop =player.GetItem(i,j)
			if itemLoop then
				local szName = itemLoop.szName
				if szName then
					local nStackNum = itemLoop.nStackNum
					local nMaxStackNum = itemLoop.nMaxStackNum
					if nStackNum ~= nMaxStackNum then
						tBoxTable[szName] = tBoxTable[szName] or {}
						table.insert(tBoxTable[szName], {dwBox =i, dwX = j, bCanStack = itemLoop.bCanStack, nStackNum = nStackNum, nMaxStackNum = nMaxStackNum, dwTabType = itemLoop.dwTabType, dwIndex = itemLoop.dwIndex})
					end
				end
			end
		end
	end
	for szName, tTypeBoxTable in pairs(tBoxTable) do
		local tTidyBoxTemp = tBoxTable[szName]
		for i = 1, #tTidyBoxTemp do
			for j = #tTidyBoxTemp, i+1, -1 do
				local item1 = tTidyBoxTemp[i]
				local item2 = tTidyBoxTemp[j]
				if item1.bCanStack and item1.nStackNum ~= item1.nMaxStackNum and item2.nStackNum > 0 and item1.dwTabType == item2.dwTabType and item1.dwIndex == item2.dwIndex then
					local nStackNumtotal = item1.nStackNum + item2.nStackNum
					if nStackNumtotal<=item1.nMaxStackNum then
						tTidyBoxTemp[i].nStackNum = nStackNumtotal
						tTidyBoxTemp[j].nStackNum = 0
					else
						tTidyBoxTemp[j].nStackNum = nStackNumtotal - item1.nMaxStackNum
						tTidyBoxTemp[i].nStackNum = item1.nMaxStackNum
					end
					OnExchangeItem(tTidyBoxTemp[j].dwBox, tTidyBoxTemp[j].dwX, tTidyBoxTemp[i].dwBox, tTidyBoxTemp[i].dwX)
				end
			end
		end
	end
	AH_Library.Message(L("STR_SPLITER_ENDSTACK"))
end

function AH_Spliter.SplitItem(frame)
	local hGroup = frame:Lookup("Edit_Group")
    local hNum = frame:Lookup("Edit_Num")
    local hBox = frame:Lookup("", "Box_Item")

	if hBox:IsEmpty() then
		return
	end

	local nGroup = tonumber(hGroup:GetText())
	local nNum = tonumber(hNum:GetText())

	local player = GetClientPlayer()

	if not GetPlayerItem(player, hBox.dwBox, hBox.dwX) then
		AH_Library.Message(L("STR_SPLITER_NOITEM"))
		return
	end

	if hBox.nCount < nGroup * nNum or nGroup * nNum == 0 then
		AH_Library.Message(L("STR_SPLITER_GROUPANDNUMBER"))
        return
    end

	local tFreeBoxList = AH_Spliter.GetPlayerBagFreeBoxList()
	if #tFreeBoxList < nGroup then
		AH_Library.Message(L("STR_SPLITER_NOBAGPOS"))
		return
	end

	AH_Library.Message(L("STR_SPLITER_BEGINSPLIT"))
	for i = 1, nGroup do
		local dwBox, dwX = tFreeBoxList[i][1], tFreeBoxList[i][2]
		player.ExchangeItem(hBox.dwBox, hBox.dwX, dwBox, dwX, nNum)
	end
	--拆分结束后存储
	if not AH_Spliter.tItemHistory[hBox.szName] then
		AH_Spliter.tItemHistory[hBox.szName] = {}
	end
	AH_Spliter.tItemHistory[hBox.szName] = {nGroup, nNum}
	AH_Library.Message(L("STR_SPLITER_ENDSPLIT"))
end

function AH_Spliter.GetPlayerBagFreeBoxList()
	local player = GetClientPlayer()
	local tBoxTable = {}
	for nIndex = 6, 1, -1 do
		local dwBox = INVENTORY_INDEX.PACKAGE + nIndex - 1
		local dwSize = player.GetBoxSize(dwBox)
		if dwSize > 0 then
			for dwX = dwSize, 1, -1 do
				local item = player.GetItem(dwBox, dwX - 1)
				if not item then
					local i, j = dwBox, dwX - 1
					table.insert(tBoxTable, {i, j})
				end
			end
		end
	end
	return tBoxTable
end

function AH_Spliter.OnExchangeBoxItem(boxItem, boxDsc, nHandCount, bHand)
	if not boxDsc then
		return
	end

	local nSourceType = boxDsc:GetObjectType()
	local _, dwBox1, dwX1 = boxDsc:GetObjectData()
	local player = GetClientPlayer()

	if nSourceType ~= UI_OBJECT_ITEM or (not dwBox1 or dwBox1 < INVENTORY_INDEX.PACKAGE or dwBox1 > INVENTORY_INDEX.PACKAGE_MIBAO) then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_ITEM_CANNOT_SPLIT)
		PlayTipSound("002")
		return
	end

	local item = GetPlayerItem(player, dwBox1, dwX1)
	if not item or item.nGenre == ITEM_GENRE.EQUIPMENT then
		return
	end

	local itemInfo = GetItemInfo(item.dwTabType, item.dwIndex)

	local nCount = 1
	if item.bCanStack then
		nCount = item.nStackNum
	end

	if nCount < 2 then
		OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.STR_ERROR_ITEM_CANNOT_SPLIT)
		PlayTipSound("002")
		return
	end

	if nHandCount and nHandCount ~= nCount then
		OutputMessage("MSG_ANNOUNCE_RED", L("STR_SPLITER_SPLITTIPS") .. "\n")
		return
	end

	local frame = Station.Lookup("Normal/AH_Spliter")
	if not boxItem then
		if not AH_Spliter.IsPanelOpened() then
			frame = Wnd.OpenWindow(szIniFile, "AH_Spliter")
		end
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		Station.SetActiveFrame(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
		boxItem = frame:Lookup("", ""):Lookup("Box_Item")

	end
	local nGroup, nNum = "1", "1"
	--载入拆分方案
	if AH_Spliter.tItemHistory[item.szName] then
		nGroup, nNum = AH_Spliter.tItemHistory[item.szName][1], AH_Spliter.tItemHistory[item.szName][2]
	end
	frame:Lookup("Edit_Group"):SetText(nGroup)
	frame:Lookup("Edit_Num"):SetText(nNum)

	boxItem.szName = item.szName
	boxItem.dwBox = dwBox1
	boxItem.dwX   = dwX1
	boxItem.nCount = nCount

	UpdataItemBoxObject(boxItem, boxItem.dwBox, boxItem.dwX, item)
	if bHand then
		Hand_Clear()
	end
end

function AH_Spliter.ClearBox(hBox)
	hBox.dwBox = nil
	hBox.dwX = nil
	hBox.szName = nil
	hBox:ClearObject()
	hBox:SetOverText(0, "")
end


function AH_Spliter.OnFrameCreate()
	local handle = this:Lookup("", "")
	handle:Lookup("Text_Group"):SetText(L("STR_SPLITER_GROUP"))
	handle:Lookup("Text_Num"):SetText(L("STR_SPLITER_NUMBER"))
	this:Lookup("Btn_Split"):Lookup("", ""):Lookup("Text_Split"):SetText(L("STR_SPLITER_SPLIT"))
	this:Lookup("Btn_Close"):Lookup("", ""):Lookup("Text_Close"):SetText(L("STR_SPLITER_CLOSE"))

	this:RegisterEvent("UI_SCALED")
end

function AH_Spliter.OnEvent(event)
	if event == "UI_SCALED" then
		if this.rect then
			this:CorrectPos(this.rect[1], this.rect[2], this.rect[3], this.rect[4], ALW.CENTER)
		else
			this:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
		end
	end
end

function AH_Spliter.IsPanelOpened()
	local frame = Station.Lookup("Normal/AH_Spliter")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AH_Spliter.OnSplitBoxItem(rect)
	local frame = nil
	if not AH_Spliter.IsPanelOpened() then
		frame = Wnd.OpenWindow(szIniFile, "AH_Spliter")
	end
	frame:Lookup("Edit_Group"):SetText("1")
	frame:Lookup("Edit_Num"):SetText("1")
	if rect then
		frame:CorrectPos(rect[1], rect[2], rect[3], rect[4], ALW.CENTER)
	else
		frame:SetPoint("CENTER", 0, 0, "CENTER", 0, 0)
	end
	Station.SetActiveFrame(frame)
	PlaySound(SOUND.UI_SOUND, g_sound.OpenFrame)
end

function AH_Spliter.ClosePanel()
	if not AH_Spliter.IsPanelOpened() then
		return
	end
	Wnd.CloseWindow("AH_Spliter")
	PlaySound(SOUND.UI_SOUND, g_sound.CloseFrame)
end

function AH_Spliter.OnLButtonClick()
	local szName = this:GetName()
	if szName == "Btn_Split" then
		AH_Spliter.SplitItem(this:GetParent())
    elseif szName == "Btn_Close" then
		AH_Spliter.ClearBox(this:GetParent():Lookup("", ""):Lookup("Box_Item"))
	end
	AH_Spliter.ClosePanel()
end

function AH_Spliter.OnSetFocus()
  	local szName = this:GetName()
  	if szName == "Edit_Group" then
		local szText = this:GetText()
		if szText == "1" then
			this:SetText("")
		else
			this:SelectAll()
		end
	elseif szName == "Edit_Num" then
		local szText = this:GetText()
		if szText == "1" then
			this:SetText("")
		else
			this:SelectAll()
		end
  	end
end

function AH_Spliter.OnKillFocus()
	local szName = this:GetName()
	if szName == "Edit_Group" then
		local szText = this:GetText()
		if not szText or szText == "" then
			this:SetText("1")
		end
	elseif szName == "Edit_Num" then
		local szText = this:GetText()
		if not szText or szText == "" then
			this:SetText("1")
		end
  	end
end

function AH_Spliter.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "Box_Item" then
		if Hand_IsEmpty() then
			if not this:IsEmpty() then
				if IsCursorInExclusiveMode() then
					OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.SRT_ERROR_CANCEL_CURSOR_STATE)
				else
					Hand_Pick(this)
					AH_Spliter.ClearBox(this)
				end
				HideTip()
			end
		else
			local boxHand, nHandCount = Hand_Get()
			AH_Spliter.OnExchangeBoxItem(this, boxHand, nHandCount, true)
		end
	end
end

function AH_Spliter.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == "Box_Item" then
		if not this:IsEmpty() then
			AH_Spliter.ClearBox(this)
		end
	end
end

function AH_Spliter.OnItemLButtonUp()
	local szName = this:GetName()
	if szName == "Box_Item" then
		this:SetObjectPressed(0)
	end
end

function AH_Spliter.OnItemLButtonDown()
	local szName = this:GetName()
	if szName == "Box_Item" then
		this:SetObjectStaring(false)
		this:SetObjectPressed(1)
	end
end

function AH_Spliter.OnItemMouseEnter()
	this:SetObjectMouseOver(1)
	local szName = this:GetName()
	local x, y = this:GetAbsPos()
	local w, h = this:GetSize()
	if szName == "Box_Item" then
		if this:IsEmpty() then
			local szText = GetFormatText(L("STR_SPLITER_PUTITEMS"), 18)
			OutputTip(szText, 400, {x, y ,w, h})
		else
			local _, dwBox, dwX = this:GetObjectData()
			OutputItemTip(UI_OBJECT_ITEM, dwBox, dwX, nil, {x, y, w, h})
		end
	end
end

function AH_Spliter.OnItemMouseLeave()
	this:SetObjectMouseOver(0)
	local szName = this:GetName()
	if szName == "Box_Item" then
		HideTip()
	end
end

function AH_Spliter.OnItemLButtonDragEnd()
	if not Hand_IsEmpty() then
		local boxHand, nHandCount = Hand_Get()
		AH_Spliter.OnExchangeBoxItem(this, boxHand, nHandCount, true)
	end
end

function AH_Spliter.OnItemLButtonDrag()
	this:SetObjectPressed(0)
	if Hand_IsEmpty() then
		if not this:IsEmpty() then
			if IsCursorInExclusiveMode() then
				OutputMessage("MSG_ANNOUNCE_RED", g_tStrings.SRT_ERROR_CANCEL_CURSOR_STATE)
			else
				Hand_Pick(this)
				AH_Spliter.ClearBox(this)
			end
		end
	end
end
