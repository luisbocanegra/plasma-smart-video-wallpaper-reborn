/*
 *  Copyright 2026 Luis Bocanegra <luisbocanegra17b@gmail.com>
 *  Copyright 2026 John Franklin <franklin@sentaidigital.com>
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

import QtQuick

QtObject {
    id: root

    /**
     * Get file statistics using async command execution
     * @param {string} filepath - The file path
     * @param {function} callback - Callback function(fileInfo) where fileInfo = {size, mtime}
     */
    function getFileStatsAsync(filepath, callback) {
        // Extract local path from file:// URL if present
        let cleanPath = filepath;
        if (filepath.toString().startsWith("file://")) {
            cleanPath = filepath.toString().substring(7);
        }

        // Use stat command to get file info
        // Format: size mtime (in seconds)
        const cmd = `stat -c "%s %Y" "${cleanPath}" 2>/dev/null || stat -f "%z %m" "${cleanPath}" 2>/dev/null`;

        // Create a temporary RunCommand instance
        const runCmdComponent = Qt.createComponent("RunCommand.qml");
        if (runCmdComponent.status !== Component.Ready) {
            console.error("Error loading RunCommand component:", runCmdComponent.errorString());
            if (callback) callback(null);
            return;
        }

        const runCmd = runCmdComponent.createObject(root);
        runCmd.exec(cmd, function(result) {
            const parts = result.stdout.trim().split(/\s+/);
            if (parts.length >= 2) {
                const fileInfo = {
                    size: parseInt(parts[0], 10),
                    mtime: parseInt(parts[1], 10)
                };
                if (callback) callback(fileInfo);
            } else {
                if (callback) callback(null);
            }
            runCmd.destroy();
        });
    }

    /**
     * Synchronous fallback - gets file stats using a hash of the filepath
     * This is a simplified version that just returns dummy stats for caching purposes
     * @param {string} filepath - The file path
     * @returns {Object} Object with size=0 and mtime based on current time
     */
    function getFileStats(filepath) {
        // For synchronous operation, we can't actually get the real stats
        // So we return a hash-based approach
        // This means cache will be based on filepath only
        return {
            size: 0,
            mtime: 0
        };
    }
}
