# Smart Video Wallpaper Reborn

Wallpaper plugin to play videos on your desktop.

https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/assets/15076387/be5b8edf-f33f-4b8c-a1d0-1a00211a4784

## Features

- Play a single video or slideshow of videos
- Enable/disable video sound
- Lock screen support
- Pause Video conditions
  - Maximized or fullscreen window
  - Active window
  - Window is present
  - Never
- Blur
  - Conditions
    - Maximized or fullscreen window
    - Active window
    - Window is present
    - Video is paused
    - Always
    - Never
  - Radius
- Battery
  - Pauses video
  - Disables Blur
- Pause video when screen is Off/Locked

## Improve performance by enabling Hardware Video Acceleration

> Hardware video acceleration makes it possible for the video card to decode/encode video, thus offloading the CPU and saving power.

Consult your distribution or the [Arch Wiki instructions on how to do this](https://wiki.archlinux.org/title/Hardware_video_acceleration).
Make sure to also enable it for [FFmpeg](https://wiki.archlinux.org/title/FFmpeg#Hardware_video_acceleration) and [GStreamer](https://wiki.archlinux.org/title/GStreamer#Hardware_video_acceleration).

To verify if is working with an Intel GPU install `intel-gpu-tools` and run `sudo intel_gpu_top`, you should see a non-zero value for the Video engine.

## Black video or Plasma crashes

If the video doesn't show, fails to loop or crashes your Desktop, try switching the Qt Media backend to `gstreamer` (default is `ffmpeg`):

1. Create the file `~/.config/plasma-workspace/env/qt-media-backend.sh`

    ```sh
    #!/bin/bash
    export QT_MEDIA_BACKEND=gstreamer
    ```

2. Reboot re-login to apply the changes

## Acknowledgements

This project a rewrite based on [adhec/Smart Video Wallpaper](https://github.com/adhec/plasma_tweaks/tree/master/SmartVideoWallpaper) and [PeterTucker/smartER-video-wallpaper](https://github.com/PeterTucker/smartER-video-wallpaper) projects.
