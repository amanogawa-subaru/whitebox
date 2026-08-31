import QtQuick
import Quickshell
import Quickshell.Wayland

import "../../Config"

Scope {
    id: root

    required property var backend
    required property var screen

    // ═════════════════════════════════════════
    // State
    // ═════════════════════════════════════════

    property bool opened: false
    property bool closing: false

    /*
     * Opening scale is kept separate from the close motion.
     *
     * On close, bounceScale and collapseScale overlap so the
     * outward rebound flows directly into the implosion instead
     * of stopping at an apex between two animations.
     */
    property real pickerScale: 0.86
    property real bounceScale: 1.0
    property real collapseScale: 1.0

    property real pickerOpacity: 0.0

    /*
     * Expanded content opacity.
     *
     * Header contents and gallery contents use this,
     * while the shell itself remains visible for the
     * close wipe.
     */
    property real contentOpacity: 0.0

    /*
     * Y position of the rising base-color wipe.
     *
     * During closing this travels from the bottom
     * edge of the yellow header to the inner top
     * border, visually "eating" the header upward.
     */
    property real closeFillTop:
        root.headerHeight

    property bool collapseBase: false

    // ═════════════════════════════════════════
    // Design
    // ═════════════════════════════════════════

    readonly property color accentColor:
        Colors.yellow

    readonly property real pickerWidth:
        760 * Appearance.scale

    readonly property real pickerHeight:
        500 * Appearance.scale

    readonly property real headerHeight:
        58 * Appearance.scale

    readonly property real cardWidth:
        320 * Appearance.scale

    readonly property real cardHeight:
        205 * Appearance.scale

    readonly property real cardSpacing:
        16 * Appearance.scale

    readonly property real innerEdge:
        Appearance.borderWidth

    // ═════════════════════════════════════════
    // Open / Close
    // ═════════════════════════════════════════

    function open() {
        closeAnimation.stop()
        openAnimation.stop()

        root.closing =
            false

        root.collapseBase =
            false

        root.closeFillTop =
            root.headerHeight

        root.pickerScale =
            0.86

        root.bounceScale =
            1.0

        root.collapseScale =
            1.0

        root.pickerOpacity =
            0.0

        /*
         * Content exists from frame one.
         * The complete picker fades in together.
         */
        root.contentOpacity =
            1.0

        root.opened =
            true

        root.backend.refreshWallpapers()

        openAnimation.restart()
        focusDelay.restart()
    }

    function close() {
        if (
            !root.opened
            || root.closing
        ) {
            return
        }

        focusDelay.stop()
        openAnimation.stop()

        root.closing =
            true

        root.collapseBase =
            false

        root.closeFillTop =
            root.headerHeight

        root.pickerScale =
            1.0

        root.bounceScale =
            1.0

        root.collapseScale =
            1.0

        closeAnimation.restart()
    }

    function toggle() {
        if (root.opened)
            root.close()
        else
            root.open()
    }

    // ═════════════════════════════════════════
    // Helpers
    // ═════════════════════════════════════════

    function basename(path) {
        const pieces =
            String(path).split("/")

        if (pieces.length === 0)
            return String(path)

        return pieces[
            pieces.length - 1
        ]
    }

    function fileUrl(path) {
        return encodeURI(
            "file://" + String(path)
        )
    }

    // ═════════════════════════════════════════
    // Overlay window
    // ═════════════════════════════════════════

    PanelWindow {
        id: pickerWindow

        screen:
            root.screen

        visible:
            root.opened
            || root.closing

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone:
            0

        focusable:
            true

        color:
            "transparent"

        WlrLayershell.layer:
            WlrLayer.Overlay

        WlrLayershell.keyboardFocus:
            root.opened
                ? WlrKeyboardFocus.OnDemand
                : WlrKeyboardFocus.None

        FocusScope {
            id: pickerFocus

            anchors.fill:
                parent

            focus:
                root.opened

            Keys.onEscapePressed: event => {
                root.close()

                event.accepted =
                    true
            }

            // ═════════════════════════════════
            // Transparent click-away layer
            // ═════════════════════════════════

            MouseArea {
                anchors.fill:
                    parent

                enabled:
                    root.opened
                    && !root.closing

                onClicked:
                    root.close()
            }

            // ═════════════════════════════════
            // Main picker shell
            // ═════════════════════════════════

            Rectangle {
                id: pickerShell

                width:
                    Math.min(
                        root.pickerWidth,
                        parent.width
                            - 40
                            * Appearance.scale
                    )

                height:
                    Math.min(
                        root.pickerHeight,
                        parent.height
                            - 40
                            * Appearance.scale
                    )

                anchors.centerIn:
                    parent

                radius:
                    Appearance.moduleRadius

                color:
                    root.collapseBase
                        ? Colors.base
                        : root.accentColor

                border.width:
                    Appearance.borderWidth

                border.color:
                    root.accentColor

                opacity:
                    root.pickerOpacity

                scale:
                    root.pickerScale
                    * root.bounceScale
                    * root.collapseScale

                transformOrigin:
                    Item.Center

                Behavior on color {
                    ColorAnimation {
                        duration:
                            160
                    }
                }

                // ═════════════════════════════
                // Normal picker contents
                // ═════════════════════════════

                Item {
                    id: pickerContent

                    /*
                     * Content stays above the wipe.
                     *
                     * The gallery itself is opaque base, so the wipe
                     * remains hidden underneath it. The transparent
                     * yellow header lets the rising base fill show
                     * through as it moves upward.
                     */
                    z:
                        10

                    anchors.fill:
                        parent

                    opacity:
                        root.contentOpacity

                    // ─────────────────────────
                    // Header
                    // ─────────────────────────

                    Item {
                        id: header

                        anchors {
                            left:
                                parent.left

                            right:
                                parent.right

                            top:
                                parent.top
                        }

                        height:
                            root.headerHeight

                        Row {
                            anchors {
                                left:
                                    parent.left

                                leftMargin:
                                    20
                                    * Appearance.scale

                                verticalCenter:
                                    parent.verticalCenter
                            }

                            spacing:
                                9 * Appearance.scale

                            Text {
                                text:
                                    "󰸉"

                                font.family:
                                    "Symbols Nerd Font"

                                font.pixelSize:
                                    Appearance.iconSize

                                color:
                                    Colors.base
                            }

                            Text {
                                text:
                                    "Wallpaper"

                                font.pixelSize:
                                    Appearance.textSize + 3

                                font.bold:
                                    true

                                color:
                                    Colors.base
                            }
                        }

                        Rectangle {
                            width:
                                32 * Appearance.scale

                            height:
                                32 * Appearance.scale

                            anchors {
                                right:
                                    parent.right

                                rightMargin:
                                    14
                                    * Appearance.scale

                                verticalCenter:
                                    parent.verticalCenter
                            }

                            radius:
                                Appearance.controlRadius

                            color:
                                closeMouse.containsMouse
                                    ? Colors.base
                                    : "transparent"

                            scale:
                                closeMouse.containsMouse
                                    ? 1.08
                                    : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration:
                                        120
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration:
                                        180

                                    easing.type:
                                        Easing.OutBack

                                    easing.overshoot:
                                        1.3
                                }
                            }

                            Text {
                                anchors.centerIn:
                                    parent

                                text:
                                    "󰅖"

                                font.family:
                                    "Symbols Nerd Font"

                                font.pixelSize:
                                    Appearance.iconSize

                                color:
                                    closeMouse.containsMouse
                                        ? root.accentColor
                                        : Colors.base

                                Behavior on color {
                                    ColorAnimation {
                                        duration:
                                            120
                                    }
                                }
                            }

                            MouseArea {
                                id: closeMouse

                                anchors.fill:
                                    parent

                                hoverEnabled:
                                    true

                                onClicked:
                                    root.close()
                            }
                        }
                    }

                    // ─────────────────────────
                    // Gallery inset
                    // ─────────────────────────

                    Rectangle {
                        id: galleryCard

                        anchors {
                            left:
                                parent.left

                            right:
                                parent.right

                            top:
                                header.bottom

                            bottom:
                                parent.bottom

                            margins:
                                Appearance.borderWidth
                        }

                        radius:
                            Math.max(
                                0,
                                Appearance.moduleRadius
                                - Appearance.borderWidth
                            )

                        color:
                            Colors.base

                        clip:
                            true

                        Flickable {
                            id: galleryFlick

                            anchors {
                                fill:
                                    parent

                                margins:
                                    18
                                    * Appearance.scale
                            }

                            clip:
                                true

                            boundsBehavior:
                                Flickable.StopAtBounds

                            contentWidth:
                                width

                            contentHeight:
                                wallpaperGrid.height
                                + 16 * Appearance.scale

                            property int columnCount:
                                Math.max(
                                    1,
                                    Math.floor(
                                        width
                                        / (
                                            root.cardWidth
                                            + root.cardSpacing
                                        )
                                    )
                                )

                            Grid {
                                id: wallpaperGrid
                                
                                y:
                                    8 * Appearance.scale

                                anchors.horizontalCenter:
                                    parent.horizontalCenter

                                columns:
                                    galleryFlick.columnCount

                                width:
                                    columns
                                    * root.cardWidth
                                    + Math.max(
                                        0,
                                        columns - 1
                                    )
                                    * root.cardSpacing

                                columnSpacing:
                                    root.cardSpacing

                                rowSpacing:
                                    root.cardSpacing

                                Repeater {
                                    model:
                                        root.backend.wallpapers
                                        || []

                                    delegate: Rectangle {
                                        id: wallpaperCard

                                        required property var modelData
                                        required property int index

                                        property bool selected:
                                            String(
                                                modelData
                                            )
                                            === root.backend
                                                .currentWallpaper

                                        width:
                                            root.cardWidth

                                        height:
                                            root.cardHeight

                                        radius:
                                            Appearance.controlRadius

                                        color:
                                            Colors.surface0

                                        border.width: {
                                            if (
                                                wallpaperCard.selected
                                            ) {
                                                return Appearance
                                                    .borderWidth
                                            }

                                            if (
                                                cardMouse
                                                    .containsMouse
                                            ) {
                                                return Appearance
                                                    .borderWidth
                                                    / 2
                                            }

                                            return 0
                                        }

                                        border.color:
                                            wallpaperCard.selected
                                                ? root.accentColor
                                                : Colors.surface2

                                        scale:
                                            cardMouse.containsMouse
                                                ? 1.035
                                                : 1.0

                                        Behavior on scale {
                                            NumberAnimation {
                                                duration:
                                                    200

                                                easing.type:
                                                    Easing.OutBack

                                                easing.overshoot:
                                                    1.35
                                            }
                                        }

                                        Behavior on border.width {
                                            NumberAnimation {
                                                duration:
                                                    120
                                            }
                                        }

                                        Behavior on border.color {
                                            ColorAnimation {
                                                duration:
                                                    120
                                            }
                                        }

                                        Image {
                                            anchors {
                                                fill:
                                                    parent

                                                margins:
                                                    wallpaperCard.selected
                                                        ? Appearance.borderWidth
                                                        : 0
                                            }

                                            source:
                                                root.fileUrl(
                                                    modelData
                                                )

                                            fillMode:
                                                Image.PreserveAspectCrop

                                            smooth:
                                                true

                                            asynchronous:
                                                true

                                            cache:
                                                true
                                        }

                                        Rectangle {
                                            anchors {
                                                left:
                                                    parent.left

                                                right:
                                                    parent.right

                                                bottom:
                                                    parent.bottom

                                                margins:
                                                    wallpaperCard.selected
                                                        ? Appearance.borderWidth
                                                        : 0
                                            }

                                            height:
                                                38
                                                * Appearance.scale

                                            color:
                                                Colors.crust

                                            opacity:
                                                0.88

                                            Text {
                                                anchors {
                                                    left:
                                                        parent.left

                                                    right:
                                                        selectedBadge.left

                                                    leftMargin:
                                                        10
                                                        * Appearance.scale

                                                    rightMargin:
                                                        8
                                                        * Appearance.scale

                                                    verticalCenter:
                                                        parent.verticalCenter
                                                }

                                                text:
                                                    root.basename(
                                                        modelData
                                                    )

                                                color:
                                                    Colors.text

                                                font.pixelSize:
                                                    Appearance.textSize
                                                    - 2

                                                elide:
                                                    Text.ElideMiddle
                                            }

                                            Text {
                                                id: selectedBadge

                                                anchors {
                                                    right:
                                                        parent.right

                                                    rightMargin:
                                                        10
                                                        * Appearance.scale

                                                    verticalCenter:
                                                        parent.verticalCenter
                                                }

                                                visible:
                                                    wallpaperCard.selected

                                                text:
                                                    "󰄬"

                                                font.family:
                                                    "Symbols Nerd Font"

                                                font.pixelSize:
                                                    Appearance.iconSize
                                                    - 2

                                                color:
                                                    root.accentColor
                                            }
                                        }

                                        MouseArea {
                                            id: cardMouse

                                            anchors.fill:
                                                parent

                                            hoverEnabled:
                                                true

                                            enabled:
                                                root.opened
                                                && !root.closing

                                            onClicked: {
                                                root.backend
                                                    .setWallpaper(
                                                        modelData
                                                    )

                                                root.close()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.centerIn:
                                parent

                            visible:
                                !root.backend.wallpapers
                                || root.backend
                                    .wallpapers.length
                                    === 0

                            text:
                                "No wallpapers found"

                            color:
                                Colors.overlay0

                            font.pixelSize:
                                Appearance.textSize
                        }
                    }
                }

                // ═════════════════════════════
                // Closing base wipe
                // ═════════════════════════════

                Rectangle {
                    id: closeFill

                    z:
                        5

                    visible:
                        root.closing

                    x:
                        root.innerEdge

                    y:
                        root.closeFillTop

                    width:
                        Math.max(
                            0,
                            pickerShell.width
                            - root.innerEdge * 2
                        )

                    height:
                        Math.max(
                            0,
                            pickerShell.height
                            - root.closeFillTop
                            - root.innerEdge
                        )

                    radius:
                        Math.max(
                            0,
                            Appearance.moduleRadius
                            - root.innerEdge
                        )

                    color:
                        Colors.base
                }
            }
        }
    }

    // ═════════════════════════════════════════
    // Opening choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: openAnimation

        ParallelAnimation {
            NumberAnimation {
                target:
                    root

                property:
                    "pickerOpacity"

                from:
                    0.0

                to:
                    1.0

                duration:
                    320

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    root

                property:
                    "pickerScale"

                from:
                    0.86

                to:
                    1.0

                duration:
                    300

                easing.type:
                    Easing.OutBack

                easing.overshoot:
                    1.9
            }
        }
    }

    // ═════════════════════════════════════════
    // Closing choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: closeAnimation

        /*
         * The key difference from the previous version:
         *
         * bounceScale and collapseScale run independently
         * and overlap. The collapse starts while the bounce
         * is still moving outward, so there is never a true
         * stationary apex.
         */
        ParallelAnimation {
            // ─────────────────────────────
            // Contents fade
            // ─────────────────────────────

            NumberAnimation {
                target:
                    root

                property:
                    "contentOpacity"

                from:
                    1.0

                to:
                    0.0

                duration:
                    320

                easing.type:
                    Easing.InOutCubic
            }

            // ─────────────────────────────
            // Header wipe
            // ─────────────────────────────

            NumberAnimation {
                target:
                    root

                property:
                    "closeFillTop"

                from:
                    root.headerHeight

                to:
                    root.innerEdge

                duration:
                    320

                easing.type:
                    Easing.InOutCubic
            }

            // ─────────────────────────────
            // Squish + rebound
            // ─────────────────────────────

            SequentialAnimation {
                NumberAnimation {
                    target:
                        root

                    property:
                        "bounceScale"

                    from:
                        1.0

                    to:
                        0.965

                    duration:
                        70

                    easing.type:
                        Easing.InCubic
                }

                NumberAnimation {
                    target:
                        root

                    property:
                        "bounceScale"

                    from:
                        0.965

                    to:
                        1.065

                    duration:
                        250

                    easing.type:
                        Easing.OutBack

                    easing.overshoot:
                        1.3
                }
            }

            // ─────────────────────────────
            // Collapse
            //
            // Starts before rebound ends.
            // This is what removes the apex hold.
            // ─────────────────────────────

            SequentialAnimation {
                PauseAnimation {
                    duration:
                        220
                }

                NumberAnimation {
                    target:
                        root

                    property:
                        "collapseScale"

                    from:
                        1.0

                    to:
                        0.0

                    duration:
                        430

                    easing.type:
                        Easing.InCubic
                }
            }

            // ─────────────────────────────
            // Whole-window fade
            //
            // Longer than before.
            // It starts while the collapse is underway
            // and finishes before the tiny final scale.
            // ─────────────────────────────

            SequentialAnimation {
                PauseAnimation {
                    duration:
                        250
                }

                NumberAnimation {
                    target:
                        root

                    property:
                        "pickerOpacity"

                    from:
                        1.0

                    to:
                        0.0

                    duration:
                        360

                    easing.type:
                        Easing.InOutCubic
                }
            }

            // ─────────────────────────────
            // Finish turning shell base-colored
            // after the wipe reaches the top.
            // ─────────────────────────────

            SequentialAnimation {
                PauseAnimation {
                    duration:
                        320
                }

                ScriptAction {
                    script: {
                        root.collapseBase =
                            true
                    }
                }
            }
        }

        // ═════════════════════════════════════
        // Closed state
        // ═════════════════════════════════════

        ScriptAction {
            script: {
                root.opened =
                    false

                root.closing =
                    false

                root.collapseBase =
                    false

                root.pickerScale =
                    0.86

                root.bounceScale =
                    1.0

                root.collapseScale =
                    1.0

                root.pickerOpacity =
                    0.0

                root.contentOpacity =
                    0.0

                root.closeFillTop =
                    root.headerHeight
            }
        }
    }

    // ═════════════════════════════════════════
    // Keyboard focus
    // ═════════════════════════════════════════

    Timer {
        id: focusDelay

        interval:
            50

        repeat:
            false

        onTriggered:
            pickerFocus.forceActiveFocus()
    }
}
