# PitBull Stage 01H Changelog

## Summary
Patched Alternate mana bar for Midnight secret-number handling while keeping the addon functional and testable.

## Goals
- Keep addon loadable
- Preserve Alternate mana bar behavior in normal gameplay
- Avoid secret-number arithmetic during config mode and restricted startup

## Files Changed
- Modules/AltManaBar/AltManaBar.lua

## Added
- Alternate mana bar example value path for shared config-mode preview handling
- Restricted-startup and world-ready guards for live mana reads
- Error-safe live mana normalization with protected arithmetic

## Changed
- Config mode now previews AltManaBar with a static example value
- Live Alternate mana bar math now fails closed instead of throwing Lua errors on Midnight

## Fixed
- Secret-number arithmetic in AltManaBar during frame updates triggered from options/config flows

## Compatibility Notes
- Retail/Midnight: avoids live alternate mana arithmetic during restricted startup and config previews
- Older clients: normal Alternate mana bar behavior is preserved

## Testing Checklist
- Login without new AltManaBar errors
- Reload UI
- Open PitBull options
- Toggle config mode on and off
- Update layout/profile settings touching the player frame
- Verify Alternate mana bar still appears in normal gameplay when appropriate

## Feedback Requested
- Any remaining secret-number errors
- Whether AltManaBar still appears correctly for specs/forms using alternate mana
- Any visual regressions in the player frame layout
