import QtQuick
import "code/enum.js" as Enum

Timer {
    id: root
    required property int sunriseTime
    required property int sunsetTime
    required property int transitionDuration

    property int currentTime

    readonly property int phase: {
        const sunriseStart = sunriseTime;
        const sunriseEnd = (sunriseTime + transitionDuration) % (24 * 60);
        const sunsetStart = sunsetTime;
        const sunsetEnd = (sunsetTime + transitionDuration) % (24 * 60);

        if (isInInterval(currentTime, sunriseStart, sunriseEnd)) {
            return Enum.DayNightPhase.Sunrise;
        } else if (isInInterval(currentTime, sunsetStart, sunsetEnd)) {
            return Enum.DayNightPhase.Sunset;
        } else if (isInInterval(currentTime, sunriseEnd, sunsetStart)) {
            return Enum.DayNightPhase.Day;
        } else {
            return Enum.DayNightPhase.Night;
        }
    }

    function isInInterval(time, start, end) {
        if (start < end) {
            return time >= start && time < end;
        } else {
            return time >= start || time < end;
        }
    }

    interval: 1000
    repeat: true
    triggeredOnStart: true
    onTriggered: {
        const now = new Date();
        currentTime = now.getHours() * 60 + now.getMinutes();
    }
}
