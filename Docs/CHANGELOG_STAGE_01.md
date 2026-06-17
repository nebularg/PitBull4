# PitBull Stage 01 Changelog

## Summary
Established a baseline compatibility foundation for cross-version PitBull loading, with an emphasis on keeping the addon functional while reducing direct dependency on expansion-specific API assumptions.

## Stage Scope
This stage is intentionally non-visual and low-risk.

It focuses on:
- centralizing client detection and expansion helpers
- adding compatibility shims for key Blizzard C_ namespaces
- routing core load-on-demand addon queries through a shared compatibility layer
- preserving current frame behavior and saved variable behavior

It does not yet refactor:
- secure frame movement internals
- aura identity logic
- Retail Edit Mode integration
- dependency removal

## Files Changed
- Compat.lua
- Main.lua
- load.xml
- Options/Modules.lua
- Options/General.lua

## Added
- `Compat.lua` bootstrap file loaded before `Main.lua`
- shared `addonNamespace.Compat` compatibility table
- compatibility/polyfill support for:
  - `C_AddOns`
  - `C_Spell`
  - `C_UnitAuras`
  - `C_TooltipInfo`
  - `C_Reputation`

## Changed
- Core bootstrap now reads retail/classic/expansion state from the compatibility layer first
- Core load-on-demand module discovery now routes through shared addon wrappers
- Options module enable/disable checks now route through shared addon wrappers
- General options minimap icon visibility check now routes through shared addon wrappers

## Fixed
- Reduced hard dependency on native `C_AddOns` availability in core bootstrap paths
- Added fallback spell, aura, tooltip, and reputation helpers for older clients missing modern C_ namespace APIs
- Reduced the number of direct client-specific addon API calls in always-loaded core files

## Compatibility Notes
- Retail continues using native `C_` APIs when present
- Older clients can fall back to legacy global APIs through compatibility shims
- Stage 01 is designed to preserve visible behavior while making future Midnight refactors safer

## Testing Checklist
- Addon loads at login
- `/reload` works without new startup errors
- Player and target frames render
- Party and raid headers still build
- Options open successfully
- Module enable/disable UI still works
- Minimap icon visibility toggle still works
- No new startup errors related to missing `C_` namespace APIs

## Feedback Requested
- Startup errors
- Load-on-demand module failures
- Broken options pages
- Client-specific compatibility failures by flavor
- Any new tooltip or aura-related errors observed during login or reload

## Known Risks
- This stage does not yet centralize every direct `C_` call in the repository
- Retail Edit Mode support is not part of this stage
- Secure frame and aura refactors are intentionally deferred to later stages
