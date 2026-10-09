# PitBull4 Stage 01R Changelog

## Summary
Reworked Aura tooltip refresh matching so Midnight no longer compares live aura names during OnUpdate.

## Goals
- Keep the addon fully loadable
- Preserve Aura tooltip behavior
- Remove remaining name-based Aura control comparisons that fault on Midnight secret strings

## Files Changed
- Modules/Aura/Controls.lua
- Modules/Aura/Update.lua
- Docs/CHANGELOG_STAGE_01R.md
- Docs/GIT_CHANGELOG_STAGE_01R.txt

## Changed
- Aura tooltip refresh now matches cached auras by aura instance ID first
- Aura tooltip refresh falls back to spell ID matching instead of aura name matching
- Aura controls now cache aura instance IDs during the update pass

## Fixed
- Removed secret-string comparisons against `auraData.name` in Aura control OnUpdate
- Prevented repeated tooltip refresh errors when hovering auras on Midnight

## Compatibility Notes
- Retail and Midnight use aura instance ID matching when available
- Fallback matching uses spell ID instead of aura names
- No intentional visible UI changes outside safer tooltip refresh behavior

## Testing Checklist
- Login and reload UI
- Hover player buffs and debuffs
- Hover target buffs and debuffs
- Confirm tooltips still appear and track the correct aura closely enough
- Confirm the Aura Controls secret-string error is gone

## Feedback Requested
- Any remaining Aura `Controls.lua` errors
- Tooltip mismatches on duplicate auras
- Missing aura tooltips
