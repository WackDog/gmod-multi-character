-- cl_menu.lua
--[[
    File: cl_menu.lua
    Description: Client-side user interface for players to manage their characters (select, create, rename, delete).
                 Provides model preview, faction dropdowns, and validation.
    Scope: Client
    Author: WackDog
]]

-- Disable default UI if opted out

function MC_OpenCharacterMenu()
    net.Start("MC_RequestCharacters")
    net.SendToServer()
end

-- Disable default UI if opted out
if mc_config and mc_config.DisableDefaultUI then return end

net.Receive("MC_SendCharacters", function()
    local chars = net.ReadTable()

    -- External override hook
    hook.Run("MC_BeforeCharacterMenu", chars)

    if mc_config.DisableDefaultUI then
        hook.Run("MC_CustomCharacterMenu", chars)
        return
    end

    -- Default Derma UI continues below
    if IsValid(MC_Frame) then MC_Frame:Remove() end

    MC_Frame = vgui.Create("DFrame")
    MC_Frame:SetTitle("Character Menu")
    MC_Frame:SetSize(700, 500)
    MC_Frame:Center()
    MC_Frame:MakePopup()

    local ScrollPanel = vgui.Create("DScrollPanel", MC_Frame)
    ScrollPanel:SetPos(10, 35)
    ScrollPanel:SetSize(680, 300)

    local List = vgui.Create("DListView", ScrollPanel)
    List:Dock(FILL)
    List:AddColumn("ID")
    List:AddColumn("Name")
    List:AddColumn("Faction")
    List:SetMultiSelect(false)
    List:SetSortable(true)

    for _, v in ipairs(chars) do
        List:AddLine(v.id, v.name, v.faction)
    end

    -- Select Button
    local SelectBtn = vgui.Create("DButton", MC_Frame)
    SelectBtn:SetText("Select")
    SelectBtn:SetSize(100, 30)
    SelectBtn:SetPos(10, 350)
    SelectBtn.DoClick = function()
        local line = List:GetSelectedLine()
        if not line then return end
        local charID = tonumber(List:GetLine(line):GetColumnText(1))
        net.Start("MC_SelectCharacter")
        net.WriteUInt(charID, 32)
        net.SendToServer()
        hook.Run("MC_CharacterSelected", charID)
        MC_Frame:Close()
    end

    -- Delete
    local DeleteBtn = vgui.Create("DButton", MC_Frame)
    DeleteBtn:SetText("Delete")
    DeleteBtn:SetSize(100, 30)
    DeleteBtn:SetPos(120, 350)
    DeleteBtn.DoClick = function()
        local line = List:GetSelectedLine()
        if not line then return end
        local charID = tonumber(List:GetLine(line):GetColumnText(1))
        Derma_Query("Are you sure you want to delete this character?", "Confirm Deletion",
            "Yes", function()
                net.Start("MC_DeleteCharacter")
                net.WriteUInt(charID, 32)
                net.SendToServer()
                MC_Frame:Close()
            end,
            "No", function() end
        )
    end

    -- Rename
    local RenameBtn = vgui.Create("DButton", MC_Frame)
    RenameBtn:SetText("Rename")
    RenameBtn:SetSize(100, 30)
    RenameBtn:SetPos(230, 350)
    RenameBtn.DoClick = function()
        local line = List:GetSelectedLine()
        if not line then return end
        local charID = tonumber(List:GetLine(line):GetColumnText(1))
        Derma_StringRequest("Rename", "New character name:", "", function(newName)
            newName = string.Trim(newName)
            if newName == "" then return end
            net.Start("MC_RenameCharacter")
            net.WriteUInt(charID, 32)
            net.WriteString(newName)
            net.SendToServer()
        end)
    end

    -- Create Character UI
    local CreateBtn = vgui.Create("DButton", MC_Frame)
    CreateBtn:SetText("Create")
    CreateBtn:SetSize(100, 30)
    CreateBtn:SetPos(340, 350)
    CreateBtn.DoClick = function()
        if #chars >= (mc_config.MaxCharacters or 3) then
            notification.AddLegacy("Character slot limit reached.", NOTIFY_ERROR, 3)
            return
        end

        local CreateFrame = vgui.Create("DFrame")
        CreateFrame:SetTitle("Create Character")
        CreateFrame:SetSize(500, 400)
        CreateFrame:Center()
        CreateFrame:MakePopup()

        local nameEntry = vgui.Create("DTextEntry", CreateFrame)
        nameEntry:SetPos(10, 30)
        nameEntry:SetSize(240, 25)
        nameEntry:SetPlaceholderText("Character Name")

        local factionDropdown = vgui.Create("DComboBox", CreateFrame)
        factionDropdown:SetPos(260, 30)
        factionDropdown:SetSize(230, 25)
        factionDropdown:SetValue("Select Faction")

        local factionDesc = vgui.Create("DLabel", CreateFrame)
        factionDesc:SetPos(10, 60)
        factionDesc:SetSize(480, 30)
        factionDesc:SetText("")
        factionDesc:SetWrap(true)

        local modelDropdown = vgui.Create("DComboBox", CreateFrame)
        modelDropdown:SetPos(10, 100)
        modelDropdown:SetSize(240, 25)
        modelDropdown:SetValue("Select Model")

        local modelPanel = vgui.Create("DModelPanel", CreateFrame)
        modelPanel:SetPos(260, 100)
        modelPanel:SetSize(230, 160)
        modelPanel:SetModel("models/Humans/Group01/male_02.mdl")
        modelPanel:SetFOV(30)
        modelPanel:SetCamPos(Vector(50, 0, 50))
        modelPanel:SetLookAt(Vector(0, 0, 50))

        local backstory = vgui.Create("DTextEntry", CreateFrame)
        backstory:SetPos(10, 270)
        backstory:SetSize(480, 60)
        backstory:SetMultiline(true)
        backstory:SetPlaceholderText("Character Backstory / Bio")

        local factions = mc_config and mc_config.Factions or {}

        for faction, data in pairs(factions) do
            factionDropdown:AddChoice(faction)
        end

        factionDropdown.OnSelect = function(_, _, selectedFaction)
            modelDropdown:Clear()
            local models = factions[selectedFaction] and factions[selectedFaction].models or {}
            for _, mdl in ipairs(models) do
                modelDropdown:AddChoice(mdl)
            end
            modelDropdown:SetValue("Select Model")

            local desc = factions[selectedFaction] and factions[selectedFaction].description or ""
            factionDesc:SetText(desc)
        end

        modelDropdown.OnSelect = function(_, _, model)
            if util.IsValidModel(model) then
                modelPanel:SetModel(model)
            end
        end

        local submitBtn = vgui.Create("DButton", CreateFrame)
        submitBtn:SetText("Create")
        submitBtn:SetSize(100, 30)
        submitBtn:SetPos(200, 340)
        submitBtn.DoClick = function()
            local name = string.Trim(nameEntry:GetValue())
            local faction = factionDropdown:GetSelected()
            local model = modelDropdown:GetSelected()
            local bio = backstory:GetValue()

            if name == "" or not faction or not model then
                notification.AddLegacy("Please complete all fields.", NOTIFY_ERROR, 3)
                return
            end

            if faction ~= "Citizen" and not (mc_config.Whitelist and mc_config.Whitelist[faction] and mc_config.Whitelist[faction][LocalPlayer():SteamID64()]) then
                notification.AddLegacy("You are not whitelisted for that faction.", NOTIFY_ERROR, 4)
                return
            end

            net.Start("MC_CreateCharacter")
            net.WriteString(name)
            net.WriteString(model)
            net.WriteString(faction)
            net.WriteString(bio or "")
            net.SendToServer()

            CreateFrame:Close()
        end
    end
end)

-- Auto-load characters on join
hook.Add("InitPostEntity", "MC_Request", function()
    timer.Simple(1, function()
        net.Start("MC_RequestCharacters")
        net.SendToServer()
    end)
end)

