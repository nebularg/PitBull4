# PitBull Stage 01V Changelog

## Summary
Hardened VisualHeal against Midnight protected incoming-heal values during config/profile rebuilds and live frame updates.

## Goals
- Keep addon loadable
- Preserve visible VisualHeal behavior where values are safe
- Stop secret-number arithmetic in VisualHeal

## Files Changed
- Modules/VisualHeal/VisualHeal.lua

## Fixed
- VisualHeal now uses preview values for force-shown frames during rebuild paths
- Incoming-heal and absorb arithmetic now runs behind a guarded path
- VisualHeal clears safely when Midnight refuses protected heal values

## Testing Checklist
- Login
- /reload
- Open options
- Toggle config mode
- Change profile/layout
- Verify no VisualHeal error
- Verify normal incoming-heal display still appears in gameplay
