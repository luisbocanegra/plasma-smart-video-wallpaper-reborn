function parseCompat(cfgStr) {
  let videos = [];
  try {
    JSON.parse(cfgStr).forEach((video) => {
      video.playbackRate = video.playbackRate ?? 0.0;
      video.alternativePlaybackRate = video.alternativePlaybackRate ?? 0.0;
      video.dayNightPhase = video.dayNightPhase ?? Enum.DayNightPhase.Unknown;
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

const Video = {
  filename: "",
  enabled: true,
  duration: 0,
  customDuration: 0,
  playbackRate: 0.0,
  alternativePlaybackRate: 0.0,
  loop: false,
  dayNightCycleAssignment: 0,
};

/**
 * Create a new Video object with the given filename
 * @param {string} filename Video filename
 * @returns {Video} Video object with the given filename and default properties
 */
function createVideo(filename) {
  let video = Object.create(Video);
  video.filename = filename;
  return video;
}

/**
 * Get fallback day-night phase for sunrise and sunset
 * @param {DayNightPhase} dayNightPhase Current day-night phase
 * @returns {DayNightPhase} Fallback phase for sunrise and sunset, or unknown if no fallback exists
 */
function getFallbackPhase(dayNightPhase) {
  switch (dayNightPhase) {
    case Enum.DayNightPhase.Sunrise:
      return Enum.DayNightPhase.Day;
    case Enum.DayNightPhase.Sunset:
      return Enum.DayNightPhase.Night;
    default:
      return Enum.DayNightPhase.Unknown;
  }
}

/**
 * Get videos matching the given day-night phase
 * @param {Array.<Video>} videos 
 * @param {DayNightPhase} dayNightPhase 
 * @returns {Array.<Video>} List of videos matching the given day-night phase
 */
function getMatchingVideos(videos, dayNightPhase) {
  return videos.filter(video => {
    return video.dayNightPhase === dayNightPhase;
  });
}

/**
 * Get videos matching the current day-night phase, including videos without a specific phase assigned
 * 
 * If day-night cycle is disabled, returns all videos
 * 
 * If no videos match the current phase, tries to get fallback videos for sunrise and sunset
 * @param {boolean} dayNightCycleEnabled Whether day-night cycle is enabled
 * @param {DayNightPhase} dayNightPhase Current day-night phase
 * @param {string} videoUrls Video URLs configuration string
 * @returns {Array.<Video>} List of videos matching the criteria
 */
function getVideos(dayNightCycleEnabled, dayNightPhase, videoUrls) {
  const videos = parseCompat(videoUrls).filter(video => video.enabled);

  if (!dayNightCycleEnabled) {
    return videos;
  }

  const defaultVideos = videos.filter(video => video.dayNightPhase === Enum.DayNightPhase.Unknown);
  let matchingVideos = getMatchingVideos(videos, dayNightPhase);
  if (matchingVideos.length > 0) {
    return matchingVideos.concat(defaultVideos);
  }

  // try to get fallback videos for sunrise and sunset
  let fallbackPhase = getFallbackPhase(dayNightPhase);
  if (fallbackPhase !== Enum.DayNightPhase.Unknown) {
    matchingVideos = getMatchingVideos(videos, fallbackPhase);
  }

  return matchingVideos.concat(defaultVideos);
}

/**
 * Get video index by filename
 * @param {string} filename Video filename to search for
 * @param {Array.<Video>} videosConfig List of videos with their properties
 * @returns {int} Matching index, or -1 when not found
 */
function getVideoIndex(filename, videosConfig) {
  return videosConfig.findIndex(video => video.filename === filename);
}

/**
 * Get index of the last played video or -1 if not last video exists
 * if day-night cycle is enabled returns the last video for that cycle
 * @param {boolean} dayNightCycleEnabled Whether day-night cycle is enabled
 * @param {DayNightPhase} dayNightPhase Current day-night phase
 * @param {KConfigPropertyMap} configuration Wallpaper (WallpaperItem) configuration
 * @param {Array.<Video>} videosConfig List of videos with their properties
 * @returns {int} Video index or -1 if not found
 */
function getLastVideoIndex(dayNightCycleEnabled, dayNightPhase, configuration, videosConfig) {
  if (dayNightCycleEnabled) {
    let lastVideos = [];
    switch (dayNightPhase) {
      case Enum.DayNightPhase.Day:
        lastVideos = [configuration.LastDayVideo, configuration.LastVideo];
        break;
      case Enum.DayNightPhase.Night:
        lastVideos = [configuration.LastNightVideo, configuration.LastVideo];
        break;
      case Enum.DayNightPhase.Sunrise:
        lastVideos = [configuration.LastSunriseVideo, configuration.LastDayVideo, configuration.LastVideo];
        break;
      case Enum.DayNightPhase.Sunset:
        lastVideos = [configuration.LastSunsetVideo, configuration.LastNightVideo, configuration.LastVideo];
        break;
      default:
        lastVideos = [configuration.LastVideo];
    }

    for (let lastVideo of lastVideos) {
      const index = getVideoIndex(lastVideo, videosConfig);
      if (lastVideo !== "" && index !== -1) {
        return index;
      }
    }
  } else {
    const lastVideo = configuration.LastVideo;
    return lastVideo === "" ? -1 : getVideoIndex(lastVideo, videosConfig);
  }

  return -1;
}

function dumpProps(obj) {
  console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
  for (var k of Object.keys(obj)) {
    const val = obj[k];
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
