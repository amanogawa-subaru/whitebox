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

    /*
     * Selected MPRIS player.
     *
     * Do not bind this to Mpris.players.values[0]: that is only
     * collection order and causes the first-opened app to win forever.
     *
     * Instead, every MPRIS player below is watched independently.
     * The most recent player to enter Playing state becomes active.
     */
    property var player: null

    property bool hasPlayer:
        root.player !== null

    /*
     * Display metadata is intentionally cached instead of being bound
     * directly to the selected player's live metadata.
     *
     * Firefox/YouTube can change MPRIS metadata for hover/autoplay
     * previews while playback is paused. Those changes should not
     * rewrite the compact music module.
     */
    property string cachedTitle: ""
    property string cachedArtist: ""
    property string cachedMediaUrl: ""
    property url cachedTrackArtUrl: ""

    property string title:
        root.cachedTitle

    property string artist:
        root.cachedArtist

    property bool playing:
        root.player
            ? root.player.playbackState
                === MprisPlaybackState.Playing
            : false

    function playerMediaUrl(player) {
        if (
            !player
            || !player.metadata
        ) {
            return ""
        }

        const value =
            player.metadata["xesam:url"]

        return value
            ? value.toString()
            : ""
    }

    function isFirefoxYouTube(player) {
        if (!player)
            return false

        const dbusName =
            player.dbusName
                ? player.dbusName.toLowerCase()
                : ""

        const isFirefoxFamily =
            dbusName.includes("firefox")
            || dbusName.includes("librewolf")

        if (!isFirefoxFamily)
            return false

        const url =
            root.playerMediaUrl(
                player
            )

        return (
            url.includes("youtube.com/")
            || url.includes("youtu.be/")
        )
    }

    function hasUsableTrackMetadata(player) {
        if (!player)
            return false

        /*
         * Firefox/LibreWolf YouTube hover previews can enter Playing
         * and publish a preview title/artist/artwork while omitting a
         * real track length.
         *
         * Quickshell exposes this directly as lengthSupported/length,
         * which is more reliable than reading raw metadata keys.
         */
        if (
            !root.isFirefoxYouTube(
                player
            )
        ) {
            return true
        }

        return (
            player.lengthSupported
            && player.length > 0
        )
    }

    function snapshotMetadata(player) {
        if (!player)
            return

        root.cachedTitle =
            player.trackTitle
                ? player.trackTitle
                : ""

        root.cachedArtist =
            player.trackArtist
                ? player.trackArtist
                : ""

        root.cachedMediaUrl =
            root.playerMediaUrl(
                player
            )

        root.cachedTrackArtUrl =
            player.trackArtUrl
                ? player.trackArtUrl
                : ""
    }

    function selectPlayer(player) {
        if (
            !player
            || !root.hasUsableTrackMetadata(
                player
            )
        ) {
            return false
        }

        const changed =
            root.player !== player

        root.player =
            player

        /*
         * A player is selected only because it became active, was
         * discovered as the best fallback, or replaced a vanished
         * player. Take one clean metadata snapshot at that point.
         */
        root.snapshotMetadata(
            player
        )

        if (changed) {
            root.cachedTrackLength =
                0

            root.durationQueryPending =
                false

            root.ytDurationQueryPending =
                false

            root.ytDurationVideoId =
                ""

            root.scrubbing =
                false

            root.cachedPosition =
                (
                    player.position !== undefined
                    && isFinite(player.position)
                    && player.position >= 0
                )
                    ? player.position
                    : 0

            root.lastPositionTickMs =
                Date.now()

            root.queryDuration()
        }

        return true
    }

    function selectBestFallback() {
        const players =
            Mpris.players.values

        if (players.length <= 0) {
            root.player =
                null

            root.cachedTitle =
                ""

            root.cachedArtist =
                ""

            root.cachedMediaUrl =
                ""

            root.cachedTrackArtUrl =
                ""

            root.cachedPosition =
                0

            root.lastPositionTickMs =
                0

            return
        }

        /*
         * Prefer anything that is currently playing.
         */
        for (
            let i = 0;
            i < players.length;
            ++i
        ) {
            if (
                players[i].playbackState
                === MprisPlaybackState.Playing
                && root.selectPlayer(
                    players[i]
                )
            ) {
                return
            }
        }

        /*
         * If nothing is playing, keep the existing paused/stopped
         * player when it still exists. This preserves the last real
         * track instead of jumping around between idle players.
         */
        if (
            root.player
            && players.indexOf(root.player) >= 0
        ) {
            return
        }

        /*
         * Last fallback: expose one valid MPRIS player so the module
         * never becomes unusable merely because the priority heuristic
         * has no winner.
         */
        for (
            let i = 0;
            i < players.length;
            ++i
        ) {
            if (
                root.selectPlayer(
                    players[i]
                )
            ) {
                return
            }
        }
    }

    function handlePlaybackStateChanged(player) {
        if (!player)
            return

        if (
            player.playbackState
            === MprisPlaybackState.Playing
        ) {
            /*
             * Most recent real Playing transition wins.
             * Firefox/YouTube previews are rejected by
             * hasUsableTrackMetadata().
             */
            root.selectPlayer(
                player
            )
            return
        }

        if (root.player !== player)
            return

        /*
         * The active player paused/stopped. If another source is still
         * playing, immediately hand control to it. Otherwise retain the
         * paused player's cached metadata.
         */
        const players =
            Mpris.players.values

        for (
            let i = 0;
            i < players.length;
            ++i
        ) {
            const candidate =
                players[i]

            if (
                candidate !== player
                && candidate.playbackState
                    === MprisPlaybackState.Playing
            ) {
                root.selectPlayer(
                    candidate
                )
                return
            }
        }
    }

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

    property string mediaUrl:
        root.cachedMediaUrl

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

    /*
     * Keep the displayed playback position locally instead of binding
     * the UI directly to player.position. Some MPRIS players update
     * their position coarsely or briefly report stale values, which can
     * make the timer/progress bar jump or flicker.
     */
    property real cachedPosition: 0
    property double lastPositionTickMs: 0

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

        return root.cachedPosition
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

        root.cachedPosition =
            safeTarget

        root.lastPositionTickMs =
            Date.now()

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
            root.requestPositionSync(
                true
            )
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

    /*
     * Firefox/LibreWolf often emits trackChanged before YouTube has
     * finished publishing the new title/artist/length. Refreshing
     * immediately can therefore read the previous video's metadata.
     *
     * Debounce the refresh very briefly and read MPRIS again after
     * YouTube's SPA navigation has settled.
     */
    property var pendingMetadataPlayer: null

    /*
     * Last valid track signature seen for every MPRIS player.
     *
     * This lets an already-Playing background source become active
     * when it starts a genuinely different track. Firefox/LibreWolf
     * hover previews never enter this map because they fail
     * hasUsableTrackMetadata().
     */
    property var validTrackSignatures:
        ({})

    function trackSignature(player) {
        if (
            !player
            || !root.hasUsableTrackMetadata(
                player
            )
        ) {
            return ""
        }

        const title =
            player.trackTitle
                ? player.trackTitle.toString()
                : ""

        const artist =
            player.trackArtist
                ? player.trackArtist.toString()
                : ""

        const url =
            root.playerMediaUrl(
                player
            )

        /*
         * Duration is deliberately not part of track identity. Some
         * players publish/refine it after title and artist, and treating
         * that maturation as a new track causes needless state resets.
         */
        return (
            title
            + "\u001f"
            + artist
            + "\u001f"
            + url
        )
    }

    Timer {
        id: metadataRefreshDelay

        interval:
            300

        repeat:
            false

        onTriggered: {
            const candidate =
                root.pendingMetadataPlayer

            root.pendingMetadataPlayer =
                null

            if (
                !candidate
                || root.player !== candidate
                || candidate.playbackState
                    !== MprisPlaybackState.Playing
                || !root.hasUsableTrackMetadata(
                    candidate
                )
            ) {
                return
            }

            const oldSignature =
                root.cachedTitle
                + "\u001f"
                + root.cachedArtist
                + "\u001f"
                + root.cachedMediaUrl

            const newTitle =
                candidate.trackTitle
                    ? candidate.trackTitle.toString()
                    : ""

            const newArtist =
                candidate.trackArtist
                    ? candidate.trackArtist.toString()
                    : ""

            const newUrl =
                root.playerMediaUrl(
                    candidate
                )

            const newSignature =
                newTitle
                + "\u001f"
                + newArtist
                + "\u001f"
                + newUrl

            const realTrackChange =
                oldSignature.length > 2
                && newSignature.length > 2
                && oldSignature !== newSignature

            root.snapshotMetadata(
                candidate
            )

            if (realTrackChange) {
                root.cachedTrackLength =
                    0

                root.cachedPosition =
                    0

                root.lastPositionTickMs =
                    Date.now()

                root.ytDurationVideoId =
                    ""

                root.durationQueryPending =
                    false

                root.ytDurationQueryPending =
                    false

                root.queryDuration()
            } else if (
                root.cachedTrackLength <= 0
            ) {
                root.queryDuration()
            }
        }
    }

    function scheduleMetadataRefresh(player) {
        if (!player)
            return

        root.pendingMetadataPlayer =
            player

        metadataRefreshDelay.restart()
    }

    /*
     * Firefox/LibreWolf do not reliably emit a useful trackChanged
     * signal for every YouTube SPA navigation. Keep the event-driven
     * path above, but also synchronize the selected player's already-
     * local MPRIS metadata while it is actually playing.
     *
     * This does not make network requests. It only rereads the MPRIS
     * properties Quickshell already has.
     */
    function syncDisplayedMetadata() {
        const candidate =
            root.player

        if (
            !candidate
            || candidate.playbackState
                !== MprisPlaybackState.Playing
            || !root.hasUsableTrackMetadata(
                candidate
            )
        ) {
            return
        }

        const liveTitle =
            candidate.trackTitle
                ? candidate.trackTitle.toString()
                : ""

        const liveArtist =
            candidate.trackArtist
                ? candidate.trackArtist.toString()
                : ""

        const liveUrl =
            root.playerMediaUrl(
                candidate
            )

        const liveArtUrl =
            candidate.trackArtUrl
                ? candidate.trackArtUrl.toString()
                : ""

        const cachedArtUrl =
            root.cachedTrackArtUrl
                ? root.cachedTrackArtUrl.toString()
                : ""

        if (
            liveTitle === root.cachedTitle
            && liveArtist === root.cachedArtist
            && liveUrl === root.cachedMediaUrl
            && liveArtUrl === cachedArtUrl
        ) {
            return
        }

        const oldSignature =
            root.cachedTitle
            + "\u001f"
            + root.cachedArtist
            + "\u001f"
            + root.cachedMediaUrl

        const newSignature =
            liveTitle
            + "\u001f"
            + liveArtist
            + "\u001f"
            + liveUrl

        const realTrackChange =
            oldSignature.length > 2
            && newSignature.length > 2
            && oldSignature !== newSignature

        root.snapshotMetadata(
            candidate
        )

        if (realTrackChange) {
            root.cachedTrackLength =
                0

            root.cachedPosition =
                0

            root.lastPositionTickMs =
                Date.now()

            root.ytDurationVideoId =
                ""

            root.durationQueryPending =
                false

            root.ytDurationQueryPending =
                false

            root.queryDuration()
        } else if (
            root.cachedTrackLength <= 0
        ) {
            root.queryDuration()
        }
    }

    Timer {
        id: metadataSyncPoll

        interval:
            300

        running:
            root.player
            && root.playing

        repeat:
            true

        triggeredOnStart:
            true

        onTriggered: {
            const players =
                Mpris.players.values

            const nextSignatures =
                ({})

            let newestTrackPlayer =
                null

            for (
                let i = 0;
                i < players.length;
                ++i
            ) {
                const candidate =
                    players[i]

                if (
                    candidate.playbackState
                    !== MprisPlaybackState.Playing
                    || !root.hasUsableTrackMetadata(
                        candidate
                    )
                ) {
                    continue
                }

                const key =
                    candidate.dbusName
                        ? candidate.dbusName.toString()
                        : (
                            candidate.identity
                                ? candidate.identity.toString()
                                : candidate.toString()
                        )

                const signature =
                    root.trackSignature(
                        candidate
                    )

                nextSignatures[key] =
                    signature

                const previous =
                    root.validTrackSignatures[key]

                /*
                 * Only an already-known player changing from one
                 * valid real track to another counts as new activity.
                 * The first observation merely establishes baseline
                 * state and cannot steal focus.
                 */
                if (
                    previous
                    && signature
                    && previous !== signature
                ) {
                    newestTrackPlayer =
                        candidate
                }
            }

            /*
             * Preserve signatures for players that are temporarily
             * paused so resume itself remains governed by the existing
             * playback-state selection logic.
             */
            const oldKeys =
                Object.keys(
                    root.validTrackSignatures
                )

            for (
                let i = 0;
                i < oldKeys.length;
                ++i
            ) {
                const key =
                    oldKeys[i]

                if (!nextSignatures[key]) {
                    nextSignatures[key] =
                        root.validTrackSignatures[key]
                }
            }

            root.validTrackSignatures =
                nextSignatures

            if (
                newestTrackPlayer
                && newestTrackPlayer
                    !== root.player
            ) {
                root.selectPlayer(
                    newestTrackPlayer
                )
            }

            root.syncDisplayedMetadata()
        }
    }

    /*
     * Repeater is used only as a convenient way to instantiate one
     * hidden watcher Item per MPRIS player. The delegates have no size
     * and never render anything.
     */
    Repeater {
        id: playerWatchers

        model:
            Mpris.players

        onCountChanged:
            Qt.callLater(
                root.selectBestFallback
            )

        delegate:
            Item {
                required property var modelData

                visible:
                    false

                width:
                    0

                height:
                    0

                Component.onCompleted: {
                    /*
                     * A newly-created player may already be Playing
                     * before its watcher exists.
                     */
                    if (
                        modelData.playbackState
                        === MprisPlaybackState.Playing
                    ) {
                        root.selectPlayer(
                            modelData
                        )
                    } else if (!root.player) {
                        root.selectBestFallback()
                    }
                }

                Connections {
                    target:
                        modelData

                    function onPlaybackStateChanged() {
                        root.handlePlaybackStateChanged(
                            modelData
                        )
                    }

                    function onTrackChanged() {
                        /*
                         * Firefox can enter Playing before all of its
                         * MPRIS metadata is ready. If there is no
                         * selected player yet, reconsider it when its
                         * track metadata arrives.
                         */
                        if (
                            !root.player
                            && modelData.playbackState
                                === MprisPlaybackState.Playing
                            && root.hasUsableTrackMetadata(
                                modelData
                            )
                        ) {
                            root.selectPlayer(
                                modelData
                            )
                            return
                        }

                        /*
                         * Only accept live metadata changes from the
                         * selected player while it is actually Playing.
                         *
                         * Paused Firefox/YouTube hover previews can
                         * emit track changes; those are intentionally
                         * ignored.
                         */
                        if (
                            root.player
                            !== modelData
                            || modelData.playbackState
                                !== MprisPlaybackState.Playing
                            || !root.hasUsableTrackMetadata(
                                modelData
                            )
                        ) {
                            return
                        }

                        root.scheduleMetadataRefresh(
                            modelData
                        )
                    }

                    function onPostTrackChanged() {
                        /*
                         * Some players finalize metadata in the
                         * post-track signal. This is also another
                         * chance to bootstrap Firefox after its
                         * metadata becomes usable.
                         */
                        if (
                            !root.player
                            && modelData.playbackState
                                === MprisPlaybackState.Playing
                            && root.hasUsableTrackMetadata(
                                modelData
                            )
                        ) {
                            root.selectPlayer(
                                modelData
                            )
                            return
                        }

                        if (
                            root.player
                            === modelData
                            && modelData.playbackState
                                === MprisPlaybackState.Playing
                        ) {
                            root.scheduleMetadataRefresh(
                                modelData
                            )
                        }
                    }
                }
            }
    }

    /*
     * Firefox can expose its MPRIS player before track length and
     * metadata are fully populated. Retry briefly while no player has
     * been selected instead of requiring another app to wake us up.
     */
    Timer {
        id: initialPlayerRetry

        interval:
            500

        running:
            !root.player

        repeat:
            true

        triggeredOnStart:
            true

        onTriggered:
            root.selectBestFallback()
    }

    /*
     * The cached URL is the clean track identity used by our YouTube
     * artwork/duration helpers.
     */
    onYoutubeIdChanged: {
        root.cachedTrackLength =
            0

        root.ytDurationVideoId =
            ""

        root.ytDurationQueryPending =
            false

        root.youtubeArtworkStage =
            0

        if (
            root.youtubeId.length > 0
            && root.player
            && root.player.playbackState
                === MprisPlaybackState.Playing
        ) {
            root.queryDuration()
        }
    }

    // ═════════════════════════════════════════
    // Position clock / MPRIS reconciliation
    // ═════════════════════════════════════════

    function syncPositionFromPlayer(force) {
        if (
            !root.player
            || root.scrubbing
        ) {
            return
        }

        const live =
            Number(root.player.position)

        if (
            !isFinite(live)
            || live < 0
        ) {
            return
        }

        const difference =
            Math.abs(
                live
                - root.cachedPosition
            )

        /*
         * Ignore small discrepancies from coarse MPRIS clocks so the
         * visible timer does not step backward/forward. Large differences
         * are treated as a real seek or meaningful drift.
         */
        if (
            force
            || !root.playing
            || difference >= 1.5
        ) {
            root.cachedPosition =
                live
        }

        root.lastPositionTickMs =
            Date.now()
    }

    function requestPositionSync(force) {
        if (!root.player)
            return

        /*
         * Refresh the MPRIS Position property once, then read it after
         * Quickshell has had a chance to process the update.
         */
        root.player.positionChanged()

        Qt.callLater(
            function() {
                root.syncPositionFromPlayer(
                    force === true
                )
            }
        )
    }

    /*
     * Smooth local clock for the visible timer and progress bar.
     */
    Timer {
        id: positionClock

        interval:
            100

        repeat:
            true

        running:
            root.active
            && root.player
            && root.playing
            && !root.scrubbing

        triggeredOnStart:
            true

        onTriggered: {
            const now =
                Date.now()

            if (root.lastPositionTickMs <= 0) {
                root.lastPositionTickMs =
                    now
                return
            }

            const elapsed =
                Math.max(
                    0,
                    (
                        now
                        - root.lastPositionTickMs
                    ) / 1000
                )

            root.lastPositionTickMs =
                now

            root.cachedPosition =
                Math.max(
                    0,
                    Math.min(
                        root.trackLength > 0
                            ? root.trackLength
                            : Number.MAX_VALUE,
                        root.cachedPosition
                            + elapsed
                    )
                )
        }
    }

    /*
     * MPRIS stays authoritative, but we only sample it occasionally.
     * Seeks and playback-state transitions still force an immediate sync.
     */
    Timer {
        id: positionSyncTimer

        interval:
            5000

        repeat:
            true

        running:
            root.active
            && root.player
            && !root.scrubbing

        triggeredOnStart:
            true

        onTriggered:
            root.requestPositionSync(
                !root.playing
            )
    }

    Connections {
        target:
            root.player

        function onPlaybackStateChanged() {
            if (!root.player)
                return

            root.lastPositionTickMs =
                Date.now()

            root.requestPositionSync(
                true
            )
        }
    }

    // ═════════════════════════════════════════
    // Artwork
    // ═════════════════════════════════════════

    property int youtubeArtworkStage:
        0

    property url artworkSource: {
        if (!root.isYouTube)
            return root.cachedTrackArtUrl

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

        return root.cachedTrackArtUrl
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
