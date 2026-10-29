
-- dilangauto.lua
-- Rayfield Gen2

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")

local LocalPlayer = Players.LocalPlayer
local CONFIG_FILE = "dilangauto_config.json"
local TOAST_ICON = 125823673784681

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "dilangauto",
    subtitle = "Halloween Dashboard",
    sidebarLayout = true,
})

local running = {}
local connections = {}
local unloaded = false
local configReady = false
local reconnectBusy = false
local lastReconnectAttempt = 0

-- CONFIG

local function loadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return { toggles = {} }
    end

    local ok, exists = pcall(isfile, CONFIG_FILE)
    if not ok or not exists then
        return { toggles = {} }
    end

    local readOk, result = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if readOk and type(result) == "table" then
        if type(result.toggles) ~= "table" then
            result.toggles = {}
        end
        return result
    end

    warn("[dilangauto] Config invalid; defaults used")
    return { toggles = {} }
end

local Config = loadConfig()
Config.toggles = type(Config.toggles) == "table" and Config.toggles or {}

local function saveConfig()
    if type(writefile) ~= "function" then
        warn("[dilangauto] writefile unavailable")
        return false
    end

    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)

    if not ok then
        warn("[dilangauto] Config save failed:", err)
        return false
    end

    return true
end

-- NOTIFICATIONS

local function notify(title, subtitle)
    if unloaded then
        return
    end

    local options = {
        title = tostring(title),
        icon = TOAST_ICON,
    }

    if subtitle then
        options.subtitle = tostring(subtitle)
    end

    local ok, err = pcall(function()
        Window:Toast(options)
    end)

    if not ok then
        warn("[dilangauto] Toast failed:", err)
    end
end

local function notifyError(action, err)
    warn("[dilangauto] " .. action .. " failed:", err)
    notify(action .. " failed", tostring(err))
end

-- TABS

local function makeTab(name, iconId)
    local options = { name = name }

    if iconId then
        options.icon = iconId
    end

    local ok, tab = pcall(function()
        return Window:CreateTab(options)
    end)

    if not ok then
        notifyError("Create tab: " .. name, tab)
        return nil
    end

    return tab
end

local Halloween = makeTab("Halloween", 93364949241311)
local Farm = makeTab("Farm", 4483362458)
local Units = makeTab("Units", 6031094678)
local Tower = makeTab("Tower", 6031265976)
local Settings = makeTab("Settings", 7733960981)

-- ANTI-AFK

local function setAntiAfk(enabled)
    if connections.antiAfk then
        connections.antiAfk:Disconnect()
        connections.antiAfk = nil
    end

    if not enabled then
        return
    end

    assert(LocalPlayer, "LocalPlayer unavailable")

    connections.antiAfk = LocalPlayer.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

-- AUTO RECONNECT
-- Retries a failed teleport. Cannot run after client disconnects or closes.

local function attemptReconnect()
    if unloaded or not configReady then
        return
    end

    if not running["Settings_AutoReconnect"] then
        return
    end

    local now = os.clock()

    if reconnectBusy or now - lastReconnectAttempt < 15 then
        return
    end

    reconnectBusy = true
    lastReconnectAttempt = now

    task.spawn(function()
        task.wait(3)

        if not unloaded and running["Settings_AutoReconnect"] then
            local ok, err = pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)

            if not ok then
                warn("[dilangauto] Reconnect attempt failed:", err)
            end
        end

        task.wait(5)
        reconnectBusy = false
    end)
end

connections.teleportFailed = TeleportService.TeleportInitFailed:Connect(
    function(player, teleportResult, errorMessage)
        if player ~= LocalPlayer then
            return
        end

        warn(
            "[dilangauto] Teleport failed:",
            teleportResult,
            errorMessage
        )

        attemptReconnect()
    end
)

-- TOGGLES

local function addToggle(tab, tabName, name, purpose, onChanged)
    if not tab then
        return
    end

    local key = tabName .. "_" .. name:gsub("%W", "")
    local savedValue = Config.toggles[key] == true

    running[key] = savedValue

    local function applyValue(value, showToast)
        if unloaded then
            return
        end

        value = value == true
        running[key] = value
        Config.toggles[key] = value

        if configReady then
            saveConfig()
        end

        if onChanged then
            local ok, err = pcall(onChanged, value)
            if not ok then
                notifyError(name, err)
            end
        end

        if showToast then
            notify(name, value and "Enabled" or "Disabled")
        end
    end

    local ok, toggle = pcall(function()
        return tab:CreateToggle({
            name = name,
            flag = key,
            value = savedValue,

            callback = function(value)
                applyValue(value, true)
            end,
        })
    end)

    if not ok then
        notifyError("Create toggle: " .. name, toggle)
        return
    end

    -- Apply saved state once after controls exist.
    task.defer(function()
        if unloaded then
            return
        end

        applyValue(savedValue, false)
    end)
end

-- BUTTONS

local function addButton(tab, name, callback)
    if not tab then
        return
    end

    local ok, err = pcall(function()
        tab:CreateButton({
            name = name,

            callback = function()
                if unloaded then
                    return
                end

                local runOk, runErr = pcall(callback)

                if not runOk then
                    notifyError(name, runErr)
                end
            end,
        })
    end)

    if not ok then
        notifyError("Create button: " .. name, err)
    end
end

-- HALLOWEEN

addToggle(
    Halloween,
    "Halloween",
    "Auto Trick-or-Treat",
    "UI only; no game action connected."
)

addToggle(
    Halloween,
    "Halloween",
    "Auto Collect Candy",
    "UI only; no game action connected."
)

addToggle(
    Halloween,
    "Halloween",
    "Event Alerts",
    "UI only; no alert system connected."
)

-- FARM

addToggle(Farm, "Farm", "Auto Roll", "UI only.")
addToggle(Farm, "Farm", "Auto Sell", "UI only.")
addToggle(Farm, "Farm", "Auto Collect", "UI only; collection remote not connected.")
addToggle(Farm, "Farm", "Auto Rebirth", "UI only.")
addToggle(Farm, "Farm", "Potion Manager", "UI only.")

-- UNITS

addToggle(Units, "Units", "Equip Best", "UI only.")
addToggle(Units, "Units", "Lock Rare Units", "UI only.")
addToggle(Units, "Units", "Trait Filter", "UI only.")
addToggle(Units, "Units", "Grade Filter", "UI only.")

-- TOWER

addToggle(Tower, "Tower", "Potion Loadout", "UI only.")
addToggle(Tower, "Tower", "Reward Alerts", "UI only.")
addToggle(Tower, "Tower", "Run Summary", "UI only.")

-- SETTINGS

addToggle(Settings, "Settings", "Notifications", "Toast notifications.", function(enabled)
    -- Toast display setting placeholder.
end)

addToggle(Settings, "Settings", "Compact Layout", "UI only.")
addToggle(Settings, "Settings", "Remember UI Position", "UI only.")

addToggle(
    Settings,
    "Settings",
    "Anti-AFK",
    "Anti-AFK connection.",
    setAntiAfk
)

addToggle(
    Settings,
    "Settings",
    "Auto Reconnect",
    "Retries failed teleport requests.",
    function(enabled)
        if enabled then
            attemptReconnect()
        end
    end
)

addButton(Settings, "Reconnect Now", function()
    local ok, err = pcall(function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end)

    if not ok then
        notifyError("Reconnect", err)
    end
end)

-- UNLOAD

local function unload()
    if unloaded then
        return
    end

    saveConfig()
    unloaded = true

    for key in pairs(running) do
        running[key] = false
    end

    for key, connection in pairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)

        connections[key] = nil
    end

    pcall(function()
        Rayfield:Destroy()
    end)
end

addButton(Settings, "Unload dilangauto", unload)

-- FINISH CONFIG RESTORE

-- Prevent saves until all controls have been created.
configReady = true

-- Silent autosave after setup.
saveConfig()

notify("dilangauto loaded", "Config restored")
