/*
 *  Copyright 2018 Rog131 <samrog131@hotmail.com>
 *  Copyright 2019 adhe   <adhemarks2@gmail.com>
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  2.010-1301, USA.
 */

import QtQuick 2.1
import QtQuick.Controls 1.0
import QtQuick.Layouts 1.3
import QtQuick.Window 2.1
import org.kde.plasma.core 2.0 as PlasmaCore

import org.kde.taskmanager 0.1 as TaskManager

Item {
	property alias screenGeometry: tasksModel.screenGeometry
	property bool playVideoWallpaper: true
	property bool currentWindowMaximized: false
	property bool isActiveWindowPinned: false

	TaskManager.VirtualDesktopInfo { id: virtualDesktopInfo }
	TaskManager.ActivityInfo { id: activityInfo }
	TaskManager.TasksModel {
		id: tasksModel
		sortMode: TaskManager.TasksModel.SortVirtualDesktop
		groupMode: TaskManager.TasksModel.GroupDisabled

		activity: activityInfo.currentActivity
		virtualDesktop: virtualDesktopInfo.currentDesktop
		screenGeometry: wallpaper.screenGeometry // Warns "Unable to assign [undefined] to QRect" during init, but works thereafter.

		filterByActivity: true
		filterByVirtualDesktop: true
		filterByScreen: true

		onActiveTaskChanged: {
			updateWindowsinfo()
		}
		onDataChanged: {
			updateWindowsinfo()
		}
		Component.onCompleted: {
			maximizedWindowModel.sourceModel = tasksModel
			fullScreenWindowModel.sourceModel = tasksModel
		}
	}
	PlasmaCore.SortFilterModel {
		id: maximizedWindowModel
		filterRole: 'IsMaximized'
		filterRegExp: 'true'
		onDataChanged: {
			updateWindowsinfo()
		}
		onCountChanged: {
			updateWindowsinfo()
		}
	}
	PlasmaCore.SortFilterModel {
		id: fullScreenWindowModel
		filterRole: 'IsFullScreen'
		filterRegExp: 'true'
		onDataChanged: {
			updateWindowsinfo()
		}
		onCountChanged: {
			updateWindowsinfo()
		}
	}

	function updateWindowsinfo() {
		// <idea> tasksModel.requestToggleMinimized(idx); FIXME: task with state maximized and minimized pause the video
		playVideoWallpaper = (fullScreenWindowModel.count + maximizedWindowModel.count) == 0 ? true : false
	}
}
