import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../"

RowLayout {
    id: root
    readonly property string ghUser: "luisbocanegra"
    readonly property string projectName: "plasma-smart-video-wallpaper-reborn"
    readonly property string ghRepo: "https://github.com/" + ghUser + "/" + projectName
    readonly property string kofi: "https://ko-fi.com/luisbocanegra"
    readonly property string paypal: "https://www.paypal.com/donate/?hosted_button_id=Y5TMH3Z4YZRDA"
    readonly property string email: "mailto:luisbocanegra17b@gmail.com"
    readonly property string projects: "https://github.com/" + ghUser + "?tab=repositories&q=&type=source&language=&sort=stargazers"
    readonly property string kdeStore: "https://store.kde.org/p/2139746"
    readonly property string matrixRoom: "https://matrix.to/#/#kde-plasma-smart-video-wallpaper-reborn:matrix.org"

    PluginMetadataModel {
        id: pluginMetadata
    }

    Label {
        text: pluginMetadata.version
        font.weight: Font.DemiBold
    }

    Button {
        id: linksButton
        text: i18nd("plasma_wallpaper_luisbocanegra.smart.video.wallpaper.reborn", "About")
        icon.name: "info-symbolic"
        onClicked: {
            if (menu.opened) {
                menu.close();
            } else {
                menu.open();
            }
        }
        Layout.fillHeight: true
    }

    Menu {
        id: menu
        y: linksButton.height
        x: linksButton.x
        Action {
            text: "Changelog"
            onTriggered: Qt.openUrlExternally(ghRepo + "/blob/main/CHANGELOG.md")
            icon.name: "view-calendar-list-symbolic"
        }
        Action {
            text: "Releases"
            onTriggered: Qt.openUrlExternally(ghRepo + "/releases")
            icon.name: "update-none-symbolic"
        }

        Action {
            text: "Discord"
            icon.source: Qt.resolvedUrl("../../icons/discord.svg")
            onTriggered: Qt.openUrlExternally("https://discord.gg/ZqD75dzKTe")
        }

        Action {
            text: "Matrix"
            icon.source: Qt.resolvedUrl("../../icons/matrix_logo.svg")
            onTriggered: Qt.openUrlExternally(matrixRoom)
        }

        MenuSeparator {}

        Menu {
            title: "Project page"
            icon.name: "globe"
            Action {
                text: "GitHub"
                onTriggered: Qt.openUrlExternally(ghRepo)
            }
            Action {
                text: "KDE Store"
                onTriggered: Qt.openUrlExternally(kdeStore)
            }
        }

        Menu {
            title: "Issues"
            icon.name: "project-open-symbolic"
            Action {
                text: "Current issues"
                onTriggered: Qt.openUrlExternally(ghRepo + "/issues?q=sort%3Aupdated-desc+is%3Aissue+is%3Aopen")
            }
            Action {
                text: "Report a bug"
                onTriggered: Qt.openUrlExternally(ghRepo + "/issues/new?assignees=&labels=bug&projects=&template=bug_report.md&title=%5BBug%5D%3A+")
            }
            Action {
                text: "Request a feature"
                onTriggered: Qt.openUrlExternally(ghRepo + "/issues/new?assignees=&labels=enhancement&projects=&template=feature_request.md&title=%5BFeature+Request%5D%3A+")
            }
        }

        Menu {
            title: "Help"
            icon.name: "question-symbolic"
            Action {
                text: "Discussions"
                onTriggered: Qt.openUrlExternally(ghRepo + "/discussions")
            }
            Action {
                text: "Send an email"
                onTriggered: Qt.openUrlExternally(email)
            }
        }

        MenuSeparator {}

        Action {
            text: "More projects"
            onTriggered: Qt.openUrlExternally(projects)
            icon.name: "starred-symbolic"
        }
    }
}
