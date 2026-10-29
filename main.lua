
-- dilangauto.lua
-- Rayfield Gen2

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local CONFIG_FILE = "dilangauto_config.json"

local function notify(title, subtitle)
    local message = tostring(title)
    if subtitle then
        message ..= " - " .. tostring(subtitle)
    end

    local ok, err = pcall(function()
        Window:Toast({
            title = tostring(title),
            subtitle = subtitle and tostring(subtitle) or nil,
        })
    end)

    if not ok then
        warn("[dilangauto] Toast failed:", err)
        print("[dilangauto] " .. message)
    end
end

local function loadRayfield()
    local ok, result = pcall(function()
        return loadstring(game:HttpGet(
            "https://sirius.menu/gen2"
        ))()
    end)

    if not ok then
        warn("[dilangauto] Rayfield load failed:", result)
        return nil
    end

    return result
end

local Rayfield = loadRayfield()
if not Rayfield then return end

local windowOk, WindowResult = pcall(function()
    return Rayfield:CreateWindow({
        name = "dilangauto",
        subtitle = "Halloween Dashboard",
        sidebarLayout = true,
    })
end)

if not windowOk then
    warn("[dilangauto] Window creation failed:", WindowResult)
    return
end

Window = WindowResult

local running = {}
local connections = {}
local unloaded = false

-- CONFIG LOAD
local function loadConfig()
    if type(isfile) ~= "function"
        or type(readfile) ~= "function" then
        return { toggles = {} }
    end

    local existsOk, exists = pcall(isfile, CONFIG_FILE)
    if not existsOk or not exists then
        return { toggles = {} }
    end

    local ok, result = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if ok and type(result) == "table" then
        result.toggles = type(result.toggles) == "table"
            and result.toggles or {}
        return result
    end

    warn("[dilangauto] Config invalid; defaults loaded")
    return { toggles = {} }
end

local Config = loadConfig()

-- CONFIG AUTO-SAVE
local function saveConfig()
    if type(writefile) ~= "function" then
        notify("Config not saved", "Delta file API unavailable")
        return false
    end

    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)

    if not ok then
        warn("[dilangauto] Config save failed:", err)
        notify("Save failed", tostring(err))
        return false
    end

    return true
end

-- TOAST HELPER
local function toastState(name, enabled)
    notify(name, enabled and "Enabled" or "Disabled")
end

-- TABS
local function makeTab(name, icon)
    local options = { name = name }
    if icon then options.icon = icon end

    local ok, tab = pcall(function()
        return Window:CreateTab(options)
    end)

    if not ok then
        warn("[dilangauto] Tab creation failed:", name, tab)
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
        return true
    end

    local player = Players.LocalPlayer
    if not player then
        error("LocalPlayer unavailable")
    end

    connections.antiAfk = player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    return true
end

-- TOGGLE BUILDER
local function addToggle(tab, tabName, name, purpose, onChanged)
    if not tab then return end

    local key = tabName .. "_" .. name:gsub("%W", "")
    local savedValue = Config.toggles[key] == true

    local ok, err = pcall(function()
        tab:CreateToggle({
            name = name,
            flag = key,
            value = savedValue,

            callback = function(value)
                if unloaded then return end

                running[key] = value
                Config.toggles[key] = value

                local saveOk = saveConfig()
                toastState(name, value)

                if saveOk then
                    notify("Config saved", name)
                end

                if onChanged then
                    local callbackOk, callbackErr =
                        pcall(onChanged, value)

                    if not callbackOk then
                        warn("[dilangauto] Action failed:", name, callbackErr)
                        notify("Action failed", tostring(callbackErr))
                    end
                else
                    notify("Info", purpose)
                end
            end,
        })
    end)

    if not ok then
        warn("[dilangauto] Toggle creation failed:", name, err)
        notify("Toggle error", name)
    end
end

-- HALLOWEEN
addToggle(Halloween, "Halloween", "Auto Trick-or-Treat",
    "Placeholder: no game action connected.")

addToggle(Halloween, "Halloween", "Auto Collect Candy",
    "Placeholder: no game action connected.")

addToggle(Halloween, "Halloween", "Event Alerts",
    "Placeholder: no alert system connected.")

-- FARM
addToggle(Farm, "Farm", "Auto Roll",
    "Placeholder: no game action connected.")

addToggle(Farm, "Farm", "Auto Sell",
    "Placeholder: no game action connected.")

addToggle(Farm, "Farm", "Auto Collect",
    "Status toggle only: collection action not connected.")

addToggle(Farm, "Farm", "Auto Rebirth",
    "Placeholder: no game action connected.")

addToggle(Farm, "Farm", "Potion Manager",
    "Placeholder: no potion logic connected.")

-- UNITS
addToggle(Units, "Units", "Equip Best",
    "Placeholder: no unit action connected.")

addToggle(Units, "Units", "Lock Rare Units",
    "Placeholder: no unit action connected.")

addToggle(Units, "Units", "Trait Filter",
    "Placeholder: no filter connected.")

addToggle(Units, "Units", "Grade Filter",
    "Placeholder: no filter connected.")

-- TOWER
addToggle(Tower, "Tower", "Potion Loadout",
    "Placeholder: no loadout connected.")

addToggle(Tower, "Tower", "Reward Alerts",
    "Placeholder: no alerts connected.")

addToggle(Tower, "Tower", "Run Summary",
    "Placeholder: no tracking connected.")

-- SETTINGS
addToggle(Settings, "Settings", "Notifications",
    "Toast notifications are active.")

addToggle(Settings, "Settings", "Compact Layout",
    "Placeholder: layout change not connected.")

addToggle(Settings, "Settings", "Remember UI Position",
    "Placeholder: position saving not connected.")

addToggle(Settings, "Settings", "Anti-AFK",
    "Prevent idle disconnect where supported.",
    setAntiAfk)

-- UNLOAD
local function unload()
    if unloaded then return end

    Config.toggles = Config.toggles or {}
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

if Settings then
    pcall(function()
        Settings:CreateButton({
            name = "Unload dilangauto",
            callback = function()
                notify("dilangauto", "Unloading UI")
                unload()
            end,
        })
    end)
end

-- RESTORE ANTI-AFK
if Config.toggles["Settings_AntiAFK"] == true then
    local ok, err = pcall(setAntiAfk, true)

    if ok then
        running["Settings_AntiAFK"] = true
        notify("Anti-AFK", "Restored from config")
    else
        warn("[dilangauto] Anti-AFK restore failed:", err)
        notify("Anti-AFK restore failed", tostring(err))
    end
end

notify("dilangauto loaded", "Config auto-save active")
