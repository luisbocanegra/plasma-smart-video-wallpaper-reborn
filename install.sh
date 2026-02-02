#!/bin/sh

set -e

if [ "$(whoami)" = root ];
then
    echo "Please do not run this script as root or using sudo"
    exit 1
fi

if [ -d "build" ]; then
    rm -rf build
fi

# install plugin
cmake -B build -S .
cmake --build build
sudo cmake --install build

# remove KDE Store / kpackagetool6 install so it doesn't override the system-wide one
echo "Removing previous install (if exists) from $HOME/.local/share/plasma/wallpapers/"
rm -r "$HOME/.local/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn/" 2>/dev/null || true
echo "Done"
