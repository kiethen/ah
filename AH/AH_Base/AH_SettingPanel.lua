AH_SettingPanel = AH_SettingPanel or {}


function AH_SettingPanel.Init()
	--主窗体
	local frame = Kimochi([[<Frame name="AH_SettingPanel" title="《交易行助手》设置" />]])
	frame:point("CENTER", 0, 0, "CENTER", 0, 0)
	
	Kimochi(frame, [[<Image w="36" h="36" x="5" image="ui\\image\\uiCommon\\commonpanel.UITex" frame="9" />]])
	
	--Tab栏背景
	Kimochi(frame, [[<Image w="770" h="33" y="50" image="ui\\image\\uiCommon\\activepopularize2.UITex" frame="46" />]]):setType(11)
	
	local pageSet = Kimochi(frame, [[<PageSet w="768" h="462" y="50" />]])
	
	local feedBack = Kimochi(pageSet, [[<Button text="问题反馈" x="670" y="4" gold="true" />]])
	feedBack.click = function()
		OpenInternetExplorer("http://weibo.com/nzgeneral")
	end

	local x = 20
	if _G["AH_Helper_Loaded"] then
		local tabBox = Kimochi(frame, string.format([[<TabBox x="%s" w="85" h="30" text="交易行" group="class" check="true"/>]], x))
		local window = Kimochi(pageSet, [[<Window w="708" h="432" x="35" y="40" />]])
		pageSet:add(window:this(), tabBox:this())
		tabBox.click = function(_check)
			if _check then
				pageSet:active(0)
			end
		end

		Kimochi(window, [[<Label text="※ 常用设置" />]]):color(255, 255, 0)
		--自动搜索
		local checkbox_AutoSearch = Kimochi(window, string.format([[<CheckBox text="启用自动搜索" check="%s" y="30" />]], tostring(AH_Helper.bAutoSearch)))
		checkbox_AutoSearch.click = function(arg)
			AH_Helper.bAutoSearch = arg
		end
		
		--品质等级
		local checkbox_QualityLevel = Kimochi(window, string.format([[<CheckBox text="显示品质等级" check="%s" x="180" y="30" />]], tostring(AH_Helper.bShowQualityLevel)))
		checkbox_QualityLevel.click = function(arg)
			AH_Helper.bShowQualityLevel = arg
		end
		
		--交易卫士
		local checkbox_Guard = Kimochi(window, string.format([[<CheckBox text="启用交易卫士" check="%s" x="360" y="30" />]], tostring(AH_Helper.bGuard)))
		Kimochi(window, [[<Label text="高于" x="492" y="30" w="30" />]])
		local textbox_Multiple = Kimochi(window, string.format([[<TextBox text="%s" x="525" y="30" w="40" />]], AH_Helper.nMultiple)):enable(AH_Helper.bGuard)
		Kimochi(window, [[<Label text="倍拦截" x="575" y="30" />]])
		checkbox_Guard.click = function(arg)
			AH_Helper.bGuard = arg
			textbox_Multiple:enable(arg)
		end
		textbox_Multiple.change = function(arg)
			AH_Helper.nMultiple = tonumber(arg)
		end
		
		--实时竞拍倒计时
		local checkbox_RealTime = Kimochi(window, string.format([[<CheckBox text="实时竞拍倒计时" check="%s" y="60"/>]], tostring(AH_Helper.bRealTime)))
		checkbox_RealTime.click = function(arg)
			AH_Helper.bRealTime = arg
		end
		
		--倒计时颜色
		local colorbox_RealTime = Kimochi(window, string.format([[<ColorBox text="倒计时颜色" x="184" y="60" r="%s" g="%s" b="%s" />]], unpack(AH_Helper.tRealTimeColor)))
		colorbox_RealTime.change = function(arg)
			AH_Helper.tRealTimeColor = arg
		end
		
		--显示竞拍者名字
		local checkbox_BidderName = Kimochi(window, string.format([[<CheckBox text="显示竞拍者名字" y="90" check="%s" />]], tostring(AH_Helper.bBidderName)))
		checkbox_BidderName.click = function(arg)
			AH_Helper.bBidderName = arg
		end
		
		--竞拍者颜色
		local colorbox_BidderName = Kimochi(window, string.format([[<ColorBox text="竞拍者颜色" x="184" y="90" r="%s" g="%s" b="%s" />]], unpack(AH_Helper.tBidderNameColor)))
		colorbox_BidderName.change = function(arg)
			AH_Helper.tBidderNameColor = arg
		end
		
		--历史记录
		Kimochi(window, [[<Label text="历史记录条数" x="364" y="60" />]])
		Kimochi(window, [[<Label text="条" x="530" y="60" />]])
		local combobox_MaxHistory = Kimochi(window, string.format([[<ComboBox text="%s" w="55" x="470" y="60" />]], AH_Helper.nMaxHistory))
		combobox_MaxHistory.click = function(m)
			table.insert(m,{szOption = "5", fnAction = function() AH_Helper.nMaxHistory = 5 combobox_MaxHistory:text(5) end,})
			table.insert(m,{szOption = "10", fnAction = function() AH_Helper.nMaxHistory = 10 combobox_MaxHistory:text(10) end,})
			table.insert(m,{szOption = "15", fnAction = function() AH_Helper.nMaxHistory = 15 combobox_MaxHistory:text(15) end,})
			table.insert(m,{szOption = "20", fnAction = function() AH_Helper.nMaxHistory = 20 combobox_MaxHistory:text(20) end,})
			PopupMenu(m)
		end
		
		--保管时间
		Kimochi(window, [[<Label text="寄售保管时间" x="364" y="90" />]])
		Kimochi(window, [[<Label text="小时" x="530" y="90" />]])
		local combobox_SellTime = Kimochi(window, string.format([[<ComboBox text="%s" w="55" x="470" y="90" />]], AH_Helper.szDefaultTime:match("(%d+)")))
		combobox_SellTime.click = function(m)
			table.insert(m,{szOption = "12", fnAction = function() AH_Helper.szDefaultTime = "12小时" combobox_SellTime:text(12) end,})
			table.insert(m,{szOption = "24", fnAction = function() AH_Helper.szDefaultTime = "24小时" combobox_SellTime:text(24) end,})
			table.insert(m,{szOption = "48", fnAction = function() AH_Helper.szDefaultTime = "48小时" combobox_SellTime:text(48) end,})
			PopupMenu(m)
		end
	
		--过滤秘籍
		local checkbox_FilterRecipe = Kimochi(window, string.format([[<CheckBox text="过滤已读秘籍" check="%s" y="120" />]], tostring(AH_Helper.bFilterRecipe)))
		checkbox_FilterRecipe.click = function(arg)
			AH_Helper.bFilterRecipe = arg
		end
		
		--过滤书籍
		local checkbox_FilterBook = Kimochi(window, string.format([[<CheckBox text="过滤已读书籍" check="%s" x="180" y="120" />]], tostring(AH_Helper.bFilterBook)))
		checkbox_FilterBook.click = function(arg)
			AH_Helper.bFilterBook = arg
		end
		
		--自动差价
		local checkbox_AutoDiscount = Kimochi(window, string.format([[<CheckBox text="启用自动差价" check="%s" x="360" y="120" />]], tostring(AH_Helper.bLowestPrices)))
		local szText = ""
		if AH_Helper.nDefaultPrices == 1 then
			szText = "1铜"
		elseif AH_Helper.nDefaultPrices == 1 * 100 then
			szText = "1银"
		elseif AH_Helper.nDefaultPrices == 100 * 100 then
			szText = "1金"
		end
		local combobox_Discount = Kimochi(window, string.format([[<ComboBox text="%s" w="80" x="500" y="120" />]], szText)):enable(AH_Helper.bLowestPrices)
		combobox_Discount.click = function(m)
			table.insert(m,{szOption = "1铜", fnAction = function() AH_Helper.nDefaultPrices = 1 combobox_Discount:text("1铜") end,})
			table.insert(m,{szOption = "1银", fnAction = function() AH_Helper.nDefaultPrices = 1 * 100 combobox_Discount:text("1银") end,})
			table.insert(m,{szOption = "1金", fnAction = function() AH_Helper.nDefaultPrices = 100 * 100 combobox_Discount:text("1金") end,})
			PopupMenu(m)
		end
		checkbox_AutoDiscount.click = function(arg)
			AH_Helper.bLowestPrices = arg
			combobox_Discount:enable(arg)
		end
		
		
		Kimochi(window, [[<Label text="※ 快捷功能" y="150" />]]):color(255, 255, 0)
		--快速寄售
		local checkbox_FastSell = Kimochi(window, string.format([[<CheckBox text="启用快速寄售" check="%s" y="180" />]], tostring(AH_Helper.bDBCtrlSell)))
		checkbox_FastSell.click = function(arg)
			AH_Helper.bDBCtrlSell = arg
		end
		Kimochi(window, [[<Label text="（按住CTRL键，鼠标右键双击物品改成批量寄售捷）" x="140" y="180" />]]):color(180, 180, 180)
		
		--快速竞拍
		local checkbox_FastBid = Kimochi(window, string.format([[<CheckBox text="启用快速竞拍" check="%s"  y="210" />]], tostring(AH_Helper.bFastBid)))
		checkbox_FastBid.click = function(arg)
			AH_Helper.bFastBid = arg
		end
		Kimochi(window, [[<Label text="（按住SHIFT+CTRL，鼠标左键点击物品栏可以快速出价）" x="140" y="210" />]]):color(180, 180, 180)
		
		--快速购买
		local checkbox_FastBuy = Kimochi(window, string.format([[<CheckBox text="启用快速购买" check="%s"  y="240" />]], tostring(AH_Helper.bFastBuy)))
		Kimochi(window, [[<Label text="（按住ALT+CTRL，鼠标左键点击物品栏可以快速购买）" x="140" y="240" />]]):color(180, 180, 180)
		Kimochi(window, [[<Label text="└" w="30" h="28" x="9" y="270" />]])
		local checkbox_DBClickBuyType = Kimochi(window, string.format([[<CheckBox text="启用鼠标双击方式" x="30" check="%s"  y="270" />]], tostring(AH_Helper.bDBClickFastBuy))):enable(AH_Helper.bFastBuy)
		checkbox_FastBuy.click = function(arg)
			AH_Helper.bFastBuy = arg
			checkbox_DBClickBuyType:enable(arg)
		end
		checkbox_DBClickBuyType.click = function(arg)
			AH_Helper.bDBClickFastBuy = arg
		end
		
		--快速取消
		local checkbox_FastCancel = Kimochi(window, string.format([[<CheckBox text="启用快速取消" check="%s" y="300" />]], tostring(AH_Helper.bFastCancel)))
		Kimochi(window, [[<Label text="（按住ALT+CTRL，鼠标左键点击物品栏可以快速取消）" x="140" y="300" />]]):color(180, 180, 180)
		Kimochi(window, [[<Label text="└" w="30" h="28" x="9" y="330" />]])
		local checkbox_DBClickCancelType = Kimochi(window, string.format([[<CheckBox text="启用鼠标双击方式" x="30" check="%s"  y="330" />]], tostring(AH_Helper.bDBClickFastCancel))):enable(AH_Helper.bFastCancel)
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
		local tabBox = Kimochi(frame, string.format([[<TabBox x="%s" w="85" h="30" text="其他" group="class" />]], x))
		local window = Kimochi(pageSet, [[<Window w="708" h="432" x="35" y="40" />]])
		pageSet:add(window:this(), tabBox:this())
		tabBox.click = function(_check)
			if _check then
				pageSet:active(1)
			end
		end
		
		local y = 0
		if _G["AH_MailBank_Loaded"] then
			Kimochi(window, string.format([[<Label text="※ 邮箱助手" y="%s" />]], y)):color(255, 255, 0)
			local checkbox_AutoExange = Kimochi(window, string.format([[<CheckBox text="自动载入上一次寄件方案" check="%s" y="%s" />]], tostring(AH_MailBank.bAutoExange), y + 30))
			checkbox_AutoExange.click = function(arg)
				AH_MailBank.bAutoExange = arg
			end
			y = y + 60
		end
		
		if _G["AH_Spliter_Loaded"] then
			Kimochi(window, string.format([[<Label text="※ 拆分助手" y="%s" />]], y)):color(255, 255, 0)
			local checkbox_SaveHistory = Kimochi(window, string.format([[<CheckBox text="自动保存/载入拆分方案" check="%s" y="%s" />]], tostring(AH_Spliter.bSaveHistory), y + 30))
			checkbox_SaveHistory.click = function(arg)
				AH_Spliter.bSaveHistory = arg
			end
			Kimochi(window, string.format([[<Label text="（打开方式，按住ALT键点击物品）" x="200" y="%s" />]], y + 30)):color(180, 180, 180)
			y = y + 60
		end
		
		if _G["AH_Tip_Loaded"] then
			Kimochi(window, string.format([[<Label text="※ 鼠标提示" y="%s" />]], y)):color(255, 255, 0)
			local checkbox_ShowTipEx = Kimochi(window, string.format([[<CheckBox text="鼠标提示显示技艺配方" check="%s" y="%s" />]], tostring(AH_Tip.bShowTipEx), y + 30))
			checkbox_ShowTipEx.click = function(arg)
				AH_Tip.bShowTipEx = arg
			end
			Kimochi(window, string.format([[<Label text="（不开启时按住ALT或SHIFT键亦可显示配方）" x="200" y="%s" />]], y + 30)):color(180, 180, 180)
			
			local checkbox_ShowLearned = Kimochi(window, string.format([[<CheckBox text="显示已学技艺配方" check="%s" y="%s" />]], tostring(AH_Tip.bShowLearned), y + 60))
			checkbox_ShowLearned.click = function(arg)
				AH_Tip.bShowLearned = arg
			end
			
			local checkbox_ShowUnlearn = Kimochi(window, string.format([[<CheckBox text="显示未学技艺配方" check="%s" y="%s" />]], tostring(AH_Tip.bShowUnlearn), y + 90))
			checkbox_ShowUnlearn.click = function(arg)
				AH_Tip.bShowUnlearn = arg
			end
			
			local checkbox_ShowCachePrice = Kimochi(window, string.format([[<CheckBox text="显示缓存的物品价格" check="%s" y="%s" />]], tostring(AH_Tip.bShowCachePrice), y + 120))
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
