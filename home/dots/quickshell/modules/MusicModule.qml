import QtQuick

import "../Config"
import "music"

FocusScope {
    id: root

    // ─────────────────────────────────────────
    // Backend
    // ─────────────────────────────────────────

    MusicBackend {
        id: music
        active: root.expanded
    }

    // ─────────────────────────────────────────
    // State
    // ─────────────────────────────────────────

    property bool suppressHover: false

    property bool hovered:
        compactMouse.containsMouse
        && !root.suppressHover

    property bool expanded: false
    property bool closing: false
    property bool shrinking: false
    property bool collapseBase: false

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

    TextMetrics {
        id: compactTextMetrics
        font.pixelSize: Appearance.textSize
        text: music.compactText
    }

    TextMetrics {
        id: compactIconMetrics
        font.family: "Symbols Nerd Font"
        font.pixelSize: Appearance.iconSize
        text: "󰎈"
    }

    property real compactWantedWidth: {
        if (!music.hasPlayer)
            return Appearance.moduleHeight

        const wantedWidth =
            compactTextMetrics.advanceWidth
            + compactIconMetrics.advanceWidth
            + root.compactSpacing
            + root.compactHorizontalPadding

        return Math.max(
            root.musicMinWidth,
            Math.min(wantedWidth, root.musicMaxWidth)
        )
    }

    // ─────────────────────────────────────────
    // Design / fixed geometry
    // ─────────────────────────────────────────

    property color accentColor:
        Colors.green

    property real expandedHeaderHeight:
        48 * Appearance.scale

    property real expandedEdgeThickness:
        Appearance.borderWidth

    property real expandedWidth:
        320 * Appearance.scale

    property real contentMargin:
        14 * Appearance.scale

    property real contentSpacing:
        12 * Appearance.scale

    property real albumArtHeight:
        270 * Appearance.scale

    property real trackInfoHeight:
        72 * Appearance.scale

    property real playbackCardHeight:
        105 * Appearance.scale

    property real expandedHeight:
        root.expandedHeaderHeight
        + root.expandedEdgeThickness
        + root.contentMargin * 2
        + root.albumArtHeight
        + root.trackInfoHeight
        + root.playbackCardHeight
        + root.contentSpacing * 2

    property real closeFillTop:
        root.expandedHeaderHeight

    property real closeBounceScale:
        1.0

    // ─────────────────────────────────────────
    // Open / Close
    // ─────────────────────────────────────────

    function open() {
        if (!music.hasPlayer)
            return

        closeAnimation.stop()

        root.suppressHover = false
        root.closing = false
        root.shrinking = false
        root.collapseBase = false
        root.closeFillTop = root.expandedHeaderHeight
        root.closeBounceScale = 1.0

        expandedContent.opacity = 0.0

        music.queryDuration()

        root.expanded = true

        contentDelay.restart()
        focusDelay.restart()
    }

    function close() {
        if (!root.expanded || root.closing)
            return

        music.scrubbing = false

        contentDelay.stop()
        focusDelay.stop()

        root.closing = true
        root.shrinking = false
        root.collapseBase = false
        root.closeFillTop = root.expandedHeaderHeight
        root.closeBounceScale = 1.0

        closeAnimation.restart()
    }

    function toggle() {
        if (root.expanded)
            root.close()
        else
            root.open()
    }

    onExpandedChanged: {
        if (!root.expanded)
            music.scrubbing = false
    }

    Connections {
        target: music

        function onHasPlayerChanged() {
            if (!music.hasPlayer && root.expanded)
                root.close()
        }
    }

    Keys.onEscapePressed: event => {
        if (root.expanded) {
            root.close()
            event.accepted = true
        }
    }

    // ─────────────────────────────────────────
    // Geometry
    // ─────────────────────────────────────────

    width:
        root.expanded && !root.shrinking
            ? root.expandedWidth
            : root.compactWantedWidth

    height:
        root.expanded && !root.shrinking
            ? root.expandedHeight
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

    // ═════════════════════════════════════════
    // Visual root
    // ═════════════════════════════════════════

    Item {
        id: visualRoot

        anchors.fill: parent

        scale: {
            if (root.closing)
                return root.closeBounceScale

            if (root.hovered && !root.expanded)
                return 1.09

            return 1.0
        }

        transformOrigin: Item.Center

        Behavior on scale {
            enabled: !root.closing

            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.9
            }
        }

        Rectangle {
            id: outerShell

            anchors.fill: parent
            radius: Appearance.moduleRadius

            color: {
                if (!music.hasPlayer)
                    return root.accentColor

                if (root.hovered && !root.expanded)
                    return root.accentColor

                if (root.collapseBase)
                    return Colors.base

                if (root.expanded)
                    return root.accentColor

                return Colors.base
            }

            border.width: Appearance.borderWidth
            border.color: root.accentColor

            Behavior on color {
                ColorAnimation { duration: 160 }
            }
        }

        // ─────────────────────────────────────
        // Header
        // ─────────────────────────────────────

        MusicHeader {
            id: musicHeader

            z: 7
            width: visualRoot.width

            anchors {
                left: parent.left
                top: parent.top
            }

            backend: music
            expanded: root.expanded
            closing: root.closing
            hovered: root.hovered
            collapseBase: root.collapseBase
            accentColor: root.accentColor
            compactSpacing: root.compactSpacing
            expandedHeaderHeight: root.expandedHeaderHeight
        }

        // ─────────────────────────────────────
        // Expanded body
        // ─────────────────────────────────────

        Rectangle {
            id: bodyCard

            z: 3
            visible: root.expanded

            x: root.expandedEdgeThickness
            y: root.expandedHeaderHeight

            width:
                Math.max(
                    0,
                    visualRoot.width
                    - root.expandedEdgeThickness * 2
                )

            height:
                Math.max(
                    0,
                    visualRoot.height
                    - root.expandedHeaderHeight
                    - root.expandedEdgeThickness
                )

            radius:
                Math.max(
                    0,
                    Appearance.moduleRadius
                    - root.expandedEdgeThickness
                )

            color: Colors.base
            clip: true

            Column {
                id: expandedContent

                width:
                    parent.width
                    - root.contentMargin * 2

                anchors {
                    top: parent.top
                    horizontalCenter: parent.horizontalCenter
                    topMargin: root.contentMargin
                }

                spacing: root.contentSpacing
                opacity: 0.0

                transform: Translate {
                    y:
                        expandedContent.opacity > 0
                            ? 0
                            : 8 * Appearance.scale

                    Behavior on y {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                AlbumArtCard {
                    width: parent.width
                    height: root.albumArtHeight
                    backend: music
                    accentColor: root.accentColor
                }

                TrackInfoCard {
                    width: parent.width
                    height: root.trackInfoHeight
                    backend: music
                    accentColor: root.accentColor
                }

                PlaybackCard {
                    width: parent.width
                    height: root.playbackCardHeight
                    backend: music
                    accentColor: root.accentColor
                }
            }
        }

        // ─────────────────────────────────────
        // Closing wipe
        // ─────────────────────────────────────

        Rectangle {
            id: closeFill

            z: 5
            visible: root.closing

            x: root.expandedEdgeThickness
            y: root.closeFillTop

            width:
                Math.max(
                    0,
                    visualRoot.width
                    - root.expandedEdgeThickness * 2
                )

            height:
                Math.max(
                    0,
                    visualRoot.height
                    - root.closeFillTop
                    - root.expandedEdgeThickness
                )

            radius:
                Math.max(
                    0,
                    Appearance.moduleRadius
                    - root.expandedEdgeThickness
                )

            color: Colors.base
        }
    }

    // ═════════════════════════════════════════
    // Compact interaction
    // ═════════════════════════════════════════

    MouseArea {
        id: compactMouse

        z: 20
        visible: !root.expanded
        enabled: !root.expanded
        anchors.fill: parent
        hoverEnabled: true

        onExited: {
            root.suppressHover = false
        }

        onClicked: {
            if (!music.hasPlayer)
                return

            root.suppressHover = false
            root.open()
        }
    }

    // ═════════════════════════════════════════
    // Opening
    // ═════════════════════════════════════════

    Timer {
        id: contentDelay
        interval: 210
        repeat: false

        onTriggered: {
            expandedContent.opacity = 1.0
        }
    }

    Timer {
        id: focusDelay
        interval: 50
        repeat: false

        onTriggered: {
            root.forceActiveFocus()
        }
    }

    // ═════════════════════════════════════════
    // Close choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: closeAnimation

        NumberAnimation {
            target: expandedContent
            property: "opacity"
            to: 0.0
            duration: 90
            easing.type: Easing.OutCubic
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "closeFillTop"
                from: root.expandedHeaderHeight
                to: root.expandedEdgeThickness
                duration: 260
                easing.type: Easing.InOutCubic
            }

            SequentialAnimation {
                NumberAnimation {
                    target: root
                    property: "closeBounceScale"
                    from: 1.0
                    to: 0.965
                    duration: 70
                    easing.type: Easing.InCubic
                }

                NumberAnimation {
                    target: root
                    property: "closeBounceScale"
                    from: 0.965
                    to: 1.075
                    duration: 190
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.45
                }
            }
        }

        ScriptAction {
            script: {
                root.collapseBase = true
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "closeBounceScale"
                from: 1.075
                to: 1.0
                duration: 280
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                ScriptAction {
                    script: {
                        root.shrinking = true
                    }
                }

                PauseAnimation { duration: 280 }
            }
        }

        ScriptAction {
            script: {
                root.suppressHover = true
                root.expanded = false
                root.closing = false
                root.shrinking = false
                root.collapseBase = true
                root.closeFillTop = root.expandedHeaderHeight
                root.closeBounceScale = 1.0
                expandedContent.opacity = 0.0
            }
        }
    }
}
