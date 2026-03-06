import QtQuick
import com.github.luisbocanegra.svwr.nighttime 1.0

Item {
    property alias isDay: dayNight.isDay
    DayNight {
        id: dayNight
    }
}
