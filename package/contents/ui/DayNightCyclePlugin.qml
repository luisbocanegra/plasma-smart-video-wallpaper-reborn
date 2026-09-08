import QtQuick
import com.github.luisbocanegra.svwr 1.0

Item {
    readonly property alias phase: dayNight.phase
    readonly property alias scheduleState: dayNight.state
    property alias initialState: dayNight.initialState
    DayNight {
        id: dayNight
    }
}
