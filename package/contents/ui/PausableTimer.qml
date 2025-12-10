// based on https://github.com/grassator/qml-utils/blob/master/qml/PausableTimer.qml
import QtQuick

Item {
    id: root
    property alias repeat: timer.repeat
    property alias running: timer.running
    property alias interval: timer.pausableInterval
    property alias triggeredOnStart: timer.triggeredOnStart
    property alias previousTimestamp: timer.previousTimestamp
    property bool useNewIntervalImmediately: false

    signal triggered

    Timer {
        id: timer
        property int pausableInterval: 1000
        property real previousTimestamp: 0
        interval: pausableInterval

        onPausableIntervalChanged: {
            if (!root.useNewIntervalImmediately) {
                return;
            }
            interval = pausableInterval;
            if (running) {
                previousTimestamp = new Date().getTime();
            } else {
                previousTimestamp = 0;
            }
        }

        onRunningChanged: {
            if (running) {
                previousTimestamp = new Date().getTime();
                return;
            }
            var timeDifference = new Date().getTime() - previousTimestamp;
            if (timeDifference < interval) {
                interval = interval - timeDifference;
            }
        }

        onTriggered: {
            previousTimestamp = new Date().getTime();
            interval = pausableInterval;
            root.triggered();
        }
    }
}
