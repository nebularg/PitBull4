# PitBull4 — Consolidated Changelog

Consolidated change history through **compat-20261015.1**, including Stages 01–01AM and the subsequent compatibility releases. Documentation updated **2026-10-15**. Release labels identify these changes; source version fields retain `@project-version@` for the packager.

## compat-20261015.1 — Totem sound registration (2026-10-15)

- Replaced the obsolete default totem sound path with FileDataID `567460`, correcting the LibSharedMedia missing-file error during Totems module loading and the default playback path.
- Preserved the existing `Drop` profile value, per-element custom sound choices, sound previews, and silent world-entry updates. An unresolved media lookup falls back to the default file ID.
- Loaded Totems through the private addon namespace. Retained the October 13 status-bar corrections, all packager version tokens, existing secure frame behavior, and all 139 locked library files.
- Passed 147 focused startup, playback, profile, and options checks, plus the 130 existing native-options assertions. Live audio confirmation remains pending; the separate incomplete Edit Mode trace remains undiagnosed.

## compat-20261013.2 — Revised status-bar refactor (2026-10-13)

- Restored exact `@project-version@` placeholders in all application TOCs and the runtime version string, preserving automated release substitution and the existing development-build fallback.
- Moved reputation event dispatch to one unnamed native frame in the private addon namespace. The frame and callback are reused across module toggles; disabling unregisters its events and clears the cached display state.
- Cached one reputation snapshot per event for all player frames. Display queries reuse scalar values, with no new polling script, table creation, or frame creation in this module's update paths.
- Selected modern reputation APIs on Retail with legacy and capability fallbacks for other clients. Handled unavailable faction/renown data, unreadable values, and invalid paragon thresholds safely. Replaced the friendship UI-mixin dependency with private rank-color calculation matching Blizzard's behavior.
- Retained the shared status-bar hook removal, class-resource correction, secure unit frames and headers, saved profiles, and all 139 library files. All 2,198 offline assertions pass; live-client confirmation remains pending.

## compat-20261013.1 — Reputation and status-bar compatibility (2026-10-13)

- Removed the reputation module's secure hooks on Blizzard's shared status-tracking manager and legacy experience-bar updater. Reputation now refreshes from world entry, faction changes, and supported renown events, addressing the PitBull hook boundary implicated in the reported CVar and override-experience-bar errors.
- Deferred reputation reads while leaving or loading the world and refreshed the display when the module is enabled after login. Blizzard status-bar layout updates no longer trigger unrelated PitBull reputation work.
- Restored the watched faction's name in the modern reputation color path, allowing native faction and paragon colors to display correctly.
- Preserved the class-resource parent correction, reversible frame toggles, existing profiles, and all 139 bundled library files. Added regression coverage against the supplied Retail, Forever, BCC, Mists, and Era sources; live-client confirmation of the reported errors remains pending.

## Core and client compatibility

- Added a private compatibility bootstrap and native/legacy API adapters for addon loading and metadata, spells, range and cooldown queries, auras, tooltips, and reputation.
- Added optional restriction-state monitoring and world-entry refreshes. Corrected the API lookup to `C_RestrictedActions.GetAddOnRestrictionState`, with a legacy fallback where available.
- Added explicit Era and Camelot entry points, optional DogTag manifests, client-specific module selections, and manifest diagnostics. Separated Forever/Camelot identity from Classic.
- Corrected Forever's Interface declaration to **16001**. Current Retail manifests retain **120100, 120105**; the earlier Midnight Interface 120000 update is superseded.
- Added default boss-group and focus units to existing TBC profiles inherited from earlier Classic releases in upstream v4.2.49.

## Blizzard frames, Edit Mode, and scenario targets

- Made Hide Blizzard frames settings reversible. Unchecking an option, changing profiles, or disabling the module restores frames immediately outside combat; combat changes apply afterward using the latest settings.
- Preserved Blizzard events, unit watches, contextual visibility, parent requests, party-frame pools, and raid-display preferences. Covered optional frames, delayed addon loading, and generated compact party and arena frames.
- Preserved native cast-bar and alternate-power parenting and methods, avoiding the direct `Show` override that caused Edit Mode taint. Removed obsolete reload instructions and the module's Reload UI option.
- Fixed the Retail Midnight `ClassPowerBar.lua:11` error on 12.1.0 build 69933. Modern class-resource bars now use reversible alpha/mouse suppression while retaining the parent chain needed by Blizzard's unit lookup, combat callbacks, setup, and maximum-power updates. Classic keeps its existing suppression and Mists Monk/Paladin aliases.
- Fixed scenario NPC targets remaining hidden or showing a stale previous unit when their GUID is restricted. Added private per-frame identity revisions, distinguished restricted live units from absent units, and refreshed matching frames and portraits when targets change.

## Health, power, and healing predictions

- Added example values and colors for configuration previews and guarded live reads during restricted startup. CombatFader remains visible when health or power data is inaccessible.
- Repaired shared bar getters, health-fraction scaling, and fill geometry. Preserved readable-value reverse, deficit, fade, animation, and extra-segment behavior while sending inaccessible values through native display methods.
- Preserved health-bar controls through death, ghost, disconnection, resurrection, and reconnection, with visible fallback values and appropriate state colors.
- Improved live unit-event updates and `best_unit` selection for swapped or target-chain frames. Corrected primary/alternate-mana hiding, the HealthBar queue-rename regression, and the duplicated color-options callback that prevented loading.
- Centralized VisualHeal control creation and corrected preview, incoming-heal, absorb, endpoint, and replacement-control handling. Inaccessible prediction data clears the affected overlay until readable data returns.

## Auras and tooltips

- Guarded aura fields, ownership, dispel types, sorting, filters, and highlights against restricted values. Replaced raw source-unit/name comparisons with derived ownership and stable numeric keys.
- Matched aura-tooltip refreshes by instance ID with spell-ID fallback, replacing name-based matching.
- Guarded stack counts, cooldown timing, and icon assignment, with spell-texture or sample-icon fallback when live icons are inaccessible.
- Added display/highlight filter fallback handling and removed reliance on the deprecated aura-consolidation tuple.
- Fixed Classic Era atlas resets and stale texture-cache state. Checked spell availability before aura-filter conversion and deferred saved-name insertion until ID iteration completes.
- Left unit-tooltip title coloring to Blizzard's native unit-tooltip path, avoiding restricted identity checks on compound units such as `targettarget`.

## Casting and text

- Guarded cast timing, interruptibility, identifiers, icon paths, and cached cast data. Restricted Retail casts suppress the cast display without preventing the owning unit frame from updating.
- Moved cast caches and ScriptEnv cast-data lookup to unit-token keys, including target-chain frames. Used token matching for cast-to-frame updates and latency player detection.
- Suppressed unsafe Mainline global-cooldown duration sizing while retaining cast-queue handling.
- Corrected LuaTexts pooled-table cleanup and guarded release of non-table input. Replaced CombatText's live FontString comparison with an internal preview-state flag.
- Kept DogTagTexts optional, corrected standalone library include paths, and modernized load-on-demand handling. Earlier supplied text-provider changes covered restricted compiler results, modern aura scanning, native/legacy cast APIs, and health/ghost-state calculations.

## Unit caches and indicators

- Added access-aware string, GUID, boolean, equality, and table helpers for core frame caches, LuaTexts status/event updates, Highlight, Border, and player/pet power matching.
- Replaced GUID-keyed throttled aura, health, power, and ready-check queues with unit-token keys; corrected queue iteration and avoided queued aura work while leaving the world.
- Used unit-token leader detection and handled ready-check frames represented by a target or `best_unit`.

## Options and specialization profiles

- Added native specialization-profile switching while preserving existing bindings and older alternate-profile data, including deferred changes during combat.
- Added PitBull-owned toggle, multiselect, three-state, and radio controls without replacing shared AceGUI widget types, constructors, or versions.
- Retained saved-profile compatibility and the existing AceConfig/AceGUI options container. Whole-addon dependency removal remains ongoing.

## Library boundary and documentation

- Restored and locked all **139 bundled library files** to the supplied scenario-target baseline. Added SHA-256 inventory and boundary verification; application-only distributions exclude library files.
- Reverted the temporary AceGUI CheckBox, LibDualSpec, and DogTag compiler whitespace-pattern edits in compat-20261010.1.
- Earlier guarded normalization, secure-call, and string-conversion experiments were superseded by later access-aware boundaries and native rendering corrections.
- Consolidated **82 changelog files** into this single document, removing repeated stage/Git copies, redundant explanations, testing prompts, and unrelated-addon notes.

## Earlier status-bar verification (compat-20261013.2)

The revised status-bar hotfix passed **2,198 offline assertions**, including **745 reputation/status-bar checks** and the existing compatibility, frame, options, and profile suites. Both original status-tracking and override-experience event paths ran against all five supplied client sources. Class-resource callbacks also passed against the updated Retail 12.1.5 build 70391 source. Packager-token checks and all **16 root manifest load graphs** pass. Earlier static checks covered **122 application Lua files** and **91 XML files**; current validation details are in `COMPATIBILITY_VALIDATION.md`.

These results do not certify live-client secrecy, taint, secure execution, layout, or performance. In-game validation remains pending.

[Upstream release history](https://github.com/nebularg/PitBull4/releases)
