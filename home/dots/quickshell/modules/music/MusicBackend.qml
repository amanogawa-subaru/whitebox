import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Item {
    id: root

    visible: false
    width: 0
    height: 0

    property bool active: false

    // ═════════════════════════════════════════
    // MPRIS player
    // ═════════════════════════════════════════

    property var player:
        Mpris.players.values.length > 0
            ? Mpris.players.values[0]
            : null

    property bool hasPlayer:
        root.player !== null

    property string title:
        root.player && root.player.trackTitle
            ? root.player.trackTitle
            : ""

    property string artist:
        root.player && root.player.trackArtist
            ? root.player.trackArtist
            : ""

    property bool playing:
        root.player
            ? root.player.playbackState
                === MprisPlaybackState.Playing
            : false

    property string compactText: {
        if (
            root.artist.length > 0
            && root.title.length > 0
        ) {
            return root.artist
                + " — "
                + root.title
        }

        if (root.title.length > 0)
            return root.title

        if (root.artist.length > 0)
            return root.artist

        return "Unknown track"
    }

    // ═════════════════════════════════════════
    // playerctl target
    // ═════════════════════════════════════════

    property string playerctlName: {
        if (
            !root.player
            || !root.player.dbusName
        ) {
            return ""
        }

        return root.player.dbusName.replace(
            /^org\.mpris\.MediaPlayer2\./,
            ""
        )
    }

    // ═════════════════════════════════════════
    // Media URL / YouTube helpers
    // ═════════════════════════════════════════

    property string mediaUrl: {
        if (
            !root.player
            || !root.player.metadata
        ) {
            return ""
        }

        const value =
            root.player.metadata["xesam:url"]

        return value
            ? value.toString()
            : ""
    }

    property string youtubeId: {
        const url =
            root.mediaUrl

        if (!url)
            return ""

        let match =
            url.match(/[?&]v=([^&#]+)/)

        if (
            match
            && match[1]
        ) {
            return match[1]
        }

        match =
            url.match(
                /youtu\.be\/([^?&#/]+)/
            )

        if (
            match
            && match[1]
        ) {
            return match[1]
        }

        match =
            url.match(
                /youtube\.com\/shorts\/([^?&#/]+)/
            )

        if (
            match
            && match[1]
        ) {
            return match[1]
        }

        return ""
    }

    property bool isYouTube:
        root.youtubeId.length > 0

    // ═════════════════════════════════════════
    // Scrubber state
    // ═════════════════════════════════════════

    property real cachedTrackLength: 0

    property bool scrubbing: false
    property real scrubPosition: 0

    property bool durationQueryPending: false
    property bool ytDurationQueryPending: false

    /*
     * Remember which YouTube video yt-dlp has
     * already resolved.
     */
    property string ytDurationVideoId: ""

    property bool canScrub:
        root.hasPlayer
        && root.cachedTrackLength > 0

    property real trackLength:
        root.cachedTrackLength

    property real displayPosition: {
        if (root.scrubbing)
            return root.scrubPosition

        if (root.player)
            return root.player.position

        return 0
    }

    property real progress: {
        if (
            root.trackLength <= 0
        ) {
            return 0
        }

        return Math.max(
            0,
            Math.min(
                1,
                root.displayPosition
                / root.trackLength
            )
        )
    }

    // ═════════════════════════════════════════
    // Time helpers
    // ═════════════════════════════════════════

    function formatTime(seconds) {
        if (
            !isFinite(seconds)
            || seconds < 0
        ) {
            seconds = 0
        }

        const total =
            Math.floor(seconds)

        const minutes =
            Math.floor(total / 60)

        const remaining =
            total % 60

        return minutes
            + ":"
            + (
                remaining < 10
                    ? "0"
                    : ""
            )
            + remaining
    }

    // ═════════════════════════════════════════
    // Duration — MPRIS first
    // ═════════════════════════════════════════

    function queryDuration() {
        if (
            !root.hasPlayer
            || root.playerctlName.length <= 0
            || root.durationQueryPending
        ) {
            return
        }

        root.durationQueryPending =
            true

        durationProcess.exec([
            "playerctl",
            "--player",
            root.playerctlName,
            "metadata",
            "mpris:length"
        ])
    }

    /*
     * yt-dlp fallback.
     *
     * Only runs when:
     *
     * - MPRIS duration is still unavailable
     * - current media is YouTube / YouTube Music
     * - we haven't already queried this video
     */
    function queryYoutubeDuration() {
        if (
            !root.hasPlayer
            || !root.isYouTube
            || root.youtubeId.length <= 0
            || root.mediaUrl.length <= 0
            || root.cachedTrackLength > 0
            || root.ytDurationQueryPending
            || root.ytDurationVideoId
                === root.youtubeId
        ) {
            return
        }

        /*
         * Mark it immediately so repeated timer
         * ticks don't launch duplicate yt-dlp
         * processes.
         */
        root.ytDurationVideoId =
            root.youtubeId

        root.ytDurationQueryPending =
            true

        ytDurationProcess.exec([
            "yt-dlp",
            "--no-playlist",
            "--skip-download",
            "--print",
            "duration",
            root.mediaUrl
        ])
    }

    // ═════════════════════════════════════════
    // Duration processes
    // ═════════════════════════════════════════

    Process {
        id: durationProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const raw =
                    Number(text.trim())

                if (
                    isFinite(raw)
                    && raw > 0
                ) {
                    /*
                     * MPRIS length:
                     * microseconds → seconds
                     */
                    root.cachedTrackLength =
                        raw / 1000000
                }
            }
        }

        onExited: {
            root.durationQueryPending =
                false

            /*
             * Firefox sometimes simply omits
             * mpris:length.
             *
             * If that happened, try yt-dlp.
             */
            if (
                root.cachedTrackLength <= 0
            ) {
                root.queryYoutubeDuration()
            }
        }
    }

    Process {
        id: ytDurationProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const raw =
                    Number(text.trim())

                if (
                    isFinite(raw)
                    && raw > 0
                ) {
                    /*
                     * yt-dlp already returns
                     * seconds.
                     */
                    root.cachedTrackLength =
                        raw
                }
            }
        }

        onExited: {
            root.ytDurationQueryPending =
                false
        }
    }

    // ═════════════════════════════════════════
    // Duration polling
    // ═════════════════════════════════════════

    Timer {
        id: durationPollTimer

        interval:
            500

        repeat:
            true

        running:
            root.hasPlayer

        triggeredOnStart:
            true

        onTriggered: {
            /*
             * Once we have a valid duration,
             * don't keep querying unnecessarily.
             */
            if (
                root.cachedTrackLength > 0
            ) {
                return
            }

            /*
             * First preference is MPRIS.
             */
            root.queryDuration()

            /*
             * If yt-dlp has not already been
             * attempted for this video, it can
             * fill the missing duration.
             */
            root.queryYoutubeDuration()
        }
    }

    // ═════════════════════════════════════════
    // Seeking
    // ═════════════════════════════════════════

    function seekTo(target) {
        if (
            !root.player
            || root.trackLength <= 0
            || root.playerctlName.length <= 0
        ) {
            return
        }

        const safeTarget =
            Math.max(
                0,
                Math.min(
                    root.trackLength,
                    target
                )
            )

        seekProcess.exec([
            "playerctl",
            "--player",
            root.playerctlName,
            "position",
            safeTarget.toString()
        ])
    }

    Process {
        id: seekProcess

        onExited: {
            seekRefreshTimer.restart()
        }
    }

    Timer {
        id: seekRefreshTimer

        interval:
            50

        repeat:
            false

        onTriggered: {
            if (root.player)
                root.player.positionChanged()
        }
    }

    // ═════════════════════════════════════════
    // Playback actions
    // ═════════════════════════════════════════

    function previous() {
        if (
            root.player
            && root.player.canGoPrevious
        ) {
            root.player.previous()
        }
    }

    function togglePlaying() {
        if (
            root.player
            && root.player.canTogglePlaying
        ) {
            root.player.togglePlaying()
        }
    }

    function next() {
        if (
            root.player
            && root.player.canGoNext
        ) {
            root.player.next()
        }
    }

    // ═════════════════════════════════════════
    // Player / track changes
    // ═════════════════════════════════════════

    onPlayerChanged: {
        root.cachedTrackLength =
            0

        root.durationQueryPending =
            false

        root.ytDurationQueryPending =
            false

        root.ytDurationVideoId =
            ""

        if (root.player) {
            root.queryDuration()
        }
    }

    Connections {
        target:
            root.player

        function onTrackChanged() {
            /*
             * New song:
             *
             * invalidate the previous duration
             * and allow a fresh yt-dlp lookup.
             */
            root.cachedTrackLength =
                0

            root.ytDurationVideoId =
                ""

            root.durationQueryPending =
                false

            root.ytDurationQueryPending =
                false

            root.queryDuration()
        }

        function onPostTrackChanged() {
            if (
                root.cachedTrackLength <= 0
            ) {
                root.queryDuration()
            }
        }
    }

    /*
     * The YouTube ID is the cleanest indicator
     * that the browser has moved to another
     * YouTube / YouTube Music video.
     */
    onYoutubeIdChanged: {
        root.cachedTrackLength =
            0

        root.ytDurationVideoId =
            ""

        root.ytDurationQueryPending =
            false

        /*
         * Artwork also resets on track change.
         */
        root.youtubeArtworkStage =
            0

        if (
            root.youtubeId.length > 0
        ) {
            root.queryDuration()
        }
    }

    // ═════════════════════════════════════════
    // Position refresh
    // ═════════════════════════════════════════

    FrameAnimation {
        running:
            root.active
            && root.player
            && root.playing
            && !root.scrubbing

        onTriggered: {
            if (root.player)
                root.player.positionChanged()
        }
    }

    // ═════════════════════════════════════════
    // Artwork
    // ═════════════════════════════════════════

    property int youtubeArtworkStage:
        0

    property url artworkSource: {
        if (!root.isYouTube) {
            return root.player
                && root.player.trackArtUrl
                    ? root.player.trackArtUrl
                    : ""
        }

        const base =
            "https://i.ytimg.com/vi/"
            + root.youtubeId
            + "/"

        if (
            root.youtubeArtworkStage === 0
        ) {
            return base
                + "maxresdefault.jpg"
        }

        if (
            root.youtubeArtworkStage === 1
        ) {
            return base
                + "sddefault.jpg"
        }

        if (
            root.youtubeArtworkStage === 2
        ) {
            return base
                + "hqdefault.jpg"
        }

        return root.player
            && root.player.trackArtUrl
                ? root.player.trackArtUrl
                : ""
    }

    function advanceArtworkStage() {
        if (
            root.isYouTube
            && root.youtubeArtworkStage < 3
        ) {
            root.youtubeArtworkStage++
        }
    }
}
