# PitBull4 Stage 01J Changelog

## Summary
Hardened the Aura pipeline against Midnight secret-string and secret-boolean faults, and reduced CastBarLatency's direct dependence on protected GCD duration values on Mainline.

## Goals
- Keep the addon loadable and testable
- Stop repeated Aura update spam caused by secret aura fields
- Stop CastBarLatency startup/update errors from protected GCD duration comparisons
- Preserve existing behavior where safe data is available

## Files Changed
- Modules/Aura/Update.lua
- Modules/Aura/Highlight.lua
- Modules/Aura/FilterTypes.lua
- Modules/CastBarLatency/CastBarLatency.lua

## Added
- Safe dispel-type normalization against a whitelist of known aura types
- Safe derived aura ownership helper based on player-origin flags
- Safe GCD helper for CastBarLatency

## Changed
- Aura sorting now uses a derived "mine" flag instead of indexing tables with raw sourceUnit values
- Aura border/highlight color selection now uses normalized dispel keys
- Aura state comparison now tracks caster ownership as a boolean instead of comparing raw sourceUnit strings
- CastBarLatency now suppresses risky GCD-duration logic on Mainline/Midnight

## Fixed
- Secret-string compare faults on aura `dispelName`
- Secret-string table index faults on aura `sourceUnit`
- Repeated Aura update spam from highlight/sort paths
- CastBarLatency secret-number compare faults on cooldown duration

## Compatibility Notes
- Mainline/Midnight: prioritizes safe aura metadata over full fidelity when protected fields are unsafe
- Classic-family clients keep the legacy behavior paths already present in the addon
- CastBarLatency queue handling remains active; only risky GCD-derived sizing is suppressed on Mainline

## Testing Checklist
- Login and reload without Aura spam
- Player and target buffs/debuffs display
- Aura highlight enabled without repeated Lua errors
- Sorting still behaves reasonably on buffs/debuffs
- CastBarLatency no longer errors on player cast start
- Config mode still works

## Feedback Requested
- Any remaining Aura stack traces, especially from:
  - Update.lua
  - Highlight.lua
  - Filter.lua
  - FilterTypes.lua
- Whether CastBarLatency still errors on player casts
- Any visible regression in aura ordering, border color, or highlight behavior

## Known Risks
- User-defined Aura filters that depend on exact non-player source units may now behave more conservatively on Mainline
- Mainline CastBarLatency GCD sizing is intentionally reduced until a safer data path is implemented
