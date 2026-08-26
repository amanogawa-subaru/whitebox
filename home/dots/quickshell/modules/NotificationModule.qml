import QtQuick
import Quickshell

import "../Config"
import "notifications"

FocusScope {
    id: root

    required property var backend

    // ═════════════════════════════════════════
    // State
    // ═════════════════════════════════════════

    property bool suppressHover:
        false

    property bool hovered:
        compactMouse.containsMouse
        && !root.suppressHover

    property bool expanded:
        false

    property bool closing:
        false

    property bool shrinking:
        false

    property bool collapseBase:
        false

    /*
     * Expanded contents have their own opacity.
     *
     * This deliberately separates them from the
     * module's width animation so text/cards do
     * not appear to slide horizontally.
     */
    property real contentOpacity:
        0.0

    /*
     * Independent attention animation for new
     * notifications.
     */
    property real notificationBounce:
        1.0

    // ═════════════════════════════════════════
    // Design
    // ═════════════════════════════════════════

    property color accentColor:
        Colors.sapphire

    property real expandedWidth:
        340 * Appearance.scale

    property real expandedHeaderHeight:
        54 * Appearance.scale

    property real expandedEdgeThickness:
        Appearance.borderWidth

    property real contentMargin:
        14 * Appearance.scale

    property real closeFillTop:
        root.expandedHeaderHeight

    property real closeBounceScale:
        1.0

    readonly property int notificationCount:
        root.backend
            ? root.backend.count
            : 0

    readonly property real emptyBodyHeight:
        170 * Appearance.scale

    readonly property real listBodyHeight:
        Math.min(
            430 * Appearance.scale,
            notificationColumn.implicitHeight
            + root.contentMargin * 2
        )

    readonly property real expandedBodyHeight:
        root.notificationCount > 0
            ? root.listBodyHeight
            : root.emptyBodyHeight

    readonly property real expandedHeight:
        root.expandedHeaderHeight
        + root.expandedEdgeThickness
        + root.expandedBodyHeight

    // ═════════════════════════════════════════
    // New notification
    // ═════════════════════════════════════════

    Connections {
        target:
            root.backend

        function onNotificationReceived(notification) {
            /*
             * Only bounce the compact module.
             *
             * If the notification center is
             * already open, there is no need to
             * draw attention to its button.
             */
            if (!root.expanded) {
                notificationBounceAnimation.restart()
            }
        }
    }

    // ═════════════════════════════════════════
    // Open
    // ═════════════════════════════════════════

    function open() {
        closeAnimation.stop()

        contentDelay.stop()
        contentFadeIn.stop()
        focusDelay.stop()

        /*
         * If we're opening while the attention
         * animation is still running, stop it and
         * restore normal scale.
         */
        notificationBounceAnimation.stop()

        root.notificationBounce =
            1.0

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

        /*
         * Contents remain completely invisible
         * while the Sapphire shell expands.
         */
        root.contentOpacity =
            0.0

        root.expanded =
            true

        contentDelay.restart()
        focusDelay.restart()
    }

    // ═════════════════════════════════════════
    // Close
    // ═════════════════════════════════════════

    function close() {
        if (
            !root.expanded
            || root.closing
        ) {
            return
        }

        contentDelay.stop()
        contentFadeIn.stop()
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

    function toggle() {
        if (root.expanded)
            root.close()
        else
            root.open()
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
        NumberAnimation {
            duration:
                280

            easing.type:
                Easing.OutCubic
        }
    }

    Behavior on height {
        NumberAnimation {
            duration:
                280

            easing.type:
                Easing.OutCubic
        }
    }

    // ═════════════════════════════════════════
    // Visual root
    // ═════════════════════════════════════════

    Item {
        id: visualRoot

        anchors.fill:
            parent

        scale: {
            /*
             * Normal close choreography has
             * highest priority.
             */
            if (root.closing)
                return root.closeBounceScale

            /*
             * New-notification attention bounce.
             */
            if (
                !root.expanded
                && notificationBounceAnimation.running
            ) {
                return root.notificationBounce
            }

            /*
             * Normal compact hover swell.
             */
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

        /*
         * The explicit notification animation
         * already controls scale itself, so the
         * normal Behavior must not interfere.
         */
        Behavior on scale {
            enabled:
                !root.closing
                && !notificationBounceAnimation.running

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

            border.width:
                Appearance.borderWidth

            border.color:
                root.accentColor

            Behavior on color {
                ColorAnimation {
                    duration:
                        150
                }
            }
        }

        // ═════════════════════════════════════
        // Compact state
        // ═════════════════════════════════════

        Item {
            z:
                8

            visible:
                !root.expanded

            anchors.fill:
                parent

            Text {
                anchors.centerIn:
                    parent

                text:
                    root.backend
                    && root.backend.doNotDisturb
                        ? "󰂛"
                        : (
                            root.notificationCount > 0
                                ? "󰂞"
                                : "󰂚"
                        )

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

            Rectangle {
                visible:
                    root.notificationCount > 0

                anchors {
                    right:
                        parent.right

                    top:
                        parent.top

                    rightMargin:
                        3 * Appearance.scale

                    topMargin:
                        3 * Appearance.scale
                }

                width:
                    14 * Appearance.scale

                height:
                    width

                radius:
                    width / 2

                color:
                    root.hovered
                        ? Colors.base
                        : root.accentColor

                Text {
                    anchors.centerIn:
                        parent

                    text:
                        root.notificationCount > 9
                            ? "9+"
                            : root.notificationCount.toString()

                    color:
                        root.hovered
                            ? root.accentColor
                            : Colors.base

                    font.pixelSize:
                        8 * Appearance.scale

                    font.bold:
                        true
                }
            }
        }

        // ═════════════════════════════════════
        // Expanded header
        // ═════════════════════════════════════

        Item {
            z:
                7

            visible:
                root.expanded

            width:
                parent.width

            height:
                root.expandedHeaderHeight

            /*
             * IMPORTANT:
             *
             * Header participates in the SAME
             * dedicated opacity as the body.
             *
             * It therefore cannot ride the
             * width animation horizontally.
             */
            opacity:
                root.contentOpacity

            Text {
                anchors {
                    left:
                        parent.left

                    leftMargin:
                        18 * Appearance.scale

                    verticalCenter:
                        parent.verticalCenter
                }

                text:
                    "Notifications"

                color:
                    Colors.base

                font.pixelSize:
                    Appearance.textSize + 2

                font.bold:
                    true
            }

            Row {
                anchors {
                    right:
                        parent.right

                    rightMargin:
                        12 * Appearance.scale

                    verticalCenter:
                        parent.verticalCenter
                }

                spacing:
                    6 * Appearance.scale

                // ─────────────────────────────
                // DND
                // ─────────────────────────────

                Rectangle {
                    width:
                        32 * Appearance.scale

                    height:
                        32 * Appearance.scale

                    radius:
                        Appearance.controlRadius

                    color:
                        root.backend
                        && root.backend.doNotDisturb
                            ? Colors.base
                            : (
                                dndMouse.containsMouse
                                    ? Qt.rgba(
                                        Colors.base.r,
                                        Colors.base.g,
                                        Colors.base.b,
                                        0.18
                                    )
                                    : "transparent"
                            )

                    Text {
                        anchors.centerIn:
                            parent

                        text:
                            "󰂛"

                        font.family:
                            "Symbols Nerd Font"

                        font.pixelSize:
                            Appearance.iconSize - 2

                        color:
                            root.backend
                            && root.backend.doNotDisturb
                                ? root.accentColor
                                : Colors.base
                    }

                    MouseArea {
                        id: dndMouse

                        anchors.fill:
                            parent

                        hoverEnabled:
                            true

                        onClicked: {
                            if (root.backend)
                                root.backend.toggleDnd()
                        }
                    }
                }

                // ─────────────────────────────
                // Clear all
                // ─────────────────────────────

                Rectangle {
                    width:
                        32 * Appearance.scale

                    height:
                        32 * Appearance.scale

                    radius:
                        Appearance.controlRadius

                    color:
                        clearMouse.containsMouse
                            ? Qt.rgba(
                                Colors.base.r,
                                Colors.base.g,
                                Colors.base.b,
                                0.18
                            )
                            : "transparent"

                    opacity:
                        root.notificationCount > 0
                            ? 1.0
                            : 0.35

                    Text {
                        anchors.centerIn:
                            parent

                        text:
                            "󰆴"

                        font.family:
                            "Symbols Nerd Font"

                        font.pixelSize:
                            Appearance.iconSize - 2

                        color:
                            Colors.base
                    }

                    MouseArea {
                        id: clearMouse

                        anchors.fill:
                            parent

                        enabled:
                            root.notificationCount > 0

                        hoverEnabled:
                            true

                        onClicked: {
                            if (root.backend)
                                root.backend.clearAll()
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════
        // Expanded body
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

            Item {
                id: expandedContent

                anchors.fill:
                    parent

                /*
                 * No Behavior here.
                 *
                 * contentFadeIn and closeAnimation
                 * explicitly control the value.
                 */
                opacity:
                    root.contentOpacity

                // ─────────────────────────────
                // Empty state
                // ─────────────────────────────

                Column {
                    visible:
                        root.notificationCount === 0

                    anchors.centerIn:
                        parent

                    spacing:
                        10 * Appearance.scale

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text:
                            "󰂚"

                        font.family:
                            "Symbols Nerd Font"

                        font.pixelSize:
                            40 * Appearance.scale

                        color:
                            root.accentColor
                    }

                    Text {
                        anchors.horizontalCenter:
                            parent.horizontalCenter

                        text:
                            "Nothing to see here"

                        color:
                            Colors.subtext0

                        font.pixelSize:
                            Appearance.textSize
                    }
                }

                // ─────────────────────────────
                // Notification history
                // ─────────────────────────────

                Flickable {
                    visible:
                        root.notificationCount > 0

                    anchors {
                        fill:
                            parent

                        margins:
                            root.contentMargin
                    }

                    contentWidth:
                        width

                    contentHeight:
                        notificationColumn.implicitHeight

                    clip:
                        true

                    boundsBehavior:
                        Flickable.StopAtBounds

                    Column {
                        id: notificationColumn

                        width:
                            parent.width

                        spacing:
                            10 * Appearance.scale

                        Repeater {
                            model:
                                root.backend
                                    ? root.backend
                                        .server
                                        .trackedNotifications
                                    : null

                            NotificationCard {
								required property var modelData

								width:
									notificationColumn.width

								notification:
									modelData

								accentColor:
									root.accentColor

								/*
								 * Clicking the card invokes the sender's
								 * default action when one exists.
								 *
								 * We don't try to launch/focus applications
								 * ourselves. The application supplied this
								 * action specifically to tell the notification
								 * daemon what clicking its notification means.
								 */
								onActivated: {
									const actions =
										modelData.actions

									for (
										let i = 0;
										i < actions.length;
										++i
									) {
										const action =
											actions[i]

										if (
											action.identifier
											=== "default"
										) {
											action.invoke()

											/*
											 * Usually the application will
											 * focus/open whatever this
											 * notification represents.
											 *
											 * Close our notification center
											 * as well so we immediately return
											 * to the application.
											 */
											root.close()

											return
										}
									}
								}

								onDismissRequested:
									root.backend.dismiss(
										modelData
									)
							}
                        }
                    }
                }
            }
        }

        // ═════════════════════════════════════
        // Closing base wipe
        // ═════════════════════════════════════

        Rectangle {
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

    /*
     * Wait until the 280 ms width expansion is
     * almost complete before beginning the fade.
     */
    Timer {
        id: contentDelay

        interval:
            220

        repeat:
            false

        onTriggered:
            contentFadeIn.restart()
    }

    NumberAnimation {
        id: contentFadeIn

        target:
            root

        property:
            "contentOpacity"

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
        id: focusDelay

        interval:
            50

        repeat:
            false

        onTriggered:
            root.forceActiveFocus()
    }

    // ═════════════════════════════════════════
    // New notification attention bounce
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: notificationBounceAnimation

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            from:
                1.0

            to:
                1.18

            duration:
                90

            easing.type:
                Easing.OutCubic
        }

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            to:
                0.94

            duration:
                90

            easing.type:
                Easing.InOutCubic
        }

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            to:
                1.08

            duration:
                110

            easing.type:
                Easing.OutCubic
        }

        NumberAnimation {
            target:
                root

            property:
                "notificationBounce"

            to:
                1.0

            duration:
                140

            easing.type:
                Easing.OutCubic
        }
    }

    // ═════════════════════════════════════════
    // Normal closing choreography
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: closeAnimation

        /*
         * FIRST:
         * Fade absolutely everything in the
         * expanded UI out IN PLACE.
         */
        NumberAnimation {
            target:
                root

            property:
                "contentOpacity"

            to:
                0.0

            duration:
                110

            easing.type:
                Easing.OutCubic
        }

        /*
         * THEN:
         * Run the normal shell collapse.
         */
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

                root.contentOpacity =
                    0.0
            }
        }
    }
}
