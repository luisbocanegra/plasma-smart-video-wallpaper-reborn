# Native KWin/Wayland DPMS monitor QML plugin.
#
# An independent, system-wide QML module (org.kde.smartvideowallpaper.dpms),
# installed to KDE_INSTALL_QMLDIR - the same standard location QtQuick,
# org.kde.kirigami etc. live in - so ScreenModel.qml/config.qml can just
# `import org.kde.smartvideowallpaper.dpms 1.0` normally. No custom import
# path or relative-folder trickery needed.
#
# Optional: builds only when Qt6Qml and KWayland client dev headers are
# present. Both call sites import it dynamically via Qt.createQmlObject in a
# try/catch and fall back to command-polling when it can't be found, so this
# is safe to skip - e.g. on the KDE Store's GHNS install, which can't ship a
# compiled binary at all.
find_package(Qt6 6.6 QUIET COMPONENTS Qml)
find_package(KWayland QUIET)

if(NOT Qt6Qml_FOUND OR NOT KWayland_FOUND)
    message(STATUS "Qt6Qml or KWayland not found - skipping native DPMS monitor plugin (screen-off detection will fall back to polling)")
    return()
endif()

include(ECMQmlModule)

add_library(dpmsmonitorplugin)
ecm_add_qml_module(dpmsmonitorplugin
    URI "org.kde.smartvideowallpaper.dpms"
    VERSION 1.0
    GENERATE_PLUGIN_SOURCE
)

target_sources(dpmsmonitorplugin PRIVATE
    dpmsmonitor.cpp
    dpmsmonitor.h
)
target_link_libraries(dpmsmonitorplugin PRIVATE Qt6::Qml Plasma::KWaylandClient)

ecm_finalize_qml_module(dpmsmonitorplugin DESTINATION ${KDE_INSTALL_QMLDIR})

# ecm_finalize_qml_module's auto-computed INSTALL_RPATH for the generated
# plugin target is off by one directory level here (verified: it resolves to
# .../qt6/lib/x86_64-linux-gnu instead of .../lib/x86_64-linux-gnu, so the
# plugin can't find the backing dpmsmonitorplugin library it links against).
# Compute and set the correct $ORIGIN-relative path ourselves instead of
# relying on it.
file(RELATIVE_PATH dpms_plugin_rpath
    "${CMAKE_INSTALL_PREFIX}/${KDE_INSTALL_QMLDIR}/org/kde/smartvideowallpaper/dpms"
    "${CMAKE_INSTALL_PREFIX}/${KDE_INSTALL_LIBDIR}"
)
set_target_properties(dpmsmonitorpluginplugin PROPERTIES
    INSTALL_RPATH "$ORIGIN/${dpms_plugin_rpath}"
)

if(INSTALL_WALLPAPER)
    install(TARGETS dpmsmonitorplugin ${KDE_INSTALL_TARGETS_DEFAULT_ARGS})
endif()
