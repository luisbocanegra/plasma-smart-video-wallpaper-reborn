function parseCompat(cfgStr) {
  try {
    return videosConfig = JSON.parse(cfgStr)
  } catch (e) {
    console.log("Possibly old config, parsing as multi-line string", e)
    const lines = cfgStr.trim().split("\n");
    let videos = []
    for (const line of lines) [
      videos.push(new createVideo(line))
    ]
    return videos
  }
}

function updateConfig() {
  cfg_VideoUrls = JSON.stringify(videosConfig)
  videosConfig = Utils.parseCompat(cfg_VideoUrls)
}

function createVideo(filename) {
  this.filename = filename;
  this.enabled = true;
  this.duration = 0;
  this.customDuration = 0;
  return {
    "filename": this.filename,
    "enabled": this.enabled,
    "duration": this.duration,
    "customDuration": this.customDuration
  }
}

function dumpProps(obj) {
  console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@");
  for (var k of Object.keys(obj)) {
    const val = obj[k]
    if (typeof val === 'function') continue
    if (k === 'metaData') continue
    console.log(k + "=" + val + "\n")
  }
}

// randomize array using Durstenfeld shuffle algorithm
function shuffleArray(array) {
  for (let i = array.length - 1; i >= 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    const temp = array[i]
    array[i] = array[j]
    array[j] = temp
  }
  return array
}
