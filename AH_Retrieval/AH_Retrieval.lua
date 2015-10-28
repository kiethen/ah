------------------------------------------------------
-- #模块名：检索助手模块
-- #模块说明：增强交易行、生活技艺搜索制造、瑰石搜索、五彩石筛选等功能
------------------------------------------------------
local L = AH_Library.LoadLangPack()

_G["AH_Retrieval_Loaded"] = true

AH_Retrieval = {
	--技艺
	nCurCraftID = -1,
	nCurRecipeID = -1,
	nCurTypeID = 0,

	--瑰石
	szCurMap = L("STR_RETRIEVAL_DEFAULTMAP"),
	
	szCurPos = "",

	--五彩石
	tLastDiamondData = {
		["Normal"] = {},
		["Simplify"] = {}
	},
	tLastOptions = {
		["Normal"] = {
			szCurLevel = nil,
			szCurAttribute1 = nil,
			szCurAttribute2 = nil,
			szCurAttribute3 = nil,
		},
		["Simplify"] = {
			szCurLevel = nil,
			szCurAttribute1 = nil,
			szCurAttribute2 = nil,
		}
	}
}

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

local szIniFile = "Interface/AH/AH_Retrieval/AH_Retrieval.ini"

--通用下拉菜单生成
local Menu = class()
function Menu:ctor(text)
	self.text = text
end

function Menu:GetMenu()
	local menu = {}
	local xT, yT = self.text:GetAbsPos()
	local wT, hT = self.text:GetSize()
	menu.nMiniWidth = wT + 16
	menu.x = xT + 2
	menu.y = yT + hT - 1
	return menu
end

------------------------------------------------------
-- 技艺模块相关实现
------------------------------------------------------
local tExpandItemType = {}
local tRecipeSkill = {
	{L("STR_TIP_ALL"), 0},
	{L("STR_TIP_COOKING"), 4},
	{L("STR_TIP_TAILORING"), 5},
	{L("STR_TIP_FOUNDING"), 6},
	{L("STR_TIP_MEDICINE"), 7},
	--{L("STR_TIP_RECASTING"), 14}
}

local tPosionType = {
	[2] = L("STR_RETRIEVAL_AUXILIARY"),
	[3] = L("STR_RETRIEVAL_ENHANCED"),
}

-- 分类，为了生成有序的表得用这种结构
local tSearchSort = {
	[1] = {
		szType = L("STR_RETRIEVAL_DRUGENHANCED"),
		nTypeID = 7,
		tSubSort = {
			L("STR_RETRIEVAL_PARRYVALUE"), L("STR_RETRIEVAL_SHIELD"), L("STR_RETRIEVAL_THREAT"), L("STR_RETRIEVAL_PHYSICSATTACK"),
			L("STR_RETRIEVAL_PHYSICSHIT"), L("STR_RETRIEVAL_PHYSICSCRITICALSTRIKE"), L("STR_RETRIEVAL_PHYSICSCRITICALDAMAGE"),
			L("STR_RETRIEVAL_MAGICATTACK"), L("STR_RETRIEVAL_MAGICWEAPONDAMAGE"), L("STR_RETRIEVAL_MAGICHIT"),
			L("STR_RETRIEVAL_MAGICCRITICALSTRIKE"), L("STR_RETRIEVAL_MAGICCRITICALDAMAGE"), L("STR_RETRIEVAL_THERAPYPOWER"),
		},
	},
	[2] = {
		szType = L("STR_RETRIEVAL_DRUGAUXILIARY"),
		nTypeID = 7,
		tSubSort = {
			L("STR_RETRIEVAL_STRENGTH"), L("STR_RETRIEVAL_SPIRIT"), L("STR_RETRIEVAL_SPUNK"),
			L("STR_RETRIEVAL_AGILITY"), L("STR_RETRIEVAL_POTENTIAL"), L("STR_RETRIEVAL_VITALITY"),
			L("STR_RETRIEVAL_PARRYVALUE"), L("STR_RETRIEVAL_PHYSICSOVERCOME"), L("STR_RETRIEVAL_PHYSICSCRITICALDAMAGE"),
			L("STR_RETRIEVAL_MAGICOVERCOME"), L("STR_RETRIEVAL_MAGICCRITICALDAMAGE"), L("STR_RETRIEVAL_THERAPYPOWER"),
		},
	},
	[3] = {
		szType = L("STR_RETRIEVAL_COOKINGENHANCED"),
		nTypeID = 4,
		tSubSort = {
			L("STR_RETRIEVAL_HIT"), L("STR_RETRIEVAL_DODGE"), L("STR_RETRIEVAL_PARRYVALUE"),
			L("STR_RETRIEVAL_SHIELD"), L("STR_RETRIEVAL_THREAT"), L("STR_RETRIEVAL_PHYSICSATTACK"),
			L("STR_RETRIEVAL_PHYSICSOVERCOME"), L("STR_RETRIEVAL_PHYSICSCRITICALDAMAGE"),
			L("STR_RETRIEVAL_MAGICATTACK"), L("STR_RETRIEVAL_MAGICWEAPONDAMAGE"), L("STR_RETRIEVAL_MAGICOVERCOME"),
			L("STR_RETRIEVAL_MAGICCRITICALDAMAGE"), L("STR_RETRIEVAL_THERAPYPOWER"),
		},
	},
	[4] = {
		szType = L("STR_RETRIEVAL_COOKINGAUXILIARY"),
		nTypeID = 4,
		tSubSort = {
			L("STR_RETRIEVAL_STRENGTH"), L("STR_RETRIEVAL_SPIRIT"), L("STR_RETRIEVAL_SPUNK"),
			L("STR_RETRIEVAL_AGILITY"), L("STR_RETRIEVAL_POTENTIAL"), L("STR_RETRIEVAL_VITALITY"),
		},
	},
	--[[[5] = {
		szType = L("STR_RETRIEVAL_EQUIPREFINING"),
		nTypeID = "14a",
		tSubSort = {
			L("STR_RETRIEVAL_VITALITY"), L("STR_RETRIEVAL_AGILITY"), L("STR_RETRIEVAL_SPIRIT"), 
			L("STR_RETRIEVAL_STRENGTH"), L("STR_RETRIEVAL_SPUNK"), L("STR_RETRIEVAL_STRAIN"), 
			L("STR_RETRIEVAL_TOUGHNESS"), L("STR_RETRIEVAL_BLOOD"), L("STR_RETRIEVAL_DODGE"), 
			L("STR_RETRIEVAL_PARRYVALUE"), L("STR_RETRIEVAL_PARRY"), L("STR_RETRIEVAL_ALLCRITICALSTRIKE"), 
			L("STR_RETRIEVAL_ALLCRITICALPOWER"), L("STR_RETRIEVAL_ALLHIT"), L("STR_RETRIEVAL_THREAT"), 
			L("STR_RETRIEVAL_MAGICATTACK"), L("STR_RETRIEVAL_MAGICCRITICALDAMAGE"), L("STR_RETRIEVAL_MAGICCRITICALSTRIKE"), 
			L("STR_RETRIEVAL_MAGICHIT"), L("STR_RETRIEVAL_MAGICOVERCOME"), L("STR_RETRIEVAL_MAGICSHIELD"), 
			L("STR_RETRIEVAL_PHYSICSATTACK"), L("STR_RETRIEVAL_PHYSICSCRITICALDAMAGE"), L("STR_RETRIEVAL_PHYSICSCRITICALSTRIKE"), 
			L("STR_RETRIEVAL_PHYSICSHIT"), L("STR_RETRIEVAL_PHYSICSOVERCOME"), L("STR_RETRIEVAL_PHYSICSSHIELD"), L("STR_RETRIEVAL_THERAPYPOWER"), 
		},
	},
	[6] = {
		szType = L("STR_RETRIEVAL_EQUIPOFFERING"),
		nTypeID = "14b",
		tSubSort = {
			g_tStrings.tForceTitle[1], g_tStrings.tForceTitle[2], g_tStrings.tForceTitle[3],
			g_tStrings.tForceTitle[4], g_tStrings.tForceTitle[5], g_tStrings.tForceTitle[6],
			g_tStrings.tForceTitle[7], g_tStrings.tForceTitle[8], g_tStrings.tForceTitle[9],
			g_tStrings.tForceTitle[10], g_tStrings.tForceTitle[21],
		},
	},]]
	[5] = {
		szType = L("STR_RETRIEVAL_ENCHANTING"),
		nTypeID = 8,
		tSubSort = {
			L("STR_RETRIEVAL_STRENGTH"), L("STR_RETRIEVAL_SPIRIT"), L("STR_RETRIEVAL_SPUNK"),
			L("STR_RETRIEVAL_AGILITY"), L("STR_RETRIEVAL_POTENTIAL"), L("STR_RETRIEVAL_VITALITY"),
			L("STR_RETRIEVAL_DODGE"), L("STR_RETRIEVAL_PARRY"), L("STR_RETRIEVAL_PARRYVALUE"),
			L("STR_RETRIEVAL_HASTE"),L("STR_RETRIEVAL_STRAIN"), L("STR_RETRIEVAL_TOUGHNESS"),
			L("STR_RETRIEVAL_DECRITICALDAMAGE"), L("STR_RETRIEVAL_HATE"), L("STR_RETRIEVAL_MOVESPEED"),
			L("STR_RETRIEVAL_MAGICSHIELD"), L("STR_RETRIEVAL_PHYSICSSHIELD"), L("STR_RETRIEVAL_THERAPYPOWER"),
			L("STR_RETRIEVAL_PHYSICSATTACK"), L("STR_RETRIEVAL_PHYSICSHIT"), L("STR_RETRIEVAL_PHYSICSOVERCOME"),
			L("STR_RETRIEVAL_PHYSICSCRITICALDAMAGE"), L("STR_RETRIEVAL_PHYSICSCRITICALSTRIKE"),
			L("STR_RETRIEVAL_MAGICATTACK"), L("STR_RETRIEVAL_MAGICHIT"), L("STR_RETRIEVAL_MAGICOVERCOME"),
			L("STR_RETRIEVAL_MAGICCRITICALDAMAGE"), L("STR_RETRIEVAL_MAGICCRITICALSTRIKE"),
		},
	},
	[6] = {
		szType = L("STR_RETRIEVAL_OTHER"),
		nTypeID = 0,
		tSubSort = {
			L("STR_RETRIEVAL_KEY"), L("STR_RETRIEVAL_ENERGY"), L("STR_RETRIEVAL_BODYSTRENGTH"), L("STR_RETRIEVAL_CANN"), 
			L("STR_RETRIEVAL_FIVEELE"), L("STR_RETRIEVAL_FAVORABILITY"), L("STR_RETRIEVAL_AURABEAD")
		},
	},
	
}

function AH_Retrieval.InitCraft(frame)
	AH_Retrieval.nProfessionID = 0
	AH_Retrieval.bIsSearch = false
	AH_Retrieval.bSub = false
	AH_Retrieval.bCoolDown = false

	AH_Retrieval.nMakeCount = 0
	AH_Retrieval.nMakeCraftID  = 0
	AH_Retrieval.nMakeRecipeID = 0

	AH_Retrieval.nSubMakeCount = 0
	AH_Retrieval.nSubMakeCraftID  = 0
	AH_Retrieval.nSubMakeRecipeID = 0

	AH_Retrieval.nCurTypeID = 0

	tExpandItemType = {}

	AH_Retrieval.UpdateItemTypeList(frame)
	AH_Retrieval.UpdateList(frame, false)
	AH_Retrieval.HideAndShowFilter(frame, false)
end

function AH_Retrieval.ForamtCoolDownTime(nTime)
	local szText = ""
	local nH, nM, nS = GetTimeToHourMinuteSecond(nTime, true)
	if nH and nH > 0 then
		if (nM and nM > 0) or (nS and nS > 0) then
			nH = nH + 1
		end
		szText = szText .. nH .. g_tStrings.STR_BUFF_H_TIME_H
	else
		nM = nM or 0
		nS = nS or 0
		if nM == 0 and nS == 0 then
			return szText
		end
		if nM > 0 and nS > 0 then
			nM = nM + 1
		end
		if nM >= 60 then
			szText = szText .. math.ceil(nM / 60) .. g_tStrings.STR_BUFF_H_TIME_H
		elseif nM > 0 then
			szText = szText .. nM .. g_tStrings.STR_BUFF_H_TIME_M
		else
			szText = szText .. nS .. g_tStrings.STR_BUFF_H_TIME_S
		end
	end
	return szText
end

function AH_Retrieval.GetRecipeTotalCount(recipe)
	local nTotalCount = 9999999
	for nIndex = 1, 6, 1 do
		if recipe["dwRequireItemCount" .. nIndex] ~= 0 then
			local nCurrentCount = GetClientPlayer().GetItemAmount(recipe["dwRequireItemType" .. nIndex], recipe["dwRequireItemIndex" .. nIndex])
			local nCount = math.floor(nCurrentCount / recipe["dwRequireItemCount" .. nIndex])
			if nCount < nTotalCount then
				nTotalCount = nCount
			end
		end
	end
	if nTotalCount == 9999999 then
		nTotalCount = 0
	end
	return nTotalCount
end

function AH_Retrieval.GetDescByItemName(szName)
	local szDesc = AH_Library.tEnchantData[szName]
	if szDesc then
		return szDesc
	end
	return ""
end

function AH_Retrieval.GetRecipeByItemName(szName)
	for k, v in pairs(AH_Library.tMergeRecipe) do
		local szRecipeName, nCraftID, nRecipeID = unpack(v)
		if szRecipeName == szName then
			return {nCraftID, nRecipeID}
		end
	end
	return nil
end

function AH_Retrieval.IsSpecialMaterial(nType, nID)
	if nType == 5 and nID == 3333 then
		return true
	end
	return false
end

function AH_Retrieval.ProcessKeywords(szName, szKey)
	szKey = string.gsub(szKey, "^%s*(.-)%s*$", "%1")
	szKey = string.gsub(szKey, "[%[%]]", "")
	local tKeys = SplitString(szKey, " ")
	for k, v in ipairs(tKeys) do
		if not StringFindW(szName, v) then
			return false
		end
	end
	return true
end

-- 处理配方类型
function AH_Retrieval.ProcessType(nTypeID, nGenre)
	if nTypeID == 0 then	--其他
		return true
	elseif nTypeID == 4 and nGenre == 14 then	--烹饪
		return true
	elseif nTypeID == 7 and nGenre == 1 then	--药品
		return true
	elseif nTypeID == 8 and (nGenre == 3 or nGenre == 7) then	--附魔
		return true
	--[[elseif nTypeID == "14a" and nGenre == 16 then	--炼化
		return true
	elseif nTypeID == "14b" and nGenre == 3 then	--祭化
		return true]]
	end
	return false
end

function AH_Retrieval.UpdateList(frame, bSub, szKey)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local hList = page:Lookup("Wnd_CList", "")
	local player = GetClientPlayer()
	local bExist = false
	local bSel = false
	local nProID = AH_Retrieval.nProfessionID
	hList:Clear()
	local tRecipe, tCache = nil, {}
	if nProID < 0 then	--原料搜索配方
		for _, k in ipairs({4, 5, 6, 7, 14}) do
			if AH_Retrieval.bIsSearch then
				tRecipe = AH_Library.tMaterialALL[k][szKey]
				if not IsTableEmpty(tRecipe) then
					bExist = true
					for _, v in ipairs(tRecipe) do
						local recipe = GetRecipe(v[1], v[2])
						local nID = recipe.dwCreateItemIndex1
						local nType = recipe.dwCreateItemType1
						local tItemInfo = GetItemInfo(nType, nID)

						table.insert(tCache, {
							szName = GetItemNameByItemInfo(tItemInfo),
							nID	= nID,
							nType = nType,
							nCraftID = v[1],
							nRecipeID = v[2],
							nQuality = tItemInfo.nQuality,
							nTotalCount = AH_Retrieval.GetRecipeTotalCount(recipe),
						})
					end
				end
			end
		end
	else	--配方搜索成品
		if nProID ~= 0 then
			tRecipe = AH_Library.tRecipeALL[nProID]
		else
			tRecipe = AH_Library.tMergeRecipe
		end
		if tRecipe then
			for k, v in pairs(tRecipe) do
				local szRecipeName, nCraftID, nRecipeID, szTip = unpack(v)
				local recipe = GetRecipe(nCraftID, nRecipeID)
				local nType = recipe.dwCreateItemType1
				local nID	= recipe.dwCreateItemIndex1
				local tItemInfo = GetItemInfo(nType, nID)
				if AH_Retrieval.bIsSearch then
					local szDesc = AH_Retrieval.GetDescByItemName(tItemInfo.szName)
					if bSub and tPosionType[tItemInfo.nSub] then
						szDesc = tPosionType[tItemInfo.nSub] .. "：" .. szDesc
					end
					local szSearch = szRecipeName .." " .. szDesc
					local bEnchant = false
					if AH_Retrieval.ProcessKeywords(szSearch, szKey) and AH_Retrieval.ProcessType(AH_Retrieval.nCurTypeID, tItemInfo.nGenre) then
						bExist = true
						table.insert(tCache, {
							szName = szRecipeName,
							nID	= nID,
							nType = nType,
							nSub = tItemInfo.nSub,
							nGenre = tItemInfo.nGenre,
							nCraftID = nCraftID,
							nRecipeID = nRecipeID,
							nQuality = tItemInfo.nQuality,
							nTotalCount = AH_Retrieval.GetRecipeTotalCount(recipe),
							szTip = szTip,
						})
					end
				end
			end
		end
	end

	if tCache then
		table.sort(tCache, function(a, b) return a.nQuality > b.nQuality end)
		for _, v in ipairs(tCache) do
			local hI = hList:AppendItemFromIni(szIniFile, "TreeLeaf_CSearch")
			hI.bItem = true
			hI.szName = v.szName
			hI.nID	= v.nID
			hI.nType = v.nType
			hI.nSub = v.nSub
			hI.nGenre = v.nGenre
			hI.nCraftID = v.nCraftID
			hI.nRecipeID = v.nRecipeID
			hI.nQuality = v.nQuality
			hI.nTotalCount = v.nTotalCount
			hI.szTip = v.szTip

			local hText  = hI:Lookup("Text_CFoodNameS")
			local hImage = hI:Lookup("Image_CFoodS")
			local szText = hI.szName
			local szLearn = ""
			if not player.IsRecipeLearned(hI.nCraftID, hI.nRecipeID) then
				szLearn = szLearn .. " " ..L("STR_RETRIEVAL_UNLEARNED")
			end
			szText = szText .. szLearn
			if hI.nTotalCount ~= 0 then
				szText = szText .. " " .. hI.nTotalCount
			end
			hText:SetText(szText)
			hText:SetFontColor(GetItemFontColorByQuality(hI.nQuality, false))
			hImage:Hide()

			if hI.nCraftID == AH_Retrieval.nCurCraftID and hI.nRecipeID == AH_Retrieval.nCurRecipeID then
				bSel = true
				AH_Retrieval.Selected(frame, hI)
				AH_Retrieval.UpdateContent(frame)
			end
		end
	end

	if not bSel then
		AH_Retrieval.Selected(frame, nil)
	end
	if AH_Retrieval.bIsSearch then
		if not bExist then
			local hI = hList:AppendItemFromIni(szIniFile, "TreeLeaf_CSearch")
			hI:Lookup("Text_CFoodNameS"):SetText(g_tStrings.STR_MSG_NOT_FIND_LIST)
			hI:Lookup("Text_CFoodNameS"):SetFontScheme(162)
			hI:Lookup("Image_CFoodS"):Hide()
		else
			hList:Sort()
		end
	end

	hList:Show()
	AH_Retrieval.OnUpdateScorllList(hList)
end

function AH_Retrieval.UpdateContent(frame)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local hWnd = page:Lookup("Wnd_CContent")
	local hMaterial = hWnd:Lookup("", "")

	local nCurProID = AH_Retrieval.nCurCraftID
	local nCurCraftID = AH_Retrieval.nCurCraftID
	local nCurRecipeID = AH_Retrieval.nCurRecipeID
	local recipe  = GetRecipe(nCurCraftID, nCurRecipeID)
	local bSatisfy = true
	local szProName = Table_GetProfessionName(nCurCraftID)

	hMaterial:Clear()

	local hItem    = hMaterial:AppendItemFromIni(szIniFile, "Handle_CItem")
	local hRequire = hMaterial:AppendItemFromIni(szIniFile, "Handle_CRequireP")
	local hBox     = hItem:Lookup("Box_CItem")
	local hText    = hItem:Lookup("Text_CItem")

	if recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
		hBox.bEnchant = true
		local szName = Table_GetEnchantName(nCurProID, nCurCraftID, nCurRecipeID)
		local nIconID = Table_GetEnchantIconID(nCurProID, nCurCraftID, nCurRecipeID)
		local nQuality = Table_GetEnchantQuality(nCurProID, nCurCraftID, nCurRecipeID)

		hText:SetText(szName)
		hText:SetFontColor(GetItemFontColorByQuality(nQuality, false))

		hBox:SetObject(UI_OBJECT_ITEM_INFO, nCurProID, nCurCraftID, nCurRecipeID)
		hBox:SetObjectIcon(nIconID)
		UpdateItemBoxExtend(hBox, nil, nQuality)
		hBox:SetOverText(0, "")
	else
		hBox.bProduct = true
		local nType = recipe.dwCreateItemType1
		local nID	= recipe.dwCreateItemIndex1

		local ItemInfo = GetItemInfo(nType, nID)
		local nMin  = recipe.dwCreateItemMinCount1
		local nMax  = recipe.dwCreateItemMaxCount1

		local szRecipeName = ItemInfo.szName
		hText:SetText(szRecipeName)
		hText:SetFontColor(GetItemFontColorByQuality(ItemInfo.nQuality, false))

		hBox:SetObject(UI_OBJECT_ITEM_INFO, ItemInfo.nUiId, GLOBAL.CURRENT_ITEM_VERSION, nType, nID)
		hBox:SetObjectIcon(Table_GetItemIconID(ItemInfo.nUiId))
		UpdateItemBoxExtend(hBox, ItemInfo.nGenre, ItemInfo.nQuality, false)
		hBox:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
		hBox:SetOverTextFontScheme(0, 15)

		if nMax == nMin then
			if nMin ~= 1 then
				hBox:SetOverText(0, nMin)
			else
				hBox:SetOverText(0, "")
			end
		else
			hBox:SetOverText(0, nMin .. "-" .. nMax)
		end
	end

	local player = GetClientPlayer()
	local szText, nFont = "", 162

	hRequire:Clear()

	szText = szText .. GetFormatText(g_tStrings.NEED, 162)
	--Tool
	local bComma = false
	if recipe.dwToolItemType ~= 0 and recipe.dwToolItemIndex ~= 0 then
		local ItemInfo   = GetItemInfo(recipe.dwToolItemType, recipe.dwToolItemIndex)
		local nToolCount = player.GetItemAmount(recipe.dwToolItemType, recipe.dwToolItemIndex)
		local nPowerfulToolCount = player.GetItemAmount(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)
		local pItemInfo = GetItemInfo(recipe.dwPowerfulToolItemType, recipe.dwPowerfulToolItemIndex)

		nFont = 162
		if nToolCount <= 0 and nPowerfulToolCount <= 0 then
			nFont = 102
		end
		local szItemName = GetItemNameByItemInfo(ItemInfo)
		szText = szText .. GetFormatText(szItemName, nFont)
		if pItemInfo then
			local szItemName2 = GetItemNameByItemInfo(pItemInfo)
			szText = szText .. GetFormatText(g_tStrings.STR_OR .. szItemName2, nFont)
		end
		bComma = true
	end
	--Stamina
	nFont = 162
	if player.nCurrentStamina < recipe.nStamina then
		nFont = 102
	end
	if bComma then
		szText = szText .. GetFormatText("，", 162)
	end
	szText = szText .. GetFormatText(FormatString(g_tStrings.CRAFT_COST_STAMINA_BLANK, recipe.nStamina), nFont)

	--Doodad
	if recipe.dwRequireDoodadID ~= 0 then
		local doodadTamplate = GetDoodadTemplate(recipe.dwRequireDoodadID)
		if doodadTamplate then
			local szName = Table_GetDoodadTemplateName(doodadTamplate.dwTemplateID)
			szText = szText .. GetFormatText("，" .. szName, 162)
		end
	end
	--技艺要求
	local szCraftText = FormatString(L("STR_RETRIEVAL_NEEDSKILL"), szProName, FormatString(g_tStrings.STR_FRIEND_WTHAT_LEVEL1, recipe.dwRequireProfessionLevel))
	local nFont = 162
	local nMaxLevel    = player.GetProfessionMaxLevel(nCurProID)
    local nLevel       = player.GetProfessionLevel(nCurProID)
    local nAdjustLevel = player.GetProfessionAdjustLevel(nCurProID) or 0

    nLevel = math.min((nLevel + nAdjustLevel), nMaxLevel)
	if recipe.dwRequireProfessionLevel > nLevel then
		nFont = 102
	end
	szText = szText .. GetFormatText("，", 162) .. GetFormatText(szCraftText, nFont)

	--冷却时间
	AH_Retrieval.bCoolDown = false
	AH_Retrieval.szCoolDownTime = nil

	if recipe.dwCoolDownID and recipe.dwCoolDownID > 0 then
		local szTimeText = ""
		local CDTotalTime  = player.GetCDInterval(recipe.dwCoolDownID)
		local CDRemainTime = player.GetCDLeft(recipe.dwCoolDownID)

		AH_Retrieval.bCoolDown = true
		if CDRemainTime <= 0 then
			local szTime = AH_Retrieval.ForamtCoolDownTime(CDTotalTime)
			szTimeText = g_tStrings.TIME_CD .. szTime
		else
			local szTime = AH_Retrieval.ForamtCoolDownTime(CDRemainTime)
			if not szTime or szTime == "" then
				CDRemainTime = 0
				local szTime = AH_Retrieval.ForamtCoolDownTime(CDTotalTime)
				szTimeText = g_tStrings.TIME_CD .. szTime
			else
				AH_Retrieval.szCoolDownTime = szTime
				szTimeText = g_tStrings.TIME_CD1 .. szTime
			end
		end

		local nFont = 162
		if CDRemainTime ~= 0 then
			nFont = 102
			bSatisfy = false
		end
		szText = szText .. GetFormatText("，"..szTimeText, nFont)
	end

	hWnd:Show()
	hRequire:Show()
	hRequire:AppendItemFromString(szText)
	hRequire:FormatAllItemPos()
	hRequire:SetSizeByAllItemSize()

	local nMW = hMaterial:GetSize()
	local _, nRH = hRequire:GetSize()
	hRequire:SetSize(nMW, nRH)

	hItem:FormatAllItemPos()

	if AH_Retrieval.nCurTotalCount <= 0 then
		bSatisfy = false
	end
	AH_Retrieval.SetBtnStatus(frame, recipe.nCraftType, bSatisfy)
	AH_Retrieval.UpdateMakeCount(frame)

	hMaterial:FormatAllItemPos()
end

function AH_Retrieval.UpdateInfo(frame)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local hList = page:Lookup("Wnd_CList", "")
	local player = GetClientPlayer()
	local nCount = hList:GetItemCount() - 1
	local bSel = false
	for i = 0, nCount, 1 do
		local hItem = hList:Lookup(i)
		local hText  = hItem:Lookup("Text_CFoodNameS")
		local hImage = hItem:Lookup("Image_CFoodS")
		local szText = hItem.szName

		local szLearn = ""
		if not player.IsRecipeLearned(hItem.nCraftID, hItem.nRecipeID) then
			szLearn = szLearn .. " " .. L("STR_RETRIEVAL_UNLEARNED")
		end
		szText = szText .. szLearn
		local recipe = GetRecipe(hItem.nCraftID, hItem.nRecipeID)
		local nTotalCount = AH_Retrieval.GetRecipeTotalCount(recipe)
		if nTotalCount ~= 0 then
			szText = szText .. " " .. nTotalCount
		end
		hItem.nTotalCount = nTotalCount
		hText:SetText(szText)

		if not hItem.bSel then
			hText:SetFontColor(GetItemFontColorByQuality(hItem.nQuality, false))
			hImage:Hide()
		end

		if hItem.nCraftID == AH_Retrieval.nCurCraftID and hItem.nRecipeID == AH_Retrieval.nCurRecipeID then
			bSel = true
			AH_Retrieval.Selected(frame, hItem)
			AH_Retrieval.UpdateContent(frame)
		end
	end
	if not bSel then
		AH_Retrieval.Selected(frame, nil)
	end
	AH_Retrieval.UpdateMakeCount(frame)
end

function AH_Retrieval.UpdateBgStatus(hItem)
	if not hItem then
		return
	end
	local img = nil
	local szName = hItem:GetName()
	if szName == "Handle_CListContent" then
		img = hItem:Lookup("Image_CSearchListCover")
	elseif szName == "Handle_CList01" then
		img = hItem:Lookup("Image_CSearchListCover01")
	elseif szName == "Handle_PBossItem" then
		img = hItem:Lookup("Image_PBossItemCover")
	elseif szName == "Handle_PStoneItem" then
		img = hItem:Lookup("Image_PStoneItemCover")
	else
		img  = hItem:Lookup("Image_CFoodS")
	end
	if not img then
		return
	end
	if hItem.bSel then
		--img:FromUITex("ui/Image/Common/TextShadow.UITex", 0)
		img:Show()
		img:SetAlpha(255)
	elseif hItem.bOver then
		--img:FromUITex("ui/Image/Common/TextShadow.UITex", 0)
		img:Show()
		img:SetAlpha(128)
	else
		img:Hide()
	end
end

function AH_Retrieval.SetBtnStatus(frame, nCraftType, bEnable)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local hText = page:Lookup("Btn_CMake", "Text_CMake")
	if nCraftType == ALL_CRAFT_TYPE.ENCHANT then
		page:Lookup("", "Image_CNum"):Hide()
		page:Lookup("Edit_CNumber"):Hide()
		page:Lookup("Btn_CMakeAll"):Hide()
		page:Lookup("Btn_CAdd"):Hide()
		page:Lookup("Btn_CDel"):Hide()
		hText:SetText(g_tStrings.STR_CRAFT_BOOK_SPECIAL_MAKE_BUTTON_TEXT)
	else
		page:Lookup("", "Image_CNum"):Show()
		page:Lookup("Edit_CNumber"):Show()
		page:Lookup("Btn_CMakeAll"):Show()
		page:Lookup("Btn_CAdd"):Show()
		page:Lookup("Btn_CDel"):Show()
		page:Lookup("Btn_CMakeAll"):Enable(bEnable)
		hText:SetText(g_tStrings.STR_CRAFT_BOOK_NORMAL_MAKE_BUTTON_TEXT)
	end
	page:Lookup("Btn_CMake"):Enable(bEnable)
	local editNum = page:Lookup("Edit_CNumber")
	if bEnable then
		hText:SetFontScheme(162)
		local szText = editNum:GetText()
		if szText == "" then
			editNum:SetText(1)
		end
	else
		hText:SetFontScheme(161)
		editNum:SetText(0)
	end
	if AH_Retrieval.nCurRecipeID == 0 then
		page:Lookup("Edit_CNumber"):SetText("")
	end
end

function AH_Retrieval.IsOnMakeRecipe()
	if AH_Retrieval.nMakeCraftID == 0 or AH_Retrieval.nMakeRecipeID == 0 then
	   return nil
	end
	if AH_Retrieval.nMakeCraftID == AH_Retrieval.nCurCraftID and AH_Retrieval.nMakeRecipeID == AH_Retrieval.nCurRecipeID then
		return true
	end
	return nil
end

function AH_Retrieval.UpdateMakeCount(frame, nDelta)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	if AH_Retrieval.nCurRecipeID == 0 then
		page:Lookup("Btn_CDel"):Enable(false)
		page:Lookup("Btn_CAdd"):Enable(false)
		page:Lookup("Edit_CNumber"):SetText("")
		return
	end
	if not nDelta then
		nDelta = 0
	end
	local hEdit = page:Lookup("Edit_CNumber")
	local szCount = hEdit:GetText()
	local nCount  = 0
	local nValue  = 0
	if AH_Retrieval.IsOnMakeRecipe() and nDelta == 0 then
		nCount = AH_Retrieval.nMakeCount
	else
		if szCount == "" then
			szCount = 0
		end
		nCount = tonumber(szCount)
	end
	nCount = nCount + nDelta
	nValue = nCount
	page:Lookup("Btn_CDel"):Enable(true)
	page:Lookup("Btn_CAdd"):Enable(true)
	if nCount <= 0 then
		nValue = 0
		page:Lookup("Btn_CDel"):Enable(false)
	end
	local nTotCount  = 0
	if AH_Retrieval.nCurTotalCount and AH_Retrieval.nCurTotalCount > 0 then
		nTotCount = AH_Retrieval.nCurTotalCount
	end
	if nCount >= nTotCount then
		nValue = nTotCount
		page:Lookup("Btn_CAdd"):Enable(false)
	end
	hEdit:SetText(nValue)
end

function AH_Retrieval.SetMakeInfo(frame, bAll)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	if bAll then
		AH_Retrieval.nMakeCount = AH_Retrieval.nCurTotalCount
	else
		local szCount = page:Lookup("Edit_CNumber"):GetText()
		if szCount == "" then
			AH_Retrieval.nMakeCount = 0
		else
			AH_Retrieval.nMakeCount = tonumber(szCount)
		end
		if AH_Retrieval.nMakeCount > AH_Retrieval.nCurTotalCount then
			AH_Retrieval.nMakeCount = AH_Retrieval.nCurTotalCount
		end
	end
	AH_Retrieval.nMakeCraftID = AH_Retrieval.nCurCraftID
	AH_Retrieval.nMakeRecipeID = AH_Retrieval.nCurRecipeID
	AH_Retrieval.UpdateMakeCount(frame)
end

function AH_Retrieval.ClearMakeInfo()
	if AH_Retrieval.bSub then
		AH_Retrieval.nSubMakeCount, AH_Retrieval.nSubMakeCraftID, AH_Retrieval.nSubMakeRecipeID = 0, 0, 0
	else
		AH_Retrieval.nMakeCount, AH_Retrieval.nMakeCraftID, AH_Retrieval.nMakeRecipeID = 0, 0, 0
	end
end

function AH_Retrieval.OnMakeRecipe()
	local nCount, nCraftID, nRecipeID = 0, 0, 0
	if AH_Retrieval.bSub then
		nCount, nCraftID, nRecipeID = AH_Retrieval.nSubMakeCount, AH_Retrieval.nSubMakeCraftID, AH_Retrieval.nSubMakeRecipeID
	else
		nCount, nCraftID, nRecipeID = AH_Retrieval.nMakeCount, AH_Retrieval.nMakeCraftID, AH_Retrieval.nMakeRecipeID
	end
	if nCount > 0 then
		GetClientPlayer().CastProfessionSkill(nCraftID, nRecipeID)
	else
		AH_Retrieval.ClearMakeInfo()
	end
end

function AH_Retrieval.OnCastProfessionSkill(nCraftID, nRecipeID, nSubMakeCount)
	AH_Retrieval.bSub = true
	if IsShiftKeyDown() then
		GetUserInputNumber(nSubMakeCount, nSubMakeCount, nil,
			function(nCount)
				AH_Retrieval.nSubMakeCraftID, AH_Retrieval.nSubMakeRecipeID, AH_Retrieval.nSubMakeCount = nCraftID, nRecipeID, nCount
				AH_Retrieval.OnMakeRecipe()
			end, nil, nil
		)
	else
		AH_Retrieval.nSubMakeCraftID, AH_Retrieval.nSubMakeRecipeID, AH_Retrieval.nSubMakeCount = nCraftID, nRecipeID, 1
		AH_Retrieval.OnMakeRecipe()
	end
end

function AH_Retrieval.OnEnchantItem()
	local fnAction = function(dwTargetBox, dwTargetX)
		local item = GetPlayerItem(GetClientPlayer(), dwTargetBox, dwTargetX)
		if item then
			GetClientPlayer().CastProfessionSkill(AH_Retrieval.nMakeCraftID, AH_Retrieval.nMakeRecipeID, TARGET.ITEM, item.dwID)
		end
	end
	local fnCancel = function()
		return
	end
	local fnCondition = function(dwTargetBox, dwTargetX)
		local item   = GetPlayerItem(GetClientPlayer(), dwTargetBox, dwTargetX)
		local recipe = GetRecipe(AH_Retrieval.nMakeCraftID, AH_Retrieval.nMakeRecipeID)
		if not item then
			return false
		end
		if not recipe then
			return false
		end

		return true
	end
	UserSelect.SelectItem(fnAction, fnCancel, fnCondition, nil)
end

function AH_Retrieval.Selected(frame, hItem)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	if hItem then
		local hList = hItem:GetParent()
		local nCount = hList:GetItemCount() - 1
		for i = 0, nCount, 1 do
			local hI = hList:Lookup(i)
			if hI.bSel then
				hI.bSel = false
				hI:Lookup("Image_CFoodS"):Hide()
				hI:Lookup("Text_CFoodNameS"):SetFontColor(GetItemFontColorByQuality(hI.nQuality, false))
			end
		end

		hItem.bSel = true
		AH_Retrieval.nCurCraftID  = hItem.nCraftID
		AH_Retrieval.nCurRecipeID = hItem.nRecipeID
		AH_Retrieval.nCurTotalCount = hItem.nTotalCount or 0

		if hItem.nTotalCount > 0 then
			page:Lookup("Edit_CNumber"):SetText(1)
		else
			page:Lookup("Edit_CNumber"):SetText(0)
		end

		AH_Retrieval.UpdateBgStatus(hItem)
	else
		AH_Retrieval.nCurCraftID  = -1
		AH_Retrieval.nCurRecipeID = -1

		page:Lookup("Wnd_CContent"):Hide()
		page:Lookup("Btn_CMakeAll"):Enable(false)
		page:Lookup("Btn_CMake"):Enable(false)
	end
end

function AH_Retrieval.OnSearchType(frame, szType, szSubType)
	local bSub, szKey = false, szSubType
	if StringFindW(szType, L("STR_RETRIEVAL_STRENGTHEN")) then
		bSub, szKey = true, szKey .. " " .. L("STR_RETRIEVAL_STRENGTHEN")
	elseif StringFindW(szType, L("STR_RETRIEVAL_AID")) then
		bSub, szKey = true, szKey .. " " .. L("STR_RETRIEVAL_AID")
	end
	if StringFindW(szKey, L("STR_RETRIEVAL_CRITICALPOWER")) then
		szKey = StringReplaceW(szKey, L("STR_RETRIEVAL_CRITICALPOWER"), L("STR_RETRIEVAL_CRITICALDAMAGEPOWERBASE"))
	elseif StringFindW(szKey, L("STR_RETRIEVAL_CRITICALSTRIKE")) then
		szKey = StringReplaceW(szKey, L("STR_RETRIEVAL_CRITICALSTRIKE"), L("STR_RETRIEVAL_CRITICALSTRIKELEVEL"))
	elseif StringFindW(szKey, L("STR_RETRIEVAL_THERAPY")) then
		szKey = StringReplaceW(szKey, L("STR_RETRIEVAL_THERAPYPOWER"), L("STR_RETRIEVAL_CURE"))
	end
	--[[if szType == L("STR_RETRIEVAL_EQUIPREFINING") then
		szKey = szSubType
	end]]
	AH_Retrieval.UpdateList(frame, bSub, szKey)
	--Output(bSub, szKey)
end

-- 左侧分类
function AH_Retrieval.UpdateItemTypeList(frame)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local hListLv1 = page:Lookup("Wnd_CSearch", "")
	hListLv1:Clear()
	for _, v in ipairs(tSearchSort) do
		local hListLv2 = hListLv1:AppendItemFromIni(szIniFile, "Handle_CListContent")
		hListLv2.nTypeID = v.nTypeID
		local imgBg1 = hListLv2:Lookup("Image_CSearchListBg1")
		local imgBg2 = hListLv2:Lookup("Image_CSearchListBg2")
		local imgCover = hListLv2:Lookup("Image_CSearchListCover")
		local imgMin = hListLv2:Lookup("Image_CMinimize")
		local txtTitle = hListLv2:Lookup("Text_CListTitle")
		if tExpandItemType.szType == v.szType then
			hListLv2.bSel = true

			local hListLv3 = hListLv2:Lookup("Handle_CItems")
	    	local w, h = AH_Retrieval.AddItemSubTypeList(hListLv3, v.tSubSort or {})
	    	imgBg1:Hide()
	    	imgBg2:Show()
	    	imgCover:Show()
			imgMin:Show()
	    	imgMin:SetFrame(8)

	    	local wB, _ = imgBg2:GetSize()
	    	imgBg2:SetSize(wB, h + 50)

	    	local wL, _ = hListLv2:GetSize()
	    	hListLv2:SetSize(wL, h + 50)
	    else
	    	imgBg1:Show()
	    	imgBg2:Hide()
	    	imgCover:Hide()
			imgMin:Show()
	    	imgMin:SetFrame(12)
	    	imgBg2:SetSize(0, 0)

	    	local w, h = imgBg1:GetSize()
	    	hListLv2:SetSize(w, h)
	    end
		hListLv2:Show()
		txtTitle:Show()
		txtTitle:SetText(v.szType)
	end
	AH_Retrieval.OnUpdateItemTypeList(hListLv1)
end

function AH_Retrieval.AddItemSubTypeList(hList, tSubType)
	for _, v in ipairs(tSubType) do
		local hItem = hList:AppendItemFromIni(szIniFile, "Handle_CList01")
		local imgCover =  hItem:Lookup("Image_CSearchListCover01")
		if tExpandItemType.szSubType == v then
			hItem.bSel = true
			imgCover:Show()
		else
			imgCover:Hide()
		end
		hItem:Lookup("Text_CList01"):SetText(v)
		hItem:Show()
	end
	hList:Show()
	hList:FormatAllItemPos()
	hList:SetSizeByAllItemSize()
	return hList:GetSize()
end

function AH_Retrieval.OnUpdateItemTypeList(hList)
	hList:FormatAllItemPos()
	local hWnd = hList:GetParent()
	local scroll = hWnd:Lookup("Scroll_CSearch")
	local w, h = hList:GetSize()
	local wAll, hAll = hList:GetAllItemSize()
	local nStepCount = math.ceil((hAll - h) / 10)

	scroll:SetStepCount(nStepCount)
	if nStepCount > 0 then
		scroll:Show()
		hWnd:Lookup("Btn_CSUp"):Show()
		hWnd:Lookup("Btn_CSDown"):Show()
	else
		scroll:Hide()
		hWnd:Lookup("Btn_CSUp"):Hide()
		hWnd:Lookup("Btn_CSDown"):Hide()
	end
end

function AH_Retrieval.OnDefaultSearch(frame, bEdit)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	AH_Retrieval.nProfessionID = 0
	if bEdit then
		page:Lookup("Edit_CSearch"):ClearText()
	end
	page:Lookup("", ""):Lookup("Text_CType"):SetText(L("STR_TIP_ALL"))
end

function AH_Retrieval.OnSearch(frame)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local szKey = page:Lookup("Edit_CSearch"):GetText()
	if not szKey or szKey == "" then
		if AH_Retrieval.bIsSearch then
			AH_Retrieval.bIsSearch = false
			AH_Retrieval.Selected(frame, nil)
			AH_Retrieval.UpdateList(frame, false)
		end
	else
		AH_Retrieval.bIsSearch = true
		AH_Retrieval.Selected(frame, nil)
		AH_Retrieval.UpdateList(frame, false, szKey)
	end
end

function AH_Retrieval.SelectProfession(frame)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local hEdit = page:Lookup("Edit_CSearch")
	local hText = page:Lookup("", ""):Lookup("Text_CType")
	local menu = Menu.new(hText):GetMenu()
	for k, v in pairs(tRecipeSkill) do
		local m = {
			szOption = v[1],
			fnAction = function()
				AH_Retrieval.nProfessionID = v[2]
				local text = hEdit:GetText()
				hEdit:ClearText()
				hEdit:SetText(text)
				hText:SetText(v[1])
			end
		}
		table.insert(menu, m)
	end
	local m1 = {
		szOption = L("STR_RETRIEVAL_MATERIAL"),
		rgb = {255, 128, 0},
		fnAction = function()
			AH_Retrieval.nProfessionID = -1
			local text = hEdit:GetText()
			hEdit:ClearText()
			hEdit:SetText(text)
			hText:SetText(L("STR_RETRIEVAL_MATERIAL"))
		end
	}
	table.insert(menu, m1)
	PopupMenu(menu)
end

function AH_Retrieval.SelectFilter(frame)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local hText = page:Lookup("", ""):Lookup("Text_CFilter")
	local menu = Menu.new(hText):GetMenu()
	local tPos = {
		L("STR_RETRIEVAL_HAT"),
		L("STR_RETRIEVAL_JACKET"),
		L("STR_RETRIEVAL_WRIST"),
		L("STR_RETRIEVAL_BELT"),
		L("STR_RETRIEVAL_PANTS"),
		L("STR_RETRIEVAL_SHOE"),
		L("STR_RETRIEVAL_WEAPON")
	}
	for k, v in ipairs(tPos) do
		local m = {
			szOption = v,
			fnAction = function()
				AH_Retrieval.szCurPos = v
				hText:SetText(v)
				local szKey = tExpandItemType.szSubType and tExpandItemType.szSubType .. " " .. v or v
				AH_Retrieval.OnSearchType(frame, tExpandItemType.szType, szKey)
			end
		}
		table.insert(menu, m)
	end
	PopupMenu(menu)
end

function AH_Retrieval.HideAndShowFilter(frame, bShow)
	local page = frame:Lookup("PageSet_Main/Page_Craft")
	local handle = page:Lookup("", "")
	local imgBg = handle:Lookup("Image_CFilterBg")
	local txtFilter = handle:Lookup("Text_CFilter")
	local btnFilter = page:Lookup("Btn_CFilter")
	if bShow then
		imgBg:Show()
		txtFilter:Show()
		btnFilter:Show()
		txtFilter:SetText(L("STR_RETRIEVAL_POSITION"))
		AH_Retrieval.szCurPos = ""
	else
		imgBg:Hide()
		txtFilter:Hide()
		btnFilter:Hide()
	end
end

--递归生成菜单
function AH_Retrieval.GenerateMenu(menu, recipe)
	local player = GetClientPlayer()
	for nIndex = 1, 6, 1 do
		local nType  = recipe["dwRequireItemType" .. nIndex]
		local nID	 = recipe["dwRequireItemIndex" .. nIndex]
		local nNeed  = recipe["dwRequireItemCount" .. nIndex]
		if nNeed > 0 then
			local nCount = player.GetItemAmount(nType, nID)
			local ItemInfo = GetItemInfo(nType, nID)
			local szName = ItemInfo.szName .. " (" .. nCount .. "/" .. nNeed.. ")"
			local m0 = {szOption = szName,}
			table.insert(menu, m0)
			local data = AH_Retrieval.GetRecipeByItemName(ItemInfo.szName)
			if data and not AH_Retrieval.IsSpecialMaterial(nType, nID) then
				local nCraftID, nRecipeID = unpack(data)
				local recipe = GetRecipe(nCraftID, nRecipeID)
				local nSubMakeCount = AH_Retrieval.GetRecipeTotalCount(recipe)
				--if player.IsRecipeLearned(nCraftID, nRecipeID) then
					local m_0 = {
						szOption = L("STR_RETRIEVAL_MAKE", nSubMakeCount),
						fnAction = function()
							AH_Retrieval.OnCastProfessionSkill(nCraftID, nRecipeID, nSubMakeCount)
						end,
						fnMouseEnter = function()
							AH_Library.OutputTip(L("STR_RETRIEVAL_MAKETIPS"))
						end,
						fnDisable = function()
							return not player.IsRecipeLearned(nCraftID, nRecipeID)
						end
					}
					table.insert(m0, m_0)
					table.insert(m0, {bDevide = true})
				--end
				AH_Retrieval.GenerateMenu(m0, recipe)
			end
		end
	end
end

------------------------------------------------------
-- 瑰石模块相关实现
------------------------------------------------------
local tExpandPredType = {}

function AH_Retrieval.InitPrediction(frame)
	tExpandPredType = {}
	tExpandPredType.szBoss = L("STR_RETRIEVAL_DEFAULTBOSS")
	AH_Retrieval.UpdatePredItemList(frame, L("STR_RETRIEVAL_DEFAULTMAP"))
end

function AH_Retrieval.SelectMap(frame)
	local page = frame:Lookup("PageSet_Main/Page_Prediction")
	local hText = page:Lookup("", ""):Lookup("Text_PMap")
	local menu = Menu.new(hText):GetMenu()
	for k, v in pairs(AH_Library.tPrediction) do
		local m = {
			szOption = k,
			fnAction = function()
				AH_Retrieval.szCurMap = k,
				AH_Retrieval.UpdatePredItemList(frame, k)
				AH_Retrieval.UpdatePredItemSubList(frame)
				hText:SetText(k)
			end
		}
		table.insert(menu, m)
	end
	PopupMenu(menu)
end

function AH_Retrieval.UpdatePredItemList(frame, szMap)
	local page = frame:Lookup("PageSet_Main/Page_Prediction")
	local hList = page:Lookup("", ""):Lookup("Handle_BossList")
	hList:Clear()
	local tBoss = AH_Library.tPrediction[szMap]
	for szBoss, _ in pairs(tBoss or {}) do
		local hItem = hList:AppendItemFromIni(szIniFile, "Handle_PBossItem")
		local imgCover =  hItem:Lookup("Image_PBossItemCover")
		if tExpandPredType.szBoss == szBoss then
			hItem.bSel = true
			AH_Retrieval.UpdatePredItemSubList(frame, tBoss[szBoss])
			imgCover:Show()
		else
			imgCover:Hide()
		end
		hItem:Lookup("Text_PBossItem"):SetText(szBoss)
		hItem:Show()
	end
	AH_Retrieval.OnUpdatePredItemList(hList)
end

function AH_Retrieval.UpdatePredItemSubList(frame, tSubItem)
	local page = frame:Lookup("PageSet_Main/Page_Prediction")
	local hList = page:Lookup("", ""):Lookup("Handle_StoneList")
	hList:Clear()
	for szStone, v in pairs(tSubItem or {}) do
		local hItem = hList:AppendItemFromIni(szIniFile, "Handle_PStoneItem")
		hItem.nIndex = v.nIndex
		hItem.nUiId = v.nUiId
		local imgCover =  hItem:Lookup("Image_PStoneItemCover")

		if tExpandPredType.szStone == szStone then
			hItem.bSel = true
			imgCover:Show()
		else
			imgCover:Hide()
		end

		local box = hItem:Lookup("Box_PStoneItem")
		box.bStone = true
		box.nIndex = v.nIndex
		local iteminfo = GetItemInfo(5, v.nIndex)
		box:SetObject(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, 5, v.nIndex)
		box:SetObjectIcon(Table_GetItemIconID(v.nUiId))
		UpdateItemBoxExtend(box, iteminfo.nGenre, iteminfo.nQuality, false)
		hItem:Lookup("Text_PStoneItem"):SetText(szStone)

		for i = 1, 2 do
			local box = hItem:Lookup("Box_PItem" .. i)
			if v[i] then
				local dwTabType, dwIndex = v[i][1], v[i][2]
				box.bPred = true
				box.dwType = dwTabType
				box.dwIndex = dwIndex

				local iteminfo = GetItemInfo(dwTabType, dwIndex)
				box:SetObject(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, dwTabType, dwIndex)
				box:SetObjectIcon(Table_GetItemIconID(iteminfo.nUiId))
				UpdateItemBoxExtend(box, iteminfo.nGenre, iteminfo.nQuality, false)
			end
		end
		hItem:Show()
	end
	AH_Retrieval.OnUpdatePredItemList(hList)
end

function AH_Retrieval.OnUpdatePredItemList(hList)
	hList:FormatAllItemPos()
	local page = hList:GetRoot():Lookup("PageSet_Main/Page_Prediction")
	local szName = hList:GetName()
	local w, h = hList:GetSize()
	local wAll, hAll = hList:GetAllItemSize()
	local nStepCount = math.ceil((hAll - h) / 10)

	local scroll, up, down = nil, nil, nil
	if szName == "Handle_BossList" then
		scroll = page:Lookup("Scroll_PBList")
		up = page:Lookup("Btn_PBUp")
		down = page:Lookup("Btn_PBDown")
	elseif szName == "Handle_StoneList" then
		scroll = page:Lookup("Scroll_PSList")
		up = page:Lookup("Btn_PSUp")
		down = page:Lookup("Btn_PSDown")
	end

	scroll:SetStepCount(nStepCount)
	if nStepCount > 0 then
		scroll:Show()
		up:Show()
		down:Show()
	else
		scroll:Hide()
		up:Hide()
		down:Hide()
	end
end
------------------------------------------------------
-- 五彩石模块相关实现
------------------------------------------------------
local tDiamondType = {"Normal", "Simplify"}

--数据筛选，用于菜单动态生成
function AH_Retrieval.Attribute2Magic(szType, szAttribute)
	for k, v in ipairs(AH_Library.tColorMagic[szType]) do
		if szAttribute == v[1] then
			return v[2]
		end
	end
	return nil
end

function AH_Retrieval.IsMagicInAttribute(szType, szMagic, nAttr)
	for k, v in ipairs(AH_Retrieval.tLastDiamondData[szType]) do
		if v[nAttr + 2] and szMagic == v[nAttr + 2] then
			return true
		end
	end
	return false
end


function AH_Retrieval.GetDiamondDataByLevel(szType, szLevel)
	local temp = {}
	for k, v in ipairs(AH_Library.tColorDiamond[szType]) do
		if StringFindW(v[2], szLevel) then
			table.insert(temp, v)
		end
	end
	return temp
end

function AH_Retrieval.GetDiamondDataByMagic(tTable, szType, nAttr, szMagic)
	local temp = {}
	for k, v in ipairs(tTable) do
		if AH_Retrieval.Attribute2Magic(szType, v[nAttr + 2]) == szMagic then
			table.insert(temp, v)
		end
	end
	return temp
end

function AH_Retrieval.IsMagicAttribute(szAttribute)
	local t = {
		L("STR_RETRIEVAL_MAGIC"),
		L("STR_RETRIEVAL_PHYSICS"),
		L("STR_RETRIEVAL_LUNAR"),
		L("STR_RETRIEVAL_NEUTRAL"),
		L("STR_RETRIEVAL_POISON"),
		L("STR_RETRIEVAL_SOLARANDLUNAR"),
		L("STR_RETRIEVAL_SOLAR")
	}
	for k, v in ipairs(t) do
		if szAttribute == v then
			return true
		end
	end
	return false
end

function AH_Retrieval.SelectDiamondLevel(frame, nIndex)
	local page = frame:Lookup("PageSet_Main/Page_Diamond")
	local hWnd = page:Lookup(string.format("PageSet_DTotle/Page_DType%d/Wnd_DType%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	local hText = handle:Lookup(string.format("Text_DType%dLevelBg", nIndex))
	local hBtn = hWnd:Lookup(string.format("Btn_DType%dLevel", nIndex))
	local hReset = hWnd:Lookup(string.format("Btn_DType%dReset", nIndex))

	local szType = tDiamondType[nIndex]
	local menu = Menu.new(hText):GetMenu()

	local tLevel = nil
	if nIndex == 1 then
		tLevel = {
			L("STR_RETRIEVAL_ONE"), L("STR_RETRIEVAL_TWO"), L("STR_RETRIEVAL_THREE"),
			L("STR_RETRIEVAL_FOUR"), L("STR_RETRIEVAL_FIVE"), L("STR_RETRIEVAL_SIX")
		}
	elseif nIndex == 2 then
		tLevel = {
			L("STR_RETRIEVAL_FOUR"), L("STR_RETRIEVAL_FIVE"), L("STR_RETRIEVAL_SIX")
		}
	end

	for k, v in ipairs(tLevel) do
		local m = {
			szOption = v,
			fnAction = function()
				hText:SetText(v)
				AH_Retrieval.tLastOptions[szType].szCurLevel = v
				if nIndex == 1 then
					AH_Retrieval.ClearAttributeValue(frame, 1, 1)
					AH_Retrieval.ClearAttributeValue(frame, 1, 2)
					AH_Retrieval.ClearAttributeValue(frame, 1, 3)
				elseif nIndex == 2 then
					AH_Retrieval.ClearAttributeValue(frame, 2, 1)
					AH_Retrieval.ClearAttributeValue(frame, 2, 2)
				end
				hReset:Enable(true)
			end
		}
		table.insert(menu, m)
	end
	PopupMenu(menu)
end

function AH_Retrieval.SelectDiamondAttribute(frame, nIndex, nAttr)
	local page = frame:Lookup("PageSet_Main/Page_Diamond")
	local hWnd = page:Lookup(string.format("PageSet_DTotle/Page_DType%d/Wnd_DType%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	local hText = handle:Lookup(string.format("Text_DType%dAttr%dBg", nIndex, nAttr))
	local hBtn = hWnd:Lookup(string.format("Btn_DType%dAttr%d", nIndex, nAttr))
	local hSearch = hWnd:Lookup(string.format("Btn_DType%dSearch", nIndex))

	local hLevel = handle:Lookup(string.format("Text_DType%dLevelBg", nIndex))
	local hPrev = handle:Lookup(string.format("Text_DType%dAttr%dBg", nIndex, nAttr - 1))
	if hLevel:GetText() == "" or (hPrev and hPrev:GetText() == "") then
		return
	end

	local szType = tDiamondType[nIndex]
	local menu = Menu.new(hText):GetMenu()

	local function _get(t, d)
		for k, v in ipairs(t) do
			for k2, v2 in pairs(v) do
				if type(k2) == "string" and k2 == d then
					return v
				end
			end
		end
		return nil
	end

	--处理分类
	local tTemp, i = {}, 1
	for k, v in ipairs(AH_Library.tColorMagic[szType]) do
		if AH_Retrieval.IsMagicInAttribute(szType, v[1], nAttr) then
			if not tTemp[i] then
				tTemp[i] = {}
			end
			local szAtr = string.sub(v[2], 1, 4)
			if AH_Retrieval.IsMagicAttribute(szAtr) then
				local t = _get(tTemp, szAtr)
				if not t then
					tTemp[i][szAtr] = {}
					t = _get(tTemp, szAtr)
				end
				table.insert(t[szAtr], {v[1], v[2]})
			else
				table.insert(tTemp[i], {v[1], v[2]})
			end
			i = i + 1
		end
	end
	--生成菜单
	for k, v in ipairs(tTemp) do
		for k2, v2 in pairs(v) do
			if type(k2) == "string" then
				local mAtr = {szOption = k2}
				for k3, v3 in pairs(v2) do
					local m = {
						szOption = v3[2],
						fnAction = function()
							hText:SetText(v3[2])
							AH_Retrieval.tLastOptions[szType]["szCurAttribute" .. nAttr] = v3[2]
							if (nIndex == 1 and nAttr == 1) then
								AH_Retrieval.ClearAttributeValue(frame, 1, 2)
								AH_Retrieval.ClearAttributeValue(frame, 1, 3)
							elseif (nIndex == 1 and nAttr == 2) then
								AH_Retrieval.ClearAttributeValue(frame, 1, 3)
							elseif (nIndex == 2 and nAttr == 1) then
								AH_Retrieval.ClearAttributeValue(frame, 2, 2)
							end
							if (nIndex == 1 and nAttr == 3) or (nIndex == 2 and nAttr == 2) then
								hSearch:Enable(true)
							end
						end
					}
					table.insert(mAtr, m)
				end
				table.insert(menu, mAtr)
			else
				local m = {
					szOption = v2[2],
					fnAction = function()
						hText:SetText(v2[2])
						AH_Retrieval.tLastOptions[szType]["szCurAttribute" .. nAttr] = v2[2]
						if (nIndex == 1 and nAttr == 1) then
							AH_Retrieval.ClearAttributeValue(frame, 1, 2)
							AH_Retrieval.ClearAttributeValue(frame, 1, 3)
						elseif (nIndex == 1 and nAttr == 2) then
							AH_Retrieval.ClearAttributeValue(frame, 1, 3)
						elseif (nIndex == 2 and nAttr == 1) then
							AH_Retrieval.ClearAttributeValue(frame, 2, 2)
						end
						if (nIndex == 1 and nAttr == 3) or (nIndex == 2 and nAttr == 2) then
							hSearch:Enable(true)
						end
					end
				}
				table.insert(menu, m)
			end
		end
	end
	PopupMenu(menu)
end

function AH_Retrieval.ClearAttributeValue(frame, nIndex, nAttr)
	local page = frame:Lookup("PageSet_Main/Page_Diamond")
	local hWnd = page:Lookup(string.format("PageSet_DTotle/Page_DType%d/Wnd_DType%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	local hText = handle:Lookup(string.format("Text_DType%dAttr%dBg", nIndex, nAttr))
	local hBox = handle:Lookup(string.format("Box_DType%dItem", nIndex))
	local hName = handle:Lookup(string.format("Text_DType%dItem", nIndex))
	local hSearch = hWnd:Lookup(string.format("Btn_DType%dSearch", nIndex))
	hText:SetText("")
	hBox:ClearObject()
	hBox:ClearObjectIcon()
	hName:SetText("")
	hSearch:Enable(false)
end

function AH_Retrieval.InitDiamond(frame, nIndex)
	local page = frame:Lookup("PageSet_Main/Page_Diamond")
	local hWnd = page:Lookup(string.format("PageSet_DTotle/Page_DType%d/Wnd_DType%d", nIndex, nIndex))
	hWnd:Lookup(string.format("Btn_DType%dReset", nIndex)):Enable(false)
	hWnd:Lookup(string.format("Btn_DType%dSearch", nIndex)):Enable(false)
end

function AH_Retrieval.ResetAllOptions(frame, nIndex)
	local page = frame:Lookup("PageSet_Main/Page_Diamond")
	local hWnd = page:Lookup(string.format("PageSet_DTotle/Page_DType%d/Wnd_DType%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	hWnd:Lookup(string.format("Btn_DType%dLevel", nIndex)):Enable(true)
	handle:Lookup(string.format("Text_DType%dLevelBg", nIndex)):SetText("")
	handle:Lookup(string.format("Box_DType%dItem", nIndex)):ClearObject()
	handle:Lookup(string.format("Text_DType%dItem", nIndex)):SetText("")

	for i = 1, 3 do
		local hBtn = hWnd:Lookup(string.format("Btn_DType%dAttr%d", nIndex, i))
		if hBtn then
			hBtn:Enable(true)
		end
		local hText = handle:Lookup(string.format("Text_DType%dAttr%dBg", nIndex, i))
		if hText then
			hText:SetText("")
		end
	end

	local szType = tDiamondType[nIndex]
	AH_Retrieval.tLastDiamondData[szType] = {}
end

function AH_Retrieval.SearchDiamond(frame, nIndex)
	local page = frame:Lookup("PageSet_Main/Page_Diamond")
	local hWnd = page:Lookup(string.format("PageSet_DTotle/Page_DType%d/Wnd_DType%d", nIndex, nIndex))
	local handle = hWnd:Lookup("", "")
	local box = handle:Lookup(string.format("Box_DType%dItem", nIndex))
	local txt = handle:Lookup(string.format("Text_DType%dItem", nIndex))

	local szType = tDiamondType[nIndex]
	local dwID, szName, _, _ = unpack(AH_Retrieval.tLastDiamondData[szType][1])

	local ItemInfo = GetItemInfo(5, dwID)
	if ItemInfo then
		txt:SetText(szName)
		txt:SetFontColor(GetItemFontColorByQuality(ItemInfo.nQuality, false))

		box.szName = szName
		box:SetObject(UI_OBJECT_ITEM_INFO, ItemInfo.nUiId, GLOBAL.CURRENT_ITEM_VERSION, 5, dwID)
		box:SetObjectIcon(Table_GetItemIconID(ItemInfo.nUiId))
		UpdateItemBoxExtend(box, ItemInfo.nGenre, ItemInfo.nQuality, false)
	end
end
------------------------------------------------------
-- 共用回调函数处理
------------------------------------------------------
function AH_Retrieval.OnFrameCreate()
	this:RegisterEvent("OT_ACTION_PROGRESS_BREAK")
	this:RegisterEvent("SYS_MSG")
	this:RegisterEvent("BAG_ITEM_UPDATE")

	local page = this:Lookup("PageSet_Main")
	page:Lookup("CheckBox_Craft"):Lookup("", ""):Lookup("Text_CraftCapital"):SetText(L("STR_RETRIEVAL_PRODUCE"))
	page:Lookup("CheckBox_Prediction"):Lookup("", ""):Lookup("Text_PredictionCapital"):SetText(L("STR_RETRIEVAL_PREDICTION"))
	page:Lookup("CheckBox_Diamond"):Lookup("", ""):Lookup("Text_DiamondCapital"):SetText(L("STR_RETRIEVAL_DIAMOND"))

	--技艺
	local page = this:Lookup("PageSet_Main/Page_Craft")
	local handle = page:Lookup("", "")
	handle:Lookup("Text_CTitle"):SetText(L("STR_RETRIEVAL_PRODUCE"))
	handle:Lookup("Text_CType"):SetText(L("STR_TIP_ALL"))
	handle:Lookup("Text_CFilter"):SetText(L("STR_RETRIEVAL_POSITION"))

	--瑰石
	local page = this:Lookup("PageSet_Main/Page_Prediction")
	local handle = page:Lookup("", "")
	handle:Lookup("Text_PMap"):SetText(L("STR_RETRIEVAL_DEFAULTMAP"))
	handle:Lookup("Text_PTitle"):SetText(L("STR_RETRIEVAL_PREDICTION"))
	handle:Lookup("Text_PMapSelect"):SetText(L("STR_RETRIEVAL_SELECTMAP"))

	--五彩石
	local page = this:Lookup("PageSet_Main/Page_Diamond")
	local handle = page:Lookup("", "")
	handle:Lookup("Text_DTitle"):SetText(L("STR_RETRIEVAL_DIAMOND"))
	handle:Lookup("Text_DTips"):SetText(L("STR_RETRIEVAL_BOXTIPS"))
	local pageSet = page:Lookup("PageSet_DTotle")
	pageSet:Lookup("CheckBox_DType1"):Lookup("", ""):Lookup("Text_DType1"):SetText(L("STR_RETRIEVAL_NORMAL"))
	pageSet:Lookup("CheckBox_DType2"):Lookup("", ""):Lookup("Text_DType2"):SetText(L("STR_RETRIEVAL_SIMPLIFY"))
	local hWnd1 = page:Lookup("PageSet_DTotle/Page_DType1/Wnd_DType1")
	hWnd1:Lookup("", ""):Lookup("Text_DType1Level"):SetText(L("STR_RETRIEVAL_DIAMONDLEVEL"))
	hWnd1:Lookup("", ""):Lookup("Text_DType1Attr1"):SetText(L("STR_RETRIEVAL_ATTRIBUTEONE"))
	hWnd1:Lookup("", ""):Lookup("Text_DType1Attr2"):SetText(L("STR_RETRIEVAL_ATTRIBUTETWO"))
	hWnd1:Lookup("", ""):Lookup("Text_DType1Attr3"):SetText(L("STR_RETRIEVAL_ATTRIBUTETHREE"))
	local hWnd2 = page:Lookup("PageSet_DTotle/Page_DType2/Wnd_DType2")
	hWnd2:Lookup("", ""):Lookup("Text_DType2Level"):SetText(L("STR_RETRIEVAL_DIAMONDLEVEL"))
	hWnd2:Lookup("", ""):Lookup("Text_DType2Attr1"):SetText(L("STR_RETRIEVAL_ATTRIBUTEONE"))
	hWnd2:Lookup("", ""):Lookup("Text_DType2Attr2"):SetText(L("STR_RETRIEVAL_ATTRIBUTETWO"))

	InitFrameAutoPosInfo(this, 1, nil, nil, function() AH_Retrieval.ClosePanel() end)
end

function AH_Retrieval.OnEvent(event)
	local frame = this:GetRoot()
	if event == "OT_ACTION_PROGRESS_BREAK" then
		if GetClientPlayer().dwID == arg0 then
			AH_Retrieval.ClearMakeInfo()
		end
	elseif event == "BAG_ITEM_UPDATE" then
		AH_Retrieval.UpdateInfo(frame)
	elseif event == "SYS_MSG" then
		if arg0 == "UI_OME_LEARN_RECIPE" then
			if AH_Retrieval.bIsSearch then
				AH_Retrieval.UpdateList(frame, false)
			end
		elseif arg0 == "UI_OME_CRAFT_RESPOND" then
			if arg1 == 1 then
				if AH_Retrieval.bSub then
					AH_Retrieval.nSubMakeCount = AH_Retrieval.nSubMakeCount - 1
				else
					AH_Retrieval.nMakeCount = AH_Retrieval.nMakeCount - 1
				end
				AH_Retrieval.OnMakeRecipe()
				AH_Retrieval.UpdateInfo(frame)
			else
				AH_Retrieval.ClearMakeInfo()
			end
		end
	end
end

function AH_Retrieval.OnFrameBreathe()
	if AH_Retrieval.bCoolDown then
		local nCurProID = AH_Retrieval.nCurCraftID
		local nCurCraftID = AH_Retrieval.nCurCraftID
		local nCurRecipeID = AH_Retrieval.nCurRecipeID
		local recipe  = GetRecipe(nCurCraftID, nCurRecipeID)
		if not recipe then
			Trace(string.format("Error: GetRecipe(%d, %d) return nil", nCurCraftID, nCurRecipeID))
			return
		end

		if recipe.dwCoolDownID and recipe.dwCoolDownID > 0 and AH_Retrieval.szCoolDownTime then
			local CDRemainTime = GetClientPlayer().GetCDLeft(recipe.dwCoolDownID)
			local szNTime = AH_Retrieval.ForamtCoolDownTime(CDRemainTime)
			if szNTime ~= AH_Retrieval.szCoolDownTime then
				AH_Retrieval.UpdateContent(this)
			end
		end
	end
end

function AH_Retrieval.OnUpdateScorllList(hList)
	hList:FormatAllItemPos()
	local hWnd  = hList:GetParent()
	local hScroll = hWnd:Lookup("Scroll_CList")
	local w, h = hList:GetSize()
	local wAll, hAll = hList:GetAllItemSize()
	local nStepCount = math.ceil((hAll - h) / 10)

	hScroll:SetStepCount(nStepCount)
	if nStepCount > 0 then
		hScroll:Show()
		hWnd:Lookup("Btn_CListUp"):Show()
		hWnd:Lookup("Btn_CListDown"):Show()
	else
		hScroll:Hide()
		hWnd:Lookup("Btn_CListUp"):Hide()
		hWnd:Lookup("Btn_CListDown"):Hide()
	end
end

function AH_Retrieval.OnEditChanged()
	local szName = this:GetName()
	if szName == "Edit_CSearch" then
		AH_Retrieval.OnSearch(this:GetRoot())
	end
end

function AH_Retrieval.OnSetFocus()
	local szName = this:GetName()
	if szName == "Edit_CSearch" then
		this:SelectAll()
		tExpandItemType = {}
		AH_Retrieval.nCurTypeID = 0
		AH_Retrieval.UpdateItemTypeList(this:GetRoot())
	end
end

function AH_Retrieval.OnKillFocus()
	local szName = this:GetName()
	if szName == "Edit_CSearch" then
	end
end

function AH_Retrieval.OnLButtonClick()
	local frame, szName = this:GetRoot(), this:GetName()
	if szName == "Btn_Close" then
		AH_Retrieval.ClosePanel()
	elseif szName == "Btn_CType" then
		AH_Retrieval.SelectProfession(frame)
	elseif szName == "Btn_CFilter" then
		AH_Retrieval.SelectFilter(frame)
	elseif szName == "Btn_CAdd" then
		AH_Retrieval.UpdateMakeCount(frame, 1)
	elseif szName == "Btn_CDel" then
		AH_Retrieval.UpdateMakeCount(frame, -1)
	elseif szName == "Btn_CMake" then
		AH_Retrieval.bSub = false
		local nCraftID = AH_Retrieval.nCurCraftID
		local nRecipeID = AH_Retrieval.nCurRecipeID
		local recipe = GetRecipe(nCraftID, nRecipeID)
		if recipe.nCraftType == ALL_CRAFT_TYPE.PRODUCE then
			AH_Retrieval.SetMakeInfo(frame)
			AH_Retrieval.OnMakeRecipe()
		elseif recipe.nCraftType == ALL_CRAFT_TYPE.ENCHANT then
			AH_Retrieval.nMakeCraftID  = nCraftID
			AH_Retrieval.nMakeRecipeID = nRecipeID
			AH_Retrieval.nMakeCount = 1
			AH_Retrieval.OnEnchantItem()
		end
	elseif szName == "Btn_CMakeAll" then
		AH_Retrieval.bSub = false
		AH_Retrieval.SetMakeInfo(frame, true)
		AH_Retrieval.OnMakeRecipe()
	elseif szName == "Btn_CDefault" then
		tExpandItemType = {}
		AH_Retrieval.nCurTypeID = 0
		AH_Retrieval.bIsSearch = false
		AH_Retrieval.OnDefaultSearch(frame, true)
		AH_Retrieval.Selected(frame, nil)
		AH_Retrieval.UpdateList(frame, false)
		AH_Retrieval.UpdateItemTypeList(frame)
		PlaySound(SOUND.UI_SOUND,g_sound.Button)
	elseif szName == "Btn_DType1Level" then
		AH_Retrieval.SelectDiamondLevel(frame, 1)
	elseif szName == "Btn_DType2Level" then
		AH_Retrieval.SelectDiamondLevel(frame, 2)
	elseif szName == "Btn_DType1Attr1" then
		local szLevel = AH_Retrieval.tLastOptions["Normal"].szCurLevel
		AH_Retrieval.tLastDiamondData["Normal"] = AH_Retrieval.GetDiamondDataByLevel("Normal", szLevel)
		AH_Retrieval.SelectDiamondAttribute(frame, 1, 1)
	elseif szName == "Btn_DType1Attr2" then
		local szLevel = AH_Retrieval.tLastOptions["Normal"].szCurLevel
		AH_Retrieval.tLastDiamondData["Normal"] = AH_Retrieval.GetDiamondDataByLevel("Normal", szLevel)
		local szAttribute1 = AH_Retrieval.tLastOptions["Normal"].szCurAttribute1
		local tTable = AH_Retrieval.tLastDiamondData["Normal"]
		AH_Retrieval.tLastDiamondData["Normal"] = AH_Retrieval.GetDiamondDataByMagic(tTable, "Normal", 1, szAttribute1)
		AH_Retrieval.SelectDiamondAttribute(frame, 1, 2)
	elseif szName == "Btn_DType1Attr3" then
		local szAttribute2 = AH_Retrieval.tLastOptions["Normal"].szCurAttribute2
		local tTable = AH_Retrieval.tLastDiamondData["Normal"]
		AH_Retrieval.tLastDiamondData["Normal"] = AH_Retrieval.GetDiamondDataByMagic(tTable, "Normal", 2, szAttribute2)
		AH_Retrieval.SelectDiamondAttribute(frame, 1, 3)
	elseif szName == "Btn_DType2Attr1" then
		local szLevel = AH_Retrieval.tLastOptions["Simplify"].szCurLevel
		AH_Retrieval.tLastDiamondData["Simplify"] = AH_Retrieval.GetDiamondDataByLevel("Simplify", szLevel)
		AH_Retrieval.SelectDiamondAttribute(frame, 2, 1)
	elseif szName == "Btn_DType2Attr2" then
		local szAttribute1 = AH_Retrieval.tLastOptions["Simplify"].szCurAttribute1
		local tTable = AH_Retrieval.tLastDiamondData["Simplify"]
		AH_Retrieval.tLastDiamondData["Simplify"] = AH_Retrieval.GetDiamondDataByMagic(tTable, "Simplify", 1, szAttribute1)
		AH_Retrieval.SelectDiamondAttribute(frame, 2, 2)
	elseif szName == "Btn_DType1Reset" then
		AH_Retrieval.ResetAllOptions(frame, 1)
		AH_Retrieval.InitDiamond(frame, 1)
	elseif szName == "Btn_DType2Reset" then
		AH_Retrieval.ResetAllOptions(frame, 2)
		AH_Retrieval.InitDiamond(frame, 2)
	elseif szName == "Btn_DType1Search" then
		local tTable = AH_Retrieval.tLastDiamondData["Normal"]
		local szAttribute3 = AH_Retrieval.tLastOptions["Normal"].szCurAttribute3
		AH_Retrieval.tLastDiamondData["Normal"] = AH_Retrieval.GetDiamondDataByMagic(tTable, "Normal", 3, szAttribute3)
		AH_Retrieval.SearchDiamond(frame, 1)
	elseif szName == "Btn_DType2Search" then
		local tTable = AH_Retrieval.tLastDiamondData["Simplify"]
		local szAttribute2 = AH_Retrieval.tLastOptions["Simplify"].szCurAttribute2
		AH_Retrieval.tLastDiamondData["Simplify"] = AH_Retrieval.GetDiamondDataByMagic(tTable, "Simplify", 2, szAttribute2)
		AH_Retrieval.SearchDiamond(frame, 2)
	elseif szName == "Btn_PMap" then
		AH_Retrieval.SelectMap(frame)
	end
end

function AH_Retrieval.OnItemLButtonClick()
	local frame, szName = this:GetRoot(), this:GetName()
	if this.bItem then
		if IsCtrlKeyDown() then
			EditBox_AppendLinkRecipe(this.nCraftID, this.nRecipeID)
			return
		end
		--Output(AH_Retrieval.nCurTypeID, this.nSub, this.nGenre)
		AH_Retrieval.Selected(frame, this)
		AH_Retrieval.UpdateContent(frame)
		PlaySound(SOUND.UI_SOUND, g_sound.Button)
		if AuctionPanel.IsOpened() and _G["AH_Helper_Loaded"] then
			AH_Helper.UpdateList(this.szName, false)
		end
	elseif this.bEnchant then
		if IsCtrlKeyDown() then
			local nProID, nCraftID, nRecipeID = this:GetObjectData()
			EditBox_AppendLinkEnchant(nProID, nCraftID, nRecipeID)
		end
	elseif this.bProduct then
		if IsCtrlKeyDown() then
			local _, dwVer, nTabType, nIndex = this:GetObjectData()
			EditBox_AppendLinkItemInfo(dwVer, nTabType, nIndex)
		end
	elseif szName == "Handle_CListContent" then
		local szType = this:Lookup("Text_CListTitle"):GetText()
		if tExpandItemType.szType == szType then
			tExpandItemType = {}
			AH_Retrieval.nCurTypeID = 0
			AH_Retrieval.bIsSearch = false
			AH_Retrieval.HideAndShowFilter(frame, false)
		else
			tExpandItemType.szType = szType
			AH_Retrieval.nCurTypeID = this.nTypeID
			AH_Retrieval.bIsSearch = true
			if szType == L("STR_RETRIEVAL_ENCHANTING") then
				AH_Retrieval.HideAndShowFilter(frame, true)
			end
		end
		AH_Retrieval.OnDefaultSearch(frame, false)
		AH_Retrieval.UpdateItemTypeList(this:GetRoot())
		PlaySound(SOUND.UI_SOUND,g_sound.Button)
	elseif szName == "Handle_CList01" then
		local szSubType = this:Lookup("Text_CList01"):GetText()
		tExpandItemType.szSubType = szSubType
		AH_Retrieval.UpdateItemTypeList(this:GetRoot())
		szSubType = (AH_Retrieval.szCurPos == "") and szSubType or (szSubType .. " " .. AH_Retrieval.szCurPos)
		AH_Retrieval.OnSearchType(frame, tExpandItemType.szType, szSubType)
	elseif szName == "Box_DType1Item" or szName == "Box_DType2Item" then
		if not this:IsEmpty() then
			if IsCtrlKeyDown() then
				local _, dwVer, nTabType, nIndex = this:GetObjectData()
				EditBox_AppendLinkItemInfo(dwVer, nTabType, nIndex)
				return
			end
			if AuctionPanel.IsOpened() and _G["AH_Helper_Loaded"] then
				AH_Helper.UpdateList(this.szName, false)
			end
		end
	elseif szName == "Handle_PBossItem" then
		local szBoss = this:Lookup("Text_PBossItem"):GetText()
		if tExpandPredType.szBoss == szBoss then
			tExpandPredType = {}
		else
			tExpandPredType.szBoss = szBoss
		end
		AH_Retrieval.UpdatePredItemList(frame, AH_Retrieval.szCurMap)
	elseif szName == "Handle_PStoneItem" then
		local szStone = this:Lookup("Text_PStoneItem"):GetText()
		tExpandPredType.szStone = szStone
		AH_Retrieval.UpdatePredItemList(frame, AH_Retrieval.szCurMap)
		if IsCtrlKeyDown() then
			EditBox_AppendLinkItemInfo(GLOBAL.CURRENT_ITEM_VERSION, 5, this.nIndex)
			return
		end
		if AuctionPanel.IsOpened() and _G["AH_Helper_Loaded"] then
			AH_Helper.UpdateList(Table_GetItemName(this.nUiId), false)
		end
	elseif this.bStone then
		if IsCtrlKeyDown() then
			EditBox_AppendLinkItemInfo(GLOBAL.CURRENT_ITEM_VERSION, 5, this.nIndex)
		end
	elseif this.bPred then
		if IsCtrlKeyDown() then
			EditBox_AppendLinkItemInfo(GLOBAL.CURRENT_ITEM_VERSION, this.dwType, this.dwIndex)
		end
	end
end

function AH_Retrieval.OnItemRButtonClick()
	local frame = this:GetRoot()
	if this.bItem then
		AH_Retrieval.Selected(frame, this)
		AH_Retrieval.UpdateContent(frame)
		local menu = {}
		local recipe = GetRecipe(this.nCraftID, this.nRecipeID)
		AH_Retrieval.GenerateMenu(menu, recipe)
		PopupMenu(menu)
	end
end

function AH_Retrieval.OnItemMouseEnter()
	local frame, szName = this:GetRoot(), this:GetName()
	if this.bItem then
		this.bOver = true
		AH_Retrieval.UpdateBgStatus(this)
		if _G["AH_Tip_Loaded"] then
			AH_Tip.szRecipeTip = GetFormatText(L("STR_RETRIEVAL_MAKETIP"), 112) .. GetFormatText(L("STR_RETRIEVAL_RECIPEFROM"), 101) .. this.szTip
		end
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, this.nType, this.nID, {x, y, w, h})
	elseif this.bEnchant then
		local nProID, nCraftID, nRecipeID = this:GetObjectData()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputEnchantTip(nProID, nCraftID, nRecipeID, {x, y, w, h})
	elseif this.bProduct then
		local _, dwVer, nTabType, nIndex = this:GetObjectData()
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputItemTip(UI_OBJECT_ITEM_INFO, dwVer, nTabType, nIndex, {x, y, w, h})
	elseif szName == "Handle_CListContent" or szName == "Handle_CList01" then
		this.bOver = true
		AH_Retrieval.UpdateBgStatus(this)
	elseif szName == "Box_DType1Item" or szName == "Box_DType2Item" then
		if not this:IsEmpty() then
			this:SetObjectMouseOver(true)
			local _, dwVer, nTabType, nIndex = this:GetObjectData()
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputItemTip(UI_OBJECT_ITEM_INFO, dwVer, nTabType, nIndex, {x, y, w, h})
		end
	elseif szName == "Handle_PBossItem" or szName == "Handle_PStoneItem" then
		this.bOver = true
		AH_Retrieval.UpdateBgStatus(this)
	elseif this.bPred then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, this.dwType, this.dwIndex, {x, y, w, h})
	elseif this.bStone then
		local x, y = this:GetAbsPos()
		local w, h = this:GetSize()
		OutputItemTip(UI_OBJECT_ITEM_INFO, GLOBAL.CURRENT_ITEM_VERSION, 5, this.nIndex, {x, y, w, h})
	end
end

function AH_Retrieval.OnItemMouseLeave()
	local frame, szName = this:GetRoot(), this:GetName()
	if this.bItem then
		this.bOver = false
		AH_Retrieval.UpdateBgStatus(this)
		if _G["AH_Tip_Loaded"] then
			AH_Tip.szRecipeTip = nil
		end
		HideTip()
	elseif this.bEnchant or this.bProduct or this.bPred or this.bStone then
		HideTip()
	elseif szName == "Handle_CListContent" or szName == "Handle_CList01" then
		this.bOver = false
		AH_Retrieval.UpdateBgStatus(this)
	elseif szName == "Box_DType1Item" or szName == "Box_DType2Item" then
		if not this:IsEmpty() then
			this:SetObjectMouseOver(false)
			HideTip()
		end
	elseif szName == "Handle_PBossItem" or szName == "Handle_PStoneItem" then
		this.bOver = false
		AH_Retrieval.UpdateBgStatus(this)
	end
end

function AH_Retrieval.OnLButtonHold()
	local frame, szName = this:GetRoot(), this:GetName()
	if szName == "Btn_CListUp" then
		frame:Lookup("PageSet_Main/Page_Craft"):Lookup("Wnd_CList/Scroll_CList"):ScrollPrev(1)
	elseif szName == "Btn_CListDown" then
		frame:Lookup("PageSet_Main/Page_Craft"):Lookup("Wnd_CList/Scroll_CList"):ScrollNext(1)
	elseif szName == "Btn_CSUp" then
		frame:Lookup("PageSet_Main/Page_Craft"):Lookup("Wnd_CSearch/Scroll_CSearch"):ScrollPrev(1)
	elseif szName == "Btn_CSDown" then
		frame:Lookup("PageSet_Main/Page_Craft"):Lookup("Wnd_CSearch/Scroll_CSearch"):ScrollNext(1)
	elseif szName == "Btn_PBUp" then
		frame:Lookup("PageSet_Main/Page_Prediction"):Lookup("Scroll_PBList"):ScrollPrev(1)
	elseif szName == "Btn_PBDown" then
		frame:Lookup("PageSet_Main/Page_Prediction"):Lookup("Scroll_PBList"):ScrollNext(1)
	elseif szName == "Btn_PSUp" then
		frame:Lookup("PageSet_Main/Page_Prediction"):Lookup("Scroll_PSList"):ScrollPrev(1)
	elseif szName == "Btn_PSDown" then
		frame:Lookup("PageSet_Main/Page_Prediction"):Lookup("Scroll_PSList"):ScrollNext(1)
    end
end

function AH_Retrieval.OnLButtonDown()
	AH_Retrieval.OnLButtonHold()
end

function AH_Retrieval.OnItemMouseWheel()
	local frame, szName = this:GetRoot(), this:GetName()
	local nDistance = Station.GetMessageWheelDelta()
	if szName == "Handle_CList" then
		frame:Lookup("PageSet_Main/Page_Craft"):Lookup("Wnd_CList/Scroll_CList"):ScrollNext(nDistance)
	elseif szName == "Handle_CSearchList" then
		frame:Lookup("PageSet_Main/Page_Craft"):Lookup("Wnd_CSearch/Scroll_CSearch"):ScrollNext(nDistance)
	elseif szName == "Handle_BossList" then
		frame:Lookup("PageSet_Main/Page_Prediction"):Lookup("Scroll_PBList"):ScrollNext(nDistance)
	elseif szName == "Handle_StoneList" then
		frame:Lookup("PageSet_Main/Page_Prediction"):Lookup("Scroll_PSList"):ScrollNext(nDistance)
	end
	return true
end

function AH_Retrieval.OnScrollBarPosChanged()
	local hWnd  = this:GetParent()
	local szName = this:GetName()
	local nCurrentValue = this:GetScrollPos()
	local hBtnUp, hBtnDown, hList = nil, nil, nil
	if szName == "Scroll_CList" then
		hBtnUp = hWnd:Lookup("Btn_CListUp")
		hBtnDown = hWnd:Lookup("Btn_CListDown")
		hList = hWnd:Lookup("", "")
	elseif szName == "Scroll_CSearch" then
		hBtnUp = hWnd:Lookup("Btn_CSUp")
		hBtnDown = hWnd:Lookup("Btn_CSDown")
		hList = hWnd:Lookup("", "")
	elseif szName == "Scroll_PBList" then
		hBtnUp = hWnd:Lookup("Btn_PBUp")
		hBtnDown = hWnd:Lookup("Btn_PBDown")
		hList = hWnd:Lookup("", ""):Lookup("Handle_BossList")
	elseif szName == "Scroll_PSList" then
		hBtnUp = hWnd:Lookup("Btn_PSUp")
		hBtnDown = hWnd:Lookup("Btn_PSDown")
		hList = hWnd:Lookup("", ""):Lookup("Handle_StoneList")
	end
	if nCurrentValue == 0 then
		hBtnUp:Enable(false)
	else
		hBtnUp:Enable(true)
	end

	if nCurrentValue == this:GetStepCount() then
		hBtnDown:Enable(false)
	else
		hBtnDown:Enable(true)
	end
	hList:SetItemStartRelPos(0, -nCurrentValue * 10)
end

function AH_Retrieval.IsPanelOpened()
	local frame = Station.Lookup("Normal/AH_Retrieval")
	if frame and frame:IsVisible() then
		return true
	end
	return false
end

function AH_Retrieval.OpenPanel()
	local frame = nil
	if not AH_Retrieval.IsPanelOpened() then
		frame = Wnd.OpenWindow(szIniFile, "AH_Retrieval")
		AH_Retrieval.InitCraft(frame)
		AH_Retrieval.InitPrediction(frame)
		for nIndex = 1, 2 do
			AH_Retrieval.InitDiamond(frame, nIndex)
		end
	else
		AH_Retrieval.ClosePanel()
	end
	PlaySound(SOUND.UI_SOUND,g_sound.OpenFrame)
end

function AH_Retrieval.ClosePanel()
	if AH_Retrieval.IsPanelOpened() then
		Wnd.CloseWindow("AH_Retrieval")
	end
	PlaySound(SOUND.UI_SOUND,g_sound.CloseFrame)
end

RegisterEvent("LOGIN_GAME", function()
	TraceButton_AppendAddonMenu({{
		szOption = L("STR_RETRIEVAL_TITLE"),
		fnAction = function()
			AH_Retrieval.OpenPanel()
		end,
	}})
end)


