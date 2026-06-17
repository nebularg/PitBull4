# PitBull4 Stage 01E Changelog

## Summary
Tightened Midnight startup handling by preventing live health and power math during config mode, and by deferring CombatFader live player-value checks until the world-entry path is established.

## Goals
- Keep Stage 01 functional and testable
- Eliminate remaining Midnight secret-number startup errors
- Avoid live bar math while config mode is rebuilding frames
- Delay CombatFader live player checks until the world is ready

## Files Changed
- Main.lua
- Modules/PowerBar/PowerBar.lua
- Modules/HealthBar/HealthBar.lua
- Modules/CombatFader/CombatFader.lua

## Changed
- HealthBar now always returns example values while PitBull config mode is active
- PowerBar now always returns example values while PitBull config mode is active
- HealthBar and PowerBar example colors are used for all config-mode updates
- CombatFader now skips live player health/power comparisons until PLAYER_ENTERING_WORLD has established the world-ready state
- Main startup now tracks a world-ready flag and refreshes restriction state again on PLAYER_ENTERING_WORLD

## Compatibility Notes
- Midnight: avoids secret-number faults during config rebuild and early startup
- Older clients: behavior remains equivalent because config mode already expects preview-safe values

## Testing Checklist
- Login with PitBull enabled
- /reload
- Open options
- Toggle config mode on and off
- Verify player and target health/power bars appear after world entry
- Verify CombatFader does not error on startup

## Feedback Requested
- Any remaining secret-number stack traces
- Bars missing after login or reload
- CombatFader staying stuck at the wrong opacity after world entry
