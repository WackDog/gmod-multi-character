-- cl_admin.lua
--[[
    File: cl_admin.lua
    Description: Client-side admin UI with tabs for character management, note editing, and log viewing.
                 Allows superadmins to manage player characters via a clean UI.
    Scope: Client
    Author: WackDog
]]

include("multi_character/sh_config.lua")

MC_LiveCharacterList = MC_LiveCharacterList or {}

net.Receive("MC_CharacterSelectedBroadcast", function()
    local name = net.ReadString()
    local steamid64 = net.ReadString()
    local charID = net.ReadUInt(32)
    local charName = net.ReadString()
    local faction = net.ReadString()

    MC_LiveCharacterList[steamid64] = {
        name = name,
        steamid64 = steamid64,
        charID = charID,
        charName = charName,
        faction = faction,
        lastSeen = os.time()
    }
end)

net.Receive("MC_AdminSendCharacters", function()
    local chars = net.ReadTable()
    local steamID64 = net.ReadString() or "unknown"

    if not LocalPlayer():IsSuperAdmin() then return end

    if IsValid(MC_AdminFrame) then MC_AdminFrame:Remove() end

    local noteMap = {}
    for _, v in ipairs(chars) do
        noteMap[v.id] = v.notes or ""
    end

    MC_AdminFrame = vgui.Create("DFrame")
    MC_AdminFrame:SetTitle("Admin Character Panel (" .. steamID64 .. ")")
    MC_AdminFrame:SetSize(900, 600)
    MC_AdminFrame:Center()
    MC_AdminFrame:MakePopup()

    MC_AdminFrame.OnClose = function()
        timer.Remove("MC_LiveListRefresh")
    end

    local sheet = vgui.Create("DPropertySheet", MC_AdminFrame)
    sheet:Dock(FILL)

    --------------------------------------------------------------------------
    -- TAB: Character Management
    --------------------------------------------------------------------------
    local charPanel = vgui.Create("DPanel", sheet)
    charPanel:Dock(FILL)

    local List = vgui.Create("DListView", charPanel)
    List:SetPos(10, 10)
    List:SetSize(860, 300)
    List:AddColumn("ID")
    List:AddColumn("Name")
    List:AddColumn("Faction")
    List:AddColumn("Dead")

    for _, v in ipairs(chars) do
        List:AddLine(v.id, v.name, v.faction, v.is_dead == "1" and "Yes" or "No")
    end

    local ReviveBtn = vgui.Create("DButton", charPanel)
    ReviveBtn:SetText("Revive")
    ReviveBtn:SetSize(120, 30)
    ReviveBtn:SetPos(10, 320)
    ReviveBtn.DoClick = function()
        local line = List:GetSelectedLine()
        if not line then return end
        local id = tonumber(List:GetLine(line):GetColumnText(1))
        Derma_Query("Are you sure you want to revive this character?", "Confirm Revive",
            "Yes", function()
                net.Start("MC_AdminReviveCharacter")
                net.WriteUInt(id, 32)
                net.SendToServer()
            end,
            "No"
        )
    end

    local DeleteBtn = vgui.Create("DButton", charPanel)
    DeleteBtn:SetText("Delete")
    DeleteBtn:SetSize(120, 30)
    DeleteBtn:SetPos(140, 320)
    DeleteBtn.DoClick = function()
        local line = List:GetSelectedLine()
        if not line then return end
        local id = tonumber(List:GetLine(line):GetColumnText(1))
        Derma_Query("Are you sure you want to permanently delete this character?", "Confirm Deletion",
            "Yes", function()
                net.Start("MC_AdminDeleteCharacter")
                net.WriteUInt(id, 32)
                net.SendToServer()
            end,
            "No"
        )
    end

    local PlayerDropdown = vgui.Create("DComboBox", charPanel)
    PlayerDropdown:SetSize(300, 25)
    PlayerDropdown:SetPos(10, 370)
    PlayerDropdown:SetValue("Select player to force-switch")

    local sidMap = {}
    for _, ply in ipairs(player.GetAll()) do
        local label = ply:Nick() .. " (" .. ply:SteamID64() .. ")"
        PlayerDropdown:AddChoice(label, ply:SteamID64())
        sidMap[label] = ply:SteamID64()
    end

    local ForceSwitchBtn = vgui.Create("DButton", charPanel)
    ForceSwitchBtn:SetText("Force Switch")
    ForceSwitchBtn:SetSize(150, 30)
    ForceSwitchBtn:SetPos(320, 368)
    ForceSwitchBtn.DoClick = function()
        local line = List:GetSelectedLine()
        local label = PlayerDropdown:GetSelected()
        if not line or not label or not sidMap[label] then return end

        local charID = tonumber(List:GetLine(line):GetColumnText(1))
        local sid64 = sidMap[label]

        Derma_Query("Force switch player to this character?", "Confirm",
            "Yes", function()
                net.Start("MC_AdminForceSwitchCharacter")
                net.WriteString(sid64)
                net.WriteUInt(charID, 32)
                net.SendToServer()
            end,
            "No"
        )
    end

    sheet:AddSheet("Character Management", charPanel, "icon16/user.png")

    --------------------------------------------------------------------------
    -- TAB: Admin Notes
    --------------------------------------------------------------------------
    local notePanel = vgui.Create("DPanel", sheet)
    notePanel:Dock(FILL)

    local NoteList = vgui.Create("DListView", notePanel)
    NoteList:SetPos(10, 10)
    NoteList:SetSize(860, 200)
    NoteList:AddColumn("ID")
    NoteList:AddColumn("Name")
    NoteList:AddColumn("Note")

    for _, v in ipairs(chars) do
        NoteList:AddLine(v.id, v.name, string.sub(v.notes or "", 1, 40) .. "...")
    end

    local NoteBox = vgui.Create("DTextEntry", notePanel)
    NoteBox:SetPos(10, 220)
    NoteBox:SetSize(860, 100)
    NoteBox:SetMultiline(true)
    NoteBox:SetPlaceholderText("Edit selected character's admin notes here...")

    function NoteList:OnRowSelected(_, line)
        local id = tonumber(line:GetColumnText(1))
        NoteBox:SetText(noteMap[id] or "")
    end

    local SaveBtn = vgui.Create("DButton", notePanel)
    SaveBtn:SetText("Save Note")
    SaveBtn:SetPos(10, 330)
    SaveBtn:SetSize(120, 30)
    SaveBtn.DoClick = function()
        local line = NoteList:GetSelectedLine()
        if not line then return end
        local id = tonumber(NoteList:GetLine(line):GetColumnText(1))
        local note = NoteBox:GetValue() or ""
        net.Start("MC_AdminEditNote")
        net.WriteUInt(id, 32)
        net.WriteString(note)
        net.SendToServer()
    end

    sheet:AddSheet("Notes", notePanel, "icon16/note.png")

    --------------------------------------------------------------------------
    -- TAB: Live View
    --------------------------------------------------------------------------
    local livePanel = vgui.Create("DPanel", sheet)
    livePanel:Dock(FILL)

    local liveList = vgui.Create("DListView", livePanel)
    liveList:SetPos(10, 10)
    liveList:SetSize(860, 500)
    liveList:AddColumn("Player")
    liveList:AddColumn("SteamID64")
    liveList:AddColumn("Character")
    liveList:AddColumn("Faction")
    liveList:AddColumn("Last Seen")

    local function UpdateLiveList()
        liveList:Clear()
        for _, data in pairs(MC_LiveCharacterList) do
            liveList:AddLine(data.name, data.steamid64, data.charName, data.faction, os.date("%H:%M:%S", data.lastSeen))
        end
    end

    timer.Create("MC_LiveListRefresh", 5, 0, function()
        if IsValid(liveList) then
            UpdateLiveList()
        end
    end)

    UpdateLiveList()

    sheet:AddSheet("Live View", livePanel, "icon16/eye.png")
end)

-- 🛠️ Open Admin Panel
concommand.Add("MC_OpenAdminPanel", function()
    if not LocalPlayer():IsSuperAdmin() then return end
    Derma_StringRequest("Character Lookup", "Enter SteamID64 of player:", "", function(sid64)
        net.Start("MC_AdminRequestCharacters")
        net.WriteString(sid64)
        net.SendToServer()
    end)
end)
