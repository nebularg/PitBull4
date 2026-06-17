# PitBull Stage 01AC Changelog

## Summary
Hardened the shared safe string helper so it no longer compares protected Midnight strings internally.

## Goals
- Keep the addon loadable and functional
- Avoid touching third-party libraries
- Fix the PitBull-owned helper that was still faulting on secret strings

## Files Changed
- Utils.lua
- Docs/CHANGELOG_STAGE_01AC.md
- Docs/GIT_CHANGELOG_STAGE_01AC.txt

## Changed
- Removed the empty-string comparison from `PitBull4.Utils.SafeString`
- Kept the helper focused on safe `tostring` conversion and type validation only

## Fixed
- `PitBull4/Utils.lua:19: attempt to compare local 'string_value' (a secret string value tainted by 'PitBull4')`

## Compatibility Notes
- No third-party libraries were modified
- This change only affects PitBull-owned helper logic

## Testing Checklist
- Login and reload UI
- Trigger cast activity that updates the cast cache
- Check follower dungeon target and nameplate cast activity
- Confirm the `Utils.lua:19` secret-string error is gone

## Feedback Requested
- Any new PitBull-owned stack trace
- Whether follower dungeon cast-related updates are now clean
