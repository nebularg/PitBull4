# PitBull Stage 01S Changelog

## Summary
Restored HealthBar rendering on Midnight by preferring Blizzard's health percent API before falling back to raw health arithmetic.

## Goals
- Keep the addon loadable and functional
- Restore visible health bars
- Avoid Midnight secret-number faults in health normalization

## Files Changed
- Modules/HealthBar/HealthBar.lua

## Fixed
- Health bars disappearing because `GetValue()` could return nil after protected health math failed
- Midnight health normalization now prefers `UnitHealthPercent()` when available

## Compatibility Notes
- Mainline/Midnight: prefers `UnitHealthPercent(unit)`
- Older clients: falls back to `UnitHealth(unit) / UnitHealthMax(unit)`

## Testing Checklist
- Login
- Reload UI
- Player health bar visible
- Target health bar visible
- Party or raid health bars visible
- No new HealthBar Lua errors

## Feedback Requested
- Whether the player and target health bars are visible again
- Whether any health bar now appears stuck at empty or full
- Any new stack traces tied to HealthBar
