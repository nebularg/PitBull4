# PitBull Stage 01AL Changelog

## Summary
Patched the remaining PitBull-owned secret-value faults in LeaderIcon and CastBarLatency without touching external libraries.

## Files Changed
- Modules/LeaderIcon/LeaderIcon.lua
- Modules/CastBarLatency/CastBarLatency.lua

## Changed
- Replaced LeaderIcon GUID comparison with unit-token leader detection.
- Replaced CastBarLatency UnitIsUnit boolean tests with token-based player-frame detection.

## Fixed
- Secret GUID compare in LeaderIcon on target and party frames.
- Secret boolean tests in CastBarLatency for non-player frames such as targettarget.

## Testing Checklist
- Load into world
- /reload
- Join a party or follower dungeon
- Verify leader icon appears correctly
- Verify cast bar latency only appears on the player frame
- Verify no Lua errors from LeaderIcon or CastBarLatency
