set(PLUGIN_NAME "nighttimeplugin")
set(LIB_NAME "nighttime")

add_library(${PLUGIN_NAME} SHARED ${PLUGIN_NAME}.cpp ${LIB_NAME}.cpp)
find_package(Qt6 ${QT_MIN_VERSION} REQUIRED COMPONENTS Qml Gui)
find_package(KNightTime ${PROJECT_DEP_VERSION} CONFIG REQUIRED)
find_package(KF6 ${KF6_MIN_VERSION} REQUIRED COMPONENTS KCMUtils)

target_link_libraries(${PLUGIN_NAME}
    Qt6::Qml
    Qt6::Gui
    KF6::KCMUtils
    KNightTime
)

install(TARGETS ${PLUGIN_NAME} DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/luisbocanegra/svwr/${LIB_NAME})
install(FILES qmldir DESTINATION ${KDE_INSTALL_QMLDIR}/com/github/luisbocanegra/svwr/${LIB_NAME})
