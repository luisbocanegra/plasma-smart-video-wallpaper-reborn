#!/bin/sh
if [ -d "build" ]; then
    rm -rf build
fi

# Install wallpaper for current user
cmake -B build/wallpaper -S . -DINSTALL_WALLPAPER=ON -DCMAKE_INSTALL_PREFIX="$HOME/.local"
cmake --build build/wallpaper
cmake --install build/wallpaper
# CMakeLists.txt plasma_install_package does't copy executable permission
chmod 700 "$HOME/.local/share/plasma/wallpapers/luisbocanegra.smart.video.wallpaper.reborn/contents/ui/tools/gdbus_get_signal.sh"

# Install plugin system-wide (required for qml modules)
cmake -B build/plugin -S . -DBUILD_PLUGIN=ON -DCMAKE_INSTALL_PREFIX=/usr
cmake --build build/plugin
sudo cmake --install build/plugin
