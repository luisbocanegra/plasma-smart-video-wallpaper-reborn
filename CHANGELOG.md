# Changelog

## [1.1.1](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/compare/v1.1.0...v1.1.1) (2025-02-14)


### Bug Fixes

* lock screen mode detection for all wallpaper configuring methods ([4ff5627](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/4ff56278a9bdb0a2a2a97056d39ac2b663ff7698))

## [1.1.0](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/compare/v1.0.0...v1.1.0) (2025-02-08)


### Features

* always pause video for Desktop wallpaper when screen is locked ([f61d9ca](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/f61d9ca11418c467537823b439278fc9124e4f85))
* automatically detect lock screen mode ([8942721](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/8942721c4d1d42769bd67911edbe3d0b8c26c019))
* resume from last playing video on login/lock ([328bb48](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/328bb48a536acdbd1b7124a2c856331961573afb))


### Bug Fixes

* don't remove videos below when removing a single video ([5e53f9b](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/5e53f9b7e53c2cd8fc741c988196992f87ae91f6))

## [1.0.0](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/compare/v0.4.1...v1.0.0) (2024-12-09)


### Features

* add option to play videos in random order ([877ed0a](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/877ed0ac4efde987dc251b751cb2c6a637f939ce))
* implement disabling & ordering of videos ([6705b89](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/6705b89ad1977e65b3f8866b0ff323d7884bf5bb))
* show current version and project urls in settings window ([51a10f9](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/51a10f9d626f4133152eadf31c12bcb5d2cf2647))
* split configuration into tabs ([936f974](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/936f97487134ed1e9d847bbaf8f586d4ceca9575))


### Bug Fixes

* settings crash due to binding on buttons with custom colors ([16efd8a](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/16efd8a756544d9b163a31fcc894ec10665cd51d)), closes [#43](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/issues/43)


### Miscellaneous Chores

* release 1.0.0 ([d28f0fd](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/commit/d28f0fd7ee6df17556212881ba7553135323af64))

## v0.4.1 2024-07-30 Switch to gdbus

## Fixes

- Switched from `qdbus` to `gdbus` command (from glib2), no more hunting down for the correct qdbus executable name.

## v0.4.0 2024-07-05 Major improvements

### Fixes

- Performance
  - Don't check Effects, Screen and Locked if not needed
  - Fix 2x GPU usage when blur is disabled
- Fix video playing between active window changes

### Improvements

- Added option to change animation duration
- Added cross-fade (dissolve) transition between videos (**Beta**, disabled by default)
- Global playback speed and volume control

## v0.3.0 2024-06-29 Desktop effects detection & playback improvements

### Fixes

- Fix undefined wallpaper property errors
- Fix video stopping in lock screen mode

### Improvements

- Player improvements - Switched to MediaPlayer, hopefully more stable and slightly less GPU/Video decoding usage - Show a placeholder message if there are no videos to play
- Toggle playback/blur based on active Desktop Effects (overview, grid, peek at desktop...)
- Translation support

### Other

- Added debug mode

## v0.1.1 2024-05-14 Bugfix Release

### Fixes

- Fixed widget crashing after disabling/re-enabling the screen it was on, causing effects to stop working

## v0.1.0 2024-04-10 Initial Release
