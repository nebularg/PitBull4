# PitBull4 Stage 01AF Changelog

## Summary
This hotfix targets the post-Ace-update PitBull-owned load errors without modifying any third-party libraries.

## Goals
- Keep the user's updated Ace libraries untouched
- Remove remaining protected GUID/string compare faults in PitBull core paths
- Remove CastBar cache indexing by protected GUIDs
- Keep the addon loadable and testable as a functional stage

## Files Changed
- Main.lua
- Utils.lua
- UnitFrame.lua
- Modules/CastBar/CastBar.lua

## Changed
- Hardened local SafeGUID in Main.lua to stop doing protected-string validation checks
- Added safe equality and safe table access helpers in Main.lua
- Wrapped GUID equality and GUID-keyed map access in PitBull core through guarded helpers
- Hardened PitBull4.Utils.SafeString and SafeBoolean to avoid secret-string and secret-boolean fault paths
- Updated UnitFrame GUID comparisons to use guarded equality
- Switched CastBar runtime cache lookups from GUID keys to unit-token keys
- Added wacky-frame target-chain handling for CastBar cache keys

## Fixed
- Main.lua refresh_guid compare and GUID table-index faults
- UnitFrame UpdateGUID protected GUID compare faults
- CastBar GetValue and UpdateInfo protected GUID table-index faults
- Shared helper faults coming from PitBull's own SafeString / SafeGUID-style paths

## Compatibility Notes
- Does not modify Ace libraries or any third-party libs
- Intended as an overlay patch on top of the user's current addon folder and updated Ace libs

## Testing Checklist
- Addon loads cleanly
- /reload works
- Targeting and clearing target work
- Target frame shows
- CastBar updates for target and player
- No new Main.lua / UnitFrame.lua / CastBar.lua secret GUID or secret string errors on load

## Feedback Requested
- Any remaining PitBull-owned stacks only
- Whether targeting and clearing target are now clean
- Whether target cast bars still function after the unit-keyed cache change
