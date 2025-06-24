-- sv_logic.lua
--[[
    File: sv_logic.lua
    Description: Core server-side logic for character creation, selection, deletion, renaming,
                 and schema initialization. Handles character state persistence and permadeath logic.
    Scope: Server
    Author: WackDog
]]

util.AddNetworkString("MC_RequestCharacters")
util.AddNetworkString("MC_SendCharacters")
util.AddNetworkString("MC_SelectCharacter")
util.AddNetworkString("MC_CreateCharacter")
util.AddNetworkString("MC_DeleteCharacter")
util.AddNetworkString("MC_RenameCharacter")
util.AddNetworkString("MC_CharacterSelectedBroadcast")

include("multi_character/sh_config.lua")

-- Placeholder SQL wrapper
MySQLite = MySQLite or {}
MySQLite.Query = sql.Query

-- 🛠 Auto-patch: add 'notes' column if missing
local function EnsureNotesColumn()
    local info = sql.Query("PRAGMA table_info(characters)")
    if not info then return end
    for _, col in ipairs(info) do
        if col.name == "notes" then return end
    end
    sql.Query("ALTER TABLE characters ADD COLUMN notes TEXT;")
    print("[MC] Added 'notes' column to characters table.")
end

hook.Add("Initialize", "MC_CheckSchema", EnsureNotesColumn)

-- ☠️ Permakill logic
hook.Add("PlayerDeath", "MC_PermakillOnDeath", function(ply)
    if not mc_config.PermakillEnabled then return end
    if not ply.CurrentCharacterID then return end
    MySQLite:Query("UPDATE characters SET is_dead = 1 WHERE id = " .. ply.CurrentCharacterID .. " AND steamid64 = '" .. ply:SteamID64() .. "'")
end)

-- 📡 Broadcast character switches (for Live Viewer)
local function BroadcastCharSelection(ply, charID, charName, faction)
    net.Start("MC_CharacterSelectedBroadcast")
    net.WriteString(ply:Nick())
    net.WriteString(ply:SteamID64())
    net.WriteUInt(charID, 32)
    net.WriteString(charName or "Unknown")
    net.WriteString(faction or "Unknown")
    net.Broadcast()
end

-- 🔁 Utility: load all alive characters
local function LoadCharactersFor(ply)
    local sid64 = ply:SteamID64()
    local chars = MySQLite:Query("SELECT * FROM characters WHERE steamid64 = '" .. sid64 .. "' AND is_dead = 0") or {}

    net.Start("MC_SendCharacters")
    net.WriteTable(chars)
    net.Send(ply)
end

-- 📨 Character list request
net.Receive("MC_RequestCharacters", function(_, ply)
    LoadCharactersFor(ply)
end)

-- 🧍 Character select
net.Receive("MC_SelectCharacter", function(_, ply)
    local charID = net.ReadUInt(32)
    ply.CurrentCharacterID = charID

    local sid64 = ply:SteamID64()
    local results = sql.Query("SELECT * FROM characters WHERE id = " .. charID .. " AND steamid64 = '" .. sid64 .. "' AND is_dead = 0")
    if not results or not results[1] then
        ply:ChatPrint("Character not found or is dead.")
        return
    end

    local char = results[1]
    ply:SetModel(char.model)
    ply:SetNWString("MC_CharName", char.name)
    ply:SetNWString("MC_Faction", char.faction)
    ply:SetNWString("MC_Backstory", char.backstory or "")

    local factionData = mc_config.Factions[char.faction]
    if factionData and factionData.spawn then
        ply:SetPos(factionData.spawn)
    end

    if factionData and factionData.inventory then
        for class, amount in pairs(factionData.inventory) do
            for i = 1, amount do
                local wep = ply:Give(class)
                if IsValid(wep) then
                    wep:SetClip1(0)
                end
            end
        end
    end

    BroadcastCharSelection(ply, charID, char.name, char.faction)
    ply:Spawn()
end)

-- ➕ Character creation
net.Receive("MC_CreateCharacter", function(_, ply)
    local name = sql.SQLStr(net.ReadString())
    local model = sql.SQLStr(net.ReadString())
    local faction = sql.SQLStr(net.ReadString())
    local backstory = sql.SQLStr(net.ReadString())
    local sid64 = ply:SteamID64()

    local factionStr = string.Trim(net.ReadString())
    if factionStr ~= "Citizen" then
        local wl = mc_config.Whitelist and mc_config.Whitelist[factionStr]
        if not (wl and wl[sid64]) then
            ply:ChatPrint("You are not whitelisted for that faction.")
            return
        end
    end

    MySQLite:Query(string.format(
        "INSERT INTO characters (steamid64, name, model, faction, is_dead, backstory) VALUES ('%s', %s, %s, %s, 0, %s)",
        sid64, name, model, faction, backstory or "''"
    ))

    LoadCharactersFor(ply)
end)

-- ❌ Character delete
net.Receive("MC_DeleteCharacter", function(_, ply)
    local id = net.ReadUInt(32)
    MySQLite:Query("DELETE FROM characters WHERE id = " .. id .. " AND steamid64 = '" .. ply:SteamID64() .. "'")
    LoadCharactersFor(ply)
end)

-- ✏️ Rename character
net.Receive("MC_RenameCharacter", function(_, ply)
    local id = net.ReadUInt(32)
    local newName = sql.SQLStr(net.ReadString())
    MySQLite:Query(string.format(
        "UPDATE characters SET name = %s WHERE id = %d AND steamid64 = '%s'",
        newName, id, ply:SteamID64()
    ))
    LoadCharactersFor(ply)
end)
