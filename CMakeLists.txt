cmake_minimum_required(VERSION 3.16)
project("plasma-smart-video-wallpaper-reborn")
option(BUILD_PLUGIN "Build the plugin" OFF)
option(INSTALL_WALLPAPER "Install wallpaper" OFF)
option(PACKAGE_WALLPAPER "Package wallpaper" OFF)

set(PROJECT_DEP_VERSION "6.0.0")
set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION "6.0.0")
set(KDE_COMPILERSETTINGS_LEVEL "5.85")
set(CMAKE_EXPORT_COMPILE_COMMANDS 1)

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

# Get id and version from metadata
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/package/metadata.json METADATA)
string(JSON PLUGIN_ID GET ${METADATA} KPlugin Id)
string(JSON CUR_VERSION GET ${METADATA} KPlugin Version)
message("Plugin Id: ${PLUGIN_ID}")
message("Version: ${CUR_VERSION}")

if(INSTALL_WALLPAPER)
    find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)
    plasma_install_package(package ${PLUGIN_ID} wallpapers)
endif()

if(PACKAGE_WALLPAPER)
    # generate wallpaper package
    set(WALLPAPER_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}-v${CUR_VERSION}.zip")
    add_custom_target(wallpaper ALL
        COMMAND rm -rf "${WALLPAPER_FILE}"
        COMMAND ${CMAKE_COMMAND} -E chdir ${CMAKE_CURRENT_SOURCE_DIR}/package zip -r ${WALLPAPER_FILE} ./
        COMMENT "Generating ${WALLPAPER_FILE}"
    )
endif()

if(BUILD_PLUGIN)
    add_subdirectory(plugin)
endif()
