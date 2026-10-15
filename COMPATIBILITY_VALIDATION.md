# PitBull4 Compatibility Validation

Date: 2026-10-15  
Revision label: **compat-20261015.1**  
Source version fields: **@project-version@**  
Installation baseline: **PitBull4_Status_Bar_Hotfix_Full_2026-10-13.zip**, revision **compat-20261013.2**  
Status: **Offline checks passed; live-client confirmation pending**

## Diagnosis

The Totems module registered `Sound\Interface\DropOnGround.ogg` as the shared-media sound named `Drop`. The supplied error identifies this registration as the missing-file failure. The same obsolete path also supplied fallback playback when LibSharedMedia was absent.

The replacement uses FileDataID **567460** for registration and default playback. Existing profiles retain `Drop`; custom sound names and selector previews continue through the existing library API. A nil media lookup now falls back to the default file ID. Totems obtains its addon table from Warcraft's private load namespace.

The asset mapping is recorded in the maintainer's [MuteAnnoying sound inventory](https://github.com/ketho-wow/MuteAnnoying/blob/master/Sounds/interface.lua). This identifies the asset; it does not establish live availability in every client installation.

## Separate Edit Mode excerpt

The second excerpt omits the error heading, message, and initial stack frames. Its locals match `ObjectiveTrackerManager:SetTextSize()` in the supplied Retail **12.1.5 build 70391** and Forever **1.60.1 build 70338** snapshots. Both select `ObjectiveTrackerFont12` and `ObjectiveTrackerFont14`, assign the native fonts, and update registered tracker containers.

PitBull's application code does not reference that manager or those fonts. The excerpt establishes no direct PitBull caller or cause. The hotfix leaves tracker, font, global, and Edit Mode methods untouched. This issue remains **unresolved** until a complete fresh error, including its first line, top stack frames, and client build, is available.

## Compatibility scope

| Supplied client | Sound handling | Secure frame changes |
| --- | --- | --- |
| Retail 12.1.5 / 70391 | Numeric file ID through existing registration/playback APIs | None |
| Forever 1.60.1 / 70338 | Same handling | None |
| Mists Classic 5.5.4 / 70032 | Same handling | None |
| BCC Anniversary 2.5.6 / 69795 | Same handling | None |
| Classic Era 1.15.9 / 69547 | Same handling | None |

No client-specific sound branch is required. The existing class gate remains. All TOCs, Interface declarations, packager tokens, secure unit buttons, group headers, anchoring, and earlier status-bar/class-resource corrections are retained. No library file or shared runtime function is modified. Whole-addon dependency removal and additional native Edit Mode integration remain separate project work.

## Verification

- **147 focused checks passed** using the complete original and revised Totems modules. A strict media fixture reproduces the original registration error, then verifies revised startup for all five supported classes with and without shared media.
- Checks cover default, custom-path, numeric, explicit `None`, and unresolved sound choices; all four saved slot defaults; selector/preview values; silent world-entry refresh; disabled sound; silent totem creation; and the unsupported-class gate.
- The existing native-options suite passed **130 assertions** through unchanged AceConfig/AceGUI code.
- The revised module parses with Lua **5.3.6** and retains Lua 5.1-compatible syntax. A Lua 5.1 compiler is unavailable.
- The required library verifier confirms all **139** locked files match their baseline; the changed-only archive contains no library entries.
- Package comparison verifies the overlay exactly reconstructs the full release from its stated baseline, preserves all application TOCs and packager-token counts, and retains a single consolidated `CHANGELOG.md`.

The **2,198** assertions recorded in `Tests/status_bar_hotfix_results.json` belong to **compat-20261013.2**. Their production code is retained byte for byte; those historical results are not a newly rerun full compatibility campaign.

Fixtures verify addon behavior and argument routing. They cannot confirm installed audio assets, real playback, secrecy/taint, or protected execution. No running Warcraft client is available.

## Installation and live checks

Overlay the changed-only ZIP on the October 13 status-bar release **compat-20261013.2**, accepting replacements. For an older or uncertain installation, use the full replacement. Keep SavedVariables.

Restart Warcraft or use `/reload`. On a supported class, confirm a clean login and enable totem sounds. Let a totem expire or destroy it and confirm the default `Drop` sound, a custom sound, and explicit `None`. World-entry refresh should stay silent. Capture a complete new error if either issue recurs.

`CHANGELOG.md` is the sole consolidated history. Test fixtures are not loaded by Warcraft. Supplied Blizzard source archives are excluded from both packages.
