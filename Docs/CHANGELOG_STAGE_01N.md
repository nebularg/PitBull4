# PitBull Stage 01N Changelog

## Summary
Hardened cast timing and interruptibility handling in LuaTexts and CastBar to avoid Midnight secret-value faults during live cast events.

## Goals
- Keep the addon loadable and testable
- Fix remaining cast-related secret-value errors
- Avoid changing visible cast behavior outside fault handling

## Files Changed
- Modules/LuaTexts/LuaTexts.lua
- Modules/CastBar/CastBar.lua

## Added
- Safe cast-time conversion helper in LuaTexts
- Safe interruptibility helper in LuaTexts
- Safe interruptibility helper in CastBar

## Changed
- LuaTexts now converts protected cast start/end times through a guarded helper
- LuaTexts now resolves interruptibility through a guarded helper
- CastBar now resolves interruptibility through a guarded helper

## Fixed
- Secret-number arithmetic in LuaTexts cast timing updates
- Secret-boolean negation in CastBar channel handling

## Compatibility Notes
- Mainline/Midnight: guarded against protected cast timing and interruptibility values
- Earlier clients: behavior should remain unchanged because normal values still pass through the same paths

## Testing Checklist
- Login
- /reload
- Player cast start and channel start
- Nameplate cast start and channel start
- LuaTexts cast-related displays
- CastBar interruptible/uninterruptible visuals

## Feedback Requested
- Any remaining LuaTexts cast stacks
- Any remaining CastBar channel/cast stacks
- Missing cast text or cast bar timing regressions
