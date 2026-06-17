# PitBull Stage 01AD Changelog

## Summary
Patched the new load-error wave after the temporary Ace3 update by removing remaining protected GUID/string compares and replacing GUID-keyed throttles with unit-keyed throttles in PitBull-owned modules.

## Files Changed
- Main.lua
- Utils.lua
- UnitFrame.lua
- Modules/Highlight/Highlight.lua
- Modules/PowerBar/PowerBar.lua
- Modules/Aura/Update.lua
- Modules/HealthBar/HealthBar.lua
- Modules/LuaTexts/LuaTexts.lua

## Fixed
- Removed secret-string compares from Main and Utils helper paths
- Replaced Highlight target GUID comparison with guarded UnitIsUnit-based matching
- Replaced PowerBar, Aura, and HealthBar throttled GUID queues with unit-token queues
- Removed LuaTexts UNIT_SPELLCAST_SENT target empty-string compare
- Removed UnitFrame OnShow GUID compare and always refresh GUID on show

## Notes
- No third-party libraries were changed in this stage
- This stage targets the five load errors reported after the Ace3 update
