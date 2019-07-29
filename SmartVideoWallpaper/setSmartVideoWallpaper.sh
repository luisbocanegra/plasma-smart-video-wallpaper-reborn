#!/bin/bash
dbus-send --session --dest=org.kde.plasmashell --type=method_call /PlasmaShell org.kde.PlasmaShell.evaluateScript \
'string: var Desktops = desktops(); for (i=0;i<Desktops.length;i++) 
{ d = Desktops[i]; d.wallpaperPlugin = "smartvideowallpaper";        
d.currentConfigGroup = Array("Wallpaper","smartvideowallpaper","General");
}'