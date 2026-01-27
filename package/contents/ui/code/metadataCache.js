/*
 *  Copyright 2024 Luis Bocanegra <luisbocanegra17b@gmail.com>
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

.pragma library
.import QtQuick.LocalStorage as Storage

/**
 * Initialize the metadata cache database
 * Creates the necessary table if it doesn't exist
 */
function initDatabase() {
    const db = Storage.LocalStorage.openDatabaseSync("VideoMetadataCache", "1.0", "Video metadata cache", 1000000);

    db.transaction(function(tx) {
        tx.executeSql(
            'CREATE TABLE IF NOT EXISTS metadata (' +
            'filepath TEXT PRIMARY KEY, ' +
            'file_size INTEGER, ' +
            'file_mtime INTEGER, ' +
            'video_width INTEGER, ' +
            'video_height INTEGER, ' +
            'video_codec TEXT, ' +
            'video_bitrate INTEGER, ' +
            'video_framerate REAL, ' +
            'is_hdr INTEGER, ' +
            'cached_at INTEGER' +
            ')'
        );
    });

    return db;
}

/**
 * Get file statistics (size and modification time)
 * @param {string} filepath - The file path
 * @returns {Object|null} Object with size and mtime, or null if file doesn't exist
 */
function getFileStats(filepath) {
    // We need to use Qt.io API to get file stats
    // This is a placeholder - we'll need to pass these from QML side
    // where we have access to FileInfo or similar
    return null;
}

/**
 * Check if metadata exists in cache and is still valid
 * @param {string} filepath - The video file path
 * @param {number} fileSize - Current file size in bytes
 * @param {number} fileMtime - Current file modification time (unix timestamp)
 * @returns {Object|null} Cached metadata if valid, null otherwise
 */
function getCachedMetadata(filepath, fileSize, fileMtime) {
    try {
        const db = initDatabase();
        let result = null;

        db.transaction(function(tx) {
            const rs = tx.executeSql(
                'SELECT * FROM metadata WHERE filepath = ? AND file_size = ? AND file_mtime = ?',
                [filepath, fileSize, fileMtime]
            );

            if (rs.rows.length > 0) {
                const row = rs.rows.item(0);
                result = {
                    videoWidth: row.video_width,
                    videoHeight: row.video_height,
                    videoCodec: row.video_codec,
                    videoBitRate: row.video_bitrate,
                    videoFrameRate: row.video_framerate,
                    isHdr: row.is_hdr === 1
                };
            }
        });

        return result;
    } catch (e) {
        console.error("Error getting cached metadata:", e);
        return null;
    }
}

/**
 * Save or update metadata in the cache
 * @param {string} filepath - The video file path
 * @param {number} fileSize - File size in bytes
 * @param {number} fileMtime - File modification time (unix timestamp)
 * @param {Object} metadata - Video metadata object
 */
function saveMetadata(filepath, fileSize, fileMtime, metadata) {
    try {
        const db = initDatabase();

        db.transaction(function(tx) {
            // Use REPLACE to insert or update
            tx.executeSql(
                'REPLACE INTO metadata (filepath, file_size, file_mtime, video_width, ' +
                'video_height, video_codec, video_bitrate, video_framerate, is_hdr, cached_at) ' +
                'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [
                    filepath,
                    fileSize,
                    fileMtime,
                    metadata.videoWidth || 0,
                    metadata.videoHeight || 0,
                    metadata.videoCodec || "",
                    metadata.videoBitRate || 0,
                    metadata.videoFrameRate || 0.0,
                    metadata.isHdr ? 1 : 0,
                    Date.now()
                ]
            );
        });
    } catch (e) {
        console.error("Error saving metadata to cache:", e);
    }
}

/**
 * Clear old cache entries (optional maintenance function)
 * @param {number} maxAgeMs - Maximum age in milliseconds (default: 30 days)
 */
function clearOldEntries(maxAgeMs) {
    if (!maxAgeMs) {
        maxAgeMs = 30 * 24 * 60 * 60 * 1000; // 30 days
    }

    try {
        const db = initDatabase();
        const cutoffTime = Date.now() - maxAgeMs;

        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM metadata WHERE cached_at < ?', [cutoffTime]);
        });
    } catch (e) {
        console.error("Error clearing old cache entries:", e);
    }
}

/**
 * Delete a specific cache entry
 * @param {string} filepath - The video file path
 */
function deleteCacheEntry(filepath) {
    try {
        const db = initDatabase();

        db.transaction(function(tx) {
            tx.executeSql('DELETE FROM metadata WHERE filepath = ?', [filepath]);
        });
    } catch (e) {
        console.error("Error deleting cache entry:", e);
    }
}

/**
 * Get cache statistics
 * @returns {Object} Statistics about the cache
 */
function getCacheStats() {
    try {
        const db = initDatabase();
        let stats = {
            totalEntries: 0,
            oldestEntry: null,
            newestEntry: null
        };

        db.transaction(function(tx) {
            const countRs = tx.executeSql('SELECT COUNT(*) as count FROM metadata');
            if (countRs.rows.length > 0) {
                stats.totalEntries = countRs.rows.item(0).count;
            }

            const minRs = tx.executeSql('SELECT MIN(cached_at) as oldest FROM metadata');
            if (minRs.rows.length > 0) {
                stats.oldestEntry = minRs.rows.item(0).oldest;
            }

            const maxRs = tx.executeSql('SELECT MAX(cached_at) as newest FROM metadata');
            if (maxRs.rows.length > 0) {
                stats.newestEntry = maxRs.rows.item(0).newest;
            }
        });

        return stats;
    } catch (e) {
        console.error("Error getting cache stats:", e);
        return null;
    }
}
