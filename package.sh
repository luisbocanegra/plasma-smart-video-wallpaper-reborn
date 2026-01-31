#!/bin/sh

# Remove the build directory if it exists
if [ -d "build" ]; then
    rm -rf build
fi

# skip building/installing
cmake -B build -S . -DINSTALL_WALLPAPER=OFF -DPACKAGE_WALLPAPER=ON

# package plasmoid
cmake --build build
