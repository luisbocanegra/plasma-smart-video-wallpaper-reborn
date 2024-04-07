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

## Improve performance by enabling Hardware Video Acceleration

> Hardware video acceleration makes it possible for the video card to decode/encode video, thus offloading the CPU and saving power.

Consult your distribution or the [Arch Wiki instructions on how to do this](https://wiki.archlinux.org/title/Hardware_video_acceleration).
Make sure to also enable it for [FFmpeg](https://wiki.archlinux.org/title/FFmpeg#Hardware_video_acceleration) and [GStreamer](https://wiki.archlinux.org/title/GStreamer#Hardware_video_acceleration).

To verify if is working with an Intel GPU install `intel-gpu-tools` and run `sudo intel_gpu_top`, you should see a non-zero value for the Video engine.

## Black video or Plasma crashes

To recover from crash remove the videos from the configuration using this command below in terminal/tty, then reboot

```sh
sed -i 's/^VideoUrls=.*$/VideoUrls=/g' $HOME/.config/plasma-org.kde.plasma.desktop-appletsrc $HOME/.config/kscreenlockerrc
```

and restart plasmashell `systemctl --user restart plasma-plasmashell.service` or `plasmashell --replace` if the former doesn't work.

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
    sudo pacman -S qt6-multimedia gst-libav --needed
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

1. Run `journalctl -f` and `sudo dmesg -wHT` in separate terminals
2. While both commands are running switch from the Image wallpaper plugin to video wallpaper
3. Then stop both commands
4. If needed, remove the plugin configuration (`sed` command above)
5. Get your system information from `kinfo` command or from **System settings** > **About this System**
6. Save the file from [here](https://gist.github.com/luisbocanegra/cb758ee5f57a9e7c2838b1db349b635a) as **test.qml**. Run the test qml with from terminal `QSG_INFO=1 QT_LOGGING_RULES="qml.debug=true" qml6 test.qml`, this file will play some public test videos from internet in fullscreen. If it doesn't crash immediately, try clicking the pause/next buttons a bunch of times.
7. Create a new [new issue](https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/issues/new) with the output of the commands from steps 1,5,6 including wether running the **test.qml** also crashes or not.

## Acknowledgements

This project a rewrite based on [adhec/Smart Video Wallpaper](https://github.com/adhec/plasma_tweaks/tree/master/SmartVideoWallpaper) and [PeterTucker/smartER-video-wallpaper](https://github.com/PeterTucker/smartER-video-wallpaper) projects.
