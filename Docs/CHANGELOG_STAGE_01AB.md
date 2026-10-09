# PitBull4 Stage 01AB Changelog

## Summary
Follower dungeon secret-value hardening focused on PitBull-owned GUID caches, Aura throttling, HealthBar throttling, CastBar caches, UnitFrame GUID updates, and target/highlight comparisons.

## Goals
- Keep the addon functional and testable
- Fix follower dungeon secret GUID and secret boolean regressions
- Avoid altering third-party libraries
- Reduce repeated table-index and direct compare faults caused by protected GUIDs and protected booleans

## Files Changed
- Main.lua
- Utils.lua
- UnitFrame.lua
- Modules/Aura/Update.lua
- Modules/HealthBar/HealthBar.lua
- Modules/LuaTexts/LuaTexts.lua
- Modules/CastBar/CastBar.lua
- Modules/Highlight/Highlight.lua
- Modules/Border/Border.lua

## Added
- `PitBull4.Utils.SafeString`
- `PitBull4.Utils.SafeGUID`
- `PitBull4.Utils.SafeBoolean`
- Local `SafeGUID` helper in `Main.lua` so Main can sanitize GUIDs before `Utils.lua` loads

## Changed
- GUID table keys are sanitized before being stored or looked up in PitBull-owned caches
- Unit frame GUID assignment now stores sanitized GUIDs
- Aura throttling now indexes update queues with sanitized GUIDs and skips queued work while leaving the world
- Aura player checks now use a safe boolean conversion instead of a raw `UnitIsUnit` result
- HealthBar throttling now uses sanitized GUID keys
- LuaTexts spellcast target caching now sanitizes the target string and cast GUID keys
- CastBar cache lookups and cast-id storage now sanitize GUID and cast-id values
- Highlight and Border target comparisons now sanitize target GUIDs and frame GUIDs

## Fixed
- `Main.lua` secret GUID table-index faults in `refresh_guid`
- `Main.lua` secret GUID compare faults while iterating frames by GUID
- `UnitFrame.lua` secret GUID compare fault in `OnShow`
- `Aura/Update.lua` secret GUID table-index faults in throttled aura update queues
- `Aura/Update.lua` secret boolean test on `is_player`
- `HealthBar.lua` secret GUID table-index faults in throttled health updates
- `LuaTexts.lua` secret target compare in `UNIT_SPELLCAST_SENT`
- `CastBar.lua` secret GUID table-index fault in cast cache lookup
- `Highlight.lua` secret target GUID compare

## Compatibility Notes
- This stage only changes PitBull-owned code paths
- Third-party libraries were intentionally left untouched
- Retail/Midnight secret GUID and secret boolean handling is the focus of this stage

## Testing Checklist
- Enter a follower dungeon
- Target follower NPCs and enemies repeatedly
- Change targets quickly during combat
- Verify target and targettarget frames keep updating
- Verify health bars still update
- Verify aura updates continue without spam
- Verify highlight on target still works
- Verify cast bars still appear on follower dungeon targets and nameplates

## Feedback Requested
- Any remaining `table index is secret` or secret GUID compare errors in PitBull-owned files
- Whether target, targettarget, and party follower frames now stay stable in follower dungeons
- Whether health, aura, cast bar, and highlight behavior still looks correct after the GUID sanitization pass

## Known Risks
- Additional GUID-based caches in PitBull modules may still need the same sanitization pattern if new follower-dungeon traces appear
- Modules that key by GUID outside this patch set may still need a second sweep
