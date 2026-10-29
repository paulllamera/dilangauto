
-- dilangauto.lua
-- Rayfield Gen2 UI with JSON auto-save and Anti-AFK

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local VirtualUser = game:GetService("VirtualUser")

local CONFIG_FILE = "dilangauto_config.json"

local Config = {
    toggles = {},
}

if type(isfile) == "function"
    and type(readfile) == "function"
    and isfile(CONFIG_FILE)
then
    local ok, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)

    if ok and type(data) == "table" then
        if type(data.toggles) == "table" then
            Config.toggles = data.toggles
        end
    end
end

local function saveConfig()
    if type(writefile) ~= "function" then
        warn("[dilangauto] JSON file saving is not supported.")
        return
    end

    local ok, err = pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(Config))
    end)

    if not ok then
        warn("[dilangauto] Config save failed:", err)
    end
end

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/gen2"
))()

local Window = Rayfield:CreateWindow({
    name = "dilangauto",
    subtitle = "Automation",
    sidebarLayout = true,
})

local running = {}
local connections = {}
local restorers = {}
local unloading = false

local function makeTab(name, icon)
    return Window:CreateTab({
        name = name,
        icon = icon,
    })
end

local function addToggle(tab, tabName, name, purpose, onChanged)
    local key = tabName .. "_" .. name:gsub("%W", "")
    local initialValue = Config.toggles[key] == true

    local function applyCallback(value)
        running[key] = value

        print(
            "[dilangauto][" .. tabName .. "] "
            .. name .. ": " .. tostring(value)
        )

        if onChanged then
            local ok, err = pcall(onChanged, value)

            if not ok then
                warn("[dilangauto] Callback error:", err)
            end
        else
            print("[dilangauto][Info] " .. purpose)
        end
    end

    local toggle = tab:CreateToggle({
        name = name,
        flag = key,
        value = initialValue,

        callback = function(value)
            if unloading then
                return
            end

            Config.toggles[key] = value
            saveConfig()
            applyCallback(value)
        end,
    })

    restorers[#restorers + 1] = function()
        if initialValue then
            applyCallback(true)
        else
            running[key] = false
        end
    end

    return toggle
end

local function addButton(tab, name, callback)
    tab:CreateButton({
        name = name,
        callback = callback,
    })
end

-- ANTI-AFK

local function startAntiAfk()
    local player = Players.LocalPlayer

    if not player then
        return
    end

    connections[#connections + 1] =
        player.Idled:Connect(function()
            if unloading then
                return
            end

            pcall(function()
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end)
        end)
end

startAntiAfk()

-- TABS

local Halloween = makeTab("Halloween", 93364949241311)
local Farm = makeTab("Farm", 4483362458)
local Units = makeTab("Units", 6031094678)
local Tower = makeTab("Tower", 6031265976)
local Settings = makeTab("Settings", 7733960981)

-- HALLOWEEN

addToggle(
    Halloween,
    "Halloween",
    "Auto Trick-or-Treat",
    "No game action connected."
)

addToggle(
    Halloween,
    "Halloween",
    "Auto Collect Candy",
    "No game action connected."
)

addToggle(
    Halloween,
    "Halloween",
    "Event Alerts",
    "No alert system connected."
)

-- FARM

addToggle(
    Farm,
    "Farm",
    "Auto Roll",
    "No game action connected."
)

addToggle(
    Farm,
    "Farm",
    "Auto Sell",
    "No game action connected."
)

-- AUTO COLLECT

addToggle(
    Farm,
    "Farm",
    "Auto Collect",
    "Collect balances from all plot IDs.",
    function(enabled)
        local key = "Farm_AutoCollect"

        running[key] = enabled

        if not enabled then
            print("[dilangauto] Auto Collect stopped")
            return
        end

        task.spawn(function()
            local remote

            local ok, result = pcall(function()
                return game:GetService("ReplicatedStorage")
                    :WaitForChild("Network")
                    :WaitForChild("PlotService")
                    :WaitForChild("RE")
                    :WaitForChild("CollectBalance")
            end)

            if not ok then
                warn("[dilangauto] Could not find CollectBalance:", result)
                running[key] = false
                return
            end

            remote = result

            while running[key] and not unloading do
                for plotId = 1, 20 do
                    if not running[key] or unloading then
                        break
                    end

                    local callOk, err = pcall(function()
                        remote:FireServer(plotId)
                    end)

                    if not callOk then
                        warn("[dilangauto] Plot", plotId, err)
                    end
                end

                if running[key] and not unloading then
                    task.wait(2)
                end
            end
        end)
    end
)

addToggle(
    Farm,
    "Farm",
    "Auto Rebirth",
    "No game action connected."
)

addToggle(
    Farm,
    "Farm",
    "Potion Manager",
    "No potion logic connected."
)

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

addToggle(
    Settings,
    "Settings",
    "Notifications",
    "No notification system connected."
)

addToggle(
    Settings,
    "Settings",
    "Compact Layout",
    "No layout change connected."
)

addToggle(
    Settings,
    "Settings",
    "Remember UI Position",
    "No position saving connected."
)

-- MANUAL SAVE

addButton(Settings, "Save Settings Now", function()
    saveConfig()
    print("[dilangauto] Settings saved")
end)

-- UNLOAD

addButton(Settings, "Unload dilangauto", function()
    if unloading then
        return
    end

    unloading = true

    for key in pairs(running) do
        running[key] = false
    end

    saveConfig()

    for _, connection in ipairs(connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(connections)

    if Rayfield and type(Rayfield.Destroy) == "function" then
        pcall(function()
            Rayfield:Destroy()
        end)
    elseif Window and type(Window.Destroy) == "function" then
        pcall(function()
            Window:Destroy()
        end)
    end
end)

-- RESTORE SAVED ENABLED CALLBACKS AFTER ALL TOGGLES EXIST

for _, restore in ipairs(restorers) do
    restore()
end

print("[dilangauto] UI loaded")
print("[dilangauto] Saved settings restored")
