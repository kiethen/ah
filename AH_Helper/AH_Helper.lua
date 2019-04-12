------------------------------------------------------
-- #模块名：交易行模块
-- #模块说明：交易行各类功能的增强
------------------------------------------------------
local L = AH_Library.LoadLangPack()

_G["AH_Helper_Loaded"] = true

local ipairs = ipairs
local pairs = pairs
local tonumber = tonumber

--------------------------------------------------------
-- 插件配置
--------------------------------------------------------
AH_Helper = {
	szDefaultValue = "Btn_Min",
	szDefaultTime = L("STR_HELPER_24HOUR"),

	nVersion = 0,
	nPricePercentage = 0.95,
	nDefaultPrices = 1,
	nMaxHistory = 10,
	--nMultiple = 1.5,

	bShowQualityLevel = true,
	bRealTime = true,
	bBidderName = true,
	bFastBid = true,
	bFastBuy = true,
	bFastCancel = true,
	bDBClickFastBuy = false,
	bDBClickFastCancel = false,
	--bNoAllPrompt = false,
	bPricePercentage = false,
	bLowestPrices = true,
	bFilterRecipe = false,
	bFilterBook = false,
	bAutoSearch = true,
	--bSellNotice = false,
	bFormatMoney = false,
	bDBCtrlSell = false,
	--bGuard = true,
    bExVersion = false,

	tItemFavorite = {},
	tBlackList = {},
	tSellerList = {},
	tItemHistory = {},
	tItemPrice = {},
    tCDiamondPrice = {},

	tRealTimeColor = {255, 0, 0},
	tBidderNameColor = {0, 200, 0},

	szDataPath = "\\Interface\\AH\\AH_Base\\data\\ah.jx3dat",
	szDataPathCDiamond = "\\Interface\\AH\\AH_Base\\data\\ahcdiamond.jx3dat",
	szVersion = "3.6.5",
}

--------------------------------------------------------
-- 交易行数据缓存
--------------------------------------------------------
local tBidTime = {}
local tTempSellPrice = {}
local tTempCDiamondSellPrice = {}
local bFilterd = false
local bHooked = false
local bAutoSearch = false
local szSellerSearch = ""
--------------------------------------------------------
-- 用户数据存储
--------------------------------------------------------
RegisterCustomData("AH_Helper.szDefaultValue")
RegisterCustomData("AH_Helper.szDefaultTime")
RegisterCustomData("AH_Helper.nDefaultPrices")
RegisterCustomData("AH_Helper.nMaxHistory")
--RegisterCustomData("AH_Helper.nMultiple")
RegisterCustomData("AH_Helper.nPricePercentage")
RegisterCustomData("AH_Helper.bFilterRecipe")
RegisterCustomData("AH_Helper.bFilterBook")
RegisterCustomData("AH_Helper.bAutoSearch")
RegisterCustomData("AH_Helper.bLowestPrices")
RegisterCustomData("AH_Helper.bPricePercentage")
RegisterCustomData("AH_Helper.bShowQualityLevel")
RegisterCustomData("AH_Helper.bFastBid")
RegisterCustomData("AH_Helper.bFastBuy")
RegisterCustomData("AH_Helper.bFastCancel")
--RegisterCustomData("AH_Helper.bGuard")
RegisterCustomData("AH_Helper.bExVersion")
RegisterCustomData("AH_Helper.bRealTime")
RegisterCustomData("AH_Helper.bBidderName")
RegisterCustomData("AH_Helper.bDBClickFastBuy")
RegisterCustomData("AH_Helper.bDBClickFastCancel")
RegisterCustomData("AH_Helper.bDBCtrlSell")
RegisterCustomData("AH_Helper.tItemHistory")
RegisterCustomData("AH_Helper.tItemFavorite")
RegisterCustomData("AH_Helper.tBlackList")
RegisterCustomData("AH_Helper.tSellerList")
RegisterCustomData("AH_Helper.tRealTimeColor")
RegisterCustomData("AH_Helper.tBidderNameColor")
--------------------------------------------------------
-- AH局部变量初始化
--------------------------------------------------------
local NO_BID_PRICE = PackMoney(9000000, 0, 0)
local PRICE_LIMITED = PackMoney(800000, 0, 0)

local tSearchInfoDefault = {
	["Name"]     = L("STR_HELPER_ITEMNAME"),
	["Level"]    = {"", ""},
	["Quality"]  = L("STR_HELPER_ANYLEVEL"),
	["Status"]   = L("STR_HELPER_ALLSTATE"),
	["MaxPrice"] = {"", "" ,""},
}

local AUCTION_ORDER_TYPE = {
	QUALITY 			= 0,
	LEVEL 				= 1,
	LEFT_TIME 			= 2,
	PRICE				= 3,
	BUY_IT_NOW_PRICE 	= 4,
}

local tItemDataInfo =
{
	["Search"] = {nStart = 1, nCurCount = 0, nTotCount = 0, nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE, bDesc = 0, bUnitPrice=true, nRequestID = 0, szCheckName = "CheckBox_RName"},
	["Sell"]   = {nStart = 1, nCurCount = 0, nTotCount = 0, nSortType = AUCTION_ORDER_TYPE.QUALITY, bDesc = 1, bUnitPrice=false, nRequestID = 1, szCheckName = "CheckBox_AName"},
	["Bid"]    = {nStart = 1, nCurCount = 0, nTotCount = 0, nSortType = AUCTION_ORDER_TYPE.LEFT_TIME, bDesc = 1, bUnitPrice=false, nRequestID = 2, szCheckName = "CheckBox_BRemainTime"},
}

local tItemWidgetInfo =
{
	["Search"] =
	{
		Scroll="Scroll_Result", BtnUp="Btn_RUp", BtnDown="Btn_RDown", Box="Box_Box", Text="Text_BoxName", Level="Text_BoxLevel", Saler="Text_BoxSaler", Time="Text_BoxRemainTime",
		aBidText={"Handle_BidMoney",  "Text_MyBid"},
		aBuyText={"Handle_BidMoneyU", "Text_UnitPrice"},
		tCheck =
		{
			["CheckBox_RName"]      = {imgUp = "Image_RNameUp",     imgDown = "Image_RNameDown",     nSortType = AUCTION_ORDER_TYPE.QUALITY},
			["CheckBox_RLevel"]     = {imgUp = "Image_RLevelUp",    imgDown = "Image_RLevelDown",    nSortType = AUCTION_ORDER_TYPE.LEVEL},
			["CheckBox_RemainTime"] = {imgUp = "Image_ReNameUp",    imgDown = "Image_ReNameDown",    nSortType = AUCTION_ORDER_TYPE.LEFT_TIME},
			["CheckBox_Bid"]        = {imgUp = "Image_BidNameUp",   imgDown = "Image_BidNameDown",   nSortType = AUCTION_ORDER_TYPE.PRICE},
			["CheckBox_Price"]      = {imgUp = "Image_PriceNameUp", imgDown = "Image_PriceNameDown", nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE},
		}
	},
	["Bid"] =
	{
		Scroll="Scroll_Bid", BtnUp="Btn_BUp", BtnDown="Btn_BDown", Box="Box_BidBox", Text="Text_BidBoxName", Level="Text_BidBoxLevel", Saler="Text_BidBoxSaler", Time="Text_BidBoxRemainTime",
		aBidText={"Handle_BidBidMoney", "Text_BidMyBid"},
		aBuyText={"Handle_BBidMoneyU",  "Text_BUnitPrice"},
		tCheck =
		{
			["CheckBox_BName"]       = {imgUp = "Image_BNameUp",      imgDown = "Image_BNameDown",      nSortType = AUCTION_ORDER_TYPE.QUALITY},
			["CheckBox_BLevel"]      = {imgUp = "Image_BLevelUp",     imgDown = "Image_BLevelDown",     nSortType = AUCTION_ORDER_TYPE.LEVEL},
			["CheckBox_BRemainTime"] = {imgUp = "Image_BReNameUp",    imgDown = "Image_BReNameDown",    nSortType = AUCTION_ORDER_TYPE.LEFT_TIME},
			["CheckBox_BBid"]        = {imgUp = "Image_BBidNameUp",   imgDown = "Image_BBidNameDown",   nSortType = AUCTION_ORDER_TYPE.PRICE},
			["CheckBox_BPrice"]      = {imgUp = "Image_BPriceNameUp", imgDown = "Image_BPriceNameDown", nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE},
		}
	},
	["Sell"] =
	{
		Scroll="Scroll_Auction", BtnUp="Btn_AUp", BtnDown="Btn_ADown", Box="Box_ABox", Text="Text_ABoxName", Level="Text_ABoxLevel", Saler="Text_ABoxSaler", Time="Text_ABoxRemainTime",
		aBidText={"Handle_ABidMoney", "Text_AMyBid",},
		aBuyText={"Handle_ABidMoneyU", "Text_AUnitPrice",},
		tCheck =
		{
			["CheckBox_AName"]       = {imgUp = "Image_ANameUp",      imgDown = "Image_ANameDown",      nSortType = AUCTION_ORDER_TYPE.QUALITY},
			["CheckBox_ALevel"]      = {imgUp = "Image_ALevelUp",     imgDown = "Image_ALevelDown",     nSortType = AUCTION_ORDER_TYPE.LEVEL},
			["CheckBox_ARemainTime"] = {imgUp = "Image_AReNameUp",    imgDown = "Image_AReNameDown",    nSortType = AUCTION_ORDER_TYPE.LEFT_TIME},
			["CheckBox_ABid"]        = {imgUp = "Image_ABidNameUp",   imgDown = "Image_ABidNameDown",   nSortType = AUCTION_ORDER_TYPE.PRICE},
			["CheckBox_APrice"]      = {imgUp = "Image_APriceNameUp", imgDown = "Image_APriceNameDown", nSortType = AUCTION_ORDER_TYPE.BUY_IT_NOW_PRICE},
		}
	}
}

AH_Helper.UpdateItemListOrg = AuctionPanel.UpdateItemList
AH_Helper.SetSaleInfoOrg = AuctionPanel.SetSaleInfo
AH_Helper.FormatAuctionTimeOrg = AuctionPanel.FormatAuctionTime
AH_Helper.GetItemSellInfoOrg = AuctionPanel.GetItemSellInfo
AH_Helper.OnMouseEnterOrg = AuctionPanel.OnMouseEnter
AH_Helper.OnMouseLeaveOrg = AuctionPanel.OnMouseLeave
AH_Helper.OnFrameBreatheOrg = AuctionPanel.OnFrameBreathe
AH_Helper.OnLButtonClickOrg = AuctionPanel.OnLButtonClick
AH_Helper.OnExchangeBoxItemOrg = AuctionPanel.OnExchangeBoxItem
AH_Helper.AuctionSellOrg = AuctionPanel.AuctionSell
AH_Helper.UpdateItemPriceInfoOrg = AuctionPanel.UpdateItemPriceInfo
AH_Helper.ApplyLookupOrg = AuctionPanel.ApplyLookup
AH_Helper.OnItemLButtonClickOrg = AuctionPanel.OnItemLButtonClick
AH_Helper.OnItemLButtonDBClickOrg = AuctionPanel.OnItemLButtonDBClick
AH_Helper.OnItemMouseEnterOrg = AuctionPanel.OnItemMouseEnter
AH_Helper.OnItemMouseLeaveOrg = AuctionPanel.OnItemMouseLeave
AH_Helper.OnEditChangedOrg = AuctionPanel.OnEditChanged
AH_Helper.InitOrg = AuctionPanel.Init
--AH_Helper.ShowNoticeOrg = AuctionPanel.ShowNotice	--去除免确认
AH_Helper.UpdateSaleInfoOrg = AuctionPanel.UpdateSaleInfo
AH_Helper.ExchangeBagAndAuctionItemOrg = AuctionPanel.ExchangeBagAndAuctionItem
--AH_Helper.AuctionBuyOrg = AuctionPanel.AuctionBuy
AH_Helper.OnCheckBoxCheckOrg = AuctionPanel.OnCheckBoxCheck
AH_Helper.SetItemNameOrg = AuctionPanel.SetItemName
--------------------------------------------------------
-- 系统AH函数重构
--------------------------------------------------------
local function FormatMoney(handle, bText)
	local szMoney = 0
	if bText then
		szMoney = handle
	else
		szMoney = handle:GetText()
	end
	if not szMoney or szMoney == "" then
		szMoney = 0
	end
	return tonumber(szMoney)
end

local function ConvertMoney(editGB, editG, editS, editC, bUnpack)
	local nGoldB, nGold, nSilver, nCopper = 0, 0, 0, 0
	if editGB then
		if editGB.GetText then
			nGoldB = tonumber(editGB:GetText()) or 0
		else
			nGoldB = tonumber(editGB) or 0
		end
	end

	if editG then
		if editG.GetText then
			nGold = tonumber(editG:GetText()) or 0
		else
			nGold = tonumber(editG) or 0
		end
	end

	if editS then
		if editS.GetText then
			nSilver = tonumber(editS:GetText()) or 0
		else
			nSilver = tonumber(editS) or 0
		end
	end

	if editC then
		if editC.GetText then
			nCopper = tonumber(editC.GetText()) or 0
		else
			nCopper = tonumber(editC) or 0
		end
	end

	if bUnpack then
		return (nGoldB * 10000 + nGold), nSilver, nCopper
	end
	return PackMoney( (nGoldB * 10000 + nGold), nSilver, nCopper )
end

local function GetMoneyTextEx(tMoney, szFont)
    local szText = ""
    local bCheckZero = true
    local nGold, nSilver, nCopper = tMoney.nGold, tMoney.nSilver, tMoney.nCopper
    if nGold ~= 0 then
        szText = szText.."<text>text=\""..nGold.."\""..szFont.."</text><image>path=\"UI/Image/Common/Money.UITex\" frame=0</image>"
        bCheckZero = false
    end

    if not bCheckZero or nSilver ~= 0 then
        szText = szText.."<text>text=\""..nSilver.."\""..szFont.."</text><image>path=\"UI/Image/Common/Money.UITex\" frame=2</image>"
    end

    szText = szText.."<text>text=\""..nCopper.."\""..szFont.."</text><image>path=\"UI/Image/Common/Money.UITex\" frame=1</image>"
	return szText
end

--[[local function FormatBigMoney(nGold)
	if AH_Helper.bFormatMoney then
		local nLen, szGold = GetIntergerBit(nGold), tostring(nGold)
		if nLen > 3 then
			local a = string.sub(szGold, 0, nLen - 3)
			local b = string.sub(szGold, -3)
			return string.format("%s, %s", a, b)
		end
		return szGold
	end
	return nGold
end]]

function AuctionPanel.UpdateItemList(frame, szDataType, tItemInfo)
	if not tItemInfo then
		tItemInfo = {}
	end

	local INI_FILE_PATH = "UI/Config/Default/AuctionItem.ini"
	local player = GetClientPlayer()
	local hList, szItem = nil, nil
	if szDataType == "Search" then
		hList = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2", "Handle_List")
		szItem = "Handle_ItemList"
	elseif szDataType == "Bid" then
		hList = frame:Lookup("PageSet_Totle/Page_State/Wnd_Bid", "Handle_BidList")
		szItem = "Handle_BidItemList"
	elseif szDataType == "Sell" then
		hList = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Auction", "Handle_AList")
		szItem = "Handle_AItemList"
	end
	if szItem == "Handle_ItemList" or "Handle_AItemList" then
        INI_FILE_PATH = "Interface/AH/AH_Helper/AH_AuctionItem.ini"
    end
	hList:Clear()
	for k, v in pairs(tItemInfo) do
		bFilterd = false
		if v["Item"] then
			if szDataType == "Search" then
				--卖家屏蔽
				if not AH_Helper.IsInBlackList(v["SellerName"]) then
					--过滤已读秘籍
					if AH_Helper.bFilterRecipe and v["Item"].nGenre == ITEM_GENRE.MATERIAL and v["Item"].nSub == 5 then
						if not IsMystiqueRecipeRead(v["Item"]) then
							local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
							AuctionPanel.SetSaleInfo(hItem, szDataType, v)
						else
							bFilterd = true
						end
					elseif AH_Helper.bFilterBook and v["Item"].nGenre == ITEM_GENRE.BOOK then
						local nBookID, nSegmentID = GlobelRecipeID2BookID(v["Item"].nBookID)
						if not GetClientPlayer().IsBookMemorized(nBookID, nSegmentID) then
							local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
							AuctionPanel.SetSaleInfo(hItem, szDataType, v)
						else
							bFilterd = true
						end
					else
						local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
						AuctionPanel.SetSaleInfo(hItem, szDataType, v)
					end
				end
			else
				local hItem = hList:AppendItemFromIni(INI_FILE_PATH, szItem)
				AuctionPanel.SetSaleInfo(hItem, szDataType, v)
			end
		else
			Trace("KLUA[ERROR] ui/Config/Default/AuctionPanel.lua UpdateItemList item is nil!!\n")
		end
	end

	AuctionPanel.OnUpdateItemList(hList, szDataType, true)
	AuctionPanel.UpdateItemPriceInfo(hList, szDataType)
	AuctionPanel.UpdateSelectedInfo(frame, szDataType)

	local hWnd = hList:GetParent():GetParent()
	AuctionPanel.OnItemDataInfoUpdate(hWnd, szDataType)

	--历史记录
	if szDataType == "Search" then
		local hEdit = AH_Helper.GetSearchEdit(frame)
		local szKeyName = hEdit:GetText()
		szKeyName = StringReplaceW(szKeyName, " ", "")
		if not AH_Helper.IsInHistory(szKeyName) and szKeyName ~= L("STR_HELPER_ITEMNAME") and szKeyName ~= "" then
			AH_Helper.AddHistory(szKeyName)
		end
	end
end

function AuctionPanel.SetSaleInfo(hItem, szDataType, tItemData)
	local player = GetClientPlayer()
	local tInfo = tItemWidgetInfo[szDataType]
	local item = tItemData["Item"]

	local nIconID = Table_GetItemIconID(item.nUiId)
	local hBox = hItem:Lookup(tInfo.Box)
	local hTextName = hItem:Lookup(tInfo.Text)
	local hTextSaler = hItem:Lookup(tInfo.Saler)

	hItem.nItemID = item.dwID	--Fix Bug:日月明尊
	hItem.nUiId = item.nUiId
	hItem.nGenre = item.nGenre	--修复无法购买书籍
	hItem.nSaleID = tItemData["ID"]
	hItem.nCRC = tItemData["CRC"]
	hItem.szItemName = GetItemNameByItem(item)
	hItem.szBidderName = tItemData["BidderName"] or ""
	hItem.szSellerName = tItemData["SellerName"]
	hItem.tBidPrice = tItemData["Price"]
	hItem.tBuyPrice = tItemData["BuyItNowPrice"]

	hItem.nQuality = item.nQuality
	hItem.nVersion = item.nVersion
	hItem.dwTabType = item.dwTabType
	hItem.dwIndex = item.dwIndex

	if MoneyOptCmp(hItem.tBuyPrice, 0) == 0 then
		hItem.tBuyPrice = NO_BID_PRICE
	end

	local nCount = 1
	if item.nGenre == ITEM_GENRE.EQUIPMENT then
		if item.nSub == EQUIPMENT_SUB.ARROW then --远程武器
			nCount = item.nCurrentDurability
		else
			if AH_Helper.bShowQualityLevel then
				hBox:SetOverText(1, item.nLevel)
			end
		end
	elseif item.bCanStack then
		nCount = item.nStackNum
	end

	if nCount == 1 then
		hBox:SetOverText(0, "")
	else
		hBox:SetOverText(0, nCount)
	end
	hItem.nCount = nCount

	--附加TIP所需数据到box
	hBox.nItemID = item.dwID
	hBox.tBidPrice = tItemData["Price"]
	hBox.tBuyPrice = tItemData["BuyItNowPrice"]
	hBox.nCount = nCount

	--价格记录
	if szDataType == "Search" then
		local szKey = (item.nGenre == ITEM_GENRE.BOOK) and hItem.szItemName or item.nUiId
		hItem.szKey = szKey

		if AH_Helper.tItemPrice[szKey] == nil or AH_Helper.tItemPrice[szKey][2] ~= AH_Helper.nVersion then
			AH_Helper.tItemPrice[szKey] = {NO_BID_PRICE, AH_Helper.nVersion}
		end
		if MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) ~= 0 then
			local tBuyPrice = MoneyOptDiv(hItem.tBuyPrice, hItem.nCount)
			--最低一口价
			if MoneyOptCmp(AH_Helper.tItemPrice[szKey][1], tBuyPrice) == 1 then
				AH_Helper.tItemPrice[szKey][1] = tBuyPrice
				--[[if bAutoSearch then
					local szMoney = GetMoneyText((tBuyPrice), "font=10")
					local szColor = GetItemFontColorByQuality(item.nQuality, true)
					local szItem = MakeItemInfoLink(string.format("[%s]", hItem.szItemName), string.format("font=10 %s", szColor), item.nVersion, item.dwTabType, item.dwIndex)
					AH_Library.Message({szItem, L("STR_HELPER_PRICE3"), szMoney}, "MONEY")
				end]]
			end
			-- 五彩石最低一口价
			if item.nGenre == ITEM_GENRE.COLOR_DIAMOND then
				local nLevel = item.nDetail
				if AH_Helper.tCDiamondPrice[nLevel] == nil or AH_Helper.tCDiamondPrice[nLevel][2] ~= AH_Helper.nVersion then
					AH_Helper.tCDiamondPrice[nLevel] = {NO_BID_PRICE, AH_Helper.nVersion}
				end
			 	if MoneyOptCmp(AH_Helper.tCDiamondPrice[nLevel][1], tBuyPrice) == 1 then
					AH_Helper.tCDiamondPrice[nLevel][1] = tBuyPrice
				end
			end
		end
	end

	hTextName:SetText(hItem.szItemName)
	hTextName:SetFontColor(GetItemFontColorByQuality(item.nQuality, false))

	hBox:SetObject(UI_OBJECT_ITEM_INFO, item.nVersion, item.dwTabType, item.dwIndex)
	hBox:SetObjectIcon(nIconID)
	UpdateItemBoxExtend(hBox, item.nGenre, item.nQuality, item.nStrengthLevel)
	hBox:SetOverTextPosition(0, ITEM_POSITION.RIGHT_BOTTOM)
	hBox:SetOverTextFontScheme(0, 15)
	hBox:SetOverTextPosition(1, ITEM_POSITION.LEFT_TOP)
	hBox:SetOverTextFontScheme(1, 16)

	hItem:Lookup(tInfo.Level):SetText(item.GetRequireLevel())
	if szDataType == "Sell" then
		if hItem.szBidderName == "" then
			hTextSaler:SetText(L("STR_HELPER_NOBODY"))
			hTextSaler:SetFontColor(255, 0, 0)
		else
			hTextSaler:SetText(hItem.szBidderName)
			hTextSaler:SetFontColor(0, 200, 0)
		end
	else
		hTextSaler:SetText(tItemData["SellerName"])
	end

	--[[local nGold, nSliver, nCopper = UnpackMoney(hItem.tBidPrice)
	hItem:Lookup(tInfo.aBidText[1]):SetText(nGold)
	hItem:Lookup(tInfo.aBidText[2]):SetText(nSliver)
	hItem:Lookup(tInfo.aBidText[3]):SetText(nCopper)]]
    local smoney = AH_Helper.bExVersion and GetMoneyTextEx(hItem.tBidPrice, "font=212") or GetMoneyText(hItem.tBidPrice, "font=212", "all3", nil, 18)
	local hMoney = hItem:Lookup(tInfo.aBidText[1])
	hMoney:Clear()
	hMoney:AppendItemFromString(smoney)
	hMoney:FormatAllItemPos()

	if MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) ~= 0 then
		--[[nGold, nSliver, nCopper = UnpackMoney(hItem.tBuyPrice)
		hItem:Lookup(tInfo.aBuyText[1]):SetText(nGold)
		hItem:Lookup(tInfo.aBuyText[2]):SetText(nSliver)
		hItem:Lookup(tInfo.aBuyText[3]):SetText(nCopper)]]
        smoney = AH_Helper.bExVersion and GetMoneyTextEx(hItem.tBuyPrice, "font=212") or GetMoneyText(hItem.tBuyPrice, "font=212", "all3", nil, 18)
		hMoney = hItem:Lookup(tInfo.aBuyText[1])
		hMoney:Clear()
		hMoney:AppendItemFromString(smoney)
		hMoney:FormatAllItemPos()
	else
		--[[hItem:Lookup(tInfo.aBuyImg[1]):Hide()
		hItem:Lookup(tInfo.aBuyImg[2]):Hide()
		hItem:Lookup(tInfo.aBuyImg[3]):Hide()
		hItem:Lookup(tInfo.aBuyText[4]):Hide()]]
		hItem:Lookup(tInfo.aBuyText[1]):Hide()
		hItem:Lookup(tInfo.aBuyText[2]):Hide()
	end

	--竞拍时间显示秒
	local nLeftTime = tItemData["LeftTime"]
	local hTextTime = hItem:Lookup(tInfo.Time)
	local szTime = AuctionPanel.FormatAuctionTime(nLeftTime)
	if nLeftTime <= 120 and AH_Helper.bRealTime then
		hTextTime:SetText(L("STR_HELPER_SECOND", nLeftTime))
		hTextTime:SetFontColor(unpack(AH_Helper.tRealTimeColor))
	else
		hTextTime:SetText(szTime)
	end
	--记录拍卖剩余时间
	if not tBidTime[hItem.nSaleID] or tBidTime[hItem.nSaleID].nVersion ~= AH_Helper.nVersion then
		tBidTime[hItem.nSaleID] = {nTime = nLeftTime * 1000 + GetTickCount(), nVersion = AH_Helper.nVersion}
	end
	hItem:Show()
end

function AuctionPanel.FormatAuctionTime(nTime)
	if not AH_Helper.bRealTime and nTime < 600 then
		return L("STR_HELPER_NEAR_DUE")
	end

	local szText = ""
	local nH, nM, nS = GetTimeToHourMinuteSecond(nTime, false)
	if nH and nH > 0 then
		if (nM and nM > 0) or (nS and nS > 0) then
			nH = nH + 1
		end
		szText = szText..nH..g_tStrings.STR_BUFF_H_TIME_H
	else
		nM = nM or 0
		nS = nS or 0
		if nM == 0 and nS == 0 then
			return szText
		end

		if nS > 0 then
			nM = nM + 1
		end

		if nM >= 60 then
			szText = szText..math.ceil(nM / 60)..g_tStrings.STR_BUFF_H_TIME_H
		else
			szText = szText..nM..g_tStrings.STR_BUFF_H_TIME_M
		end
	end

	return szText
end

--无记录时调整寄售时间
function AuctionPanel.UpdateSaleInfo(frame, bDefault)
	AH_Helper.UpdateSaleInfoOrg(frame, bDefault)
	if bDefault then
		local hWndSale = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale")
		local handle = hWndSale:Lookup("", "")
		local box = handle:Lookup("Box_Item")
		local textTime = handle:Lookup("Text_Time")
		local textItemName = handle:Lookup("Text_ItemName")
		if not box:IsEmpty() then
			local szItemName = textItemName:GetText()
			if not AH_Helper.tItemPrice[szItemName] then
				local szText = textTime:GetText()
				if szText ~= AH_Helper.szDefaultTime then
					textTime:SetText(AH_Helper.szDefaultTime)
				end
			end
		end
	end
end

function AuctionPanel.GetItemSellInfo(szItemName)
	local frame = Station.Lookup("Normal/AuctionPanel")
	local szText = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale", "Text_ItemName"):GetText()
	local box = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale", "Box_Item")
	local item = GetPlayerItem(GetClientPlayer(), box.dwBox, box.dwX)
	local szKey = (szItemName == L("STR_HELPER_BOOK")) and szText or item.nUiId	--书籍名字转化
    if AH_Helper.szDefaultValue == "Btn_Min" then
		local function GetSellInfo(szName, tPrice)
			local u = {szName = szName, tBidPrice = tPrice[1], tBuyPrice = tPrice[1], szTime = AH_Helper.szDefaultTime}
			if AH_Helper.bLowestPrices then
				if AH_Helper.bPricePercentage then
					u.tBidPrice = MoneyOptMult(u.tBidPrice, AH_Helper.nPricePercentage)
					u.tBuyPrice = MoneyOptMult(u.tBuyPrice, AH_Helper.nPricePercentage)
				else
					--单价判断，防止差价溢出
					if MoneyOptCmp(u.tBidPrice, AH_Helper.nDefaultPrices) == 1 then
						u.tBidPrice = MoneyOptSub(u.tBidPrice, AH_Helper.nDefaultPrices)
					end
					if MoneyOptCmp(u.tBuyPrice, AH_Helper.nDefaultPrices) == 1 then
						u.tBuyPrice = MoneyOptSub(u.tBuyPrice, AH_Helper.nDefaultPrices)
					end
				end
			end
			return u
		end
		if tTempSellPrice[szKey] then
			AH_Library.Message(L("STR_HELPER_LOWPRICE"))
			local tPrice = {tTempSellPrice[szKey]}
			return GetSellInfo(szKey, tPrice)
		else
			for k, v in pairs(AH_Helper.tItemPrice) do
				if szKey == k and MoneyOptCmp(v[1], NO_BID_PRICE) ~= 0 then
					AH_Library.Message(L("STR_HELPER_LOWPRICE"))
					if type(szKey) == "string" then
						return GetSellInfo(szKey, v)
					else
						return GetSellInfo(szItemName, v)
					end
				end
			end
		end
		if item.nGenre == ITEM_GENRE.COLOR_DIAMOND then
			local tPrice = AH_Helper.tCDiamondPrice[item.nDetail]
			if tPrice and MoneyOptCmp(tPrice[1], NO_BID_PRICE) ~= 0 then
				AH_Library.Message(L("STR_HELPER_CDIAMONDPRICE"))
				if type(szKey) == "string" then
					return GetSellInfo(szKey, tPrice)
				else
					return GetSellInfo(szItemName, tPrice)
				end
			end
		end
	else
		for k, v in pairs(AuctionPanel.tItemSellInfoCache) do
			if v.szName == szItemName then
				AH_Library.Message(L("STR_HELPER_SYSTEMPRICE"))
				return v
			end
		end
    end
	AH_Library.Message(L("STR_HELPER_NOITEMPRICE"))
	return nil
end

function AuctionPanel.OnMouseEnter()
	local szName = this:GetName()
	if szName == "Btn_Sale" then
		AH_Library.OutputTip(L("STR_HELPER_TIP1"))
	elseif szName == "Btn_History" then
		AH_Library.OutputTip(L("STR_HELPER_TIP2"))
	end
end

function AuctionPanel.OnMouseLeave()
	local szName = this:GetName()
	if szName == "Btn_Sale" then
		HideTip()
	elseif szName == "Btn_History" then
		HideTip()
	end
end

function AuctionPanel.OnFrameBreathe()
	AH_Helper.OnFrameBreatheOrg()
	AH_Helper.OnBreathe()
end

function AuctionPanel.OnLButtonClick()
	local szName  = this:GetName()
	if szName == "Btn_Search" then
		local hEdit = AH_Helper.GetSearchEdit()
		local szText = hEdit:GetText()
		szText = string.gsub(szText, "^%s*(.-)%s*$", "%1")
		szText = string.gsub(szText, "[%[%]]", "")
		hEdit:SetText(szText)
		--bAutoSearch = false
		szSellerSearch = ""
	elseif szName == "Btn_SearchDefault" then
		szSellerSearch = ""
	end
	return AH_Helper.OnLButtonClickOrg()
end

function AuctionPanel.OnExchangeBoxItem(boxItem, boxDsc, nHandCount, bHand)
	if boxDsc == AH_Helper.boxDsc and not boxItem:IsEmpty() then
		local frame = Station.Lookup("Normal/AuctionPanel")
		if AH_Helper.bDBCtrlSell then
			AH_Helper.AuctionAutoSell(frame)
		else
			return AH_Helper.AuctionSellOrg(frame)
		end
	else
		AH_Helper.OnExchangeBoxItemOrg(boxItem, boxDsc, nHandCount, bHand)
		AH_Helper.boxDsc = boxDsc
		RemoveUILockItem("Auction")
	end
end

function AuctionPanel.OnEditChanged()
	local szName = this:GetName()
	if szName == "Edit_ItemName" and AH_Helper.bAutoSearch then
		local hFocus = Station.GetFocusWindow()
		if hFocus then
			local szName = hFocus:GetName()
			if this:GetTextLength() > 0 and szName == "BigBagPanel" then
				--bAutoSearch = true
				AH_Helper.UpdateList(this:GetText(), "", true)
			end
		end
	else
		return AH_Helper.OnEditChangedOrg()
	end
end

function AuctionPanel.AuctionSell(frame)
	if IsShiftKeyDown() then
		--[[if not AH_Helper.bSellNotice then
			local tMsg =
			{
				szName = "AuctionSell",
				szMessage = L("STR_HELPER_MESSAGE2"),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() AH_Helper.AuctionAutoSell(frame) end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
			}
			MessageBox(tMsg)
		else
			AH_Helper.AuctionAutoSell(frame)
		end]]
		AH_Helper.AuctionAutoSell(frame)
	elseif IsAltKeyDown() then
		--[[if not AH_Helper.bSellNotice then
			local tMsg =
			{
				szName = "AuctionSell2",
				szMessage = L("STR_HELPER_MESSAGE2"),
				{szOption = g_tStrings.STR_HOTKEY_SURE, fnAction = function() AH_Helper.AuctionSimilarAutoSell(frame) end, },
				{szOption = g_tStrings.STR_HOTKEY_CANCEL, },
			}
			MessageBox(tMsg)
		else
			AH_Helper.AuctionSimilarAutoSell(frame)
		end]]
		AH_Helper.AuctionSimilarAutoSell(frame)
	else
		return AH_Helper.AuctionSellOrg(frame)
	end
end

function AuctionPanel.UpdateItemPriceInfo(hList,szDataType)
	if szDataType == "Search" then
		AH_Helper.UpdatePriceInfo(hList, szDataType)
		local frame = Station.Lookup("Normal/AuctionPanel")
		local page  = frame:Lookup("PageSet_Totle/Page_Business")
		local hWndResult = page:Lookup("Wnd_Result2")
		local btn  = hWndResult:Lookup("Btn_Next")

		if bFilterd then
			if btn:IsEnabled() then
				OutputMessage("MSG_ANNOUNCE_YELLOW", L("STR_HELPER_ALERT1"))
			else
				OutputMessage("MSG_ANNOUNCE_YELLOW", L("STR_HELPER_ALERT2"))
			end
		end
	else
		return AH_Helper.UpdateItemPriceInfoOrg(hList,szDataType)
	end
end

function AuctionPanel.ApplyLookup(frame, szType, nSortType, szKey, nStart, bDesc, szSellerName)
    tItemDataInfo[szType].nStart = nStart
    if szType == "Search" and nStart == 1 then
       AH_Helper.nVersion = GetCurrentTime()
    end
	if szSellerSearch ~= "" then
		szSellerName = szSellerSearch
	end
    return AH_Helper.ApplyLookupOrg(frame, szType, nSortType, szKey, nStart, bDesc, szSellerName)
end

--[[function AuctionPanel.AuctionBuy(hItem, szDataType)
	if not AH_Helper.bGuard then
		return AH_Helper.AuctionBuyOrg(hItem, szDataType)
	end
	local szKey = (hItem.nGenre == ITEM_GENRE.BOOK) and hItem.szItemName or hItem.nUiId
	local lowestBuyPrice = MoneyOptMult(AH_Helper.tItemPrice[szKey][1], hItem.nCount)
	local cmpPrice = MoneyOptMult(lowestBuyPrice, AH_Helper.nMultiple)
	if MoneyOptCmp(hItem.tBuyPrice, cmpPrice) == 1 then
		local fun = function()
			if hItem:IsValid() then
				FireEvent("BUY_AUCTION_ITEM")
				local AuctionClient = GetAuctionClient()
				local tBuyPrice = hItem.tBuyPrice
				AuctionClient.Bid(AuctionPanel.dwTargetID, hItem.nSaleID, hItem.nItemID, hItem.nCRC, tBuyPrice.nGold, tBuyPrice.nSilver, tBuyPrice.nCopper)
				PlaySound(SOUND.UI_SOUND, g_sound.Trade)
				AH_Helper.UpdateList()
			end
		end
		local szContent = FormatString(L("STR_HELPER_GUARDTIP"), hItem.szItemName, AH_Helper.nMultiple)
		--local szContent = "<text>text="..EncodeComponentsString(L("STR_HELPER_GUARDTIP")).." font=159 </text>"
		return AuctionPanel.ShowNotice(szContent, true, fun, true, true)

	else
		return AH_Helper.AuctionBuyOrg(hItem, szDataType)
	end
end]]

--修复搜索卖家后寄卖页无物品显示的问题
function AuctionPanel.OnCheckBoxCheck()
	szSellerSearch = ""
	return AH_Helper.OnCheckBoxCheckOrg()
end

-- 修复搜索页没有激活不能搜索的问题
function AuctionPanel.SetItemName(...)
	local hPageSet = Station.Lookup("Normal/AuctionPanel/PageSet_Totle")
	if hPageSet:GetActivePage():GetName() ~= "Page_Business" then
		hPageSet:ActivePage("Page_Business")
	end
	return AH_Helper.SetItemNameOrg(...)
end

--[[function AuctionPanel.ShowNotice(szNotice, bSure, fun, bCancel, bText)
	if AH_Helper.bNoAllPrompt then
		fun()
	else
		AH_Helper.ShowNoticeOrg(szNotice, bSure, fun, bCancel, bText)
	end
end]]

function AuctionPanel.OnItemLButtonDBClick()
	local szName = this:GetName()
	if szName == "Handle_ItemList" and AH_Helper.bDBClickFastBuy then
		if MoneyOptCmp(this.tBuyPrice, NO_BID_PRICE) ~= 0 then
			AuctionPanel.AuctionBuy(this, "Search")
		end
	elseif szName == "Handle_AItemList" and AH_Helper.bDBClickFastCancel then
		AuctionPanel.AuctionCancel(this)
	else
		return AH_Helper.OnItemLButtonDBClickOrg()
	end
end

function AuctionPanel.OnItemLButtonClick()
	local szName = this:GetName()
	if szName == "Handle_ItemList" then
		AuctionPanel.Selected(this)
		AuctionPanel.UpdateSelectedInfo(this:GetRoot(), "Search", true)
		if AH_Helper.bFastBid and IsShiftKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.AuctionBid(this)
		elseif AH_Helper.bFastBuy and IsAltKeyDown() and IsCtrlKeyDown() then
			if MoneyOptCmp(this.tBuyPrice, NO_BID_PRICE) ~= 0 then
				AuctionPanel.AuctionBuy(this, "Search")
			end
		end
	elseif szName == "Handle_AItemList" then
		AuctionPanel.Selected(this)
		AuctionPanel.UpdateSelectedInfo(this:GetRoot(), "Sell", true)
		if AH_Helper.bFastCancel and IsAltKeyDown() and IsCtrlKeyDown() then
			AuctionPanel.AuctionCancel(this)
		end
	else
		return AH_Helper.OnItemLButtonClickOrg()
	end
end

function AuctionPanel.OnItemMouseEnter()
	local szName = this:GetName()
	if szName == "Box_Box" then
		if not this:IsEmpty() then
			if _G["AH_Tip_Loaded"] then
				AH_Tip.szItemTip = AH_Helper.GetItemTip(this)
			end
			local x, y = this:GetAbsPos()
			local w, h = this:GetSize()
			OutputItemTip(UI_OBJECT_ITEM_ONLY_ID, this.nItemID, nil, nil, {x, y, w, h})
		end
	elseif szName == "Handle_ItemList" then
		this.bOver = true
		AuctionPanel.UpdateBgStatus(this)
	elseif szName == "Handle_AItemList" then
		this.bOver = true
		AuctionPanel.UpdateBgStatus(this)
	else
		return AH_Helper.OnItemMouseEnterOrg()
	end
end

function AuctionPanel.OnItemMouseLeave()
	local szName = this:GetName()
	if szName == "Box_Box" then
		HideTip()
		if _G["AH_Tip_Loaded"] then
			AH_Tip.szItemTip = nil
		end
	else
		return AH_Helper.OnItemMouseLeaveOrg()
	end
end

function AuctionPanel.OnItemRButtonClick()
	local szName = this:GetName()
	if szName == "Box_Item" then
		if not this:IsEmpty() then
			RemoveUILockItem("Auction")
			AuctionPanel.ClearBox(this)
			AuctionPanel.UpdateSaleInfo(this:GetRoot(), true)
		end
	elseif szName == "Handle_ItemList" then
		AuctionPanel.Selected(this)
		local hItem = this
		local menu = {
			{szOption = L("STR_HELPER_SETSELLPRICE"), fnAction = function() AH_Helper.SetTempSellPrice(hItem) end,},
			{bDevide = true},
			{szOption = L("STR_HELPER_SEARCHALL"), fnAction = function() --[[bAutoSearch = false]] AH_Helper.UpdateList(hItem.szItemName) end,},
			{bDevide = true},
			{szOption = L("STR_HELPER_SEARCHSELLER", hItem.szSellerName), fnAction = function() AH_Helper.UpdateList(nil, nil, false, hItem.szSellerName) end,},
			{szOption = L("STR_HELPER_CONTACTSELLER", hItem.szSellerName), fnAction = function() EditBox_TalkToSomebody(hItem.szSellerName) end,},
			{szOption = L("STR_HELPER_ADDSELLER", hItem.szSellerName), fnAction = function() AH_Helper.AddSeller(hItem.szSellerName) end,},
			{szOption = L("STR_HELPER_SHIELDEDSELLER", hItem.szSellerName), fnAction = function() AH_Helper.AddBlackList(hItem.szSellerName) AH_Helper.UpdateList() end,},
			{bDevide = true},
			{szOption = L("STR_HELPER_ADDTOFAVORITES"), fnAction = function() AH_Helper.AddFavorite(hItem.szItemName) end,},
		}
		local m = AH_Helper.GetPrediction(this)
		if m then
			table.insert(menu, m)
		end
		PopupMenu(menu)
	end
end

function AuctionPanel.ExchangeBagAndAuctionItem(boxBag)
	if not boxBag then
		return
	end

	if AuctionPanel.IsOpened() then
		local frame = Station.Lookup("Normal/AuctionPanel")
		local hPageSet = frame:Lookup("PageSet_Totle")
		local page  = frame:Lookup("PageSet_Totle/Page_Auction")
		local hWnd  = page:Lookup("Wnd_Sale")
		local box = hWnd:Lookup("", "Box_Item")
		if hPageSet:GetActivePage():GetName() ~= "Page_Auction" then
			RemoveUILockItem("Auction")
			AuctionPanel.ClearBox(box)
			AuctionPanel.UpdateSaleInfo(frame, true)
			hPageSet:ActivePage("Page_Auction")
		end
		if page and page:IsVisible() and hWnd and hWnd:IsVisible() then
			AuctionPanel.OnExchangeBoxItem(box, boxBag)
		end
	end
end

function AuctionPanel.Init(frame)
	AH_Helper.InitOrg(frame)
	--默认单价
	local hWndRes = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2")
	local hCheckPervalue = hWndRes:Lookup("CheckBox_PerValue")
	local hCheckPrice = hWndRes:Lookup("CheckBox_Price")
	hCheckPervalue:Check(true)
	AuctionPanel.OnSortStateUpdate(hCheckPrice)
	if hCheckPrice:Lookup("", "Image_PriceNameDown"):IsVisible() then
		AuctionPanel.OnSortStateUpdate(hCheckPrice)
	end
	AH_Helper.AddWidget(frame)
	AH_Helper.SetSellPriceType()
	tTempSellPrice = {}
end

--------------------------------------------------------
-- 插件AH函数
--------------------------------------------------------

--显示即时剩余竞拍时间
function AH_Helper.UpdateAllBidItemTime(frame)
	local tInfo = tItemWidgetInfo["Search"]
	local hList = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2", "Handle_List")
	local nCount = hList:GetItemCount()
	for i = 0, nCount - 1, 1 do
		local hItem = hList:Lookup(i)
		local hTextTime = hItem:Lookup(tInfo.Time)
		if tBidTime[hItem.nSaleID] then
			local nLeftTime = math.max(0, math.ceil((tBidTime[hItem.nSaleID].nTime - GetTickCount()) / 1000))
			local szTime = AuctionPanel.FormatAuctionTime(nLeftTime)
			if nLeftTime <= 120 then
				if nLeftTime > 0 then
					hTextTime:SetText(L("STR_HELPER_SECOND", nLeftTime))
				else
					hTextTime:SetText(L("STR_HELPER_SETTLEMENT"))
				end
				hTextTime:SetFontColor(255, 0, 0)
			else
				hTextTime:SetText(szTime)
			end
		end
	end
end

function AH_Helper.UpdatePriceInfo(hList, szDataType)
	local tInfo = tItemWidgetInfo[szDataType]
	local bUnitPrice = AH_Helper.CheckUnitPrice(hList)
	local nCount = hList:GetItemCount()
	local player = GetClientPlayer()

	for i = 0, nCount - 1, 1 do
		local hItem = hList:Lookup(i)
		local tBidPrice = hItem.tBidPrice
		local tBuyPrice = hItem.tBuyPrice

		local hTextBid = hItem:Lookup(tInfo.aBidText[2])
		if bUnitPrice then
			tBidPrice = MoneyOptDiv(hItem.tBidPrice, hItem.nCount)
			tBuyPrice = MoneyOptDiv(hItem.tBuyPrice, hItem.nCount)

			if szDataType == "Search" then
				if hItem.szBidderName == "" then
					hTextBid:SetText(L("STR_HELPER_UNITPRICE"))
				elseif player.szName == hItem.szBidderName then
					hTextBid:SetText(L("STR_HELPER_MYPRICE"))
					hTextBid:SetFontColor(255, 255, 0)
				else
					if AH_Helper.bBidderName then
						hTextBid:SetText(hItem.szBidderName)	--显示竞拍者
						hTextBid:SetFontColor(unpack(AH_Helper.tBidderNameColor))
					end
				end
			elseif szDataType == "Bid" then
				hTextBid:SetText(L("STR_HELPER_MYPRICE"))
			elseif szDataType == "Sell" then
				hTextBid:SetText(L("STR_HELPER_UNITPRICE"))
			end

			if MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) ~= 0 then
				hItem:Lookup(tInfo.aBuyText[2]):SetText("")
			end
		else
			if szDataType == "Search" then
				if hItem.szBidderName == "" then
					hTextBid:SetText("")
				elseif player.szName == hItem.szBidderName then
					hTextBid:SetText(L("STR_HELPER_MYPRICE"))
				else
					if AH_Helper.bBidderName then
						hTextBid:SetText(hItem.szBidderName)
						hTextBid:SetFontColor(unpack(AH_Helper.tBidderNameColor))
					end
				end
			elseif szDataType == "Bid" then
				hTextBid:SetText(L("STR_HELPER_MYPRICE"))
			elseif szDataType == "Sell" then
				hTextBid:SetText("")
			end

			if MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) ~= 0 then
				hItem:Lookup(tInfo.aBuyText[2]):SetText("")
			end
		end

		--[[local nGold, nSliver, nCopper = UnpackMoney(tBidPrice)
		hItem:Lookup(tInfo.aBidText[1]):SetText(nGold)
		hItem:Lookup(tInfo.aBidText[2]):SetText(nSliver)
		hItem:Lookup(tInfo.aBidText[3]):SetText(nCopper)

		if MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) ~= 0 then
			nGold, nSliver, nCopper = UnpackMoney(tBuyPrice)
			hItem:Lookup(tInfo.aBuyText[1]):SetText(nGold)
			hItem:Lookup(tInfo.aBuyText[2]):SetText(nSliver)
			hItem:Lookup(tInfo.aBuyText[3]):SetText(nCopper)
		end]]
		local smoney = AH_Helper.bExVersion and GetMoneyTextEx(tBidPrice, "font=212") or GetMoneyText(tBidPrice, "font=212", "all3", nil, 18)
		local hMoney = hItem:Lookup(tInfo.aBidText[1])
		hMoney:Clear()
		hMoney:AppendItemFromString(smoney)
		hMoney:FormatAllItemPos()

		if MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) ~= 0 then
			smoney = AH_Helper.bExVersion and GetMoneyTextEx(tBuyPrice, "font=212") or GetMoneyText(tBuyPrice, "font=212", "all3", nil, 18)
			hMoney = hItem:Lookup(tInfo.aBuyText[1])
			hMoney:Clear()
			hMoney:AppendItemFromString(smoney)
			hMoney:FormatAllItemPos()
		end
	end
end

--添加按钮
function AH_Helper.AddWidget(frame)
	if not frame then return end
	local page  = frame:Lookup("PageSet_Totle/Page_Business")
	local hWndSrch = page:Lookup("Wnd_Search")
	local temp = Wnd.OpenWindow("Interface\\AH\\AH_Base\\AH_Widget.ini")
	if not hWndSrch:Lookup("Btn_History") then
		local hBtnHistory = temp:Lookup("Btn_History")
		if hBtnHistory then
			local hEdit = AH_Helper.GetSearchEdit(frame)
			hEdit:SetSize(125, 20)
			hBtnHistory:ChangeRelation(hWndSrch, true, true)
			hBtnHistory:SetRelPos(148, 32)
			hBtnHistory.OnLButtonClick = function()
				local xT, yT = hEdit:GetAbsPos()
				local wT, hT = hEdit:GetSize()
				local menu = AH_Helper.GetHistory()
				menu.nMiniWidth = wT + 32
				menu.x = xT - 5
				menu.y = yT + hT
				PopupMenu(menu)
			end
			hBtnHistory.OnRButtonClick = function()
				local menu = {}
				for k, v in pairs(AH_Helper.tItemFavorite) do
					table.insert(menu,
					{
						szOption = k,
						fnAction = function()
							--bAutoSearch = false
							AH_Helper.UpdateList(k, L("STR_HELPER_FAVORITEITEMS"))
						end,
					})
				end
				PopupMenu(menu)
			end
		end
	end

	if not frame:Lookup("Btn_Setting") then
		local nEggIndex = 0
		local btnSetting = temp:Lookup("Btn_Setting")
		if btnSetting then
			btnSetting:ChangeRelation(frame, true, true)
			btnSetting:SetRelPos(853, 56)
			btnSetting:Lookup("", ""):Lookup("Text_Setting"):SetText(L("STR_HELPER_SETTING"))
			btnSetting.OnLButtonClick = function()
				AH.TogglePanel()
			end
			btnSetting.OnRButtonClick = function()
				if IsCtrlKeyDown() then
					nEggIndex = nEggIndex + 1
					if nEggIndex == 10 then
						AH_Helper.bExVersion = not AH_Helper.bExVersion
						AH_Helper.UpdateList()
						nEggIndex = 0
					end
				end
			end
		end
	end

	if not frame:Lookup("Wnd_Side") then
		local hWndSide = temp:Lookup("Wnd_Side")
		if hWndSide then
			hWndSide:ChangeRelation(frame, true, true)
			hWndSide:SetRelPos(960, 8)

			local hBtnPrice = hWndSide:Lookup("Btn_Price")
			hBtnPrice:Lookup("", ""):Lookup("Text_Price"):SetText(L("STR_HELPER_TEXTPRICE"))
			hBtnPrice.OnLButtonClick = function()
				local menu =
				{
					{szOption = L("STR_HELPER_USELOWEST"), bMCheck = true, bChecked = (AH_Helper.szDefaultValue == "Btn_Min"), fnAction = function() AH_Helper.szDefaultValue = "Btn_Min" AH_Helper.SetSellPriceType() end,},
					{szOption = L("STR_HELPER_USESYSTEM"), bMCheck = true, bChecked = (AH_Helper.szDefaultValue == "Btn_Save"), fnAction = function() AH_Helper.szDefaultValue = "Btn_Save" AH_Helper.SetSellPriceType() end,},
				}
				PopupMenu(menu)
			end

			local hBtnFavorite = hWndSide:Lookup("Btn_Favorite")
			hBtnFavorite:Lookup("", ""):Lookup("Text_Favorite"):SetText(L("STR_HELPER_TEXTFAVORITE"))
			hBtnFavorite.OnLButtonClick = function()
				local menu = {}
				local m_1 = {szOption = L("STR_HELPER_FAVORITES")}
				for k, v in pairs(AH_Helper.tItemFavorite) do
					table.insert(m_1,
					{
						szOption = k,
						{szOption = L("STR_HELPER_SEARCH"), fnAction = function() --[[bAutoSearch = false]] AH_Helper.UpdateList(k, L("STR_HELPER_FAVORITEITEMS")) end,},
						{szOption = L("STR_HELPER_DELETE"), fnAction = function() local szText = L("STR_HELPER_DELETEITEMS", k) AH_Library.Message(szText) AH_Helper.tItemFavorite[k] = nil end,},
					})
					table.insert(m_1, m_1_1)
				end
				local m_2 = {szOption = L("STR_HELPER_SELLERS")}
				for k, v in pairs(AH_Helper.tSellerList) do
					table.insert(m_2,
					{
						szOption = k,
						{szOption = L("STR_HELPER_SEARCH"), fnAction = function() AH_Helper.UpdateList(nil, nil, false, k) end,},
						{szOption = L("STR_HELPER_DELETE"), fnAction = function() local szText = L("STR_HELPER_DELETESELLERS", k) AH_Library.Message(szText) AH_Helper.tSellerList[k] = nil end,},
					})
				end
				local m_3 = {szOption = L("STR_HELPER_BLACKLIST")}
				for k, v in pairs(AH_Helper.tBlackList) do
					table.insert(m_3,
					{
						szOption = k,
						{szOption = L("STR_HELPER_DELETE"), fnAction = function() local szText = L("STR_HELPER_DELETESELLERS", k) AH_Library.Message(szText) AH_Helper.tBlackList[k] = nil AH_Helper.UpdateList() end,},
					})
				end
				table.insert(menu, m_1)
				table.insert(menu, m_2)
				table.insert(menu, {bDevide = true})
				table.insert(menu, m_3)
				PopupMenu(menu)
			end

			local hBtnSplit = hWndSide:Lookup("Btn_Split")
			hBtnSplit:Lookup("", ""):Lookup("Text_Split"):SetText(L("STR_HELPER_TEXTSPLIT"))
			hBtnSplit:Enable(_G["AH_Spliter_Loaded"] or false)
			hBtnSplit.OnLButtonClick = function()
				local x, y = this:GetAbsPos()
				local w, h = this:GetSize()
				if _G["AH_Spliter_Loaded"] then
					AH_Spliter.OnSplitBoxItem({x, y, w, h})
				end
			end
			hBtnSplit.OnRButtonClick = function()
				if _G["AH_Spliter_Loaded"] then
					AH_Spliter.StackItem()
				end
			end

			local hBtnRetrieval = hWndSide:Lookup("Btn_Retrieval")
			hBtnRetrieval:Enable(_G["AH_Retrieval_Loaded"] or false)
			hBtnRetrieval:Lookup("", ""):Lookup("Text_Retrieval"):SetText(L("STR_HELPER_TEXTRETRIEVAL"))
			hBtnRetrieval.OnLButtonClick = function()
				if _G["AH_Retrieval_Loaded"] then
					AH_Retrieval.OpenPanel()
				end
			end

			local hBtnOption = hWndSide:Lookup("Btn_Option")
			hBtnOption:Lookup("", ""):Lookup("Text_Option"):SetText(L("STR_HELPER_TEXTOPTION"))
			hBtnOption.OnLButtonClick = function()
				local menu =
				{
					{szOption = L("STR_HELPER_VERSION", AH_Helper.szVersion), fnDisable = function() return true end},
					{ bDevide = true },
					{szOption = L("STR_HELPER_FILTERRECIPE"), bCheck = true, bChecked = AH_Helper.bFilterRecipe, fnAction = function() AH_Helper.bFilterRecipe = not AH_Helper.bFilterRecipe end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_FILTERRECIPETIPS")) end,},
					{szOption = L("STR_HELPER_FILTERBOOK"), bCheck = true,bChecked = AH_Helper.bFilterBook,fnAction = function()AH_Helper.bFilterBook = not AH_Helper.bFilterBook end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_FILTERBOOKTIPS")) end,},
					{ bDevide = true },
					{szOption = L("STR_HELPER_MAXHISTORY"), fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_MAXHISTORYTIPS")) end,
						{szOption = "5", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 5), fnAction = function() AH_Helper.nMaxHistory = 5 end,},
						{szOption = "10", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 10), fnAction = function() AH_Helper.nMaxHistory = 10 end,},
						{szOption = "15", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 15), fnAction = function() AH_Helper.nMaxHistory = 15 end,},
						{szOption = "20", bMCheck = true, bChecked = (AH_Helper.nMaxHistory == 20), fnAction = function() AH_Helper.nMaxHistory = 20 end,},
					},
					{ bDevide = true },
					{szOption = L("STR_HELPER_SELLTIME"), fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_SELLTIMETIPS")) end,
						{szOption = L("STR_HELPER_12HOUR"), bMCheck = true, bChecked = (AH_Helper.szDefaultTime == L("STR_HELPER_12HOUR")), fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_12HOUR") end,},
						{szOption = L("STR_HELPER_24HOUR"), bMCheck = true, bChecked = (AH_Helper.szDefaultTime == L("STR_HELPER_24HOUR")), fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_24HOUR") end,},
						{szOption = L("STR_HELPER_48HOUR"), bMCheck = true, bChecked = (AH_Helper.szDefaultTime == L("STR_HELPER_48HOUR")), fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_48HOUR") end,},
					},
					{szOption = L("STR_HELPER_AUTOMATICSPREAD"), bCheck = true, bChecked = AH_Helper.bLowestPrices, fnAction = function() AH_Helper.bLowestPrices = not AH_Helper.bLowestPrices end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_AUTOMATICSPREADTIPS")) end,
						{szOption = L("STR_HELPER_DISCOUNT"), bCheck = true, bChecked = AH_Helper.bPricePercentage, fnDisable = function() return not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.bPricePercentage = not AH_Helper.bPricePercentage end,
							{szOption = L("STR_HELPER_MODIFY", AH_Helper.nPricePercentage), fnDisable = function() return not AH_Helper.bPricePercentage end, fnAction = function()
									GetUserInput(L("STR_HELPER_INPUTDISCOUNT"), function(szText)
										local n = tonumber(szText)
										if n > 0 then
											AH_Helper.nPricePercentage = n
										end
									end, nil, nil, nil, nil, nil)
								end,
							}
						},
						{ bDevide = true },
						{szOption = L("STR_HELPER_COPPER"), bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 1), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 1 end,},
						{szOption = L("STR_HELPER_SLIVER"), bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 1 * 100), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 1 * 100 end,},
						{szOption = L("STR_HELPER_GOLD"), bMCheck = true, bChecked = (AH_Helper.nDefaultPrices == 100 * 100), fnDisable = function() return AH_Helper.bPricePercentage or not AH_Helper.bLowestPrices end, fnAction = function() AH_Helper.nDefaultPrices = 100 * 100 end,},
						--{ bDevide = true },
						--{szOption = L("STR_HELPER_DBCTRLSELL"), bCheck = true, bChecked = AH_Helper.bDBCtrlSell, fnAction = function() AH_Helper.bDBCtrlSell = not AH_Helper.bDBCtrlSell end,},
					},
					{ bDevide = true },
					--[[{szOption = L("STR_HELPER_NOALLPROMPT"), bCheck = true, bChecked = AH_Helper.bNoAllPrompt, fnAction = function() AH_Helper.bNoAllPrompt = not AH_Helper.bNoAllPrompt end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_NOALLPROMPTTIPS")) end,
						{szOption = L("STR_HELPER_NOSELLNOTICE"), bCheck = true, bChecked = AH_Helper.bSellNotice, fnAction = function() AH_Helper.bSellNotice = not AH_Helper.bSellNotice end,},
						{szOption = L("STR_HELPER_DBCTRLSELL"), bCheck = true, bChecked = AH_Helper.bDBCtrlSell, fnAction = function() AH_Helper.bDBCtrlSell = not AH_Helper.bDBCtrlSell end,},
					},
					{ bDevide = true },]]
					{szOption = L("STR_HELPER_FASTSELL"), bCheck = true, bChecked = AH_Helper.bDBCtrlSell, fnAction = function() AH_Helper.bDBCtrlSell = not AH_Helper.bDBCtrlSell end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_DBCTRLSELL")) end,},
					{szOption = L("STR_HELPER_FASTBID"), bCheck = true, bChecked = AH_Helper.bFastBid, fnAction = function() AH_Helper.bFastBid = not AH_Helper.bFastBid end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_FASTBIDTIPS")) end,},
					{szOption = L("STR_HELPER_FASTBUY"), bCheck = true, bChecked = AH_Helper.bFastBuy, fnAction = function() AH_Helper.bFastBuy = not AH_Helper.bFastBuy end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_FASTBUYTIPS")) end,
						{szOption = L("STR_HELPER_DBCLICKTYPE"), bCheck = true, bChecked = AH_Helper.bDBClickFastBuy, fnAction = function() AH_Helper.bDBClickFastBuy = not AH_Helper.bDBClickFastBuy end,},
					},
					{szOption = L("STR_HELPER_FASTCANCEL"), bCheck = true, bChecked = AH_Helper.bFastCancel, fnAction = function() AH_Helper.bFastCancel = not AH_Helper.bFastCancel end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_FASTCANCELTIPS")) end,
						{szOption = L("STR_HELPER_DBCLICKTYPE"), bCheck = true, bChecked = AH_Helper.bDBClickFastCancel, fnAction = function() AH_Helper.bDBClickFastCancel = not AH_Helper.bDBClickFastCancel end,},
					},
					{ bDevide = true },
					{szOption = L("STR_HELPER_AUTOSEARCH"), bCheck = true, bChecked = AH_Helper.bAutoSearch, fnAction = function() AH_Helper.bAutoSearch = not AH_Helper.bAutoSearch end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_AUTOSEARCHTIPS")) end,},
					--{szOption = L("STR_HELPER_FORMATMONEY"), bCheck = true, bChecked = AH_Helper.bFormatMoney, fnAction = function() AH_Helper.bFormatMoney = not AH_Helper.bFormatMoney end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_FORMATMONEYTIPS")) end,},
					--{szOption = L("STR_HELPER_GUARD"), bCheck = true, bChecked = AH_Helper.bGuard, fnAction = function() AH_Helper.bGuard = not AH_Helper.bGuard end,},
					{szOption = L("STR_HELPER_SHOWTIPEX"), bCheck = true, bChecked = _G["AH_Tip_Loaded"] and AH_Tip.bShowTipEx or false, fnAction = function() if _G["AH_Tip_Loaded"] then AH_Tip.bShowTipEx = not AH_Tip.bShowTipEx end end, fnDisable = function() return not _G["AH_Tip_Loaded"] end, fnMouseEnter = function() AH_Library.OutputTip(L("STR_HELPER_SHOWTIPEXTIPS")) end,},
					--{szOption = L("STR_HELPER_EXVERSIONPRICE"), bCheck = true, bChecked = AH_Helper.bExVersion, fnAction = function() AH_Helper.bExVersion = not AH_Helper.bExVersion AH_Helper.UpdateList() end,},
					{ bDevide = true },
					{szOption = L("STR_HELPER_RESETPRICE"), fnAction = function() AH_Helper.tItemPrice = {} AH_Library.Message(L("STR_HELPER_RESETPRICETIPS")) end,},
				}
				PopupMenu(menu)
			end
		end
	end
	Wnd.CloseWindow(temp)

	local nW, nH = frame:GetSize()
	if nW < 1018 then
		frame:SetSize(nW + 56, nH)
	end
end

function AH_Helper.GetPrediction(hItem)
	local item = GetItem(hItem.nItemID)
	local tItemInfo = GetItemInfo(item.dwTabType, item.dwIndex)
	local tDesc = Table_GetItemDesc(item.nUiId)
	if string.find(tDesc, L("STR_HELPER_ADDITIONALDROP")) then
		local m = {szOption = L("STR_HELPER_VIEWDROP")}
		local drops = string.gsub(tDesc,  "this\.dwTabType\=(%d+) this.dwIndex=(%d+) ", function(k, v)
			local itm = GetItemInfo(k, v)
			table.insert(m, {
				szOption = itm.szName,
				fnMouseEnter = function()
					local x, y = this:GetAbsPos()
					local w, h = this:GetSize()
					OutputItemTip(UI_OBJECT_ITEM_INFO, 0, k, v, {x, y, w, h}, false)
				end,
			})
		end)
		return m
	end
	return nil
end

function AH_Helper.SetSellPriceType()
	local hWndSide = Station.Lookup("Normal/AuctionPanel"):Lookup("Wnd_Side")
	local hText = hWndSide:Lookup("Btn_Price"):Lookup("", ""):Lookup("Text_Price")
	if AH_Helper.szDefaultValue == "Btn_Min" then
        hText:SetText(L("STR_HELPER_LOWEST"))
    elseif AH_Helper.szDefaultValue == "Btn_Save" then
        hText:SetText(L("STR_HELPER_SYSTEM"))
    end
end

function AH_Helper.AuctionAutoSell(frame)
	local hWndSale  = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale")
	local handle    = hWndSale:Lookup("", "")
	local box       = handle:Lookup("Box_Item")
	local text      = handle:Lookup("Text_Time")
	local szTime    = text:GetText()
	local nTime     = tonumber(string.sub(szTime, 1, 2))
	local tBidPrice = nil
	local tBuyPrice = nil
	local player    = GetClientPlayer()

	local item = GetPlayerItem(player, box.dwBox, box.dwX);
	if not item or item.szName ~= box.szName then
		AuctionPanel.ClearBox(box)
		AuctionPanel.UpdateSaleInfo(frame, true)
		RemoveUILockItem("Auction")
		OutputMessage("MSG_ANNOUNCE_RED", L("STR_HELPER_SELLERROR"))
		return
	end
	
	if IsBagInSort() then -- 背包整理中禁止交易
		AuctionPanel.ClearBox(box)
		AuctionPanel.UpdateSaleInfo(frame, true)
		RemoveUILockItem("Auction")
		OutputMessage("MSG_ANNOUNCE_RED", L("STR_HELPER_BAGINSORT"))
		return
	end
	--[[local nGold   = FormatMoney(hWndSale:Lookup("Edit_OPGold"))
	local nSliver = FormatMoney(hWndSale:Lookup("Edit_OPSilver"))
	local nCopper = FormatMoney(hWndSale:Lookup("Edit_OPCopper"))
	tBidPrice = PackMoney(nGold, nSliver, nCopper)

	nGold   = FormatMoney(hWndSale:Lookup("Edit_PGold"))
	nSliver = FormatMoney(hWndSale:Lookup("Edit_PSilver"))
	nCopper = FormatMoney(hWndSale:Lookup("Edit_PCopper"))
	tBuyPrice = PackMoney(nGold, nSliver, nCopper)]]

	tBidPrice = ConvertMoney(hWndSale:Lookup("Edit_OPGoldB"), hWndSale:Lookup("Edit_OPGold"), hWndSale:Lookup("Edit_OPSilver"))
	tBuyPrice = ConvertMoney(hWndSale:Lookup("Edit_PGoldB"), hWndSale:Lookup("Edit_PGold"), hWndSale:Lookup("Edit_PSilver"))

	box.szTime = szTime
	box.tBidPrice = tBidPrice
	box.tBuyPrice = tBuyPrice

	--local nStackNum = item.nStackNum
	local nStackNum = item.bCanStack and item.nStackNum or 1
	local tSBidPrice = MoneyOptDiv(tBidPrice, nStackNum)
	local tSBuyPrice = MoneyOptDiv(tBuyPrice, nStackNum)
	local AtClient = GetAuctionClient()
	FireEvent("SELL_AUCTION_ITEM")

	for i = 1, 6 do
		if player.GetBoxSize(i) > 0 then
			for j = 0, player.GetBoxSize(i) - 1 do
				local item2 = player.GetItem(i, j)
				if item2 and GetItemNameByItem(item2) == GetItemNameByItem(item) then
					local nStackNum2 = item2.bCanStack and item2.nStackNum or 1
					if nStackNum2 <= nStackNum then
						local tBidPrice2 = MoneyOptMult(tSBidPrice, nStackNum2)
						local tBuyPrice2 = MoneyOptMult(tSBuyPrice, nStackNum2)
						AtClient.Sell(AuctionPanel.dwTargetID, i, j, tBidPrice2.nGold, tBidPrice2.nSilver, tBidPrice2.nCopper, tBuyPrice2.nGold, tBuyPrice2.nSilver, tBuyPrice2.nCopper, nTime)
					end
				end
			end
		end
	end
	PlaySound(SOUND.UI_SOUND, g_sound.Trade)
end

local function IsSameSellItem(item1, item2)
	if not item2 or not item2.bCanTrade then
		return false
	end
	if item1.nGenre ~= item2.nGenre and item1.nQuality ~= item2.nQuality then
		return false
	end
	if item1.nGenre == ITEM_GENRE.BOOK and item1.szName == item2.szName then
		return true
	elseif item1.nGenre == ITEM_GENRE.MATERIAL and item1.nSub == 5 and item1.nSub == item2.nSub then
		return true
	elseif item1.nGenre == ITEM_GENRE.COLOR_DIAMOND then
		local nStack1, nStack2 = item1.bCanStack and item1.nStackNum or 1, item2.bCanStack and item2.nStackNum or 1
		if nStack1 == nStack2 then
			local szName1, szName2 = GetItemNameByItem(item1), GetItemNameByItem(item2)
			if string.sub(szName1, -3, -2) == string.sub(szName2, -3, -2) then
				return true
			end
		end
	end
	return false
end

function AH_Helper.AuctionSimilarAutoSell(frame)
	local hWndSale  = frame:Lookup("PageSet_Totle/Page_Auction/Wnd_Sale")
	local handle    = hWndSale:Lookup("", "")
	local box       = handle:Lookup("Box_Item")
	local text      = handle:Lookup("Text_Time")
	local szTime    = text:GetText()
	local nTime     = tonumber(string.sub(szTime, 1, 2))
	local tBidPrice = nil
	local tBuyPrice = nil
	local player    = GetClientPlayer()

	local item = GetPlayerItem(player, box.dwBox, box.dwX);
	if not item or item.szName ~= box.szName then
		AuctionPanel.ClearBox(box)
		AuctionPanel.UpdateSaleInfo(frame, true)
		RemoveUILockItem("Auction")
		OutputMessage("MSG_ANNOUNCE_RED", L("STR_HELPER_SELLERROR"))
		return
	end
	
	if IsBagInSort() then -- 背包整理中禁止交易
		AuctionPanel.ClearBox(box)
		AuctionPanel.UpdateSaleInfo(frame, true)
		RemoveUILockItem("Auction")
		OutputMessage("MSG_ANNOUNCE_RED", L("STR_HELPER_BAGINSORT"))
		return
	end
	--[[local nGold   = FormatMoney(hWndSale:Lookup("Edit_OPGold"))
	local nSliver = FormatMoney(hWndSale:Lookup("Edit_OPSilver"))
	local nCopper = FormatMoney(hWndSale:Lookup("Edit_OPCopper"))
	tBidPrice = PackMoney(nGold, nSliver, nCopper)

	nGold   = FormatMoney(hWndSale:Lookup("Edit_PGold"))
	nSliver = FormatMoney(hWndSale:Lookup("Edit_PSilver"))
	nCopper = FormatMoney(hWndSale:Lookup("Edit_PCopper"))
	tBuyPrice = PackMoney(nGold, nSliver, nCopper)]]

	tBidPrice = ConvertMoney(hWndSale:Lookup("Edit_OPGoldB"), hWndSale:Lookup("Edit_OPGold"), hWndSale:Lookup("Edit_OPSilver"))
	tBuyPrice = ConvertMoney(hWndSale:Lookup("Edit_PGoldB"), hWndSale:Lookup("Edit_PGold"), hWndSale:Lookup("Edit_PSilver"))

	box.szTime = szTime
	box.tBidPrice = tBidPrice
	box.tBuyPrice = tBuyPrice

	local nStackNum = item.bCanStack and item.nStackNum or 1	--修复不可叠加类物品定价错误
	local tSBidPrice = MoneyOptDiv(tBidPrice, nStackNum)
	local tSBuyPrice = MoneyOptDiv(tBuyPrice, nStackNum)
	local AtClient = GetAuctionClient()
	FireEvent("SELL_AUCTION_ITEM")

	for i = 1, 6 do
		if player.GetBoxSize(i) > 0 then
			for j = 0, player.GetBoxSize(i) - 1 do
				local item2 = player.GetItem(i, j)
				if IsSameSellItem(item, item2) then
					local nStack = item2.bCanStack and item2.nStackNum or 1
					local tBidPrice2 = MoneyOptMult(tSBidPrice, nStack)
					local tBuyPrice2 = MoneyOptMult(tSBuyPrice, nStack)
					AtClient.Sell(AuctionPanel.dwTargetID, i, j, tBidPrice2.nGold, tBidPrice2.nSilver, tBidPrice2.nCopper, tBuyPrice2.nGold, tBuyPrice2.nSilver, tBuyPrice2.nCopper, nTime)
				end
			end
		end
	end
	PlaySound(SOUND.UI_SOUND, g_sound.Trade)
end

function AH_Helper.UpdateList(szItemName, szType, bNotInit, szSellerName)
	if not szItemName then
		szItemName = ""
	end
	szSellerSearch = szSellerName or ""
	local t = tItemDataInfo["Search"]
	local frame = Station.Lookup("Normal/AuctionPanel")
	AuctionPanel.tSearch = tSearchInfoDefault
	AuctionPanel.tSearch["Name"] = szItemName
	if szSellerName and szSellerName ~= "" then
		AuctionPanel.tSearch["Name"] = L("STR_HELPER_ITEMNAME")
		--AuctionPanel.tSearch["szSellerName"] = szSellerName
	end
	if not bNotInit then
		AuctionPanel.InitSearchInfo(frame, AuctionPanel.tSearch)
	end
	AuctionPanel.SaveSearchInfo(frame)

	if szType and szType ~= "" then
		local szText = L("STR_HELPER_SEARCHITEM", szType, szItemName)
		AH_Library.Message(szText)
	end

	return AuctionPanel.ApplyLookup(frame, "Search", t.nSortType, "", 1, t.bDesc, szSellerName)
end

function AH_Helper.CheckUnitPrice(hList)
	local frame = hList:GetRoot()
	local hWndRes = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2")
	local hCheckboxPerValue = hWndRes:Lookup("CheckBox_PerValue")
	local bChecked = hCheckboxPerValue:IsCheckBoxChecked()
	if bChecked then
		return true
	end
	return false
end

function AH_Helper.IsInBlackList(szSellerName)
	for k, v in pairs(AH_Helper.tBlackList) do
		if k == szSellerName then
			return true
		end
	end
	return false
end

function AH_Helper.IsInHistory(szKeyName)
	for k, v in pairs(AH_Helper.tItemHistory) do
		if v.szName == szKeyName then
			return true
		end
	end
	return false
end

function AH_Helper.SetTempSellPrice(hItem)
	local szItemName = hItem.szItemName
	local szKey = hItem.szKey
	if MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) == 0 then
		AH_Library.Message(L("STR_HELPER_ALERT3"))
		return
	end

	local tBuyPrice = MoneyOptDiv(hItem.tBuyPrice, hItem.nCount)
	tTempSellPrice[szKey] = tBuyPrice
	local szMoney = GetMoneyText(tBuyPrice, "font=10")
	local szColor = GetItemFontColorByQuality(hItem.nQuality, true)
	local szItem = MakeItemInfoLink(string.format("[%s]", szItemName), string.format("font=10 %s", szColor), hItem.nVersion, hItem.dwTabType, hItem.dwIndex)
	AH_Library.Message({szItem, L("STR_HELPER_PRICE4"), szMoney}, "MONEY")
end

function AH_Helper.AddFavorite(szItemName)
    AH_Helper.tItemFavorite[szItemName] = 1
	local szText = L("STR_HELPER_BEADDTOFAVORITES", szItemName)
    AH_Library.Message(szText)
end

function AH_Helper.AddSeller(szSellerName)
    AH_Helper.tSellerList[szSellerName] = 1
    local szText = L("STR_HELPER_BEADDTOSELLER", szSellerName)
	AH_Library.Message(szText)
end

function AH_Helper.AddBlackList(szSellerName)
    AH_Helper.tBlackList[szSellerName] = 1
    local szText = L("STR_HELPER_BEADDTOBLACKLIST", szSellerName)
	AH_Library.Message(szText)
end

function AH_Helper.AddHistory(szKeyName)
	local index = nil
	for k, v in pairs(AH_Helper.tItemHistory) do
		if v.szName == szKeyName then
			index = k
			break
		end
	end
	if index then
		table.remove(AH_Helper.tItemHistory, index)
	end
	table.insert(AH_Helper.tItemHistory, {szName = szKeyName})
	local nCount = table.getn(AH_Helper.tItemHistory)
	if nCount > AH_Helper.nMaxHistory then
		table.remove(AH_Helper.tItemHistory, 1)
	end
end

function AH_Helper.GetItemTip(hItem)
	local player, szTip = GetClientPlayer(), ""
	local item = GetItem(hItem.nItemID)
	if item then
		local nItemCountInPackage = player.GetItemAmount(item.dwTabType, item.dwIndex)
		local nItemCountTotal = player.GetItemAmountInAllPackages(item.dwTabType, item.dwIndex)
		local nItemCountInBank = nItemCountTotal - nItemCountInPackage

		szTip = szTip .. GetFormatText(L("STR_TIP_TOTAL"), 101) .. GetFormatText(nItemCountTotal, 162)
		szTip = szTip .. GetFormatText(L("STR_TIP_BAGANDBANK"), 101) .. GetFormatText(nItemCountInPackage, 162) .. GetFormatText("/", 162) .. GetFormatText(nItemCountInBank, 162)

		--配方
		if item.nGenre == ITEM_GENRE.MATERIAL and _G["AH_Tip_Loaded"] then
			szTip = szTip .. AH_Tip.GetRecipeTip(player, item)
		end

		if MoneyOptCmp(hItem.tBuyPrice, 0) == 1 and MoneyOptCmp(hItem.tBuyPrice, NO_BID_PRICE) ~= 0 then
			if AH_Helper.GetCheckPervalue() then
				szTip = szTip .. GetFormatText("\n" .. L("STR_HELPER_PRICE1"), 157) .. GetMoneyTipText(hItem.tBuyPrice, 106)
			else
				szTip = szTip .. GetFormatText("\n" .. L("STR_HELPER_PRICE2"), 157) .. GetMoneyTipText(MoneyOptDiv(hItem.tBuyPrice, hItem.nCount), 106)
			end
		end
	end
	return szTip
end

function AH_Helper.GetHistory()
	local menu = {}
	local nCount = table.getn(AH_Helper.tItemHistory)
	for i = nCount, 1, -1 do
		local m = {
			szOption = AH_Helper.tItemHistory[i].szName,
			fnAction = function()
				--bAutoSearch = false
				AH_Helper.UpdateList(AH_Helper.tItemHistory[i].szName)
			end,
		}
		table.insert(menu, m)
	end
	table.insert(menu, {bDevide = true})
	local d = {
		szOption = L("STR_HELPER_CLEARHISTORY"),
		fnAction = function()
			AH_Helper.tItemHistory = {}
		end,
	}
	table.insert(menu, d)

	return menu
end

function AH_Helper.GetSearchEdit(frame)
	if not frame then
		frame = Station.Lookup("Normal/AuctionPanel")
	end
	local hWndSch = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Search")
	if hWndSch then
		return hWndSch:Lookup("Edit_ItemName")
	end
	return nil
end

function AH_Helper.GetCheckPervalue(frame)
	if not frame then
		frame = Station.Lookup("Normal/AuctionPanel")
	end
	local hWndRes = frame:Lookup("PageSet_Totle/Page_Business/Wnd_Result2")
	if hWndRes then
		return hWndRes:Lookup("CheckBox_PerValue"):IsCheckBoxChecked()
	end
	return nil
end

function AH_Helper.OnBreathe()
	local frame = Station.Lookup("Normal/AuctionPanel")
	if not frame then
		return
	end
	AH_Helper.UpdateAllBidItemTime(frame)
end

local function protect(object)
	local proxy = {}
	local mt = {
		__index = object,
		__newindex = function(t, k, v)
			local function _fn(v)
				return (type(v) == "function") and true or false
			end
			if not _fn(v) then
				object[k] = v
			end
		end
	}
	setmetatable(proxy, mt)
	return proxy
end
AuctionPanel = protect(AuctionPanel)


RegisterEvent("LOGIN_GAME", function()
	if IsFileExist(AH_Helper.szDataPath) then
		AH_Helper.tItemPrice = LoadLUAData(AH_Helper.szDataPath) or {}
		AH_Helper.tCDiamondPrice = LoadLUAData(AH_Helper.szDataPathCDiamond) or {}
	end
end)

RegisterEvent("GAME_EXIT", function()
	SaveLUAData(AH_Helper.szDataPath, AH_Helper.tItemPrice)
	SaveLUAData(AH_Helper.szDataPathCDiamond, AH_Helper.tCDiamondPrice)
end)

RegisterEvent("PLAYER_EXIT_GAME", function()
	SaveLUAData(AH_Helper.szDataPath, AH_Helper.tItemPrice)
	SaveLUAData(AH_Helper.szDataPathCDiamond, AH_Helper.tCDiamondPrice)
end)
