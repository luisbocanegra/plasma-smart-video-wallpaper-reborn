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

import QtQuick
import QtMultimedia
import "code/utils.js" as Utils
import "code/metadataCache.js" as MetadataCache

/**
 * Helper component for loading and caching video metadata
 * Usage: Create an instance and call loadMetadata(filepath, callback)
 */
QtObject {
    id: root

    // Properties
    property bool debugEnabled: false
    property FileStatHelper fileStatHelper: null

    // Signals
    signal metadataLoaded(string filepath, var metadata)
    signal metadataError(string filepath, string error)

    /**
     * Load metadata for a video file
     * First checks cache, then loads from file if needed
     * @param {string} filepath - Path to the video file
     * @param {function} callback - Callback function(metadata) where metadata contains video properties
     */
    function loadMetadata(filepath, callback) {
        if (!filepath || filepath === "") {
            if (callback) callback(null);
            return;
        }

        // Try to load from cache first
        tryLoadFromCache(filepath, function(cachedMetadata) {
            if (cachedMetadata) {
                // Cache hit
                if (callback) callback(cachedMetadata);
                metadataLoaded(filepath, cachedMetadata);
            } else {
                // Cache miss - load from file
                loadFromFile(filepath, function(extractedMetadata) {
                    if (extractedMetadata) {
                        if (callback) callback(extractedMetadata);
                        metadataLoaded(filepath, extractedMetadata);
                    } else {
                        if (callback) callback(null);
                        metadataError(filepath, "Failed to load metadata");
                    }
                });
            }
        });
    }

    /**
     * Try to load metadata from cache
     * @param {string} filepath - Path to the video file
     * @param {function} callback - Callback function(metadata or null)
     */
    function tryLoadFromCache(filepath, callback) {
        if (!fileStatHelper) {
            if (debugEnabled) {
                console.log("FileStatHelper not available, skipping cache");
            }
            if (callback) callback(null);
            return;
        }

        // Get file stats asynchronously
        fileStatHelper.getFileStatsAsync(filepath, function(fileInfo) {
            if (!fileInfo) {
                // No file info available, can't use cache
                if (callback) callback(null);
                return;
            }

            // Try to get cached metadata
            const cachedMetadata = MetadataCache.getCachedMetadata(
                filepath,
                fileInfo.size,
                fileInfo.mtime
            );

            if (cachedMetadata) {
                if (debugEnabled) {
                    console.log("Using cached metadata for:", filepath);
                }
                if (callback) callback(cachedMetadata);
            } else {
                // Cache miss
                if (debugEnabled) {
                    console.log("Cache miss for:", filepath);
                }
                if (callback) callback(null);
            }
        });
    }

    /**
     * Load metadata from video file
     * @param {string} filepath - Path to the video file
     * @param {function} callback - Callback function(metadata or null)
     */
    function loadFromFile(filepath, callback) {
        // Create a temporary MediaPlayer to extract metadata using inline QML
        const qmlString = `
            import QtQuick
            import QtMultimedia
            import "code/utils.js" as Utils

            MediaPlayer {
                id: metadataLoader
                audioOutput: AudioOutput { muted: true }

                property var extractCallback: null
                property string targetFilepath: ""
                property bool debugMode: false
                property var helperRoot: null

                onMediaStatusChanged: {
                    if (mediaStatus === MediaPlayer.LoadedMedia) {
                        if (debugMode) {
                            Utils.dumpVideoMetadata(targetFilepath, metaData);
                        }

                        const extractedMetadata = Utils.extractVideoMetadata(metaData);

                        // Save to cache via helper
                        if (extractedMetadata.videoWidth > 0 && extractedMetadata.videoHeight > 0 && helperRoot) {
                            helperRoot.saveToCache(targetFilepath, extractedMetadata);
                        }

                        // Return metadata
                        if (extractCallback) {
                            extractCallback(extractedMetadata);
                        }

                        // Cleanup
                        stop();
                        source = "";
                        destroy();
                    } else if (mediaStatus === MediaPlayer.InvalidMedia || mediaStatus === MediaPlayer.NoMedia) {
                        if (extractCallback) {
                            extractCallback(null);
                        }
                        destroy();
                    }
                }
            }
        `;

        try {
            const player = Qt.createQmlObject(qmlString, root, "MetadataPlayerLoader");
            player.targetFilepath = filepath;
            player.extractCallback = callback;
            player.debugMode = debugEnabled;
            player.helperRoot = root;
            player.source = filepath;
        } catch (e) {
            console.error("Error creating MediaPlayer for metadata extraction:", e);
            if (callback) callback(null);
        }
    }

    /**
     * Save metadata to cache
     * @param {string} filepath - Path to the video file
     * @param {object} metadata - Metadata object to save
     */
    function saveToCache(filepath, metadata) {
        if (!fileStatHelper) {
            return;
        }

        // Get file stats and save to cache asynchronously
        fileStatHelper.getFileStatsAsync(filepath, function(fileInfo) {
            if (fileInfo) {
                try {
                    MetadataCache.saveMetadata(
                        filepath,
                        fileInfo.size,
                        fileInfo.mtime,
                        metadata
                    );
                    if (debugEnabled) {
                        console.log("Saved metadata to cache for:", filepath);
                    }
                } catch (e) {
                    console.error("Error saving to cache:", e);
                }
            }
        });
    }

    /**
     * Dump video metadata to console (for debugging)
     * @param {string} filepath - Path to the video file
     * @param {object} metaData - MediaPlayer metaData object
     */
    function dumpMetadata(filepath, metaData) {
        Utils.dumpVideoMetadata(filepath, metaData);
    }
}
