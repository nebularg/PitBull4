# PitBull Unit Frames 4.0

## [Unreleased](https://github.com/nebularg/PitBull4/compare/v4.2.49...HEAD) (2026-04-16)
[Full Changelog](https://github.com/nebularg/PitBull4/compare/v4.2.49...HEAD) [Previous Releases](https://github.com/nebularg/PitBull4/releases)

- Midnight / Retail secret-value compatibility pass across PitBull text evaluation.
    Hardened LuaTexts, ComboPoints, and DogTag-driven text paths against secret boolean / number / string comparisons that could trigger taint-style runtime errors on modern clients.
    This includes avoiding unsafe direct boolean tests and numeric comparisons when the client marks values as secret.

- Modernized DogTag text loading and startup behavior.
    Updated the DogTag text provider to use `C_AddOns` loading paths and modern addon availability checks while keeping the module load-on-demand friendly.
    Preserves existing PitBull text-provider behavior while improving compatibility with current clients.

- Expanded LibDogTag-3.0 secret-value handling.
    Added defensive handling for secret values in compiler output and core categories so expressions no longer break on empty-string coercion, numeric conversion, or equality checks when protected values are returned.
    Secret results are now preserved safely instead of being forced through unsafe normalization paths.

- Updated LibDogTag-Unit aura scanning for current Blizzard APIs.
    Aura tags now use `C_UnitAuras.GetAuraDataByIndex` / `GetAuraDataBySpellName`, skip secret aura names, track aura counts and expiration data safely, and continue to fire DogTag aura events without depending on legacy name-based access patterns.

- Improved cast-tag compatibility from Classic through Midnight.
    Cast handling now branches between older rank-returning cast APIs and modern spellID-based APIs, respects Classic player-only fallback behavior, and avoids unsafe comparisons when GUID, cast times, or spell identifiers are secret.

- Modernized health-tag calculations for restricted clients.
    Health text now uses `UnitHealthPercent()` and Blizzard curve helpers where available, with safe fallback math for older clients.
    Ghost-health edge cases and color calculations were also tightened for better cross-version consistency.

- Cross-version DogTagTexts packaging pass.
    Kept versioned TOCs aligned for TBC, Cataclysm Classic, Mists Classic, and Mainline so the DogTag text module remains loadable across supported WoW branches during the compatibility refactor.

## [v4.2.49](https://github.com/nebularg/PitBull4/tree/v4.2.49) (2026-02-12)
[Full Changelog](https://github.com/nebularg/PitBull4/compare/v4.2.48...v4.2.49) [Previous Releases](https://github.com/nebularg/PitBull4/releases)

- Add default boss group and focus units to existing profiles in TBC  
    This is for people coming from classic releases.  
    Resolves #94  
