-- sv_init.lua
-- Entry point for Multi-Character System (server-only)

-- 📦 Send client-side scripts
AddCSLuaFile("multi_character/cl_menu.lua")
AddCSLuaFile("multi_character/cl_admin.lua")
AddCSLuaFile("multi_character/sh_config.lua")

-- 🔄 Load server + shared logic
include("multi_character/sh_config.lua")
include("multi_character/sv_logic.lua")
include("multi_character/sv_admin.lua")

-- ✅ Loaded
print("[MultiCharacter v1.0] Server initialized.")
