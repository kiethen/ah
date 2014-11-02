------------------------------------------------------
-- #模块名：鼠标提示模块
-- #模块说明：用于交易行价格已经材料的配方显示
------------------------------------------------------
local L = AH_Library.LoadLangPack()

_G["AH_Tip_Loaded"] = true

AH_Tip = {
	szItemTip = nil,
	szBagItemTip = nil,
	szRecipeTip = nil,
	bShowTipEx = false,
}

RegisterCustomData("AH_Tip.bShowTipEx")

local ipairs = ipairs
local pairs = pairs

local PRICE_LIMITED = PackMoney(9000000, 0, 0)
local MAX_BID_PRICE = PackMoney(800000, 0, 0)

local bBagHooked = false
local bTipHooked = false
local bCompact = nil
local tRecipeSkill = {
	{L("STR_TIP_COOKING"), 4},
	{L("STR_TIP_TAILORING"), 5},
	{L("STR_TIP_FOUNDING"), 6},
	{L("STR_TIP_MEDICINE"), 7},
	{L("STR_TIP_RECASTING"), 14}
}

local function FormatTipEx(h, szText, szTip)
	local i, j = h:GetItemCount(), 0
	if string.find(szText, L("STR_TIP_DONOTDISASSEMBLE")) and string.find(szText, L("STR_TIP_DEBUGINFO")) then
		j = i - 3
	elseif string.find(szText, L("STR_TIP_DONOTDISASSEMBLE")) then
		j = i - 1
	elseif string.find(szText, L("STR_TIP_DEBUGINFO")) then
		j = i - 2
	else
		j = i
	end
	h:InsertItemFromString(j, false, szTip)
end

function AH_Tip.OnUpdate()
	if not bTipHooked then
		local frame = Station.Lookup("Topmost1/TipPanel_Normal")
		if frame and frame:IsVisible() then
			if DelayCall then
				DelayCall(3, function() AH_Tip.InitHookTip(frame) end)
			else
				AH_Tip.InitHookTip(frame)
			end
			bTipHooked = true
		end
	end
	local frame = Station.Lookup("Normal/BigBagPanel")
	if frame then
		if not bBagHooked and frame:IsVisible() then
			bCompact = frame:Lookup("CheckBox_Compact"):IsCheckBoxChecked()
			if bCompact then
				AH_Tip.UpdateCompact(frame)
			else
				AH_Tip.UpdateNormal(frame)
			end
			if _G["AH_Spliter_Loaded"] then
				local hSplit = frame:Lookup("Btn_Split")
				--hSplit:Lookup("","Text_Split"):SetText(L("STR_TIP_STACK"))
				hSplit.OnRButtonClick = function()
					AH_Spliter.StackItem()
				end
				hSplit.OnMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					local szTip = GetFormatText(L("STR_TIP_SPLITTIP"), 162)
					OutputTip(szTip, 800, {x, y, w, h})
				end
			end
			bBagHooked = true
		elseif not frame:IsVisible() then
			bBagHooked = false
		end
	end
end

--Hook TIP
function AH_Tip.InitHookTip(frame)
	local h = frame:Lookup("", "Handle_Message")
	if not h.AppendItemFromStringOrg then
		h.AppendItemFromStringOrg = h.AppendItemFromString
	end
	h.AppendItemFromString = function(h, szText)
		szText = string.gsub(szText,"<text>text=\"\\\
\"</text><text>text=\"\\\
\"</text>", "<text>text=\"\\\
\"</text>")
		h:AppendItemFromStringOrg(szText)
		local hWnd = Station.GetMouseOverWindow()
		if hWnd then
			if AuctionPanel.IsOpened() and hWnd:GetName() == "Wnd_Result2" then
				if AH_Tip.szItemTip then
					FormatTipEx(h, szText, AH_Tip.szItemTip)
				end
			elseif IsBigBagPanelOpened() and hWnd:GetName() == "BigBagPanel" then
				if AH_Tip.szBagItemTip then
					FormatTipEx(h, szText, AH_Tip.szBagItemTip)
				end
			elseif AH_Retrieval.IsPanelOpened() and hWnd:GetName() == "Wnd_CList" then
				if AH_Tip.szRecipeTip then
					FormatTipEx(h, szText, AH_Tip.szRecipeTip)
				end
			end
		end
	end
end


--背包相关
function AH_Tip.UpdateCompact(frame)
	local handle = frame:Lookup("", "Handle_Bag_Compact")
	local nCount = handle:GetItemCount()
	for i = 0, nCount - 1 do
		local hBox = handle:Lookup(i)
		local box = hBox:Lookup(1)
		AH_Tip.HookBagItemBox(box)
	end
end

function AH_Tip.UpdateNormal(frame)
	for i = 1, 6 do
		local handle = frame:Lookup("", "Handle_Bag_Normal/Handle_Bag" .. i):Lookup("Handle_Bag_Content" .. i)
		for j = 0, GetClientPlayer().GetBoxSize(i) - 1 do
			local hBox = handle:Lookup(j)
			local box = hBox:Lookup(1)
			AH_Tip.HookBagItemBox(box)
		end
	end
end

function AH_Tip.HookBagItemBox(box)
	if box and not box.bBag then
		--鼠标悬停
		if not box.SetObjectMouseOverOrg then
			box.SetObjectMouseOverOrg = box.SetObjectMouseOver
		end
		box.SetObjectMouseOver = function(h, bOver)
			box:SetObjectMouseOverOrg(bOver)
			if bOver == 1 then
				AH_Tip.szBagItemTip = AH_Tip.GetBagItemTip(this)
			elseif bOver == 0 then
				AH_Tip.szBagItemTip = nil
			end
		end
		--鼠标点击
		if _G["AH_Spliter_Loaded"] then
			if not box.SetObjectStaringOrg then
				box.SetObjectStaringOrg = box.SetObjectStaring
			end
			if not box.SetObjectPressedOrg then
				box.SetObjectPressedOrg = box.SetObjectPressed
			end
			local bStarting = true
			box.SetObjectStaring = function(h, bStart)
				box:SetObjectStaringOrg(bStart)
				if bStart == false then
					bStarting = false
				end
			end
			box.SetObjectPressed = function(h, bPress)
				if IsAltKeyDown() and not bStarting and bPress == 1 then
					AH_Spliter.OnExchangeBoxItem(nil, box, nil, false)
				end
				box:SetObjectPressedOrg(bPress)
				bStarting = true
			end
		end
	end
end

--背包物品鼠标提示
function AH_Tip.GetBagItemTip(box)
	local player, szTip = GetClientPlayer(), ""
	local item = player.GetItem(box.dwBox, box.dwX)
	if item then
		local nItemCountInPackage = player.GetItemAmount(item.dwTabType, item.dwIndex)
		local nItemCountTotal = player.GetItemAmountInAllPackages(item.dwTabType, item.dwIndex)
		local nItemCountInBank = nItemCountTotal - nItemCountInPackage

		szTip = szTip .. GetFormatText(L("STR_TIP_TOTAL"), 101) .. GetFormatText(nItemCountTotal, 162)
		szTip = szTip .. GetFormatText(L("STR_TIP_BAGANDBANK"), 101) .. GetFormatText(nItemCountInPackage, 162) .. GetFormatText("/", 162) .. GetFormatText(nItemCountInBank, 162)

		--配方
		if item.nGenre == ITEM_GENRE.MATERIAL then
			szTip = szTip .. AH_Tip.GetRecipeTip(player, item)
		end

		local szKey = (item.nGenre == ITEM_GENRE.BOOK) and GetItemNameByItem(item) or item.nUiId

		local fnAction = function(szKey)
			local v = AH_Library.tItemPrice[szKey]
			if v and v[1] then
				if MoneyOptCmp(v[1], PRICE_LIMITED) ~= 0 then
					szTip = szTip .. GetFormatText("\n" .. L("STR_TIP_PRICE"), 157) .. GetMoneyTipText(v[1], 106)
				end
			end
		end
		pcall(fnAction, szKey)
	end
	return szTip
end

function AH_Tip.GetRecipeByItemName(dwProfessionID, szName)
	local player, t = GetClientPlayer(), {}
	for _, v in ipairs(player.GetRecipe(dwProfessionID)) do
		local recipe = GetRecipe(v.CraftID, v.RecipeID)
		if recipe and recipe.nCraftType ~= ALL_CRAFT_TYPE.ENCHANT then
			for nIndex = 1, 6, 1 do
				local nType  = recipe["dwRequireItemType"..nIndex]
				local nID	 = recipe["dwRequireItemIndex"..nIndex]
				local nNeed  = recipe["dwRequireItemCount"..nIndex]
				if nNeed > 0 then
					if GetItemInfo(nType, nID).szName == szName then
						table.insert(t, {v.CraftID, v.RecipeID})
					end
				end
			end
		end
	end
	table.sort(t, function(a, b) return a[2] > b[2] end)
	return t
end

function AH_Tip.GetRecipeTip(player, item)
	local szTip, bFlag = "", false
	if IsAltKeyDown() or IsShiftKeyDown() or AH_Tip.bShowTipEx then
		local szItemName = GetItemNameByItem(item)
		local szOuter, szInner = GetFormatText("\n" .. L("STR_TIP_RECIPELEARN"), 165), ""
		for k, v in ipairs(tRecipeSkill) do
			if player.IsProfessionLearnedByCraftID(v[2]) then
				local tRecipe = AH_Tip.GetRecipeByItemName(v[2], szItemName)
				if not IsTableEmpty(tRecipe) then
					bFlag, szInner = true, szInner .. GetFormatText(FormatString("\n<D0>：\n", v[1]), 163) .. GetFormatText("      ")
					local t1 = {}
					for k2, v2 in ipairs(tRecipe) do
						local recipe = GetRecipe(v2[1], v2[2])
						if recipe then
							local tItemInfo = GetItemInfo(recipe.dwCreateItemType1, recipe.dwCreateItemIndex1)
							table.insert(t1, "<text>text=" .. EncodeComponentsString(GetItemNameByItemInfo(tItemInfo)) .. " font=162 " .. GetItemFontColorByQuality(tItemInfo.nQuality, true).."</text>")
						end
					end
					szInner = szInner .. table.concat(t1, GetFormatText("，", 162))
				end
			end
		end
		if bFlag and szInner ~= "" then szTip = szTip .. szOuter .. szInner end
		szOuter, szInner = GetFormatText("\n" .. L("STR_TIP_RECIPEUNLEARN"), 166), ""
		for k, v in ipairs(tRecipeSkill) do
			--if player.IsProfessionLearnedByCraftID(v[2]) then	--去除未学显示限制
				local tRecipe = AH_Library.tMaterialALL[v[2]][szItemName]
				if not IsTableEmpty(tRecipe) then
					local temp = {}
					for m, n in ipairs(tRecipe) do
						if not player.IsRecipeLearned(n[1], n[2]) then
							table.insert(temp, {n[1], n[2]})
						end
					end
					if not IsTableEmpty(temp) then
						bFlag, szInner = true, szInner .. GetFormatText(FormatString("\n<D0>：\n", v[1]), 163) .. GetFormatText("      ")
						local t2 = {}
						for k2, v2 in ipairs(temp) do
							local recipe = GetRecipe(v2[1], v2[2])
							if recipe then
								local tItemInfo = GetItemInfo(recipe.dwCreateItemType1, recipe.dwCreateItemIndex1)
								table.insert(t2, "<text>text=" .. EncodeComponentsString(GetItemNameByItemInfo(tItemInfo)) .. " font=162 " .. GetItemFontColorByQuality(tItemInfo.nQuality, true).."</text>")
							end
						end
						szInner = szInner .. table.concat(t2, GetFormatText("，", 162))
					end
				end
			--end
		end
		if bFlag and szInner ~= "" then szTip = szTip .. szOuter .. szInner end
	end
	return szTip
end

RegisterEvent("ON_SET_BAG_COMPACT_MODE", function() bBagHooked = false end)
AH_Library.BreatheCall("ON_AH_TIP_UPDATE", AH_Tip.OnUpdate)
