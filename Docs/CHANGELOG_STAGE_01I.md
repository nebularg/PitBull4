# PitBull Stage 01I Changelog

## Summary
Hardened the Aura pipeline against Midnight secret-value faults by sanitizing aura-entry fields before use and adding error boundaries around compiled aura filters and highlight filters.

## Goals
- Keep addon loadable and testable
- Preserve Aura rendering as much as possible
- Stop repeated secret boolean and secret string faults in Aura update loops
- Keep changes narrow to the Aura subsystem only

## Files Changed
- Modules/Aura/Update.lua
- Modules/Aura/Highlight.lua
- Modules/Aura/Filter.lua
- Modules/Aura/FilterTypes.lua

## Added
- Safe boolean, number, and string coercion helpers for aura-entry fields
- Aura-entry normalization before highlight and filter evaluation
- Error-safe filter execution for display and highlight filter paths

## Changed
- Aura update now normalizes retail aura-entry values before comparing or filtering them
- Aura highlight now sanitizes dispel type reads and ignores filter execution faults instead of throwing
- Aura display filtering now falls back safely if a compiled or custom filter faults on a secret value
- Several built-in aura filter types now use safe field coercion for dispel, source, and boolean aura flags

## Fixed
- Secret string comparison on `entry.dispelName`
- Secret boolean tests inside compiled aura highlight filters
- Repeated Aura update-loop errors caused by unsafe field checks on retail aura entries

## Compatibility Notes
- Retail and Midnight now sanitize aura fields before PitBull logic uses them
- Classic-family behavior is preserved for normal non-secret aura values
- On a secret-value fault, Aura filters now fail closed for highlighting and fail open for normal aura display

## Testing Checklist
- Login cleanly
- `/reload` cleanly
- Open PitBull options
- Toggle aura highlight options
- Verify buffs and debuffs still display
- Verify highlight no longer throws repeated Lua errors
- Verify aura filtering still works for common filters

## Feedback Requested
- Any remaining Aura Lua errors
- Missing buffs or debuffs after load
- Highlight color mismatches
- Filters that now silently stop matching

## Known Risks
- Filters that depend on unavailable secret fields may now fall back instead of matching exactly
- Additional Aura filter types may still need direct hardening if later stacks identify them
