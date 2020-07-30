# PitBull Unit Frames 4.0

Woof. Arf. Yip.

[Issues](https://www.wowace.com/projects/pitbull-unit-frames-4-0/issues) ([New issue](https://www.wowace.com/projects/pitbull-unit-frames-4-0/issues/create))

[FAQ](https://www.wowace.com/projects/pitbull-unit-frames-4-0/pages/faq)

Getting Started:

- [Making Layouts](https://www.wowace.com/projects/pitbull-unit-frames-4-0/pages/guide/making-layouts-and-applying-to-frames)
- [Party and Raid Frames](https://www.wowace.com/projects/pitbull-unit-frames-4-0/pages/guide/party-and-raid-frames)

You can help translate PitBull for your language with the [localization tool](https://www.wowace.com/projects/pitbull-unit-frames-4-0/localization/).

## Classic

PitBull works with WoW Classic! Some things that are different from retail:

- Health is only reported as the percentage (0-100). PitBull supports showing
  actual values if you also install [Real Mob Health](https://www.curseforge.com/wow/addons/real-mob-health).
- Aura duration is not available from the API, so PitBull uses [LibClassicDurations](https://www.curseforge.com/wow/addons/libclassicdurations)
  to show them. The duration can be inaccurate if it's affected by rank or
  talents.
- Cast info is only available for your spells from the API. PitBull uses [LibClassicCasterino](https://github.com/rgd87/LibClassicCasterino)
  to show cast bars for other units, but this can be inaccurate since there is
  a lot of guess-work involved.

## Changelog Highlights ![OhMyDog](https://static-cdn.jtvnw.net/emoticons/v1/65/1.0)

### v4.1.26 changes

- Fixed an issue with '30-man raid' filtering that would hide groups when your
  group size was between 26 and 30.

### v4.1.25 changes

- Updated `PhaseIcon` to show a tooltip with the phase reason.
- Fixed `PhaseIcon` for 9.0.1.
- Fixed boss frames not hiding for 9.0.1.

### v4.1.24 changes

- Added '30-man raid' to groups filtering.
- Updated for 9.0.1.

### v4.1.22 changes

- Updated for 8.3.0.
- Updated `ArtifactPowerBar` to hide if your azerite item is at max level.

### v4.1.21 changes

- Updated for 8.2.5.
- Added some more initial frame updates.

### v4.1.20 changes

- Fixed frames getting stuck with incomplete unit infomation. This should
  fix things like the name getting stuck as "Unknown" and class colors being
  wrong.

### v4.1.19 changes

- Updated for 8.2.0.

### v4.1.18 changes

- Updated `ArtifactPowerBar` to hide if your azerite item is not equipped.
- Fixed `ResurrectionIcon` and `SummonIcon` getting stuck shown after zoning.
- Updated unit and group selector dropdowns to show which items are disabled.

### v4.1.17 changes

- Added `ResurrectionIcon` indictor to show incoming and pending resurrection spells.
- Added `SummonIcon` indictor to show incoming and pending summons.
- Updated `PhaseIcon` indicator to show on players with a different warmode setting.
- Updated the vehicle swap handling to work like the default UI. For example, this
  fixes being able to click on the person in the pod in the Antoran High Command
  encounter from your raid frames. Unfortunately, it only works in raid, so things like
  selecting the player in the Tol Dagor cannon are still cumbersome.
- Added sorting and filtering party groups by role.
- Aura: Added Arcane Torrent for Blood Elves and updated purge filters.

### v4.1.0 changes

- **Frame anchoring**. For example, you can anchor your `Target of target` frame to your `Target` frame so that it moves when you move your `Target` frame. In config mode, frames anchored to another frame will show a gray line connecting them at the anchor points set.
- **Multiple unit frames**
  - Want a player cast bar that auto-hides and doesn't squish your other bars together? Create a new unit frame and set the unit to `Player`, set a layout that only has `Cast bar` enabled on it, and anchor it to your original player frame.
  - Due to how the indicator offset system works, it makes fine-tuning the position of secondary resource icons awkward. You can now create a duplicate unit frame for positioning your combo points exactly where you want.
  - Frame names now use the unit frame label instead of the unit. For example, PitBull4\_Frames\_player is now PitBull4\_Frames\_Player, PitBull4\_Frames\_targettarget is now "PitBull4\_Frames\_Target's target". You'll need to update any addons (**kgPanels**) that anchor to your unit frames. You can check the name of the frame with `/framestack`.
- **Default frame positions**. Starting from scratch no longer dumps all of the frames in the middle of your screen. They will now show in a layout similar to the Blizzard layout.
- **Added Masque support for auras.** If you use Masque, you can set the skin for the layout under Aura-&gt;Display or in Masque under "PitBull4 Aura". Two PitBull skins are provided that will work with hiding/showing the border as set in the settings, or you can disable Masque support completely in the module options (Modules-&gt;Aura).

## Download

CurseForge: <https://www.curseforge.com/wow/addons/pitbull-unit-frames-4-0>  
WoWInterface: <https://www.wowinterface.com/downloads/info20021>  
GitHub: <https://github.com/nebularg/PitBull4/releases>  
