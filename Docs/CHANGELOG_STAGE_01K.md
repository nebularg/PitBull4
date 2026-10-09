# PitBull Stage 01K Changelog

## Summary
Hardens Aura sorting against Midnight secret aura-name strings and fixes a LuaTexts cast-data cleanup bug that was calling `wipe` on the global `date` function instead of the cast-data table.

## Goals
- Keep addon loadable and functional
- Stop Aura sort spam caused by secret-name comparisons
- Fix LuaTexts cleanup regression without changing visible behavior

## Files Changed
- Modules/Aura/Update.lua
- Modules/LuaTexts/LuaTexts.lua
- Docs/CHANGELOG_STAGE_01K.md
- Docs/GIT_CHANGELOG_STAGE_01K.txt

## Changed
- Removed Aura name-based sort comparison from the live sort path
- Uses numeric stable keys for Aura sorting instead
- Hardened LuaTexts pooled-table cleanup helper

## Fixed
- Midnight secret-string fault from comparing `a.name < b.name` in Aura sorting
- LuaTexts typo `del(date)` causing `wipe` on a function instead of a table

## Compatibility Notes
- Midnight/Mainline: avoids secret aura-name string comparisons in sort logic
- Older clients: stable numeric aura ordering remains deterministic
- No intended visual behavior change outside stopping the faults

## Testing Checklist
- Login and `/reload`
- Buff and debuff display on player/target
- Aura sorting no longer spams errors
- LuaTexts no longer throws `wipe` type errors
- Cast-related LuaTexts still update normally

## Feedback Requested
- Any remaining Aura secret-string or secret-boolean stacks
- Any LuaTexts cast-text regressions
- Any odd aura reordering that looks visibly wrong
