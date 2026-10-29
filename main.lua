
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
    subtitle = "Halloween Dashboard",
    sidebarLayout = true,

    -- Rayfield's built-in config persistence.
    configuration = {
        autoSave = true,
        autoLoad = true,
        fileName = "dilangauto",
    },
})

local running = {}
local connections = {}
local toggleCallbacks = {}
local unloaded = false

-- TOASTS
local function notify(title, subtitle)
    if unloaded then return end

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

-- CUSTOM CONFIG
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
        if type(result.toggles) ~= "table" then
            result.toggles = {}
        end
        return result
    end

    warn("[dilangauto] Config invalid; defaults used")
    return { toggles = {} }
end

local Config = loadConfig()
Config.toggles = type(Config.toggles) == "table"
    and Config.toggles or {}

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

    local player = Players.LocalPlayer
    assert(player, "LocalPlayer unavailable")

    connections.antiAfk = player.Idled:Connect(function()
        pcall(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
    end)
end

-- TOGGLES
local function addToggle(tab, tabName, name, purpose, onChanged)
    if not tab then return end

    local key = tabName .. "_" .. name:gsub("%W", "")
    local savedValue = Config.toggles[key] == true

    running[key] = savedValue

    local function applyValue(value, showToast)
        if unloaded then return end

        running[key] = value
        Config.toggles[key] = value

        -- Save silently. Never toast "Config saved".
        saveConfig()

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

    toggleCallbacks[key] = {
        apply = applyValue,
        value = savedValue,
    }

    -- Rayfield may not fire callback when loading initial value.
    -- Apply saved state explicitly so behavior matches saved config.
    if savedValue and onChanged then
        task.defer(function()
            if not unloaded then
                local callbackOk, err = pcall(onChanged, true)
                if not callbackOk then
                    notifyError("Restore " .. name, err)
                end
            end
        end)
    end
end

-- BUTTONS
local function addButton(tab, name, callback)
    if not tab then return end

    local ok, err = pcall(function()
        tab:CreateButton({
            name = name,
            callback = function()
                if unloaded then return end

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
    "UI toggle only; collection remote not connected.")

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
    "Toast notifications enabled.")

addToggle(Settings, "Settings", "Compact Layout",
    "Placeholder: layout change not connected.")

addToggle(Settings, "Settings", "Remember UI Position",
    "Placeholder: position saving not connected.")

addToggle(
    Settings,
    "Settings",
    "Anti-AFK",
    "Anti-AFK connection.",
    setAntiAfk
)

-- MANUAL SAVE BUTTON
-- Optional; automatic save still happens on each toggle change.
addButton(Settings, "Save Config Now", function()
    if saveConfig() then
        notify("Config", "Saved")
    else
        notify("Config", "Save failed; check executor file API")
    end
end)

-- UNLOAD
local function unload()
    if unloaded then return end

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

-- LOAD RAYFIELD CONFIGURATION
-- Supports Rayfield's own saved control state.
local loadOk, loadErr = pcall(function()
    Rayfield:LoadConfiguration()
end)

if not loadOk then
    warn("[dilangauto] Rayfield config load failed:", loadErr)
end

notify("dilangauto loaded", "Config restored where available")
