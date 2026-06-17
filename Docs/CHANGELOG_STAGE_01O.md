# PitBull4 Stage 01O Changelog

## Summary
Patched the remaining CastBar interruptibility path that was still negating a protected boolean on Midnight.

## Files Changed
- Modules/CastBar/CastBar.lua

## Fixed
- Replaced the remaining `not uninterruptible` path with a guarded boolean resolution helper.
- Defaulted to interruptible when Midnight provides a protected boolean that cannot be safely evaluated.

## Testing Checklist
- Login
- Reload UI
- Player cast start
- Player channel start
- Nameplate cast start
- Nameplate channel start
- Interruptible vs uninterruptible cast coloring

## Feedback Requested
- Any remaining CastBar stack traces
- Whether uninterruptible coloring still appears correctly when available
