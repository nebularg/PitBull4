# PitBull4 Stage 01P Changelog

## Summary
Patched the remaining active Midnight cast-data and icon-path faults reported after Stage 01O.

## Goals
- Keep the addon functional and testable
- Remove remaining raw arithmetic on protected cast times in LuaTexts
- Remove protected icon-path comparisons in BetterStatusBar
- Remove protected cast-id comparisons in CastBar

## Files Changed
- Modules/LuaTexts/LuaTexts.lua
- Controls/BetterStatusBar.lua
- Modules/CastBar/CastBar.lua

## Fixed
- Replaced a remaining raw `start_time * 0.001` and `end_time * 0.001` path in LuaTexts with guarded conversion helpers
- Replaced raw `not uninterruptible`-style logic in LuaTexts cast caching with the guarded interruptibility helper
- Replaced raw cast-id equality in LuaTexts with a guarded comparator
- Replaced raw `old_icon_path == path` comparison in BetterStatusBar with a guarded comparator
- Guarded `SetTexture(path)` in BetterStatusBar so restricted cast icons fail closed instead of throwing
- Replaced raw `data.cast_id == event_cast_id` in CastBar with a guarded comparator

## Compatibility Notes
- Midnight/Mainline: avoids protected arithmetic, boolean negation, and secret-value equality on cast data and icon values
- Older clients: behavior should remain unchanged because the guarded helpers fall through to normal values

## Testing Checklist
- Login
- `/reload`
- Player cast start
- Player channel start
- Nameplate cast start
- Nameplate channel start
- Cast bar icon display
- LuaTexts cast-related text updates

## Feedback Requested
- Any remaining PitBull stack traces mentioning CastBar, LuaTexts, or BetterStatusBar
- Whether cast icons now disappear on some units instead of erroring
- Whether any cast-related LuaTexts stop updating
