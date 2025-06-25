-- sh_config.lua
--[[
    File: sh_config.lua
    Description: Shared configuration for the multi-character system, including faction definitions,
                 spawn settings, inventory, and character limits.
    Scope: Shared (included by both client and server)
    Author: WackDog
]]

mc_config = mc_config or {}

-- Max characters allowed per player
mc_config.MaxCharacters = 3

-- Enable permakill system
mc_config.PermakillEnabled = true

-- Optional UI notice for dead characters
mc_config.DeadCharacterMessage = "This character is permanently dead and cannot be used."

-- Disable built-in Derma UI (for server integration with custom UI systems)
mc_config.DisableDefaultUI = false

-- Faction definitions
mc_config.Factions = {
    ["Citizen"] = {
        name = "Citizen",
        description = "Ordinary residents of the city. Low-level access and default status.",
        models = {
            "models/Humans/Group01/male_02.mdl",
            "models/Humans/Group01/female_06.mdl"
        },
        spawn = Vector(0, 0, 0),
        inventory = {
            flashlight = 1,
            bandage = 1
        }
    },
    ["Civil Protection"] = {
        name = "Civil Protection",
        description = "The authoritarian city police force, tasked with enforcing Combine law.",
        models = {
            "models/player/police.mdl"
        },
        spawn = Vector(1000, 0, 0),
        inventory = {
            stunstick = 1,
            radio = 1
        }
    },
    ["Overwatch"] = {
        name = "Overwatch",
        description = "Elite transhuman military units used for suppression and tactical operations.",
        models = {
            "models/player/combine_soldier.mdl"
        },
        spawn = Vector(2000, 0, 0),
        inventory = {
            pulse_rifle = 1
        }
    }
}

-- Whitelist system for restricted factions
-- Format: ["Faction"]["SteamID64"] = true
mc_config.Whitelist = {
    ["Civil Protection"] = {
        ["76561198000000000"] = true
    },
    ["Overwatch"] = {
        ["76561198000000000"] = true
    }
}


