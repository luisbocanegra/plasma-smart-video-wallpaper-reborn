import QtQuick
import org.kde.kirigami as Kirigami
import "code/enum.js" as Enum

Item {
    id: root
    required property int mode
    required property int sunriseTime
    required property int sunsetTime
    required property int transitionDuration
    property string darkLightScheduleState
    property var dayNightPlugin: null

    readonly property color targetColor: (palette && palette.window) ? palette.window : Kirigami.Theme.backgroundColor
    readonly property int dayNightByColor: Qt.rgba(targetColor.r, targetColor.g, targetColor.b, targetColor.a).hslLightness > 0.75 ? Enum.DayNightPhase.Day : Enum.DayNightPhase.Night

    readonly property int currentPhase: {
        let phase = Enum.DayNightPhase.Unknown;
        switch (mode) {
        case Enum.DayNightCycleMode.Time:
            phase = dayNightCycleTimer.phase;
            break;
        case Enum.DayNightCycleMode.DayNightCycle:
            phase = dayNightPlugin ? dayNightPlugin.phase : Enum.DayNightPhase.Unknown;
            break;
        case Enum.DayNightCycleMode.PlasmaStyle:
            phase = root.dayNightByColor;
            break;
        case Enum.DayNightCycleMode.AlwaysNight:
            phase = Enum.DayNightPhase.Night;
            break;
        case Enum.DayNightCycleMode.AlwaysDay:
            phase = Enum.DayNightPhase.Day;
            break;
        }
        return phase;
    }

    DayNightCycleTimer {
        id: dayNightCycleTimer
        running: root.mode === Enum.DayNightCycleMode.Time
        sunriseTime: root.sunriseTime
        sunsetTime: root.sunsetTime
        transitionDuration: root.transitionDuration
    }

    Component.onCompleted: {
        let component = null;
        component = Qt.createComponent("DayNightCyclePlugin.qml");
        if (component.status === Component.Ready) {
            dayNightPlugin = component.createObject(root);
            dayNightPlugin.initialState = root.darkLightScheduleState;
            dayNightPlugin.scheduleStateChanged.connect(() => {
                if (root.darkLightScheduleState != dayNightPlugin.scheduleState) {
                    root.darkLightScheduleState = dayNightPlugin.scheduleState;
                }
            });
        } else {
            console.warn(component.errorString());
        }
    }
}
