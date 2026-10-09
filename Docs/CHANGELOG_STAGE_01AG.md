# PitBull4 Stage 01AG Changelog

## Summary
Patched ReadyCheckIcon to stop using GUID-keyed ready-check status caches on Midnight and newer clients.

## Files Changed
- Modules/ReadyCheckIcon/ReadyCheckIcon.lua

## Changed
- Replaced GUID-keyed ready-check status cache with unit-token keyed cache.
- Added guarded unit matching for frames that represent group members through target or best_unit.
- Removed direct ready-check texture lookup by frame GUID.

## Fixed
- ReadyCheckIcon.lua:34 table index is secret

## Compatibility Notes
- Works without touching third-party libraries.
- Preserves Classic and Retail behavior by using GetReadyCheckStatus and UnitIsUnit only.

## Testing Checklist
- Load into world
- Join party or follower dungeon
- Trigger ready check
- Confirm ready check icons appear on player/party frames
- Confirm no ReadyCheckIcon secret table-index errors
