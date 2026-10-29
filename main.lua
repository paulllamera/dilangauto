
-- dilangauto.lua
-- Rayfield Gen2 UI

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/gen2"
))()

local Window = Rayfield:CreateWindow({
    name = "dilangauto",
    subtitle = "Auto Collect",
    sidebarLayout = true,
})

local running = {}
local connections = {}

local function makeTab(name, icon)
    return Window:CreateTab({
        name = name,
        icon = icon,
    })
end

local function addToggle(tab, tabName, name, purpose, onChanged)
    local toggle = tab:CreateToggle({
        name = name,
        flag = tabName .. "_" .. name:gsub("%W", ""),
        value = false,

        callback = function(value)
            running[tabName .. "_" .. name] = value

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
        end,
    })

    return toggle
end

local function addButton(tab, name, callback)
    tab:CreateButton({
        name = name,
        callback = callback,
    })
end

-- TABS
local Halloween = makeTab("Halloween", 93364949241311)
local Farm = makeTab("Farm", 4483362458)
local Units = makeTab("Units", 6031094678)
local Tower = makeTab("Tower", 6031265976)
local Settings = makeTab("Settings", 7733960981)

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

-- Auto Collect diagnostic

addToggle(
    Farm,
    "Farm",
    "Auto Collect",
    "Collect balances from all plot IDs.",
    function(enabled)
        local key = "AutoCollectAllPlots"

        running[key] = enabled

        if not enabled then
            print("[dilangauto] Auto Collect stopped")
            return
        end

        task.spawn(function()
            local remote = game:GetService("ReplicatedStorage")
                :WaitForChild("Network")
                :WaitForChild("PlotService")
                :WaitForChild("RE")
                :WaitForChild("CollectBalance")

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
    end
)


addToggle(Farm, "Farm", "Auto Rebirth",
    "No game action connected.")

addToggle(Farm, "Farm", "Potion Manager",
    "No potion logic connected.")

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
addToggle(Settings, "Settings", "Notifications", "No notification system connected.")
addToggle(Settings, "Settings", "Compact Layout", "No layout change connected.")
addToggle(Settings, "Settings", "Remember UI Position", "No position saving connected.")

-- UNLOAD
addButton(Settings, "Unload dilangauto", function()
    for key in pairs(running) do
        running[key] = false
    end

    if Window and type(Window.Destroy) == "function" then
        pcall(function()
            Window:Destroy()
        end)
    elseif Rayfield and type(Rayfield.Destroy) == "function" then
        pcall(function()
            Rayfield:Destroy()
        end)
    else
        warn("[dilangauto] No supported Destroy method found.")
    end
end)

print("[dilangauto] UI loaded")
