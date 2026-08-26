import QtQuick
import Quickshell
import Quickshell.Io

import "../Config"
import "controls"

FocusScope {
    id: root

    // ═════════════════════════════════════════
    // State
    // ═════════════════════════════════════════

    property bool suppressHover: false

    property bool hovered:
        compactMouse.containsMouse
        && !root.suppressHover

    property bool expanded: false
    property bool closing: false
    property bool shrinking: false
    property bool collapseBase: false

    /*
     * Used only for the Lock fast-close path.
     *
     * When true, width/height Behaviors are
     * temporarily disabled so the module can
     * become genuinely compact BEFORE Hyprlock
     * appears.
     */
    property bool instantGeometry: false

    property string userName:
        "User"

    property string hostName:
        "host"

    property string uptimeText:
        "Up"

    // ═════════════════════════════════════════
    // Design
    // ═════════════════════════════════════════

    property color accentColor:
        Colors.red

    property real expandedWidth:
        Appearance.powerExpandedWidth

    property real expandedHeaderHeight:
        72 * Appearance.scale

    property real expandedEdgeThickness:
        Appearance.borderWidth

    property real contentMargin:
        14 * Appearance.scale

    property real contentSpacing:
        12 * Appearance.scale

    property real controlCardPadding:
        14 * Appearance.scale

    property real controlRowHeight:
        34 * Appearance.scale

    property real closeFillTop:
        root.expandedHeaderHeight

    property real closeBounceScale:
        1.0

    /*
     * Identity visibility is completely
     * independent of module geometry.
     */
    property real headerOpacity:
        0.0

    readonly property real bodyContentHeight:
        controlColumn.implicitHeight
        + root.contentMargin * 2

    readonly property real expandedHeight:
        root.expandedHeaderHeight
        + root.expandedEdgeThickness
        + root.bodyContentHeight

    // ═════════════════════════════════════════
    // Open
    // ═════════════════════════════════════════

    function open() {
        closeAnimation.stop()
        lockCloseAnimation.stop()

        headerDelay.stop()
        headerFadeIn.stop()

        contentDelay.stop()
        focusDelay.stop()

        root.instantGeometry =
            false

        root.suppressHover =
            false

        root.closing =
            false

        root.shrinking =
            false

        root.collapseBase =
            false

        root.closeFillTop =
            root.expandedHeaderHeight

        root.closeBounceScale =
            1.0

        root.headerOpacity =
            0.0

        expandedContent.opacity =
            0.0

        root.expanded =
            true

        /*
         * Wait until the shell is nearly fully
         * expanded before revealing identity.
         */
        headerDelay.restart()

        contentDelay.restart()
        focusDelay.restart()
    }

    // ═════════════════════════════════════════
    // Normal close
    // ═════════════════════════════════════════

    function close() {
        if (
            !root.expanded
            || root.closing
        ) {
            return
        }

        headerDelay.stop()
        headerFadeIn.stop()

        contentDelay.stop()
        focusDelay.stop()

        root.closing =
            true

        root.shrinking =
            false

        root.collapseBase =
            false

        root.closeFillTop =
            root.expandedHeaderHeight

        root.closeBounceScale =
            1.0

        closeAnimation.restart()
    }

    // ═════════════════════════════════════════
    // Lock fast-close
    // ═════════════════════════════════════════

    function lockSession() {
        if (lockCloseAnimation.running)
            return

        /*
         * Kill any normal animation path first.
         */
        closeAnimation.stop()

        headerDelay.stop()
        headerFadeIn.stop()

        contentDelay.stop()
        focusDelay.stop()

        /*
         * The special Lock animation will:
         *
         * 1. fade content,
         * 2. snap Power completely compact,
         * 3. launch Hyprlock.
         */
        lockCloseAnimation.restart()
    }

    Process {
        id: lockProcess

        command: [
            "hyprlock"
        ]
    }

    // ═════════════════════════════════════════
    // Nested device selectors
    // ═════════════════════════════════════════

    function toggleOutputDevices() {
        if (outputSelector.expanded) {
            outputSelector.close()
            return
        }

        inputSelector.close()
        outputSelector.open()
    }

    function toggleInputDevices() {
        if (inputSelector.expanded) {
            inputSelector.close()
            return
        }

        outputSelector.close()
        inputSelector.open()
    }

    Keys.onEscapePressed: event => {
        if (root.expanded) {
            root.close()

            event.accepted =
                true
        }
    }

    // ═════════════════════════════════════════
    // Geometry
    // ═════════════════════════════════════════

    width:
        root.expanded
        && !root.shrinking
            ? root.expandedWidth
            : Appearance.moduleHeight

    height:
        root.expanded
        && !root.shrinking
            ? root.expandedHeight
            : Appearance.moduleHeight

    Behavior on width {
        enabled:
            !root.instantGeometry

        NumberAnimation {
            duration:
                280

            easing.type:
                Easing.OutCubic
        }
    }

    /*
     * During normal selector expansion, the
     * selector's animatedHeight already drives
     * the shell smoothly.
     *
     * During lock fast-close, ALL geometry
     * interpolation is disabled.
     */
    Behavior on height {
        enabled:
            !root.instantGeometry
            && !outputSelector.animating
            && !inputSelector.animating

        NumberAnimation {
            duration:
                280

            easing.type:
                Easing.OutCubic
        }
    }

    // ═════════════════════════════════════════
    // Identity / uptime
    // ═════════════════════════════════════════

    Process {
        id: identityProcess

        command: [
            "sh",
            "-c",
            "printf '%s\\n%s' \"$USER\" \"$(hostname)\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts =
                    text.trim().split("\n")

                if (
                    parts.length > 0
                    && parts[0].length > 0
                ) {
                    root.userName =
                        parts[0]
                }

                if (
                    parts.length > 1
                    && parts[1].length > 0
                ) {
                    root.hostName =
                        parts[1]
                }
            }
        }
    }

    Process {
        id: uptimeProcess

        command: [
            "sh",
            "-c",
            "awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); if (d>0) printf \"Up %dd, %dh\", d, h; else if (h>0) printf \"Up %dh, %dm\", h, m; else printf \"Up %dm\", m}' /proc/uptime"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value =
                    text.trim()

                if (value.length > 0) {
                    root.uptimeText =
                        value
                }
            }
        }
    }

    Timer {
        interval:
            60000

        running:
            true

        repeat:
            true

        onTriggered:
            uptimeProcess.running = true
    }

    Component.onCompleted: {
        identityProcess.running =
            true

        uptimeProcess.running =
            true
    }

    // ═════════════════════════════════════════
    // Visual root
    // ═════════════════════════════════════════

    Item {
        id: visualRoot

        anchors.fill:
            parent

        scale: {
            if (root.closing)
                return root.closeBounceScale

            if (
                root.hovered
                && !root.expanded
            ) {
                return 1.09
            }

            return 1.0
        }

        transformOrigin:
            Item.Center

        Behavior on scale {
            enabled:
                !root.closing
                && !root.instantGeometry

            NumberAnimation {
                duration:
                    300

                easing.type:
                    Easing.OutBack

                easing.overshoot:
                    1.9
            }
        }

        // ─────────────────────────────────────
        // Outer shell
        // ─────────────────────────────────────

        Rectangle {
            anchors.fill:
                parent

            radius:
                Appearance.moduleRadius

            border.width:
                Appearance.borderWidth

            border.color:
                root.accentColor

            color: {
                if (
                    root.hovered
                    && !root.expanded
                ) {
                    return root.accentColor
                }

                if (root.collapseBase)
                    return Colors.base

                if (root.expanded)
                    return root.accentColor

                return Colors.base
            }

            Behavior on color {
                enabled:
                    !root.instantGeometry

                ColorAnimation {
                    duration:
                        150
                }
            }
        }

        // ═════════════════════════════════════
        // Compact power icon
        // ═════════════════════════════════════

        Text {
            z:
                8

            visible:
                !root.expanded

            anchors.centerIn:
                parent

            text:
                "󰐥"

            font.family:
                "Symbols Nerd Font"

            font.pixelSize:
                Appearance.iconSize

            color:
                root.hovered
                    ? Colors.base
                    : root.accentColor

            Behavior on color {
                ColorAnimation {
                    duration:
                        150
                }
            }
        }

        // ═════════════════════════════════════
        // Expanded identity header
        // ═════════════════════════════════════

        Item {
            id: identityHeader

            z:
                7

            visible:
                root.expanded

            width:
                parent.width

            height:
                root.expandedHeaderHeight

            opacity:
                root.headerOpacity

            /*
             * No Translate.
             * No x animation.
             * No y animation.
             *
             * Fade only.
             */
			Column {
				anchors {
					left:
						parent.left

					right:
						parent.right

					leftMargin:
						root.contentMargin
						+ 4 * Appearance.scale

					rightMargin:
						root.contentMargin
						+ 4 * Appearance.scale

					verticalCenter:
						parent.verticalCenter
				}

				spacing:
					3 * Appearance.scale

				// Username
				Text {
					text:
						root.userName

					color:
						Colors.base

					font.pixelSize:
						Appearance.textSize + 2

					font.bold:
						true
				}

				// Hostname + uptime
				Row {
					width:
						parent.width

					Text {
						text:
							root.hostName

						color:
							Qt.rgba(
								Colors.base.r,
								Colors.base.g,
								Colors.base.b,
								0.72
							)

						font.pixelSize:
							Appearance.textSize - 2
					}

					Item {
						width:
							parent.width
							- parent.children[0].width
							- parent.children[2].width

						height:
							1
					}

					Text {
						text:
							root.uptimeText

						color:
							Qt.rgba(
								Colors.base.r,
								Colors.base.g,
								Colors.base.b,
								0.72
							)

						font.pixelSize:
							Appearance.textSize - 2
					}
				}
			}
        }

        // ═════════════════════════════════════
        // Body
        // ═════════════════════════════════════

        Rectangle {
            id: bodyCard

            z:
                3

            visible:
                root.expanded

            x:
                root.expandedEdgeThickness

            y:
                root.expandedHeaderHeight

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

            color:
                Colors.base

            clip:
                true

            Column {
                id: expandedContent

                width:
                    parent.width
                    - root.contentMargin * 2

                anchors {
                    top:
                        parent.top

                    horizontalCenter:
                        parent.horizontalCenter

                    topMargin:
                        root.contentMargin
                }

                opacity:
                    0.0

                transform: Translate {
                    y:
                        expandedContent.opacity > 0
                            ? 0
                            : 8 * Appearance.scale

                    Behavior on y {
                        NumberAnimation {
                            duration:
                                200

                            easing.type:
                                Easing.OutCubic
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration:
                            180

                        easing.type:
                            Easing.OutCubic
                    }
                }

                Column {
                    id: controlColumn

                    width:
                        parent.width

                    spacing:
                        root.contentSpacing

                    // ═════════════════════════
                    // Brightness
                    // ═════════════════════════

                    Rectangle {
                        width:
                            parent.width

                        height:
                            64 * Appearance.scale

                        radius:
                            Appearance.controlRadius

                        color:
                            Colors.surface0

                        BrightnessSlider {
                            anchors {
                                left:
                                    parent.left

                                right:
                                    parent.right

                                verticalCenter:
                                    parent.verticalCenter

                                leftMargin:
                                    root.controlCardPadding

                                rightMargin:
                                    root.controlCardPadding
                            }

                            height:
                                root.controlRowHeight
                        }
                    }

                    // ═════════════════════════
                    // Audio output
                    // ═════════════════════════

                    Rectangle {
                        id: volumeCard

                        width:
                            parent.width

                        height:
                            root.controlCardPadding * 2
                            + root.controlRowHeight
                            + (
                                outputSelector.animatedHeight > 0
                                    ? 8 * Appearance.scale
                                    : 0
                            )
                            + outputSelector.animatedHeight

                        radius:
                            Appearance.controlRadius

                        color:
                            Colors.surface0

                        Column {
                            anchors {
                                left:
                                    parent.left

                                right:
                                    parent.right

                                top:
                                    parent.top

                                margins:
                                    root.controlCardPadding
                            }

                            spacing:
                                8 * Appearance.scale

                            Row {
                                width:
                                    parent.width

                                height:
                                    root.controlRowHeight

                                spacing:
                                    8 * Appearance.scale

                                VolumeControl {
                                    width:
                                        parent.width
                                        - outputArrowButton.width
                                        - parent.spacing

                                    height:
                                        parent.height
                                }

                                Item {
                                    id: outputArrowButton

                                    width:
                                        30 * Appearance.scale

                                    height:
                                        parent.height

                                    Text {
                                        anchors.centerIn:
                                            parent

                                        text:
                                            outputSelector.expanded
                                                ? "▴"
                                                : "▾"

                                        color:
                                            outputArrowMouse.containsMouse
                                                ? Colors.pink
                                                : Colors.subtext0

                                        font.pixelSize:
                                            Appearance.textSize + 1

                                        scale:
                                            outputArrowMouse.containsMouse
                                                ? 1.15
                                                : 1.0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration:
                                                    130
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
                                    }

                                    MouseArea {
                                        id: outputArrowMouse

                                        anchors.fill:
                                            parent

                                        hoverEnabled:
                                            true

                                        onClicked:
                                            root.toggleOutputDevices()
                                    }
                                }
                            }

                            AudioDeviceSelector {
                                id: outputSelector

                                width:
                                    parent.width

                                deviceType:
                                    "sink"

                                accentColor:
                                    Colors.pink
                            }
                        }
                    }

                    // ═════════════════════════
                    // Microphone
                    // ═════════════════════════

                    Rectangle {
                        id: micCard

                        width:
                            parent.width

                        height:
                            root.controlCardPadding * 2
                            + root.controlRowHeight
                            + (
                                inputSelector.animatedHeight > 0
                                    ? 8 * Appearance.scale
                                    : 0
                            )
                            + inputSelector.animatedHeight

                        radius:
                            Appearance.controlRadius

                        color:
                            Colors.surface0

                        Column {
                            anchors {
                                left:
                                    parent.left

                                right:
                                    parent.right

                                top:
                                    parent.top

                                margins:
                                    root.controlCardPadding
                            }

                            spacing:
                                8 * Appearance.scale

                            Row {
                                width:
                                    parent.width

                                height:
                                    root.controlRowHeight

                                spacing:
                                    8 * Appearance.scale

                                MicControl {
                                    width:
                                        parent.width
                                        - inputArrowButton.width
                                        - parent.spacing

                                    height:
                                        parent.height
                                }

                                Item {
                                    id: inputArrowButton

                                    width:
                                        30 * Appearance.scale

                                    height:
                                        parent.height

                                    Text {
                                        anchors.centerIn:
                                            parent

                                        text:
                                            inputSelector.expanded
                                                ? "▴"
                                                : "▾"

                                        color:
                                            inputArrowMouse.containsMouse
                                                ? Colors.mauve
                                                : Colors.subtext0

                                        font.pixelSize:
                                            Appearance.textSize + 1

                                        scale:
                                            inputArrowMouse.containsMouse
                                                ? 1.15
                                                : 1.0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration:
                                                    130
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
                                    }

                                    MouseArea {
                                        id: inputArrowMouse

                                        anchors.fill:
                                            parent

                                        hoverEnabled:
                                            true

                                        onClicked:
                                            root.toggleInputDevices()
                                    }
                                }
                            }

                            AudioDeviceSelector {
                                id: inputSelector

                                width:
                                    parent.width

                                deviceType:
                                    "source"

                                accentColor:
                                    Colors.mauve
                            }
                        }
                    }

                    // ═════════════════════════
                    // Session / power actions
                    // ═════════════════════════

                    PowerActions {
                        width:
                            parent.width

                        onLockRequested:
                            root.lockSession()

                        onCloseRequested:
                            root.close()
                    }
                }
            }
        }

        // ═════════════════════════════════════
        // Normal closing base fill
        // ═════════════════════════════════════

        Rectangle {
            id: closeFill

            z:
                5

            visible:
                root.closing

            x:
                root.expandedEdgeThickness

            y:
                root.closeFillTop

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

            color:
                Colors.base
        }
    }

    // ═════════════════════════════════════════
    // Compact interaction
    // ═════════════════════════════════════════

    MouseArea {
        id: compactMouse

        z:
            20

        visible:
            !root.expanded

        enabled:
            !root.expanded

        anchors.fill:
            parent

        hoverEnabled:
            true

        onExited:
            root.suppressHover = false

        onClicked:
            root.open()
    }

    // ═════════════════════════════════════════
    // Opening choreography
    // ═════════════════════════════════════════

    Timer {
        id: headerDelay

        interval:
            220

        repeat:
            false

        onTriggered:
            headerFadeIn.restart()
    }

    NumberAnimation {
        id: headerFadeIn

        target:
            root

        property:
            "headerOpacity"

        from:
            0.0

        to:
            1.0

        duration:
            180

        easing.type:
            Easing.OutCubic
    }

    Timer {
        id: contentDelay

        interval:
            180

        repeat:
            false

        onTriggered:
            expandedContent.opacity = 1.0
    }

    Timer {
        id: focusDelay

        interval:
            50

        repeat:
            false

        onTriggered:
            root.forceActiveFocus()
    }

    // ═════════════════════════════════════════
    // FAST LOCK choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: lockCloseAnimation

        /*
         * First remove everything visibly
         * identifying the expanded state.
         *
         * Short enough to make Lock feel
         * immediate, but not an ugly teleport.
         */
        ParallelAnimation {
            NumberAnimation {
                target:
                    expandedContent

                property:
                    "opacity"

                to:
                    0.0

                duration:
                    100

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    root

                property:
                    "headerOpacity"

                to:
                    0.0

                duration:
                    100

                easing.type:
                    Easing.OutCubic
            }
        }

        ScriptAction {
            script: {
                /*
                 * IMPORTANT:
                 *
                 * Disable geometry Behaviors
                 * BEFORE changing expanded.
                 *
                 * This means width + height SNAP
                 * to the final compact geometry.
                 */
                root.instantGeometry =
                    true

                root.suppressHover =
                    true

                root.closing =
                    false

                root.shrinking =
                    false

                root.collapseBase =
                    true

                root.closeFillTop =
                    root.expandedHeaderHeight

                root.closeBounceScale =
                    1.0

                root.headerOpacity =
                    0.0

                expandedContent.opacity =
                    0.0

                outputSelector.close()
                inputSelector.close()

                /*
                 * This assignment is now
                 * instantaneous because the width
                 * and height Behaviors are off.
                 */
                root.expanded =
                    false
            }
        }

        /*
         * Give QML one frame to commit the compact
         * geometry before re-enabling normal
         * animations.
         */
        PauseAnimation {
            duration:
                16
        }

        ScriptAction {
            script: {
                root.instantGeometry =
                    false

                /*
                 * NOW the module is fully compact.
                 *
                 * Only now do we hand control to
                 * Hyprlock.
                 */
                lockProcess.running =
                    true
            }
        }
    }

    // ═════════════════════════════════════════
    // Normal closing choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: closeAnimation

        // 1. Fade header + controls in place

        ParallelAnimation {
            NumberAnimation {
                target:
                    expandedContent

                property:
                    "opacity"

                to:
                    0.0

                duration:
                    110

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    root

                property:
                    "headerOpacity"

                to:
                    0.0

                duration:
                    110

                easing.type:
                    Easing.OutCubic
            }
        }

        // 2. Base fill + bounce simultaneously

        ParallelAnimation {
            NumberAnimation {
                target:
                    root

                property:
                    "closeFillTop"

                from:
                    root.expandedHeaderHeight

                to:
                    root.expandedEdgeThickness

                duration:
                    260

                easing.type:
                    Easing.InOutCubic
            }

            SequentialAnimation {
                NumberAnimation {
                    target:
                        root

                    property:
                        "closeBounceScale"

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
                        "closeBounceScale"

                    from:
                        0.965

                    to:
                        1.075

                    duration:
                        190

                    easing.type:
                        Easing.OutBack

                    easing.overshoot:
                        1.45
                }
            }
        }

        ScriptAction {
            script:
                root.collapseBase = true
        }

        // 3. Bounce recovery + shrink together

        ParallelAnimation {
            NumberAnimation {
                target:
                    root

                property:
                    "closeBounceScale"

                from:
                    1.075

                to:
                    1.0

                duration:
                    280

                easing.type:
                    Easing.OutCubic
            }

            SequentialAnimation {
                ScriptAction {
                    script:
                        root.shrinking = true
                }

                PauseAnimation {
                    duration:
                        280
                }
            }
        }

        // 4. Final compact state

        ScriptAction {
            script: {
                root.suppressHover =
                    true

                root.expanded =
                    false

                root.closing =
                    false

                root.shrinking =
                    false

                root.collapseBase =
                    true

                root.closeFillTop =
                    root.expandedHeaderHeight

                root.closeBounceScale =
                    1.0

                root.headerOpacity =
                    0.0

                expandedContent.opacity =
                    0.0

                /*
                 * Reset nested menus only after
                 * normal close is fully complete.
                 */
                outputSelector.close()
                inputSelector.close()
            }
        }
    }
}
