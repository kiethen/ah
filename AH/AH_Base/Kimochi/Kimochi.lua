local _class = { }

local function class(super)
    local class_type = { }
    class_type.ctor = false
    class_type.super = super
    class_type.new = function(...)
        local obj = { }
        setmetatable(obj, { __index = _class[class_type] })
        do
            local create
            create = function(c, ...)
                if c.super then
                    create(c.super, ...)
                end
                if c.ctor then
                    c.ctor(obj, ...)
                end
            end
            create(class_type, ...)
        end
        return obj
    end
    local vtbl = { }
    _class[class_type] = vtbl

    setmetatable(class_type, {
        __newindex =
        function(t, k, v)
            vtbl[k] = v
        end
    } )

    if super then
        setmetatable(vtbl, {
            __index =
            function(t, k)
                local ret = _class[super][k]
                vtbl[k] = ret
                return ret
            end
        } )
    end

    return class_type
end

local INI_FILE = "Interface/AH/AH_Base/Kimochi/ui/%s.ini"
local PARA_ERROR = "parameters error."
local NAME_INDEX = 1

----------------------------------------------
-- Wnd 类型组件
----------------------------------------------
--- <summary>
--- 向Frame面板追加组件
--- </summary>
--- <param name="_parent">父级组件</param>
--- <param name="_type">追加组件的类型</param>
--- <param name="_name">追加组件的别名</param>
--- <returns>组件</returns>
local _AppendWnd = function(_parent, _type, _name)
    if not _name then
        _name = string.format("KIMOCHI_INDEX_%d", NAME_INDEX)
        NAME_INDEX = NAME_INDEX + 1
    end
    if _parent._addon then
        _parent = _parent:this()
    end
    local hwnd = Wnd.OpenWindow(string.format(INI_FILE, _type:match("(%a+)_?")), _name):Lookup(_type)
    hwnd:ChangeRelation(_parent, true, true)
    hwnd:SetName(_name)
    Wnd.CloseWindow(_name)
    return hwnd
end

--- <summary>
--- Wnd 基础组件类
--- </summary>
local WndBase = class()

--- <summary>
--- 构造 Wnd 基础组件
--- </summary>
--- <param name="_this">当前组件</param>
function WndBase:ctor(_this)
    self._addon = true
    self._listeners = { self }
end

--- <summary>
--- 获取 Wnd 组件名
--- </summary>
--- <returns>组件名</returns>
function WndBase:name()
    return self._this:GetName()
end

--- <summary>
--- 设置或获取 Wnd 当前组件
--- </summary>
--- <param name="_this">当前组件</param>
--- <returns>当前组件</returns>
function WndBase:this(_this)
    if _this then
        self._this = _this
    end
    return self._this
end

--- <summary>
--- 设置或获取 Wnd 组件大小
--- </summary>
--- <param name="...">大小</param>
--- <returns type="int">组件大小</returns>
function WndBase:size(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetSize(...)
        return self
    end
    return self._this:GetSize()
end

--- <summary>
--- 设置或获取 Wnd 相对坐标
--- </summary>
--- <param name="...">坐标</param>
--- <returns>组件坐标</returns>
function WndBase:pos(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetRelPos(...)
        return self
    end
    return self._this:GetRelPos()
end

--- <summary>
--- 设置或获取 Wnd 组件启用状态
--- </summary>
--- <param name="...">是否启</param>
--- <returns>组件启用状态</returns>
function WndBase:enable(...)
    local t = { ... }
    if #t > 0 then
        self._this:Enable(...)
        return self
    end
    return self._this:IsEnabled()
end

--- <summary>
--- 设置或获取 Wnd 组件父级
--- </summary>
--- <param name="_parent">父级组件</param>
--- <returns>父级组件</returns>
function WndBase:parent(_parent)
    if _parent then
        self._parent = _parent
        return self
    end
    return self._parent
end

--- <summary>
--- 显示 Wnd 组件
--- </summary>
function WndBase:show()
    self._this:Show()
    return self
end

--- <summary>
--- 隐藏 Wnd 组件
--- </summary>
function WndBase:hide()
    self._this:Hide()
    return self
end

--- <summary>
--- 获取 Wnd 是否可见
--- </summary>
--- <returns>可见状态</returns>
function WndBase:visible()
    return self._this:IsVisible()
end

--- <summary>
--- 设置 Wnd 可见时隐藏，否则显示
--- </summary>
function WndBase:toggle()
    self._this:ToggleVisible()
    return self
end

--- <summary>
--- 设置 Wnd 组件缩放等级
--- </summary>
--- <param name="...">缩放等级</param>
function WndBase:scale(...)
    self._this:Scale(...)
    return self
end

--- <summary>
--- 设置或获取 Wnd 组件透明度
--- </summary>
--- <param name="...">透明度</param>
--- <returns>透明度</returns>
function WndBase:alpha(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetAlpha(...)
        return self
    end
    return self._this:GetAlpha()
end

--- <summary>
--- 设置 Wnd 组件层级关系
--- </summary>
--- <param name="...">层级关系</param>
function WndBase:relation(...)
    self._this:ChangeRelation(...)
    return self
end

--- <summary>
--- 设置 Wnd 组件左上角位置
--- </summary>
--- <param name="...">左上角位置</param>
function WndBase:point(...)
    self._this:SetPoint(...)
    return self
end

--- <summary>
--- 移除控件	
--- </summary
function WndBase:remove()
	local _name = self:name()
	if self._this:GetType() == "WndFrame" then
		Wnd.CloseWindow(_name)
	else
		self._this:Destroy()
	end
end

--- <summary>
--- 设置 Wnd 组件触发事件
--- </summary>
--- <param name="_event">事件名</param>
--- <param name="...">事件参数</param>
function WndBase:fireEvent(_event, ...)
    for _k, _v in pairs(self._listeners) do
        if _v[_event] then
            local res, err = pcall(_v[_event], ...)
            if not res then
                OutputMessage("MSG_SYS", "ERROR:" .. err .. "\n")
            end
        end
    end
end

--- <summary>
--- WndFrame 组件类，继承自 Wnd 基础类
--- </summary>
--- <param name="...">左上角位置</param>
local WndFrame = class(WndBase)

--- <summary>
--- 构造 WndFrame 组件
--- </summary>
--- <param name="_xml">WndFrame属性</param>
function WndFrame:ctor(_xml)
    assert(_xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.Frame["@name"]
    local _title = parser.Frame["@title"]

    local frame = Wnd.OpenWindow(string.format(INI_FILE, "WndFrame"), _name)
    frame:SetName(_name)
    self._this = frame
    self:this(self._this)

    frame:Lookup("Btn_Close").OnLButtonClick = function()
        Wnd.CloseWindow(_name)
    end
    frame.OnFrameKeyDown = function()
        local szKey = GetKeyName(Station.GetMessageKey())
        if szKey == "Esc" or szKey == "ESC" then
            PlaySound(SOUND.UI_SOUND, g_sound.Button)
            Wnd.CloseWindow(_name)
        end
        return 1
    end
    self:title(_title or "")
end

--- <summary>
--- 获取 WndFrame 容器
--- </summary>
--- <returns>容器</returns>
function WndFrame:handle()
    return self._this:Lookup("", "")
end

-- 清空 WndFrame 容器
function WndFrame:clear()
    self._this:Lookup("", ""):Clear()
    return self
end

-- 设置或获取 WndFrame 标题
function WndFrame:title(...)
    local t = { ... }
    if #t > 0 then
        self._this:Lookup("", "Text_Title"):SetText(...)
        return self
    end
    return self._this:Lookup("", "Text_Title"):GetText()
end

-- 设置或获取 WndFrame 拖动状态及范围
function WndFrame:drag(...)
    local t = { ... }
    if #t == 1 then
        self._this:EnableDrag(...)
        return self
    elseif #t == 4 then
        self._this:SetDragArea(...)
        return self
    end
    return self._this:IsDragable()
end

-- 注册 WndFrame 事件
function WndFrame:event(...)
    self._this:RegisterEvent(...)
    return self
end

-- 激活 WndFrame
function WndFrame:active()
    Station.SetFocusWindow(self._this)
    self._this:BringToTop()
    return self
end

-- WndWindow 组件类，继承自 Wnd 基础类
local WndWindow = class(WndBase)

-- 构造 WndWindow 组件
function WndWindow:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.Window["@name"]
    local _w = parser.Window["@w"] or 100
    local _h = parser.Window["@h"] or 100
    local _x = parser.Window["@x"] or 0
    local _y = parser.Window["@y"] or 0

    local hwnd = _AppendWnd(_parent, "WndWindow", _name)
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self:size(_w, _h)
    self:pos(_x, _y)
end

-- 设置或获取 WndWindow 大小
function WndWindow:size(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetSize(...)
        self._this:Lookup("", ""):SetSize(...)
        return self
    end
    return self._this:GetSize()
end

-- 获取 WndWindow 容器
function WndWindow:handle()
    return self._this:Lookup("", "")
end

-- 清空 WndWindow 容器
function WndWindow:clear()
    self._this:Lookup("", ""):Clear()
    return self
end

-- WndPageSet 组件类，继承自 Wnd 基础类
local WndPageSet = class(WndBase)

-- 构造 WndPageSet 组件
function WndPageSet:ctor(_parent, _xml)
	assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.PageSet["@name"]
    local _w = parser.PageSet["@w"] or 100
    local _h = parser.PageSet["@h"] or 100
    local _x = parser.PageSet["@x"] or 0
    local _y = parser.PageSet["@y"] or 0
	
	local hwnd = _AppendWnd(_parent, "WndPageSet", _name)
	self._this = hwnd
	self:this(self._this)
	self:parent(_parent)
	self:size(_w, _h)
	self:pos(_x, _y)
end

function WndPageSet:add(...)
	self._this:AddPage(...)
	return self
end

function WndPageSet:active(...)
	self._this:ActivePage(...)
	return self
end

-- WndButton 组件类，继承自 Wnd 基础类
local WndButton = class(WndBase)

-- 构造 WndButton 组件
function WndButton:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.Button["@name"]
    local _text = parser.Button["@text"]
    local _enable = (parser.Button["@enable"] == nil or parser.Button["@enable"]) and true or false
	local _gold = parser.Button["@gold"] and true or false
    local _w = parser.Button["@w"] or 91
    local _x = parser.Button["@x"] or 0
    local _y = parser.Button["@y"] or 0

    local hwnd = nil
	if _gold then
		hwnd = _AppendWnd(_parent, "WndButton_Gold", _name)
		self._text = hwnd:Lookup("", "Text_Default_Gold")
	else
		hwnd = _AppendWnd(_parent, "WndButton", _name)
		self._text = hwnd:Lookup("", "Text_Default")
	end
    self:text(_text or "")
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self:enable(_enable)
    self:size(_w, 26)
    self:pos(_x, _y)

    self._this.OnLButtonClick = function()
        self:fireEvent("click")
    end
    self._this.OnMouseEnter = function()
        self:fireEvent("enter")
    end
    self._this.OnMouseLeave = function()
        self:fireEvent("leave")
    end
end

-- 设置或获取 WndButton 可用状态
function WndButton:enable(...)
    local t = { ... }
    if #t > 0 then
        if t[1] then
            self._text:SetFontColor(255, 255, 255)
            self._this:Enable(true)
            return self
        elseif not t[1] then
            self._text:SetFontColor(180, 180, 180)
            self._this:Enable(false)
            return self
        end
    end
    return self._this:IsEnabled()
end

-- 设置或获取 WndButton 文本
function WndButton:text(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetText(...)
        return self
    end
    return self._text:GetText()
end

-- 设置或获取 WndButton 大小
function WndButton:size(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetSize(...)
        self._this:Lookup("", ""):SetSize(...)
        self._text:SetSize(...)
        return self
    end
    return self._this:GetSize()
end

-- WndTextBox 组件类，继承自 Wnd 基础类
local WndTextBox = class(WndBase)

-- 构造 WndTextBox 组件
function WndTextBox:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.TextBox["@name"]
    local _text = parser.TextBox["@text"]
    local _multi = parser.TextBox["@multi"] and true or false
    local _enable = (parser.TextBox["@enable"] == nil or parser.TextBox["@enable"]) and true or false
    local _limit = parser.TextBox["@limit"] or 36
    local _w = parser.TextBox["@w"] or 100
    local _h = parser.TextBox["@h"] or 25
    local _x = parser.TextBox["@x"] or 0
    local _y = parser.TextBox["@y"] or 0

    local hwnd = _AppendWnd(_parent, "WndTextBox", _name)
    self._edit = hwnd:Lookup("Edit_Default")
    self:text(_text or "")
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self:limit(_limit)
    self:multi(_multi)
    self:enable(_enable)
    self:size(_w, _h)
    self:pos(_x, _y)

    self._edit.OnEditChanged = function()
        local _text = self._edit:GetText()
        self:fireEvent("change", _text)
    end
end

-- 设置或获取 WndTextBox 大小
function WndTextBox:size(_w, _h)
    if _w and _h then
        self._this:SetSize(_w + 4, _h)
        self._this:Lookup("", ""):SetSize(_w + 4, _h)
        self._this:Lookup("", "Image_Default"):SetSize(_w + 4, _h)
        self._edit:SetSize(_w, _h)
        return self
    end
    return self._this:GetSize()
end

-- 设置或获取 WndTextBox 限制长度
function WndTextBox:limit(...)
    local t = { ... }
    if #t > 0 then
        self._edit:SetLimit(...)
        return self
    end
    return self._edit:GetLimit()
end

-- 设置或获取 WndTextBox 是否多行
function WndTextBox:multi(...)
    local t = { ... }
    if #t > 0 then
        self._edit:SetMultiLine(...)
        return self
    end
    return self._edit:IsMultiLine()
end

-- 设置 WndTextBox 可用状态
function WndTextBox:enable(_enable)
    if _enable then
        self._edit:SetFontColor(255, 255, 255)
        self._edit:Enable(true)
    else
        self._edit:SetFontColor(180, 180, 180)
        self._edit:Enable(false)
    end
    return self
end

-- 全选 WndTextBox 内容
function WndTextBox:select()
    self._this:SelectAll()
    return self
end

-- 设置或获取 WndTextBox 内容
function WndTextBox:text(...)
    local t = { ... }
    if #t > 0 then
        self._edit:SetText(...)
        return self
    end
    return self._edit:GetText()
end

-- 清空 WndTextBox 内容
function WndTextBox:clear()
    self._edit:ClearText()
    return self
end

-- 设置或获取 WndTextBox 字体
function WndTextBox:font(...)
    local t = { ... }
    if #t > 0 then
        self._edit:SetFontScheme(...)
        return self
    end
    return self._edit:GetFontScheme()
end

-- 设置 WndTextBox 字体颜色
function WndTextBox:color(...)
    self._edit:SetFontColor(...)
    return self
end

-- WndCheckBox 组件类，继承自 Wnd 基础类
local WndCheckBox = class(WndBase)

-- 构造 WndCheckBox组件
function WndCheckBox:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.CheckBox["@name"]
    local _text = parser.CheckBox["@text"]
    local _check = parser.CheckBox["@check"] and true or false
    local _enable = (parser.CheckBox["@enable"] == nil or parser.CheckBox["@enable"]) and true or false
    local _w = parser.CheckBox["@w"] or 150
    local _x = parser.CheckBox["@x"] or 0
    local _y = parser.CheckBox["@y"] or 0

    local hwnd = _AppendWnd(_parent, "WndCheckBox", _name)
    self._text = hwnd:Lookup("", "Text_Default")
    self:text(_text or "")
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self:check(_check)
    self:enable(_enable)
    self:size(_w, 28)
    self:pos(_x, _y)

    self._this.OnCheckBoxCheck = function()
        self:fireEvent("click", true)
    end
    self._this.OnCheckBoxUncheck = function()
        self:fireEvent("click", false)
    end
end

-- 设置或获取 WndCheckBox 大小
function WndCheckBox:size(_w, _h)
    if _w and _h then
        self._text:SetSize(_w - 30, _h)
        return self
    end
    return self._text:GetSize()
end

-- 设置或获取 WndCheckBox 勾选状态
function WndCheckBox:check(...)
    local t = { ... }
    if #t > 0 then
        self._this:Check(...)
        return self
    end
    return self._this:IsCheckBoxChecked()
end

-- 设置 WndCheckBox 可用状态
function WndCheckBox:enable(_enable)
    if _enable then
        self._text:SetFontColor(255, 255, 255)
        self._this:Enable(true)
    else
        self._text:SetFontColor(180, 180, 180)
        self._this:Enable(false)
    end
    return self
end

-- 设置或获取 WndCheckBox 文本
function WndCheckBox:text(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetText(...)
        return self
    end
    return self._text:GetText()
end

-- 设置或获取 WndCheckBox 字体颜色
function WndCheckBox:color(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetFontColor(...)
        return self
    end
    return self._text:GetFontColor()
end

-- 设置或获取 WndCheckBox 字体
function WndCheckBox:font(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetFontScheme(...)
        return self
    end
    return self._text:GetFontScheme()
end

-- WndComboBox 组件，继承自 Wnd 基础类
local WndComboBox = class(WndBase)

-- 构造 WndComboBox 组件
function WndComboBox:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.ComboBox["@name"]
    local _text = parser.ComboBox["@text"]
    local _enable =(parser.ComboBox["@enable"] == nil or parser.ComboBox["@enable"]) and true or false
    local _w = parser.ComboBox["@w"] or 185
    local _x = parser.ComboBox["@x"] or 0
    local _y = parser.ComboBox["@y"] or 0

    local hwnd = _AppendWnd(_parent, "WndComboBox", _name)
    self._text = hwnd:Lookup("", "Text_Default")
    self:text(_text or "")
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self:enable(_enable)
    self:size(_w, 25)
    self:pos(_x, _y)

    self._this:Lookup("Btn_ComboBox").OnLButtonClick = function()
        local _x, _y = self._this:GetAbsPos()
        local _w, _h = self:size()
        local _menu = { }
        _menu.nMiniWidth = _w
        _menu.x = _x
        _menu.y = _y + _h
        self:fireEvent("click", _menu)
    end
end

-- 设置 WndComboBox 可用状态
function WndComboBox:enable(_enable)
    if _enable then
        self._text:SetFontColor(255, 255, 255)
        self._this:Lookup("Btn_ComboBox"):Enable(true)
    else
        self._text:SetFontColor(180, 180, 180)
        self._this:Lookup("Btn_ComboBox"):Enable(false)
    end
    return self
end

-- 设置或获取 WndComboBox 大小
function WndComboBox:size(_w, _h)
    if _w and _h then
        self._this:SetSize(_w, _h)
        local handle = self._this:Lookup("", "")
        handle:SetSize(_w, _h)
        handle:Lookup("Image_ComboBoxBg"):SetSize(_w, _h)
        handle:Lookup("Text_Default"):SetSize(_w - 20, _h)
        local btn = self._this:Lookup("Btn_ComboBox")
        btn:SetRelPos(_w - _h, 8)
        local h = btn:Lookup("", "")
        h:SetSize(_w, _h)
        local _x, _y = handle:GetAbsPos()
        h:SetAbsPos(_x, _y)
        return self
    end
    return self._this:GetSize()
end

-- 设置或获取 WndComboBox 文本
function WndComboBox:text(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetText(...)
        return self
    end
    return self._text:GetText()
end

-- WndRadioBox 组件，继承自 Wnd 基础类
local WndRadioBox = class(WndBase)
local _RadioBoxGroups = { }

-- 构造 WndRadioBox 组件
function WndRadioBox:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.RadioBox["@name"]
    local _text = parser.RadioBox["@text"]
    local _check = parser.RadioBox["@check"] and true or false
    local _enable = (parser.RadioBox["@enable"] == nil or parser.RadioBox["@enable"]) and true or false
    local _group = parser.RadioBox["@group"]
    local _w = parser.RadioBox["@w"] or 150
    local _x = parser.RadioBox["@x"] or 0
    local _y = parser.RadioBox["@y"] or 0

    local hwnd = _AppendWnd(_parent, "WndRadioBox", _name)
    self._text = hwnd:Lookup("", "Text_Default")
    self:text(_text or "")
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self:check(_check)
    self:enable(_enable)
    self:size(_w, 28)
    self:pos(_x, _y)

    self._this._group = _group
    self:group(_group)

    self._this.OnCheckBoxCheck = function()
        if self._group then
            for k, v in pairs(_RadioBoxGroups[self._group]) do
                if v:group() == this._group and v:name() ~= this:GetName() then
                    v:check(false)
                end
            end
            self:fireEvent("click", true)
        end
    end
end

-- 设置或获取 WndRadioBox 大小
function WndRadioBox:size(_w, _h)
    if _w and _h then
        self._text:SetSize(_w - 30, _h)
        return self
    end
    return self._text:GetSize()
end

-- 设置或获取 WndRadioBox 组别
function WndRadioBox:group(_group)
    if _group then
        if not _RadioBoxGroups[_group] then
            _RadioBoxGroups[_group] = { }
        end
        table.insert(_RadioBoxGroups[_group], self)
        self._group = _group
        return self
    end
    return self._group
end

-- 设置或获取 WndRadioBox 勾选状态
function WndRadioBox:check(...)
    local t = { ... }
    if #t > 0 then
        self._this:Check(...)
        return self
    end
    return self._this:IsCheckBoxChecked()
end

-- 设置 WndRadioBox 可用状态
function WndRadioBox:enable(_enable)
    if _enable then
        self._text:SetFontColor(255, 255, 255)
        self._this:Enable(true)
    else
        self._text:SetFontColor(180, 180, 180)
        self._this:Enable(false)
    end
    return self
end

-- 设置或获取 WndRadioBox 文本
function WndRadioBox:text(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetText(...)
        return self
    end
    return self._text:GetText()
end

-- 设置或获取 WndRadioBox 字体颜色
function WndRadioBox:color(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetFontColor(...)
        return self
    end
    return self._text:GetFontColor()
end

-- 设置或获取 WndRadioBox 字体
function WndRadioBox:font(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetFontScheme(...)
        return self
    end
    return self._text:GetFontScheme()
end


-- WndTabBox Object
local WndTabBox = class(WndBase)
local _TabBoxGroups = {}
function WndTabBox:ctor(_parent, _xml)
	assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.TabBox["@name"]
    local _text = parser.TabBox["@text"]
    local _check = parser.TabBox["@check"] and true or false
    local _enable = (parser.TabBox["@enable"] == nil or parser.TabBox["@enable"]) and true or false
    local _group = parser.TabBox["@group"]
    local _w = parser.TabBox["@w"] or 83
	local _h = parser.TabBox["@h"] or 30
    local _x = parser.TabBox["@x"] or 0
    local _y = parser.TabBox["@y"] or 0
	
	local hwnd = _AppendWnd(_parent, "WndTabBox", _name)
	self._text = hwnd:Lookup("", "Text_Default")
	self:text(_text or "")
	self._this = hwnd
	self:this(self._this)
	self:parent(_parent)
	self:check(_check)
	self:enable(_enable)
	self:size(_w, _h)
	self:pos(_x, _y)

	self._this._group = _group
	self:group(_group)
	
	self._this.OnCheckBoxCheck = function()
		if self._group then
			for k, v in pairs(_TabBoxGroups[self._group]) do
				if v:group() == this._group and v:name() ~= this:GetName() then
					v:check(false)
				end
			end
		end
		self:fireEvent("click", true)
	end
end

-- 设置或获取 WndTabBox 组别
function WndTabBox:group(_group)
	if _group then
		if not _TabBoxGroups[_group] then
			_TabBoxGroups[_group] = { }
		end
		table.insert(_TabBoxGroups[_group], self)
		self._group = _group
        return self
    end
end

-- 设置或获取 WndTabBox 勾选状态
function WndTabBox:check(...)
    local t = { ... }
    if #t > 0 then
        self._this:Check(...)
        return self
    end
    return self._this:IsCheckBoxChecked()
end

-- 设置 WndTabBox 可用状态
function WndTabBox:enable(_enable)
    if _enable then
        self._text:SetFontColor(255, 255, 255)
        self._this:Enable(true)
    else
        self._text:SetFontColor(180, 180, 180)
        self._this:Enable(false)
    end
    return self
end

-- 设置或获取 WndTabBox 文本
function WndTabBox:text(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetText(...)
        return self
    end
    return self._text:GetText()
end

-- 设置或获取 WndTabBox 大小
function WndTabBox:size(...)
	local t = { ... }
	if #t > 0 then
		self._this:SetSize(...)
		self._this:Lookup("", ""):SetSize(...)
        self._text:SetSize(...)
        return self
    end
    return self._this:GetSize()
end

-- WndTrackBar 组件，继承自 Wnd 基础类
local WndTrackBar = class(WndBase)

-- 构造 WndTrackBar 组件
function WndTrackBar:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.TrackBar["@name"]
    local _text = parser.TrackBar["@text"] or ""
    local _enable = (parser.TrackBar["@enable"] == nil or parser.TrackBar["@enable"]) and true or false
    local _min = parser.TrackBar["@min"] or 0
    local _max = parser.TrackBar["@max"] or 100
    local _step = parser.TrackBar["@step"] or 100
    local _unit = parser.TrackBar["@unit"] or ""
    local _value = parser.TrackBar["@value"] or 0
    local _w = parser.TrackBar["@w"] or 150
    local _x = parser.TrackBar["@x"] or 0
    local _y = parser.TrackBar["@y"] or 0

    local hwnd = _AppendWnd(_parent, "WndTrackBar", _name)
	self._text = hwnd:Lookup("", "Text_Name")
    self._scroll = hwnd:Lookup("Scroll_Default")
    self._value = hwnd:Lookup("", "Text_Default")
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self._min = _min
    self._max = _max
    self._step = _step
    self._unit = _unit
    self._scroll:SetStepCount(_step)
	self._text:SetText(_text)
    self:size(_w, 25)
    self:enable(_enable)
    self:pos(_x, _y)
    self:update(_value)

    self._scroll.OnScrollBarPosChanged = function()
        local _step = this:GetScrollPos()
        local _value = self:value(_step)
        self._value:SetText(_value .. self._unit)
        self:fireEvent("change", _value)
    end
end

-- 设置 WndTrackBar 可用状态
function WndTrackBar:enable(_enable)
    if _enable then
        self._text:SetFontColor(255, 255, 255)
		self._value:SetFontColor(255, 255, 255)
        self._scroll:Enable(true)
    else
        self._text:SetFontColor(180, 180, 180)
		self._value:SetFontColor(180, 180, 180)
        self._scroll:Enable(false)
    end
    return self
end

-- 设置或获取 WndTrackBar 大小
function WndTrackBar:size(_w, _h)
    if _w and _h then
        self._this:SetSize(_w, _h)
        self._this:Lookup("", ""):SetSize(_w, _h)
        self._this:Lookup("", ""):Lookup("Image_BG"):SetSize(_w, 10)
        self._scroll:SetSize(_w, _h)
		self._text:AutoSize()
		local _len = self._text:GetTextLen()
		local _w2, _h2 = self._text:GetTextExtent(_len)
		self._text:SetRelPos(0, _h - 18)
		self._this:Lookup("", ""):Lookup("Image_BG"):SetRelPos(_w2 + 3, _h - 16)
		self._scroll:SetRelPos(_w2 + 3, _h - 17)
        self._value:SetRelPos(_w + _w2 + 8, _h - 22)
        self._this:Lookup("", ""):FormatAllItemPos()
        return self
    end
    return self._this:GetSize()
end

-- 获取 WndTrackBar 值
function WndTrackBar:value(_step)
    return self._min + _step *(self._max - self._min) / self._step
end

-- 获取 WndTrackBar 步进
function WndTrackBar:step(_value)
    return(_value - self._min) * self._step /(self._max - self._min)
end

-- 获取 WndTrackBar 范围
function WndTrackBar:area(_min, _max, _step)
    return _min +(_max - _min) *(self:value(_step) - self._min) /(self._max - self._min)
end

-- 获取 WndTrackBar 范围
function WndTrackBar:areaFromValue(_min, _max, _value)
    return _min +(_max - _min) *(_value - self._min) /(self._max - self._min)
end

-- 获取 WndTrackBar 步进
function WndTrackBar:stepFromArea(_min, _max, _value)
    return self:step(self._min +(self._max - self._min) *(_value - _min) /(_max - _min))
end

-- 更新 WndTrackBar
function WndTrackBar:update(_value)
    self._value:SetText(_value .. self._unit)
    self._scroll:SetScrollPos(self:step(_value))
    return self
end

-- WndColorBox 组件，继承自 Wnd 基础类
local WndColorBox = class(WndBase)

-- 构造 WndColorBox 组件
function WndColorBox:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.ColorBox["@name"]
    local _text = parser.ColorBox["@text"]
    local _r = parser.ColorBox["@r"] or 125
    local _g = parser.ColorBox["@g"] or 125
    local _b = parser.ColorBox["@b"] or 125
    local _w = parser.ColorBox["@w"] or 140
    local _x = parser.ColorBox["@x"] or 0
    local _y = parser.ColorBox["@y"] or 0

    local hwnd = _AppendWnd(_parent, "WndColorBox", _name)
    self._text = hwnd:Lookup("", "Text_Default")
    self._shadow = hwnd:Lookup("", "Shadow_Default")
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self._r = _r
    self._g = _g
    self._b = _b
    self:text(_text or "")
    self:color(_r, _g, _b)
    self:size(_w, 25)
    self:pos(_x, _y)

    self._shadow.OnItemLButtonClick = function()
        local fnChangeColor = function(r, g, b)
            self:color(r, g, b)
            self:fireEvent("change", { r, g, b })
        end
        OpenColorTablePanel(fnChangeColor)
    end
end

-- 设置或获取 WndColorBox 大小
function WndColorBox:size(_w, _h)
    if _w and _h then
        self._this:SetSize(_w, _h)
        self._this:Lookup("", ""):SetSize(_w, _h)
        self._text:SetSize(_w - _h, _h)
        return self
    end
    return self._this:GetSize()
end

-- 设置或获取 WndColorBox 文本
function WndColorBox:text(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetText(...)
        return self
    end
    return self._text:GetText()
end

-- 设置或获取 WndColorBox 字体颜色
function WndColorBox:color(...)
    local t = { ... }
    if #t > 0 then
        self._shadow:SetColorRGB(...)
        self._text:SetFontColor(...)
        return self
    end
    return self._shadow:GetColorRGB()
end

-- 设置或获取 WndColorBox 字体
function WndColorBox:font(...)
    local t = { ... }
    if #t > 0 then
        self._text:SetFontScheme(...)
        return self
    end
    return self._text:GetFontScheme()
end

----------------------------------------------
-- ItemNull 类型组件
----------------------------------------------

-- 追加组件
local _AppendItem = function(_parent, _string, _name)
    if not _name then
        _name = string.format("EASYUI_INDEX_%d", NAME_INDEX)
        NAME_INDEX = NAME_INDEX + 1
    end
    if _parent._addon then
        _parent = _parent:handle()
    end
    local _count = _parent:GetItemCount()
    _parent:AppendItemFromString(_string)
    local hwnd = _parent:Lookup(_count)
    hwnd:SetName(_name)
    return hwnd
end

-- Item 基础组件类
local ItemBase = class()
function ItemBase:ctor(_this)
    self._addon = true
    self._listeners = { self }
end

-- 设置或获取 Item 组件名
function ItemBase:name(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetName(...)
        return self
    end
    return self._this:GetName()
end

-- 设置 Item 组件名
function ItemBase:scale(...)
    self._this:Scale(...)
    return self
end

-- 设置 Item 显示隐藏上锁
function ItemBase:lock(...)
    self._this:LockShowAndHide(...)
    return self
end

-- 设置或获取 Item 当前组件
function ItemBase:this(_this)
    if _this then
        self._this = _this
    end
    return self._this
end

-- 设置或获取 Item 大小
function ItemBase:size(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetSize(...)
        return self
    end
    return self._this:GetSize()
end

-- 设置或获取 Item 相对坐标
function ItemBase:pos(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetRelPos(...)
        return self
    end
    return self._this:GetRelPos()
end

-- 设置或获取 Item 透明度
function ItemBase:alpha(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetAlpha(...)
        return self
    end
    return self._this:GetAlpha()
end

-- 设置或获取 Item 鼠标Tip
function ItemBase:tip(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetTip(...)
        return self
    end
    return self._this:GetTip()
end

-- 设置或获取 Item 父级
function ItemBase:parent(_parent)
    if _parent then
        self._parent = _parent
    end
    return self._parent
end

-- 移除 Item
function ItemBase:remove()
    self._parent:RemoveItem(self._this)
end

-- 显示 Item
function ItemBase:show()
    self._this:Show()
    return self
end

-- 隐藏 Item
function ItemBase:hide()
    self._this:Hide()
    return self
end

-- 设置 Item 是否可见
function ItemBase:visible()
    return self._this:IsVisible()
end

-- 设置 Item 组件触发事件
function ItemBase:fireEvent(_event, ...)
    for _k, _v in pairs(self._listeners) do
        if _v[_event] then
            local res, err = pcall(_v[_event], ...)
            if not res then
                OutputMessage("MSG_SYS", "ERROR:" .. err .. "\n")
            end
        end
    end
end

-- Text 组建类，继承自 Item 基础类
local ItemLabel = class(ItemBase)

-- 构造 ItemLabel
function ItemLabel:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.Label["@name"]
    local _text = parser.Label["@text"]
    local _valign = parser.Label["@valign"]
    local _font = parser.Label["@font"]
    local _postype = parser.Label["@postype"]
    local _w = parser.Label["@w"]
    local _h = parser.Label["@h"]
    local _x = parser.Label["@x"] or 0
    local _y = parser.Label["@y"] or 0

    local _string = "<text>w=150 h=30 valign=1 font=162 postype=0 </text>"
    if _w then
        _string = string.gsub(_string, "w=%d+", string.format("w=%d", _w))
    end
    if _h then
        _string = string.gsub(_string, "h=%d+", string.format("h=%d", _h))
    end
    if _valign then
        _string = string.gsub(_string, "valign=%d+", string.format("valign=%d", _valign))
    end
    if _font then
        _string = string.gsub(_string, "font=%d+", string.format("font=%d", _font))
    end
    if _postype then
        _string = string.gsub(_string, "postype=%d+", string.format("postype=%d", _postype))
    end
    local hwnd = _AppendItem(_parent, _string, _name)
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    self:text(_text or "")
    self:pos(_x, _y + 1)
    if _parent._addon then
        _parent = _parent:handle()
    end
    _parent:FormatAllItemPos()
end

-- 设置或获取 ItemLabel 文本
function ItemLabel:text(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetText(...)
        return self
    end
    return self._this:GetText()
end

-- 设置或获取 ItemLabel 字体
function ItemLabel:font(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetFontScheme(...)
        return self
    end
    return self._this:GetFontScheme()
end

-- 设置或获取 ItemLabel 垂向位置
function ItemLabel:valign(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetVAlign(...)
        return self
    end
    return self._this:GetVAlign()
end

-- 设置或获取 ItemLabel 横向位置
function ItemLabel:halign(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetHAlign(...)
        return self
    end
    return self._this:GetHAlign()
end

-- 设置或获取 ItemLabel 行距
function ItemLabel:rowSpacing(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetRowSpacing(...)
        return self
    end
    return self._this:GetRowSpacing()
end

-- 设置或获取 ItemLabel 是否多行
function ItemLabel:multi(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetMultiLine(...)
        return self
    end
    return self._this:IsMultiLine()
end

-- 设置或获取 ItemLabel 是否每行居中
function ItemLabel:center(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetCenterEachLine(...)
        return self
    end
    return self._this:IsCenterEachLine()
end

-- 设置或获取 ItemLabel 是否富文本
function ItemLabel:rich(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetRichText(...)
        return self
    end
    return self._this:IsRichText()
end

-- 设置或获取 ItemLabel 字体缩放
function ItemLabel:scale(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetFontScale(...)
        return self
    end
    return self._this:GetFontScale()
end

-- 设置或获取 ItemLabel 字体ID
function ItemLabel:id(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetFontID(...)
        return self
    end
    return self._this:GetFontID()
end

-- 设置或获取 ItemLabel 字体边框
function ItemLabel:border(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetFontBorder(...)
        return self
    end
    return self._this:GetFontBoder()
end

-- 设置或获取 ItemLabel 字体颜色
function ItemLabel:color(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetFontColor(...)
        return self
    end
    return self._this:GetFontColor()
end

-- 设置或获取 ItemLabel 字体间距
function ItemLabel:spacing(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetFontSpacing(...)
        return self
    end
    return self._this:GetFontSpacing()
end

-- Image 组件类，继承自 ItemBase 基础组件类
local ItemImage = class(ItemBase)

-- 构造 ItemImage 组件
function ItemImage:ctor(_parent, _xml)
    assert(_parent ~= nil and _xml ~= nil, PARA_ERROR)

    local parser = XmlParser:ParseXmlText(_xml)
    local _name = parser.Image["@name"]
    local _lockshowhide = parser.Image["@lockshowhide"]
    local _eventid = parser.Image["@eventid"]
    local _postype = parser.Image["@postype"]
    local _image = parser.Image["@image"]
    local _frame = parser.Image["@frame"]
    local _w = parser.Image["@w"]
    local _h = parser.Image["@h"]
    local _x = parser.Image["@x"] or 0
    local _y = parser.Image["@y"] or 0

    local _string = "<image>w=100 h=100 postype=0 lockshowhide=0 eventid=0 </image>"
    if _w then
        _string = string.gsub(_string, "w=%d+", string.format("w=%d", _w))
    end
    if _h then
        _string = string.gsub(_string, "h=%d+", string.format("h=%d", _h))
    end
    if _postype then
        _string = string.gsub(_string, "postype=%d+", string.format("postype=%d", _postype))
    end
    if _lockshowhide then
        _string = string.gsub(_string, "lockshowhide=%d+", string.format("lockshowhide=%d", _lockshowhide))
    end
    if _eventid then
        _string = string.gsub(_string, "eventid=%d+", string.format("eventid=%d", _eventid))
    end
    local hwnd = _AppendItem(_parent, _string, _name)
    self._this = hwnd
    self:this(self._this)
    self:parent(_parent)
    if _image then
        local _image = _image
        local _frame = _frame or nil
        self:setImage(_image, _frame)
    end
    self:pos(_x, _y)
    if _parent._addon then
        _parent = _parent:handle()
    end
    _parent:FormatAllItemPos()

    self._this.OnItemMouseEnter = function()
        self:fireEvent("enter")
    end
    self._this.OnItemMouseLeave = function()
        self:fireEvent("leave")
    end
    self._this.OnItemLButtonClick = function()
        self:fireEvent("click")
    end
end

-- 设置或获取 ItemImage 帧数
function ItemImage:frame(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetFrame(...)
        return self
    end
    return self._this:GetFrame()
end

-- 设置或获取 ItemImage 图片类型
function ItemImage:setType(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetImageType(...)
        return self
    end
    return self._this:GetImageType()
end

-- 设置或获取 ItemImage 图片百分比
function ItemImage:percentage(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetPercentage(...)
        return self
    end
    return self._this:GetPercentage()
end

-- 设置或获取 ItemImage 旋转度
function ItemImage:rotate(...)
    local t = { ... }
    if #t > 0 then
        self._this:SetRotate(...)
        return self
    end
    return self._this:GetRotate()
end

-- 获取 ItemImage 图片ID
function ItemImage:id()
    return self._this:GetImageID()
end

-- 设置 ItemImage 图片
function ItemImage:fromUITex(...)
    self._this:FromUITex(...)
    return self
end

-- 设置 ItemImage 图片
function ItemImage:fromTextureFile(...)
    self._this:FromTextureFile(...)
    return self
end

-- 设置 ItemImage 图片
function ItemImage:fromScene(...)
    self._this:FromScene(...)
    return self
end

-- 设置 ItemImage 图片
function ItemImage:fromImageID(...)
    self._this:FromImageID(...)
    return self
end

-- 设置 ItemImage 图片
function ItemImage:fromIconID(...)
    self._this:FromIconID(...)
    return self
end

-- 设置 ItemImage 图片
function ItemImage:setImage(_image, _frame)
    if type(_image) == "string" then
        if _frame then
            if type(_frame) == "string" then
                _frame = tonumber(_frame)
            end
            self:fromUITex(_image, _frame)
        else
            self:fromTextureFile(_image)
        end
    elseif type(_image) == "number" then
        self:fromIconID(_image)
    end
    return self
end

function Kimochi(...)
    local t = { ... }
    local parent, xml = nil, nil
    if #t == 1 then
        xml = t[1]
    else
        parent, xml = t[1], t[2]
    end
    local parser = XmlParser:ParseXmlText(xml)
    for k, v in pairs(parser) do
        if k == "Frame" then
            return WndFrame.new(xml)
		elseif k == "Window" then
            return WndWindow.new(parent, xml)
		elseif k == "PageSet" then
            return WndPageSet.new(parent, xml)
        elseif k == "Button" then
            return WndButton.new(parent, xml)
        elseif k == "TextBox" then
            return WndTextBox.new(parent, xml)
        elseif k == "CheckBox" then
            return WndCheckBox.new(parent, xml)
        elseif k == "ComboBox" then
            return WndComboBox.new(parent, xml)
        elseif k == "RadioBox" then
            return WndRadioBox.new(parent, xml)
		elseif k == "TabBox" then
            return WndTabBox.new(parent, xml)
        elseif k == "TrackBar" then
            return WndTrackBar.new(parent, xml)
        elseif k == "ColorBox" then
            return WndColorBox.new(parent, xml)
        elseif k == "Label" then
            return ItemLabel.new(parent, xml)
        elseif k == "Image" then
            return ItemImage.new(parent, xml)
        end
    end
end
