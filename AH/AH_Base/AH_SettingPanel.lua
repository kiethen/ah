AH_SettingPanel = AH_SettingPanel or {}

local L = AH_Library.LoadLangPack()

local _Xml = function(xmlString, ...)
	return string.format(xmlString, ...)
end

function AH_SettingPanel.Init()
	--主窗体
	local frame = Kimochi(_Xml([[<Frame name="AH_SettingPanel" title="%s" />]], L("STR_SETTING_TITLE")))
	frame:point("CENTER", 0, 0, "CENTER", 0, 0)
	
	Kimochi(frame, [[<Image w="36" h="36" x="5" image="ui\\image\\uiCommon\\commonpanel.UITex" frame="9" />]])
	
	--Tab栏背景
	Kimochi(frame, [[<Image w="770" h="33" y="50" image="ui\\image\\uiCommon\\activepopularize2.UITex" frame="46" />]]):setType(11)
	
	local pageSet = Kimochi(frame, [[<PageSet w="768" h="462" y="50" />]])
	
	local feedBack = Kimochi(pageSet, _Xml([[<Button text="%s" x="670" y="4" gold="true" />]], L("STR_SETTING_FEEDBACK")))
	feedBack.click = function()
		OpenInternetExplorer("http://weibo.com/nzgeneral")
	end

	local x = 20
	if _G["AH_Helper_Loaded"] then
		local tabBox = Kimochi(frame, string.format(_Xml([[<TabBox x="%s" w="85" h="30" text="%s" group="class" check="true"/>]], x, L("STR_SETTING_AH"))))
		local window = Kimochi(pageSet, [[<Window w="708" h="432" x="35" y="40" />]])
		pageSet:add(window:this(), tabBox:this())
		tabBox.click = function(_check)
			if _check then
				pageSet:active(0)
			end
		end

		Kimochi(window, _Xml([[<Label text="%s" />]], L("STR_SETTING_COMMON"))):color(255, 255, 0)
		--自动搜索
		local checkbox_AutoSearch = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="30" />]], L("STR_SETTING_AUTOSEARCH"), tostring(AH_Helper.bAutoSearch)))
		checkbox_AutoSearch.click = function(arg)
			AH_Helper.bAutoSearch = arg
		end
		
		--品质等级
		local checkbox_QualityLevel = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" x="180" y="30" />]], L("STR_SETTING_QUALITYLEVEL"), tostring(AH_Helper.bShowQualityLevel)))
		checkbox_QualityLevel.click = function(arg)
			AH_Helper.bShowQualityLevel = arg
		end
		
		--交易卫士
		local checkbox_Guard = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" x="360" y="30" />]], L("STR_SETTING_GUARD"), tostring(AH_Helper.bGuard)))
		Kimochi(window, _Xml([[<Label text="%s" x="492" y="30" w="30" />]], L("STR_SETTING_OVER")))
		local textbox_Multiple = Kimochi(window, _Xml([[<TextBox text="%s" x="525" y="30" w="40" />]], AH_Helper.nMultiple)):enable(AH_Helper.bGuard)
		Kimochi(window, _Xml([[<Label text="%s" x="575" y="30" />]], L("STR_SETTING_INTERCEPT")))
		checkbox_Guard.click = function(arg)
			AH_Helper.bGuard = arg
			textbox_Multiple:enable(arg)
		end
		textbox_Multiple.change = function(arg)
			AH_Helper.nMultiple = tonumber(arg)
		end
		
		--实时竞拍倒计时
		local checkbox_RealTime = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="60"/>]], L("STR_SETTING_REALTIME"), tostring(AH_Helper.bRealTime)))
		checkbox_RealTime.click = function(arg)
			AH_Helper.bRealTime = arg
		end
		
		--倒计时颜色
		local colorbox_RealTime = Kimochi(window, _Xml([[<ColorBox text="%s" x="184" y="60" r="%s" g="%s" b="%s" />]], L("STR_SETTING_TIMECOLOR"), unpack(AH_Helper.tRealTimeColor)))
		colorbox_RealTime.change = function(arg)
			AH_Helper.tRealTimeColor = arg
		end
		
		--显示竞拍者名字
		local checkbox_BidderName = Kimochi(window, _Xml([[<CheckBox text="%s" y="90" check="%s" />]], L("STR_SETTING_BINDERNAME"), tostring(AH_Helper.bBidderName)))
		checkbox_BidderName.click = function(arg)
			AH_Helper.bBidderName = arg
		end
		
		--竞拍者颜色
		local colorbox_BidderName = Kimochi(window, _Xml([[<ColorBox text="%s" x="184" y="90" r="%s" g="%s" b="%s" />]], L("STR_SETTING_BINDERNAMECOLOR"), unpack(AH_Helper.tBidderNameColor)))
		colorbox_BidderName.change = function(arg)
			AH_Helper.tBidderNameColor = arg
		end
		
		--历史记录
		Kimochi(window, _Xml([[<Label text="%s" x="364" y="60" />]], L("STR_SETTING_HISTORY")))
		Kimochi(window, _Xml([[<Label text="%s" x="530" y="60" />]], L("STR_SETTING_COUNT")))
		local combobox_MaxHistory = Kimochi(window, _Xml([[<ComboBox text="%s" w="55" x="470" y="60" />]], AH_Helper.nMaxHistory))
		combobox_MaxHistory.click = function(m)
			table.insert(m,{szOption = "5", fnAction = function() AH_Helper.nMaxHistory = 5 combobox_MaxHistory:text(5) end,})
			table.insert(m,{szOption = "10", fnAction = function() AH_Helper.nMaxHistory = 10 combobox_MaxHistory:text(10) end,})
			table.insert(m,{szOption = "15", fnAction = function() AH_Helper.nMaxHistory = 15 combobox_MaxHistory:text(15) end,})
			table.insert(m,{szOption = "20", fnAction = function() AH_Helper.nMaxHistory = 20 combobox_MaxHistory:text(20) end,})
			PopupMenu(m)
		end
		
		--保管时间
		Kimochi(window, _Xml([[<Label text="%s" x="364" y="90" />]], L("STR_SETTING_SAVETIME")))
		Kimochi(window, _Xml([[<Label text="%s" x="530" y="90" />]], L("STR_SETTING_HOUR")))
		local combobox_SellTime = Kimochi(window, _Xml([[<ComboBox text="%s" w="55" x="470" y="90" />]], AH_Helper.szDefaultTime:match("(%d+)")))
		combobox_SellTime.click = function(m)
			table.insert(m,{szOption = "12", fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_12HOUR") combobox_SellTime:text(12) end,})
			table.insert(m,{szOption = "24", fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_24HOUR") combobox_SellTime:text(24) end,})
			table.insert(m,{szOption = "48", fnAction = function() AH_Helper.szDefaultTime = L("STR_HELPER_48HOUR") combobox_SellTime:text(48) end,})
			PopupMenu(m)
		end
	
		--过滤秘籍
		local checkbox_FilterRecipe = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="120" />]], L("STR_SETTING_FILTERRECIPE"), tostring(AH_Helper.bFilterRecipe)))
		checkbox_FilterRecipe.click = function(arg)
			AH_Helper.bFilterRecipe = arg
		end
		
		--过滤书籍
		local checkbox_FilterBook = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" x="180" y="120" />]], L("STR_SETTING_FILTERBOOK"), tostring(AH_Helper.bFilterBook)))
		checkbox_FilterBook.click = function(arg)
			AH_Helper.bFilterBook = arg
		end
		
		--自动差价
		local checkbox_AutoDiscount = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" x="360" y="120" />]], L("STR_SETTING_AUTODISCOUNT"), tostring(AH_Helper.bLowestPrices)))
		local szText = ""
		if AH_Helper.nDefaultPrices == 1 then
			szText = L("STR_HELPER_COPPER")
		elseif AH_Helper.nDefaultPrices == 1 * 100 then
			szText = L("STR_HELPER_SLIVER")
		elseif AH_Helper.nDefaultPrices == 100 * 100 then
			szText = L("STR_HELPER_GOLD")
		end
		local combobox_Discount = Kimochi(window, _Xml([[<ComboBox text="%s" w="80" x="500" y="120" />]], szText)):enable(AH_Helper.bLowestPrices)
		combobox_Discount.click = function(m)
			table.insert(m,{szOption = L("STR_HELPER_COPPER"), fnAction = function() AH_Helper.nDefaultPrices = 1 combobox_Discount:text(L("STR_HELPER_COPPER")) end,})
			table.insert(m,{szOption = L("STR_HELPER_SLIVER"), fnAction = function() AH_Helper.nDefaultPrices = 1 * 100 combobox_Discount:text(L("STR_HELPER_SLIVER")) end,})
			table.insert(m,{szOption = L("STR_HELPER_GOLD"), fnAction = function() AH_Helper.nDefaultPrices = 100 * 100 combobox_Discount:text(L("STR_HELPER_GOLD")) end,})
			PopupMenu(m)
		end
		checkbox_AutoDiscount.click = function(arg)
			AH_Helper.bLowestPrices = arg
			combobox_Discount:enable(arg)
		end
		
		
		Kimochi(window, _Xml([[<Label text="%s" y="150" />]], L("STR_SETTING_SHORTCUT"))):color(255, 255, 0)
		--快速寄售
		local checkbox_FastSell = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="180" />]], L("STR_SETTING_FASTSELL"), tostring(AH_Helper.bDBCtrlSell)))
		checkbox_FastSell.click = function(arg)
			AH_Helper.bDBCtrlSell = arg
		end
		Kimochi(window, _Xml([[<Label text="%s" x="140" y="180" />]], L("STR_SETTING_FASRSELLTIP"))):color(180, 180, 180)
		
		--快速竞拍
		local checkbox_FastBid = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s"  y="210" />]], L("STR_SETTING_FASTBID"), tostring(AH_Helper.bFastBid)))
		checkbox_FastBid.click = function(arg)
			AH_Helper.bFastBid = arg
		end
		Kimochi(window, _Xml([[<Label text="%s" x="140" y="210" />]], L("STR_SETTING_FASTBIDTIP"))):color(180, 180, 180)
		
		--快速购买
		local checkbox_FastBuy = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s"  y="240" />]], L("STR_SETTING_FASTBUY"), tostring(AH_Helper.bFastBuy)))
		Kimochi(window, _Xml([[<Label text="%s" x="140" y="240" />]], L("STR_SETTING_FASTBUYTIP"))):color(180, 180, 180)
		Kimochi(window, [[<Label text="└" w="30" h="28" x="9" y="270" />]])
		local checkbox_DBClickBuyType = Kimochi(window, _Xml([[<CheckBox text="%s" x="30" check="%s"  y="270" />]], L("STR_SETTING_DBCLICKTYPE"), tostring(AH_Helper.bDBClickFastBuy))):enable(AH_Helper.bFastBuy)
		checkbox_FastBuy.click = function(arg)
			AH_Helper.bFastBuy = arg
			checkbox_DBClickBuyType:enable(arg)
		end
		checkbox_DBClickBuyType.click = function(arg)
			AH_Helper.bDBClickFastBuy = arg
		end
		
		--快速取消
		local checkbox_FastCancel = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="300" />]], L("STR_SETTING_FASTCANCEL"), tostring(AH_Helper.bFastCancel)))
		Kimochi(window, _Xml([[<Label text="%s" x="140" y="300" />]], L("STR_SETTING_FASRCANCELTIP"))):color(180, 180, 180)
		Kimochi(window, [[<Label text="└" w="30" h="28" x="9" y="330" />]])
		local checkbox_DBClickCancelType = Kimochi(window, _Xml([[<CheckBox text="%s" x="30" check="%s"  y="330" />]], L("STR_SETTING_DBCLICKTYPE"), tostring(AH_Helper.bDBClickFastCancel))):enable(AH_Helper.bFastCancel)
		checkbox_FastCancel.click = function(arg)
			AH_Helper.bFastCancel = arg
			checkbox_DBClickCancelType:enable(arg)
		end
		checkbox_DBClickCancelType.click = function(arg)
			AH_Helper.bDBClickFastCancel = arg
		end

		x = x + 85
	end

	if _G["AH_MailBank_Loaded"] or _G["AH_Spliter_Loaded"] or _G["AH_Tip_Loaded"] then
		local tabBox = Kimochi(frame, _Xml([[<TabBox x="%s" w="85" h="30" text="%s" group="class" />]], x, L("STR_SETTING_OTHER")))
		local window = Kimochi(pageSet, [[<Window w="708" h="432" x="35" y="40" />]])
		pageSet:add(window:this(), tabBox:this())
		tabBox.click = function(_check)
			if _check then
				pageSet:active(1)
			end
		end
		
		local y = 0
		if _G["AH_MailBank_Loaded"] then
			Kimochi(window, _Xml([[<Label text="%s" y="%s" />]], L("STR_SETTING_MAIL"), y)):color(255, 255, 0)
			local checkbox_AutoExange = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="%s" />]], L("STR_SETTING_AUTOEXANGE"), tostring(AH_MailBank.bAutoExange), y + 30))
			checkbox_AutoExange.click = function(arg)
				AH_MailBank.bAutoExange = arg
			end
			y = y + 60
		end
		
		if _G["AH_Spliter_Loaded"] then
			Kimochi(window, _Xml([[<Label text="%s" y="%s" />]], L("STR_SETTING_SPLIT"), y)):color(255, 255, 0)
			local checkbox_SaveHistory = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="%s" />]], L("STR_SETTING_SAVEHISTORY"), tostring(AH_Spliter.bSaveHistory), y + 30))
			checkbox_SaveHistory.click = function(arg)
				AH_Spliter.bSaveHistory = arg
			end
			Kimochi(window, _Xml([[<Label text="%s" x="200" y="%s" />]], L("STR_SETTING_SAVEHISTORYTIP"), y + 30)):color(180, 180, 180)
			y = y + 60
		end
		
		if _G["AH_Tip_Loaded"] then
			Kimochi(window, _Xml([[<Label text="%s" y="%s" />]], L("STR_SETTING_ITEMTIP"), y)):color(255, 255, 0)
			local checkbox_ShowTipEx = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="%s" />]], L("STR_SETTING_SHOWTIPEX"), tostring(AH_Tip.bShowTipEx), y + 30))
			checkbox_ShowTipEx.click = function(arg)
				AH_Tip.bShowTipEx = arg
			end
			Kimochi(window, _Xml([[<Label text="%s" x="200" y="%s" />]], L("STR_SETTING_SHOWTIPEXTIP"), y + 30)):color(180, 180, 180)
			
			local checkbox_ShowLearned = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="%s" />]], L("STR_SETTING_SHOWLEARNED"), tostring(AH_Tip.bShowLearned), y + 60))
			checkbox_ShowLearned.click = function(arg)
				AH_Tip.bShowLearned = arg
			end
			
			local checkbox_ShowUnlearn = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="%s" />]], L("STR_SETTING_SHOWUNLEARNED"), tostring(AH_Tip.bShowUnlearn), y + 90))
			checkbox_ShowUnlearn.click = function(arg)
				AH_Tip.bShowUnlearn = arg
			end
			
			local checkbox_ShowCachePrice = Kimochi(window, _Xml([[<CheckBox text="%s" check="%s" y="%s" />]], L("STR_SETTING_SHOWCACHEPRICE"), tostring(AH_Tip.bShowCachePrice), y + 120))
			checkbox_ShowCachePrice.click = function(arg)
				AH_Tip.bShowCachePrice = arg
			end
			
		end
	end
	
	return frame
end

AH = AH or {}

function AH.OpenPanel()
	AH_SettingPanel.Init()
end

function AH.ClosePanel()
	local frame = Station.Lookup("Normal/AH_SettingPanel")
	if frame and frame:IsVisible() then
		Wnd.CloseWindow("AH_SettingPanel")
	end
end

function AH.TogglePanel()
	local frame = Station.Lookup("Normal/AH_SettingPanel")
	if not frame then
		AH.OpenPanel()
	else
		Wnd.CloseWindow("AH_SettingPanel")
	end
end

--[[RegisterEvent("LOGIN_GAME", function()
	TraceButton_AppendAddonMenu({{
		szOption = "SettingPanel",
		fnAction = function()
			AH.TogglePanel()
		end,
	}})
end)]]
