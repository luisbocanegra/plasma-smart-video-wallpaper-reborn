# Smart Video Wallpaper Reborn

Plasma 6 Wallpaper plugin to play videos on your Desktop/Lock Screen.

https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/assets/15076387/45f32fde-a1b4-406f-8aeb-221bb071a6b9

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

## Installing

Install the plugin from the KDE Store [Plasma 6 version](https://store.kde.org/p/2139746)

1. **Right click on the Desktop** > **Configure Desktop and Wallpaper...** > **Get New Plugins**
2. **Search** for "**Smart Video Wallpaper Reborn**", install and set it as your wallpaper.
3. Click on **Add new videos** pick your video(s) and apply.

To set as Lock Screen wallpaper go to **System settings** > **Screen Locking** > **Appearance: Configure...**

## This plugin requires correctly setup Media codecs

- [Fedora (RPM Fusion repo)](https://rpmfusion.org/Howto/Multimedia)
- [openSUSE (Packman repositories)](https://en.opensuse.org/SDB:Installing_codecs_from_Packman_repositories)

## Improve performance by enabling Hardware Video Acceleration

> Hardware video acceleration makes it possible for the video card to decode/encode video, thus offloading the CPU and saving power.

First, verify acceleration you can install and run [nvtop](https://github.com/Syllo/nvtop), it will show a decoding usage when Hardware acceleration is working:

![nvtop hw video decoding](screenshots/nvtop-hw-decoding.png)

If `nvtop` is not available you can use:

- `intel_gpu_top` from [intel-gpu-tools](https://gitlab.freedesktop.org/drm/igt-gpu-tools) for Intel GPU (video engine)
- `nvidia-smi dmon` for Nvidia GPU (dec column)
- [amdgpu_top](https://github.com/Umio-Yasuno/amdgpu_top) for AMD GPU (dec column)

If there is no decoding usage you will have to enable video acceleration in your system

- [Arch](https://wiki.archlinux.org/title/Hardware_video_acceleration).
- [Fedora](https://fedoraproject.org/wiki/Firefox_Hardware_acceleration#Video_decoding)
- Additional setup for [FFmpeg](https://wiki.archlinux.org/title/FFmpeg#Hardware_video_acceleration) and [GStreamer](https://wiki.archlinux.org/title/GStreamer#Hardware_video_acceleration) may be needed.

## Black video or Plasma crashes

There may be some issues with Qt Causing crashes on AMD GPUs, this is currently being investigated in [QTBUG-124586 - QML video media player segmentation fault on AMD GPU with FFMPEG](https://bugreports.qt.io/browse/QTBUG-124586) and [Black screen with gstreamer as Qt Media backend (Recent KDE Neon update)](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/issues/8)

To recover from crash remove the videos from the configuration using this command below in terminal/tty

```sh
sed -i 's/^VideoUrls=.*$/VideoUrls=/g' $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/kscreenlockerrc
```

then reboot or restart plasmashell `systemctl --user restart plasma-plasmashell.service` or `plasmashell --replace` if the former doesn't work.

### Possible solution, switching to GStreamer as Qt Media backend

1. Install the media codecs and qt6-multimedia and gstreamer packages if you don't have them:

    **openSUSE**

    ```sh
    sudo zypper install opi
    opi codecs
    sudo zypper install qt6-multimedia gstreamer-plugins-libav
    ```

    **Arch**

    ```sh
    sudo pacman -S qt6-multimedia qt6-multimedia-gstreamer gst-libav --needed
    ```

    If you need extra codecs see https://wiki.archlinux.org/title/GStreamer

    **PRs to expand this list are welcome :)**

2. **Reboot**

3. If after that the video doesn't play, fails to loop or crashes your Desktop (remove the plugin configuration using `sed` command above if needed), try switching the Qt Media backend to `gstreamer` (default is `ffmpeg`):

    Create the file `~/.config/plasma-workspace/env/qt-media-backend.sh`

    ```sh
    #!/bin/bash
    export QT_MEDIA_BACKEND=gstreamer
    ```

4. Reboot again to apply the changes, and verify it was correctly set by running `echo $QT_MEDIA_BACKEND`

**Video still doesn't play/keeps crashing?** Follow these steps

1. Run `journalctl -f > journal.txt` and `sudo dmesg -wHT > dmesg.txt` in separate terminals
2. While both commands are running switch from the Image wallpaper plugin to video wallpaper and reproduce the issue
3. Then stop both commands
4. If needed, remove the plugin configuration (`sed` command above)
5. Get your system information from `kinfo > sysinfo.txt` command or from **System settings** > **About this System**
6. Save the file from [here](https://gist.github.com/luisbocanegra/cb758ee5f57a9e7c2838b1db349b635a) as **test.qml**. Run the test qml with from terminal `QT_FFMPEG_DEBUG=1 QSG_INFO=1 QT_LOGGING_RULES="*.debug=true" qml6 test.qml 2> qml_video_test_log.txt `, (qml6 may be qml-qt6 or /usr/lib/qt6/bin/qml please confirm is qt6 one with --version) this file will play some public test videos from internet in fullscreen. If it doesn't crash immediately, try clicking the pause/next buttons a bunch of times.
7. Run `lspci -k | grep -EA3 'VGA|3D|Display' > lspci.txt`
8. Create a new [new issue](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/issues/new) describing the problem and how to reproduce, and attach those files including wether running the **test.qml** also crashes or not.

## Acknowledgements

This project a rewrite based on [adhec/Smart Video Wallpaper](https://github.com/adhec/plasma_tweaks/tree/master/SmartVideoWallpaper) and [PeterTucker/smartER-video-wallpaper](https://github.com/PeterTucker/smartER-video-wallpaper) projects.
