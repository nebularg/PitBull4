# PitBull4 Stage 01X Changelog

## Summary
Adjusted HealthBar live value retrieval so Midnight uses secure-call health normalization before falling back.

## Changed
- HealthBar now prefers securecallfunction for UnitHealthPercent math
- HealthBar now prefers securecallfunction for UnitHealth/UnitHealthMax ratio math
- Live fallback now returns a visible full bar instead of the config preview value

## Why
The bar was showing a partial preview-like fill while tooltips reported 100%, which indicates the live health path was falling back to the example value instead of a real live value.

## Test Checklist
- Player health bar visible
- Target health bar visible
- Health bars update after damage/healing
- No new HealthBar errors
