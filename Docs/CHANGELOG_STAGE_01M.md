# PitBull Stage 01M Changelog

## Summary
Hardened one remaining Aura update path and one CastBar startup path for Midnight secret-value handling.

## Goals
- Keep addon loadable and testable
- Remove the Aura nil-compare spam
- Remove the CastBar temp-icon compare fault
- Preserve visible behavior where possible

## Files Changed
- Modules/Aura/Update.lua
- Modules/CastBar/CastBar.lua

## Fixed
- Aura count text now uses sanitized numeric application, duration, and expiration values before comparison and cooldown setup
- CastBar temp icon detection no longer compares raw protected icon values directly
- CastBar start and end times now use safe millisecond-to-second conversion

## Compatibility Notes
- Midnight: avoids comparing protected icon and aura numeric values directly in these paths
- Other clients: behavior should remain unchanged

## Testing Checklist
- Login and /reload
- Player and target aura display
- Aura cooldown swirls and stack counts
- Player cast bar starts correctly
- Nameplate cast events do not throw Lua errors

## Feedback Requested
- Any remaining Aura Lua spam
- Any missing aura cooldowns or stack text
- Any cast bar start/update regressions

## Known Issues Outside PitBull
- The EMA LibAuras error in your report is coming from `EMA/Libs/LibAuras/LibAuras.lua`, not PitBull. That needs a separate EMA-side patch.
