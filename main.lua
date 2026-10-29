
-- dilangauto.lua
-- Rayfield Gen2

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local CONFIG_FILE = "dilangauto_config.json"
local TOAST_ICON = 125823673784681

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/gen2"
))()

local Window = Rayfield:CreateWindow({
    name = "dilangauto",
    subtitle = "Automation",
    sidebarLayout = true,
})

local LocalPlayer = Players.LocalPlayer
local running = {}
local connections = {}
local toggleRestorations = {}
local unloaded = false
local configReady = false

-- CONFIG

local function loadConfig()
    if type(isfile) ~= "function"
        or type(readfile) ~= "function" then
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

local function saveConfig()
    if type(writefile) ~= "function" then
        warn("[dilangauto] writefile unavailable")
        return false
    end

    local ok, err = pcall(function()
        writefile(
            CONFIG_FILE,
            HttpService:JSONEncode(Config)
        )
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
        if unloaded or not running["Settings_AntiAFK"] then
            return
        end

        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

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

    -- Restore callbacks after all controls exist.
    table.insert(toggleRestorations, function()
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

addToggle(
    Farm,
    "Farm",
    "Auto Collect",
    "UI only; collection logic not connected."
)

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

addToggle(
    Settings,
    "Settings",
    "Notifications",
    "Toast notifications setting."
)

addToggle(Settings, "Settings", "Compact Layout", "UI only.")
addToggle(Settings, "Settings", "Remember UI Position", "UI only.")

addToggle(
    Settings,
    "Settings",
    "Anti-AFK",
    "Keep Anti-AFK connection active.",
    setAntiAfk
)

-- UNLOAD

local function unload()
    if unloaded then
        return
    end

    -- Stop callbacks before saving final state.
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

    saveConfig()

    pcall(function()
        Rayfield:Destroy()
    end)
end

addButton(Settings, "Unload dilangauto", unload)

-- RESTORE SAVED STATES ONCE

configReady = true

for _, restore in ipairs(toggleRestorations) do
    if unloaded then
        break
    end

    local ok, err = pcall(restore)

    if not ok then
        notifyError("Restore toggle", err)
    end
end

-- Silent save. No "Config saved" toast.
saveConfig()

notify("dilangauto loaded", "Saved settings restored")
