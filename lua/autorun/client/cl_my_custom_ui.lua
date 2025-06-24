-- cl_my_custom_ui.lua
-- Example of overriding the default Multi-Character UI

-- Register a hook that your system will call before showing default UI
hook.Add("MC_CustomCharacterMenu", "MyCustomCharacterMenu", function(characters)
    -- You now have full control to display your own menu
    print("[Custom UI] Received characters:", #characters)

    -- Example: simple notification + print
    for _, char in ipairs(characters) do
        print(string.format("ID: %s | Name: %s | Faction: %s", char.id, char.name, char.faction))
    end

    -- Example: create a very basic panel
    local frame = vgui.Create("DFrame")
    frame:SetTitle("My Custom Character UI")
    frame:SetSize(500, 400)
    frame:Center()
    frame:MakePopup()

    local list = vgui.Create("DListView", frame)
    list:Dock(FILL)
    list:AddColumn("ID")
    list:AddColumn("Name")
    list:AddColumn("Faction")

    for _, char in ipairs(characters) do
        list:AddLine(char.id, char.name, char.faction)
    end

    list.OnRowSelected = function(_, index, line)
        local charID = tonumber(line:GetColumnText(1))
        net.Start("MC_SelectCharacter")
        net.WriteUInt(charID, 32)
        net.SendToServer()

        frame:Close()
    end
end)
