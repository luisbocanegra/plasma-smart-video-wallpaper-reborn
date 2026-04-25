import QtQuick
import org.kde.kirigami as Kirigami
import "code/enum.js" as Enum

Item {
    id: root
    required property bool enabled
    required property int mode
    required property int sunriseTime
    required property int sunsetTime

    property var dayNightPlugin: null
    property int currentTime

    property bool isDay: {
        let day = false;
        switch (mode) {
        case Enum.DayNightCycleMode.Time:
            if (dayNightPlugin) {
                day = dayNightPlugin.isDay;
                break;
            }
            day = currentTime >= root.sunriseTime && currentTime < root.sunsetTime;
            break;
        case Enum.DayNightCycleMode.PlasmaStyle:
            const targetColor = (palette && palette.window) ? palette.window : Kirigami.Theme.backgroundColor;
            day = Qt.rgba(targetColor.r, targetColor.g, targetColor.b, targetColor.a).hslLightness > 0.75;
            break;
        case Enum.DayNightCycleMode.AlwaysNight:
            day = false;
            break;
        case Enum.DayNightCycleMode.AlwaysDay:
            day = true;
            break;
        default:
            day = false;
            break;
        }
        return day;
    }

    Timer {
        id: timer
        interval: 1000
        running: root.mode === Enum.DayNightCycleMode.Time && root.dayNightPlugin === null
        repeat: true
        triggeredOnStart: true
        property bool prevEnabled: root.enabled
        onTriggered: {
            const now = new Date();
            root.currentTime = now.getHours() * 60 + now.getMinutes();
        }
    }

    Component.onCompleted: {
        let component = null;
        component = Qt.createComponent("NighttimeHelper.qml");
        if (component.status === Component.Ready) {
            dayNightPlugin = component.createObject(root);
            dayNightPlugin.initialState = configuration.DarkLightScheduleState;
            dayNightPlugin.stateChanged.connect(() => {
                if (configuration.DarkLightScheduleState != dayNightPlugin.state) {
                    configuration.DarkLightScheduleState = dayNightPlugin.state;
                    configuration.writeConfig();
                }
            });
        } else {
            console.warn(component.errorString());
        }
    }
}
