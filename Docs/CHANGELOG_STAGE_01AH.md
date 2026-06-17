# PitBull Stage 01AH Changelog

## Summary
Hardened LuaTexts ScriptEnv GUID-keyed table lookups so Midnight protected GUIDs no longer throw when LuaTexts utility functions read AFK, DND, offline, dead, power, or cast caches.

## Files Changed
- Modules/LuaTexts/ScriptEnv.lua

## Changed
- Added a guarded table lookup helper for ScriptEnv runtime caches
- Routed AFK, DND, Offline, Dead, and CastData lookups through safe GUID conversion and guarded access
- Routed pet/player power-guid comparisons through safe GUID equality

## Testing Checklist
- Load into world
- /reload
- Target and clear target
- Verify LuaTexts no longer errors from ScriptEnv.lua
- Check AFK/DND/offline/dead style texts if used
- Check cast-related LuaTexts if used
