-- sv_init.lua
--[[
    File: sv_init.lua
    Description: Initialization entry point for the Multi-Character System. 
                 Registers and loads all client/server/shared components. 
                 Ensures network delivery and modular separation.

    Scope: Server
    Author: WackDog
]]

-- Shared
AddCSLuaFile("multi_character/sh_config.lua")
include("multi_character/sh_config.lua")

-- Client-side
AddCSLuaFile("multi_character/cl_menu.lua")
AddCSLuaFile("multi_character/cl_admin.lua")

-- Server-side
if SERVER then
    include("multi_character/sv_logic.lua")
    include("multi_character/sv_admin.lua")
end

-- Client-side (optional for dev environment if running on listen server)
if CLIENT then
    include("multi_character/cl_menu.lua")
    include("multi_character/cl_admin.lua")
end

print("[MultiCharacter v1.0] Server initialized.")
