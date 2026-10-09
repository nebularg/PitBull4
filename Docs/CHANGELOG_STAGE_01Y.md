# PitBull Stage 01Y Changelog

## Summary
Fixed a Lua syntax error introduced in `HealthBar.lua` that prevented the addon from loading.

## Files Changed
- `Modules/HealthBar/HealthBar.lua`
- `Docs/CHANGELOG_STAGE_01Y.md`
- `Docs/GIT_CHANGELOG_STAGE_01Y.txt`

## Fixed
- Removed an accidentally duplicated anonymous `function(info)` block in the health bar color options section.
- Restored valid Lua syntax for the health bar color defaults callback.

## Testing Checklist
- Addon loads without Lua syntax errors
- `/reload` works
- PitBull options open
- HealthBar module loads

## Feedback Requested
- Whether the addon now loads cleanly
- Whether the health bar is visible and updating
