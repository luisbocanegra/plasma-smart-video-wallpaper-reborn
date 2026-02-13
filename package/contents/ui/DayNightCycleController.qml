import QtQuick
import "code/enum.js" as Enum

Item {
    id: root
    required property bool enabled
    required property int mode
    required property int sunriseTime
    required property int sunsetTime

    required property bool isLoading

    function detectDayTime(mode: int, sunriseTime: int, sunsetTime: int): bool {
      switch (root.mode) {
        case Enum.DayNightCycleMode.Time:
          const now = new Date();
          const currentTime = now.getHours() * 60 + now.getMinutes();

          return currentTime >= root.sunriseTime && currentTime < root.sunsetTime;
        case Enum.DayNightCycleMode.PlasmaStyle: return Qt.styleHints.colorScheme === Qt.ColorScheme.Light;
        case Enum.DayNightCycleMode.AlwaysNight: return false;
        case Enum.DayNightCycleMode.AlwaysDay:   return true;
      }
    }

    property bool isDay: true

    signal beforeChanged;
    signal changed;

    Timer {
        id: timer
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        property bool prevEnabled: root.enabled
        onTriggered: {
            const enableChanged = timer.prevEnabled !== root.enabled;
            if ((!enableChanged && !root.enabled) || root.isLoading) {
                return;
            }
            timer.prevEnabled = root.enabled;

            const isDay = root.detectDayTime(root.mode, root.sunriseTime, root.sunsetTime);

            if ((root.isDay != isDay) || enableChanged) {
                root.beforeChanged();
                root.isDay = isDay;
                root.changed();
            }
        }
    }

    Component.onCompleted: {
        root.isDay = root.detectDayTime(root.mode, root.sunriseTime, root.sunsetTime);
        timer.start();
    }
}
