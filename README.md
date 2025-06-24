# GMod Multi-Character System

A modular and extensible multi-character management system for Garry's Mod.

Designed to plug in to a pre-existing server UI

## Features

-  Multiple character slots per player
-  Admin tools with revive/delete/switch/logs/export
-  Custom faction support with spawn/inventory definitions
-  Admin notes per character
-  Optional permadeath support
-  Plug-and-play UI override system

---

## 📁 File Structure

```
gmod-multi-character/
├── lua/
│   ├── autorun/
│   │   └── cl_my_custom_ui.lua
│   ├── autorun/server/
│   │   └── sv_init.lua
│   ├── multi_character/
│   │   ├── cl_admin.lua
│   │   ├── cl_menu.lua
│   │   ├── sh_config.lua
│   │   ├── sv_admin.lua
│   │   ├── sv_logic.lua
├── data/
│   └── character/
│       └── admin_logs.txt
├── mock/
│   ├── admin_logs.txt
│   ├── characters.sql
│   └── export.csv
└── README.md
```

---

## ⚙️ Configuration

Edit `lua/multi_character/sh_config.lua`:

```lua
mc_config.MaxCharacters = 3
mc_config.PermakillEnabled = true
mc_config.DeadCharacterMessage = "This character is permanently dead."
mc_config.DisableDefaultUI = false
```

Add new factions in `mc_config.Factions` with custom spawn points, models, and inventory.

---

## 🔌 UI Integration

Override the default UI by setting:

```lua
mc_config.DisableDefaultUI = true
```

Then, hook into:

```lua
hook.Add("MC_CustomCharacterMenu", "YourHook", function(characters)
    -- Open your custom UI here.
end)
```

Or intercept early via:

```lua
hook.Add("MC_BeforeCharacterMenu", "LogCharacters", function(characters)
    PrintTable(characters)
end)
```

---

## 📚 Available Hooks

| Hook Name                | Description                               |
|-------------------------|-------------------------------------------|
| `MC_BeforeCharacterMenu`| Called before default character UI opens  |
| `MC_CustomCharacterMenu`| Lets servers replace UI entirely          |
| `MC_CharacterSelected`  | Fires after character selection           |

---

## ✅ Requirements

- Garry's Mod (x64 preferred)
- SQLite (default database engine)

---

## 🧪 Mock SQL

To test character data, use `mock/mock_characters.sql` to prefill the `characters` table.

---

## 🧑‍💻 Author

- Created by WackDog for interview/portfolio purposes.
- Not for resale or commercial GModStore listing.
