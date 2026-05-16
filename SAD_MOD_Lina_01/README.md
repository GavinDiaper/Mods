# Mod_Lina – Survivor Assistant v1

A three-tier AI-powered colony management assistant for **Stranded: Alien Dawn**.

## Overview

Mod_Lina provides real-time monitoring and decision support for your colony operations, with future integration for external AI APIs (OpenAI, Azure OpenAI, Claude, etc.).

### Current Version (v1)

**Mode A (Advisor)** is fully implemented and operational. Modes B and C are scaffolded and ready for future expansion.

---

## Features – v1 Release

### Mode A: Advisor (Fully Implemented)

#### Advisor Cadence & Alerts

- **Survivor Stress**: Alerts when a survivor's composite stress score exceeds your configured threshold (default: 60).
- **Survivor Hunger**: Alerts when a survivor's food level falls below your threshold (default: 20).
- **Resource Reserves**: Alerts when Cloth reserves drop below your threshold (default: 20).
- **Stalled Production**: Detects workbenches with queued tasks but no output for 4+ hours.
- **Advisor Evaluation Rate**: Lina evaluates alert conditions once per in-game hour.
- **HUD Refresh Rate**: Lina's HUD refreshes every 2 seconds in real time.
- **Expanded Live HUD**: The HUD now shows top at-risk survivors and live per-survivor vitals in verbose/rollover views.

#### Smart Notifications

- Per-alert-type cooldown prevents spam (customizable).
- Category-based toggles let you enable/disable survivor, resource, or production alerts.
- All notifications branded as "Mod_Lina – Survivor Assistant".

#### Persistent Configuration

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

### AI Secrets Setup

To use cloud AI calls, create a local secrets file named `ai.secrets.lua` in the mod root.

- Required file: `SAD_MOD_Lina_01/ai.secrets.lua`
- Included template/example: `SAD_MOD_Lina_01/ai.secrets.example.lua`
- The live secrets file is ignored by git and should never be committed.

Example structure:

```lua
return {
   provider = "AzureOpenAI",
   endpoint = "https://your-resource.cognitiveservices.azure.com/",
   deployment = "gpt-5-mini",
   model = "gpt-5-mini",
   api_version = "2024-04-01-preview",
   key = "<your-api-key>",
}
```

If the secrets file is missing or invalid, Lina falls back to local safe behavior and will append `(AINA)` to affected messages.

### First Run

When you load a map, Lina will display:

```text
Mod_Lina – Survivor Assistant
Lina online. Monitoring survivor wellbeing and colony status.
```

Hourly alerts will begin automatically based on your configured thresholds, while the HUD refreshes every 2 seconds for near-real-time status updates.

### Stress Formula

Lina now evaluates stress as a weighted composite score rather than a single relaxation check.

The implementation first converts each survivor condition into a normalized risk value from `0` to `100`, where larger values mean more stress pressure. It then applies the weighted sum below:

```text
StressScore = clamp(
   DistressRisk * 0.30 +
   HungerRisk   * 0.23 +
   FatigueRisk  * 0.17 +
   HealthRisk   * 0.15 +
   BleedRisk    * 0.10 +
   TempRisk     * 0.05 +
   EquipRisk    * 0.00 +
   Modifiers,
   0,
   100
)
```

Expanded summation logic:

```text
BaseStress =
   (DistressRisk * 0.30) +
   (HungerRisk   * 0.23) +
   (FatigueRisk  * 0.17) +
   (HealthRisk   * 0.15) +
   (BleedRisk    * 0.10) +
   (TempRisk     * 0.05) +
   (EquipRisk    * 0.00)

StressScore = clamp(BaseStress + Modifiers, 0, 100)
```

Current weights:

- `0.30` Distress: the largest contributor, based on low relaxation and low mood.
- `0.23` Hunger: strong pressure from low available food/energy.
- `0.17` Fatigue: pressure from low rest reserve.
- `0.15` Health: direct penalty from injury or poor health.
- `0.10` Bleeding: additional pressure from active bleeding.
- `0.05` Temperature: minor pressure from hot/cold discomfort.
- `0.00` Equipment: reserved for future use; collected safely but not currently counted.

Component details:

- `DistressRisk = 0.6 * (100 - RelaxationPct) + 0.4 * (100 - MoodPct)`
- `HungerRisk = 100 - FoodPct`
- `FatigueRisk = 100 - RestPct`
- `HealthRisk = 100 - HealthPct`
- `BleedRisk = clamp(BleedingNormalized * 100, 0, 100)`
- `TempRisk = clamp(abs(TemperaturePerception) * 125, 0, 100)`
- `EquipRisk = 100 - EquipmentConditionPct` (currently collected with safe fallback, but weighted at `0.00`)

Applied modifiers:

- Sleeping survivors receive `-5` stress.
- Survivors with meaningful bleeding receive `+5` stress.

In practical terms, this means Lina is evaluating stress as a single capped score composed of:

```text
30% distress + 23% hunger + 17% fatigue + 15% health + 10% bleeding + 5% temperature + modifiers
```

The configured `stress` threshold still uses the same `0-100` range, but it now compares against this composite score.

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
ModLina_SetThreshold("stress", 75)    -- Composite stress alert threshold (0-100)
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

Alert cadence and backoff behavior:

- Advisor checks run once per in-game hour, so notification conditions are not evaluated continuously.
- Survivor cooldowns are tracked per survivor and per alert type, so the same survivor can trigger `stress` and `hunger` separately.
- Resource cooldowns use a single global bucket, so repeated cloth shortages intentionally notify less often.
- Production cooldowns are tracked per workbench.
- HUD updates are separate from alert checks and refresh every 2 seconds, even when no new notifications are shown.

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

For day-to-day use, prefer the local `ai.secrets.lua` file over console entry.

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
