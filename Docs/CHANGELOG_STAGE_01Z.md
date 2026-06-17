# PitBull Stage 01Z Changelog

## Summary
Refined HealthBar Midnight handling to avoid doing arithmetic directly on protected health values.

## Goals
- Keep the addon loadable and functional
- Preserve visible health bars
- Convert protected health values into plain numeric values before normalization

## Files Changed
- Modules/HealthBar/HealthBar.lua
- Docs/CHANGELOG_STAGE_01Z.md
- Docs/GIT_CHANGELOG_STAGE_01Z.txt

## Changed
- Reworked HealthBar value normalization to fetch raw values first
- Added safe numeric conversion helper for protected health values
- Added normalized clamping helper for bar values

## Fixed
- Removed direct arithmetic on protected UnitHealthPercent values
- Removed direct arithmetic on protected UnitHealth values in the ratio path
- Reduced startup/profile-update faults in HealthBar during Midnight client rebuilds

## Compatibility Notes
- Mainline/Midnight: prefers safe numeric conversion from live health values before normalization
- Older clients: still uses the same UnitHealthPercent or UnitHealth/UnitHealthMax sources when available

## Testing Checklist
- Addon loads
- Reload UI works
- Player health bar appears
- Target health bar appears
- Bars update when taking damage or healing
- No new HealthBar Lua errors during profile/config rebuilds

## Feedback Requested
- Whether the player health bar appears
- Whether the target health bar appears
- Whether the bar updates accurately after damage/healing
- Any new HealthBar stack traces
