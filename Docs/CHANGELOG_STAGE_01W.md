# PitBull Stage 01W Changelog

## Summary
Adjusted HealthBar normalization again so Midnight does not compare protected health max values during bar updates.

## Goals
- Keep the addon loadable
- Restore visible health bars
- Remove the remaining raw comparison against protected health maximum values

## Files Changed
- Modules/HealthBar/HealthBar.lua
- Docs/CHANGELOG_STAGE_01W.md
- Docs/GIT_CHANGELOG_STAGE_01W.txt

## Changed
- Reworked the health value path to prefer fully guarded normalization blocks
- Removed the raw `max <= 0` comparison that faulted on Midnight protected values
- Fallback now returns the example value instead of a missing bar value

## Compatibility Notes
- Midnight/Mainline: health normalization avoids direct comparison against protected health max values
- Older clients: legacy UnitHealth and UnitHealthMax ratio path remains available

## Testing Checklist
- Addon loads at login
- Reload UI works
- Player health bar is visible
- Target health bar is visible
- Health bars still update after damage and healing

## Feedback Requested
- Whether the health bar is visible again
- Whether it updates correctly or stays stuck
- Any new HealthBar stack traces
