# Mod_Lina – Survivor Assistant v1

A three-tier AI-powered colony management assistant for **Stranded: Alien Dawn**.

## Overview

Mod_Lina provides real-time monitoring and decision support for your colony operations, with future integration for external AI APIs (OpenAI, Azure OpenAI, Claude, etc.).

### Current Version (v1)

**Mode A (Advisor)** is fully implemented and operational. Modes B and C are scaffolded and ready for future expansion.

---

## Features – v1 Release

### Mode A: Advisor (Fully Implemented)

**Hourly Monitoring & Alerts**

- **Survivor Stress**: Alerts when a survivor's stress exceeds your configured threshold (default: 80).
- **Survivor Hunger**: Alerts when a survivor's food level falls below your threshold (default: 20).
- **Resource Reserves**: Alerts when Cloth reserves drop below your threshold (default: 20).
- **Stalled Production**: Detects workbenches with queued tasks but no output for 4+ hours.

**Smart Notifications**

- Per-alert-type cooldown prevents spam (customizable).
- Category-based toggles let you enable/disable survivor, resource, or production alerts.
- All notifications branded as "Mod_Lina – Survivor Assistant".

**Persistent Configuration**

- Thresholds saved per save game.
- Global defaults provided for new games.
- Settings survive game reload cycles.

### Mode B & C: Scaffolding

Both Semi-Auto and Full Automation modes are scaffolded with extension points ready for future implementation.

---

## Getting Started

### Installation

1. Place the `SAD_MOD_Lina_01` folder into your Stranded: Alien Dawn mods directory.
2. Enable the mod in the game's mod manager.
3. Start a new game or load an existing save.

### First Run

When you load a map, Lina will display:
```
Mod_Lina – Survivor Assistant
Lina online. Monitoring survivor wellbeing and colony status.
```

Hourly alerts will begin automatically based on your configured thresholds.

---

## Configuration

### Console Commands (v1)

Open the debug console and use these commands to configure Lina:

#### Get Current Settings
```lua
ModLina_GetSettings()
```
Displays all current thresholds, alert toggles, and mode.

#### Set Mode
```lua
ModLina_SetMode("A")  -- Advisor (current only)
ModLina_SetMode("B")  -- Semi-Auto (scaffolded)
ModLina_SetMode("C")  -- Full-Auto (scaffolded)
```

#### Set Thresholds
```lua
ModLina_SetThreshold("stress", 75)    -- Stress alert threshold (0-100)
ModLina_SetThreshold("hunger", 15)    -- Hunger alert threshold (0-100)
ModLina_SetThreshold("cloth", 50)     -- Cloth reserve threshold (any value)
```

#### Enable/Disable Alert Categories
```lua
ModLina.Config.SetAlertEnabled("survivors", true)    -- Survivor alerts
ModLina.Config.SetAlertEnabled("resources", true)    -- Resource alerts
ModLina.Config.SetAlertEnabled("production", true)   -- Production alerts
```

#### Debug Mode
```lua
ModLina.Config.SetDebugEnabled(true)   -- Enable debug logging
ModLina.Config.SetDebugEnabled(false)  -- Disable debug logging
```

---

## Notification Cooldowns

Lina prevents alert spam using per-type cooldown periods:

- **Survivor Alerts**: 5 minutes per survivor (customizable)
- **Resource Alerts**: 10 minutes global (customizable)
- **Production Alerts**: 5 minutes per workbench (customizable)

Customize cooldowns with:
```lua
ModLina.Config.SetCooldown("survivor", 300)    -- seconds
ModLina.Config.SetCooldown("resources", 600)   -- seconds
ModLina.Config.SetCooldown("production", 300)  -- seconds
```

---

## Known Limitations – v1

- **No UI Dialog**: Settings are configured via console commands. Full UI coming in later versions.
- **API Credentials Not Used**: OpenAI/Azure/Claude fields are stored but not functional in v1.
- **Modes B & C Inactive**: Semi-Auto and Full-Auto modes display scaffold status only; no automation actions occur.
- **Single Resource Tracked**: Only Cloth is monitored. Additional resources can be added in future versions.
- **Basic Stall Detection**: Uses produced-item count delta. May need refinement based on specific game APIs.

---

## Future Roadmap

### v2+ Planned Features

- **Mode B (Semi-Auto)**: Auto-assign rest, food, and relaxation based on survivor needs.
- **Mode B (Semi-Auto)**: Auto-adjust workbench task queues to resolve bottlenecks.
- **Mode C (Full-Auto)**: Lina fully manages colony resource distribution and task allocation.
- **AI Integration**: Real API calls to external AI providers for smarter decision-making.
- **In-Game UI**: Full settings dialog for configuring mode, thresholds, and credentials.
- **Extended Monitoring**: Track additional resources, survivor health, morale, and relationships.
- **Daily Forecasting**: Predict shortages and recommend proactive adjustments.

---

## API Credential Storage (Prepared for Future Use)

While not functional in v1, you can store API credentials now for future use:

```lua
ModLina.Config.SetAPICredential("provider", "OpenAI")
ModLina.Config.SetAPICredential("key", "sk-your-key-here")
ModLina.Config.SetAPICredential("endpoint", "https://api.openai.com/v1")
ModLina.Config.SetAPICredential("model", "gpt-4")
```

**Note**: Avoid pasting sensitive keys in console during streaming or public gameplay.

---

## Mod Architecture

### Module Breakdown

- **main.lua**: Entry point; wires game event hooks (NewMapLoaded, NewHour, NewDay, etc.).
- **ModLina_Core.lua**: Namespace initialization, lifecycle management, mode dispatcher.
- **ModLina_Config.lua**: Settings persistence, defaults, validation, and getter/setter functions.
- **ModLina_Notifications.lua**: Notification system with anti-spam cooldowns and category toggles.
- **ModLina_Advisor.lua**: Mode A monitoring logic (stress, hunger, resources, stalled workbenches).
- **ModLina_SemiAuto.lua**: Mode B scaffold with extension points for future automation.
- **ModLina_FullAuto.lua**: Mode C scaffold with extension points for colony-wide automation.
- **ModLina_Settings.lua**: Settings UI placeholder and console command helpers.

### State Persistence

Mod state is stored in `CurrentModStorageTable.ModLina` (Stranded engine storage):
- Per-save overrides merge with global defaults at load time.
- Workbench tracking resets each game load (transient per session).
- Alert cooldowns reset each game load.

---

## Troubleshooting

### Lina Isn't Showing Alerts

1. **Verify Mode A is Active**:
   ```lua
   print(ModLina.Config.GetMode())  -- Should return "A"
   ```

2. **Check Alert Categories**:
   ```lua
   ModLina_GetSettings()  -- Review alert toggles
   ```

3. **Verify Thresholds**:
   ```lua
   print("Stress threshold:", ModLina.Config.GetThreshold("stress"))
   ```

4. **Enable Debug Logging**:
   ```lua
   ModLina.Config.SetDebugEnabled(true)
   ```

### Alerts Are Spamming

Reduce cooldown durations:
```lua
ModLina.Config.SetCooldown("survivor", 600)  -- 10 minutes
ModLina.Config.SetCooldown("resources", 1200) -- 20 minutes
```

Or temporarily disable categories:
```lua
ModLina.Config.SetAlertEnabled("survivors", false)
```

---

## Support & Feedback

For issues, feature requests, or feedback, please refer to the mod page documentation or the source repository.

---

## License & Credits

Mod_Lina is developed for Stranded: Alien Dawn community use. Follows established mod conventions from reference implementations in the SAD mod ecosystem.

---

## Changelog

### v1 (May 14, 2026)

- ✅ Advisor Mode fully implemented with stress, hunger, and resource monitoring.
- ✅ Stalled workbench detection (4-hour no-output rule).
- ✅ Per-alert-type cooldown system with category toggles.
- ✅ Persistent configuration (global defaults + per-save overrides).
- ✅ Multi-language localization scaffolding (English + 9 language stubs).
- ✅ Console commands for configuration.
- ✅ Mode B/C scaffolding ready for future development.
- ✅ Clean modular architecture following SAD mod patterns.
