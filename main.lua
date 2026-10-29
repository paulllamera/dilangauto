
-- dilangauto.lua
-- Rayfield Gen2 UI
-- Config persistence requires Delta file APIs.

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local CONFIG_FILE = "dilangauto_config.json"

local function log(...)
    print("[dilangauto]", ...)
end

local function warnLog(...)
    warn("[dilangauto]", ...)
end

-- LOAD RAYFIELD
local loaded, Rayfield = pcall(function()
    return loadstring(game:HttpGet(
        "https://sirius.menu/gen2"
    ))()
end)

if not loaded or not Rayfield then
    warnLog("Rayfield load failed:", Rayfield)
    return
end

-- CONFIG
local function loadConfig()
    if type(isfile) ~= "function"
        or type(readfile) ~= "function" then
        log("File APIs unavailable; using defaults")
        return {}
    end

    local existsOk, exists = pcall(isfile, CONFIG_FILE)
    if not existsOk or not exists then
        return {}
    end

    local ok, result = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if ok and type(result) == "table" then
        log("Config loaded")
        return result
    end

    warnLog("Config invalid; using defaults")
    return {}
end

local Config = loadConfig()
Config.toggles = type(Config.toggles) == "table"
    and Config.toggles or {}

local function saveConfig()
    if type(writefile) ~= "function" then
        warnLog("writefile unavailable; config not saved")
        return
    end

    local ok, err = pcall(function()
        writefile(
            CONFIG_FILE,
            HttpService:JSONEncode(Config)
        )
    end)

    if ok then
        log("Config saved")
    else
        warnLog("Config save failed:", err)
    end
end

-- WINDOW
local windowOk, Window = pcall(function()
    return Rayfield:CreateWindow({
        name = "dilangauto",
        subtitle = "Halloween Dashboard",
        sidebarLayout = true,
    })
end)

if not windowOk or not Window then
    warnLog("Window creation failed:", Window)
    return
end

local running = {}
local connections = {}
local unloaded = false

-- ANTI-AFK
local function setAntiAfk(enabled)
    if connections.antiAfk then
        connections.antiAfk:Disconnect()
        connections.antiAfk = nil
    end

    if not enabled then
        log("Anti-AFK disabled")
        return
    end

    local player = Players.LocalPlayer
    if not player then
        warnLog("LocalPlayer unavailable")
        return
    end

    connections.antiAfk = player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)

    log("Anti-AFK enabled")
end

-- TABS
local function makeTab(name, icon)
    local options = { name = name }
    if icon then
        options.icon = icon
    end

    local ok, tab = pcall(function()
        return Window:CreateTab(options)
    end)

    if not ok then
        warnLog("Tab creation failed:", name, tab)
        return nil
    end

    return tab
end

local Halloween = makeTab("Halloween", 93364949241311)
local Farm = makeTab("Farm", 4483362458)
local Units = makeTab("Units", 6031094678)
local Tower = makeTab("Tower", 6031265976)
local Settings = makeTab("Settings", 7733960981)

-- TOGGLES
local function addToggle(tab, tabName, name, purpose, onChanged)
    if not tab then
        warnLog("Missing tab for toggle:", name)
        return
    end

    local key = tabName .. "_" .. name:gsub("%W", "")
    local defaultValue = Config.toggles[key] == true

    local ok, toggle = pcall(function()
        return tab:CreateToggle({
            name = name,
            flag = key,
            value = defaultValue,

            callback = function(value)
                if unloaded then
                    return
                end

                running[key] = value
                Config.toggles[key] = value
                saveConfig()

                log(tabName .. " / " .. name .. ":", value)

                if onChanged then
                    local callbackOk, err = pcall(onChanged, value)
                    if not callbackOk then
                        warnLog("Callback failed:", name, err)
                    end
                else
                    log("Placeholder:", purpose)
                end
            end,
        })
    end)

    if not ok then
        warnLog("Toggle creation failed:", name, toggle)
    end
end

local function addButton(tab, name, callback)
    if not tab then return end

    local ok, err = pcall(function()
        tab:CreateButton({
            name = name,
            callback = callback,
        })
    end)

    if not ok then
        warnLog("Button creation failed:", name, err)
    end
end

-- HALLOWEEN
addToggle(Halloween, "Halloween", "Auto Trick-or-Treat",
    "No game action connected.")
addToggle(Halloween, "Halloween", "Auto Collect Candy",
    "No game action connected.")
addToggle(Halloween, "Halloween", "Event Alerts",
    "No alert system connected.")

-- FARM
addToggle(Farm, "Farm", "Auto Roll",
    "No game action connected.")
addToggle(Farm, "Farm", "Auto Sell",
    "No game action connected.")

addToggle(Farm, "Farm", "Auto Collect",
    "No game action connected. Remote details need verification.")

addToggle(Farm, "Farm", "Auto Rebirth",
    "No game action connected.")
addToggle(Farm, "Farm", "Potion Manager",
    "No potion logic connected.")

-- UNITS
addToggle(Units, "Units", "Equip Best",
    "No unit action connected.")
addToggle(Units, "Units", "Lock Rare Units",
    "No unit action connected.")
addToggle(Units, "Units", "Trait Filter",
    "No filter connected.")
addToggle(Units, "Units", "Grade Filter",
    "No filter connected.")

-- TOWER
addToggle(Tower, "Tower", "Potion Loadout",
    "No loadout connected.")
addToggle(Tower, "Tower", "Reward Alerts",
    "No alerts connected.")
addToggle(Tower, "Tower", "Run Summary",
    "No tracking connected.")

-- SETTINGS
addToggle(Settings, "Settings", "Notifications",
    "No notification system connected.")
addToggle(Settings, "Settings", "Compact Layout",
    "No layout change connected.")
addToggle(Settings, "Settings", "Remember UI Position",
    "No position saving connected.")

addToggle(Settings, "Settings", "Anti-AFK",
    "Prevent idle disconnect where supported.",
    setAntiAfk)

addButton(Settings, "Save Config", function()
    saveConfig()
end)

addButton(Settings, "Reload Config", function()
    Config = loadConfig()
    Config.toggles = type(Config.toggles) == "table"
        and Config.toggles or {}

    log("Config reloaded. Re-execute script to apply saved toggle states.")
end)

addButton(Settings, "Unload dilangauto", function()
    if unloaded then return end
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

    local ok, err = pcall(function()
        Rayfield:Destroy()
    end)

    if not ok then
        warnLog("Rayfield destroy failed:", err)
    end

    log("Unload requested")
end)

-- AUTO-SAVE INITIAL STATE
saveConfig()

-- Restore Anti-AFK after UI creation if previously enabled
local antiAfkKey = "Settings_AntiAFK"
if Config.toggles[antiAfkKey] == true then
    setAntiAfk(true)
    running[antiAfkKey] = true
end

log("UI loaded")
log("Auto-execute must be enabled in Delta's own script settings.")
