# DragonToast - Agent Guidelines

Project-specific guidelines for DragonToast. See the parent `../AGENTS.md` for general WoW addon rules.

---

## Build, Lint & Test

### Linting

Luacheck is the only static analysis tool. Config lives in `.luacheckrc` (Lua 5.1, 120 char lines, `Libs/` excluded).

```bash
# Lint entire addon
luacheck .

# Lint a single file (preferred during development)
luacheck Core/Init.lua

# CI-style (matches GitHub Actions workflow)
luacheck . --no-color
```

CI runs Luacheck via `nebularg/actions-luacheck@v1` on `pull_request_target` to `master`. All warnings must pass before merge.

### Testing

Busted tests run in CI. Run locally with `busted --verbose`.

### Packaging

No local build step. BigWigsMods packager runs automatically via `packager.yml` (dispatched by `release.yml`). Release flow: merge to `master` -> release-please PR -> merge that PR -> tag + GitHub Release -> release.yml dispatches packager.yml -> packager publishes to CurseForge, Wago, GitHub Releases.

---

## Architecture

| Layer     | Directory    | Responsibility                                         |
|-----------|--------------|--------------------------------------------------------|
| Core      | `Core/`      | Addon lifecycle, config, slash commands, minimap icon  |
| Listeners | `Listeners/` | Version-specific loot/XP/honor event parsing           |
| Display   | `Display/`   | Toast frames, animations, feed management, ElvUI skin  |
| Libs      | `Libs/`      | Embedded Ace3 + utility libraries (never lint or edit) |

### Namespace Sub-tables

All modules attach to `ns`: `ns.Addon`, `ns.ToastManager`, `ns.ToastFrame`, `ns.ToastAnimations`, `ns.ElvUISkin`, `ns.LootListener`, `ns.XPListener`, `ns.HonorListener`, `ns.MailListener`, `ns.MessageBridge`, `ns.ListenerUtils`, `ns.MinimapIcon`, `ns.Print`.

### Ace3 Stack (mandatory, no raw alternatives)

| Library            | Replaces                                 |
|--------------------|------------------------------------------|
| AceEvent           | `frame:RegisterEvent()`                  |
| AceTimer           | `C_Timer.After()` / `C_Timer.NewTimer()` |
| AceDB              | Raw `SavedVariables`                     |
| AceConsole         | `SLASH_*` globals                        |
| LibSharedMedia-3.0 | Hardcoded font/texture paths             |

### Version-Specific Loading

Three target versions: TBC Anniversary (20505, primary), MoP Classic (50503), and Retail (120001, secondary).

Version-specific files load via BigWigsMods packager comment directives in the TOC (`#@retail@` / `#@tbc-anniversary@` / `#@version-mists@`). Do NOT use `## Interface-*` mid-file directives. Locally, all listener files load; runtime guards in each version-specific listener ensure only the correct one initializes.

---

## Toast Lifecycle

1. Loot event -> `LootListener` / `XPListener` parses and calls `ToastManager.QueueToast(lootData)`
2. QueueToast -> Checks combat deferral and duplicate stacking, then calls `ShowToast()`
3. ShowToast -> `ToastFrame.Acquire()` gets frame from pool, `Populate()` fills it, `PlayLifecycle()` starts animation
4. PlayLifecycle -> Builds a `lib:Queue()`: entrance -> attention (optional, quality-gated) -> exit (with hold delay)
5. Queue completes -> `OnToastFinished()` -> `StopAll()` -> `Release()` returns frame to pool

Frames are recycled via `Acquire()` / `Release()`. `Release()` calls `ClearQueue()`, clears state fields, and has a pool duplication guard. Always call `StopAll()` before starting a new queue on an acquired frame.

---

## ElvUI Integration

When "Match ElvUI Style" is enabled: font face uses `E.media.normFont`, font size/outline respects user settings (not overridden), background is never overridden, border color uses `E.media.bordercolor` when quality border is off. `SkinToast()` runs after `PopulateToast()`.

---

## Cross-Addon Messaging API

### Generic Messages

| Message | Payload | Description |
|---------|---------|-------------|
| `DRAGONTOAST_SUPPRESS` | `source` (string) | Suppresses normal item toasts. Adds source to suppression set with a per-source 120s safety timer. |
| `DRAGONTOAST_UNSUPPRESS` | `source` (string) | Removes source from suppression set and cancels its safety timer. |
| `DRAGONTOAST_QUEUE_TOAST` | `toastData` (table) | Validates required fields and forwards to `ToastManager.QueueToast()`. |

### Toast Data Contract

Required fields:
- `itemName` (string) - display name
- `itemIcon` (number) - texture ID
- `itemQuality` (number) - Blizzard quality enum (0-7)

Optional fields (auto-filled if missing):
- `timestamp` (number) - defaults to `GetTime()` if omitted
- `itemLink` (string) - clickable item link
- `itemID` (number) - item ID for duplicate detection
- `itemLevel` (number) - item level
- `itemType` (string) - item type / subheading text
- `itemSubType` (string) - item sub-type
- `quantity` (number) - stack count
- `looter` (string) - name of the looter
- `isSelf` (boolean) - whether the looter is the local player
- `isCurrency` (boolean) - currency flag (bypasses suppression)
- `isRollWin` (boolean) - roll-win flag (bypasses suppression)
- `isXP` (boolean) - XP flag (bypasses suppression, enables XP stacking)
- `isHonor` (boolean) - honor flag (bypasses suppression, enables honor stacking)

### Suppression Mechanism

Suppression uses a multi-source set. Each source string maps to its own 120-second safety timer. Toasts are suppressed when any source is active (`next(suppressionSources) ~= nil`). Normal item toasts are blocked; XP, honor, currency, and roll-win toasts always pass through.

The safety timer auto-clears a source if the matching UNSUPPRESS message never arrives (e.g. crash or reload).

### Legacy Messages (backward compat)

| Legacy Message | Translates To |
|----------------|---------------|
| `DRAGONLOOT_LOOT_OPENED` | `DRAGONTOAST_SUPPRESS` with source `"DragonLoot"` |
| `DRAGONLOOT_LOOT_CLOSED` | `DRAGONTOAST_UNSUPPRESS` with source `"DragonLoot"` |
| `DRAGONLOOT_ROLL_WON` | `DRAGONTOAST_QUEUE_TOAST` (transforms rollData to lootData) |

These will be removed when all senders migrate to the generic API.

---

## CI/CD

| Workflow         | Trigger                         | Purpose                                                          |
|------------------|---------------------------------|------------------------------------------------------------------|
| `lint.yml`       | `pull_request_target` to master | Luacheck + busted tests via `Xerrion/wow-workflows` reusable workflow |
| `release.yml`    | `push` to master                | release-please PR via `Xerrion/wow-workflows`; dispatches `packager.yml` on release |
| `packager.yml`   | `workflow_dispatch` (from release.yml) | BigWigsMods packager via `Xerrion/wow-workflows` reusable workflow |
| `toc-update.yml` | Weekly schedule / manual        | Auto-bump TOC Interface versions via `Xerrion/wow-workflows` reusable workflow |

Branch protection on `master`: PRs required, Luacheck status check required, branches must be up to date, no force pushes. Squash merge only; auto-delete head branches.

---

## Known Gotchas

1. **GetItemInfo caching** - Returns nil on first call for uncached items. Use retry pattern.
2. **Localized loot patterns** - `CHAT_MSG_LOOT` strings are locale-dependent. Build patterns from Blizzard globals.
3. **AceTimer cleanup** - Cancel timers before nullifying references, or closures fire on recycled frames.
4. **ElvUI skin ordering** - `SkinToast()` must respect user Appearance settings, not override them.
5. **TOC conditional loading** - Use packager comment directives, not `## Interface:` mid-file.
6. **pull_request_target** - GitHub does not trigger `pull_request` for PRs from GITHUB_TOKEN. Use `pull_request_target`.
