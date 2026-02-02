cmake_minimum_required(VERSION 3.16)
project("plasma-smart-video-wallpaper-reborn")
option(INSTALL_WALLPAPER "Install wallpaper" ON)
option(PACKAGE_WALLPAPER "Package wallpaper" OFF)

set(PROJECT_DEP_VERSION "6.0.0")
set(QT_MIN_VERSION "6.6.0")
set(KF6_MIN_VERSION "6.0.0")
set(KDE_COMPILERSETTINGS_LEVEL "5.85")

find_package(ECM ${KF6_MIN_VERSION} REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs)
include(KDECMakeSettings)

find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS
    I18n
)

# Get id and version from metadata
file(READ ${CMAKE_CURRENT_SOURCE_DIR}/package/metadata.json METADATA)
string(JSON PLUGIN_ID GET ${METADATA} KPlugin Id)
string(JSON CUR_VERSION GET ${METADATA} KPlugin Version)
message("Plugin Id: ${PLUGIN_ID}")
message("Version: ${CUR_VERSION}")

if(INSTALL_WALLPAPER)
    find_package(Plasma ${PROJECT_DEP_VERSION} REQUIRED)
    plasma_install_package(package ${PLUGIN_ID} wallpapers)
    add_subdirectory(translate)
endif()

if(PACKAGE_WALLPAPER)
    # Translations
    # As of 6.5.5 translations of wallpapers from KDE Store are not picked up by Plasma
    #   https://github.com/luisbocanegra/plasma-smart-video-wallpaper-reborn/issues/84
    #   upstream report https://bugs.kde.org/show_bug.cgi?id=501400
    # But this is here for when they finally support that
    add_custom_target(translations ALL
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMAND ./bin/i18n compile
        COMMENT "Compiling translations"
    )

    # wallpaper package
    set(PACKAGE_FILE "${CMAKE_CURRENT_SOURCE_DIR}/${PROJECT_NAME}-v${CUR_VERSION}.tar.gz")
    add_custom_target(wallpaper ALL
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/package
        COMMAND rm -f "${PACKAGE_FILE}" || true
        COMMAND tar -cf "${PACKAGE_FILE}" --auto-compress .
        COMMENT "Generating ${PACKAGE_FILE}"
    )

    add_dependencies(wallpaper translations)
endif()
