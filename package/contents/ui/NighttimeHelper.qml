import QtQuick
import com.github.luisbocanegra.svwr.nighttime 1.0

Item {
    property alias isDay: dayNight.isDay
    property alias initialState: dayNight.initialState
    property alias state: dayNight.state
    DayNight {
        id: dayNight
    }
}
