import QtQuick
import QtMultimedia
import "code/utils.js" as Utils
import "code/enum.js" as Enum

Item {
    id: root
    property var currentSource: Utils.createVideo("")
    property real volume: 1.0
    property bool muted: true
    property real playbackRate: 1
    property int fillMode
    property bool crossfadeEnabled: false
    property int targetCrossfadeDuration: 1000
    property bool multipleVideos: false
    property int lastVideoPosition: 0
    property bool restoreLastPosition: true
    property bool debugEnabled: false
    property int changeWallpaperMode: Enum.ChangeWallpaperMode.Slideshow
    property int changeWallpaperTimerSeconds: 0
    property int changeWallpaperTimerMinutes: 10
    property int changeWallpaperTimerHours: 0
    property int changeWallpaperTimerMs: ((changeWallpaperTimerHours * 60 * 60) + (changeWallpaperTimerMinutes * 60) + changeWallpaperTimerSeconds) * 1000
    property bool resumeLastVideo: true
    property int fillBlurRadius: 32
    property bool fillBlur: true
    property real alternativePlaybackRateGlobal: 0.5
    property bool useAlternativePlaybackRate: false

    property bool prebufferNextVideo: true
    property var nextSource: Utils.createVideo("")

    property int crossfadeMinDurationLast: {
        const d = Number(otherPlayer.actualDuration);
        const safeDuration = Number.isFinite(d) ? Math.max(0, d) : 0;
        return Math.min(root.targetCrossfadeDuration / 2, safeDuration / 3);
    }
    property int crossfadeMinDurationCurrent: {
        const d = Number(player.actualDuration);
        const safeDuration = Number.isFinite(d) ? Math.max(0, d) : 0;
        return Math.min(root.targetCrossfadeDuration / 2, safeDuration / 3);
    }
    property int crossfadeDuration: {
        const safeLast = Number.isFinite(crossfadeMinDurationLast) ? Math.max(0, crossfadeMinDurationLast) : 0;
        const safeCurrent = Number.isFinite(crossfadeMinDurationCurrent) ? Math.max(0, crossfadeMinDurationCurrent) : 0;
        if (!root.crossfadeEnabled) {
            return 0;
        } else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.OnATimer) {
            return Math.min(root.targetCrossfadeDuration, changeWallpaperTimerMs / 3 * 2);
        } else {
            return safeLast + safeCurrent;
        }
    }

    readonly property int stateIdle: 0
    readonly property int statePrebuffering: 1
    readonly property int statePendingSwap: 2
    readonly property int stateFading: 3

    property int transitionState: root.stateIdle
    readonly property string transitionStateName: root.stateName(root.transitionState)
    readonly property bool transitionBusy: root.transitionState === root.statePendingSwap || root.transitionState === root.stateFading

    property bool primaryPlayer: true
    property string pendingTargetFilename: ""
    property bool pendingAdvancePlaylist: false
    property real pendingSwitchStartMs: 0
    property bool holdActiveTailFrame: false
    property bool fadeVisualPending: false
    property bool fadeAdvanceSourcePending: false
    property bool fadeIncomingIsPlayer1: false
    property int fadeResumeBaselinePosition: 0
    property int fadeResumeMinDeltaMs: 80
    property int fadeResumeTimeoutMs: 220
    property real fadeResumeDeadlineMs: 0
    property int prebufferWarmupMinMs: 90

    property int prebufferGeneration: 0
    property int activePrebufferGeneration: 0
    property string lastFailedTargetFilename: ""
    property int maxPrebufferRetries: 1
    property int timeoutPrebufferRetries: 2
    property int prebufferRetryExtraTimeoutMs: 900
    property int prebufferStallTimeoutMs: Math.max(2200, root.safeCrossfadeDuration() * 4 + 1200)
    property int pendingSwitchTimeoutMs: Math.max(2500, root.prebufferStallTimeoutMs + root.safeCrossfadeDuration())
    property int holdTailLeadMs: Math.max(80, Math.min(260, root.safeCrossfadeDuration() / 2 + 80))

    property VideoPlayer player: primaryPlayer ? videoPlayer1 : videoPlayer2
    property VideoPlayer otherPlayer: primaryPlayer ? videoPlayer2 : videoPlayer1

    readonly property alias player1: videoPlayer1
    readonly property alias player2: videoPlayer2

    signal setNextSource
    signal requestNextCandidate(string failedFilename)

    function stateName(value) {
        switch (value) {
        case root.stateIdle:
            return "Idle";
        case root.statePrebuffering:
            return "Prebuffering";
        case root.statePendingSwap:
            return "PendingSwap";
        case root.stateFading:
            return "Fading";
        default:
            return "Unknown";
        }
    }

    function shortFilename(filename) {
        if (!filename) {
            return "<none>";
        }
        const parts = filename.split("/");
        return parts.length === 0 ? filename : parts[parts.length - 1];
    }

    function sourceFilename(videoSource) {
        return videoSource && videoSource.filename ? videoSource.filename : "";
    }

    function logDebug(channel, message) {
        if (root.debugEnabled) {
            console.log(`[FadePlayer][${channel}] ${message}`);
        }
    }

    function play() {
        player.play();
    }

    function pause() {
        player.pause();
    }

    function stop() {
        player.stop();
    }

    function safeCrossfadeDuration() {
        return Number.isFinite(root.crossfadeDuration) ? Math.max(0, root.crossfadeDuration) : 0;
    }

    function refreshWatchdog() {
        prebufferWatchdog.running = root.transitionState === root.statePendingSwap
                || root.fadeVisualPending
                || videoPlayer1.prebufferPending
                || videoPlayer2.prebufferPending;
    }

    function setTransitionState(nextState, reason) {
        if (root.transitionState === nextState) {
            return;
        }
        root.logDebug("transition", `${root.stateName(root.transitionState)} -> ${root.stateName(nextState)} (${reason})`);
        root.transitionState = nextState;
        refreshWatchdog();
    }

    function clearPrebufferState(target, reason) {
        const hadState = target.prebufferPending || target.prebufferReady || target.prebufferTargetFilename !== "";
        if (hadState) {
            root.logDebug("prebuffer", `cancel player=${target.objectName} target=${root.shortFilename(target.prebufferTargetFilename)} reason=${reason}`);
        }
        target.prebufferPending = false;
        target.prebufferReady = false;
        target.prebufferTargetFilename = "";
        target.prebufferGeneration = 0;
        target.prebufferStartMs = 0;
        target.prebufferReadyPosition = 0;
        target.prebufferRetryCount = 0;
        refreshWatchdog();
    }

    function assignPlayerSource(target, source, reason) {
        const filename = root.sourceFilename(source);
        if (target.playerSource.filename === filename) {
            return;
        }
        if (filename === "" && root.prebufferNextVideo
                && reason !== "non-prebuffer-clear"
                && reason !== "prebuffer-reset") {
            return;
        }
        root.logDebug("source", `assign player=${target.objectName} source=${root.shortFilename(filename)} reason=${reason}`);
        target.playerSource = source;
    }

    function syncActivePlayerSource(force) {
        const filename = root.sourceFilename(root.currentSource);
        if (!filename) {
            return;
        }
        if (root.transitionState === root.statePendingSwap || root.transitionState === root.stateFading) {
            return;
        }
        const active = root.player;
        if (force
                || !active.playerSource.filename
                || active.mediaStatus === MediaPlayer.NoMedia
                || active.mediaStatus === MediaPlayer.InvalidMedia) {
            clearPrebufferState(active, "active-source-sync");
            assignPlayerSource(active, root.currentSource, "active-source-sync");
        }
    }

    function isPlayerReadyFor(target, targetFilename) {
        return !!targetFilename
                && target.playerSource.filename === targetFilename
                && target.prebufferTargetFilename === targetFilename
                && !target.prebufferPending
                && target.prebufferReady;
    }

    function isInactivePrebufferReadyFor(targetFilename) {
        return isPlayerReadyFor(root.otherPlayer, targetFilename);
    }

    function ensurePrebufferEventCurrent(target, reason) {
        if (!target.prebufferPending) {
            return false;
        }

        if (target.prebufferGeneration === 0 || target.prebufferGeneration !== root.activePrebufferGeneration) {
            root.logDebug("prebuffer", `stale-event-ignored player=${target.objectName} reason=${reason}`);
            clearPrebufferState(target, "stale-generation");
            return false;
        }

        if (target.prebufferTargetFilename === "" || target.playerSource.filename !== target.prebufferTargetFilename) {
            root.logDebug("prebuffer", `stale-event-ignored player=${target.objectName} source=${root.shortFilename(target.playerSource.filename)} target=${root.shortFilename(target.prebufferTargetFilename)} reason=${reason}`);
            clearPrebufferState(target, "stale-source");
            return false;
        }

        return true;
    }

    function releaseTailHold(resumePlayback) {
        if (!root.holdActiveTailFrame) {
            return;
        }
        const active = root.player;
        root.holdActiveTailFrame = false;
        if (resumePlayback) {
            if (!active.playing) {
                active.play();
            }
        }
    }

    function holdActiveFrameIfNearTail(activePlayer) {
        if (root.transitionState !== root.statePendingSwap || root.holdActiveTailFrame || !activePlayer.duration) {
            return;
        }
        const holdAt = Math.max(0, activePlayer.duration - root.holdTailLeadMs);
        if (activePlayer.position >= holdAt) {
            if (activePlayer.seekable) {
                activePlayer.position = Math.max(0, activePlayer.duration - 16);
            }
            activePlayer.pause();
            root.holdActiveTailFrame = true;
            root.logDebug("transition", `hold-tail player=${activePlayer.objectName} position=${activePlayer.position} duration=${activePlayer.duration}`);
        }
    }

    function resolveVideoSourceForFilename(filename, fallbackSource) {
        if (!filename) {
            return Utils.createVideo("");
        }
        if (root.sourceFilename(root.nextSource) === filename) {
            return root.nextSource;
        }
        if (root.sourceFilename(root.currentSource) === filename) {
            return root.currentSource;
        }
        if (root.sourceFilename(fallbackSource) === filename) {
            return fallbackSource;
        }
        return Utils.createVideo(filename);
    }

    function beginPrebufferOnPlayer(target, source, reason, retryCount) {
        const targetFilename = root.sourceFilename(source);
        if (!targetFilename) {
            return false;
        }

        root.prebufferGeneration += 1;
        const generation = root.prebufferGeneration;
        root.activePrebufferGeneration = generation;

        clearPrebufferState(target, "new-request");

        // Reusing the same filename can leave the decoder at tail/end state.
        // Force reload for deterministic prebuffer warmup.
        if (target.playerSource.filename === targetFilename) {
            root.logDebug("prebuffer", `force-reload same-source player=${target.objectName} target=${root.shortFilename(targetFilename)}`);
            target.stop();
            assignPlayerSource(target, Utils.createVideo(""), "prebuffer-reset");
        }
        assignPlayerSource(target, source, `prebuffer-gen-${generation}`);

        target.prebufferPending = true;
        target.prebufferReady = false;
        target.prebufferTargetFilename = targetFilename;
        target.prebufferGeneration = generation;
        target.prebufferStartMs = Date.now();
        target.prebufferReadyPosition = 0;
        target.prebufferRetryCount = retryCount;

        if (target.seekable) {
            target.position = 0;
        }
        target.play();
        root.logDebug("prebuffer", `start player=${target.objectName} target=${root.shortFilename(targetFilename)} reason=${reason}`);

        if (root.transitionState === root.stateIdle) {
            setTransitionState(root.statePrebuffering, "prebuffer-start");
        }

        refreshWatchdog();
        return true;
    }

    function retryLimitForReason(reason) {
        if (reason === "invalid-media") {
            return 0;
        }
        if (reason === "timeout") {
            return Math.max(root.maxPrebufferRetries, root.timeoutPrebufferRetries);
        }
        return root.maxPrebufferRetries;
    }

    function startPrebufferForInactive(reason) {
        if (!root.prebufferNextVideo || root.transitionState === root.stateFading) {
            return;
        }

        const targetFilename = root.sourceFilename(root.nextSource);
        if (!targetFilename) {
            if (root.transitionState === root.statePrebuffering) {
                setTransitionState(root.stateIdle, "empty-prebuffer-target");
            }
            refreshWatchdog();
            return;
        }

        const inactive = root.otherPlayer;
        if (isPlayerReadyFor(inactive, targetFilename)) {
            if (root.transitionState === root.statePrebuffering) {
                setTransitionState(root.stateIdle, "already-ready");
            }
            refreshWatchdog();
            return;
        }

        if (inactive.prebufferPending
                && inactive.prebufferTargetFilename === targetFilename
                && inactive.playerSource.filename === targetFilename) {
            root.logDebug("prebuffer", `in-flight player=${inactive.objectName} target=${root.shortFilename(targetFilename)} reason=${reason}`);
            refreshWatchdog();
            return;
        }

        beginPrebufferOnPlayer(inactive, root.nextSource, reason, 0);
    }

    function retryPrebufferTarget(target, reason) {
        const targetFilename = target.prebufferTargetFilename;
        if (!targetFilename || !root.prebufferNextVideo || root.transitionState === root.stateFading) {
            return false;
        }

        const currentRetry = target.prebufferRetryCount || 0;
        const retryLimit = root.retryLimitForReason(reason);
        if (currentRetry >= retryLimit) {
            return false;
        }

        const retrySource = resolveVideoSourceForFilename(targetFilename, target.playerSource);
        const nextRetry = currentRetry + 1;
        root.logDebug("prebuffer", `retry player=${target.objectName} target=${root.shortFilename(targetFilename)} reason=${reason}`);
        return beginPrebufferOnPlayer(target, retrySource, `retry-${reason}`, nextRetry);
    }

    function markPrebufferReady(target, reason) {
        if (!ensurePrebufferEventCurrent(target, reason)) {
            return;
        }

        const readyFilename = target.prebufferTargetFilename;
        const readyPosition = target.position;
        target.pause();
        target.prebufferPending = false;
        target.prebufferReady = true;
        target.prebufferReadyPosition = readyPosition;
        target.prebufferStartMs = 0;

        root.logDebug("prebuffer", `first-frame-ready player=${target.objectName} target=${root.shortFilename(readyFilename)} pos=${readyPosition}`);

        if (root.transitionState === root.statePrebuffering) {
            setTransitionState(root.stateIdle, "prebuffer-ready");
        }

        if (root.transitionState === root.statePendingSwap) {
            maybeStartPendingSwap("ready");
        }

        refreshWatchdog();
    }

    function armTransitionFinalize() {
        transitionFinalizeTimer.interval = Math.max(1, root.safeCrossfadeDuration() + 20);
        transitionFinalizeTimer.restart();
    }

    function beginVisualSwitch(incoming, outgoing) {
        // Keep outgoing on top and fade it out. Incoming is already visible underneath.
        outgoing.z = 2;
        incoming.z = 1;
        incoming.opacity = 1;
        outgoing.opacity = 0;
        root.primaryPlayer = (incoming === videoPlayer1);
        armTransitionFinalize();
    }

    function isPendingFadeIncoming(target) {
        return root.fadeVisualPending && ((target === videoPlayer1) === root.fadeIncomingIsPlayer1);
    }

    function startVisualFadeIfReady(reason) {
        if (!root.fadeVisualPending) {
            return;
        }

        const incoming = root.fadeIncomingIsPlayer1 ? videoPlayer1 : videoPlayer2;
        const outgoing = root.fadeIncomingIsPlayer1 ? videoPlayer2 : videoPlayer1;
        const resumed = incoming.position > (root.fadeResumeBaselinePosition + root.fadeResumeMinDeltaMs);
        const timedOut = Date.now() >= root.fadeResumeDeadlineMs;
        if (!resumed && !timedOut) {
            return;
        }

        if (timedOut && !resumed) {
            root.logDebug("transition", `fade-visual-timeout incoming=${incoming.objectName} baseline=${root.fadeResumeBaselinePosition} position=${incoming.position}`);
        } else {
            root.logDebug("transition", `fade-visual-ready incoming=${incoming.objectName} baseline=${root.fadeResumeBaselinePosition} position=${incoming.position} reason=${reason}`);
        }

        root.fadeVisualPending = false;
        root.fadeResumeDeadlineMs = 0;
        beginVisualSwitch(incoming, outgoing);

        if (root.fadeAdvanceSourcePending) {
            root.fadeAdvanceSourcePending = false;
            root.logDebug("transition", "request setNextSource()");
            setNextSource();
        }

        refreshWatchdog();
    }

    function startFade(incoming, outgoing, shouldAdvanceSource, reason) {
        if (root.transitionState === root.stateFading) {
            return;
        }

        root.pendingTargetFilename = "";
        root.pendingAdvancePlaylist = false;
        root.pendingSwitchStartMs = 0;
        root.holdActiveTailFrame = false;
        root.fadeVisualPending = false;
        root.fadeAdvanceSourcePending = false;
        root.fadeResumeDeadlineMs = 0;

        clearPrebufferState(incoming, "fade-start");
        if (incoming.seekable && incoming.mediaStatus === MediaPlayer.EndOfMedia) {
            incoming.position = 0;
        }
        incoming.play();
        setTransitionState(root.stateFading, reason);
        root.logDebug("transition", `fade-start incoming=${incoming.objectName} outgoing=${outgoing.objectName} reason=${reason}`);

        // Keep outgoing fully visible until incoming makes post-resume progress.
        outgoing.z = 2;
        incoming.z = 1;
        incoming.opacity = 1;
        outgoing.opacity = 1;

        root.fadeIncomingIsPlayer1 = (incoming === videoPlayer1);
        root.fadeResumeBaselinePosition = incoming.position;
        root.fadeResumeDeadlineMs = Date.now() + root.fadeResumeTimeoutMs;
        root.fadeAdvanceSourcePending = shouldAdvanceSource;
        root.fadeVisualPending = true;
        startVisualFadeIfReady("start");

        refreshWatchdog();
    }

    function startPrebufferedFade(shouldAdvanceSource, reason) {
        const incoming = root.otherPlayer;
        const outgoing = root.player;
        startFade(incoming, outgoing, shouldAdvanceSource, reason);
    }

    function startDirectFade(shouldAdvanceSource, reason) {
        const incoming = root.otherPlayer;
        const outgoing = root.player;

        root.pendingTargetFilename = "";
        root.pendingAdvancePlaylist = false;
        root.pendingSwitchStartMs = 0;
        root.holdActiveTailFrame = false;

        if (shouldAdvanceSource) {
            root.logDebug("transition", "request setNextSource() for direct path");
            setNextSource();
        }

        clearPrebufferState(incoming, "direct-switch");
        assignPlayerSource(incoming, root.currentSource, "direct-switch");
        startFade(incoming, outgoing, false, reason);
    }

    function maybeStartPendingSwap(reason) {
        if (root.transitionState !== root.statePendingSwap) {
            return;
        }
        const targetFilename = root.pendingTargetFilename;
        if (!targetFilename) {
            return;
        }
        if (!isInactivePrebufferReadyFor(targetFilename)) {
            return;
        }

        root.logDebug("transition", `pending-ready target=${root.shortFilename(targetFilename)} reason=${reason}`);
        startPrebufferedFade(root.pendingAdvancePlaylist, `pending-ready-${reason}`);
    }

    function failPrebufferTarget(target, reason) {
        const failedFilename = target.prebufferTargetFilename;
        const retryLimit = root.retryLimitForReason(reason);
        const canRetry = (target.prebufferRetryCount || 0) < retryLimit
                && root.prebufferNextVideo
                && root.transitionState !== root.stateFading
                && !!failedFilename;

        root.logDebug("prebuffer", `fail player=${target.objectName} target=${root.shortFilename(failedFilename)} reason=${reason} willRetry=${canRetry}`);

        if (retryPrebufferTarget(target, reason)) {
            return;
        }
        clearPrebufferState(target, reason);
        target.pause();

        if (failedFilename) {
            root.lastFailedTargetFilename = failedFilename;
        }

        if (root.transitionState === root.statePendingSwap && failedFilename === root.pendingTargetFilename) {
            cancelPendingSwap(reason, failedFilename);
            return;
        }

        if (root.transitionState === root.statePrebuffering) {
            setTransitionState(root.stateIdle, `prebuffer-failed-${reason}`);
        }

        if (failedFilename && root.prebufferNextVideo) {
            requestNextCandidate(failedFilename);
        }

        refreshWatchdog();
    }

    function cancelPendingSwap(reason, failedFilename) {
        if (root.transitionState !== root.statePendingSwap) {
            return;
        }

        const inactive = root.otherPlayer;
        const failed = failedFilename || root.pendingTargetFilename;

        root.pendingTargetFilename = "";
        root.pendingAdvancePlaylist = false;
        root.pendingSwitchStartMs = 0;
        setTransitionState(root.stateIdle, `pending-cancel-${reason}`);
        root.fadeVisualPending = false;
        root.fadeAdvanceSourcePending = false;
        root.fadeResumeDeadlineMs = 0;
        clearPrebufferState(inactive, `pending-cancel-${reason}`);
        inactive.pause();
        releaseTailHold(true);

        if (failed) {
            root.logDebug("prebuffer", `cancel target=${root.shortFilename(failed)} reason=${reason}`);
            requestNextCandidate(failed);
        }

        refreshWatchdog();
    }

    function requestPrebufferedSwitch(reason) {
        const targetFilename = root.sourceFilename(root.nextSource);
        root.logDebug("transition", `request target=${root.shortFilename(targetFilename)} reason=${reason}`);

        if (!targetFilename) {
            root.logDebug("transition", "missing prebuffer target, fallback to direct switch");
            if (root.multipleVideos) {
                startDirectFade(true, "missing-prebuffer-target");
            } else {
                startDirectFade(false, "missing-prebuffer-target-single");
            }
            return;
        }

        if (targetFilename === root.lastFailedTargetFilename) {
            root.logDebug("prebuffer", `skip known failed target=${root.shortFilename(targetFilename)}`);
            requestNextCandidate(targetFilename);
            return;
        }

        if (isInactivePrebufferReadyFor(targetFilename)) {
            startPrebufferedFade(true, "ready-at-request");
            return;
        }

        root.pendingTargetFilename = targetFilename;
        root.pendingAdvancePlaylist = true;
        root.pendingSwitchStartMs = Date.now();
        root.holdActiveTailFrame = false;
        setTransitionState(root.statePendingSwap, "waiting-ready");
        root.logDebug("transition", `pending target=${root.shortFilename(targetFilename)}`);

        startPrebufferForInactive("pending-switch");
        holdActiveFrameIfNearTail(root.player);
        refreshWatchdog();
    }

    function finalizeTransition() {
        const active = root.player;
        const inactive = root.otherPlayer;

        inactive.pause();
        active.z = 2;
        inactive.z = 1;
        active.opacity = 1;
        inactive.opacity = 1;
        root.holdActiveTailFrame = false;
        root.fadeVisualPending = false;
        root.fadeAdvanceSourcePending = false;
        root.fadeResumeDeadlineMs = 0;

        setTransitionState(root.stateIdle, "finalize");
        root.logDebug("transition", `finalize active=${active.objectName}`);

        if (!root.prebufferNextVideo) {
            clearPrebufferState(inactive, "finalize-non-prebuffer");
            assignPlayerSource(inactive, Utils.createVideo(""), "non-prebuffer-clear");
        } else {
            prebufferTimer.restart();
        }

        refreshWatchdog();
    }

    function handleMediaStatus(target) {
        const active = (root.player === target);

        if (active && target.mediaStatus === MediaPlayer.EndOfMedia) {
            if (root.transitionState === root.statePendingSwap) {
                holdActiveFrameIfNearTail(target);
                return;
            }
            if (!root.crossfadeEnabled && root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow) {
                root.next(true);
            }
            return;
        }

        if (active && target.mediaStatus === MediaPlayer.LoadedMedia && target.seekable) {
            if (root.restoreLastPosition && root.resumeLastVideo && root.lastVideoPosition < target.duration) {
                target.position = root.lastVideoPosition;
            }
            root.restoreLastPosition = false;
        }

        if (!target.prebufferPending) {
            return;
        }

        if (!ensurePrebufferEventCurrent(target, `media-status-${target.mediaStatus}`)) {
            return;
        }

        if (target.mediaStatus === MediaPlayer.EndOfMedia) {
            if (target.position > 0) {
                markPrebufferReady(target, "end-of-media");
            } else {
                root.logDebug("prebuffer", `end-without-progress player=${target.objectName} target=${root.shortFilename(target.prebufferTargetFilename)}`);
                failPrebufferTarget(target, "end-without-progress");
            }
            return;
        }

        if (target.mediaStatus === MediaPlayer.InvalidMedia || target.mediaStatus === MediaPlayer.NoMedia) {
            root.logDebug("prebuffer", `invalid player=${target.objectName} target=${root.shortFilename(target.prebufferTargetFilename)}`);
            failPrebufferTarget(target, "invalid-media");
            return;
        }

        if ((target.mediaStatus === MediaPlayer.LoadedMedia || target.mediaStatus === MediaPlayer.BufferedMedia)
                && !target.playing) {
            // Keep warming playback until first frame progress is observed.
            target.play();
        }
    }

    function maybeTriggerTransitionFromPosition(activePlayer) {
        if (root.transitionState === root.statePendingSwap || root.transitionState === root.stateFading) {
            return;
        }

        if (root.crossfadeEnabled
                && (activePlayer.position / activePlayer.playbackRate) > (activePlayer.actualDuration - root.crossfadeMinDurationCurrent)) {
            if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow) {
                root.next(true);
            } else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Never) {
                root.next(false);
            }
            return;
        }

        if (!root.crossfadeEnabled
                && root.prebufferNextVideo
                && root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow
                && !root.currentSource.loop
                && root.multipleVideos
                && activePlayer.duration > 0
                && activePlayer.position >= Math.max(0, activePlayer.duration - root.holdTailLeadMs)) {
            root.next(true);
        }
    }

    function handlePosition(target) {
        const active = (root.player === target);

        if (active) {
            if (target === videoPlayer1) {
                if (!root.restoreLastPosition) {
                    root.lastVideoPosition = target.position;
                }
            } else {
                root.lastVideoPosition = target.position;
            }

            maybeTriggerTransitionFromPosition(target);

            if (root.transitionState === root.statePendingSwap) {
                holdActiveFrameIfNearTail(target);
            }
            return;
        }

        if (root.transitionState === root.stateFading && root.isPendingFadeIncoming(target)) {
            root.startVisualFadeIfReady("position-progress");
        }

        if (target.prebufferPending && target.position >= root.prebufferWarmupMinMs) {
            markPrebufferReady(target, "position-progress");
        }
    }

    function handleSourceChanged(target) {
        if (!target.prebufferPending || !target.source) {
            return;
        }
        if (!ensurePrebufferEventCurrent(target, "source-changed")) {
            return;
        }
        if (!target.playing) {
            root.logDebug("prebuffer", `source-changed warmup player=${target.objectName} target=${root.shortFilename(target.prebufferTargetFilename)}`);
            target.play();
        }
    }

    function next(switchSource, forceSwitch) {
        if (root.transitionState === root.stateFading) {
            return;
        }

        const shouldSwitchSource = (switchSource && !currentSource.loop) || forceSwitch;

        if (!shouldSwitchSource) {
            if (root.transitionState === root.statePendingSwap) {
                return;
            }
            startDirectFade(false, "same-source");
            return;
        }

        if (!root.prebufferNextVideo) {
            if (root.transitionState === root.statePendingSwap) {
                return;
            }
            startDirectFade(true, "direct-no-prebuffer");
            return;
        }

        if (root.transitionState === root.statePendingSwap) {
            root.logDebug("transition", "request ignored while pending");
            return;
        }

        requestPrebufferedSwitch("next");
    }

    PausableTimer {
        id: changeTimer
        running: root.changeWallpaperMode === Enum.ChangeWallpaperMode.OnATimer && root.player.playing
        interval: root.changeWallpaperTimerMs - (root.crossfadeEnabled ? root.crossfadeMinDurationCurrent : 0)
        repeat: true
        useNewIntervalImmediately: true
        onTriggered: {
            if (root.debugEnabled) {
                console.log("Timer triggered, changing wallpaper");
            }
            root.next(true);
        }
        onIntervalChanged: {
            if (root.debugEnabled) {
                root.logDebug("timer", `change interval=${interval}`);
            }
        }
    }

    Timer {
        id: transitionFinalizeTimer
        interval: 1
        repeat: false
        onTriggered: root.finalizeTransition()
    }

    Timer {
        id: prebufferWatchdog
        interval: 150
        repeat: true
        running: false
        onTriggered: {
            const inactive = videoPlayer1.prebufferPending ? videoPlayer1
                    : (videoPlayer2.prebufferPending ? videoPlayer2 : root.otherPlayer);

            if (inactive.prebufferPending && inactive.prebufferStartMs > 0) {
                if (!root.ensurePrebufferEventCurrent(inactive, "watchdog")) {
                    root.refreshWatchdog();
                    return;
                }
                const elapsed = Date.now() - inactive.prebufferStartMs;
                const timeoutBudget = root.prebufferStallTimeoutMs + (inactive.prebufferRetryCount || 0) * root.prebufferRetryExtraTimeoutMs;
                if (elapsed >= timeoutBudget) {
                    root.logDebug("prebuffer", `cancel timeout player=${inactive.objectName} target=${root.shortFilename(inactive.prebufferTargetFilename)} elapsed=${elapsed}ms budget=${timeoutBudget}`);
                    root.failPrebufferTarget(inactive, "timeout");
                    return;
                }
            }

            if (root.transitionState === root.statePendingSwap) {
                if (root.pendingSwitchStartMs <= 0) {
                    root.pendingSwitchStartMs = Date.now();
                }
                root.maybeStartPendingSwap("watchdog");
                root.holdActiveFrameIfNearTail(root.player);

                const pendingElapsed = Date.now() - root.pendingSwitchStartMs;
                if (pendingElapsed >= root.pendingSwitchTimeoutMs) {
                    root.logDebug("transition", `pending-timeout elapsed=${pendingElapsed}ms target=${root.shortFilename(root.pendingTargetFilename)}`);
                    root.cancelPendingSwap("timeout", root.pendingTargetFilename);
                    return;
                }
            }
            if (root.transitionState === root.stateFading && root.fadeVisualPending) {
                root.startVisualFadeIfReady("watchdog");
            }

            root.refreshWatchdog();
        }
    }

    VideoPlayer {
        id: videoPlayer1
        objectName: "1"
        anchors.fill: parent

        property var playerSource: Utils.createVideo("")
        property int actualDuration: duration / playbackRate
        property bool prebufferPending: false
        property bool prebufferReady: false
        property string prebufferTargetFilename: ""
        property int prebufferGeneration: 0
        property real prebufferStartMs: 0
        property int prebufferReadyPosition: 0
        property int prebufferRetryCount: 0

        playbackRate: {
            if (root.useAlternativePlaybackRate) {
                return playerSource.alternativePlaybackRate || root.alternativePlaybackRateGlobal;
            }
            return playerSource.playbackRate || root.playbackRate;
        }
        source: playerSource.filename ?? ""
        volume: root.volume
        muted: root.muted || !root.primaryPlayer
        z: 2
        opacity: 1
        fillMode: root.fillMode
        fillBlur: root.fillBlur
        fillBlurRadius: root.fillBlurRadius

        loops: {
            if (!root.multipleVideos || (root.currentSource.loop && !root.crossfadeEnabled))
                return MediaPlayer.Infinite;
            else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow)
                return 1;
            else
                return MediaPlayer.Infinite;
        }

        onPositionChanged: root.handlePosition(videoPlayer1)
        onMediaStatusChanged: root.handleMediaStatus(videoPlayer1)
        onSourceChanged: root.handleSourceChanged(videoPlayer1)

        onLoopsChanged: {
            if (root.primaryPlayer) {
                let pos = videoPlayer1.position;
                videoPlayer1.stop();
                videoPlayer1.play();
                videoPlayer1.position = pos;
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.crossfadeDuration
                easing.type: Easing.OutQuint
            }
        }
    }

    VideoPlayer {
        id: videoPlayer2
        objectName: "2"
        anchors.fill: parent

        property var playerSource: Utils.createVideo("")
        property int actualDuration: duration / playbackRate
        property bool prebufferPending: false
        property bool prebufferReady: false
        property string prebufferTargetFilename: ""
        property int prebufferGeneration: 0
        property real prebufferStartMs: 0
        property int prebufferReadyPosition: 0
        property int prebufferRetryCount: 0

        playbackRate: {
            if (root.useAlternativePlaybackRate) {
                return playerSource.alternativePlaybackRate || root.alternativePlaybackRateGlobal;
            }
            return playerSource.playbackRate || root.playbackRate;
        }
        source: playerSource.filename ?? ""
        volume: root.volume
        muted: root.muted || root.primaryPlayer
        z: 1
        opacity: 1
        fillMode: root.fillMode
        fillBlur: root.fillBlur
        fillBlurRadius: root.fillBlurRadius

        loops: {
            if (!root.multipleVideos || (root.currentSource.loop && !root.crossfadeEnabled))
                return MediaPlayer.Infinite;
            else if (root.changeWallpaperMode === Enum.ChangeWallpaperMode.Slideshow)
                return 1;
            else
                return MediaPlayer.Infinite;
        }

        onPositionChanged: root.handlePosition(videoPlayer2)
        onMediaStatusChanged: root.handleMediaStatus(videoPlayer2)
        onSourceChanged: root.handleSourceChanged(videoPlayer2)

        onLoopsChanged: {
            if (!root.primaryPlayer) {
                let pos = videoPlayer2.position;
                videoPlayer2.stop();
                videoPlayer2.play();
                videoPlayer2.position = pos;
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: root.crossfadeDuration
                easing.type: Easing.OutQuint
            }
        }
    }

    onNextSourceChanged: {
        const nextFilename = root.sourceFilename(root.nextSource);

        if (nextFilename !== root.lastFailedTargetFilename) {
            root.lastFailedTargetFilename = "";
        }

        if (!root.prebufferNextVideo) {
            return;
        }

        if (root.transitionState === root.statePendingSwap) {
            if (nextFilename) {
                root.pendingTargetFilename = nextFilename;
                root.logDebug("transition", `pending target updated=${root.shortFilename(root.pendingTargetFilename)} from nextSource`);
            } else {
                root.logDebug("transition", "nextSource became empty while pending; keeping existing pending target");
            }
        }

        if (!nextFilename) {
            if (root.transitionState === root.statePrebuffering) {
                setTransitionState(root.stateIdle, "nextSource-empty");
            }
            return;
        }

        startPrebufferForInactive("nextSource-changed");
        maybeStartPendingSwap("nextSource-changed");
    }

    onCurrentSourceChanged: syncActivePlayerSource(false)

    onPrimaryPlayerChanged: {
        if (root.prebufferNextVideo && root.transitionState !== root.stateFading) {
            prebufferTimer.restart();
        }
    }

    Timer {
        id: prebufferTimer
        interval: 200
        onTriggered: root.startPrebufferForInactive("timer")
    }

    Component.onCompleted: {
        Qt.callLater(() => {
            videoPlayer1.z = 2;
            videoPlayer2.z = 1;
            videoPlayer1.opacity = 1;
            videoPlayer2.opacity = 1;
            syncActivePlayerSource(true);
            if (root.prebufferNextVideo) {
                startPrebufferForInactive("component-init");
            }
        });
    }

    onPrebufferNextVideoChanged: {
        if (root.prebufferNextVideo) {
            root.logDebug("transition", "prebuffer enabled");
            startPrebufferForInactive("prebuffer-enabled");
            return;
        }

        root.logDebug("transition", "prebuffer disabled");
        if (root.transitionState === root.statePendingSwap) {
            cancelPendingSwap("prebuffer-disabled", "");
        }

        releaseTailHold(true);
        setTransitionState(root.stateIdle, "prebuffer-disabled");

        root.pendingTargetFilename = "";
        root.pendingAdvancePlaylist = false;
        clearPrebufferState(videoPlayer1, "prebuffer-disabled");
        clearPrebufferState(videoPlayer2, "prebuffer-disabled");

        assignPlayerSource(root.otherPlayer, Utils.createVideo(""), "non-prebuffer-clear");
        refreshWatchdog();
    }
}
