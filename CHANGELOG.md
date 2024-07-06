# Changelog

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
