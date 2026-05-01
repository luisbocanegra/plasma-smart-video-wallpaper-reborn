import QtQuick
import com.github.luisbocanegra.svwr.nighttime 1.0

Item {
    readonly property alias phase: dayNight.phase
    readonly property alias state: dayNight.state
    property alias initialState: dayNight.initialState
    DayNight {
        id: dayNight
    }
}
