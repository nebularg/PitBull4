# PitBull4 Stage 01Q Changelog

## Summary
Patched CombatText so it no longer compares live FontString text against the preview example string during frame updates on Midnight.

## Files Changed
- Modules/CombatText/CombatText.lua
- Docs/CHANGELOG_STAGE_01Q.md
- Docs/GIT_CHANGELOG_STAGE_01Q.txt

## Fixed
- Removed direct string comparison against `font_string:GetText()` in CombatText update flow.
- Replaced preview text cleanup with an internal `is_example_text` flag.

## Why
Midnight can mark live font string contents as protected/secret values. Comparing `font_string:GetText()` against a plain Lua string can fault during layout refreshes.

## Testing Checklist
- Login
- `/reload`
- Player and target frames load
- CombatText updates during combat
- Layout/profile changes do not throw CombatText errors
- CastBar-triggered layout refresh no longer throws the CombatText secret-string error

## Feedback Requested
- Any remaining CombatText stack traces
- Any missing combat text display after this hotfix
