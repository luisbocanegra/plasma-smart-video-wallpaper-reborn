import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../" as Root

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
    property string wallpaperVersion

    Root.RunCommand {
        id: runCommand
        onExited: (cmd, exitCode, exitStatus, stdout, stderr) => {
            if (exitCode !== 0) {
                root.wallpaperVersion = stderr;
                console.log(cmd, stderr);
            } else {
                try {
                    root.wallpaperVersion = JSON.parse(stdout).KPlugin.Version;
                } catch (e) {
                    console.log(e);
                    root.wallpaperVersion = e;
                }
            }
        }
    }

    Component.onCompleted: {
        const metaDataFile = Qt.resolvedUrl("../../../").toString().substring(7) + "metadata.json";
        console.log(metaDataFile);
        runCommand.run(`cat "${metaDataFile}"`);
    }

    Item {
        Layout.fillWidth: true
    }
    RowLayout {
        Layout.alignment: Qt.AlignRight
        Label {
            text: i18n("Version:")
        }
        Label {
            text: wallpaperVersion
            font.weight: Font.DemiBold
        }
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
            text: "Matrix chat"
            icon.name: Qt.resolvedUrl("../../icons/matrix_logo.svg").toString().replace("file://", "")
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

        Menu {
            title: "Donate"
            icon.name: "love"
            Action {
                text: "Ko-fi"
                onTriggered: Qt.openUrlExternally(kofi)
            }
            Action {
                text: "Paypal"
                onTriggered: Qt.openUrlExternally(paypal)
            }
            Action {
                text: "GitHub sponsors"
                onTriggered: Qt.openUrlExternally("https://github.com/sponsors/" + ghUser)
            }
        }

        MenuSeparator {}

        Action {
            text: "More projects"
            onTriggered: Qt.openUrlExternally(projects)
            icon.name: "starred-symbolic"
        }
    }
    ToolButton {
        id: linksButton
        icon.name: "application-menu"
        onClicked: {
            if (menu.opened) {
                menu.close();
            } else {
                menu.open();
            }
        }
    }
}
