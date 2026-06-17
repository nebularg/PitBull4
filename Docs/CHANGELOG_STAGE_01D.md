# PitBull Stage 01D Changelog

## Summary
Added Midnight startup gating for restricted unit data so PitBull does not read protected health and power numbers during the addon's activation window.

## Goals
- Keep Stage 01 functional
- Stop Midnight startup errors from health, power, and combat fader modules
- Avoid risky behavior rewrites

## Files Changed
- Main.lua
- Modules/PowerBar/PowerBar.lua
- Modules/HealthBar/HealthBar.lua
- Modules/CombatFader/CombatFader.lua

## Added
- Restricted-state tracking for Midnight startup
- Optional handling for ADDON_RESTRICTION_STATE_CHANGED

## Changed
- HealthBar and PowerBar now avoid live unit math while addon restriction state is pending
- CombatFader now treats restricted startup state as fully visible instead of reading live player health or power

## Fixed
- Midnight startup secret-number errors in PowerBar
- Midnight startup secret-number errors in HealthBar
- Midnight startup secret-number errors in CombatFader

## Compatibility Notes
- Retail/Midnight: uses guarded restriction-state handling when the API/event is available
- Classic-family clients: unchanged behavior

## Testing Checklist
- Login with PitBull enabled
- Reload UI
- Open options
- Toggle config mode
- Verify player and target bars appear after startup settles
- Verify CombatFader does not throw startup errors

## Feedback Requested
- Any remaining startup stack traces mentioning secret numbers
- Whether bars appear normally after login/reload
- Whether CombatFader stays stuck after login
