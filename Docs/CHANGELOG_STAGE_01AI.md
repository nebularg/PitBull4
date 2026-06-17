# PitBull Stage 01AI Changelog

## Summary
Hardens the remaining LuaTexts event-update GUID comparisons and the shared SafeBoolean helper against Midnight protected values.

## Files Changed
- Utils.lua
- Modules/LuaTexts/LuaTexts.lua

## Fixed
- Replaced direct GUID equality checks in LuaTexts event fan-out with guarded equality.
- Replaced direct string comparisons inside SafeBoolean with guarded equality.

## Testing Checklist
- Addon loads
- /reload works
- PLAYER_FLAGS_CHANGED no longer throws in LuaTexts
- Lua texts continue updating on target and player frames
