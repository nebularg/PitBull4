# PitBull4 Stage 01B Changelog

## Summary
Fixed the first Midnight runtime regressions reported during load testing while keeping the stage functional and low-risk.

## Goals
- Stop config mode from touching secret numeric unit values on Midnight
- Prevent source-snapshot DogTag warnings when LibDogTag libraries are not packaged
- Keep visible behavior unchanged outside preview/config mode

## Files Changed
- ModuleHandling/BarModules.lua
- Modules/CombatFader/CombatFader.lua
- modules.xml
- modules_TBC.xml
- modules_Cata.xml
- modules_Mists.xml
- Modules/DogTagTexts/load.xml

## Fixed
- PowerBar and HealthBar preview updates triggering arithmetic/comparison on secret numeric values during config mode
- CombatFader preview state recalculation triggering secret numeric comparisons during config mode
- DogTagTexts source-snapshot load warnings caused by missing LibDogTag packaged libraries
- Incorrect relative library paths in the standalone DogTagTexts load file

## Changed
- Bar modules now prefer example values while a frame is force-shown in config mode
- CombatFader now uses a safe preview state during config mode instead of reading live player health/power values
- DogTagTexts is no longer force-included from the root module XML files when the required libraries are not packaged
- Corrected standalone DogTagTexts library include paths for builds that do vendor LibDogTag

## Compatibility Notes
- Midnight: avoids known secret-number preview failures reported in load testing
- Earlier clients: normal live bar calculations remain unchanged outside config mode
- DogTagTexts remains an optional module and should only be packaged or enabled when LibDogTag is present

## Testing Checklist
- Login with existing profile
- Reload UI
- Open options
- Toggle config mode on and off
- Verify player and target bars appear
- Verify combat fade preview does not throw errors
- Confirm no DogTag lib warnings appear on startup

## Feedback Requested
- Any remaining secret value errors
- Whether config mode previews now load cleanly
- Whether you still want DogTagTexts packaged in-tree or fully split out as a separate optional addon
