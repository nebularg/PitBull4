# PitBull Stage 01A Changelog

## Summary
Applied a Midnight TOC hotfix so the addon can load on the 12.0 client track.

## Why this stage hotfix was needed
The uploaded snapshot still used the mainline TOC interface value `110207`. On Midnight builds, that can block addon loading even with outdated addons enabled.

## Files Changed
- PitBull4_Mainline.toc
- Modules/DogTagTexts/PitBull4_DogTagTexts_Mainline.toc

## Changed
- Updated the mainline interface number from `110207` to `120000`
- Updated the DogTagTexts mainline interface number from `110207` to `120000`

## Compatibility Notes
- This hotfix only changes the Midnight/mainline TOCs
- Classic-family TOCs were left unchanged
- No intended runtime logic changes in this hotfix

## Testing Checklist
- Addon appears in the addon list on Midnight
- Addon can be enabled without being blocked by TOC mismatch
- Login succeeds with PitBull enabled
- DogTagTexts module loads when installed

## Feedback Requested
- Exact client/build where the TOC mismatch occurred
- Any remaining startup errors after the TOC hotfix
- Whether DogTagTexts also required the same TOC bump on your install

## Note
This uses interface value `120000` for the Midnight/12.0 track. If your specific client build expects a newer 12.0.x interface number, I can bump it again in the next pass.
