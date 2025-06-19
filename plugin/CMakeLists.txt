set(PLUGIN_NAME "mpvplugin")
set(LIB_NAME "mpvitem")

include(KDEInstallDirs)
include(KDECMakeSettings)

find_package(Qt6 COMPONENTS Core Quick REQUIRED)
find_package(MpvQt)

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_NAME}.cpp ${LIB_NAME}.cpp mpvproperties.h)

target_link_libraries(${PLUGIN_NAME}
    Qt6::Core
    Qt6::Quick
    Qt6::Qml
    MpvQt::MpvQt
)

install(TARGETS ${PLUGIN_NAME} DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/luisbocanegra/${LIB_NAME})
install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/luisbocanegra/${LIB_NAME})
