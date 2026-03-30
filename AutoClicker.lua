local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService  = game:GetService("TweenService")
local RunService    = game:GetService("RunService")
local GuiService    = game:GetService("GuiService")
local VIM          = game:GetService("VirtualInputManager")
local CoreGui      = (gethui and gethui()) or game:GetService("CoreGui")

local Theme = {
    MainBg      = Color3.fromRGB(12, 6, 6),
    PanelBg     = Color3.fromRGB(25, 12, 12),
    Accent      = Color3.fromRGB(220, 0, 0),
    AccentGlow  = Color3.fromRGB(255, 60, 60),
    TextPrimary = Color3.fromRGB(255, 255, 255),
    TextDim     = Color3.fromRGB(160, 100, 100),
    Border      = Color3.fromRGB(65, 25, 25),
    FontBold    = Enum.Font.GothamBold,
    FontMedium  = Enum.Font.GothamMedium
}

local Anim = {
    Decisive = TweenInfo.new(0.55, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
    Fast     = TweenInfo.new(0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Spring   = TweenInfo.new(0.65, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Pulse    = TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
    Shimmer  = TweenInfo.new(2.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1)
}

local State = {
    IsRunning     = false,
    IsPicking     = false,
    IsDestroyed   = false,
    IsMinimized   = false,
    ClickMode     = "QUEUE",
    ClickThread   = nil,
    PositionQueue = {},
    Connections   = {},
    WindowPos     = UDim2.new(0.5, -240, 0.5, -155),
    IconPos       = UDim2.new(0.9, 0, 0.8, 0)
}

local function Terminate()
    State.IsRunning = false
    if State.ClickThread then task.cancel(State.ClickThread); State.ClickThread = nil end
end

local function Cleanup()
    State.IsDestroyed = true; Terminate()
    for _, c in ipairs(State.Connections) do if c then c:Disconnect() end end
    table.clear(State.Connections)
end

pcall(function() if CoreGui:FindFirstChild("DiabloAlpha") then CoreGui.DiabloAlpha:Destroy() end end)

local function create(className, props, parent)
    local inst = Instance.new(className)
    for k, v in pairs(props) do inst[k] = v end
    if parent then inst.Parent = parent end
    return inst
end

local function addCorner(p, r) create("UICorner", { CornerRadius = UDim.new(0, r or 12) }, p) end
local function addStroke(p, c, t) return create("UIStroke", { Color = c or Theme.Border, Thickness = t or 1.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, p) end

local function makeDraggable(part, target, key)
    local dragIndex, dragInput, dragStart, startPos
    table.insert(State.Connections, part.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragIndex = true; dragStart = inp.Position; startPos = target.Position
            inp.Changed:Connect(function() if inp.UserInputState == Enum.UserInputState.End then dragIndex = false end end)
        end
    end))
    table.insert(State.Connections, UIS.InputChanged:Connect(function(inp) if inp.UserInputType == Enum.UserInputType.MouseMovement then dragInput = inp end end))
    table.insert(State.Connections, RunService.RenderStepped:Connect(function()
        if dragIndex and dragInput then
            local pos = UDim2.new(startPos.X.Scale, startPos.X.Offset + (dragInput.Position - dragStart).X, startPos.Y.Scale, startPos.Y.Offset + (dragInput.Position - dragStart).Y)
            target.Position = pos; if key then State[key] = pos end
        end
    end))
end

local ScreenGui = create("ScreenGui", { Name = "DiabloAlpha", ResetOnSpawn = false, DisplayOrder = 9999 }, CoreGui)
ScreenGui.Destroying:Connect(Cleanup)

local Icon = create("Frame", { Name = "Icon", Size = UDim2.new(0, 48, 0, 48), Position = State.IconPos, BackgroundTransparency = 1, Visible = false, Parent = ScreenGui })
addCorner(Icon, 24); addStroke(Icon, Theme.Accent, 2)
create("TextLabel", { Text = "🖱️", Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, TextSize = 24, Parent = Icon })
local IconBtn = create("TextButton", { Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, Text = "", Parent = Icon })
makeDraggable(IconBtn, Icon, "IconPos")

local Main = create("CanvasGroup", { Name = "Main", Size = UDim2.new(0, 480, 0, 315), Position = State.WindowPos, BackgroundColor3 = Theme.MainBg, GroupTransparency = 1, Parent = ScreenGui })
addCorner(Main, 14); local MainStroke = addStroke(Main, Theme.Accent, 1)

local TitleBar = create("Frame", { Size = UDim2.new(1, 0, 0, 50), BackgroundColor3 = Theme.PanelBg, Parent = Main })
addCorner(TitleBar, 14)
local HeaderLabel = create("TextLabel", { Text = "Auto Clicker By. Diablo", Size = UDim2.new(1, -150, 1, 0), Position = UDim2.new(0, 20, 0, 0), BackgroundTransparency = 1, TextColor3 = Theme.Accent, TextSize = 15, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = TitleBar })
local Shimmer = create("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Theme.Accent), ColorSequenceKeypoint.new(0.5, Theme.TextPrimary), ColorSequenceKeypoint.new(1, Theme.Accent) }), Offset = Vector2.new(-1, 0), Parent = HeaderLabel })
TweenService:Create(Shimmer, Anim.Shimmer, {Offset = Vector2.new(1, 0)}):Play()
makeDraggable(TitleBar, Main, "WindowPos")

local ControlBar = create("Frame", { Size = UDim2.new(0, 85, 1, 0), Position = UDim2.new(1, -95, 0, 0), BackgroundTransparency = 1, Parent = TitleBar })
local MiniBtn = create("TextButton", { Text = "−", Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 0, 0.5, -19), BackgroundTransparency = 1, TextColor3 = Theme.TextPrimary, TextSize = 22, Parent = ControlBar })
local CloseBtn = create("TextButton", { Text = "X", Size = UDim2.new(0, 38, 0, 38), Position = UDim2.new(0, 42, 0.5, -19), BackgroundTransparency = 1, TextColor3 = Theme.TextPrimary, TextSize = 16, Font = Theme.FontBold, Parent = ControlBar })

local StatusLabel = create("TextLabel", { Text = "READY", Size = UDim2.new(1, -40, 0, 30), Position = UDim2.new(0, 22, 1, -38), BackgroundTransparency = 1, TextColor3 = Theme.Accent, TextSize = 9, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = Main })

local function WriteStatus(msg)
    StatusLabel.Text = ""
    for i = 1, #msg do StatusLabel.Text = string.sub(msg, 1, i); task.wait(0.012) end
end

local function makeTactileBtn(text, parent, x, y, w, h, cb, isAccent)
    local b = create("TextButton", { Text = text, Size = UDim2.new(0, w, 0, h), Position = UDim2.new(0, x, 0, y), BackgroundColor3 = isAccent and Theme.Accent or Theme.PanelBg, TextColor3 = Theme.TextPrimary, TextSize = 10, Font = Theme.FontBold, AutoButtonColor = false, Parent = parent })
    addCorner(b, 10); local st = addStroke(b, isAccent and Theme.AccentGlow or Theme.Border)
    b.MouseEnter:Connect(function() TweenService:Create(st, Anim.Fast, {Color = Theme.AccentGlow, Thickness = 2.5}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(st, Anim.Fast, {Color = isAccent and Theme.AccentGlow or Theme.Border, Thickness = 1.5}):Play() end)
    b.MouseButton1Down:Connect(function() TweenService:Create(b, Anim.Fast, {Position = UDim2.new(0, x, 0, y+3)}):Play() end)
    b.MouseButton1Up:Connect(function() TweenService:Create(b, Anim.Fast, {Position = UDim2.new(0, x, 0, y)}):Play() end)
    if cb then b.MouseButton1Click:Connect(cb) end
    return b
end

local function makeInp(parent, x, y, w, def)
    local c = create("Frame", { Size = UDim2.new(0, w, 0, 34), Position = UDim2.new(0, x, 0, y), BackgroundColor3 = Theme.PanelBg, Parent = parent })
    addCorner(c, 10); local st = addStroke(c)
    local box = create("TextBox", { Text = tostring(def or ""), Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 7, 0, 0), BackgroundTransparency = 1, TextColor3 = Theme.TextPrimary, TextSize = 12, Font = Theme.FontMedium, Parent = c })
    box.Focused:Connect(function() TweenService:Create(st, Anim.Fast, {Color = Theme.Accent, Thickness = 2}):Play() end)
    box.FocusLost:Connect(function() TweenService:Create(st, Anim.Fast, {Color = Theme.Border, Thickness = 1.5}):Play() end)
    return box
end

local Container = create("Frame", { Size = UDim2.new(1, -40, 1, -95), Position = UDim2.new(0, 20, 0, 65), BackgroundTransparency = 1, Parent = Main })
local Left = create("Frame", { Size = UDim2.new(0, 160, 1, 0), BackgroundColor3 = Theme.PanelBg, BackgroundTransparency = 0.5, Parent = Container }); addCorner(Left, 12)
local Right = create("Frame", { Size = UDim2.new(1, -175, 1, 0), Position = UDim2.new(0, 175, 0, 0), BackgroundColor3 = Theme.PanelBg, BackgroundTransparency = 0.5, Parent = Container }); addCorner(Right, 12)

local ModeBtn = makeTactileBtn("MODE: QUEUE", Left, 15, 12, 130, 30, nil, false)
local StartBtn = makeTactileBtn("START STRIKE", Left, 15, 65, 130, 42, nil, true)
local AbortBtn = makeTactileBtn("STOP [F6]", Left, 15, 118, 130, 34, nil, false)
local RepIn = makeInp(Left, 85, 165, 60, "1"); create("TextLabel", { Text = "REPS:", Position = UDim2.new(0, 15, 0, 165), Size = UDim2.new(0, 70, 0, 34), BackgroundTransparency = 1, TextColor3 = Theme.TextDim, TextSize = 10, Font = Theme.FontBold, Parent = Left })

local XIn = makeInp(Right, 35, 18, 50, "0"); local YIn = makeInp(Right, 115, 18, 50, "0")
local PickBtn = makeTactileBtn("PICK", Right, 175, 18, 45, 34, nil, false); local AddBtn = makeTactileBtn("ADD", Right, 226, 18, 42, 34, nil, true)
local SlpIn = makeInp(Right, 85, 60, 65, "500"); create("TextLabel", { Text = "DELAY (MS):", Position = UDim2.new(0,10,0,60), Size = UDim2.new(0,70,0,34), BackgroundTransparency = 1, TextColor3 = Theme.TextDim, TextSize = 9, Font = Theme.FontBold, Parent = Right })
local Scroll = create("ScrollingFrame", { Size = UDim2.new(1, -24, 1, -110), Position = UDim2.new(0, 12, 0, 105), BackgroundColor3 = Theme.MainBg, BackgroundTransparency = 0.4, CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 1, Parent = Right }); addCorner(Scroll, 10); create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = Scroll })

local function Morph()
    local isFollow = (State.ClickMode == "FOLLOW")
    ModeBtn.Text = isFollow and "MODE: FOLLOW" or "MODE: QUEUE"
    TweenService:Create(Right, Anim.Fast, {GroupTransparency = isFollow and 1 or 0}):Play()
    Right.Visible = not isFollow; WriteStatus(isFollow and "READY (MOUSE TRACKING)" or "READY (POINT QUEUE)")
end
ModeBtn.MouseButton1Click:Connect(function() State.ClickMode = (State.ClickMode == "QUEUE") and "FOLLOW" or "QUEUE"; Morph() end)

local function Sync()
    for _, item in ipairs(Scroll:GetChildren()) do if item:IsA("Frame") then item:Destroy() end end
    for i, d in ipairs(State.PositionQueue) do
        local r = create("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.PanelBg, Parent = Scroll }); addCorner(r, 8)
        create("TextLabel", { Text = string.format("[%d] (%d, %d) | %dms", i, d.x, d.y, d.delay), Size = UDim2.new(1,-40,1,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1, TextColor3 = Theme.TextPrimary, TextSize = 9, Parent = r })
        makeTactileBtn("X", r, 222, 6, 20, 20, function() table.remove(State.PositionQueue, i); Sync() end)
    end
    Scroll.CanvasSize = UDim2.new(0,0,0,#State.PositionQueue*40)
end

PickBtn.MouseButton1Click:Connect(function()
    if State.IsPicking then return end
    State.IsPicking = true; WriteStatus("CHOOSE COORDINATES...")
    local c; c = UIS.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            local p = UIS:GetMouseLocation()
            XIn.Text, YIn.Text = math.floor(p.X), math.floor(p.Y)
            State.IsPicking = false; c:Disconnect(); WriteStatus("COORDS CAPTURED")
            local py = create("Frame", { Size=UDim2.new(0,0,0,0), Position=UDim2.new(0,p.X,0,p.Y), BackgroundColor3=Theme.Accent, AnchorPoint=Vector2.new(0.5,0.5), Parent=ScreenGui })
            addCorner(py,100); addStroke(py, Theme.AccentGlow, 2); TweenService:Create(py, Anim.Decisive, {Size=UDim2.new(0,100,0,100), BackgroundTransparency=1}):Play(); task.delay(0.5, function() if py then py:Destroy() end end)
        end
    end); table.insert(State.Connections, c)
end)

AddBtn.MouseButton1Click:Connect(function() local x,y,sl = tonumber(XIn.Text), tonumber(YIn.Text), tonumber(SlpIn.Text) or 500; if x and y then table.insert(State.PositionQueue, {x=x, y=y, delay=sl}); Sync(); WriteStatus("POINT REGISTERED") end end)

local function Stop() State.IsRunning = false; if State.ClickThread then task.cancel(State.ClickThread) end; WriteStatus("STRIKE TERMINATED"); pcall(function() if State.Pulse then State.Pulse:Cancel() end end); TweenService:Create(MainStroke, Anim.Fast, {Color=Theme.Accent, Thickness=1}):Play() end

local function Start()
    if State.IsRunning or State.IsDestroyed or (State.ClickMode == "QUEUE" and #State.PositionQueue == 0) then return end
    State.IsRunning = true; State.Pulse = TweenService:Create(MainStroke, Anim.Pulse, {Color=Theme.AccentGlow, Thickness=3.5}); State.Pulse:Play()
    local rL = tonumber(RepIn.Text) or 1; local isInf = (rL == 0); local delayVal = tonumber(SlpIn.Text) or 500
    State.ClickThread = task.spawn(function()
        local cur = 0
        while State.IsRunning and (isInf or cur < rL) do
            cur = cur + 1
            if State.ClickMode == "FOLLOW" then
                local p = UIS:GetMouseLocation()
                WriteStatus(isInf and string.format("[INF] ROUND: %d | ACTIVE", cur) or string.format("REP: %d/%d | ACTIVE", cur, rL))
                VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 1); if delayVal >= 15 then task.wait(0.01) end; VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 1)
                if delayVal > 0 then task.wait(delayVal/1000) end
            else
                for idx, d in ipairs(State.PositionQueue) do
                    if not State.IsRunning then break end
                    WriteStatus(string.format("REP: %d/%d | PATH: #%d", cur, rL, idx))
                    VIM:SendMouseButtonEvent(d.x, d.y, 0, true, game, 1); if d.delay >= 15 then task.wait(0.01) end; VIM:SendMouseButtonEvent(d.x, d.y, 0, false, game, 1)
                    if d.delay > 0 then task.wait(d.delay/1000) end
                end
            end
        end
        Stop()
    end)
end

StartBtn.MouseButton1Click:Connect(Start); AbortBtn.MouseButton1Click:Connect(Stop)
table.insert(State.Connections, UIS.InputBegan:Connect(function(i, g) if not g and not State.IsDestroyed then if i.KeyCode == Enum.KeyCode.F4 then if State.IsRunning then Stop() else Start() end elseif i.KeyCode == Enum.KeyCode.F6 then Stop() end end end))

MiniBtn.MouseButton1Click:Connect(function() State.IsMinimized = true; TweenService:Create(Main, Anim.Decisive, {GroupTransparency = 1, Size = UDim2.new(0, 0, 0, 0), Position = State.IconPos}):Play(); task.delay(0.3, function() Main.Visible = false; Icon.Visible = true; Icon.Size = UDim2.new(0, 0, 0, 0); TweenService:Create(Icon, Anim.Spring, {Size = UDim2.new(0, 48, 0, 48)}):Play() end) end)
IconBtn.MouseButton1Click:Connect(function() if State.IsMinimized then State.IsMinimized = false; TweenService:Create(Icon, Anim.Fast, {Size = UDim2.new(0, 0, 0, 0)}):Play(); task.delay(0.2, function() Icon.Visible = false; Main.Visible = true; Main.Position = Icon.Position; TweenService:Create(Main, Anim.Spring, {GroupTransparency = 0, Size = UDim2.new(0, 480, 0, 315), Position = State.WindowPos}):Play() end) end end)
CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

Main.Size = UDim2.new(0, 0, 0, 0); Main.Position = UDim2.new(0.5, 0, 0.5, 0)
TweenService:Create(Main, Anim.Spring, {GroupTransparency = 0, Size = UDim2.new(0, 480, 0, 315), Position = State.WindowPos}):Play()
task.wait(0.12); Left.Position = UDim2.new(0, -60, 0, 0); TweenService:Create(Left, Anim.Spring, {Position = UDim2.new(0, 0, 0, 0)}):Play()
task.wait(0.12); Right.Position = UDim2.new(0, 225, 0, 0); TweenService:Create(Right, Anim.Spring, {Position = UDim2.new(0, 175, 0, 0)}):Play()
