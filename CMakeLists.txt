cmake_minimum_required(VERSION 3.16)
project("plasma-smart-video-wallpaper-reborn")
option(INSTALL_PLASMOID "Install plasmoid" ON)

set(PROJECT_DEP_VERSION "6.0.0")
set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION "6.0.0")
set(KDE_COMPILERSETTINGS_LEVEL "5.85")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules)

# Get id and version from metadata
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/package/metadata.json METADATA)
string(JSON PLUGIN_ID GET ${METADATA} KPlugin Id)
string(JSON CUR_VERSION GET ${METADATA} KPlugin Version)
message("Plugin Id: ${PLUGIN_ID}")
message("Version: ${CUR_VERSION}")

if(INSTALL_PLASMOID)
    find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)
    plasma_install_package(package ${PLUGIN_ID} wallpapers)
endif()
