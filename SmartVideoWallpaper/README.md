# Reddit/r/Unixporn description

[https://www.reddit.com/r/unixporn/comments/cj4dfh/plasma_smart_video_wallpaper/](https://www.reddit.com/r/unixporn/comments/cj4dfh/plasma_smart_video_wallpaper/)



Now you can use a video wallpaper using few resources, this plugin pauses the video when the background desktop is not visible ;). You can see this by monitoring the process "plasmashell".

+ **Installation**:
Installation in the last plasma:
Right click on the desktop > Configure Desktop > Get New Plugins > Search "Smart video wallpaper"> Install

If you do not see the option "Get new plugins" visit this link [Smart video wallpaper](https://www.pling.com/p/1316299/) for more details.

+ **To use**:
Right click on the desktop> Configure Desktop> in Wallpaper type select "Smart video wallpaper" and select some video.

For video lock screen please use:
+ **For Video lockscreen**: [Video lockscreen](https://www.pling.com/p/1316300/)
----

Details theme:

+ **Dock**: LatteDock 
ditto menu - latte window buttons - icons task manager - title window applet - menu applet - pager - systemtray
+ **Plasma theme**: Pear Dark
+ **Look and feel**: Pear Dark [gif animation theme](https://www.reddit.com/r/unixporn/comments/cc2462/plasma_animations_for_plasma_look_and_feel/)
+ **Icons**: Aether icons 
+ **Video wallpapers sites**: taken from [desktophut](https://www.desktophut.com/), [pexels](https://www.pexels.com/search/videos/free%20wallpaper/) and [komorebi](https://github.com/cheesecakeufo/komorebi).

Some videos: 
[Seashore](https://www.pexels.com/video/waves-rushing-to-the-shore-1321208/), [waterfalls](https://www.pexels.com/video/amazing-shot-of-waterfalls-in-slow-motion-2039605/), [anime](https://www.desktophut.com/grace-lamp-anime-live-wallpaper/) and 
[dreams of the sea - i like this one, try it with sound -](https://www.desktophut.com/wake-up-anime-live-wallpaper/)

----

## Scripts 

For use "Smart Video Wallpaper" when the charger is attached use the scripts in [https://github.com/adhec/plasma_tweaks/tree/master/SmartVideoWallpaper](https://github.com/adhec/plasma_tweaks/tree/master/SmartVideoWallpaper)

#### Configuration

First set execute permission for the scripts: 

```bash
chmod +x setSmartVideoWallpaper.sh
chmod +x setImage.sh
```

**Pluggued**  SystemSettings > Notifications > Power Management > Configure events > Ac Adaptor plugged in > Run command > Select path script "setSmartVideoWallpaper.sh"

**Unpluggued**  SystemSettings > Notifications > Power Management > Configure events > Ac Adaptor unplugged > Run command > Select path script "setImageWallpaper.sh"

