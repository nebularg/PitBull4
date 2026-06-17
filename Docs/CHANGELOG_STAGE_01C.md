# PitBull Stage 01C Changelog

## Summary
Move Midnight-sensitive health and power math behind safe wrappers so PitBull no longer performs direct arithmetic or comparisons on live secret numeric values during startup.

## Goals
- Keep the addon loadable
- Fix the remaining Midnight secret-number startup errors
- Preserve visible behavior of health, power, and combat fading
- Avoid broad module churn in this hotfix

## Files Changed
- Modules/PowerBar/PowerBar.lua
- Modules/HealthBar/HealthBar.lua
- Modules/CombatFader/CombatFader.lua

## Changed
- Wrapped power value normalization in a safe helper before returning the final bar value
- Wrapped health value normalization in a safe helper before returning the final bar value
- Wrapped CombatFader health and power state checks in safe helpers
- Wrapped PowerBar power-type reads used for color selection

## Fixed
- Midnight startup error in PowerBar when dividing secret power values
- Midnight startup error in HealthBar when comparing or dividing secret health values
- Midnight startup error in CombatFader when comparing secret health or power values

## Compatibility Notes
- Midnight/Mainline: prefers secure wrappers when available
- Older clients: falls back to the original direct API behavior
- No intended layout or profile behavior changes in this hotfix

## Testing Checklist
- Login with PitBull enabled
- Reload UI
- Open options
- Verify player and target health bars update
- Verify player power bar updates
- Verify CombatFader no longer throws startup errors

## Feedback Requested
- Any remaining secret value errors
- Any missing health or power bars
- Any combat fade state that now looks wrong
