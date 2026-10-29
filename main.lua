
-- dilangauto.lua
-- Rayfield Gen2 UI; callbacks are placeholders.

local Rayfield = loadstring(game:HttpGet(
    "https://sirius.menu/gen2"
))()

local Window = Rayfield:CreateWindow({
    name = "dilangauto",
    subtitle = "Halloween Dashboard",
    sidebarLayout = true,
})

local function makeTab(name, icon)
    return Window:CreateTab({
        name = name,
        icon = icon,
    })
end

local function addToggle(tab, tabName, name, purpose)
    tab:CreateToggle({
        name = name,
        callback = function(value)
            print(
                "[dilangauto][" .. tabName .. "] "
                .. name .. ": " .. tostring(value)
            )
            print("[dilangauto][Info] " .. purpose)
        end,
    })
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
addToggle(
    Halloween,
    "Halloween",
    "Auto Trick-or-Treat",
    "Placeholder only. No game actions connected."
)

addToggle(
    Halloween,
    "Halloween",
    "Auto Collect Candy",
    "Placeholder only. No game actions connected."
)

addToggle(
    Halloween,
    "Halloween",
    "Event Alerts",
    "Placeholder only. No alerts connected."
)

-- FARM
addToggle(
    Farm,
    "Farm",
    "Auto Roll",
    "Placeholder only. No game actions connected."
)

addToggle(
    Farm,
    "Farm",
    "Auto Sell",
    "Placeholder only. No game actions connected."
)

addToggle(
    Farm,
    "Farm",
    "Auto Collect",
    "Placeholder only. No game actions connected."
)

addToggle(
    Farm,
    "Farm",
    "Auto Rebirth",
    "Placeholder only. No game actions connected."
)

addToggle(
    Farm,
    "Farm",
    "Potion Manager",
    "Placeholder only. No potion logic connected."
)

-- UNITS
addToggle(
    Units,
    "Units",
    "Equip Best",
    "Placeholder only. No unit actions connected."
)

addToggle(
    Units,
    "Units",
    "Lock Rare Units",
    "Placeholder only. No unit actions connected."
)

addToggle(
    Units,
    "Units",
    "Trait Filter",
    "Placeholder only. No filter logic connected."
)

addToggle(
    Units,
    "Units",
    "Grade Filter",
    "Placeholder only. No filter logic connected."
)

-- TOWER
addToggle(
    Tower,
    "Tower",
    "Potion Loadout",
    "Placeholder only. No loadout logic connected."
)

addToggle(
    Tower,
    "Tower",
    "Reward Alerts",
    "Placeholder only. No alerts connected."
)

addToggle(
    Tower,
    "Tower",
    "Run Summary",
    "Placeholder only. No tracking connected."
)

-- SETTINGS
addToggle(
    Settings,
    "Settings",
    "Notifications",
    "Placeholder only. No notification system connected."
)

addToggle(
    Settings,
    "Settings",
    "Compact Layout",
    "Placeholder only. No layout change connected."
)

addToggle(
    Settings,
    "Settings",
    "Remember UI Position",
    "Placeholder only. No position saving connected."
)

-- UNLOAD BUTTON
addButton(Settings, "Unload dilangauto", function()
    print("[dilangauto] Unload requested")

    -- Try supported cleanup methods.
    if Window and type(Window.Destroy) == "function" then
        pcall(function()
            Window:Destroy()
        end)
    elseif Rayfield and type(Rayfield.Destroy) == "function" then
        pcall(function()
            Rayfield:Destroy()
        end)
    else
        warn(
            "[dilangauto] No documented Destroy method found. "
            .. "Check Rayfield Gen2 API."
        )
    end
end)

print("[dilangauto] UI loaded")
