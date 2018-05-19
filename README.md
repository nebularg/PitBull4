# PitBull Unit Frames 4.0

Woof. Arf. Yip.

[Issues](https://www.wowace.com/projects/pitbull-unit-frames-4-0/issues) ([New issue](https://www.wowace.com/projects/pitbull-unit-frames-4-0/issues/create))

[FAQ](https://www.wowace.com/projects/pitbull-unit-frames-4-0/pages/faq)

Getting Started:

- [Making Layouts](https://www.wowace.com/projects/pitbull-unit-frames-4-0/pages/guide/making-layouts-and-applying-to-frames)
- [Party and Raid Frames](https://www.wowace.com/projects/pitbull-unit-frames-4-0/pages/guide/party-and-raid-frames)

You can help translate PitBull for your language with the [localization tool](https://www.wowace.com/projects/pitbull-unit-frames-4-0/localization/).

---

## Changelog ![OhMyDog](https://static-cdn.jtvnw.net/emoticons/v1/65/1.0)

### v4.1.10beta2 changes

- Added inactive boss frames support (previously hidden boss frames will be shown in Battle for Azeroth).
- Fixed some LuaTexts functions for Battle for Azeroth.
- Added support for Battle for Azeroth.
- Added Allied races for LuaText functions.

### v4.1.6 changes

- Fixed an error that would prevent frames from showing in config mode.
- Updated Totems to show for Death Knight Gargoyles and Priest Shadowfiends.

### v4.1.5 changes

- Updated when the Totem bar shows and added some color settings (background/timer text) to the layout settings (There are more color settings under Colors->Totems).
- Fixed Chi display.

### v4.1.4 changes

- Added showing your prestige rank when flagged for PvP. You can change this back to just your faction icon under Indictors->PvP icon.
- Updated Soulstones to use the Blizzard art. Hopefully everyone likes the new icons!

### v4.1.1 changes

- **Added Masque support for auras.** If you use Masque, you can set the skin for the layout under Aura->Display or in Masque under "PitBull4 Aura". Two PitBull skins are provided that will work with hiding/showing the border as set in the settings, or you can disable Masque support completely in the module options (Modules->Aura).
- Fixed modules not updating on group frames. (Notably VisualHeal)
- Fixed anchoring to group frames.

### v4.1.0 changes

- **Frame anchoring**. For example, you can anchor your `Target of target` frame to your `Target` frame so that it moves when you move your `Target` frame. In config mode, frames anchored to another frame will show a gray line connecting them at the anchor points set.
- **Multiple unit frames**
  - Want a player cast bar that auto-hides and doesn't squish your other bars together? Create a new unit frame and set the unit to `Player`, set a layout that only has `Cast bar` enabled on it, and anchor it to your original player frame.
  - Due to how the indicator offset system works, it makes fine-tuning the position of secondary resource icons awkward. You can now create a duplicate unit frame for positioning your combo points exactly where you want.
  - Frame names now use the unit frame label instead of the unit. For example, PitBull4\_Frames\_player is now PitBull4\_Frames\_Player, PitBull4\_Frames\_targettarget is now "PitBull4\_Frames\_Target's target". You'll need to update any addons (**kgPanels**) that anchor to your unit frames. You can check the name of the frame with `/framestack`.
- **Default frame positions**. Starting from scratch no longer dumps all of the frames in the middle of your screen. They will now show in a layout similar to the Blizzard layout.

---

## Download

<https://www.curseforge.com/wow/addons/pitbull-unit-frames-4-0>
