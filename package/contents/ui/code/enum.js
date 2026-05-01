const PlaybackOverride = {
  Play: 0,
  Pause: 1,
  Default: 2,
};

const MuteOverride = {
  Mute: 0,
  Unmute: 1,
  Default: 2,
};

const ChangeWallpaperMode = {
  Never: 0,
  Slideshow: 1,
  OnATimer: 2,
};

const DayNightPhase = {
  Night: 0,
  Sunrise: 1,
  Day: 2,
  Sunset: 3,
  Unknown: 4, // or unset
};

const DayNightCycleMode = {
  Disabled: 0,
  DayNightCycle: 1,
  Time: 2,
  PlasmaStyle: 3,
  AlwaysDay: 4,
  AlwaysNight: 5,
};

const PauseMode = {
  MaximizedOrFullScreen: 0,
  ActiveWindowPresent: 1,
  WindowVisible: 2,
  Never: 3
};

const BlurMode = {
  MaximizedOrFullScreen: 0,
  ActiveWindowPresent: 1,
  WindowVisible: 2,
  VideoPaused: 3,
  Always: 4,
  Never: 5
};

const MuteMode = {
  MaximizedOrFullScreen: 0,
  ActiveWindowPresent: 1,
  WindowVisible: 2,
  AnotherAppPlayingAudio: 3,
  Never: 4,
  Always: 5,
};
