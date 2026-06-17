# PitBull Stage 01T Changelog

## Summary
Restored the HealthBar live-value path by moving health normalization into a secure call on Midnight.

## Files Changed
- Modules/HealthBar/HealthBar.lua

## Changed
- Reworked HealthBar value normalization to run inside `securecallfunction` before returning a normalized value to the shared bar updater.
- Kept the legacy UnitHealth/UnitHealthMax fallback for older clients.

## Why
The earlier pcall-based protection could suppress errors but still return `nil`, which caused the shared bar updater to clear the HealthBar entirely.

## Testing Checklist
- Login
- /reload
- Player health bar visible
- Target health bar visible
- Party or raid health bars visible
- Health updates when taking damage/healing
