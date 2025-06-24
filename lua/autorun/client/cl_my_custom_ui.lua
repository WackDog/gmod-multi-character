-- cl_mc_custom_ui.lua
--[[ 
    Custom Character Menu UI (Expanded)
    Full override for Multi-Character System with GMod Store quality polish

    Author: WackDog
--]]

if not mc_config or not mc_config.DisableDefaultUI then return end

hook.Add("MC_CustomCharacterMenu", "MyCustomUI_Render", function(chars)
    if IsValid(MyCharMenu) then MyCharMenu:Remove() end

    MyCharMenu = vgui.Create("DFrame")
    MyCharMenu:SetTitle("Character Selection")
    MyCharMenu:SetSize(ScrW() * 0.65, ScrH() * 0.65)
    MyCharMenu:Center()
    MyCharMenu:MakePopup()

    local sheet = vgui.Create("DPropertySheet", MyCharMenu)
    sheet:Dock(FILL)

    -------------------------------------------------------------------
    -- TAB 1: Character List
    -------------------------------------------------------------------
    local listPanel = vgui.Create("DPanel", sheet)
    listPanel:Dock(FILL)

    local charList = vgui.Create("DListView", listPanel)
    charList:Dock(FILL)
    charList:AddColumn("ID")
    charList:AddColumn("Name")
    charList:AddColumn("Faction")
    charList:AddColumn("Dead")

    local selectedID = nil

    for _, v in ipairs(chars) do
        local dead = v.is_dead == "1" and "Yes" or "No"
        local line = charList:AddLine(v.id, v.name, v.faction, dead)
        if v.is_dead == "1" then
            line.Paint = function(_, w, h)
                surface.SetDrawColor(150, 50, 50, 100)
                surface.DrawRect(0, 0, w, h)
            end
        end
    end

    function charList:OnRowSelected(_, line)
        selectedID = tonumber(line:GetColumnText(1))
    end

    local selectBtn = vgui.Create("DButton", listPanel)
    selectBtn:SetText("Select Character")
    selectBtn:Dock(BOTTOM)
    selectBtn:SetTall(30)
    selectBtn.DoClick = function()
        if not selectedID then return end
        net.Start("MC_SelectCharacter")
        net.WriteUInt(selectedID, 32)
        net.SendToServer()
        MyCharMenu:Close()
    end

    sheet:AddSheet("Characters", listPanel, "icon16/user.png")

    -------------------------------------------------------------------
    -- TAB 2: Create Character
    -------------------------------------------------------------------
    local createPanel = vgui.Create("DPanel", sheet)
    createPanel:Dock(FILL)

    local nameEntry = vgui.Create("DTextEntry", createPanel)
    nameEntry:SetPlaceholderText("Character Name")
    nameEntry:SetSize(300, 25)
    nameEntry:SetPos(20, 20)

    local factionDropdown = vgui.Create("DComboBox", createPanel)
    factionDropdown:SetPos(340, 20)
    factionDropdown:SetSize(200, 25)
    factionDropdown:SetValue("Select Faction")

    local modelDropdown = vgui.Create("DComboBox", createPanel)
    modelDropdown:SetPos(20, 60)
    modelDropdown:SetSize(300, 25)
    modelDropdown:SetValue("Select Model")

    local modelPanel = vgui.Create("DModelPanel", createPanel)
    modelPanel:SetPos(340, 60)
    modelPanel:SetSize(200, 200)
    modelPanel:SetFOV(25)
    modelPanel:SetCamPos(Vector(50, 0, 60))
    modelPanel:SetLookAt(Vector(0, 0, 60))

    local bioEntry = vgui.Create("DTextEntry", createPanel)
    bioEntry:SetPos(20, 100)
    bioEntry:SetSize(520, 80)
    bioEntry:SetMultiline(true)
    bioEntry:SetPlaceholderText("Character Backstory / Notes")

    local factions = mc_config and mc_config.Factions or {}

    for faction, data in pairs(factions) do
        factionDropdown:AddChoice(faction)
    end

    factionDropdown.OnSelect = function(_, _, faction)
        modelDropdown:Clear()
        local models = factions[faction].models or {}
        for _, mdl in ipairs(models) do
            modelDropdown:AddChoice(mdl)
        end
        modelDropdown:SetValue("Select Model")
    end

    modelDropdown.OnSelect = function(_, _, model)
        if util.IsValidModel(model) then
            modelPanel:SetModel(model)
        end
    end

    local createBtn = vgui.Create("DButton", createPanel)
    createBtn:SetText("Create Character")
    createBtn:SetPos(20, 200)
    createBtn:SetSize(200, 30)
    createBtn.DoClick = function()
        local name = nameEntry:GetValue()
        local faction = factionDropdown:GetSelected()
        local model = modelDropdown:GetSelected()
        local bio = bioEntry:GetValue()

        if name == "" or not faction or not model then
            notification.AddLegacy("Please complete all fields.", NOTIFY_ERROR, 4)
            return
        end

        if faction ~= "Citizen" and not (mc_config.Whitelist and mc_config.Whitelist[faction] and mc_config.Whitelist[faction][LocalPlayer():SteamID64()]) then
            notification.AddLegacy("You are not whitelisted for this faction.", NOTIFY_ERROR, 4)
            return
        end

        net.Start("MC_CreateCharacter")
        net.WriteString(name)
        net.WriteString(model)
        net.WriteString(faction)
        net.WriteString(bio or "")
        net.SendToServer()

        MyCharMenu:Close()
    end

    sheet:AddSheet("Create", createPanel, "icon16/add.png")
end)

-- Command for testing
concommand.Add("MC_ShowCustomUI", function()
    net.Start("MC_RequestCharacters")
    net.SendToServer()
end)
