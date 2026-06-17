# PitBull4 Stage 01L Changelog

## Summary
Hardened Aura icon rendering for Midnight by preventing secret icon values from being passed directly into Texture:SetTexture.

## Goals
- Keep addon loadable and functional
- Stop Aura icon spam on Midnight
- Preserve visible aura rendering with a safe fallback path

## Files Changed
- Modules/Aura/Update.lua

## Added
- Safe aura texture setter with fallback handling
- Spell texture fallback lookup by spell ID when available

## Changed
- Aura normalization no longer tries to coerce icon values through generic string conversion
- Aura control updates now use a guarded texture assignment path

## Fixed
- Prevented secret aura icon strings from being passed directly to SetTexture
- Added fallback to spell texture or sample buff/debuff icon when the live icon is restricted

## Compatibility Notes
- Midnight/Mainline: guarded against secret icon values returned by aura data
- Older clients: normal icon assignment still works

## Testing Checklist
- Login
- /reload
- Player buffs/debuffs render
- Target buffs/debuffs render
- Aura update loop stays clean
- No repeated SetTexture secret string errors

## Feedback Requested
- Any remaining Aura errors
- Missing aura icons
- Wrong fallback icons
