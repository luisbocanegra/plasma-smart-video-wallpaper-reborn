function parseCompat(cfgStr) {
  let videos = [];
  try {
    JSON.parse(cfgStr).forEach((video) => {
      video.playbackRate = video.playbackRate ?? 0.0;
      video.alternativePlaybackRate = video.alternativePlaybackRate ?? 0.0;
      video.videoWidth = video.videoWidth ?? 0;
      video.videoHeight = video.videoHeight ?? 0;
      video.videoCodec = video.videoCodec ?? "";
      video.videoBitRate = video.videoBitRate ?? 0;
      video.videoFrameRate = video.videoFrameRate ?? 0.0;
      video.isHdr = video.isHdr ?? false;
      videos.push(video);
    });
  } catch (e) {
    console.log("Possibly old config, parsing as multi-line string", e);
    const lines = cfgStr.trim().split("\n");
    for (const line of lines) {
      if (line.length > 0) {
        videos.push(new createVideo(line));
      }
    }
  }
  return videos;
}

function createVideo(filename) {
  return {
    "filename": filename ?? "",
    "enabled": true,
    "duration": 0,
    "customDuration": 0,
    "playbackRate": 0.0,
    "alternativePlaybackRate": 0.0,
    "loop": false,
    "videoWidth": 0,
    "videoHeight": 0,
    "videoCodec": "",
    "videoBitRate": 0,
    "videoFrameRate": 0.0,
    "isHdr": false,
  };
}

/**
 *
 * @param {String} filename File path
 * @param {Array} videosConfig Videos config
 * @returns {Object} Video properties
 */
function getVideoByFile(filename, videosConfig) {
  const video = videosConfig.find((video) => video.filename === filename);
  return video ?? createVideo("");
}

/**
 *
 * @param {int} index Video index
 * @param {Array} videosConfig Videos config
 * @returns {Object} Video properties
 */
function getVideoByIndex(index, videosConfig) {
  return videosConfig.length > 0 ? videosConfig[index] : createVideo("");
}

function dumpProps(obj) {
  console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
  for (var k of Object.keys(obj)) {
    const val = obj[k];
    if (typeof val === 'function') continue;
    if (k === 'metaData') continue;
    console.log(k + "=" + val + "\n");
  }
}

/**
 * Extracts video metadata from MediaPlayer's metaData object
 * @param {Object} metaData - The metaData object from MediaPlayer
 * @returns {Object} Extracted video properties including width, height, codec, etc.
 */
function extractVideoMetadata(metaData) {
  const width = metaData.value(MediaMetaData.Resolution)?.width ?? 0;
  const height = metaData.value(MediaMetaData.Resolution)?.height ?? 0;
  const codec = metaData.stringValue(MediaMetaData.VideoCodec) ?? "";
  const bitRate = metaData.value(MediaMetaData.VideoBitRate) ?? 0;
  const frameRate = metaData.value(MediaMetaData.VideoFrameRate) ?? 0.0;

  // Check for HDR support
  let isHdr = false;
  try {
      // Try to check the HasHdrContent property (Qt 6.8+)
      isHdr = metaData.value(MediaMetaData.HasHdrContent) ?? false;
  } catch (e) {
      // If HDR detection fails, just continue without it
      // No need to log as this is expected on older Qt versions
  }

  return {
    videoWidth: width,
    videoHeight: height,
    videoCodec: codec,
    videoBitRate: bitRate,
    videoFrameRate: frameRate,
    isHdr: isHdr
  };
}

function dumpVideoMetadata(filename, metaData) {
  // Dump all available metadata keys and values
  console.log("=== Metadata Dump ===");
  console.log("Filename:", filename);
  console.log("MetaData object:", metaData);
  console.log("MetaData keys():", metaData.keys());
  console.log("Checking known MediaMetaData properties:");

  // List of known MediaMetaData enum values to check
  const knownKeys = [
      'Title', 'Author', 'Comment', 'Description', 'Genre', 'Date',
      'Language', 'Publisher', 'Copyright', 'Url',
      'Duration', 'MediaType', 'FileFormat', 'AudioBitRate', 'AudioCodec',
      'VideoBitRate', 'VideoCodec', 'VideoFrameRate', 'VideoWidth', 'VideoHeight',
      'Orientation', 'Resolution', 'LeadPerformer', 'ContributingArtist',
      'AlbumTitle', 'AlbumArtist', 'TrackNumber', 'Composer',
      'ThumbnailImage', 'CoverArtImage',
      // Qt 6.8+ HDR-related
      'ColorSpace', 'ColorTransfer', 'HasHdrContent'
  ];

  knownKeys.forEach(key => {
      try {
          if (typeof MediaMetaData[key] !== 'undefined') {
              const value = metaData.value(MediaMetaData[key]);
              if (value !== undefined && value !== null && value !== "") {
                  console.log(`  ${key}:`, value);
              }
          }
      } catch (e) {
          // Property doesn't exist or can't be read
      }
  });
  console.log("=== End Metadata Dump ===");
}

// randomize array using Durstenfeld shuffle algorithm
function shuffleArray(array) {
  for (let i = array.length - 1; i >= 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    const temp = array[i];
    array[i] = array[j];
    array[j] = temp;
  }
  return array;
}

// https://stackoverflow.com/questions/28507619/how-to-create-delay-function-in-qml
function delay(interval, callback, parentItem) {
  let timer = Qt.createQmlObject("import QtQuick; Timer {}", parentItem);
  timer.interval = interval;
  timer.repeat = false;
  timer.triggered.connect(callback);
  timer.triggered.connect(function release() {
    timer.triggered.disconnect(callback);
    timer.triggered.disconnect(release);
    timer.destroy();
  });
  timer.start();
}

// a rudimentary way to parse gdbus GVariant into a valid js object
function parseGVariant(str) {
  str = gVariantTupleToArray(str);
  str = str.trim().replace(/^\([']?/, "") // remove starting ( or ('
    .replace(/[']?[,]?\)$/, ""); // remove ending ,) or ',)

  // remove GVariant typing thingy e.g <(uint32 ...,)> or <@as ...> <...> <[...]>
  str = str.replace(/<[\(]?\s*(.+?)[,]?\s*[\)]?>/g, "$1").replace(/@as |uint32 /g, '');

  if (str === "") return "";
  if (str === "true") return true;
  if (str === "false") return false;
  if (str === "null") return null;
  if (/^-?\d+(\.\d+)?$/.test(str)) return Number(str);

  // try to parse as array or dictionary
  if (/^[\[]?[\{]?.*[\]]?[\}]?$/.test(str)) {
    try {
      return JSON.parse(str.replace(/'null'/g, "null").replace(/'/g, '"'));
    } catch (e) {
      return str;
    }
  }
  return str.replace(/^['"]|['"]$/g, "").trim();
}

// convert GVariant tuples to arrays
function gVariantTupleToArray(str) {
  // convert all tuples like (..., ...) arrays [..., ...]
  return str.replace(/\(([^()]+?)\)/g, (_, inner) => {
    // only replace if it's NOT inside a JSON-style key or between quotes
    if (/^[^:][^']+,[^:][^']+$/.test(inner)) {
      return `[${inner}]`;
    }
    return `(${inner})`;
  });
}
