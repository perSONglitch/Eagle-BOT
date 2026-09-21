local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local VirtualInputManager = nil
pcall(function()
    VirtualInputManager = game:GetService("VirtualInputManager")
end)
local bot = Players.LocalPlayer
local camera = workspace.CurrentCamera
local MASTER_NAME = (tostring(getgenv().JARVIS_SAVED_OWNER or ""))
local HOST_NAME = ""
local ROLE = nil
JARVIS_KX_ADMIN_ENABLED = true
local PREFIX = "'"
local CMD_PREFIX = "'"

-- JARVIS LOCAL OWNER CONFIG (Volt workspace)
-- Saved locally on this PC in Volt's workspace and reused on future executions.
;(function()
    local ENV = getgenv()
    local FOLDER = "JARVIS"
    local FILE = FOLDER .. "/owner.txt"

    local function clean(v)
        return tostring(v or ""):gsub("^%s+", ""):gsub("%s+$", "")
    end

    local function saveOwner(name)
        name = clean(name)
        if name == "" then
            return false
        end
        if not isfolder(FOLDER) then
            makefolder(FOLDER)
        end
        writefile(FILE, name)
        ENV.JARVIS_SAVED_OWNER = name
        return true
    end

    local function loadOwner()
        if isfile(FILE) then
            local ok, value = pcall(readfile, FILE)
            if ok then
                value = clean(value)
                if value ~= "" then
                    ENV.JARVIS_SAVED_OWNER = value
                    return value
                end
            end
        end
        return nil
    end

    loadOwner()

    -- Public helpers so the rest of JARVIS can use the saved owner without
    -- adding more top-level locals to this already-large script.
    ENV.JARVIS_GET_OWNER = function()
        return ENV.JARVIS_SAVED_OWNER
    end
    ENV.JARVIS_SET_OWNER = saveOwner

    -- P opens the local owner menu.
    task.spawn(function()
        local UIS = game:GetService("UserInputService")
        local PlayersService = game:GetService("Players")
        local localPlayer = PlayersService.LocalPlayer
        local gui

        local function openOwnerBox()
            if gui then
                gui:Destroy()
            end

            gui = Instance.new("ScreenGui")
            gui.Name = "JARVIS_OwnerConfig"
            gui.ResetOnSpawn = false
            gui.DisplayOrder = 10050
            gui.Parent = localPlayer:WaitForChild("PlayerGui")

            local frame = Instance.new("Frame")
            frame.Size = UDim2.fromOffset(390, 155)
            frame.Position = UDim2.new(0.5, -195, 0.5, -78)
            frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
            frame.BorderSizePixel = 0
            frame.Parent = gui
            Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

            local title = Instance.new("TextLabel")
            title.BackgroundTransparency = 1
            title.Size = UDim2.new(1,-24,0,32)
            title.Position = UDim2.fromOffset(12,8)
            title.Font = Enum.Font.GothamBold
            title.TextSize = 16
            title.TextColor3 = Color3.new(1,1,1)
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.Text = "JARVIS Owner"
            title.Parent = frame

            local current = Instance.new("TextLabel")
            current.BackgroundTransparency = 1
            current.Size = UDim2.new(1,-24,0,24)
            current.Position = UDim2.fromOffset(12,38)
            current.Font = Enum.Font.Gotham
            current.TextSize = 13
            current.TextColor3 = Color3.fromRGB(180,180,185)
            current.TextXAlignment = Enum.TextXAlignment.Left
            current.Text = "Current: " .. tostring(ENV.JARVIS_SAVED_OWNER or "Not set")
            current.Parent = frame

            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1,-116,0,38)
            box.Position = UDim2.fromOffset(12,72)
            box.BackgroundColor3 = Color3.fromRGB(31,31,37)
            box.BorderSizePixel = 0
            box.Font = Enum.Font.Gotham
            box.TextSize = 14
            box.TextColor3 = Color3.new(1,1,1)
            box.PlaceholderColor3 = Color3.fromRGB(145,145,150)
            box.PlaceholderText = "Choose new owner username"
            box.ClearTextOnFocus = false
            box.Text = ""
            box.Parent = frame
            Instance.new("UICorner", box).CornerRadius = UDim.new(0,7)

            local save = Instance.new("TextButton")
            save.Size = UDim2.fromOffset(82,38)
            save.Position = UDim2.new(1,-94,0,72)
            save.BackgroundColor3 = Color3.fromRGB(48,48,58)
            save.BorderSizePixel = 0
            save.Font = Enum.Font.GothamBold
            save.TextSize = 13
            save.TextColor3 = Color3.new(1,1,1)
            save.Text = "SAVE"
            save.Parent = frame
            Instance.new("UICorner", save).CornerRadius = UDim.new(0,7)

            local hint = Instance.new("TextLabel")
            hint.BackgroundTransparency = 1
            hint.Size = UDim2.new(1,-24,0,25)
            hint.Position = UDim2.fromOffset(12,118)
            hint.Font = Enum.Font.Gotham
            hint.TextSize = 12
            hint.TextColor3 = Color3.fromRGB(145,145,150)
            hint.TextXAlignment = Enum.TextXAlignment.Left
            hint.Text = "P = close  •  saved only in this Volt workspace"
            hint.Parent = frame

            local function commit()
                local name = clean(box.Text)
                if name ~= "" and saveOwner(name) then
                    current.Text = "Current: " .. name
                    box.Text = ""
                    print("[JARVIS] owner saved locally:", name)
                end
            end

            save.MouseButton1Click:Connect(commit)
            box.FocusLost:Connect(function(enter)
                if enter then commit() end
            end)
            task.defer(function() box:CaptureFocus() end)
        end

        UIS.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.P then
                if gui and gui.Parent then
                    gui:Destroy()
                    gui = nil
                else
                    openOwnerBox()
                end
            end
        end)
    end)
end)()
local DOT = "."
local PRISON_SPEED = 29
local OUTSIDE_SPEED = 90
local MIN_SPEED = 1
local MAX_SPEED = 150
local PRISON_BOUNDS = {
    minX = 470,
    maxX = 1040,
    minZ = 2160,
    maxZ = 2660,
}
local FOLLOW_DIST = 4
local SIDE = 4
local PUNCH_SAFE = 14
local CAR_SPAWNER_POSITION = Vector3.new(624.152, 98.403, 2495.038)
local CAR_SPAWN_REMOTE_NAME = "CarSpawn"
local CAR_BUTTON_RADIUS = 40
local CAR_SEARCH_RADIUS = 100
local CAR_MOVE_TEST_TIME = 0.9
local CAR_MOVE_THRESHOLD = 1.25
local CAR_SEAT_RETRY_DELAY = 0.35
local INVIS_DEPTH = 8
local followDistance = FOLLOW_DIST
local sideDistance = SIDE
local cloakDepth = INVIS_DEPTH
local followVerticalOffset = 0
local savedMarks = {}
local freezeCFrame = nil
local MAX_SLOTS = 8
local FORMATION_BACK = 4
local FORMATION_SIDE = 4
local FORMATION_ROW = 3.5
local DEFAULT_ORBIT_RADIUS = 10
local MIN_ORBIT_RADIUS = 4
local MAX_ORBIT_RADIUS = 50
local PATROL_RADIUS = 18
local SCOUT_DISTANCE = 35
local STUCK_TIME = 2
local STUCK_DISTANCE = 0.5
local SLOT_MAP = {
}
local masterLower = ""
local IS_LEADER = false
local extraOwners = {}
local sharedAccessLevel = {}
local revokedOwners = {}
JARVIS_WHITELIST = JARVIS_WHITELIST or {
}
local mySlot = IS_LEADER and 0 or 1
local manualSlot = nil
local shut = false
local mode = "idle"
local hiddenLock = false
local HIDE_CFRAME = CFrame.new(874.332336, 116.509766, 2419.012939, -0.883117, 0.000000, 0.469153, 0.000000, 1.000000, -0.000000, -0.469153, -0.000000, -0.883117)
local targetPlayer = nil
local followCamPlayer = nil
local flying = false
local spinning = false
local frozen = false
local punchOn = false
local protecting = false
local protectedPlayer = nil
local followPosition = "center"
local invisFollow = false
local invisPosition = nil
JARVIS_CLOAK_RELEASE_UNTIL = 0
JARVIS_CLOAK_DEADZONE = 1.35
JARVIS_CLOAK_SPEED = 22
JARVIS_CLOAK_ADMIN_RELEASE = 1.35
JARVIS_CLOAK_COMBAT_RELEASE = 2.10
JARVIS_FOLLOW_RELEASE_UNTIL = JARVIS_FOLLOW_RELEASE_UNTIL or 0
JARVIS_FOLLOW_DEADZONE = JARVIS_FOLLOW_DEADZONE or 1.6
JARVIS_FOLLOW_SPEED = JARVIS_FOLLOW_SPEED or 18
JARVIS_FOLLOW_ADMIN_RELEASE = JARVIS_FOLLOW_ADMIN_RELEASE or 1.35
JARVIS_FOLLOW_COMBAT_RELEASE = JARVIS_FOLLOW_COMBAT_RELEASE or 2.35
JARVIS_IDLE_HOLD_CFRAME = JARVIS_IDLE_HOLD_CFRAME or nil
JARVIS_CLOAK_Y_HOLD_NAME = "JARVIS_CloakYHold"
local flySpeed = PRISON_SPEED
local manualSpeedOverride = false
local groundLock = true
local noclipOn = false
local NoclipParts = {}
local Noclipping = nil
local noSit = true
local vehicleRoutineActive = false
local carFlingBusy = false
local rejoinAttempted = false
local camLocked = false
local sayBusy = false
local sayQ = {}
local CHAT_MIN_DELAY = 1.05
local CHAT_MAX_DELAY = 4.00
local CHAT_BACKOFF = 0.40
local CHAT_RECOVERY_STEP = 0.025
local adaptiveChatDelay = 1.15
local lastChatFloodAt = -math.huge
local chatMessagesSent = 0
local didJoinFly = false
local lastHash = ""
local lastAt = 0
local usingTextChat = false
local lastRevenge = {}
local ownerTeamStrikes = {}
local protectionConnection = nil
local protectionCharacterConnection = nil
local protectionConnections = {}
local orbiting = false
local orbitTarget = nil
local orbitAngle = 0
local orbitRadius = DEFAULT_ORBIT_RADIUS
local dancing = false
local danceTime = 0
local guardMode = false
local patrolOrigin = nil
local patrolAngle = 0
local scoutOrigin = nil
local scoutReturning = false
local formationType = "dynamic"
local JARVIS_CONFIG_VERSION = 2
local JARVIS_CONFIG_FILE = string.format(
    "JARVIS_%s_%s.json",
    tostring(game.PlaceId),
    tostring(bot.UserId)
)
local JARVIS_FS = {
    read = type(readfile) == "function",
    write = type(writefile) == "function",
    exists = type(isfile) == "function",
}
local persistentLastEncoded = nil
local persistentLoaded = false
local persistentSaveBusy = false
local function persistentCanUse()
    return JARVIS_FS.read and JARVIS_FS.write
end
local function serializeCFrame(cf)
    if typeof(cf) ~= "CFrame" then
        return nil
    end
    return {cf:GetComponents()}
end
local function deserializeCFrame(data)
    if type(data) ~= "table" or #data ~= 12 then
        return nil
    end
    local ok, cf = pcall(CFrame.new, table.unpack(data))
    return ok and cf or nil
end
local function buildPersistentState()
    local marks = {}
    for name, cf in pairs(savedMarks) do
        local encoded = serializeCFrame(cf)
        if encoded then
            marks[name] = encoded
        end
    end
    return {
        version = JARVIS_CONFIG_VERSION,
        role = ROLE,
        hostName = HOST_NAME,
        whitelist = JARVIS_WHITELIST,
        extraOwners = extraOwners,
        sharedAccessLevel = sharedAccessLevel,
        revokedOwners = revokedOwners,
        followDistance = followDistance,
        sideDistance = sideDistance,
        cloakDepth = cloakDepth,
        followVerticalOffset = followVerticalOffset,
        followPosition = followPosition,
        formationType = formationType,
        noSit = noSit,
        shut = shut,
        manualSlot = manualSlot,
        manualSpeedOverride = manualSpeedOverride,
        flySpeed = flySpeed,
        kxAdminEnabled = JARVIS_KX_ADMIN_ENABLED,
        marks = marks,
    }
end
local function savePersistentState(force)
    if not persistentCanUse() or persistentSaveBusy then
        return false
    end
    persistentSaveBusy = true
    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(buildPersistentState())
    end)
    if ok and encoded and (force or encoded ~= persistentLastEncoded) then
        ok = pcall(function()
            writefile(JARVIS_CONFIG_FILE, encoded)
        end)
        if ok then
            persistentLastEncoded = encoded
        end
    end
    persistentSaveBusy = false
    return ok == true
end
local function loadPersistentState()
-- Protection is session-only. Never resume it after execute/rejoin.
protecting = false
protectedPlayer = nil
targetPlayer = nil

    if persistentLoaded or not persistentCanUse() then
        return false
    end
    persistentLoaded = true
    if JARVIS_FS.exists then
        local existsOk, exists = pcall(isfile, JARVIS_CONFIG_FILE)
        if not existsOk or not exists then
            return false
        end
    end
    local readOk, raw = pcall(readfile, JARVIS_CONFIG_FILE)
    if not readOk or type(raw) ~= "string" or raw == "" then
        return false
    end
    local decodeOk, data = pcall(function()
        return HttpService:JSONDecode(raw)
    end)
    if not decodeOk or type(data) ~= "table" then
        return false
    end
    if type(data.role) == "string" and (data.role == "host" or data.role == "bot") then
        ROLE = data.role
    end
    if type(data.hostName) == "string" and data.hostName ~= "" then
        HOST_NAME = data.hostName
    end
    if type(data.whitelist) == "table" then
        table.clear(JARVIS_WHITELIST)
        for name, enabled in pairs(data.whitelist) do
            if type(name) == "string" and enabled == true then
                JARVIS_WHITELIST[name:lower()] = true
            end
        end
    end
    if type(data.extraOwners) == "table" then
        table.clear(extraOwners)
        for name, enabled in pairs(data.extraOwners) do
            if type(name) == "string" and enabled == true then
                extraOwners[name:lower()] = true
            end
        end
    end
    if type(data.sharedAccessLevel) == "table" then
        table.clear(sharedAccessLevel)
        for name, level in pairs(data.sharedAccessLevel) do
            if type(name) == "string" and (level == 1 or level == 2) then
                sharedAccessLevel[name:lower()] = level
            end
        end
    end
    if type(data.revokedOwners) == "table" then
        table.clear(revokedOwners)
        for name, enabled in pairs(data.revokedOwners) do
            if type(name) == "string" and enabled == true then
                revokedOwners[name:lower()] = true
            end
        end
    end
    if type(data.followDistance) == "number" then followDistance = math.clamp(data.followDistance, 1, 50) end
    if type(data.sideDistance) == "number" then sideDistance = math.clamp(data.sideDistance, 0, 50) end
    if type(data.cloakDepth) == "number" then cloakDepth = math.clamp(data.cloakDepth, 2, 30) end
    if type(data.followVerticalOffset) == "number" then followVerticalOffset = math.clamp(data.followVerticalOffset, -30, 30) end
    if type(data.followPosition) == "string" and (data.followPosition == "left" or data.followPosition == "center" or data.followPosition == "right" or data.followPosition == "front" or data.followPosition == "behind") then
        followPosition = data.followPosition
    end
    if type(data.formationType) == "string" then formationType = data.formationType end
    if type(data.noSit) == "boolean" then noSit = data.noSit end
    if type(data.shut) == "boolean" then shut = data.shut end
    if type(data.manualSlot) == "number" then manualSlot = math.clamp(math.floor(data.manualSlot), 1, MAX_SLOTS) end
    if type(data.manualSpeedOverride) == "boolean" then manualSpeedOverride = data.manualSpeedOverride end
    if type(data.flySpeed) == "number" then flySpeed = math.clamp(data.flySpeed, MIN_SPEED, MAX_SPEED) end
    if type(data.kxAdminEnabled) == "boolean" then JARVIS_KX_ADMIN_ENABLED = data.kxAdminEnabled end
    if type(data.marks) == "table" then
        table.clear(savedMarks)
        for name, encoded in pairs(data.marks) do
            local cf = deserializeCFrame(encoded)
            if type(name) == "string" and cf then
                savedMarks[name] = cf
            end
        end
    end
    targetPlayer = nil
    followCamPlayer = nil
    protectedPlayer = nil
    protecting = false
    hiddenLock = false
    frozen = false
    freezeCFrame = nil
    orbiting = false
    dancing = false
    guardMode = false
    invisFollow = false
    invisPosition = nil
    mode = "idle"
    persistentLastEncoded = raw
    return true
end
loadPersistentState()

local function chooseJarvisRole()
    if ROLE == "host" or ROLE == "bot" then return end
    local pg = bot:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "JARVIS_RoleSelector"
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 9999
    gui.Parent = pg

    local frame = Instance.new("Frame")
    frame.Size = UDim2.fromOffset(360, 190)
    frame.Position = UDim2.new(0.5, -180, 0.5, -95)
    frame.BackgroundColor3 = Color3.fromRGB(18,18,22)
    frame.BorderSizePixel = 0
    frame.Parent = gui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,10)

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1,-20,0,35)
    title.Position = UDim2.fromOffset(10,10)
    title.BackgroundTransparency = 1
    title.Text = "JARVIS — Choose Role"
    title.TextColor3 = Color3.new(1,1,1)
    title.TextSize = 18
    title.Font = Enum.Font.GothamBold
    title.Parent = frame

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1,-30,0,35)
    info.Position = UDim2.fromOffset(15,48)
    info.BackgroundTransparency = 1
    info.Text = "Choose Host if this account controls the bot."
    info.TextColor3 = Color3.fromRGB(190,190,190)
    info.TextSize = 12
    info.Font = Enum.Font.Gotham
    info.TextWrapped = true
    info.Parent = frame

    local host = Instance.new("TextButton")
    host.Size = UDim2.fromOffset(145,48)
    host.Position = UDim2.fromOffset(20,105)
    host.Text = "HOST"
    host.TextSize = 16
    host.Font = Enum.Font.GothamBold
    host.TextColor3 = Color3.new(1,1,1)
    host.BackgroundColor3 = Color3.fromRGB(45,45,55)
    host.Parent = frame
    Instance.new("UICorner", host).CornerRadius = UDim.new(0,7)

    local botBtn = host:Clone()
    botBtn.Text = "BOT"
    botBtn.Position = UDim2.fromOffset(195,105)
    botBtn.Parent = frame

    local selected = false
    local function finish(role)
        if selected then return end
        selected = true
        ROLE = role
        HOST_NAME = role == "host" and bot.Name or ""
        if role == "bot" then
            info.Text = "Enter the Host username in the next box."
        end
    end
    host.MouseButton1Click:Connect(function() finish("host") end)
    botBtn.MouseButton1Click:Connect(function() finish("bot") end)

    repeat task.wait() until selected

    if ROLE == "bot" then
        host:Destroy()
        botBtn:Destroy()
        local box = Instance.new("TextBox")
        box.Size = UDim2.fromOffset(320,48)
        box.Position = UDim2.fromOffset(20,105)
        box.PlaceholderText = "Host username"
        box.Text = ""
        box.TextColor3 = Color3.new(1,1,1)
        box.TextSize = 14
        box.Font = Enum.Font.Gotham
        box.BackgroundColor3 = Color3.fromRGB(30,30,36)
        box.Parent = frame
        Instance.new("UICorner", box).CornerRadius = UDim.new(0,7)
        info.Text = "Host username:"
        box.FocusLost:Wait()
        while box.Text:gsub("%s+","") == "" do
            info.Text = "Please enter the Host username."
            box:CaptureFocus()
            box.FocusLost:Wait()
        end
        HOST_NAME = box.Text:gsub("^%s+",""):gsub("%s+$","")
    end

    MASTER_NAME = HOST_NAME
    masterLower = MASTER_NAME:lower()
    IS_LEADER = ROLE == "host"
    gui:Destroy()
    savePersistentState(true)
end

chooseJarvisRole()
MASTER_NAME = HOST_NAME
masterLower = MASTER_NAME:lower()
IS_LEADER = ROLE == "host"

local function startPersistentSaver()
    if not persistentCanUse() then
        warn("[JARVIS] persistent config unavailable; executor needs readfile/writefile/isfile")
        return
    end
    task.spawn(function()
        while true do
            task.wait(1.5)
            savePersistentState(false)
        end
    end)
end
local lastPosition = nil
local stuckTimer = 0
local sessionCommandCount = 0
local lastCommand = "none"
local LOCAL = {
    follow = true,
    unfollow = true,
    loopfollow = true,
    unloopfollow = true,
    line = true,
    unline = true,
    stop = true,
    idle = true,
    halt = true,
    fly = true,
    unfly = true,
    noclip = true,
    clip = true,
    cam = true,
    view = true,
    uncam = true,
    unview = true,
    reset = true,
    re = true,
    rejoin = true,
    rj = true,
    invis = true,
    invisible = true,
    vis = true,
    uninvis = true,
    visible = true,
    hide = true,
    unhide = true,
    freeze = true,
    unfreeze = true,
    thaw = true,
    panic = true,
    mark = true,
    recall = true,
    marks = true,
    target = true,
    distance = true,
    dist = true,
    face = true,
    front = true,
    behind = true,
    above = true,
    below = true,
    followdist = true,
    sidedist = true,
    cloakdepth = true,
    vertical = true,
    selfcheck = true,
    diag = true,
    diagnostics = true,
    nearest = true,
    near = true,
    untarget = true,
    where = true,
    coords = true,
    recover = true,
    unstuck = true,
    resetoffsets = true,
    settings = true,
    cmdspeed = true,
    park = true,
    unpark = true,
    spin = true,
    unheadsit = true,
    headsit = true,
    unbounce = true,
    unspin = true,
    cmd = true,
    cmds = true,
    help = true,
    commands = true,
    cmdlist = true,
    say = true,
    punchaura = true,
    pa = true,
    share = true,
    share1 = true,
    share2 = true,
    unshare = true,
    owners = true,
    whitelist = true,
    unwhitelist = true,
    wl = true,
    unwl = true,
    shut = true,
    unshut = true,
    slot = true,
    slots = true,
    call = true,
    who = true,
    hello = true,
    hi = true,
    protect = true,
    unprotect = true,
    speed = true,
    autospeed = true,
    formation = true,
    form = true,
    orbit = true,
    unorbit = true,
    spiral = true,
    unspiral = true,
    dance = true,
    undance = true,
    cheer = true,
    laugh = true,
    point = true,
    wave = true,
    salute = true,
    bounce = true,
    guard = true,
    unguard = true,
    scout = true,
    unscout = true,
    patrol = true,
    unpatrol = true,
    surround = true,
    unsurround = true,
    assemble = true,
    regroup = true,
    disperse = true,
    ["return"] = true,
    status = true,
    report = true,
    radio = true,
    personality = true,
    mood = true,
    captain = true,
    sit = true,
    nosit = true,
    stand = true,
    invisfollow = true,
    cloakfollow = true,
    ipa = true,
    invispunchaura = true,
    unipa = true,
    sb = true,
    shootback = true,
    ap = true,
    antipunch = true,
}
local ADMIN = {
    kill = true,
    kick = true,
    loopkill = true,
    lk = true,
    fling = true,
    hitbox = true,
    combo1 = true,
    combo2 = true,
    combo3 = true,
    ragebot = true,
    silentaim = true,
    esp = true,
    m4a1 = true,
    reming = true,
    ak = true,
    riot = true,
    mafia = true,
    serverhop = true,
    hop = true,
    toolaura = true,
    bring = true,
    antifling = true,
}
-- Commands available to users granted access with 'share.
-- Destructive/admin escalation commands such as fling remain owner-only.
-- SHARE LEVELS
-- share1: broad access to normal JARVIS commands, but no fling/carfling.
-- share2: basic harmless commands only.
JARVIS_SHARE2_ALLOWED_COMMANDS = {
    spin=true, unspin=true, bounce=true, unbounce=true, headsit=true, unheadsit=true, dance=true,
    cmds=true, help=true, commands=true, cmdlist=true,
    follow=true, stop=true, line=true,
    nearest=true, untarget=true, where=true, coords=true,
    left=true, center=true, right=true, front=true, behind=true,
    above=true, below=true,
    view=true, unview=true,
    orbit=true, unorbit=true,
    dance=true, cheer=true, laugh=true, point=true,
    status=true, report=true, settings=true,
}

JARVIS_SHARE1_BLOCKED_COMMANDS = {
    fling=true, carfling=true,
}

local COMMAND_HELP = {
    {
        "CORE  follow line stop fly protect punchaura invis vis hide unhide share shut cmds",
        "TARGET  target <player> | nearest | untarget | distance | face <player>",
        "POSITION  left center right front behind above below | park unpark",
    },
    {
        "ADMIN  'k <player> = kill | 'k <player> <2+> = loopkill | 'fling <player>",
        "WEAPONS  .combo1 .combo2 .combo3 .m4a1 .reming .ak",
        "SAFETY  protect [player] = 10-stud orbit guard; same team = punch aura, enemy = .kill | unprotect | panic | recover",
    },
    {
        "FOLLOW  follow [player] / loopfollow [player] / line / left center right",
        "TUNING  followdist <n> / sidedist <n> / vertical <n> / cloakdepth <n>",
        "RESET  resetoffsets restores default follow/side/vertical/cloak values",
    },
    {
        "CLOAK  invis [player] / invisfollow [player] / vis / hide / unhide",
        "FORMATION  dynamic v diamond wall circle columns",
        "SQUAD  assemble regroup disperse line guard surround return",
    },
    {
        "POSITION  mark [name] / recall [name] / marks / freeze / unfreeze",
        "LOCATION  where / coords / distance",
        "CAMERA  .view .unview | 'view <player> | face <player>",
    },
    {
        "FUN  orbit spiral dance [1-3] wave cheer laugh point salute bounce scout patrol spin",
        "CONTROL  share unshare owners | whitelist/wl <player> | unwhitelist/unwl <player>",
        "INFO  status report selfcheck settings radio captain who personality mood",
    },
    {
        "CHAT  cmds [page] / cmdspeed | full list is queued with adaptive pacing",
        "ADMIN  'cmd <full command> keeps every word/argument and forwards it to the bot.",
        "NOCLIP  continuous local noclip | 'noclip enables | 'clip disables",
    },
    {
        "RECOVERY  panic = clean idle reset | recover/unstuck = movement repair",
        "TARGETING  nearest selects closest player; untarget returns target to owner",
        "STATUS  settings shows movement tuning + adaptive chat interval",
    },
}
local function findPlayer(name)
    if not name or name == "" then
        return nil
    end
    name = tostring(name):lower()
    if name == "me" or name == "master" then
        name = masterLower
    end
    local exact
    local prefix
    local partial
    for _, p in ipairs(Players:GetPlayers()) do
        local n = p.Name:lower()
        local d = (p.DisplayName or ""):lower()
        if n == name or d == name then
            exact = p
            break
        end
        if n:sub(1, #name) == name
            or d:sub(1, #name) == name
        then
            prefix = prefix or p
        end
        if n:find(name, 1, true)
            or d:find(name, 1, true)
        then
            partial = partial or p
        end
    end
    return exact or prefix or partial
end
local function getMaster()
    return findPlayer(MASTER_NAME)
end
local function rootOf(plr)
    local character = plr and plr.Character
    return character and character:FindFirstChild("HumanoidRootPart")
end
local function humOf(plr)
    local character = plr and plr.Character
    return character and character:FindFirstChildOfClass("Humanoid")
end
local function headOf(plr)
    local character = plr and plr.Character
    if not character then
        return nil
    end
    return character:FindFirstChild("Head")
        or character:FindFirstChild("HumanoidRootPart")
end
local function myRoot()
    return rootOf(bot)
end
local function myHum()
    return humOf(bot)
end
local noSitConnection = nil
local otherCmd
local function applyNoSitState()
    local hum = myHum()
    if not hum then
        return
    end
    if noSitConnection then
        noSitConnection:Disconnect()
        noSitConnection = nil
    end
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, not noSit)
    if noSit then
        hum.Sit = false
        if hum:GetState() == Enum.HumanoidStateType.Seated then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        noSitConnection = hum.Seated:Connect(function(seated)
            if seated and noSit then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
end
local function setNoSit(on)
    noSit = on == true
    applyNoSitState()
end
local respawnRecoverySerial = 0
local function runRespawnNoclipRecovery(char)
    if IS_LEADER then
        return
    end
    respawnRecoverySerial += 1
    local mySerial = respawnRecoverySerial
    task.spawn(function()
        local activeChar = char or bot.Character
        if not activeChar then
            activeChar = bot.CharacterAdded:Wait()
        end
        local hum = activeChar:WaitForChild("Humanoid", 8)
        local root = activeChar:WaitForChild("HumanoidRootPart", 8)
        if not hum or not root then
            return
        end
        task.wait(0.35)
        if mySerial ~= respawnRecoverySerial or bot.Character ~= activeChar then
            return
        end
        applyNoSitState()
        if frozen and not hiddenLock then
            frozen = false
            freezeCFrame = nil
        end
        if hiddenLock then
            task.wait(0.05)
            local newRoot = myRoot()
            if newRoot then
                newRoot.AssemblyLinearVelocity = Vector3.zero
                newRoot.AssemblyAngularVelocity = Vector3.zero
                newRoot.CFrame = HIDE_CFRAME
            end
        end
    end)
end
bot.CharacterAdded:Connect(function(char)
    runRespawnNoclipRecovery(char)
end)
local function activeTarget()
    if targetPlayer and targetPlayer.Parent then
        return targetPlayer
    end
    return getMaster()
end
local function isMasterTarget()
    local target = activeTarget()
    return target
        and target.Name:lower() == masterLower
end
local function camRoot()
    if followCamPlayer and followCamPlayer.Parent then
        return rootOf(followCamPlayer)
    end
    return rootOf(getMaster())
end
local function isOwnerName(name)
    if not name then
        return false
    end
    name = tostring(name):lower()
    if name == masterLower then
        return true
    end
    if revokedOwners[name] then
        return false
    end
    if extraOwners[name] then
        return true
    end
    local p = findPlayer(name)
    if p then
        local canonical = p.Name:lower()
        if revokedOwners[canonical] then
            return false
        end
        if extraOwners[canonical] then
            return true
        end
        if targetPlayer == p
            and (mode == "follow" or mode == "loopfollow" or invisFollow)
        then
            return true
        end
    end
    return false
end
local function isAlly(p)
    if not p then
        return false
    end
    local n = p.Name:lower()
    if n == masterLower then
        return true
    end
    if n == bot.Name:lower() then
        return true
    end
    if extraOwners[n] then
        return true
    end
    if p:GetAttribute("EagleBot") == true then
        return true
    end
    if n:find("eagletestsubject", 1, true) then
        return true
    end
    return false
end
local function isEagleUnit(p)
    if not p then
        return false
    end
    if p.Name:lower() == masterLower then
        return false
    end
    local n = p.Name:lower()
    if n:find("eagletestsubject", 1, true) then
        return true
    end
    if p:GetAttribute("EagleBot") == true then
        return true
    end
    if extraOwners[n] then
        return true
    end
    return false
end
local function getEagleUnits()
    local units = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if isEagleUnit(p) then
            table.insert(units, p)
        end
    end
    table.sort(units, function(a, b)
        if a.UserId == b.UserId then
            return a.Name:lower() < b.Name:lower()
        end
        return a.UserId < b.UserId
    end)
    return units
end
local function getJarvisNumber()
    if IS_LEADER then
        return 0
    end
    return mySlot
end
local function getJarvisName()
    if IS_LEADER then
        return "JARVIS-MASTER"
    end
    return string.format("JARVIS-%02d", getJarvisNumber())
end
local function getAutomaticSlot()
    if IS_LEADER then
        return 0
    end
    if manualSlot then
        return math.clamp(
            manualSlot,
            1,
            MAX_SLOTS
        )
    end
    local mapped = SLOT_MAP[bot.Name:lower()]
    if mapped then
        return math.clamp(
            mapped,
            1,
            MAX_SLOTS
        )
    end
    local units = getEagleUnits()
    for index, p in ipairs(units) do
        if p == bot then
            return math.clamp(
                index,
                1,
                MAX_SLOTS
            )
        end
    end
    return (math.abs(bot.UserId) % MAX_SLOTS) + 1
end
local function refreshSlot()
    if IS_LEADER then
        mySlot = 0
        return
    end
    mySlot = getAutomaticSlot()
    print(
        "[JARVIS] automatic slot:",
        mySlot
    )
end
local function canTalk()
    return not IS_LEADER
        and not shut
        and mySlot == 1
end
local function isInsidePrison()
    local root = myRoot()
    if not root then
        return false
    end
    local p = root.Position
    return p.X >= PRISON_BOUNDS.minX
        and p.X <= PRISON_BOUNDS.maxX
        and p.Z >= PRISON_BOUNDS.minZ
        and p.Z <= PRISON_BOUNDS.maxZ
end
local function updateAutomaticSpeed()
    if manualSpeedOverride then
        return
    end
    if isInsidePrison() then
        flySpeed = PRISON_SPEED
    else
        flySpeed = OUTSIDE_SPEED
    end
end
local function floorY()
    local masterRoot = rootOf(getMaster())
    if masterRoot then
        return masterRoot.Position.Y
    end
    local me = myRoot()
    if me then
        return me.Position.Y
    end
    return 0
end
local function flatten(v)
    if not v then
        return nil
    end
    if not groundLock then
        return v
    end
    return Vector3.new(
        v.X,
        floorY(),
        v.Z
    )
end
local function say(text)
    if type(text) ~= "string" or text == "" then
        return
    end
    table.insert(sayQ, text)
    if sayBusy then
        return
    end
    sayBusy = true
    task.spawn(function()
        while #sayQ > 0 do
            local line = table.remove(
                sayQ,
                1
            )
            local sent = false
            pcall(function()
                local channels =
                    TextChatService:FindFirstChild(
                        "TextChannels"
                    )
                local channel = channels
                    and (
                        channels:FindFirstChild(
                            "RBXGeneral"
                        )
                        or channels:FindFirstChild(
                            "General"
                        )
                    )
                if channel then
                    channel:SendAsync(line)
                    sent = true
                end
            end)
            if not sent then
                pcall(function()
                    local folder =
                        ReplicatedStorage:FindFirstChild(
                            "DefaultChatSystemChatEvents"
                        )
                    local request =
                        folder
                        and folder:FindFirstChild(
                            "SayMessageRequest"
                        )
                    if request then
                        request:FireServer(
                            line,
                            "All"
                        )
                        sent = true
                    end
                end)
            end
            if sent then
                chatMessagesSent += 1
            end
            if os.clock() - lastChatFloodAt > 12 then
                adaptiveChatDelay = math.max(
                    CHAT_MIN_DELAY,
                    adaptiveChatDelay - CHAT_RECOVERY_STEP
                )
            end
            task.wait(adaptiveChatDelay)
        end
        sayBusy = false
    end)
end
local function voice(text)
    if canTalk() then
        say(text)
    end
end
TextChatService.MessageReceived:Connect(function(msg)
    local ok, text, source = pcall(function()
        return tostring(msg.Text or ""), msg.TextSource
    end)
    if not ok then return end
    local lower = text:lower()
    if source == nil and (
        lower:find("wait before sending another message", 1, true)
        or lower:find("wait before sending", 1, true)
        or lower:find("too many messages", 1, true)
    ) then
        lastChatFloodAt = os.clock()
        adaptiveChatDelay = math.min(
            CHAT_MAX_DELAY,
            adaptiveChatDelay + CHAT_BACKOFF
        )
        warn(string.format(
            "[JARVIS] chat throttle detected; adaptive delay now %.2fs",
            adaptiveChatDelay
        ))
    end
end)
local function findCmdBox()
    local pg = bot:FindFirstChild(
        "PlayerGui"
    )
    if not pg then
        return nil
    end
    for _, inst in ipairs(
        pg:GetDescendants()
    ) do
        if inst:IsA("TextBox") then
            local n = inst.Name:lower()
            if n:find("cmd", 1, true)
                or n:find("command", 1, true)
                or n:find("input", 1, true)
            then
                return inst
            end
        end
    end
    for _, inst in ipairs(
        pg:GetDescendants()
    ) do
        if inst:IsA("TextBox")
            and inst.Visible
        then
            return inst
        end
    end
    return nil
end
otherCmd = function(body, prefixOverride)
    if IS_LEADER then
        return
    end
    if JARVIS_KX_ADMIN_ENABLED == false then
        return
    end
    body = tostring(body or "")
    body = body:gsub("^%s+", "")
    body = body:gsub("%s+$", "")
    if body == "" then
        return
    end
    local rawForRelease = body:gsub("^[%.;]", "")
    local releaseCmd = rawForRelease:match("^(%S+)")
    releaseCmd = releaseCmd and releaseCmd:lower() or ""
    if releaseCmd ~= "invis"
        and releaseCmd ~= "vis"
        and releaseCmd ~= "noclip"
        and releaseCmd ~= "clip"
        and releaseCmd ~= "antifling"
    then
        local combatRelease = {
            combo1 = true, combo2 = true, combo3 = true,
            kill = true, loopkill = true, lk = true,
            fling = true, bring = true, hitbox = true,
            ragebot = true, silentaim = true,
            m4a1 = true, reming = true, ak = true, riot = true, mafia = true,
        }
        local releaseTime =
            combatRelease[releaseCmd]
                and JARVIS_FOLLOW_COMBAT_RELEASE
                or JARVIS_FOLLOW_ADMIN_RELEASE
        releaseSoftFollow(releaseTime)
        if invisFollow then
            releaseSoftCloak(
                combatRelease[releaseCmd]
                    and JARVIS_CLOAK_COMBAT_RELEASE
                    or JARVIS_CLOAK_ADMIN_RELEASE
            )
        end
    end
    if body:sub(1, 1) == "."
        or body:sub(1, 1) == ";"
    then
        if JARVIS_KX_ADMIN_ENABLED == false then
            voice("kx off. admin commands disabled.")
            return
        end
        body = body:sub(2)
    end
    local commandPrefix = prefixOverride or DOT
    local fullCommand = commandPrefix .. body
    local box = findCmdBox()
    if box then
        pcall(function()
            box:CaptureFocus()
            box.Text = fullCommand
            box:ReleaseFocus(true)
        end)
        print(
            "[JARVIS] admin command:",
            fullCommand
        )
        return
    end
    say(fullCommand)
end
local lastTeamRecoveryAt = 0
bot:GetPropertyChangedSignal("Team"):Connect(function()
    if IS_LEADER then
        return
    end
    local stamp = os.clock()
    lastTeamRecoveryAt = stamp
    task.delay(0.75, function()
        if lastTeamRecoveryAt ~= stamp then
            return
        end
        local char = bot.Character
        if not char then
            return
        end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if hum and root and hum.Health > 0 then
            if hiddenLock then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = HIDE_CFRAME
            end
        end
    end)
end)
local function setNoclipAdmin(on)
    if IS_LEADER then
        return
    end
    if on then
        pcall(function()
            if Noclipping then
                Noclipping:Disconnect()
            end
        end)
        noclipOn = true
        NoclipParts = {}
        local firstChar = bot.Character
        if firstChar then
            for _, child in ipairs(firstChar:GetDescendants()) do
                if child:IsA("BasePart") and child.CanCollide == true then
                    child.CanCollide = false
                    NoclipParts[child] = true
                end
            end
        end
        Noclipping = RunService.Stepped:Connect(function()
            if not noclipOn then
                return
            end
            local char = bot.Character
            if not char then
                return
            end
            for _, child in ipairs(char:GetDescendants()) do
                if child:IsA("BasePart") then
                    if child.CanCollide == true then
                        NoclipParts[child] = true
                    end
                    child.CanCollide = false
                end
            end
        end)
    else
        noclipOn = false
        if Noclipping then
            pcall(function()
                Noclipping:Disconnect()
            end)
            Noclipping = nil
        end
        for part in pairs(NoclipParts) do
            if part and part.Parent then
                pcall(function()
                    part.CanCollide = true
                end)
            end
        end
        NoclipParts = {}
    end
end
task.spawn(function()
    task.wait(0.35)
    if not IS_LEADER then
        setNoclipAdmin(true)
        print("[JARVIS] continuous client noclip enabled")
    end
end)
local function partPositionForInteraction(inst)
    if not inst then return nil end
    if inst:IsA("BasePart") then return inst.Position end
    local current = inst
    while current and current ~= workspace do
        if current:IsA("BasePart") then
            return current.Position
        end
        if current:IsA("Model") then
            return current:GetPivot().Position
        end
        current = current.Parent
    end
    return nil
end
local function nearestBasePartAncestor(inst)
    local current = inst
    while current and current ~= workspace do
        if current:IsA("BasePart") then
            return current
        end
        current = current.Parent
    end
    return nil
end
local function looksLikeCarSpawner(inst)
    local pieces = {}
    local function add(v)
        if v ~= nil then
            table.insert(pieces, tostring(v):lower())
        end
    end
    add(inst.Name)
    if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
        add(inst.Text)
    elseif inst:IsA("ProximityPrompt") then
        add(inst.ActionText)
        add(inst.ObjectText)
    end
    local current = inst.Parent
    for _ = 1, 4 do
        if not current or current == workspace then break end
        add(current.Name)
        current = current.Parent
    end
    local text = table.concat(pieces, " ")
    return (
        text:find("spawn car", 1, true)
        or text:find("spawncar", 1, true)
        or text:find("car spawn", 1, true)
        or text:find("carspawn", 1, true)
        or text:find("vehicle spawn", 1, true)
        or text:find("vehicle", 1, true) and text:find("spawn", 1, true)
    ) ~= nil
end
local function findCarSpawnerCandidates()
    local found = {}
    local added = {}
    local function push(inst, kind, bonus)
        if not inst or added[inst] then return end
        local pos = partPositionForInteraction(inst)
        if not pos then return end
        local distance = (pos - CAR_SPAWNER_POSITION).Magnitude
        if distance > CAR_BUTTON_RADIUS then return end
        added[inst] = true
        table.insert(found, {
            object = inst,
            kind = kind,
            distance = distance,
            score = distance + (bonus or 0),
        })
    end
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("ClickDetector") then
            push(inst, "click", -50)
        elseif inst:IsA("ProximityPrompt") then
            push(inst, "prompt", -45)
        elseif (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox"))
            and looksLikeCarSpawner(inst)
        then
            local part = nearestBasePartAncestor(inst)
            if part then
                push(part, "labelpart", -70)
            end
        elseif inst:IsA("BasePart") and looksLikeCarSpawner(inst) then
            push(inst, "namedpart", -60)
        end
    end
    for _, inst in ipairs(workspace:GetPartBoundsInRadius(CAR_SPAWNER_POSITION, 14)) do
        if inst:IsA("BasePart") then
            push(inst, "physical", 25)
        end
    end
    table.sort(found, function(a, b)
        if a.score == b.score then
            return a.distance < b.distance
        end
        return a.score < b.score
    end)
    return found
end
local function faceInteractionPosition(pos)
    local root = myRoot()
    if not root or not pos then return end
    local flat = Vector3.new(pos.X, root.Position.Y, pos.Z)
    if (flat - root.Position).Magnitude > 0.05 then
        root.CFrame = CFrame.lookAt(root.Position, flat)
    end
end
local function screenClickWorldPosition(pos)
    if not pos then return false end
    local point, visible = camera:WorldToViewportPoint(pos)
    if not visible or point.Z <= 0 then
        return false
    end
    local x, y = point.X, point.Y
    if VirtualInputManager then
        local ok = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, true, game, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(x, y, 0, false, game, 0)
        end)
        if ok then return true end
    end
    local ok = pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:Button1Down(Vector2.new(x, y), camera.CFrame)
        task.wait(0.05)
        VirtualUser:Button1Up(Vector2.new(x, y), camera.CFrame)
    end)
    return ok
end
local function physicallyTouchSpawner(part)
    if not part or not part:IsA("BasePart") then
        return false
    end
    local root = myRoot()
    if not root then return false end
    if type(firetouchinterest) == "function" then
        local ok = pcall(function()
            firetouchinterest(root, part, 0)
            task.wait(0.08)
            firetouchinterest(root, part, 1)
        end)
        if ok then
            return true
        end
    end
    local original = root.CFrame
    local topY = part.Position.Y + (part.Size.Y * 0.5)
    local target = CFrame.new(part.Position.X, topY + 1.8, part.Position.Z)
    pcall(function()
        root.CFrame = target
        root.AssemblyLinearVelocity = Vector3.new(0, -10, 0)
    end)
    task.wait(0.18)
    pcall(function()
        root.CFrame = CFrame.new(part.Position.X, topY + 0.4, part.Position.Z)
    end)
    task.wait(0.18)
    return true
end
local function activateSpawnerCandidate(item)
    if not item or not item.object then return false end
    local obj = item.object
    local pos = partPositionForInteraction(obj)
    if pos then
        faceInteractionPosition(pos)
    end
    if obj:IsA("ClickDetector") then
        if type(fireclickdetector) == "function" then
            local ok = pcall(function()
                fireclickdetector(obj)
            end)
            if ok then return true end
        end
        if pos and screenClickWorldPosition(pos) then
            return true
        end
        local part = nearestBasePartAncestor(obj)
        if part then
            return physicallyTouchSpawner(part)
        end
    elseif obj:IsA("ProximityPrompt") then
        if type(fireproximityprompt) == "function" then
            local ok = pcall(function()
                fireproximityprompt(obj)
            end)
            if ok then return true end
        end
        local ok = pcall(function()
            obj:InputHoldBegin()
            task.wait(math.max(obj.HoldDuration, 0.05))
            obj:InputHoldEnd()
        end)
        if ok then return true end
        local part = nearestBasePartAncestor(obj)
        if part then
            return physicallyTouchSpawner(part)
        end
    elseif obj:IsA("BasePart") then
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("ClickDetector") then
                if type(fireclickdetector) == "function" then
                    local ok = pcall(function() fireclickdetector(d) end)
                    if ok then return true end
                end
            elseif d:IsA("ProximityPrompt") then
                if type(fireproximityprompt) == "function" then
                    local ok = pcall(function() fireproximityprompt(d) end)
                    if ok then return true end
                end
            end
        end
        if pos then
            screenClickWorldPosition(pos)
        end
        return physicallyTouchSpawner(obj)
    end
    return false
end
local function snapshotVehicleSeats()
    local seen = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("VehicleSeat") then
            seen[inst] = true
        end
    end
    return seen
end
local function nearestDriverSeat(existing, preferNew)
    local candidates = {}
    for _, inst in ipairs(workspace:GetDescendants()) do
        if inst:IsA("VehicleSeat") and inst.Parent then
            local distance = (inst.Position - CAR_SPAWNER_POSITION).Magnitude
            if distance <= CAR_SEARCH_RADIUS then
                local occupantOkay = (not inst.Occupant) or inst.Occupant == myHum()
                if occupantOkay then
                    local modelName = inst.Parent and inst.Parent.Name:lower() or ""
                    local policeBonus = (modelName:find("police", 1, true) or modelName:find("car", 1, true)) and -20 or 0
                    local newBonus = (existing and not existing[inst]) and -80 or 0
                    if preferNew and existing and existing[inst] then
                        newBonus = newBonus + 50
                    end
                    table.insert(candidates, {
                        seat = inst,
                        score = distance + policeBonus + newBonus,
                    })
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        return a.score < b.score
    end)
    return candidates[1] and candidates[1].seat or nil
end
local function waitForDriverSeat(existing, timeout)
    local deadline = os.clock() + (timeout or 6)
    repeat
        local seat = nearestDriverSeat(existing, true)
        if seat and (not existing[seat] or os.clock() > deadline - 3) then
            return seat
        end
        task.wait(0.1)
    until os.clock() >= deadline
    return nearestDriverSeat(existing, false)
end
local function seatAsDriver(seat)
    if not seat or not seat:IsA("VehicleSeat") or not seat.Parent then
        return false
    end
    local hum = myHum()
    local root = myRoot()
    if not hum or not root then return false end
    hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
    hum.Sit = false
    root.CFrame = seat.CFrame * CFrame.new(0, 2.65, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    task.wait(0.12)
    pcall(function()
        seat:Sit(hum)
    end)
    local deadline = os.clock() + 2.2
    repeat
        if seat.Occupant == hum and hum.SeatPart == seat then
            return true
        end
        pcall(function()
            seat:Sit(hum)
        end)
        task.wait(0.05)
    until os.clock() >= deadline
    return seat.Occupant == hum and hum.SeatPart == seat
end
local function jumpOutOfVehicle()
    local hum = myHum()
    local root = myRoot()
    if not hum then return end
    hum.Sit = false
    hum.Jump = true
    pcall(function()
        hum:ChangeState(Enum.HumanoidStateType.Jumping)
    end)
    if root then
        root.AssemblyLinearVelocity = Vector3.new(0, 12, 0)
    end
    task.wait(CAR_SEAT_RETRY_DELAY)
end
local function holdForward(seat, duration)
    if not seat or not seat.Parent then return false, 0, 0 end
    duration = duration or CAR_MOVE_TEST_TIME
    local startPos = seat.Position
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.W, false, game)
        end)
    end
    pcall(function()
        VirtualUser:CaptureController()
        VirtualUser:SetKeyDown("w")
    end)
    pcall(function() seat.ThrottleFloat = 1 end)
    pcall(function() seat.Throttle = 1 end)
    task.wait(duration)
    local moved = seat.Parent and (seat.Position - startPos).Magnitude or 0
    local speed = seat.Parent and seat.AssemblyLinearVelocity.Magnitude or 0
    if VirtualInputManager then
        pcall(function()
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.W, false, game)
        end)
    end
    pcall(function()
        VirtualUser:SetKeyUp("w")
    end)
    pcall(function() seat.ThrottleFloat = 0 end)
    pcall(function() seat.Throttle = 0 end)
    return (moved >= CAR_MOVE_THRESHOLD or speed >= 2), moved, speed
end
local function waitForNewCar(existing, timeout)
    local newSeat = nil
    local connection
    connection = workspace.DescendantAdded:Connect(function(inst)
        if newSeat then return end
        if inst:IsA("VehicleSeat") then
            task.defer(function()
                if inst.Parent
                    and (inst.Position - CAR_SPAWNER_POSITION).Magnitude <= CAR_SEARCH_RADIUS
                    and (not existing or not existing[inst])
                then
                    newSeat = inst
                end
            end)
        end
    end)
    local deadline = os.clock() + (timeout or 6)
    repeat
        if newSeat and newSeat.Parent then
            connection:Disconnect()
            return newSeat
        end
        local seat = nearestDriverSeat(existing, true)
        if seat and (not existing or not existing[seat]) then
            connection:Disconnect()
            return seat
        end
        task.wait(0.08)
    until os.clock() >= deadline
    connection:Disconnect()
    return nil
end
local function spawnPoliceCar(existing)
    local candidates = findCarSpawnerCandidates()
    if #candidates == 0 then
        return nil, "no spawn pad/control found near supplied coordinates"
    end
    print("[JARVIS] car spawner candidates:", #candidates)
    for i = 1, math.min(#candidates, 12) do
        local item = candidates[i]
        local obj = item.object
        local pos = partPositionForInteraction(obj)
        local root = myRoot()
        if root and pos then
            local approach = pos + Vector3.new(0, 2.5, 0)
            root.CFrame = CFrame.new(approach, Vector3.new(pos.X, approach.Y, pos.Z))
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            task.wait(0.10)
        end
        print(
            "[JARVIS] trying spawner",
            i,
            item.kind,
            obj:GetFullName(),
            string.format("%.2f", item.distance)
        )
        activateSpawnerCandidate(item)
        local seat = waitForNewCar(existing, 2.0)
        if seat then
            print("[JARVIS] NEW driver seat:", seat:GetFullName())
            return seat
        end
    end
    local delayedSeat = waitForDriverSeat(existing, 3.5)
    if delayedSeat and (not existing or not existing[delayedSeat]) then
        return delayedSeat
    end
    return nil, "spawn interaction completed but no NEW VehicleSeat appeared"
end
local function findCarSpawnRemote()
    local direct = ReplicatedStorage:FindFirstChild(CAR_SPAWN_REMOTE_NAME, true)
    if direct and direct:IsA("RemoteEvent") then
        return direct
    end
    return nil
end
local forceAntiFlingOn
local restoreOwnCam
local setFly
function jarvisDisableEverythingForCarFling()
    frozen = false
    freezeCFrame = nil
    hiddenLock = false
    protecting = false
    protectedPlayer = nil
    orbiting = false
    dancing = false
    guardMode = false
    punchOn = false
    spinning = false
    patrolOrigin = nil
    scoutOrigin = nil
    scoutReturning = false
    invisFollow = false
    invisPosition = nil
    groundLock = false
    targetPlayer = nil
    followCamPlayer = nil
    mode = "idle"
    if stopJarvisIPA then
        stopJarvisIPA()
    else
        JARVIS_IPA_ACTIVE = false
        JARVIS_IPA_TARGET = nil
    end
    JARVIS_PUNCHAURA_ACTIVE = false
    JARVIS_PUNCHAURA_TARGET = nil
    if clearJarvisPriorityTarget then
        clearJarvisPriorityTarget()
    else
        JARVIS_PRIORITY_TARGET_ACTIVE = false
        JARVIS_PRIORITY_TARGET = nil
    end
    if disconnectProtectDamageWatcher then
        disconnectProtectDamageWatcher()
    end
    if disconnectProtection then
        disconnectProtection()
    end
    if stopMove then
        stopMove()
    end
    restoreOwnCam()
    setNoSit(false)
    setFly(false)
    if setNoclipAdmin then
        setNoclipAdmin(false)
    else
        noclipOn = false
        if Noclipping then
            pcall(function()
                Noclipping:Disconnect()
            end)
            Noclipping = nil
        end
    end
    local r = myRoot()
    if r then
        r.Anchored = false
        r.AssemblyLinearVelocity = Vector3.zero
        r.AssemblyAngularVelocity = Vector3.zero
    end
end
local function runRemoteCarFling(targetText)
    targetText = tostring(targetText or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if targetText == "" then
        voice("fling target required.")
        return
    end
    jarvisDisableEverythingForCarFling()
    vehicleRoutineActive = true
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local LocalPlayer = Players.LocalPlayer
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    local humanoid = character:WaitForChild("Humanoid")
    local root = character:WaitForChild("HumanoidRootPart")
    local spawner = nil
    local buttons = Workspace:FindFirstChild("Prison_ITEMS") and Workspace.Prison_ITEMS:FindFirstChild("buttons")
    if buttons then
        for _, b in ipairs(buttons:GetChildren()) do
            local p = b:FindFirstChild("Car Spawner")
            local t = p and p:FindFirstChild("type")
            if p and p:IsA("BasePart") and t and t:IsA("StringValue") and t.Value == "Squad" then
                spawner = p
                break
            end
        end
    end
    if spawner then
        character:PivotTo(spawner.CFrame + Vector3.new(0, 2.5, 0))
        task.wait(0.15)
        local interact = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("InteractWithItem")
        if interact and interact:IsA("RemoteFunction") then
            pcall(function()
                interact:InvokeServer(spawner)
            end)
        end
        task.wait(0.25)
        local car = nil
        local seat = nil
        local container = Workspace:FindFirstChild("CarContainer")
        local spawnDeadline = os.clock() + 4.0
        repeat
            if container then
                for _, c in ipairs(container:GetChildren()) do
                    if c:IsA("Model") then
                        local s = c:FindFirstChild("VehicleSeat", true)
                        if s and s:IsA("VehicleSeat") and (s.Position - spawner.Position).Magnitude <= 35 then
                            car = c
                            seat = s
                            break
                        end
                    end
                end
            end
            if not car then
                task.wait(0.05)
            end
        until car ~= nil or os.clock() >= spawnDeadline
        if car and seat then
            humanoid:SetStateEnabled(Enum.HumanoidStateType.Seated, true)
            seat.Disabled = false
            seat.CanTouch = true
            character:PivotTo(seat.CFrame + Vector3.new(0, 1.5, 0))
            seat:Sit(humanoid)
            local boardDeadline = os.clock() + 3.0
            repeat
                if humanoid.SeatPart ~= seat then
                    character:PivotTo(seat.CFrame + Vector3.new(0, 1.5, 0))
                    seat:Sit(humanoid)
                end
                task.wait(0.05)
            until humanoid.SeatPart == seat or os.clock() >= boardDeadline
        end
    end
    task.wait(1.5)
    otherCmd("fling " .. targetText)
    vehicleRoutineActive = false
    mode = "idle"
    setFly(false)
    setNoSit(false)
    setNoclipAdmin(false)
end
forceAntiFlingOn = function()
    pcall(function()
        otherCmd("antifling on")
    end)
end
local function runCarFling(targetText)
    targetText = tostring(targetText or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if targetText == "" then
        voice("fling target required.")
        return
    end
    if carFlingBusy then
        voice("car fling already running.")
        return
    end
    carFlingBusy = true
    vehicleRoutineActive = true
    local previousNoSit = noSit
    local previousFlying = flying
    local previousMode = mode
    setNoSit(false)
    otherCmd("antifling off")
    setFly(false)
    mode = "idle"
    local ok, err = xpcall(function()
        otherCmd("tp cop")
        task.wait(1.0)
        local root = myRoot()
        if not root then error("character root missing after .tp cop") end
        local buttonPos = CAR_SPAWNER_POSITION
        local approach = buttonPos + Vector3.new(0, 2.8, 3.0)
        root.CFrame = CFrame.lookAt(approach, buttonPos)
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        task.wait(0.20)
        local existing = snapshotVehicleSeats()
        local seat, spawnErr = spawnPoliceCar(existing)
        if not seat then
            error(spawnErr or "spawned VehicleSeat not found")
        end
        task.wait(0.35)
        local seated = seatAsDriver(seat)
        if not seated then
            jumpOutOfVehicle()
            seated = seatAsDriver(seat)
        end
        if not seated or seat.Occupant ~= myHum() or myHum().SeatPart ~= seat then
            error("JARVIS could not become the DRIVER")
        end
        local moved, distance, speed = holdForward(seat, 0.9)
        print(string.format(
            "[JARVIS] car W test: moved=%s distance=%.2f speed=%.2f",
            tostring(moved), distance, speed
        ))
        if not moved then
            jumpOutOfVehicle()
            task.wait(0.15)
            if not seatAsDriver(seat) then
                error("driver-seat retry failed")
            end
            local moved2, distance2, speed2 = holdForward(seat, 1.0)
            print(string.format(
                "[JARVIS] car W retry: moved=%s distance=%.2f speed=%.2f",
                tostring(moved2), distance2, speed2
            ))
            if not moved2 then
                error("car did not move after W retry; fling cancelled")
            end
        end
        if seat.Occupant ~= myHum() or myHum().SeatPart ~= seat then
            if not seatAsDriver(seat) then
                error("driver seat lost before fling")
            end
        end
        task.wait(0.12)
        otherCmd("fling " .. targetText)
        voice("car fling " .. targetText)
        task.wait(1.0)
    end, debug.traceback)
    forceAntiFlingOn()
    vehicleRoutineActive = false
    setNoSit(previousNoSit)
    if previousFlying then
        setFly(true)
    end
    mode = previousMode
    carFlingBusy = false
    if not ok then
        warn("[JARVIS] CAR FLING FAILED:", err)
        voice("car fling failed. " .. tostring(err))
    else
        print("[JARVIS] car fling complete; antifling restored ON")
    end
end
restoreOwnCam = function()
    camLocked = false
    camera.CameraType =
        Enum.CameraType.Custom
    local h = myHum()
    if h then
        camera.CameraSubject = h
    end
end
local function lockCam(plr)
    if IS_LEADER then
        return
    end
    camLocked = true
    if plr then
        targetPlayer = plr
        followCamPlayer = plr
    end
end
setFly = function(on)
    if IS_LEADER then
        return
    end
    flying = on
    local hum = myHum()
    local root = myRoot()
    if hum then
        hum.PlatformStand = on
        hum.AutoRotate = not on
    end
    if root then
        root.Anchored = false
        root.AssemblyLinearVelocity =
            Vector3.zero
    end
end
local function setTrueIdleAnchor()
    if IS_LEADER then
        return
    end
    flying = false
    local hum = myHum()
    local root = myRoot()
    if hum then
        hum.PlatformStand = false
        hum.AutoRotate = true
    end
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.Anchored = true
    end
end
local function releaseTrueIdleAnchor()
    local root = myRoot()
    if root and root.Anchored then
        root.Anchored = false
    end
end
local function flyStep(
    part,
    goal,
    dt,
    preserveGoalY
)
    local hum = myHum()
    if hum then
        hum.PlatformStand = true
    end
    if not part or not goal then
        return true
    end
    part.AssemblyLinearVelocity =
        Vector3.zero
    if not preserveGoalY then
        goal = flatten(goal)
    end
    local delta =
        goal - part.Position
    if delta.Magnitude < 0.35 then
        return true
    end
    local step = math.min(
        flySpeed * dt,
        delta.Magnitude
    )
    local pos =
        part.Position
        + delta.Unit * step
    if not preserveGoalY then
        pos = flatten(pos)
    end
    local lookRoot = camRoot()
    local lookDirection
    if lookRoot then
        lookDirection =
            lookRoot.CFrame.LookVector
    else
        lookDirection =
            part.CFrame.LookVector
    end
    if spinning then
        local rotationOnly = part.CFrame - part.Position
        part.CFrame = CFrame.new(pos) * rotationOnly
    else
        part.CFrame =
            CFrame.lookAt(
                pos,
                pos + Vector3.new(
                    lookDirection.X,
                    0,
                    lookDirection.Z
                )
            )
    end
    return false
end
local function getUnitIndex()
    local units = getEagleUnits()
    for i, p in ipairs(units) do
        if p == bot then
            return i, #units
        end
    end
    return 1, #units
end
function getFormationPosition(
    masterRoot,
    requestedFormation
)
    if not masterRoot then
        return nil
    end
    local index, count =
        getUnitIndex()
    local formation =
        requestedFormation
        or formationType
    if formation == "v" then
        local row =
            math.floor((index - 1) / 2)
        local side =
            ((index - 1) % 2 == 0)
            and -1
            or 1
        if index == 1 then
            return masterRoot.Position
                - masterRoot.CFrame.LookVector
                    * FORMATION_BACK
        end
        return masterRoot.Position
            - masterRoot.CFrame.LookVector
                * (
                    FORMATION_BACK
                    + row * FORMATION_ROW
                )
            + masterRoot.CFrame.RightVector
                * (
                    math.max(
                        2,
                        row * 2.5
                    ) * side
                )
    end
    if formation == "diamond" then
        local positions = {
            Vector3.new(
                0,
                0,
                -FORMATION_BACK
            ),
            Vector3.new(
                -FORMATION_SIDE,
                0,
                0
            ),
            Vector3.new(
                FORMATION_SIDE,
                0,
                0
            ),
            Vector3.new(
                0,
                0,
                FORMATION_BACK
            ),
        }
        local localPos =
            positions[
                ((index - 1) % 4) + 1
            ]
        return masterRoot.CFrame:PointToWorldSpace(
            localPos
        )
    end
    if formation == "wall" then
        local spacing = 5
        local offset =
            (index - (count + 1) / 2)
            * spacing
        return masterRoot.Position
            + masterRoot.CFrame.RightVector
                * offset
            - masterRoot.CFrame.LookVector
                * FORMATION_BACK
    end
    if formation == "circle" then
        local radius = 10
        local angle =
            ((index - 1)
                / math.max(count, 1))
            * math.pi
            * 2
        return masterRoot.Position
            + Vector3.new(
                math.cos(angle) * radius,
                0,
                math.sin(angle) * radius
            )
    end
    if formation == "columns" then
        local row =
            math.floor((index - 1) / 2)
        local column =
            (index - 1) % 2
        local side =
            column == 0
            and -1
            or 1
        return masterRoot.Position
            - masterRoot.CFrame.LookVector
                * (
                    FORMATION_BACK
                    + row * FORMATION_ROW
                )
            + masterRoot.CFrame.RightVector
                * (
                    FORMATION_SIDE
                    * 0.55
                    * side
                )
    end
    if count <= 0 then
        return masterRoot.Position
    end
    if count == 1 then
        return masterRoot.Position
            - masterRoot.CFrame.LookVector
                * FORMATION_BACK
    end
    if count == 2 then
        local side =
            index == 1
            and -1
            or 1
        return masterRoot.Position
            - masterRoot.CFrame.LookVector
                * FORMATION_BACK
            + masterRoot.CFrame.RightVector
                * (
                    FORMATION_SIDE
                    * side
                )
    end
    if count == 3 then
        if index == 1 then
            return masterRoot.Position
                - masterRoot.CFrame.LookVector
                    * FORMATION_BACK
        end
        local side =
            index == 2
            and -1
            or 1
        return masterRoot.Position
            - masterRoot.CFrame.LookVector
                * (
                    FORMATION_BACK + 1.5
                )
            + masterRoot.CFrame.RightVector
                * (
                    FORMATION_SIDE
                    * side
                )
    end
    local row =
        math.floor((index - 1) / 2)
    local column =
        (index - 1) % 2
    local side =
        column == 0
        and -1
        or 1
    return masterRoot.Position
        - masterRoot.CFrame.LookVector
            * (
                FORMATION_BACK
                + row * FORMATION_ROW
            )
        + masterRoot.CFrame.RightVector
            * (
                FORMATION_SIDE
                * 0.55
                * side
            )
end
JARVIS_INVIS_FLOOR = JARVIS_INVIS_FLOOR or {
    target = nil,
    lockedY = nil,
    pendingY = nil,
    pendingAt = 0,
}
function resetInvisibleFloorLatch(player)
    local targetRoot = rootOf(player)
    JARVIS_INVIS_FLOOR.target = player
    JARVIS_INVIS_FLOOR.pendingY = nil
    JARVIS_INVIS_FLOOR.pendingAt = 0
    JARVIS_INVIS_FLOOR.lockedY = targetRoot and targetRoot.Position.Y or nil
end
function getLatchedInvisibleTargetY(player)
    local targetRoot = rootOf(player)
    if not targetRoot then
        return nil
    end
    local state = JARVIS_INVIS_FLOOR
    if state.target ~= player or state.lockedY == nil then
        resetInvisibleFloorLatch(player)
    end
    local hum = humOf(player)
    if not hum then
        return state.lockedY or targetRoot.Position.Y
    end
    local humState = hum:GetState()
    local grounded =
        hum.FloorMaterial ~= Enum.Material.Air
        and humState ~= Enum.HumanoidStateType.Jumping
        and humState ~= Enum.HumanoidStateType.Freefall
        and humState ~= Enum.HumanoidStateType.FallingDown
    if grounded then
        local currentY = targetRoot.Position.Y
        local lockedY = state.lockedY or currentY
        if math.abs(currentY - lockedY) >= 2.25 then
            if state.pendingY == nil or math.abs(currentY - state.pendingY) > 0.75 then
                state.pendingY = currentY
                state.pendingAt = os.clock()
            elseif os.clock() - state.pendingAt >= 0.22 then
                state.lockedY = currentY
                state.pendingY = nil
                state.pendingAt = 0
            end
        else
            state.pendingY = nil
            state.pendingAt = 0
        end
    else
        state.pendingY = nil
        state.pendingAt = 0
    end
    return state.lockedY or targetRoot.Position.Y
end
function ensureCloakYHold(part)
    if not part or not part.Parent then
        return
    end
    local mover = part:FindFirstChild(JARVIS_CLOAK_Y_HOLD_NAME)
    if not mover then
        mover = Instance.new("BodyVelocity")
        mover.Name = JARVIS_CLOAK_Y_HOLD_NAME
        mover.P = 30000
        mover.MaxForce = Vector3.new(0, math.huge, 0)
        mover.Velocity = Vector3.zero
        mover.Parent = part
    else
        mover.MaxForce = Vector3.new(0, math.huge, 0)
        mover.Velocity = Vector3.zero
    end
end
function removeCloakYHold()
    local root = myRoot()
    if not root then
        return
    end
    local mover = root:FindFirstChild(JARVIS_CLOAK_Y_HOLD_NAME)
    if mover then
        mover:Destroy()
    end
end
function releaseSoftFollow(seconds)
    JARVIS_FOLLOW_RELEASE_UNTIL = math.max(
        JARVIS_FOLLOW_RELEASE_UNTIL or 0,
        os.clock() + (tonumber(seconds) or JARVIS_FOLLOW_ADMIN_RELEASE or 1.35)
    )
end
function captureIdleHold()
    local root = myRoot()
    if root then
        JARVIS_IDLE_HOLD_CFRAME = root.CFrame
    end
end
function softFollowStep(part, goal, dt)
    if not part or not goal then
        return true
    end
    if os.clock() < (JARVIS_FOLLOW_RELEASE_UNTIL or 0) then
        return false
    end
    local delta = goal - part.Position
    local distance = delta.Magnitude
    local deadzone = JARVIS_FOLLOW_DEADZONE or 1.6
    if distance <= deadzone then
        part.AssemblyLinearVelocity = Vector3.zero
        return true
    end
    local allowed = math.max(0, distance - deadzone)
    local step = math.min((JARVIS_FOLLOW_SPEED or 18) * dt, allowed)
    if distance > 0 and step > 0 then
        local pos = part.Position + delta.Unit * step
        local targetRoot = camRoot()
        local look = targetRoot and targetRoot.CFrame.LookVector or part.CFrame.LookVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.001 then
            flatLook = Vector3.new(0, 0, -1)
        else
            flatLook = flatLook.Unit
        end
        part.AssemblyLinearVelocity = Vector3.zero
        part.CFrame = CFrame.lookAt(pos, pos + flatLook)
    end
    return false
end
function releaseSoftCloak(seconds)
    if not invisFollow then
        return
    end
    JARVIS_CLOAK_RELEASE_UNTIL = math.max(
        JARVIS_CLOAK_RELEASE_UNTIL or 0,
        os.clock() + (tonumber(seconds) or JARVIS_CLOAK_ADMIN_RELEASE)
    )
end
function softCloakStep(part, goal, dt)
    if not part or not goal then
        return true
    end
    ensureCloakYHold(part)
    if os.clock() < (JARVIS_CLOAK_RELEASE_UNTIL or 0) then
        return false
    end
    local current = part.Position
    local dx = goal.X - current.X
    local dz = goal.Z - current.Z
    local horizontalDistance = math.sqrt(dx * dx + dz * dz)
    local newX = current.X
    local newZ = current.Z
    if horizontalDistance > (JARVIS_CLOAK_DEADZONE or 1.35) then
        local maxHorizontalStep = (JARVIS_CLOAK_SPEED or 22) * dt
        local desiredStep = math.max(
            0,
            horizontalDistance - (JARVIS_CLOAK_DEADZONE or 1.35)
        )
        local horizontalStep = math.min(maxHorizontalStep, desiredStep)
        if horizontalDistance > 0 then
            newX = current.X + (dx / horizontalDistance) * horizontalStep
            newZ = current.Z + (dz / horizontalDistance) * horizontalStep
        end
    end
    local yDelta = goal.Y - current.Y
    local maxYStep = 70 * dt
    local newY = current.Y
    if math.abs(yDelta) > 0.08 then
        newY = current.Y + math.clamp(yDelta, -maxYStep, maxYStep)
    else
        newY = goal.Y
    end
    if math.abs(newX - current.X) < 0.001
        and math.abs(newY - current.Y) < 0.001
        and math.abs(newZ - current.Z) < 0.001
    then
        return true
    end
    local look = part.CFrame.LookVector
    local flatLook = Vector3.new(look.X, 0, look.Z)
    if flatLook.Magnitude < 0.001 then
        flatLook = Vector3.new(0, 0, -1)
    else
        flatLook = flatLook.Unit
    end
    local newPos = Vector3.new(newX, newY, newZ)
    part.CFrame = CFrame.lookAt(newPos, newPos + flatLook)
    return false
end
function getInvisibleGoal(player)
    local targetRoot = rootOf(player)
    if not targetRoot then
        return nil
    end
    local latchedY = getLatchedInvisibleTargetY(player)
    if not latchedY then
        return nil
    end
    return Vector3.new(
        targetRoot.Position.X,
        latchedY - cloakDepth,
        targetRoot.Position.Z
    )
end
function followGoal()
    local target = activeTarget()
    local targetRoot = rootOf(target)
    if not targetRoot then
        return nil
    end
    if invisFollow then
        local latchedY = getLatchedInvisibleTargetY(target)
        if not latchedY then
            return nil
        end
        return Vector3.new(
            targetRoot.Position.X,
            latchedY - cloakDepth,
            targetRoot.Position.Z
        )
    end
    local sideOffset = 0
    if followPosition == "left" then
        sideOffset = -sideDistance
    elseif followPosition == "right" then
        sideOffset = sideDistance
    end
    local forwardOffset = -followDistance
    if followPosition == "front" then
        forwardOffset = followDistance
    elseif followPosition == "behind" then
        forwardOffset = -followDistance
    end
    local horizontal =
        targetRoot.Position
        + targetRoot.CFrame.LookVector * forwardOffset
        + targetRoot.CFrame.RightVector * sideOffset
    local goal = Vector3.new(
        horizontal.X,
        targetRoot.Position.Y + followVerticalOffset,
        horizontal.Z
    )
    if punchOn then
        local me = myRoot()
        if me then
            local away = me.Position - targetRoot.Position
            if Vector3.new(away.X, 0, away.Z).Magnitude < 0.2 then
                away = -targetRoot.CFrame.LookVector
            end
            local flatAway = Vector3.new(away.X, 0, away.Z)
            if flatAway.Magnitude > 0 then
                goal = targetRoot.Position + flatAway.Unit * PUNCH_SAFE
                goal = Vector3.new(goal.X, targetRoot.Position.Y + followVerticalOffset, goal.Z)
            end
        end
    end
    return goal
end
function protectGoal(dt)
    local target = protectedPlayer or activeTarget() or getMaster()
    local targetRoot = rootOf(target)
    if not targetRoot then
        return nil
    end
    return targetRoot.Position
end
function orbitGoal()
    local target =
        orbitTarget
        or getMaster()
    local targetRoot =
        rootOf(target)
    if not targetRoot then
        return nil
    end
    orbitAngle =
        orbitAngle + 1.5 * 0.016
    local index, count =
        getUnitIndex()
    local spacing =
        ((index - 1)
            / math.max(count, 1))
        * math.pi
        * 2
    local angle =
        orbitAngle + spacing
    local y = targetRoot.Position.Y
    if dancing then
        y =
            y
            + math.sin(
                danceTime * 4
            ) * 2
    end
    if invisFollow then
        local latchedY = getLatchedInvisibleTargetY(target)
        y = (latchedY or targetRoot.Position.Y) - cloakDepth
    end
    return Vector3.new(
        targetRoot.Position.X
            + math.cos(angle)
                * orbitRadius,
        y,
        targetRoot.Position.Z
            + math.sin(angle)
                * orbitRadius
    )
end
function guardGoal()
    local guardTarget = activeTarget() or getMaster()
    local masterRoot =
        rootOf(guardTarget)
    if not masterRoot then
        return nil
    end
    local index, count =
        getUnitIndex()
    local angle =
        ((index - 1)
            / math.max(count, 1))
        * math.pi
        * 2
    local radius = 11
    local pos =
        masterRoot.Position
        + Vector3.new(
            math.cos(angle)
                * radius,
            0,
            math.sin(angle)
                * radius
        )
    if invisFollow then
        local latchedY = getLatchedInvisibleTargetY(guardTarget)
        pos = Vector3.new(
            pos.X,
            (latchedY or masterRoot.Position.Y) - cloakDepth,
            pos.Z
        )
    end
    return pos
end
function patrolGoal()
    local masterRoot =
        rootOf(getMaster())
    if not masterRoot then
        return nil
    end
    if not patrolOrigin then
        patrolOrigin =
            masterRoot.Position
    end
    patrolAngle =
        patrolAngle + 0.5 * 0.016
    return patrolOrigin
        + Vector3.new(
            math.cos(patrolAngle)
                * PATROL_RADIUS,
            0,
            math.sin(patrolAngle)
                * PATROL_RADIUS
        )
end
function scoutGoal()
    local masterRoot =
        rootOf(getMaster())
    if not masterRoot then
        return nil
    end
    if not scoutOrigin then
        scoutOrigin =
            masterRoot.Position
    end
    local forward =
        masterRoot.CFrame.LookVector
    if scoutReturning then
        return masterRoot.Position
    end
    return masterRoot.Position
        + forward * SCOUT_DISTANCE
end
function stopMove()
    mode = "idle"
    captureIdleHold()
    protecting = false
    orbiting = false
    dancing = false
    guardMode = false
    lastRevenge = {}
    patrolOrigin = nil
    scoutOrigin = nil
    scoutReturning = false
    targetPlayer = nil
    followCamPlayer = nil
end
function returnToMaster()
    protecting = false
    orbiting = false
    dancing = false
    guardMode = false
    targetPlayer = getMaster()
    followCamPlayer = getMaster()
    mode = "follow"
    JARVIS_IDLE_HOLD_CFRAME = nil
    setFly(true)
    lockCam(getMaster())
end
function lockOnPlayer(p)
    if IS_LEADER or not p then
        return
    end
    protecting = false
    targetPlayer = p
    followCamPlayer = p
    mode = "loopfollow"
    JARVIS_IDLE_HOLD_CFRAME = nil
    setFly(true)
    lockCam(p)
end
function updateStuckRecovery(root, dt)
    if not root then
        return
    end
    if not lastPosition then
        lastPosition =
            root.Position
        stuckTimer = 0
        return
    end
    local moved =
        (
            root.Position
            - lastPosition
        ).Magnitude
    lastPosition =
        root.Position
    if moved < STUCK_DISTANCE
        and (
            mode ~= "idle"
            or protecting
            or orbiting
            or dancing
        )
    then
        stuckTimer =
            stuckTimer + dt
    else
        stuckTimer = 0
    end
    if stuckTimer >= STUCK_TIME then
        stuckTimer = 0
        setFly(true)
        if mode == "follow"
            or mode == "loopfollow"
        then
            local target = activeTarget()
            if target and rootOf(target) then
                targetPlayer = target
            end
        end
        print(
            "[JARVIS] movement recovery"
        )
    end
end
JARVIS_SIMPLE_COMMAND_PAGES = {
    "JARVIS CMDS 1/4 | follow <player> | stop | protect <player> | unprotect | invis <player> | vis | pa <player> | unpa | kill <player>",
    "JARVIS CMDS 2/4 | whitelist <player> | unwhitelist <player> | share <player> | unshare <player> | hide | unhide | fly | unfly | noclip | clip",
    "JARVIS CMDS 3/4 | view <player> | unview | orbit <player> | unorbit | guard | unguard | patrol | unpatrol | nearest | untarget | left | center | right",
    "JARVIS CMDS 4/4 | kx on/off | carfling <player> | front | behind | above | below | speed <n> | autospeed | mark <name> | recall <name> | freeze | unfreeze | status | settings | recover | panic | rejoin | reset",
}
JARVIS_SIMPLE_CMD_PAGE_DELAY = 1.5
function dumpPage(_)
    announceCmds()
end
function getJarvisWhisperChannel(target)
    if not target or not target:IsA("Player") then
        return nil
    end
    local channels = TextChatService:FindFirstChild("TextChannels")
    if not channels then
        return nil
    end
    local id1 = tostring(bot.UserId)
    local id2 = tostring(target.UserId)
    local direct =
        channels:FindFirstChild("RBXWhisper:" .. id1 .. "_" .. id2)
        or channels:FindFirstChild("RBXWhisper:" .. id2 .. "_" .. id1)
    if direct and direct:IsA("TextChannel") then
        return direct
    end
    for _, channel in ipairs(channels:GetChildren()) do
        if channel:IsA("TextChannel") then
            local name = channel.Name
            if name:find("RBXWhisper:", 1, true)
                and name:find(id1, 1, true)
                and name:find(id2, 1, true)
            then
                return channel
            end
        end
    end
    return nil
end
function announceCmds(targetPlayer)
    task.spawn(function()
        local target = targetPlayer
        if typeof(target) ~= "Instance" or not target:IsA("Player") then
            target = nil
        end
        if not target then
            for _, line in ipairs(JARVIS_SIMPLE_COMMAND_PAGES) do
                voice(line)
                task.wait(JARVIS_SIMPLE_CMD_PAGE_DELAY)
            end
            return
        end
        local whisper = getJarvisWhisperChannel(target)
        if not whisper then
            local channels = TextChatService:FindFirstChild("TextChannels")
            local general = channels and (
                channels:FindFirstChild("RBXGeneral")
                or channels:FindFirstChild("General")
            )
            if general and general:IsA("TextChannel") then
                pcall(function()
                    -- Include a tiny seed message so Roblox actually creates
                    -- the whisper channel on the very first 'cmds invocation.
                    general:SendAsync("/w @" .. target.Name .. " .")
                end)
            end
            local deadline = os.clock() + 5
            repeat
                task.wait(0.10)
                whisper = getJarvisWhisperChannel(target)
            until whisper or os.clock() >= deadline
        end
        if whisper then
            for _, line in ipairs(JARVIS_SIMPLE_COMMAND_PAGES) do
                pcall(function()
                    whisper:SendAsync(line)
                end)
                task.wait(JARVIS_SIMPLE_CMD_PAGE_DELAY)
            end
        else
            voice("could not open private cmds for " .. target.Name .. ".")
        end
    end)
end
-- HOST COMMAND BAR
-- Press apostrophe (') to open it.
-- This intentionally does NOT use Roblox whisper/private-message channels.
-- `sendJarvisRemoteCommand` is the transport hook for the user's external EXE.

JARVIS_PROTECT_RADIUS = 10
JARVIS_PROTECT_ORBIT_SPEED = 2.2
JARVIS_PROTECT_ORBIT_ANGLE = 0
JARVIS_PROTECT_ACTION_COOLDOWN = 1.0
JARVIS_PROTECT_LAST_ACTION = {}
JARVIS_MELEE_RANGE = 12
JARVIS_PROTECT_ORBIT_RADIUS = 4.25
JARVIS_PROTECT_ORBIT_SPEED = 2.6
JARVIS_PROTECT_RESPAWN_GRACE = 4.0
JARVIS_PROTECT_RESPAWN_GRACE_UNTIL = 0
JARVIS_LAST_SAFE_CFRAME = nil
JARVIS_LAST_SAFE_UPDATE = 0
JARVIS_SAFE_UPDATE_INTERVAL = 0.15
JARVIS_FALL_RECOVERY_DROP = 42
JARVIS_FALL_EMERGENCY_Y = -45
function jarvisGroundBelow(root)
    if not root then
        return false
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if bot.Character then
        table.insert(exclude, bot.Character)
    end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true
    local result = workspace:Raycast(
        root.Position,
        Vector3.new(0, -10, 0),
        params
    )
    return result ~= nil
end
function updateJarvisSafePosition(root, hum)
    if not root or not hum then
        return
    end
    if not jarvisGroundBelow(root) then
        return
    end
    local now = os.clock()
    if now - JARVIS_LAST_SAFE_UPDATE
        < JARVIS_SAFE_UPDATE_INTERVAL
    then
        return
    end
    JARVIS_LAST_SAFE_UPDATE = now
    JARVIS_LAST_SAFE_CFRAME = root.CFrame
end
function recoverJarvisFromFall(root)
    if not root then
        return false
    end
    local shouldRecover = false
    if JARVIS_LAST_SAFE_CFRAME then
        if root.Position.Y
            < JARVIS_LAST_SAFE_CFRAME.Position.Y
                - JARVIS_FALL_RECOVERY_DROP
        then
            shouldRecover = true
        end
    elseif root.Position.Y < JARVIS_FALL_EMERGENCY_Y then
        shouldRecover = true
    end
    if not shouldRecover then
        return false
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    if JARVIS_LAST_SAFE_CFRAME then
        root.CFrame = JARVIS_LAST_SAFE_CFRAME
    else
        root.CFrame =
            CFrame.new(
                root.Position.X,
                5,
                root.Position.Z
            )
    end
    return true
end
JARVIS_PUNCHAURA_ACTIVE = false
JARVIS_IPA_ACTIVE = false
JARVIS_IPA_TARGET = nil
JARVIS_IPA_PREDICTION = 0.18
JARVIS_IPA_DISTANCE = 3.25
function stopJarvisIPA()
    JARVIS_IPA_ACTIVE = false
    JARVIS_IPA_TARGET = nil
end
function jarvisIPAGoal(target)
    if not target then
        return nil
    end
    local tr = rootOf(target)
    if not tr then
        return nil
    end
    local velocity = tr.AssemblyLinearVelocity or Vector3.zero
    local horizontalVelocity =
        Vector3.new(velocity.X, 0, velocity.Z)
    local predicted =
        tr.Position
        + horizontalVelocity * JARVIS_IPA_PREDICTION
    local backOffset =
        -tr.CFrame.LookVector * JARVIS_IPA_DISTANCE
    return predicted + backOffset
end
function jarvisIPAStep(root, dt)
    if not JARVIS_IPA_ACTIVE then
        return false
    end
    local target = JARVIS_IPA_TARGET
    if not target
        or not target.Parent
        or target == bot
    then
        stopJarvisIPA()
        return false
    end
    if isJarvisOwnerPlayer
        and isJarvisOwnerPlayer(target)
    then
        stopJarvisIPA()
        return false
    end
    local targetRoot = rootOf(target)
    local targetHum = humOf(target)
    if not targetRoot
        or not targetHum
        or targetHum.Health <= 0
    then
        releaseTrueIdleAnchor()
        if not flying then
            setFly(true)
        end
        return true
    end
    local goal = jarvisIPAGoal(target)
    if not goal then
        return true
    end
    releaseTrueIdleAnchor()
    if not flying then
        setFly(true)
    end
    flyStep(
        root,
        goal,
        dt,
        true
    )
    if (root.Position - targetRoot.Position).Magnitude
        <= (JARVIS_MELEE_RANGE or 12)
        and not isJarvisProtectedFromAura(target, nil)
    then
        local shouldSkip = false
        pcall(function()
            local myTeamName = bot.Team and bot.Team.Name or ""
            local theirTeamName = target.Team and target.Team.Name or ""
            if myTeamName:lower():find("guard", 1, true)
                and theirTeamName:lower():find("inmate", 1, true)
                and target.Character
                and not target.Character:GetAttribute("Hostile")
            then
                shouldSkip = true
            end
        end)
        if not shouldSkip then
            jarvisMeleeAttack(target)
        end
    end
    return true
end
JARVIS_PUNCHAURA_TARGET = nil
JARVIS_PUNCHAURA_PREDICT = 0.18
JARVIS_PUNCHAURA_FRONT_DISTANCE = 3.5
JARVIS_PUNCHAURA_NEARBY_WHITELIST_RADIUS = 18
JARVIS_DYNAMIC_WHITELIST = JARVIS_DYNAMIC_WHITELIST or {}
JARVIS_MELEE_LAST_HIT = JARVIS_MELEE_LAST_HIT or {}
JARVIS_MELEE_HIT_COOLDOWN = 0.10
JARVIS_PROTECT_DAMAGE_CONNECTION = nil
JARVIS_PROTECT_CHARACTER_CONNECTION = nil
JARVIS_PROTECT_LAST_HEALTH = nil
JARVIS_PROTECT_ATTACK_SCAN_RANGE = 180
JARVIS_PROTECT_ATTACK_FACING_DOT = 0.35
JARVIS_PROTECT_ATTACK_COOLDOWN = 1.25
JARVIS_PROTECT_LAST_RETALIATE = {}
JARVIS_PRIORITY_TARGET = nil
JARVIS_PRIORITY_TARGET_ACTIVE = false
JARVIS_PRIORITY_TARGET_LAST_ACTION = 0
JARVIS_PRIORITY_TARGET_ACTION_DELAY = 0.75
JARVIS_PRIORITY_TARGET_RESPAWN_GRACE_UNTIL = 0
JARVIS_TARGET_KILL_CHECK_DELAY = 1.25
JARVIS_TARGET_KILL_PENDING = false
JARVIS_TARGET_KILL_CHECK_AT = 0
JARVIS_TARGET_KILL_START_HEALTH = nil
JARVIS_TARGET_KILL_RETRY_COOLDOWN = 1.5
JARVIS_TARGET_KILL_LAST_RETRY = 0
JARVIS_TARGET_NEARBY_DISTANCE = 7
JARVIS_TARGET_HIDE_CFRAME = CFrame.new(
    874.332336, 116.509766, 2419.012939,
    -0.883117, 0, 0.469153,
    0, 1, 0,
    -0.469153, 0, -0.883117
)
JARVIS_TARGET_PA_PREDICTION = 0.22
function jarvisPriorityTargetExempt(player)
    if not player or player == bot then
        return true
    end
    if isJarvisOwnerPlayer
        and isJarvisOwnerPlayer(player)
    then
        return true
    end
    if isWhitelistedPlayer
        and isWhitelistedPlayer(player)
    then
        return true
    end
    return false
end
function clearJarvisPriorityTarget()
    JARVIS_PRIORITY_TARGET_ACTIVE = false
    JARVIS_PRIORITY_TARGET = nil
    JARVIS_PRIORITY_TARGET_LAST_ACTION = 0
    JARVIS_TARGET_KILL_PENDING = false
    JARVIS_TARGET_KILL_CHECK_AT = 0
    JARVIS_TARGET_KILL_START_HEALTH = nil
    JARVIS_TARGET_KILL_LAST_RETRY = 0
    if JARVIS_PUNCHAURA_ACTIVE then
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
    end
    local r = myRoot()
    if r and r.Anchored then
        r.Anchored = false
    end
end
function prepareJarvisPriorityTarget(player)
    frozen = false
    freezeCFrame = nil
    hiddenLock = false
    protecting = false
    protectedPlayer = nil
    orbiting = false
    dancing = false
    guardMode = false
    punchOn = false
    spinning = false
    patrolOrigin = nil
    scoutOrigin = nil
    scoutReturning = false
    invisFollow = false
    invisPosition = nil
    groundLock = false
    if stopJarvisIPA then
        stopJarvisIPA()
    else
        JARVIS_IPA_ACTIVE = false
        JARVIS_IPA_TARGET = nil
    end
    JARVIS_PUNCHAURA_ACTIVE = false
    JARVIS_PUNCHAURA_TARGET = nil
    if disconnectProtectDamageWatcher then
        disconnectProtectDamageWatcher()
    end
    if disconnectProtection then
        disconnectProtection()
    end
    targetPlayer = player
    followCamPlayer = player
    mode = "idle"
    releaseTrueIdleAnchor()
    setFly(true)
    lockCam(player)
end
function setJarvisPriorityTarget(player)
    if not player
        or player == bot
        or jarvisPriorityTargetExempt(player)
    then
        return false
    end
    prepareJarvisPriorityTarget(player)
    JARVIS_PRIORITY_TARGET = player
    JARVIS_PRIORITY_TARGET_ACTIVE = true
    JARVIS_PRIORITY_TARGET_LAST_ACTION = 0
    JARVIS_TARGET_KILL_PENDING = false
    JARVIS_TARGET_KILL_CHECK_AT = 0
    JARVIS_TARGET_KILL_START_HEALTH = nil
    JARVIS_TARGET_KILL_LAST_RETRY = 0
    return true
end
function jarvisTargetHoldAtHide(root)
    if not root or not root.Parent then
        return
    end
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
    root.CFrame = JARVIS_TARGET_HIDE_CFRAME
    root.Anchored = true
end
function jarvisTargetReleaseHide(root)
    if not root or not root.Parent then
        return
    end
    root.Anchored = false
    releaseTrueIdleAnchor()
    if not flying then
        setFly(true)
    end
end
function jarvisPriorityTargetStep(root, dt)
    if not JARVIS_PRIORITY_TARGET_ACTIVE then
        return false
    end
    local target = JARVIS_PRIORITY_TARGET
    if not target
        or not target.Parent
        or jarvisPriorityTargetExempt(target)
    then
        clearJarvisPriorityTarget()
        return false
    end
    local targetHum = humOf(target)
    local targetRoot = rootOf(target)
    if not targetHum
        or targetHum.Health <= 0
        or not targetRoot
    then
        jarvisTargetHoldAtHide(root)
        return true
    end
    local myTeam = bot.Team
    local theirTeam = target.Team
    local myTeamName =
        myTeam and myTeam.Name:lower() or ""
    local theirTeamName =
        theirTeam and theirTeam.Name:lower() or ""
    local sameTeam =
        myTeam ~= nil
        and theirTeam ~= nil
        and myTeam == theirTeam
    local now = os.clock()
    if sameTeam
        and myTeamName:find("guard", 1, true)
        and theirTeamName:find("guard", 1, true)
    then
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        jarvisTargetHoldAtHide(root)
        if now - (JARVIS_PRIORITY_TARGET_LAST_ACTION or 0) >= 1.25 then
            JARVIS_PRIORITY_TARGET_LAST_ACTION = now
            otherCmd("team inmate")
        end
        return true
    end
    if sameTeam then
        jarvisTargetReleaseHide(root)
        JARVIS_PUNCHAURA_TARGET = target
        JARVIS_PUNCHAURA_ACTIVE = true
        local velocity = targetRoot.AssemblyLinearVelocity
        local horizontalVelocity = Vector3.new(
            velocity.X,
            0,
            velocity.Z
        )
        local predicted =
            targetRoot.Position
            + horizontalVelocity * (JARVIS_TARGET_PA_PREDICTION or 0.22)
        local goal = Vector3.new(
            predicted.X,
            targetRoot.Position.Y,
            predicted.Z
        )
        flyStep(root, goal, dt, true)
        if (root.Position - targetRoot.Position).Magnitude
            <= (JARVIS_MELEE_RANGE or 12)
        then
            if not isJarvisProtectedFromAura(target, nil) then
                jarvisMeleeAttack(target)
            end
        end
        return true
    end
    JARVIS_PUNCHAURA_ACTIVE = false
    JARVIS_PUNCHAURA_TARGET = nil
    jarvisTargetHoldAtHide(root)
    if JARVIS_TARGET_KILL_PENDING then
        if targetHum.Health <= 0 then
            JARVIS_TARGET_KILL_PENDING = false
            JARVIS_TARGET_KILL_START_HEALTH = nil
            jarvisTargetHoldAtHide(root)
            return true
        end
        if now >= (JARVIS_TARGET_KILL_CHECK_AT or 0) then
            local startHealth = JARVIS_TARGET_KILL_START_HEALTH
            local unchanged =
                startHealth ~= nil
                and targetHum.Health >= startHealth
            JARVIS_TARGET_KILL_PENDING = false
            JARVIS_TARGET_KILL_START_HEALTH = nil
            if unchanged
                and now - (JARVIS_TARGET_KILL_LAST_RETRY or 0)
                    >= (JARVIS_TARGET_KILL_RETRY_COOLDOWN or 1.5)
            then
                JARVIS_TARGET_KILL_LAST_RETRY = now
                task.spawn(function()
                    local liveRoot = myRoot()
                    if not liveRoot then
                        return
                    end
                    jarvisTargetReleaseHide(liveRoot)
                    otherCmd("tp " .. target.Name)
                    task.wait(0.12)
                    if JARVIS_PRIORITY_TARGET_ACTIVE
                        and JARVIS_PRIORITY_TARGET == target
                        and target.Parent
                    then
                        otherCmd("kill " .. target.Name)
                    end
                    task.wait(0.18)
                    local returnRoot = myRoot()
                    if returnRoot
                        and JARVIS_PRIORITY_TARGET_ACTIVE
                        and JARVIS_PRIORITY_TARGET == target
                    then
                        jarvisTargetHoldAtHide(returnRoot)
                    end
                end)
            end
        end
        return true
    end
    if now - (JARVIS_PRIORITY_TARGET_LAST_ACTION or 0)
        >= (JARVIS_PRIORITY_TARGET_ACTION_DELAY or 0.75)
    then
        JARVIS_PRIORITY_TARGET_LAST_ACTION = now
        JARVIS_TARGET_KILL_START_HEALTH = targetHum.Health
        JARVIS_TARGET_KILL_PENDING = true
        JARVIS_TARGET_KILL_CHECK_AT =
            now + (JARVIS_TARGET_KILL_CHECK_DELAY or 1.25)
        otherCmd("kill " .. target.Name)
    end
    return true
end
JARVIS_SELF_RETALIATE_COOLDOWN = 1.0
JARVIS_SHOOTBACK_ENABLED = true
JARVIS_ANTIPUNCH_ENABLED = true
JARVIS_SELF_LAST_RETALIATE = {}
JARVIS_ANTIPUNCH_TARGET = nil
JARVIS_ANTIPUNCH_ACTIVE = false
JARVIS_ANTIPUNCH_RANGE = JARVIS_MELEE_RANGE or 12
JARVIS_SELF_DAMAGE_CONN = nil
JARVIS_SELF_CHAR_CONN = nil
function isJarvisOwnerPlayer(player)
    if not player then
        return false
    end
    if player.Name:lower() == masterLower then
        return true
    end
    local key = player.Name:lower()
    if extraOwners and extraOwners[key] then
        return true
    end
    if isWhitelistedPlayer
        and isWhitelistedPlayer(player)
    then
        return true
    end
    return false
end
function clearJarvisAntiPunch()
    JARVIS_ANTIPUNCH_TARGET = nil
    JARVIS_ANTIPUNCH_ACTIVE = false
end
function startJarvisAntiPunch(target)
    if not JARVIS_ANTIPUNCH_ENABLED then
        clearJarvisAntiPunch()
        return
    end
    if not target or target == bot then
        clearJarvisAntiPunch()
        return
    end
    if isJarvisOwnerPlayer(target) then
        clearJarvisAntiPunch()
        return
    end
    JARVIS_ANTIPUNCH_TARGET = target
    JARVIS_ANTIPUNCH_ACTIVE = true
end
function jarvisAntiPunchStep()
    if not JARVIS_ANTIPUNCH_ACTIVE then
        return
    end
    local target = JARVIS_ANTIPUNCH_TARGET
    if not target
        or not target.Parent
        or isJarvisOwnerPlayer(target)
    then
        clearJarvisAntiPunch()
        return
    end
    local myR = myRoot()
    local tr = rootOf(target)
    if not myR or not tr then
        clearJarvisAntiPunch()
        return
    end
    local distance = (myR.Position - tr.Position).Magnitude
    if distance > JARVIS_ANTIPUNCH_RANGE then
        clearJarvisAntiPunch()
        return
    end
    runJarvisMeleeAura(bot, nil)
end
function retaliateJarvisSelfDamage(attacker)
    if not attacker or attacker == bot then
        return
    end
    if isJarvisOwnerPlayer(attacker) then
        return
    end
    local now = os.clock()
    local key = attacker.UserId or attacker.Name
    if now - (JARVIS_SELF_LAST_RETALIATE[key] or 0)
        < JARVIS_SELF_RETALIATE_COOLDOWN
    then
        return
    end
    JARVIS_SELF_LAST_RETALIATE[key] = now
    if bot.Team and attacker.Team == bot.Team then
        if JARVIS_ANTIPUNCH_ENABLED then
            startJarvisAntiPunch(attacker)
        else
            clearJarvisAntiPunch()
        end
        return
    end
    clearJarvisAntiPunch()
    if JARVIS_SHOOTBACK_ENABLED then
        otherCmd(
            "loopkill "
            .. attacker.Name
            .. " 1"
        )
    end
end
function disconnectJarvisSelfDamageWatcher()
    if JARVIS_SELF_DAMAGE_CONN then
        JARVIS_SELF_DAMAGE_CONN:Disconnect()
        JARVIS_SELF_DAMAGE_CONN = nil
    end
    if JARVIS_SELF_CHAR_CONN then
        JARVIS_SELF_CHAR_CONN:Disconnect()
        JARVIS_SELF_CHAR_CONN = nil
    end
end
function attachJarvisSelfDamageWatcher()
    disconnectJarvisSelfDamageWatcher()
    local function hookCharacter(char)
        if not char then
            return
        end
        local hum =
            char:FindFirstChildOfClass("Humanoid")
            or char:WaitForChild("Humanoid", 8)
        if not hum then
            return
        end
        local lastHealth = hum.Health
        if JARVIS_SELF_DAMAGE_CONN then
            JARVIS_SELF_DAMAGE_CONN:Disconnect()
            JARVIS_SELF_DAMAGE_CONN = nil
        end
        JARVIS_SELF_DAMAGE_CONN =
            hum.HealthChanged:Connect(function(newHealth)
                if newHealth < lastHealth then
                    local attacker =
                        findLikelyProtectAttacker(bot)
                    if attacker then
                        retaliateJarvisSelfDamage(attacker)
                    end
                end
                lastHealth = newHealth
            end)
    end
    if bot.Character then
        hookCharacter(bot.Character)
    end
    JARVIS_SELF_CHAR_CONN =
        bot.CharacterAdded:Connect(function(char)
            clearJarvisAntiPunch()
            task.defer(function()
                hookCharacter(char)
            end)
        end)
end

-- Defensive modes stay enabled until explicitly turned off.
-- IMPORTANT: AntiPunch must NOT select arbitrary nearby players.
-- A response is only allowed after the existing damage/punch detector identifies
-- a specific attacker and calls startJarvisAntiPunch(attacker).
function disconnectProtectDamageWatcher()
    if JARVIS_PROTECT_DAMAGE_CONNECTION then
        pcall(function()
            JARVIS_PROTECT_DAMAGE_CONNECTION:Disconnect()
        end)
        JARVIS_PROTECT_DAMAGE_CONNECTION = nil
    end
    if JARVIS_PROTECT_CHARACTER_CONNECTION then
        pcall(function()
            JARVIS_PROTECT_CHARACTER_CONNECTION:Disconnect()
        end)
        JARVIS_PROTECT_CHARACTER_CONNECTION = nil
    end
    JARVIS_PROTECT_LAST_HEALTH = nil
end
function protectRayVisible(attacker, target)
    local ar = rootOf(attacker)
    local tr = rootOf(target)
    if not ar or not tr then
        return false
    end
    local origin = ar.Position + Vector3.new(0, 1.5, 0)
    local targetPos = tr.Position + Vector3.new(0, 1.2, 0)
    local direction = targetPos - origin
    if direction.Magnitude <= 0.01 then
        return true
    end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local exclude = {}
    if attacker.Character then
        table.insert(exclude, attacker.Character)
    end
    if bot.Character then
        table.insert(exclude, bot.Character)
    end
    params.FilterDescendantsInstances = exclude
    params.IgnoreWater = true
    local result = workspace:Raycast(
        origin,
        direction,
        params
    )
    if not result then
        return true
    end
    if target.Character
        and result.Instance
        and result.Instance:IsDescendantOf(target.Character)
    then
        return true
    end
    return false
end
function protectFacingScore(attacker, target)
    local ar = rootOf(attacker)
    local tr = rootOf(target)
    if not ar or not tr then
        return nil
    end
    local delta = tr.Position - ar.Position
    local distance = delta.Magnitude
    if distance <= 0.01
        or distance > JARVIS_PROTECT_ATTACK_SCAN_RANGE
    then
        return nil
    end
    local flatDelta = Vector3.new(
        delta.X,
        0,
        delta.Z
    )
    local flatFacing = Vector3.new(
        ar.CFrame.LookVector.X,
        0,
        ar.CFrame.LookVector.Z
    )
    if flatDelta.Magnitude <= 0.01
        or flatFacing.Magnitude <= 0.01
    then
        return nil
    end
    local facingDot =
        flatFacing.Unit:Dot(flatDelta.Unit)
    if facingDot < JARVIS_PROTECT_ATTACK_FACING_DOT then
        return nil
    end
    if not protectRayVisible(attacker, target) then
        return nil
    end
    local score =
        distance * 0.08
        + (1 - facingDot) * 35
    return score
end
function findLikelyProtectAttacker(target)
    if not target then
        return nil
    end
    local bestPlayer = nil
    local bestScore = math.huge
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= bot
            and p ~= target
            and p.Parent
        then
            local ph = humOf(p)
            if ph and ph.Health > 0 then
                local score =
                    protectFacingScore(p, target)
                if score
                    and score < bestScore
                then
                    bestScore = score
                    bestPlayer = p
                end
            end
        end
    end
    return bestPlayer
end
function retaliateProtectDamage(target)
    if not protecting or not target then
        return
    end
    local attacker =
        findLikelyProtectAttacker(target)
    if not attacker then
        print(
            "[JARVIS] protect damage detected, "
            .. "but no likely attacker found."
        )
        return
    end
    if attacker.Name:lower() == MASTER_NAME:lower() then
        return
    end
    if attacker == target then
        return
    end
    if isWhitelistedPlayer
        and isWhitelistedPlayer(attacker)
    then
        return
    end
    local now = os.clock()
    local key = attacker.UserId
    if now - (JARVIS_PROTECT_LAST_RETALIATE[key] or 0)
        < JARVIS_PROTECT_ATTACK_COOLDOWN
    then
        return
    end
    JARVIS_PROTECT_LAST_RETALIATE[key] = now
    print(
        "[JARVIS] protect retaliation -> .kill",
        attacker.Name
    )
    otherCmd("kill " .. attacker.Name)
end
function attachProtectDamageWatcher(target)
    disconnectProtectDamageWatcher()
    if not target then
        return
    end
    local function hookCharacter(char)
        if not char then
            return
        end
        local hum =
            char:FindFirstChildOfClass("Humanoid")
            or char:WaitForChild("Humanoid", 8)
        if not hum then
            return
        end
        JARVIS_PROTECT_LAST_HEALTH = hum.Health
        JARVIS_PROTECT_DAMAGE_CONNECTION =
            hum.HealthChanged:Connect(function(newHealth)
                local oldHealth =
                    JARVIS_PROTECT_LAST_HEALTH
                JARVIS_PROTECT_LAST_HEALTH =
                    newHealth
                if not protecting
                    or protectedPlayer ~= target
                then
                    return
                end
                if oldHealth
                    and newHealth < oldHealth
                then
                    task.defer(function()
                        retaliateProtectDamage(target)
                    end)
                end
            end)
    end
    if target.Character then
        hookCharacter(target.Character)
    end
    JARVIS_PROTECT_CHARACTER_CONNECTION =
        target.CharacterAdded:Connect(function(char)
            task.wait(0.25)
            if protecting
                and protectedPlayer == target
            then
                hookCharacter(char)
            end
        end)
end

-- SHOT -> .kill TARGET
-- Uses the same HealthChanged idea as Protect, but only acts after this client
-- has just fired while holding a Tool. It then chooses the damaged player that
-- was most plausibly in the shot direction and sends the normal admin .kill.
;(function()
    local env = getgenv()
    env.JARVIS_SHOTKILL_ENABLED = true
    env.JARVIS_SHOTKILL_WINDOW = 0.75
    env.JARVIS_SHOTKILL_MAX_RANGE = 500
    env.JARVIS_SHOTKILL_LAST_SHOT = 0
    env.JARVIS_SHOTKILL_CONNECTIONS = env.JARVIS_SHOTKILL_CONNECTIONS or {}

    local function clearPlayer(player)
        local old = env.JARVIS_SHOTKILL_CONNECTIONS[player]
        if old then
            for _, connection in ipairs(old) do
                pcall(function() connection:Disconnect() end)
            end
        end
        env.JARVIS_SHOTKILL_CONNECTIONS[player] = nil
    end

    local function holdingGunLikeTool()
        local char = bot.Character
        if not char then return false end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return false end
        -- Generic on purpose: you said you'll swap/limit the gun later.
        return true
    end

    local function plausibleShotVictim(player)
        if player == bot or not player.Character then
            return false
        end
        local camera = workspace.CurrentCamera
        local root = rootOf(player)
        if not camera or not root then
            return false
        end

        local delta = root.Position - camera.CFrame.Position
        local distance = delta.Magnitude
        if distance <= 0.01 or distance > env.JARVIS_SHOTKILL_MAX_RANGE then
            return false
        end

        -- Require the victim to be reasonably close to the direction the
        -- shooter was looking when the shot was fired.
        local dot = camera.CFrame.LookVector:Dot(delta.Unit)
        if dot < 0.94 then
            return false
        end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = bot.Character and {bot.Character} or {}
        params.IgnoreWater = true

        local hit = workspace:Raycast(
            camera.CFrame.Position,
            delta,
            params
        )

        return not hit
            or (hit.Instance and hit.Instance:IsDescendantOf(player.Character))
    end

    local function onDamaged(player, oldHealth, newHealth)
        if not env.JARVIS_SHOTKILL_ENABLED then return end
        if not oldHealth or newHealth >= oldHealth then return end
        if os.clock() - env.JARVIS_SHOTKILL_LAST_SHOT > env.JARVIS_SHOTKILL_WINDOW then
            return
        end
        if not plausibleShotVictim(player) then
            return
        end

        -- Consume this shot so one click cannot trigger several victims.
        env.JARVIS_SHOTKILL_LAST_SHOT = 0
        print("[JARVIS] shot target -> .kill", player.Name)
        otherCmd("kill " .. player.Name)
    end

    local function watchCharacter(player, character)
        clearPlayer(player)
        local connections = {}
        env.JARVIS_SHOTKILL_CONNECTIONS[player] = connections

        local hum = character:FindFirstChildOfClass("Humanoid")
            or character:WaitForChild("Humanoid", 8)
        if not hum then return end

        local lastHealth = hum.Health
        table.insert(connections, hum.HealthChanged:Connect(function(newHealth)
            local oldHealth = lastHealth
            lastHealth = newHealth
            onDamaged(player, oldHealth, newHealth)
        end))
    end

    local function watchPlayer(player)
        if player == bot then return end
        if player.Character then
            task.defer(watchCharacter, player, player.Character)
        end
        local list = env.JARVIS_SHOTKILL_CONNECTIONS[player] or {}
        env.JARVIS_SHOTKILL_CONNECTIONS[player] = list
        table.insert(list, player.CharacterAdded:Connect(function(character)
            task.wait(0.15)
            watchCharacter(player, character)
        end))
    end

    for _, player in ipairs(Players:GetPlayers()) do
        watchPlayer(player)
    end
    Players.PlayerAdded:Connect(watchPlayer)
    Players.PlayerRemoving:Connect(clearPlayer)

    -- Record a shot only while a Tool is equipped.
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            and holdingGunLikeTool()
        then
            env.JARVIS_SHOTKILL_LAST_SHOT = os.clock()
        end
    end)
end)()


-- CLIENT-ONLY GUN TARGET HOOK
-- Left click while holding any Tool -> identify the player under the mouse.
-- Replace/extend JARVIS_LOCAL_GUN_TARGET_CALLBACK for your own game's
-- authorized weapon/admin handling.
;(function()
    local env = getgenv()

    env.JARVIS_LOCAL_GUN_TARGET_ENABLED = true

    if type(env.JARVIS_LOCAL_GUN_TARGET_CALLBACK) ~= "function" then
        env.JARVIS_LOCAL_GUN_TARGET_CALLBACK = function(targetPlayer)
            print("[JARVIS] local gun target:", targetPlayer.Name)
        end
    end

    local function equippedTool()
        local character = bot.Character
        return character and character:FindFirstChildOfClass("Tool")
    end

    local function playerFromPart(part)
        if not part then return nil end

        local model = part:FindFirstAncestorOfClass("Model")
        while model do
            local player = Players:GetPlayerFromCharacter(model)
            if player then
                return player
            end
            model = model.Parent and model.Parent:FindFirstAncestorOfClass("Model")
        end

        return nil
    end

    local function targetUnderMouse()
        local mouse = bot:GetMouse()
        local target = mouse and mouse.Target
        local player = playerFromPart(target)

        if player and player ~= bot then
            return player
        end

        -- Fallback: client camera ray through current mouse position.
        local camera = workspace.CurrentCamera
        if not camera then return nil end

        local pos = UserInputService:GetMouseLocation()
        local ray = camera:ViewportPointToRay(pos.X, pos.Y)

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances =
            bot.Character and {bot.Character} or {}
        params.IgnoreWater = true

        local result = workspace:Raycast(
            ray.Origin,
            ray.Direction * 1000,
            params
        )

        return result and playerFromPart(result.Instance) or nil
    end

    UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not env.JARVIS_LOCAL_GUN_TARGET_ENABLED then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
            return
        end

        if not equippedTool() then
            return
        end

        local targetPlayer = targetUnderMouse()
        if not targetPlayer then
            return
        end

        local callback = env.JARVIS_LOCAL_GUN_TARGET_CALLBACK
        if type(callback) == "function" then
            task.spawn(callback, targetPlayer)
        end
    end)
end)()

function jarvisWhitelistName(name)
    return tostring(name or ""):lower()
end
function isJarvisProtectedFromAura(p, protected)
    if not p then
        return true
    end
    if p == bot then
        return true
    end
    if p.Name:lower() == MASTER_NAME:lower() then
        return true
    end
    if protected and p == protected then
        return true
    end
    if JARVIS_WHITELIST
        and JARVIS_WHITELIST[jarvisWhitelistName(p.Name)]
    then
        return true
    end
    if JARVIS_DYNAMIC_WHITELIST
        and JARVIS_DYNAMIC_WHITELIST[p.UserId]
    then
        return true
    end
    return false
end
function refreshPunchauraNearbyWhitelist(target)
    table.clear(JARVIS_DYNAMIC_WHITELIST)
    if not target then
        return
    end
    local tr = rootOf(target)
    if not tr then
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= bot then
            local pr = rootOf(p)
            if pr then
                local d = (pr.Position - tr.Position).Magnitude
                if d <= JARVIS_PUNCHAURA_NEARBY_WHITELIST_RADIUS
                    and p ~= target
                then
                    JARVIS_DYNAMIC_WHITELIST[p.UserId] = true
                end
            end
        end
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Name:lower() == MASTER_NAME:lower() then
            JARVIS_DYNAMIC_WHITELIST[p.UserId] = true
        end
    end
end
function getMeleeRemote()
    return ReplicatedStorage:FindFirstChild("meleeEvent")
        or ReplicatedStorage:FindFirstChild("MeleeEvent")
end
function jarvisMeleeAttack(target)
    if not target or target == bot then
        return
    end
    local now = os.clock()
    local key = target.UserId
    if now - (JARVIS_MELEE_LAST_HIT[key] or 0)
        < JARVIS_MELEE_HIT_COOLDOWN
    then
        return
    end
    local melee = getMeleeRemote()
    if not melee or not melee:IsA("RemoteEvent") then
        return
    end
    JARVIS_MELEE_LAST_HIT[key] = now
    pcall(function()
        melee:FireServer(target, 1, 1)
    end)
end
function runJarvisMeleeAura(centerPlayer, protectedPlayerForAura)
    local centerRoot = rootOf(centerPlayer or bot)
    if not centerRoot then
        return
    end
    for _, p in ipairs(Players:GetPlayers()) do
        if not isJarvisProtectedFromAura(p, protectedPlayerForAura) then
            local pr = rootOf(p)
            local ph = humOf(p)
            if pr
                and ph
                and ph.Health > 0
                and (pr.Position - centerRoot.Position).Magnitude <= JARVIS_MELEE_RANGE
            then
                local shouldSkip = false
                pcall(function()
                    local myTeamName = bot.Team and bot.Team.Name or ""
                    local theirTeamName = p.Team and p.Team.Name or ""
                    if myTeamName:lower():find("guard", 1, true)
                        and theirTeamName:lower():find("inmate", 1, true)
                        and p.Character
                        and not p.Character:GetAttribute("Hostile")
                    then
                        shouldSkip = true
                    end
                end)
                if not shouldSkip then
                    jarvisMeleeAttack(p)
                end
            end
        end
    end
end
function punchauraPredictionGoal(target)
    local tr = rootOf(target)
    if not tr then
        return nil
    end
    local velocity = tr.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(
        velocity.X,
        0,
        velocity.Z
    )
    local predicted =
        tr.Position
        + horizontalVelocity * JARVIS_PUNCHAURA_PREDICT
        + tr.CFrame.LookVector * JARVIS_PUNCHAURA_FRONT_DISTANCE
    return Vector3.new(
        predicted.X,
        tr.Position.Y,
        predicted.Z
    )
end
function punchauraStep(root, dt)
    local target = JARVIS_PUNCHAURA_TARGET
    if not JARVIS_PUNCHAURA_ACTIVE
        or not target
        or not target.Parent
    then
        return false
    end
    if invisFollow then
        return false
    end
    local goal = punchauraPredictionGoal(target)
    if goal then
        flyStep(
            root,
            goal,
            dt,
            true
        )
    end
    refreshPunchauraNearbyWhitelist(target)
    runJarvisMeleeAura(bot, nil)
    return true
end
JARVIS_RESPAWN_COMBO_DELAY = 1.25
function shouldAutoCombo2ForTeam()
    local teamName = ""
    if bot.Team then
        teamName = tostring(bot.Team.Name or ""):lower()
    end
    local teamColorName = ""
    pcall(function()
        teamColorName = tostring(bot.TeamColor.Name or ""):lower()
    end)
    local combined = teamName .. " " .. teamColorName
    if combined:find("criminal", 1, true)
        or combined:find("crim", 1, true)
    then
        return false
    end
    if combined:find("guard", 1, true)
        or combined:find("police", 1, true)
        or combined:find("inmate", 1, true)
        or combined:find("prisoner", 1, true)
    then
        return true
    end
    return false
end
function runRespawnCombo2()
    task.delay(JARVIS_RESPAWN_COMBO_DELAY, function()
        if not bot.Character or not bot.Character.Parent then
            return
        end
        if shouldAutoCombo2ForTeam() then
            print("[JARVIS] respawn team eligible -> .combo2")
            otherCmd("combo2")
        else
            print(
                "[JARVIS] respawn combo2 skipped for team:",
                bot.Team and bot.Team.Name or tostring(bot.TeamColor)
            )
        end
    end)
end
function disconnectProtection()
    if protectionCharacterConnection then
        pcall(function()
            protectionCharacterConnection:Disconnect()
        end)
        protectionCharacterConnection = nil
    end
    for _, connection in ipairs(protectionConnections) do
        if connection then
            pcall(function()
                connection:Disconnect()
            end)
        end
    end
    table.clear(protectionConnections)
    protectionConnection = nil
end
function watchProtectedPlayer(plr)
    protectedPlayer = plr
end
function sameProtectTeam(a, b)
    if not a or not b then
        return false
    end
    if a.Team ~= nil and b.Team ~= nil then
        return a.Team == b.Team
    end
    if a.TeamColor ~= nil and b.TeamColor ~= nil then
        return a.TeamColor == b.TeamColor
    end
    return false
end
function protectPunchAuraTarget(target)
    if not target or target == bot then
        return
    end
    otherCmd("punchaura " .. target.Name)
end
function protectKillTarget(target)
    if not target or target == bot then
        return
    end
    if isWhitelistedPlayer and isWhitelistedPlayer(target) then
        return
    end
    otherCmd("kill " .. target.Name)
end
function protectGuardScan()
    if not protecting then
        return
    end
    local protected = protectedPlayer or getMaster()
    local protectedRoot = rootOf(protected)
    if not protected or not protectedRoot then
        return
    end
    local now = os.clock()
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= bot
            and p ~= protected
            and p.Parent
        then
            local pr = rootOf(p)
            local ph = humOf(p)
            if pr
                and ph
                and ph.Health > 0
            then
                local distance =
                    (pr.Position - protectedRoot.Position).Magnitude
                if distance <= JARVIS_PROTECT_RADIUS then
                    local key = p.UserId
                    if now - (JARVIS_PROTECT_LAST_ACTION[key] or 0)
                        >= JARVIS_PROTECT_ACTION_COOLDOWN
                    then
                        JARVIS_PROTECT_LAST_ACTION[key] = now
                        if sameProtectTeam(protected, p) then
                            protectPunchAuraTarget(p)
                        else
                            protectKillTarget(p)
                        end
                    end
                end
            end
        end
    end
end
function protectOrbitStep(root, dt)
    if not protecting then
        return false
    end
    local protected = protectedPlayer or getMaster()
    local protectedRoot = rootOf(protected)
    if not protectedRoot then
        return true
    end
    releaseTrueIdleAnchor()
    setFly(true)
    JARVIS_PROTECT_ORBIT_ANGLE =
        (JARVIS_PROTECT_ORBIT_ANGLE
            + JARVIS_PROTECT_ORBIT_SPEED * dt)
        % (math.pi * 2)
    local offset = Vector3.new(
        math.cos(JARVIS_PROTECT_ORBIT_ANGLE)
            * JARVIS_PROTECT_ORBIT_RADIUS,
        0,
        math.sin(JARVIS_PROTECT_ORBIT_ANGLE)
            * JARVIS_PROTECT_ORBIT_RADIUS
    )
    local goal =
        protectedRoot.Position
        + offset
    goal = Vector3.new(
        goal.X,
        protectedRoot.Position.Y,
        goal.Z
    )
    flyStep(
        root,
        goal,
        dt,
        true
    )
    runJarvisMeleeAura(bot, protected)
    return true
end
function setFormation(name)
    name = string.lower(
        tostring(name or "")
    )
    local aliases = {
        v = "v",
        wedge = "v",
        diamond = "diamond",
        d = "diamond",
        wall = "wall",
        circle = "circle",
        ring = "circle",
        columns = "columns",
        column = "columns",
        dynamic = "dynamic",
        auto = "dynamic",
    }
    local selected =
        aliases[name]
    if not selected then
        voice(
            "formations: dynamic, v, diamond, wall, circle, columns"
        )
        return
    end
    formationType = selected
    voice(
        "formation "
        .. selected
    )
end
function firstArg(rest)
    return rest:match(
        "^(%S+)"
    ) or ""
end
function secondArg(rest)
    return rest:match(
        "^%S+%s+(%S+)"
    ) or ""
end
function normalizeCommandBody(body)
    body = tostring(body or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local lower = body:lower()
    local capture = lower:match("^eliminate%s+(.+)$")
        or lower:match("^take out%s+(.+)$")
        or lower:match("^go after%s+(.+)$")
    if capture then
        return "kill " .. capture
    end
    if lower == "come here" or lower == "follow me" or lower == "can you follow me" then
        return "follow"
    end
    if lower == "guard me" or lower == "protect me" then
        return "protect"
    end
    if lower == "hide" or lower == "go invisible" then
        return "invis"
    end
    if lower == "show" or lower == "be visible" then
        return "vis"
    end
    if lower == "halt" then
        return "stop"
    end
    return body
end
MASTER_BLOCKED_COMMANDS = {
    kill = true,
    loopkill = true,
    lk = true,
    kick = true,
    fling = true,
    hitbox = true,
    bring = true,
    punchaura = true,
    pa = true,
    unshare = true,
}
function isMasterReference(text)
    text = tostring(text or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local first = text:match("^(%S+)") or ""
    if first == "master" or first == masterLower then
        return true
    end
    local p = findPlayer(first)
    return (p and p.Name:lower() == masterLower) or false
end
function normalizeTeamName(name)
    name = tostring(name or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    name = name:gsub("%s+team$", "")
    if name:sub(-1) == "s" then
        name = name:sub(1, -2)
    end
    return name
end
function isWhitelistedPlayer(player)
    if not player then
        return false
    end
    if protecting
        and protectedPlayer
        and protectedPlayer == player
    then
        return true
    end
    return JARVIS_WHITELIST[player.Name:lower()] == true
end
function setWhitelisted(player, enabled)
    if not player then
        return false
    end
    local key = player.Name:lower()
    if enabled then
        JARVIS_WHITELIST[key] = true
    else
        JARVIS_WHITELIST[key] = nil
    end
    return true
end
function getWhitelistNames()
    local names = {}
    for username, enabled in pairs(JARVIS_WHITELIST) do
        if enabled then
            table.insert(names, username)
        end
    end
    table.sort(names)
    return names
end
function resolveTeamSelector(rest)
    rest = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local requested = rest:match("^[Tt][Ee][Aa][Mm]%s+(.+)$")
    if not requested or requested == "" then
        return nil
    end
    local wanted = normalizeTeamName(requested)
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team and normalizeTeamName(player.Team.Name) == wanted then
            return player.Team
        end
    end
    return nil
end
function whitelistAwareTeamKill(cmd, rest)
    cmd = tostring(cmd or ""):lower()
    if cmd ~= "kill"
        and cmd ~= "loopkill"
        and cmd ~= "lk"
        and cmd ~= "k"
    then
        return false
    end
    local team = resolveTeamSelector(rest)
    if not team then
        return false
    end
    local teamPlayers = {}
    local hasProtectedMember = false
    local function isProtectedTeamMember(player)
        if not player then
            return false
        end
        if isWhitelistedPlayer(player) then
            return true
        end
        if isOwnerName(player.Name) then
            return true
        end
        return false
    end
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Team == team then
            table.insert(teamPlayers, player)
            if isProtectedTeamMember(player) then
                hasProtectedMember = true
            end
        end
    end
    if not hasProtectedMember then
        otherCmd(
            "kill team "
            .. team.Name
        )
        return true
    end
    local protectedCount = 0
    local loopkilled = 0
    local LOOPKILL_TEAM_RADIUS = 800
    local botRoot = myRoot()
    for _, player in ipairs(teamPlayers) do
        if isProtectedTeamMember(player) then
            protectedCount += 1
        else
            local targetRoot = rootOf(player)
            local withinRadius = false
            if botRoot and targetRoot then
                withinRadius =
                    (targetRoot.Position - botRoot.Position).Magnitude
                    <= LOOPKILL_TEAM_RADIUS
            end
            if withinRadius then
                otherCmd(
                    "kill "
                    .. player.Name
                )
                loopkilled += 1
            end
        end
    end
    voice(
        "access protected "
        .. tostring(protectedCount)
        .. " player"
        .. (protectedCount == 1 and "" or "s")
        .. " on "
        .. team.Name
        .. ". kill sent to "
        .. tostring(loopkilled)
        .. "."
    )
    return true
end
function handleJarvisKillCommand(cmd, rest)
    if cmd ~= "kill" and cmd ~= "k" then
        return false
    end
    rest = tostring(rest or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
    if rest == "" then
        return true
    end
    if whitelistAwareTeamKill(cmd, rest) then
        return true
    end
    local targetText, countText =
        rest:match("^(.-)%s+(%d+)$")
    if not targetText then
        targetText = rest
        countText = nil
    end
    targetText = targetText
        :gsub("^%s+", "")
        :gsub("%s+$", "")
    local target = findPlayer(targetText)
    if target and isWhitelistedPlayer(target) then
        voice(target.Name .. " is protected.")
        return true
    end
    local resolvedTarget =
        target and target.Name or targetText
    local count = tonumber(countText)
    if count and count >= 2 then
        otherCmd(
            "loopkill "
            .. resolvedTarget
            .. " "
            .. tostring(math.floor(count))
        )
    else
        otherCmd(
            "kill "
            .. resolvedTarget
        )
    end
    return true
end
function teamSelectorIncludesMaster(rest)
    rest = tostring(rest or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
    local teamName = rest:match("^team%s+(.+)$")
    if not teamName then
        return false
    end
    local master = getMaster()
    if not master or not master.Team then
        return false
    end
    local wanted = normalizeTeamName(teamName)
    local actual = normalizeTeamName(master.Team.Name)
    return wanted ~= "" and wanted == actual
end
function revokeOwnerAccess(fromName, reason, retaliate)
    if not fromName or fromName:lower() == masterLower then
        return false
    end
    local key = fromName:lower()
    extraOwners[key] = nil
    revokedOwners[key] = true
    ownerTeamStrikes[key] = nil
    local p = findPlayer(fromName)
    if p and targetPlayer == p then
        targetPlayer = getMaster()
        followCamPlayer = getMaster()
        followPosition = "center"
        mode = "follow"
        invisFollow = false
    end
    say("WARNING: " .. fromName .. " cannot target the permanent owner. Access revoked.")
    if retaliate ~= false then
        otherCmd("kill " .. fromName)
    end
    print("[JARVIS] OWNER ACCESS REVOKED:", fromName, reason or "blocked")
    return true
end
function blockMasterAttack(body, fromName)
    if fromName and fromName:lower() == masterLower then
        return false
    end
    local clean = tostring(body or "")
        :gsub("^%s+", "")
        :gsub("%s+$", "")
    if clean:sub(1, 1) == "."
        or clean:sub(1, 1) == ";"
    then
        clean = clean:sub(2)
    end
    local cmd, rest = clean:match("^(%S+)%s*(.*)$")
    cmd = (cmd or ""):lower()
    rest = rest or ""
    if not MASTER_BLOCKED_COMMANDS[cmd] then
        return false
    end
    if isMasterReference(rest) then
        return revokeOwnerAccess(
            fromName,
            cmd .. " permanent owner",
            true
        )
    end
    return false
end
HIDE_BLOCKED_COMMANDS = {
    follow = true, unfollow = true, loopfollow = true, unloopfollow = true,
    line = true, unline = true,
    left = true, right = true, center = true, centre = true, middle = true,
    formation = true, form = true,
    orbit = true, unorbit = true, spiral = true, unspiral = true,
    guard = true, unguard = true,
    scout = true, unscout = true,
    patrol = true, unpatrol = true,
    surround = true, unsurround = true,
    assemble = true, regroup = true, disperse = true, ["return"] = true,
    protect = true, unprotect = true,
    invis = true, invisible = true, vis = true, uninvis = true, visible = true,
    invisfollow = true, cloakfollow = true,
    fly = true, unfly = true,
    speed = true, autospeed = true,
    freeze = true, unfreeze = true, thaw = true,
    recall = true, face = true, front = true, behind = true, above = true, below = true,
    followdist = true, sidedist = true, cloakdepth = true, vertical = true,
    recover = true, unstuck = true, park = true, unpark = true, resetoffsets = true,
}
function enterHideLock()
    hiddenLock = true
    mode = "idle"
    orbiting = false
    dancing = false
    protecting = false
    guardMode = false
    invisFollow = false
    orbitTarget = nil
    targetPlayer = nil
    followCamPlayer = nil
    invisPosition = nil
    groundLock = false
    local root = myRoot()
    local hum = myHum()
    if hum then
        hum.Sit = false
    end
    if root then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
        root.CFrame = HIDE_CFRAME
    end
end
function leaveHideLock()
    hiddenLock = false
    mode = "idle"
    targetPlayer = nil
    followCamPlayer = nil
    invisPosition = nil
    orbiting = false
    dancing = false
    protecting = false
    guardMode = false
    groundLock = false
end
local function getHostUserId()
    if HOST_NAME == "" then return nil end
    local ok, id = pcall(function()
        return Players:GetUserIdFromNameAsync(HOST_NAME)
    end)
    return ok and id or nil
end

local function callHostServer()
    if IS_LEADER then return false, "Host cannot call itself." end
    local hostId = getHostUserId()
    if not hostId then return false, "Host not found." end
    local ok, _, _, placeId, jobId = pcall(function()
        return TeleportService:GetPlayerPlaceInstanceAsync(hostId)
    end)
    if not ok or type(placeId) ~= "number" or type(jobId) ~= "string" or jobId == "" then
        return false, "Host server could not be found."
    end
    if placeId == game.PlaceId and jobId == game.JobId then
        return true, "Already with Host."
    end
    savePersistentState(true)
    local teleported = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, bot)
    end)
    return teleported, teleported and "Joining Host..." or "Teleport failed."
end

function handle(body, fromName)
    if IS_LEADER then
        return
    end
    body = tostring(body or "")
    body = body:gsub(
        "^%s+",
        ""
    )
    body = body:gsub(
        "%s+$",
        ""
    )
    body = normalizeCommandBody(body)
    if body == "" then
        return
    end
    if tostring(body):lower() == "call" then
        if tostring(fromName or ""):lower() ~= masterLower then
            voice("access denied.")
            return
        end
        local ok, message = callHostServer()
        voice(message)
        return
    end
    sessionCommandCount =
        sessionCommandCount + 1
    lastCommand = body
    do
        local preCmd, preRest = tostring(body or ""):match("^(%S+)%s*(.*)$")
        preCmd = (preCmd or ""):gsub("^[%.;]", ""):lower()
        preRest = preRest or ""
        if whitelistAwareTeamKill(preCmd, preRest) then
            return
        end
    end
    if blockMasterAttack(body, fromName) then
        return
    end
    if body:sub(1, 1) == "."
        or body:sub(1, 1) == ";"
    then
        local rawClean = body:sub(2)
        local rawCmd, rawRest = rawClean:match("^(%S+)%s*(.*)$")
        rawCmd = (rawCmd or ""):lower()
        rawRest = rawRest or ""
        if whitelistAwareTeamKill(rawCmd, rawRest) then
            return
        end
        otherCmd(body)
        return
    end
    local cmd, rest =
        body:match(
            "^(%S+)%s*(.*)$"
        )
    cmd = string.lower(
        cmd or ""
    )
    rest = rest or ""
    local speaker =
        findPlayer(fromName)
    if getgenv().JARVIS_ACTION_COMMAND
        and getgenv().JARVIS_ACTION_COMMAND(cmd, rest)
    then
        return
    end

    if cmd == "kx" then
        if tostring(fromName or ""):lower() ~= masterLower then
            voice("kx access denied.")
            return
        end
        local setting = tostring(rest or ""):lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        if setting == "off"
            or setting == "0"
            or setting == "false"
        then
            JARVIS_KX_ADMIN_ENABLED = false
            voice("kx off. admin commands disabled.")
        elseif setting == "on"
            or setting == "1"
            or setting == "true"
        then
            JARVIS_KX_ADMIN_ENABLED = true
            voice("kx on. admin commands enabled.")
        else
            voice(
                "kx is "
                .. (JARVIS_KX_ADMIN_ENABLED and "on." or "off.")
                .. " use kx on or kx off."
            )
        end
        return
    end
    if cmd == "hide" then
        enterHideLock()
        voice("hide lock active. movement commands disabled.")
        return
    end
    if cmd == "unhide" then
        leaveHideLock()
        voice("hide lock released. movement commands restored.")
        return
    end
    if hiddenLock
        and HIDE_BLOCKED_COMMANDS[cmd]
        and tostring(fromName or ""):lower() ~= masterLower
    then
        voice("access denied. JARVIS is hidden. use eagle unhide first.")
        return
    end
    if cmd == "panic" then
        stopMove()
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        invisFollow = false
        invisPosition = nil
        protecting = false
        protectedPlayer = nil
        guardMode = false
        orbiting = false
        dancing = false
        punchOn = false
        spinning = false
        disconnectProtection()
        restoreOwnCam()
        setFly(false)
        pcall(function() otherCmd("antifling on") end)
        voice("emergency reset complete.")
        return
    end
    if cmd == "freeze" then
        local root = myRoot()
        if root then
            freezeCFrame = root.CFrame
            frozen = true
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            voice("position frozen.")
        end
        return
    end
    if cmd == "unfreeze" or cmd == "thaw" then
        frozen = false
        freezeCFrame = nil
        voice("position released.")
        return
    end
    if cmd == "mark" then
        local root = myRoot()
        if not root then return end
        local markName = firstArg(rest):lower()
        if markName == "" then markName = "default" end
        savedMarks[markName] = root.CFrame
        voice("saved mark " .. markName .. ".")
        return
    end
    if cmd == "recall" then
        local markName = firstArg(rest):lower()
        if markName == "" then markName = "default" end
        local cf = savedMarks[markName]
        local root = myRoot()
        if not cf then
            voice("mark not found: " .. markName)
            return
        end
        if root then
            stopMove()
            setFly(true)
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = cf
            voice("recalled " .. markName .. ".")
        end
        return
    end
    if cmd == "marks" then
        local names = {}
        for name in pairs(savedMarks) do table.insert(names, name) end
        table.sort(names)
        voice(#names > 0 and ("marks: " .. table.concat(names, ", ")) or "no saved marks.")
        return
    end
    if cmd == "target" then
        local p = findPlayer(firstArg(rest)) or speaker
        if not p then
            voice("target not found.")
            return
        end
        pcall(function()
            otherCmd("unloopkill all")
        end)
        if not setJarvisPriorityTarget(p) then
            voice("that player is protected.")
            return
        end
        releaseTrueIdleAnchor()
        setFly(true)
        local sameTeam =
            bot.Team ~= nil
            and p.Team ~= nil
            and bot.Team == p.Team
        if sameTeam then
            voice("target " .. p.Name .. ". same team: PA focus.")
        else
            voice("target " .. p.Name .. ". enemy team: kill focus.")
        end
        return
    end
    if cmd == "distance" or cmd == "dist" then
        local p = findPlayer(firstArg(rest)) or activeTarget()
        local root = myRoot()
        local tr = rootOf(p)
        if root and tr and p then
            local d = (root.Position - tr.Position).Magnitude
            voice(string.format("%s distance %.1f studs.", p.Name, d))
        else
            voice("distance unavailable.")
        end
        return
    end
    if cmd == "face" then
        local p = findPlayer(firstArg(rest)) or activeTarget() or speaker
        local root = myRoot()
        local tr = rootOf(p)
        if root and tr then
            root.CFrame = CFrame.lookAt(root.Position, Vector3.new(tr.Position.X, root.Position.Y, tr.Position.Z))
            voice("facing " .. p.Name .. ".")
        end
        return
    end
    if cmd == "followdist" then
        local n = tonumber(firstArg(rest))
        if n then followDistance = math.clamp(n, 1, 50) end
        voice("follow distance " .. tostring(followDistance) .. ".")
        return
    end
    if cmd == "sidedist" then
        local n = tonumber(firstArg(rest))
        if n then sideDistance = math.clamp(n, 0, 50) end
        voice("side distance " .. tostring(sideDistance) .. ".")
        return
    end
    if cmd == "cloakdepth" then
        local n = tonumber(firstArg(rest))
        if n then cloakDepth = math.clamp(n, 2, 30) end
        voice("cloak depth " .. tostring(cloakDepth) .. ".")
        return
    end
    if cmd == "vertical" or cmd == "above" or cmd == "below" then
        local n
        if cmd == "above" then
            n = tonumber(firstArg(rest)) or 5
            n = math.abs(n)
        elseif cmd == "below" then
            n = -(math.abs(tonumber(firstArg(rest)) or 5))
        else
            n = tonumber(firstArg(rest))
        end
        if n then followVerticalOffset = math.clamp(n, -30, 30) end
        voice("follow vertical " .. tostring(followVerticalOffset) .. ".")
        return
    end
    if cmd == "selfcheck" or cmd == "diag" or cmd == "diagnostics" then
        local root = myRoot()
        local hum = myHum()
        local target = activeTarget()
        local tr = rootOf(target)
        local dist = (root and tr) and (root.Position - tr.Position).Magnitude or -1
        local report = string.format(
            "check mode=%s target=%s dist=%.1f fly=%s noclip=%s hidden=%s frozen=%s protect=%s speed=%d",
            tostring(mode), target and target.Name or "none", dist,
            tostring(flying), tostring(noclipOn), tostring(hiddenLock), tostring(frozen),
            tostring(protecting), math.floor(flySpeed)
        )
        print("[JARVIS SELF-CHECK] " .. report)
        voice(report)
        return
    end
    if cmd == "nearest" or cmd == "near" then
        local root = myRoot()
        if not root then return end
        local best, bestDist = nil, math.huge
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= bot then
                local r = rootOf(p)
                if r then
                    local d = (r.Position - root.Position).Magnitude
                    if d < bestDist then
                        best, bestDist = p, d
                    end
                end
            end
        end
        if best then
            targetPlayer = best
            followCamPlayer = best
            voice(string.format("nearest target %s at %.1f studs.", best.Name, bestDist))
        else
            voice("no nearby target found.")
        end
        return
    end
    if cmd == "untarget" then
        targetPlayer = getMaster()
        followCamPlayer = targetPlayer
        voice("target returned to permanent owner.")
        return
    end
    if cmd == "where" or cmd == "coords" then
        local root = myRoot()
        if root then
            local p = root.Position
            voice(string.format("position X %.1f Y %.1f Z %.1f", p.X, p.Y, p.Z))
            print(string.format("[JARVIS COORDS] Vector3.new(%.6f, %.6f, %.6f)", p.X, p.Y, p.Z))
        end
        return
    end
    if cmd == "recover" or cmd == "unstuck" then
        local root = myRoot()
        local hum = myHum()
        if root then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
        end
        if hum then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        stuckTimer = 0
        lastPosition = root and root.Position or nil
        setFly(true)
        voice("movement recovery complete.")
        return
    end
    if cmd == "resetoffsets" then
        followDistance = FOLLOW_DIST
        sideDistance = SIDE
        followVerticalOffset = 0
        cloakDepth = INVIS_DEPTH
        voice("movement offsets reset to defaults.")
        return
    end
    if cmd == "settings" then
        voice(string.format(
            "settings fd %.1f side %.1f vertical %.1f cloak %.1f speed %d chat %.2fs saved=%s",
            followDistance, sideDistance, followVerticalOffset, cloakDepth,
            math.floor(flySpeed + 0.5), adaptiveChatDelay,
            tostring(persistentCanUse())
        ))
        return
    end
    if cmd == "cmdspeed" then
        voice(string.format(
            "adaptive command-chat interval %.2fs, queued %d, sent %d.",
            adaptiveChatDelay, #sayQ, chatMessagesSent
        ))
        return
    end
    if cmd == "park" then
        local root = myRoot()
        if root then
            frozen = true
            freezeCFrame = root.CFrame
            mode = "idle"
            orbiting = false
            dancing = false
            guardMode = false
            voice("parked in place.")
        end
        return
    end
    if cmd == "unpark" then
        frozen = false
        freezeCFrame = nil
        voice("park released.")
        return
    end
    if cmd == "say" then
        voice(rest)
        return
    end
    if cmd == "shut" then
        shut = true
        return
    end
    if cmd == "unshut" then
        shut = false
        voice("JARVIS voice restored.")
        return
    end
    if cmd == "slot" then
        local who =
            firstArg(rest)
        local num =
            tonumber(
                rest:match(
                    "%S+%s+(%d+)"
                )
            )
        if who ~= ""
            and num
        then
            local p =
                findPlayer(who)
            if who:lower()
                == bot.Name:lower()
                or (
                    p
                    and p.UserId
                        == bot.UserId
                )
            then
                manualSlot =
                    math.clamp(
                        num,
                        1,
                        MAX_SLOTS
                    )
                mySlot =
                    manualSlot
                voice(
                    "assigned "
                    .. getJarvisName()
                )
            end
        end
        return
    end
    if cmd == "slots" then
        manualSlot = nil
        refreshSlot()
        voice(
            "automatic slot "
            .. tostring(mySlot)
        )
        return
    end
    if cmd == "who"
        or cmd == "hello"
        or cmd == "hi"
    then
        voice(
            "I am "
            .. getJarvisName()
            .. "."
        )
        return
    end
    if cmd == "nosit" or cmd == "stand" then
        setNoSit(true)
        local hum = myHum()
        if hum then
            hum.Sit = false
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        voice("sitting disabled.")
        return
    end
    if cmd == "sit" then
        local arg = firstArg(rest):lower()
        if arg == "on" then
            setNoSit(false)
            voice("sitting allowed.")
        elseif arg == "off" then
            setNoSit(true)
            local hum = myHum()
            if hum then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            voice("sitting disabled.")
        else
            voice(noSit and "sitting is off. use eagle sit on." or "sitting is on. use eagle sit off.")
        end
        return
    end
    if cmd == "unpunchaura" or cmd == "unpa" then
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        table.clear(JARVIS_DYNAMIC_WHITELIST)
        voice("punchaura disabled.")
        return
    end
    if cmd == "protect" then
        local requestedName =
            tostring(rest or "")
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        local p = nil
        if requestedName ~= "" then
            p = findPlayer(requestedName)
        end
        p = p or speaker or getMaster()
        if not p then
            voice("protect target not found.")
            return
        end
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        table.clear(JARVIS_DYNAMIC_WHITELIST)
        protecting = true
        protectedPlayer = p
        targetPlayer = p
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        releaseTrueIdleAnchor()
        setFly(true)
        attachProtectDamageWatcher(p)
        followCamPlayer = p
        local keepInvis = invisFollow == true
        if not keepInvis then
            mode = "idle"
            invisPosition = nil
            groundLock = false
        end
        orbiting = false
        dancing = false
        guardMode = false
        JARVIS_PROTECT_ORBIT_ANGLE = 0
        table.clear(JARVIS_PROTECT_LAST_ACTION)
        refreshSlot()
        releaseTrueIdleAnchor()
        setFly(true)
        disconnectProtection()
        lockCam(p)
        voice(
            "protecting "
            .. p.Name
            .. ". ten stud orbit guard active."
        )
        return
    end
    if cmd == "unprotect" then
        protecting = false
        disconnectProtectDamageWatcher()
        protectedPlayer = nil
        targetPlayer = nil
        setFly(false)
        table.clear(JARVIS_PROTECT_LAST_ACTION)
        disconnectProtection()
        voice("protection disabled.")
        return
    end
    if cmd == "invis"
        or cmd == "invisible"
    then
        local requestedName = firstArg(rest)
        local p = nil
        if requestedName ~= "" then
            p = findPlayer(requestedName)
        end
        p = p or speaker or activeTarget() or getMaster()
        if not p then
            voice("target not found.")
            return
        end
        otherCmd("invis")
        invisFollow = true
        invisPosition = nil
        resetInvisibleFloorLatch(p)
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        groundLock = false
        targetPlayer = p
        followCamPlayer = p
        mode = "loopfollow"
        setFly(true)
        lockCam(p)
        voice("cloak active under " .. p.Name .. ".")
        return
    end
    if cmd == "invisfollow"
        or cmd == "cloakfollow"
    then
        local name =
            firstArg(rest)
        local p
        if name ~= "" then
            p = findPlayer(name)
        else
            p = speaker or activeTarget() or getMaster()
        end
        if not p then
            voice("target not found.")
            return
        end
        otherCmd("invis")
        invisFollow = true
        invisPosition = nil
        resetInvisibleFloorLatch(p)
        groundLock = false
        targetPlayer = p
        followCamPlayer = p
        mode = "loopfollow"
        setFly(true)
        lockCam(p)
        voice(
            "cloak follow "
            .. p.Name
        )
        return
    end
    if cmd == "vis"
        or cmd == "uninvis"
        or cmd == "visible"
    then
        invisFollow = false
        invisPosition = nil
        resetInvisibleFloorLatch(nil)
        removeCloakYHold()
        groundLock = not (mode == "follow" or mode == "loopfollow")
        otherCmd("vis")
        voice(
            "cloak disabled."
        )
        return
    end
    if cmd == "punchaura" or cmd == "pa" then
        local requestedName = firstArg(rest)
        if requestedName == "" then
            voice("punchaura target required.")
            return
        end
        local p = findPlayer(requestedName)
        if not p then
            voice("punchaura target not found.")
            return
        end
        protecting = false
        protectedPlayer = nil
        JARVIS_PUNCHAURA_ACTIVE = true
        JARVIS_PUNCHAURA_TARGET = p
        targetPlayer = p
        followCamPlayer = p
        mode = "idle"
        orbiting = false
        dancing = false
        guardMode = false
        invisFollow = false
        invisPosition = nil
        groundLock = false
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        refreshPunchauraNearbyWhitelist(p)
        refreshSlot()
        releaseTrueIdleAnchor()
        setFly(true)
        lockCam(p)
        voice(
            "punchaura tracking "
            .. p.Name
            .. ". predictive front follow active."
        )
        return
    end
    if cmd == "share1" or cmd == "share2" or cmd == "share" then
        if fromName:lower() ~= masterLower then
            voice("access denied.")
            return
        end

        local level = (cmd == "share2") and 2 or 1
        local p = findPlayer(firstArg(rest))
        if p then
            local key = p.Name:lower()
            extraOwners[key] = true
            sharedAccessLevel[key] = level
            revokedOwners[key] = nil
            voice("shared access " .. tostring(level) .. " complete: " .. p.Name)
            refreshSlot()
            savePersistentState(true)
        else
            voice("shared access " .. tostring(level) .. " incomplete: player not found.")
        end
        return
    end
    if cmd == "unshare" then
        if isMasterReference(rest) and fromName:lower() ~= masterLower then
            punishOwnerViolation(fromName, "unshare permanent owner")
            return
        end
        if fromName:lower() ~= masterLower then
            voice("only the permanent owner can unshare access.")
            return
        end
        local name =
            firstArg(rest)
        local p =
            findPlayer(name)
        if p then
            extraOwners[
                p.Name:lower()
            ] = nil
            sharedAccessLevel[p.Name:lower()] = nil
        else
            extraOwners[
                name:lower()
            ] = nil
            sharedAccessLevel[name:lower()] = nil
        end
        refreshSlot()
        savePersistentState(true)
        return
    end
    if cmd == "owners" then
        local owners = {
            MASTER_NAME
        }
        for name in pairs(
            extraOwners
        ) do
            table.insert(
                owners,
                name
            )
        end
        voice(
            "owners: "
            .. table.concat(
                owners,
                ", "
            )
        )
        return
    end
    if cmd == "speed" then
        local value =
            tonumber(
                firstArg(rest)
            )
        if not value then
            voice(
                "speed "
                .. tostring(
                    math.floor(flySpeed)
                )
            )
            return
        end
        flySpeed =
            math.clamp(
                value,
                MIN_SPEED,
                MAX_SPEED
            )
        manualSpeedOverride = true
        voice(
            "manual speed "
            .. tostring(
                math.floor(flySpeed)
            )
        )
        return
    end
    if cmd == "autospeed" then
        manualSpeedOverride = false
        updateAutomaticSpeed()
        voice(
            "automatic speed "
            .. tostring(
                math.floor(flySpeed)
            )
        )
        return
    end
    if cmd == "formation"
        or cmd == "form"
    then
        setFormation(
            firstArg(rest)
        )
        return
    end
    if cmd == "orbit" then
        local name =
            firstArg(rest)
        local p =
            name ~= ""
            and findPlayer(name)
            or getMaster()
        if not p then
            voice("orbit target not found.")
            return
        end
        local radius =
            tonumber(
                secondArg(rest)
            )
        if radius then
            orbitRadius =
                math.clamp(
                    radius,
                    MIN_ORBIT_RADIUS,
                    MAX_ORBIT_RADIUS
                )
        end
        orbitTarget = p
        orbitAngle = 0
        orbiting = true
        dancing = false
        protecting = false
        targetPlayer = p
        mode = "orbit"
        setFly(true)
        lockCam(p)
        voice(
            "orbiting "
            .. p.Name
        )
        return
    end
    if cmd == "unorbit" then
        orbiting = false
        orbitTarget = nil
        returnToMaster()
        voice("orbit disabled.")
        return
    end
    if cmd == "spiral" then
        local p =
            findPlayer(
                firstArg(rest)
            )
            or getMaster()
        if not p then
            voice("spiral target not found.")
            return
        end
        orbitTarget = p
        orbitAngle = 0
        orbitRadius =
            DEFAULT_ORBIT_RADIUS
        orbiting = true
        dancing = true
        protecting = false
        targetPlayer = p
        mode = "orbit"
        setFly(true)
        lockCam(p)
        voice(
            "spiral protocol active."
        )
        return
    end
    if cmd == "unspiral" then
        orbiting = false
        dancing = false
        returnToMaster()
        return
    end
    if cmd == "dance" then
        local arg = firstArg(rest):lower()
        local danceNumber = tonumber(arg)
        if danceNumber then
            danceNumber = math.clamp(math.floor(danceNumber), 1, 3)
            say("/e dance" .. tostring(danceNumber))
            voice("dance " .. tostring(danceNumber) .. ".")
            return
        end
        local p =
            findPlayer(arg)
            or getMaster()
        if not p then
            voice("dance target not found.")
            return
        end
        orbitTarget = p
        orbitRadius = DEFAULT_ORBIT_RADIUS
        dancing = true
        orbiting = true
        danceTime = 0
        protecting = false
        mode = "dance"
        targetPlayer = p
        setFly(true)
        voice("dance protocol engaged.")
        return
    end
    if cmd == "undance" then
        dancing = false
        orbiting = false
        returnToMaster()
        return
    end
    if cmd == "cheer" or cmd == "laugh" or cmd == "point" then
        say("/e " .. cmd)
        return
    end
    if cmd == "wave" then
        local root = myRoot()
        if root then
            local base =
                root.CFrame
            task.spawn(function()
                for i = 1, 6 do
                    if not root.Parent then
                        break
                    end
                    root.CFrame =
                        base
                        * CFrame.new(
                            math.sin(i)
                                * 1.5,
                            0,
                            0
                        )
                    task.wait(0.12)
                end
            end)
        end
        voice("hello, commander.")
        return
    end
    if cmd == "salute" then
        local root = myRoot()
        if root then
            local base =
                root.CFrame
            task.spawn(function()
                root.CFrame =
                    base
                    * CFrame.Angles(
                        0,
                        0,
                        math.rad(-25)
                    )
                task.wait(0.5)
                if root.Parent then
                    root.CFrame = base
                end
            end)
        end
        voice("at your service.")
        return
    end
    if cmd == "bounce" then
        local root = myRoot()
        if root then
            local base =
                root.Position
            task.spawn(function()
                for i = 1, 6 do
                    if not root.Parent then
                        break
                    end
                    local offset =
                        math.sin(
                            (i / 6)
                            * math.pi
                        ) * 4
                    root.CFrame =
                        CFrame.new(
                            base
                            + Vector3.new(
                                0,
                                offset,
                                0
                            )
                        )
                    task.wait(0.08)
                end
            end)
        end
        return
    end
    if cmd == "guard"
        or cmd == "surround"
    then
        guardMode = true
        protecting = false
        targetPlayer = getMaster()
        followCamPlayer = getMaster()
        mode = "guard"
        setFly(true)
        lockCam(getMaster())
        voice(
            "guard formation deployed."
        )
        return
    end
    if cmd == "unguard"
        or cmd == "unsurround"
    then
        guardMode = false
        returnToMaster()
        voice("guard formation dismissed.")
        return
    end
    if cmd == "scout" then
        scoutOrigin = nil
        scoutReturning = false
        mode = "scout"
        protecting = false
        targetPlayer = getMaster()
        setFly(true)
        voice(
            "scouting ahead."
        )
        return
    end
    if cmd == "unscout" then
        scoutReturning = true
        returnToMaster()
        voice("scout returning.")
        return
    end
    if cmd == "patrol" then
        patrolOrigin = nil
        patrolAngle = 0
        mode = "patrol"
        protecting = false
        setFly(true)
        voice(
            "patrol route active."
        )
        return
    end
    if cmd == "unpatrol" then
        returnToMaster()
        voice("patrol complete.")
        return
    end
    if cmd == "assemble"
        or cmd == "regroup"
        or cmd == "return"
    then
        formationType = "dynamic"
        orbiting = false
        dancing = false
        guardMode = false
        protecting = false
        invisFollow = false
        invisPosition = nil
        targetPlayer = getMaster()
        followCamPlayer = getMaster()
        mode = "follow"
        groundLock = true
        setFly(true)
        lockCam(getMaster())
        voice(
            "squad assembled."
        )
        return
    end
    if cmd == "disperse" then
        local root = myRoot()
        if root then
            local index =
                getUnitIndex()
            local angle =
                index * 1.7
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local pos =
                    masterRoot.Position
                    + Vector3.new(
                        math.cos(angle)
                            * 25,
                        0,
                        math.sin(angle)
                            * 25
                    )
                mode = "follow"
                targetPlayer = getMaster()
                setFly(true)
                task.spawn(function()
                    flyStep(
                        root,
                        pos,
                        1,
                        true
                    )
                end)
            end
        end
        voice("squad dispersed.")
        return
    end
    if cmd == "halt" then
        mode = "idle"
        orbiting = false
        dancing = false
        protecting = false
        guardMode = false
        targetPlayer = nil
        local root = myRoot()
        if root then
            invisPosition = root.Position
        end
        voice("halt.")
        return
    end
    if cmd == "follow" then
        local requestedName =
            firstArg(rest)
        local p
        if requestedName ~= "" then
            p =
                findPlayer(
                    requestedName
                )
            if not p then
                voice(
                    "player not found: "
                    .. requestedName
                )
                return
            end
        else
            p = speaker or getMaster()
            if not p then
                voice("follow target not found.")
                return
            end
        end
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        targetPlayer = p
        followCamPlayer = p
        followPosition = "center"
        mode = "follow"
        groundLock = false
        setFly(true)
        lockCam(p)
        voice(
            "following "
            .. p.Name
        )
        return
    end
    if cmd == "left" or cmd == "right"
        or cmd == "center" or cmd == "centre" or cmd == "middle"
        or cmd == "front" or cmd == "behind"
    then
        local p = activeTarget() or speaker or getMaster()
        if not p then
            voice("follow target not found.")
            return
        end
        if cmd == "centre" or cmd == "middle" then
            followPosition = "center"
        else
            followPosition = cmd
        end
        targetPlayer = p
        followCamPlayer = p
        mode = "follow"
        JARVIS_IDLE_HOLD_CFRAME = nil
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        groundLock = not invisFollow
        setFly(true)
        lockCam(p)
        voice("following " .. p.Name .. " " .. followPosition .. ".")
        return
    end
    if cmd == "unfollow"
        or cmd == "unline"
        or cmd == "unloopfollow"
    then
        stopMove()
        voice("halted.")
        return
    end
    if cmd == "loopfollow" then
        local requestedName =
            firstArg(rest)
        local p
        if requestedName ~= "" then
            p =
                findPlayer(
                    requestedName
                )
            if not p then
                voice(
                    "player not found: "
                    .. requestedName
                )
                return
            end
        else
            p = speaker or getMaster()
            if not p then
                voice("follow target not found.")
                return
            end
        end
        protecting = false
        orbiting = false
        dancing = false
        targetPlayer = p
        followCamPlayer = p
        followPosition = "center"
        mode = "loopfollow"
        JARVIS_IDLE_HOLD_CFRAME = nil
        groundLock = false
        setFly(true)
        lockCam(p)
        voice(
            "continuous follow "
            .. p.Name
        )
        return
    end
    if cmd == "line" then
        protecting = false
        orbiting = false
        dancing = false
        guardMode = false
        mode = "line"
        if not invisFollow then
            groundLock = true
        end
        targetPlayer = getMaster()
        setFly(true)
        lockCam(getMaster())
        voice(
            "formation line. "
            .. getJarvisName()
        )
        return
    end
    if cmd == "stop"
        or cmd == "idle"
    then
        stopMove()
        if invisFollow then
            local root = myRoot()
            if root then
                invisPosition =
                    root.Position
            end
        end
        setFly(false)
        restoreOwnCam()
        voice("idle.")
        return
    end
    if cmd == "fly" then
        setFly(true)
        return
    end
    if cmd == "unfly" then
        setFly(false)
        return
    end
    if cmd == "noclip" then
        setNoclipAdmin(true)
        voice("continuous noclip enabled.")
        return
    end
    if cmd == "clip" then
        setNoclipAdmin(false)
        voice("noclip disabled.")
        return
    end
    if cmd == "cam"
        or cmd == "view"
    then
        lockCam(
            findPlayer(
                firstArg(rest)
            )
            or speaker
            or activeTarget()
        )
        return
    end
    if cmd == "uncam"
        or cmd == "unview"
    then
        restoreOwnCam()
        return
    end
    if cmd == "reset"
        or cmd == "re"
    then
        setFly(false)
        local h = myHum()
        if h then
            h.Health = 0
        end
        return
    end
    if cmd == "rejoin"
        or cmd == "rj"
    then
        savePersistentState(true)
        pcall(function()
            TeleportService:
                TeleportToPlaceInstance(
                    game.PlaceId,
                    game.JobId,
                    bot
                )
        end)
        return
    end
    if cmd == "spin" then
        spinning = true
        camera.CameraType = Enum.CameraType.Custom
        local hum = myHum()
        if hum then
            camera.CameraSubject = hum
        end
        voice("spin on.")
        return
    end
    if cmd == "unspin" then
        spinning = false
        voice("spin off.")
        return
    end
    if cmd == "status"
        or cmd == "report"
    then
        local target =
            activeTarget()
        local zone =
            isInsidePrison()
        voice(
            string.format(
                "%s | mode=%s | slot=%d | target=%s | speed=%d | zone=%s | protect=%s | hide=%s | freeze=%s | fd=%.1f | cloak=%.1f",
                getJarvisName(),
                mode,
                mySlot,
                target
                    and target.Name
                    or "none",
                math.floor(flySpeed),
                zone
                    and "PRISON"
                    or "OUTSIDE",
                tostring(protecting),
                tostring(hiddenLock),
                tostring(frozen),
                followDistance,
                cloakDepth
            )
        )
        return
    end
    if cmd == "radio" then
        local text = rest
        if text == "" then
            voice(
                "radio online. "
                .. getJarvisName()
            )
        else
            voice(
                "["
                .. getJarvisName()
                .. "] "
                .. text
            )
        end
        return
    end
    if cmd == "personality"
        or cmd == "mood"
    then
        local mood =
            firstArg(rest):lower()
        if mood == ""
            or mood == "normal"
        then
            voice(
                "Personality: professional."
            )
        elseif mood == "funny" then
            voice(
                "Personality: mildly chaotic."
            )
        elseif mood == "serious" then
            voice(
                "Personality: tactical."
            )
        elseif mood == "goofy" then
            voice(
                "Personality: questionable."
            )
        else
            voice(
                "moods: normal, funny, serious, goofy."
            )
        end
        return
    end
    if cmd == "captain" then
        if mySlot == 1 then
            voice(
                "Captain JARVIS online."
            )
        else
            voice(
                "Captain is JARVIS-01."
            )
        end
        return
    end
    if cmd == "cmds"
        or cmd == "help"
        or cmd == "commands"
        or cmd == "cmdlist"
    then
        announceCmds(speaker)
        return
    end
    if handleJarvisKillCommand(cmd, rest) then
        return
    elseif cmd == "whitelist" or cmd == "wl" then
        local clean = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
        if clean == "" then
            local names = getWhitelistNames()
            if #names == 0 then
                voice("whitelist is empty.")
            else
                voice("whitelist: " .. table.concat(names, ", "))
            end
            return
        end
        local player = findPlayer(clean)
        if not player then
            voice("whitelist player not found.")
            return
        end
        setWhitelisted(player, true)
        voice(player.Name .. " whitelisted.")
        return
    end
    if cmd == "unwhitelist" or cmd == "unwl" then
        local clean = tostring(rest or ""):gsub("^%s+", ""):gsub("%s+$", "")
        local player = findPlayer(clean)
        if not player then
            local key = clean:lower()
            if key ~= "" and JARVIS_WHITELIST[key] then
                JARVIS_WHITELIST[key] = nil
                voice(clean .. " removed from whitelist.")
            else
                voice("whitelist player not found.")
            end
            return
        end
        setWhitelisted(player, false)
        voice(player.Name .. " removed from whitelist.")
        return
    end
    if cmd == "cmd" then
        if JARVIS_KX_ADMIN_ENABLED == false then
            voice("kx off. admin commands disabled.")
            return
        end
        local forwardedCmd, forwardedRest = tostring(rest or ""):match("^(%S+)%s*(.*)$")
        forwardedCmd = (forwardedCmd or ""):gsub("^[%.;]", ""):lower()
        forwardedRest = forwardedRest or ""
        if whitelistAwareTeamKill(forwardedCmd, forwardedRest) then
            return
        end
        otherCmd(rest)
        return
    end
    if cmd == "ipa"
        or cmd == "invispunchaura"
    then
        local p = findPlayer(rest)
        if not p then
            voice("player not found.")
            return
        end
        if isJarvisOwnerPlayer
            and isJarvisOwnerPlayer(p)
        then
            voice("owner target blocked.")
            return
        end
        JARVIS_PUNCHAURA_ACTIVE = false
        JARVIS_PUNCHAURA_TARGET = nil
        JARVIS_IPA_TARGET = p
        JARVIS_IPA_ACTIVE = true
        frozen = false
        freezeCFrame = nil
        hiddenLock = false
        orbiting = false
        dancing = false
        protecting = false
        guardMode = false
        invisFollow = false
        invisPosition = nil
        groundLock = false
        mode = "idle"
        releaseTrueIdleAnchor()
        setFly(true)
        lockCam(p)
        voice("predictive aura on " .. p.Name)
        return
    end
    if cmd == "unipa" then
        stopJarvisIPA()
        voice("predictive aura off.")
        return
    end
    if cmd == "sb"
        or cmd == "shootback"
    then
        local setting = tostring(rest or ""):lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        if setting == "off"
            or setting == "false"
            or setting == "0"
        then
            JARVIS_SHOOTBACK_ENABLED = false
            voice("Eagle shootback off.")
        elseif setting == "on"
            or setting == "true"
            or setting == "1"
            or setting == ""
        then
            JARVIS_SHOOTBACK_ENABLED = true
            voice("Eagle shootback on.")
        end
        return
    end
    if cmd == "ap"
        or cmd == "antipunch"
    then
        local setting = tostring(rest or ""):lower()
            :gsub("^%s+", "")
            :gsub("%s+$", "")
        if setting == "off"
            or setting == "false"
            or setting == "0"
        then
            JARVIS_ANTIPUNCH_ENABLED = false
            clearJarvisAntiPunch()
            voice("Eagle anti punch off.")
        elseif setting == "on"
            or setting == "true"
            or setting == "1"
            or setting == ""
        then
            JARVIS_ANTIPUNCH_ENABLED = true
            voice("Eagle anti punch on.")
        end
        return
    end
    if cmd == "untarget" then
        local old =
            JARVIS_PRIORITY_TARGET
            and JARVIS_PRIORITY_TARGET.Name
            or "target"
        clearJarvisPriorityTarget()
        pcall(function()
            otherCmd("unloopkill all")
        end)
        voice("priority target cleared " .. old)
        return
    end
    if cmd == "carfling" or cmd == "cf" then
        task.spawn(function()
            runRemoteCarFling(rest)
        end)
        return
    end
    if cmd == "fling" then
        task.spawn(function()
            runRemoteCarFling(rest)
        end)
        return
    end
    if cmd == "revenge" then
        local target = rest
        if target == "" then
            voice("revenge requires a player name.")
            return
        end
        local p = findPlayer(target)
        if not p then
            voice("player not found.")
            return
        end
        otherCmd("kill " .. p.Name)
        voice("revenge on " .. p.Name)
        return
    end
    if handleJarvisKillCommand(cmd, rest) then
        return
    end
    if whitelistAwareTeamKill(cmd, rest) then
        return
    end
    if ADMIN[cmd]
        and not LOCAL[cmd]
    then
        otherCmd(body)
        voice(cmd)
        return
    end
    if not LOCAL[cmd] then
        otherCmd(body)
        return
    end
end
attachJarvisSelfDamageWatcher()
bot.CharacterAdded:Connect(function()
    if JARVIS_PRIORITY_TARGET_ACTIVE then
        JARVIS_PRIORITY_TARGET_RESPAWN_GRACE_UNTIL =
            os.clock() + 2.2
        task.delay(1.25, function()
            if JARVIS_PRIORITY_TARGET_ACTIVE
                and shouldAutoCombo2ForTeam()
            then
                otherCmd("combo2")
            end
        end)
    end
end)
RunService.Heartbeat:Connect(
    function(dt)
        if not invisFollow then
            removeCloakYHold()
        end
        if IS_LEADER then
            return
        end
        local root = myRoot()
        local hum = myHum()
        if not root or not hum then
            return
        end
        if vehicleRoutineActive then
            releaseTrueIdleAnchor()
            JARVIS_IDLE_HOLD_CFRAME = nil
            if root.Anchored then
                root.Anchored = false
            end
            return
        end
        jarvisAntiPunchStep()
        local trulyIdle =
            mode == "idle"
            and not hiddenLock
            and not vehicleRoutineActive
            and not invisFollow
            and not protecting
            and not orbiting
            and not dancing
            and not guardMode
            and not JARVIS_PUNCHAURA_ACTIVE
            and not JARVIS_IPA_ACTIVE
            and not JARVIS_PRIORITY_TARGET_ACTIVE
            and not frozen
        if trulyIdle then
            if os.clock() < (JARVIS_FOLLOW_RELEASE_UNTIL or 0) then
                releaseTrueIdleAnchor()
                JARVIS_IDLE_HOLD_CFRAME = root.CFrame
            else
                if not JARVIS_IDLE_HOLD_CFRAME then
                    JARVIS_IDLE_HOLD_CFRAME = root.CFrame
                end
                setTrueIdleAnchor()
                root.CFrame = JARVIS_IDLE_HOLD_CFRAME
            end
        else
            releaseTrueIdleAnchor()
            JARVIS_IDLE_HOLD_CFRAME = nil
        end
        if hiddenLock then
            mode = "idle"
            orbiting = false
            dancing = false
            protecting = false
            guardMode = false
            invisFollow = false
            targetPlayer = nil
            followCamPlayer = nil
            groundLock = false
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = HIDE_CFRAME
        end
        updateAutomaticSpeed()
        if noSit and not vehicleRoutineActive then
            hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
            if hum.Sit or hum:GetState() == Enum.HumanoidStateType.Seated then
                hum.Sit = false
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end
        updateStuckRecovery(
            root,
            dt
        )
        if spinning and not frozen and not hiddenLock then
            root.CFrame =
                root.CFrame
                * CFrame.Angles(
                    0,
                    math.rad(180)
                        * dt,
                    0
                )
        end
        local cameraTarget =
            camRoot()
        local myHead =
            headOf(bot)
        if (
            not spinning
            and (
                camLocked
                or mode ~= "idle"
                or protecting
                or orbiting
            )
        )
        and cameraTarget
        and myHead
        then
            camera.CameraType =
                Enum.CameraType.Scriptable
            local look =
                myHead.Position
                + cameraTarget.CFrame.LookVector
                    * 12
            camera.CFrame =
                CFrame.lookAt(
                    myHead.Position,
                    look
                )
        end
        local hum = myHum()
        if hum then
            updateJarvisSafePosition(root, hum)
        end
        if recoverJarvisFromFall(root) then
            return
        end
        if jarvisPriorityTargetStep(root, dt) then
            return
        end
        if jarvisIPAStep(root, dt) then
            return
        end
        if JARVIS_PUNCHAURA_ACTIVE then
            if punchauraStep(root, dt) then
                return
            end
        end
        if protecting then
            protectOrbitStep(root, dt)
            return
        end
        if frozen then
            if freezeCFrame and not hiddenLock then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                root.CFrame = freezeCFrame
            end
            return
        end
        if mode == "follow"
            or mode == "loopfollow"
        then
            if not flying then
                setFly(true)
            end
            local goal =
                followGoal()
            if goal then
                if invisFollow then
                    softCloakStep(root, goal, dt)
                else
                    flyStep(
                        root,
                        goal,
                        dt,
                        true
                    )
                end
            end
            return
        end
        if mode == "line" then
            if not flying then
                setFly(true)
            end
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local goal =
                    getFormationPosition(
                        masterRoot
                    )
                if goal then
                    if invisFollow then
                        local latchedY = getLatchedInvisibleTargetY(getMaster())
                        goal = Vector3.new(
                            goal.X,
                            (latchedY or masterRoot.Position.Y) - cloakDepth,
                            goal.Z
                        )
                    else
                        goal = flatten(goal)
                    end
                    flyStep(
                        root,
                        goal,
                        dt,
                        invisFollow
                    )
                end
            end
            return
        end
        if mode == "orbit"
            or mode == "dance"
        then
            if not flying then
                setFly(true)
            end
            danceTime =
                danceTime + dt
            local goal =
                orbitGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    true
                )
            end
            return
        end
        if mode == "guard" then
            if not flying then
                setFly(true)
            end
            local goal =
                guardGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    true
                )
            end
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local outward =
                    root.Position
                    - masterRoot.Position
                if outward.Magnitude > 0.1 then
                    root.CFrame =
                        CFrame.lookAt(
                            root.Position,
                            root.Position
                                + outward.Unit
                        )
                end
            end
            return
        end
        if mode == "patrol" then
            if not flying then
                setFly(true)
            end
            local goal =
                patrolGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    false
                )
            end
            return
        end
        if mode == "scout" then
            if not flying then
                setFly(true)
            end
            local masterRoot =
                rootOf(getMaster())
            if masterRoot then
                local distance =
                    (
                        root.Position
                        - masterRoot.Position
                    ).Magnitude
                if not scoutReturning
                    and distance
                        >= SCOUT_DISTANCE
                then
                    scoutReturning = true
                end
            end
            local goal =
                scoutGoal()
            if goal then
                flyStep(
                    root,
                    goal,
                    dt,
                    false
                )
            end
            return
        end
        if mode == "idle"
            and invisFollow
            and invisPosition
        then
            if not flying then
                setFly(true)
            end
            softCloakStep(
                root,
                invisPosition,
                dt
            )
            return
        end
        if flying and not hiddenLock then
            hum.PlatformStand = true
            root.AssemblyLinearVelocity =
                Vector3.zero
            if groundLock and mode ~= "idle" then
                local pos =
                    flatten(
                        root.Position
                    )
                if (
                    root.Position
                    - pos
                ).Magnitude > 0.15 then
                    root.CFrame =
                        CFrame.new(pos)
                        * (
                            root.CFrame
                            - root.CFrame.Position
                        )
                end
            end
        end
        if hiddenLock then
            root.AssemblyLinearVelocity = Vector3.zero
            root.AssemblyAngularVelocity = Vector3.zero
            root.CFrame = HIDE_CFRAME
        end
    end
)

;(function()
    local env = getgenv()

    env.JARVIS_SHARED_OWNER_PROTECTION = function(senderName, commandBody)
        local senderKey = tostring(senderName or ""):lower()
        if senderKey == masterLower or extraOwners[senderKey] ~= true then
            return false
        end

        local body = tostring(commandBody or "")
        local cmd, rest = body:match("^%s*(%S+)%s*(.-)%s*$")
        cmd = tostring(cmd or ""):lower()
        rest = tostring(rest or "")

        -- Commands that can directly harm/force the owner are never allowed
        -- from a shared account when the owner is the requested target.
        local harmful = {
            kill=true, k=true, loopkill=true, lk=true,
            fling=true, carfling=true, bring=true,
            hitbox=true, ragebot=true, silentaim=true,
            toolaura=true, combo1=true, combo2=true, combo3=true,
            m4a1=true, reming=true, ak=true, riot=true, mafia=true,
        }

        if not harmful[cmd] then
            return false
        end

        local target = rest:match("^%s*(%S+)")
        if not target or target == "" then
            return false
        end

        local owner = Players:FindFirstChild(MASTER_NAME)
        local targetPlayer = findPlayer(target)
        local targetsOwner =
            (owner and targetPlayer == owner)
            or target:lower() == tostring(MASTER_NAME):lower()
            or target:lower() == "owner"
            or target:lower() == "master"

        if not targetsOwner then
            return false
        end

        extraOwners[senderKey] = nil
        sharedAccessLevel[senderKey] = nil
        revokedOwners[senderKey] = true
        savePersistentState(true)
        refreshSlot()
        voice("access revoked: " .. tostring(senderName) .. " attempted to harm the owner.")
        return true
    end
end)()


;(function()
    local env = getgenv()
    env.JARVIS_ACTION_STATE = env.JARVIS_ACTION_STATE or {
        spin = false,
        spinSpeed = 8,
        bounce = false,
        bounceHeight = 2.5,
        bounceSpeed = 4,
        headSitTarget = nil,
        danceTrack = nil,
    }

    local state = env.JARVIS_ACTION_STATE

    local function stopDanceTrack()
        if state.danceTrack then
            pcall(function() state.danceTrack:Stop(0.15) end)
            state.danceTrack = nil
        end
    end

    env.JARVIS_ACTION_COMMAND = function(cmd, rest)
        cmd = tostring(cmd or ""):lower()
        rest = tostring(rest or "")

        if cmd == "spin" then
            state.spin = true
            local n = tonumber(rest:match("[-+]?%d+%.?%d*"))
            if n then state.spinSpeed = math.clamp(n, 0.5, 30) end
            voice("spin enabled.")
            return true
        elseif cmd == "unspin" then
            state.spin = false
            voice("spin disabled.")
            return true
        elseif cmd == "bounce" then
            state.bounce = true
            voice("bounce enabled.")
            return true
        elseif cmd == "unbounce" then
            state.bounce = false
            voice("bounce disabled.")
            return true
        elseif cmd == "headsit" then
            local name = rest:match("^%s*(%S+)")
            local p = name and findPlayer(name)
            if not p or p == bot then
                voice("headsit target not found.")
                return true
            end
            state.headSitTarget = p
            voice("headsit tracking " .. p.Name .. ".")
            return true
        elseif cmd == "unheadsit" then
            state.headSitTarget = nil
            voice("headsit disabled.")
            return true
        elseif cmd == "dance" then
            stopDanceTrack()
            local char = bot.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local animator = hum and (hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum))
            if animator then
                local choice = tonumber(rest:match("%d+")) or 1
                local ids = {
                    [1] = "rbxassetid://507771019",
                    [2] = "rbxassetid://507776043",
                    [3] = "rbxassetid://507777268",
                }
                local anim = Instance.new("Animation")
                anim.AnimationId = ids[math.clamp(choice,1,3)]
                local ok, track = pcall(function() return animator:LoadAnimation(anim) end)
                anim:Destroy()
                if ok and track then
                    track.Looped = true
                    track.Priority = Enum.AnimationPriority.Action
                    track:Play(0.15)
                    state.danceTrack = track
                    voice("dance " .. tostring(choice) .. " enabled.")
                end
            end
            return true
        end
        return false
    end

    RunService.Heartbeat:Connect(function()
        local char = bot.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then return end

        -- Apply spin AFTER movement/follow logic each frame so follow, orbit,
        -- idle, etc. do not overwrite the rotation.
        if state.spin then
            root.CFrame = root.CFrame * CFrame.Angles(0, state.spinSpeed * (1/60), 0)
        end

        -- Bounce is an additive vertical motion and does not replace follow.
        if state.bounce and not state.headSitTarget then
            local y = math.sin(os.clock() * state.bounceSpeed) * state.bounceHeight
            root.CFrame = root.CFrame + Vector3.new(0, math.max(0,y) * 0.08, 0)
        end

        -- Headsit: position above the target's head while preserving a normal
        -- upright orientation. This is a local movement utility, not a fling.
        local target = state.headSitTarget
        if target then
            local tc = target.Character
            local head = tc and tc:FindFirstChild("Head")
            if head then
                local goal = head.CFrame * CFrame.new(0, 1.65, 0)
                root.CFrame = CFrame.new(goal.Position) * CFrame.Angles(0, select(2, root.CFrame:ToEulerAnglesYXZ()), 0)
                root.AssemblyLinearVelocity = Vector3.zero
            else
                state.headSitTarget = nil
            end
        end
    end)
end)()

function onChat(sender, message)
    if IS_LEADER or not sender or not message then return end
    if sender:lower() == bot.Name:lower() then return end

    local text = tostring(message)
    local lower = text:lower()
    local senderLower = sender:lower()
    local isHost = senderLower == masterLower
    local isShared = extraOwners[senderLower] == true
        and revokedOwners[senderLower] ~= true
    local hasAccess = isHost or isShared

    -- Permanent owner AND users granted with 'share use the same apostrophe
    -- prefix. Previously this branch checked only isHost, so shared users
    -- could never reach handle().
    if lower:sub(1, #CMD_PREFIX) == CMD_PREFIX then
        if not hasAccess then
            voice("access denied.")
            return
        end

        local body = text:sub(#CMD_PREFIX + 1)
        if isShared and not isHost
            and getgenv().JARVIS_SHARED_OWNER_PROTECTION
            and getgenv().JARVIS_SHARED_OWNER_PROTECTION(sender, body)
        then
            return
        end
        if isShared and not isHost then
            local sharedCmd = tostring(body):match("^%s*(%S+)")
            sharedCmd = sharedCmd and sharedCmd:lower() or ""
            local level = sharedAccessLevel[senderLower] or 2

            if level == 1 then
                -- Share1 has the full normal command surface.
                -- Owner protection/revocation is enforced separately below.
            elseif not JARVIS_SHARE2_ALLOWED_COMMANDS[sharedCmd] then
                voice("access denied: share2 has basic access only.")
                return
            end
        end

        handle(body, sender)
        return
    end

    -- Keep the secondary prefix path consistent with the same access table.
    if lower:sub(1, #PREFIX) == PREFIX then
        if not hasAccess then
            voice("access denied.")
            return
        end

        local body = text:sub(#PREFIX + 1)
        if isShared and not isHost
            and getgenv().JARVIS_SHARED_OWNER_PROTECTION
            and getgenv().JARVIS_SHARED_OWNER_PROTECTION(sender, body)
        then
            return
        end
        if isShared and not isHost then
            local sharedCmd = tostring(body):match("^%s*(%S+)")
            sharedCmd = sharedCmd and sharedCmd:lower() or ""
            local level = sharedAccessLevel[senderLower] or 2

            if level == 1 then
                -- Share1 has the full normal command surface.
                -- Owner protection/revocation is enforced separately below.
            elseif not JARVIS_SHARE2_ALLOWED_COMMANDS[sharedCmd] then
                voice("access denied: share2 has basic access only.")
                return
            end
        end

        handle(body, sender)
    end
end
pcall(function()
    TextChatService.MessageReceived:Connect(
        function(msg)
            local src =
                msg.TextSource
            if not src then
                return
            end
            if src.UserId
                == bot.UserId
            then
                return
            end
            local plr =
                Players:GetPlayerByUserId(
                    src.UserId
                )
            if plr then
                usingTextChat = true
                onChat(
                    plr.Name,
                    msg.Text
                )
            end
        end
    )
end)
function hook(plr)
    if plr == bot then
        return
    end
    plr.Chatted:Connect(
        function(message)
            if usingTextChat then
                return
            end
            onChat(
                plr.Name,
                message
            )
        end
    )
end
Players.PlayerAdded:Connect(
    function(p)
        hook(p)
        if protecting and protectedPlayer == p then
            watchProtectedPlayer(p)
        end
        task.defer(function()
            refreshSlot()
        end)
    end
)
-- Keep the startup player iteration inside a callback function.
-- This avoids allocating another top-level Luau local register for `p`.
table.foreach(
    Players:GetPlayers(),
    function(_, player)
        hook(player)
        if protecting and protectedPlayer == player then
            watchProtectedPlayer(player)
        end
    end
)
Players.PlayerRemoving:Connect(
    function(p)
        task.defer(function()
            if p.Name:lower()
                ~= bot.Name:lower()
            then
                refreshSlot()
            end
        end)
    end
)
bot.Idled:Connect(
    function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(
                Vector2.new()
            )
        end)
    end
)
if not IS_LEADER then
    pcall(function()
        local ev =
            ReplicatedStorage:FindFirstChild(
                "EagleHello"
            )
        if ev then
            ev:FireServer()
        end
    end)
end
task.spawn(function()
    local messages = {
        "systems nominal.",
        "JARVIS standing by.",
        "squad link stable.",
        "all systems operational.",
        "awaiting commander.",
    }
    while task.wait(
        math.random(45, 90)
    ) do
        if not IS_LEADER
            and not shut
            and canTalk()
            and mode == "idle"
        then
            voice(
                messages[
                    math.random(
                        1,
                        #messages
                    )
                ]
            )
        end
    end
end)
task.defer(function()
    local pg =
        bot:WaitForChild(
            "PlayerGui"
        )
    local old =
        pg:FindFirstChild(
            "JarvisPanel"
        )
    if old then
        old:Destroy()
    end
    local gui =
        Instance.new("ScreenGui")
    gui.Name = "JarvisPanel"
    gui.ResetOnSpawn = false
    gui.Enabled = false
    gui.Parent = pg
    local frame =
        Instance.new("Frame")
    frame.Size =
        UDim2.fromOffset(
            350,
            410
        )
    frame.Position =
        UDim2.fromOffset(
            16,
            80
        )
    frame.BackgroundColor3 =
        Color3.fromRGB(
            16,
            16,
            20
        )
    frame.Parent = gui
    local corner =
        Instance.new("UICorner")
    corner.CornerRadius =
        UDim.new(
            0,
            10
        )
    corner.Parent = frame
    local title =
        Instance.new("TextLabel")
    title.Size =
        UDim2.new(
            1,
            -20,
            0,
            38
        )
    title.Position =
        UDim2.fromOffset(
            10,
            8
        )
    title.BackgroundTransparency = 1
    title.Font =
        Enum.Font.Code
    title.TextSize = 20
    title.TextXAlignment =
        Enum.TextXAlignment.Left
    title.TextColor3 =
        Color3.fromRGB(
            230,
            230,
            240
        )
    title.Text =
        "J.A.R.V.I.S."
    title.Parent = frame
    local lab =
        Instance.new("TextLabel")
    lab.Size =
        UDim2.new(
            1,
            -20,
            1,
            -55
        )
    lab.Position =
        UDim2.fromOffset(
            10,
            48
        )
    lab.BackgroundTransparency = 1
    lab.Font =
        Enum.Font.Code
    lab.TextSize = 14
    lab.TextColor3 =
        Color3.fromRGB(
            220,
            220,
            220
        )
    lab.TextXAlignment =
        Enum.TextXAlignment.Left
    lab.TextYAlignment =
        Enum.TextYAlignment.Top
    lab.TextWrapped = true
    lab.Parent = frame
    local function updatePanel()
        local eagleCount =
            #getEagleUnits()
        local target =
            activeTarget()
        local zone =
            isInsidePrison()
        local captain =
            mySlot == 1
        lab.Text =
            string.format(
                "UNIT       %s\n"
                .. "SLOT       %s / %s\n"
                .. "CAPTAIN    %s\n"
                .. "MODE       %s\n"
                .. "TARGET     %s\n\n"
                .. "SQUAD      %s JARVIS units\n"
                .. "FORMATION  %s\n"
                .. "SPEED      %d\n"
                .. "ZONE       %s\n\n"
                .. "PROTECT    %s\n"
                .. "INVIS      %s\n"
                .. "FLY        %s\n"
                .. "NOCLIP     %s\n"
                .. "PUNCH      %s\n"
                .. "NO-SIT     %s\n"
                .. "HIDDEN     %s\n"
                .. "FROZEN     %s\n"
                .. "FOLLOW D   %.1f\n"
                .. "CLOAK D    %.1f\n\n"
                .. "COMMANDS   %d\n"
                .. "LAST       %s\n\n"
                .. "` close",
                getJarvisName(),
                tostring(mySlot),
                tostring(
                    math.max(
                        eagleCount,
                        1
                    )
                ),
                tostring(captain),
                mode,
                target
                    and target.Name
                    or "none",
                tostring(eagleCount),
                formationType,
                math.floor(flySpeed),
                zone
                    and "PRISON"
                    or "OUTSIDE",
                tostring(protecting),
                tostring(invisFollow),
                tostring(flying),
                tostring(noclipOn),
                tostring(punchOn),
                tostring(noSit),
                tostring(hiddenLock),
                tostring(frozen),
                followDistance,
                cloakDepth,
                sessionCommandCount,
                lastCommand
            )
    end
    UserInputService.InputBegan:Connect(
        function(inp, gp)
            if gp then
                return
            end
            if inp.KeyCode
                == Enum.KeyCode.F8
            then
                gui.Enabled =
                    not gui.Enabled
                if gui.Enabled then
                    updatePanel()
                end
            end
        end
    )
    task.spawn(function()
        while gui.Parent do
            if gui.Enabled then
                updatePanel()
            end
            task.wait(0.25)
        end
    end)
end)
function tryAutoRejoin(reason)
    if rejoinAttempted then return end
    rejoinAttempted = true
    savePersistentState(true)
    warn("[JARVIS] reconnect detected:", reason or "unknown")
    task.defer(function()
        pcall(function()
            TeleportService:Teleport(game.PlaceId, bot)
        end)
    end)
end
pcall(function()
    GuiService.ErrorMessageChanged:Connect(function(message)
        message = tostring(message or "")
        if message ~= "" then
            tryAutoRejoin(message)
        end
    end)
end)
pcall(function()
    TeleportService.TeleportInitFailed:Connect(function(player)
        if player == bot then
            rejoinAttempted = false
            task.delay(0.5, function()
                tryAutoRejoin("teleport retry")
            end)
        end
    end)
end)
startPersistentSaver()
task.spawn(function()
    task.wait(1)
    refreshSlot()
    applyNoSitState()
    if IS_LEADER then
        print(
            "[JARVIS] Master detected. "
            .. "No autonomous movement."
        )
        return
    end
    if not didJoinFly then
        didJoinFly = true
        setFly(true)
        voice(
            "JARVIS online. "
            .. getJarvisName()
            .. " ready."
        )
    end
end)
refreshSlot()
JARVIS_AUTO_PROTECT_SERIAL = JARVIS_AUTO_PROTECT_SERIAL or 0
function autoProtectMaster()
    if IS_LEADER then
        return false
    end
    local master = getMaster()
    if not master or not master.Parent then
        return false
    end
    protecting = true
    protectedPlayer = master
    targetPlayer = master
    attachProtectDamageWatcher(master)
    followCamPlayer = master
    mode = "idle"
    orbiting = false
    groundLock = false
    JARVIS_PROTECT_ORBIT_ANGLE = 0
    table.clear(JARVIS_PROTECT_LAST_ACTION)
    refreshSlot()
    setFly(true)
    disconnectProtection()
    lockCam(master)
    print(
        "[JARVIS] Auto-protect 10-stud orbit guard:",
        master.Name
    )
    return true
end
function scheduleAutoProtect(delaySeconds)
    if IS_LEADER then
        return
    end
    JARVIS_AUTO_PROTECT_SERIAL += 1
    local serial = JARVIS_AUTO_PROTECT_SERIAL
    task.spawn(function()
        task.wait(tonumber(delaySeconds) or 0)
        for _ = 1, 30 do
            if serial ~= JARVIS_AUTO_PROTECT_SERIAL then
                return
            end
            if autoProtectMaster() then
                voice("Protecting you, Sir. Auto-protect engaged.")
                return
            end
            task.wait(0.5)
        end
        warn("[JARVIS] Master not found; auto-protect will arm on PlayerAdded.")
    end)
end
scheduleAutoProtect(1.5)
Players.PlayerAdded:Connect(function(p)
    if p == bot then
        return
    end
    if p.Name:lower() == masterLower then
        scheduleAutoProtect(0.5)
    end
end)
Players.PlayerRemoving:Connect(function(p)
    if p.Name:lower() ~= masterLower then
        return
    end
    if protectedPlayer == p then
        protecting = false
        protectedPlayer = nil
        targetPlayer = nil
        followCamPlayer = nil
        disconnectProtection()
    end
end)
if not IS_LEADER then
    task.spawn(function()
        while task.wait(8) do
            if ROLE == "bot" and HOST_NAME ~= "" then
                local hostId = getHostUserId()
                if hostId then
                    local ok, _, _, placeId, jobId = pcall(function()
                        return TeleportService:GetPlayerPlaceInstanceAsync(hostId)
                    end)
                    if ok and placeId == game.PlaceId and type(jobId) == "string"
                        and jobId ~= "" and jobId ~= game.JobId
                    then
                        -- Host-server discovery is available, but only the explicit
                        -- "call" command should trigger the teleport.
                    end
                end
            end
        end
    end)
end

print(
    "[JARVIS] ready | unit="
    .. getJarvisName()
    .. " | slot="
    .. tostring(mySlot)
    .. " | formation="
    .. formationType
)
print(
    "[JARVIS] speed system: "
    .. tostring(PRISON_SPEED)
    .. " inside current Prison Life bounds / "
    .. tostring(OUTSIDE_SPEED)
    .. " outside"
)
task.defer(applyNoSitState)
bot.CharacterAdded:Connect(function()
    stopJarvisIPA()
    clearJarvisAntiPunch()
    JARVIS_LAST_SAFE_CFRAME = nil
    JARVIS_LAST_SAFE_UPDATE = 0
    JARVIS_PROTECT_RESPAWN_GRACE_UNTIL =
        os.clock() + JARVIS_PROTECT_RESPAWN_GRACE
    runRespawnCombo2()
end)
if bot.Character and bot.Character.Parent then
    runRespawnCombo2()
end
task.defer(function()
    protecting = false
    protectedPlayer = nil
    if disconnectProtectDamageWatcher then
        disconnectProtectDamageWatcher()
    end
    if JARVIS_PROTECT_LAST_ACTION then
        table.clear(JARVIS_PROTECT_LAST_ACTION)
    end
    if disconnectProtection then
        disconnectProtection()
    end
    print("[JARVIS] startup protection state: OFF")
end)

getgenv().JARVIS_VOLT_COMMAND_DISPATCH = function(commandText)
    handleJarvisKillCommand(getMaster(), commandText)
end

