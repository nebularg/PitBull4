# PitBull4 Stage 01AE Changelog

## Summary
Fixed a load regression introduced in the prior HealthBar queue refactor and tightened the shared string/GUID sanitizers used by PitBull after the Ace library refresh.

## Goals
- Restore clean load after the latest PitBull-only hotfix
- Keep third-party library updates untouched
- Fix the HealthBar OnUpdate queue bug
- Remove remaining secret-string comparisons inside PitBull helper functions

## Files Changed
- Main.lua
- Utils.lua
- Modules/HealthBar/HealthBar.lua

## Fixed
- HealthBar timer tried to iterate `guids_to_update` after the queue was renamed to `units_to_update`
- Safe GUID helper in `Main.lua` still compared/probed protected strings internally
- Shared `Utils.SafeString` helper still compared/probed protected strings internally

## Compatibility Notes
- No Ace library files were modified
- Changes are PitBull-only and safe for the current staged Midnight hardening work

## Testing Checklist
- Addon loads without the HealthBar `pairs` error
- Reload UI works
- HealthBar updates continue to run
- No new `SafeString`/`SafeGUID` helper errors at load

## Feedback Requested
- Clean load result
- Remaining PitBull-owned stack traces only
- Whether player/target health bars still update after load
