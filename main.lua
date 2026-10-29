-- dilangauto.lua
-- Rayfield Gen2
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = game:GetService("VirtualUser")

local CONFIG_FILE = "dilangauto_config.json"
local TOAST_ICON = 125823673784681

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
    name = "dilangauto",
    subtitle = "Automation",
    sidebarLayout = true
})

local LocalPlayer = Players.LocalPlayer
local running = {}
local connections = {}
local toggleRestorations = {}
local unloaded = false
local configReady = false

-- CONFIG

local function loadConfig()
    if type(isfile) ~= "function" or type(readfile) ~= "function" then
        return {
            toggles = {}
        }
    end

    local ok, exists = pcall(isfile, CONFIG_FILE)
    if not ok or not exists then
        return {
            toggles = {}
        }
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
    return {
        toggles = {}
    }
end

local Config = loadConfig()

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
        icon = TOAST_ICON
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
    local options = {
        name = name
    }
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

-- TOGGLE BUILDER

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

    local ok, result = pcall(function()
        return tab:CreateToggle({
            name = name,
            flag = key,
            value = savedValue,
            callback = function(value)
                applyValue(value, true)
            end
        })
    end)

    if not ok then
        notifyError("Create toggle: " .. name, result)
        return
    end

    -- Restore each saved callback once after all controls exist.
    table.insert(toggleRestorations, function()
        applyValue(savedValue, false)
    end)
end

-- BUTTON BUILDER

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
            end
        })
    end)

    if not ok then
        notifyError("Create button: " .. name, err)
    end
end

-- HALLOWEEN

addToggle(Halloween, "Halloween", "Auto Trick-or-Treat", "No game action connected.")

addToggle(Halloween, "Halloween", "Auto Collect Candy", "No game action connected.")

addToggle(Halloween, "Halloween", "Event Alerts", "No alert system connected.")

-- FARM

addToggle(Farm, "Farm", "Auto Roll", "No game action connected.")
addToggle(Farm, "Farm", "Auto Sell", "No game action connected.")

addToggle(Farm, "Farm", "Auto Collect", "Collection logic not connected.", function(enabled)
    -- Placeholder for authorized collection logic.
    running["AutoCollectAllPlots"] = enabled
    if not enabled then
        print("[dilangauto] Auto Collect stopped")
        return
    end

    task.spawn(function()
        local remote = game:GetService("ReplicatedStorage"):WaitForChild("Network"):WaitForChild("PlotService")
            :WaitForChild("RE"):WaitForChild("CollectBalance")

        while running[key] do
            for plotId = 1, 20 do
                if not running[key] then
                    break
                end

                local ok, err = pcall(function()
                    remote:FireServer(plotId)
                end)

                if not ok then
                    warn("[dilangauto] Plot", plotId, err)
                end
            end

            task.wait(2)
        end
    end)
end)

addToggle(Farm, "Farm", "Auto Rebirth", "No game action connected.")
addToggle(Farm, "Farm", "Potion Manager", "No potion logic connected.")

-- UNITS

addToggle(Units, "Units", "Equip Best", "No unit action connected.")
addToggle(Units, "Units", "Lock Rare Units", "No unit action connected.")
addToggle(Units, "Units", "Trait Filter", "No filter connected.")
addToggle(Units, "Units", "Grade Filter", "No filter connected.")

-- TOWER

addToggle(Tower, "Tower", "Potion Loadout", "No loadout connected.")
addToggle(Tower, "Tower", "Reward Alerts", "No alerts connected.")
addToggle(Tower, "Tower", "Run Summary", "No tracking connected.")

-- SETTINGS

addToggle(Settings, "Settings", "Notifications", "Toast notifications setting.")

addToggle(Settings, "Settings", "Compact Layout", "No layout change connected.")
addToggle(Settings, "Settings", "Remember UI Position", "No position saving connected.")

addToggle(Settings, "Settings", "Anti-AFK", "Maintain Anti-AFK connection.", setAntiAfk)

-- UNLOAD

local function unload()
    if unloaded then
        return
    end

    -- Stop active loops and connections first.
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

-- RESTORE SAVED STATE

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

-- Silent autosave. No save button or save toast.
saveConfig()
notify("dilangauto loaded", "Saved settings restored")
