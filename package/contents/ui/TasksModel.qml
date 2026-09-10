import QtQuick
import org.kde.taskmanager 0.1 as TaskManager
import org.kde.plasma.plasmoid

Item {
    id: root
    property var screenGeometry
    property bool activeExists: false
    property bool maximizedExists: false
    property bool fullscreenExists: false
    property bool visibleExists: false
    property var abstractTasksModel: TaskManager.AbstractTasksModel
    property var isMaximized: abstractTasksModel.IsMaximized
    property var isActive: abstractTasksModel.IsActive
    property var isWindow: abstractTasksModel.IsWindow
    property var isFullScreen: abstractTasksModel.IsFullScreen
    property var isMinimized: abstractTasksModel.IsMinimized
    property bool filterByActive: false
    property bool filterByScreen: false
    property bool trackLastActive: false
    readonly property string currentActivity: activityInfo.currentActivity

    function getTopTask() {
        let highestTask = null;
        let maxStackingOrder = -1;
        for (var i = 0; i < tasksModel.count; i++) {
            const currentTask = tasksModel.index(i, 0);
            if (currentTask === undefined || !tasksModel.data(currentTask, isWindow))
                continue;

            const stackingOrder = tasksModel.data(currentTask, abstractTasksModel.StackingOrder);
            if (stackingOrder > maxStackingOrder) {
                maxStackingOrder = stackingOrder;
                highestTask = currentTask;
            }
        }
        return highestTask;
    }

    function updateWindowsInfo() {
        let activeCount = 0;
        let visibleCount = 0;
        let maximizedCount = 0;
        let fullscreenCount = 0;
        for (var i = 0; i < tasksModel.count; i++) {
            const currentTask = tasksModel.index(i, 0);
            if (currentTask === undefined || !tasksModel.data(currentTask, isWindow))
                continue;

            if (filterByActive && !tasksModel.data(currentTask, isActive))
                continue;

            visibleCount += 1;
            if (tasksModel.data(currentTask, isMaximized))
                maximizedCount += 1;

            if (tasksModel.data(currentTask, isFullScreen))
                fullscreenCount += 1;
        }

        let _activeExists = tasksModel.data(tasksModel.activeTask, isActive) || false;
        let _activeTask = null;
        let _maximizedExists = maximizedCount > 0;
        let _fullscreenExists = fullscreenCount > 0;
        let _visibleExists = visibleCount > 0;
        if (filterByActive && _activeExists) {
            _activeTask = tasksModel.activeTask;
        }

        if (!_activeTask && trackLastActive) {
            _activeTask = getTopTask();
            _activeExists = Boolean(_activeTask);
        }

        if (_activeTask) {
            _maximizedExists = tasksModel.data(_activeTask, isMaximized) || false;
            _fullscreenExists = tasksModel.data(_activeTask, isFullScreen) || false;
            _visibleExists = _activeExists;
        }

        activeExists = _activeExists;
        fullscreenExists = _fullscreenExists;
        maximizedExists = _maximizedExists;
        visibleExists = _visibleExists;
    }

    Connections {
        target: Plasmoid.configuration
        function onValueChanged() {
            Qt.callLater(root.update);
        }
    }

    TaskManager.VirtualDesktopInfo {
        id: virtualDesktopInfo
    }

    TaskManager.ActivityInfo {
        id: activityInfo
    }

    TaskManager.TasksModel {
        id: tasksModel

        sortMode: TaskManager.TasksModel.SortVirtualDesktop
        groupMode: TaskManager.TasksModel.GroupDisabled
        activity: activityInfo.currentActivity
        screenGeometry: root.screenGeometry
        filterByScreen: root.filterByScreen
        filterByActivity: true
        filterMinimized: true
        onDataChanged: {
            Qt.callLater(root.update);
        }
        onCountChanged: {
            Qt.callLater(root.update);
        }
        Component.onCompleted: {
            // Plasma 6.7 per-output virtual desktops
            // https://invent.kde.org/plasma/plasma-desktop/-/merge_requests/3427
            if (tasksModel.hasOwnProperty("filterByCurrentVirtualDesktop")) {
                tasksModel.filterByCurrentVirtualDesktop = true;
            } else {
                tasksModel.virtualDesktop = Qt.binding(function () {
                    return virtualDesktopInfo.currentDesktop;
                });
                tasksModel.filterByVirtualDesktop = true;
            }
        }
    }

    function update() {
        if (!updateTimer.running) {
            updateTimer.start();
        }
    }

    Timer {
        id: updateTimer

        interval: 5
        onTriggered: {
            root.updateWindowsInfo();
        }
    }
}
