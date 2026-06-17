# PitBull Stage 01AJ Changelog

## Summary
Patched two remaining PitBull-only Midnight faults: LeaderIcon protected GUID comparison and CastBarLatency protected boolean tests.

## Files Changed
- Modules/LeaderIcon/LeaderIcon.lua
- Modules/CastBarLatency/CastBarLatency.lua

## Fixed
- Replaced LeaderIcon GUID comparison with direct group-leader unit checks
- Replaced CastBarLatency UnitIsUnit boolean tests with token-based player frame detection

## Testing Checklist
- Load into world
- Trigger group leader changes
- Check leader icon on party frames and targets
- Cast on player and verify CastBarLatency still appears only on player frames
- Confirm no new LeaderIcon or CastBarLatency errors
