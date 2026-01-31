# SPDX-FileCopyrightText: 2020 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
#
# SPDX-License-Identifier: BSD-3-Clause

find_program(GETTEXT_MSGFMT_EXECUTABLE msgfmt)

if (NOT GETTEXT_MSGFMT_EXECUTABLE)
    message(WARNING "-- msgfmt: not found. Translations will not be installed")
else ()
    set(catalogname plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn)
    add_custom_target(translations ALL)

    file(GLOB PO_FILES *.po)

    foreach (_po ${PO_FILES})
        get_filename_component(_filename ${_po} NAME)
        string(REGEX REPLACE "^${catalogname}_?" "" _langCode ${_filename})
        string(REGEX REPLACE "\\.po$" "" _langCode ${_langCode})

        if (_langCode)
            if (_langCode EQUAL "template")
                continue()
            endif()
            get_filename_component(_lang ${_po} NAME_WE)
            set(_gmo ${CMAKE_CURRENT_BINARY_DIR}/${_lang}.gmo)

            add_custom_command(OUTPUT ${_gmo}
                COMMAND ${GETTEXT_MSGFMT_EXECUTABLE} --check -o ${_gmo} ${_po}
                DEPENDS ${_po}
                VERBATIM)

            add_custom_target(${_langCode} ALL DEPENDS ${_gmo})

            install(FILES ${_gmo}
                DESTINATION ${KDE_INSTALL_DATADIR}/locale/${_langCode}/LC_MESSAGES/
                RENAME ${catalogname}.mo)
        endif()
    endforeach()
endif()
