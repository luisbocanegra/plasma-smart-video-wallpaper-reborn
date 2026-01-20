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

/**
 * Generates an SVG string for displaying video annotation badge
 * @param {String} text - The text to insert in the badge (e.g., "4K", "HDR")
 * @param {String} bgColor - The background color of the badge. Defaults to blue ('#4285F4')
 * @param {String} fgColor - The color of the text. Defaults to white.
 * @returns {String} SVG string representing the badge
 */
function generateBadge(text, bgColor="#4285F4", fgColor="white") {
  return `<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<svg width="80" height="40" viewBox="0 0 200 100" xmlns="http://www.w3.org/2000/svg">
  <rect x="20" y="20" width="160" height="60" rx="10" ry="10" fill="${bgColor}"/>
  <text x="100" y="60" font-family="Arial, sans-serif" font-size="36" font-weight="bold" text-anchor="middle" fill="${fgColor}">${text}</text>
</svg>`;
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
