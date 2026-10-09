# PitBull Stage 01F Changelog

## Summary
Hardens remaining Midnight secret-number startup/config-mode failures by moving guards into the shared bar pipeline and using error-safe numeric probes for CombatFader.

## Files Changed
- ModuleHandling/BarModules.lua
- Modules/PowerBar/PowerBar.lua
- Modules/HealthBar/HealthBar.lua
- Modules/CombatFader/CombatFader.lua

## Changed
- Config mode now uses example bar values from the shared bar module path for all frame rebuilds, not only force-shown frames.
- HealthBar and PowerBar now wrap live normalization math in `pcall` to suppress Midnight secret-number startup faults.
- CombatFader now uses error-safe power and health state probes instead of raw numeric comparisons that can fault during startup.

## Testing Checklist
- Login
- Reload UI
- Open options
- Toggle config mode
- Verify player and target health/power bars
- Verify CombatFader loads without startup errors
