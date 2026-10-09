# PitBull Stage 01AK Changelog

## Summary
Patched the remaining LuaTexts cast cache key path and tightened live bar update/value handling for HealthBar, PowerBar, and Alternate Mana Bar. This stage is an overlay hotfix and does not modify external libraries.

## Files Changed
- Modules/LuaTexts/LuaTexts.lua
- Modules/LuaTexts/ScriptEnv.lua
- Modules/PowerBar/PowerBar.lua
- Modules/HealthBar/HealthBar.lua
- Modules/AltManaBar/AltManaBar.lua

## Fixed
- Removed the remaining GUID-keyed cast cache path in LuaTexts and switched cast data to unit-token keys
- Updated ScriptEnv CastData lookups to use unit-token keys
- Added direct combat update calls for HealthBar and PowerBar on unit events
- Added more reliable live numeric conversion for PowerBar and Alternate Mana Bar
- Used best_unit when available for live bar value reads so wacky/unit-swapped frames resolve the correct live unit

## Testing Checklist
- Load into world
- /reload
- Verify power/mana bar appears
- Verify health and power bars update during combat
- Verify LuaTexts no longer throws the cast-data table index error

## Notes
- This is a PitBull-only overlay patch
- No Ace libraries were modified
