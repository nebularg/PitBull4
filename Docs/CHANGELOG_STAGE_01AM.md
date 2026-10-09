# PitBull4 Stage 01AM Changelog

## Summary
Harden LuaTexts cast-to-frame matching against Midnight protected UnitIsUnit results.

## Files Changed
- Modules/LuaTexts/LuaTexts.lua

## Fixed
- Removed the remaining UnitIsUnit-based boolean test in the LuaTexts cast fan-out path.
- Prevented `LuaTexts.lua:1046` secret-boolean faults during frame updates.

## Notes
- This is a PitBull-only overlay hotfix.
- Ace libraries are untouched.
