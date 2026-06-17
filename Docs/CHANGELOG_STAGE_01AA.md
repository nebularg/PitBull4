# PitBull Stage 01AA Changelog

## Summary
Hardened HealthBar numeric conversion so protected Midnight health values are converted through strings before any normalization math.

## Files Changed
- Modules/HealthBar/HealthBar.lua

## Fixed
- Removed the last direct numeric passthrough that allowed protected health values to reach arithmetic paths.
- Changed health conversion to use guarded `tostring` plus `tonumber` instead of returning numeric values directly.

## Testing Checklist
- Addon loads
- `/reload` works
- Player health bar appears
- Target health bar appears
- Health bars update when taking damage or healing
- No new `HealthBar.lua` errors during config/profile rebuilds
