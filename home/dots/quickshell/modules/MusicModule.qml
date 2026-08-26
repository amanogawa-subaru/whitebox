import QtQuick
import Quickshell
import Quickshell.Services.Mpris

import "../Config"

Item {
    id: root

    property bool hovered: mouseArea.containsMouse
    property bool expanded: false
    property bool contentVisible: false

    // ─────────────────────────────────────────
    // Compact sizing
    // ─────────────────────────────────────────

    property real musicMinWidth:
        220 * Appearance.scale

    property real musicMaxWidth:
        500 * Appearance.scale

    property real compactHorizontalPadding:
        28 * Appearance.scale

    property real compactSpacing:
        10 * Appearance.scale

    // ─────────────────────────────────────────
    // MPRIS
    // ─────────────────────────────────────────

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

    // ─────────────────────────────────────────
    // High-resolution artwork
    // ─────────────────────────────────────────

    /*
     * Firefox's MPRIS extension gives us a
     * hilariously tiny 60x60 mpris:artUrl.
     *
     * But it also exposes the real media page
     * through xesam:url.
     *
     * For YouTube:
     *
     * xesam:url
     *      ↓
     * video ID
     *      ↓
     * i.ytimg.com high-resolution thumbnail
     *
     * Everything else continues using MPRIS art.
     */

    property string mediaUrl: {
        if (!root.player || !root.player.metadata)
            return ""

        const value =
            root.player.metadata["xesam:url"]

        return value
            ? value.toString()
            : ""
    }

    property string youtubeId: {
        const url = root.mediaUrl

        if (!url)
            return ""

        /*
         * Standard:
         * youtube.com/watch?v=VIDEO_ID
         */
        let match =
            url.match(/[?&]v=([^&#]+)/)

        if (match && match[1])
            return match[1]

        /*
         * Short:
         * youtu.be/VIDEO_ID
         */
        match =
            url.match(
                /youtu\.be\/([^?&#/]+)/
            )

        if (match && match[1])
            return match[1]

        /*
         * Shorts:
         * youtube.com/shorts/VIDEO_ID
         */
        match =
            url.match(
                /youtube\.com\/shorts\/([^?&#/]+)/
            )

        if (match && match[1])
            return match[1]

        return ""
    }

    property bool isYouTube:
        root.youtubeId.length > 0

    property int youtubeArtworkStage: 0

    /*
     * Stage 0:
     * maxresdefault
     *
     * Stage 1:
     * sddefault
     *
     * Stage 2:
     * hqdefault
     *
     * Stage 3:
     * original MPRIS artwork
     */

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

        if (root.youtubeArtworkStage === 0)
            return base + "maxresdefault.jpg"

        if (root.youtubeArtworkStage === 1)
            return base + "sddefault.jpg"

        if (root.youtubeArtworkStage === 2)
            return base + "hqdefault.jpg"

        return root.player
            && root.player.trackArtUrl
                ? root.player.trackArtUrl
                : ""
    }

    onYoutubeIdChanged: {
        youtubeArtworkStage = 0
    }

    // ─────────────────────────────────────────
    // Text measurement
    // ─────────────────────────────────────────

    TextMetrics {
        id: compactTextMetrics

        font.pixelSize:
            Appearance.textSize

        text:
            root.compactText
    }

    // ─────────────────────────────────────────
    // Open / Close
    // ─────────────────────────────────────────

    function open() {
        if (!root.hasPlayer)
            return

        collapseDelay.stop()

        root.expanded = true
        root.contentVisible = false

        contentDelay.restart()
    }

    function close() {
        if (!root.expanded)
            return

        contentDelay.stop()

        root.contentVisible = false
        collapseDelay.restart()
    }

    function toggle() {
        if (root.expanded)
            root.close()
        else
            root.open()
    }

    onHasPlayerChanged: {
        if (!root.hasPlayer && root.expanded)
            root.close()
    }

    // ─────────────────────────────────────────
    // Geometry
    // ─────────────────────────────────────────

    width: {
        if (root.expanded)
            return 320 * Appearance.scale

        if (!root.hasPlayer)
            return Appearance.moduleHeight

        const wantedWidth =
            compactTextMetrics.advanceWidth
            + musicIcon.implicitWidth
            + root.compactSpacing
            + root.compactHorizontalPadding

        return Math.max(
            root.musicMinWidth,
            Math.min(
                wantedWidth,
                root.musicMaxWidth
            )
        )
    }

    height:
        root.expanded
            ? expandedContent.implicitHeight
                + 32 * Appearance.scale
            : Appearance.moduleHeight

    Behavior on width {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    // ─────────────────────────────────────────
    // Outer shell
    // ─────────────────────────────────────────

    Rectangle {
        id: background

        anchors.fill: parent

        radius:
            Appearance.moduleRadius

        color:
            root.hasPlayer
                ? Colors.base
                : Colors.green

        border.width:
            Appearance.borderWidth

        border.color:
            Colors.green

        scale:
            root.hovered && !root.expanded
                ? 1.09
                : 1.0

        transformOrigin:
            Item.Center

        Behavior on color {
            ColorAnimation {
                duration: 200
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.9
            }
        }
    }

    // ─────────────────────────────────────────
    // Compact view
    // ─────────────────────────────────────────

    Row {
        id: compactContent

        visible:
            !root.expanded

        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter

            leftMargin:
                root.hasPlayer
                    ? 14 * Appearance.scale
                    : 0

            rightMargin:
                root.hasPlayer
                    ? 14 * Appearance.scale
                    : 0
        }

        spacing:
            root.hasPlayer
                ? root.compactSpacing
                : 0

        Text {
            id: musicIcon

            width:
                root.hasPlayer
                    ? implicitWidth
                    : parent.width

            anchors.verticalCenter:
                parent.verticalCenter

            text:
                "󰎆"

            font.family:
                "Symbols Nerd Font"

            font.pixelSize:
                Appearance.iconSize

            color:
                root.hasPlayer
                    ? Colors.green
                    : Colors.base

            horizontalAlignment:
                Text.AlignHCenter

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }

        Text {
            visible:
                root.hasPlayer

            width:
                parent.width
                - musicIcon.width
                - parent.spacing

            anchors.verticalCenter:
                parent.verticalCenter

            text:
                root.compactText

            color:
                Colors.text

            font.pixelSize:
                Appearance.textSize

            elide:
                Text.ElideRight

            maximumLineCount:
                1
        }
    }

    // ─────────────────────────────────────────
    // Expanded content
    // ─────────────────────────────────────────

    Column {
        id: expandedContent

        z: 2

        width:
            root.width
            - 32 * Appearance.scale

        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter

            topMargin:
                16 * Appearance.scale
        }

        spacing:
            14 * Appearance.scale

        visible:
            opacity > 0

        opacity:
            root.contentVisible
                ? 1.0
                : 0.0

        transform: Translate {
            y:
                root.contentVisible
                    ? 0
                    : 8

            Behavior on y {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutCubic
            }
        }

        // ─────────────────────────────────────
        // Album art
        // ─────────────────────────────────────

        Rectangle {
            id: albumArtContainer

            width:
                280 * Appearance.scale

            height:
                width

            anchors.horizontalCenter:
                parent.horizontalCenter

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            clip:
                true

            Image {
                id: albumArt

                anchors.fill:
                    parent

                source:
                    root.artworkSource

                fillMode:
                    Image.PreserveAspectCrop

                smooth:
                    true

                mipmap:
                    true

                asynchronous:
                    true

                cache:
                    true

                visible:
                    status === Image.Ready

                onStatusChanged: {
                    if (status !== Image.Error)
                        return

                    /*
                     * YouTube artwork failed.
                     * Walk down through increasingly
                     * compatible thumbnail sizes.
                     */
                    if (
                        root.isYouTube
                        && root.youtubeArtworkStage < 3
                    ) {
                        root.youtubeArtworkStage++
                    }
                }
            }

            Text {
                anchors.centerIn:
                    parent

                visible:
                    albumArt.status !== Image.Ready

                text:
                    "󰝚"

                font.family:
                    "Symbols Nerd Font"

                font.pixelSize:
                    64 * Appearance.scale

                color:
                    Colors.green
            }
        }

        // ─────────────────────────────────────
        // Track info
        // ─────────────────────────────────────

        Rectangle {
            id: trackInfoCard

            width:
                parent.width

            implicitHeight:
                trackInfoColumn.implicitHeight
                + 28 * Appearance.scale

            height:
                implicitHeight

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            Column {
                id: trackInfoColumn

                width:
                    parent.width
                    - 28 * Appearance.scale

                anchors.centerIn:
                    parent

                spacing:
                    7 * Appearance.scale

                Text {
                    width:
                        parent.width

                    text:
                        root.title.length > 0
                            ? root.title
                            : "Unknown track"

                    horizontalAlignment:
                        Text.AlignHCenter

                    color:
                        Colors.text

                    font.pixelSize:
                        Appearance.textSize + 2

                    font.bold:
                        true

                    wrapMode:
                        Text.Wrap

                    maximumLineCount:
                        3

                    elide:
                        Text.ElideRight
                }

                Text {
                    width:
                        parent.width

                    text:
                        root.artist.length > 0
                            ? root.artist
                            : "Unknown artist"

                    horizontalAlignment:
                        Text.AlignHCenter

                    color:
                        Colors.green

                    font.pixelSize:
                        Appearance.textSize

                    wrapMode:
                        Text.Wrap

                    maximumLineCount:
                        2

                    elide:
                        Text.ElideRight
                }
            }
        }

        // ─────────────────────────────────────
        // Playback controls
        // ─────────────────────────────────────

        Rectangle {
            id: playbackCard

            width:
                parent.width

            height:
                74 * Appearance.scale

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            Row {
                anchors.centerIn:
                    parent

                spacing:
                    30 * Appearance.scale

                // Previous

                Item {
                    width:
                        38 * Appearance.scale

                    height:
                        width

                    Text {
                        anchors.centerIn:
                            parent

                        text:
                            "󰒮"

                        font.family:
                            "Symbols Nerd Font"

                        font.pixelSize:
                            Appearance.iconSize + 2

                        color:
                            previousMouse.containsMouse
                                ? Colors.green
                                : Colors.text

                        scale:
                            previousMouse.containsMouse
                                ? 1.15
                                : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }

                    MouseArea {
                        id: previousMouse

                        anchors.fill:
                            parent

                        hoverEnabled:
                            true

                        onClicked: {
                            if (
                                root.player
                                && root.player.canGoPrevious
                            ) {
                                root.player.previous()
                            }
                        }
                    }
                }

                // Play / Pause

                Item {
                    width:
                        46 * Appearance.scale

                    height:
                        width

                    Text {
                        anchors.centerIn:
                            parent

                        text:
                            root.playing
                                ? "󰏤"
                                : "󰐊"

                        font.family:
                            "Symbols Nerd Font"

                        font.pixelSize:
                            Appearance.iconSize + 8

                        color:
                            playMouse.containsMouse
                                ? Colors.green
                                : Colors.text

                        scale:
                            playMouse.containsMouse
                                ? 1.15
                                : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }

                    MouseArea {
                        id: playMouse

                        anchors.fill:
                            parent

                        hoverEnabled:
                            true

                        onClicked: {
                            if (!root.player)
                                return

                            if (root.player.canTogglePlaying)
                                root.player.togglePlaying()
                        }
                    }
                }

                // Next

                Item {
                    width:
                        38 * Appearance.scale

                    height:
                        width

                    Text {
                        anchors.centerIn:
                            parent

                        text:
                            "󰒭"

                        font.family:
                            "Symbols Nerd Font"

                        font.pixelSize:
                            Appearance.iconSize + 2

                        color:
                            nextMouse.containsMouse
                                ? Colors.green
                                : Colors.text

                        scale:
                            nextMouse.containsMouse
                                ? 1.15
                                : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutBack
                                easing.overshoot: 1.4
                            }
                        }
                    }

                    MouseArea {
                        id: nextMouse

                        anchors.fill:
                            parent

                        hoverEnabled:
                            true

                        onClicked: {
                            if (
                                root.player
                                && root.player.canGoNext
                            ) {
                                root.player.next()
                            }
                        }
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // Compact interaction
    // ─────────────────────────────────────────

    MouseArea {
        id: mouseArea

        z: 3

        visible:
            !root.expanded

        enabled:
            !root.expanded

        anchors.fill:
            parent

        hoverEnabled:
            true

        onClicked: {
            if (root.hasPlayer)
                root.open()
        }
    }

    // ─────────────────────────────────────────
    // Animation timing
    // ─────────────────────────────────────────

    Timer {
        id: contentDelay

        interval:
            280

        repeat:
            false

        onTriggered: {
            root.contentVisible = true
        }
    }

    Timer {
        id: collapseDelay

        interval:
            200

        repeat:
            false

        onTriggered: {
            root.expanded = false
        }
    }
}
