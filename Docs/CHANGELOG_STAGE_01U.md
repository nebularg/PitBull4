# PitBull Stage 01U Changelog

## Summary
Adjusted HealthBar normalization again for Midnight so protected health percentages no longer trigger direct comparisons, and the bar remains visible instead of disappearing.

## Files Changed
- Modules/HealthBar/HealthBar.lua
- Docs/CHANGELOG_STAGE_01U.md
- Docs/GIT_CHANGELOG_STAGE_01U.txt

## Changed
- Removed direct comparisons against protected `UnitHealthPercent` values.
- Converted health percent through `tonumber` first, then normalized it in a guarded path.
- Added a visible fallback return path when Midnight still refuses to yield a plain health value.
- Kept classic and older-client health math fallback intact.

## Fixed
- `HealthBar.lua:71` protected percent compare fault.
- Health bar disappearing when health normalization returned `nil`.

## Testing Checklist
- Login
- `/reload`
- Player health bar visible
- Target health bar visible
- Health bars update after taking damage or healing
- No new `HealthBar.lua` secret-number error on load

## Feedback Requested
- Whether player health is visible now
- Whether target health is visible now
- Whether bars update correctly or stay pinned full
