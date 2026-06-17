# PitBull Stage 01G Changelog

## Summary
Patched the VisualHeal module to avoid Midnight secret-number arithmetic during config mode and restricted startup.

## Goals
- Keep the addon functional and loadable
- Stop VisualHeal from performing live heal-prediction math during config-mode rebuilds
- Avoid restricted live unit-data reads during Midnight startup

## Files Changed
- Modules/VisualHeal/VisualHeal.lua

## Added
- Shared local helper to create or reuse the VisualHeal status bar
- Example VisualHeal preview rendering for config mode

## Changed
- VisualHeal now shows static preview values during config mode instead of reading live incoming-heal values
- VisualHeal now clears itself during restricted startup instead of doing live heal-prediction arithmetic
- VisualHeal bar creation is centralized through a local helper

## Fixed
- Secret-number arithmetic in VisualHeal during config-mode updates on Midnight

## Compatibility Notes
- Midnight/Mainline: avoids live heal-prediction math during config mode and restricted startup
- Classic-family clients: behavior remains unchanged for normal live updates

## Testing Checklist
- Login
- Reload UI
- Open options
- Toggle config mode on and off
- Confirm no VisualHeal Lua error appears
- Confirm normal health bars still render

## Feedback Requested
- Any remaining VisualHeal errors
- Whether config mode now opens cleanly
- Whether live heal prediction still appears in normal gameplay after loading into the world
