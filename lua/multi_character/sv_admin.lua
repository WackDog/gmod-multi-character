-- sv_admin.lua
--[[
    File: sv_admin.lua
    Description: Server-side admin panel support, logging, and command/control over characters.
                 Includes character revive/delete, live switching, and note editing.
    Scope: Server
    Author: WackDog
]]


util.AddNetworkString("MC_AdminRequestCharacters")
util.AddNetworkString("MC_AdminSendCharacters")
util.AddNetworkString("MC_AdminReviveCharacter")
util.AddNetworkString("MC_AdminDeleteCharacter")
util.AddNetworkString("MC_AdminForceSwitchCharacter")
util.AddNetworkString("MC_AdminEditNote")
util.AddNetworkString("MC_AdminRequestLogs")
util.AddNetworkString("MC_AdminSendLogs")

local LOG_PATH = "multi_character/admin_logs.txt"

-- Logging
local function LogAdminAction(ply, action)
    local line = os.date("[%Y-%m-%d %H:%M:%S] ") ..
        ply:Nick() .. " (" .. ply:SteamID64() .. ") " .. action .. "\n"
    file.Append(LOG_PATH, line)
    print("[MC LOG] " .. line)
end

-- Debug Concommands

concommand.Add("MC_ListCharacters", function(ply, _, args)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local sid64 = args[1]
    if not sid64 then
        print("[MC] Usage: MC_ListCharacters <steamid64>")
        return
    end
    local rows = sql.Query("SELECT * FROM characters WHERE steamid64 = '" .. sid64 .. "'")
    if not rows then
        print("[MC] No characters found for " .. sid64)
    else
        PrintTable(rows)
    end
end)

concommand.Add("MC_ExportCharacters", function(ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    local rows = sql.Query("SELECT * FROM characters")
    if not rows then
        print("[MC] No characters to export.")
        return
    end

    local lines = { "id,steamid64,name,faction,is_dead" }
    for _, row in ipairs(rows) do
        local line = string.format("%s,%s,%s,%s,%s",
            row.id or "",
            row.steamid64 or "",
            string.gsub(row.name or "", ",", ";"),
            row.faction or "",
            row.is_dead or "0"
        )
        table.insert(lines, line)
    end

    file.Write("multi_character/export.csv", table.concat(lines, "\n"))
    print("[MC] Character export saved to data/multi_character/export.csv")
end)

-- Net Receivers

net.Receive("MC_AdminRequestCharacters", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local sid64 = net.ReadString()
    if not sid64 then return end

    local rows = sql.Query("SELECT * FROM characters WHERE steamid64 = '" .. sid64 .. "'")
    net.Start("MC_AdminSendCharacters")
    net.WriteTable(rows or {})
    net.WriteString(sid64)
    net.Send(ply)
end)

net.Receive("MC_AdminReviveCharacter", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local id = net.ReadUInt(32)
    sql.Query("UPDATE characters SET is_dead = 0 WHERE id = " .. id)
    LogAdminAction(ply, "revived character ID " .. id)
end)

net.Receive("MC_AdminDeleteCharacter", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local id = net.ReadUInt(32)
    sql.Query("DELETE FROM characters WHERE id = " .. id)
    LogAdminAction(ply, "deleted character ID " .. id)
end)

net.Receive("MC_AdminForceSwitchCharacter", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local targetSID = net.ReadString()
    local charID = net.ReadUInt(32)

    for _, target in ipairs(player.GetAll()) do
        if target:SteamID64() == targetSID then
            target.CurrentCharacterID = charID
            net.Start("MC_SelectCharacter")
            net.WriteUInt(charID, 32)
            net.Send(target)
            LogAdminAction(ply, "force-switched " .. target:Nick() .. " to character ID " .. charID)
            return
        end
    end

    print("[MC] Player not found for force switch.")
end)

net.Receive("MC_AdminEditNote", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end
    local id = net.ReadUInt(32)
    local note = sql.SQLStr(net.ReadString() or "")
    sql.Query("UPDATE characters SET notes = " .. note .. " WHERE id = " .. id)
    LogAdminAction(ply, "edited note for character ID " .. id)
end)

net.Receive("MC_AdminRequestLogs", function(_, ply)
    if not IsValid(ply) or not ply:IsSuperAdmin() then return end

    if not file.Exists(LOG_PATH, "DATA") then
        net.Start("MC_AdminSendLogs")
        net.WriteString("No logs found.")
        net.Send(ply)
        return
    end

    local contents = file.Read(LOG_PATH, "DATA") or ""
    net.Start("MC_AdminSendLogs")
    net.WriteString(contents)
    net.Send(ply)
end)