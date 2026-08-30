import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import "../../Config"

Item {
    id: root

    function resolveAppIcon(icon) {
        if (!icon || icon.length === 0)
            return ""

        if (
            icon.startsWith("file://")
            || icon.startsWith("/")
        ) {
            return icon
        }

        return Quickshell.iconPath(icon)
    }

    required property var backend
    required property var notification
    required property int notificationId

    property color accentColor:
        Colors.sapphire

    signal removalRequested(int notificationId)

    width:
        340 * Appearance.scale

    implicitHeight:
        popupCard.implicitHeight

    height:
        implicitHeight

    property bool closing:
        false

    // ═════════════════════════════════════════
    // Cached visual data
    // ═════════════════════════════════════════

    property string cachedAppName:
        "Notification"

    property string cachedSummary:
        ""

    property string cachedBody:
        ""

    property string cachedAppIcon:
        ""

    /*
     * Urgency is cached for exactly the same
     * reason as the text/icon data.
     *
     * dismiss() may destroy the Notification
     * object while the popup is still bouncing.
     */
    property bool cachedCritical:
        false

    /*
     * Normal notification:
     *     sapphire
     *
     * Critical notification:
     *     red
     */
    property color effectiveAccent:
        root.cachedCritical
            ? Colors.red
            : root.accentColor

    // ═════════════════════════════════════════
    // Default action
    // ═════════════════════════════════════════

    function invokeDefaultAction() {
        if (
            !root.backend
            || !root.notification
            || root.closing
        ) {
            return false
        }

        /*
         * NotificationBackend owns all activation logic:
         * default action + Hyprland app focusing.
         */
        root.backend.activate(
            root.notification
        )

        root.beginClose()

        return true
    }

    // ═════════════════════════════════════════
    // Close
    // ═════════════════════════════════════════

    function beginClose() {
        if (root.closing)
            return

        root.closing =
            true

        expiryTimer.stop()
        enterAnimation.stop()

        exitAnimation.restart()
    }

    // ═════════════════════════════════════════
    // Visual card
    // ═════════════════════════════════════════

    Rectangle {
        id: popupCard

        width:
            root.width

        implicitHeight:
            contentColumn.implicitHeight
            + 26 * Appearance.scale

        height:
            implicitHeight

        anchors.centerIn:
            parent

        radius:
            Appearance.moduleRadius

        color:
            Colors.base

        border.width:
            Appearance.borderWidth

        border.color:
            root.effectiveAccent

        opacity:
            0.0

        transform: Scale {
            id: popupScale

            origin.x:
                popupCard.width / 2

            origin.y:
                popupCard.height / 2

            xScale:
                0.82

            yScale:
                0.82
        }

        // ═════════════════════════════════════
        // Main interaction
        // ═════════════════════════════════════

        MouseArea {
            id: popupMouse

            anchors.fill:
                parent

            z:
                0

            hoverEnabled:
                true

            cursorShape:
                Qt.PointingHandCursor

            onEntered: {
                if (!root.closing)
                    expiryTimer.stop()
            }

            onExited: {
                if (!root.closing)
                    expiryTimer.restart()
            }

            onClicked:
                root.invokeDefaultAction()
        }

        // ═════════════════════════════════════
        // Content
        // ═════════════════════════════════════

        Row {
            z:
                1

            anchors {
                left:
                    parent.left

                right:
                    parent.right

                top:
                    parent.top

                leftMargin:
                    14 * Appearance.scale

                rightMargin:
                    10 * Appearance.scale

                topMargin:
                    13 * Appearance.scale
            }

            spacing:
                11 * Appearance.scale

            // ─────────────────────────────────
            // App icon
            // ─────────────────────────────────

            Rectangle {
                width:
                    38 * Appearance.scale

                height:
                    width

                radius:
                    Appearance.controlRadius

                color:
                    Colors.surface0

                IconImage {
                    anchors.centerIn:
                        parent

                    implicitSize:
                        24 * Appearance.scale

                    source:
                        root.resolveAppIcon(
                            root.cachedAppIcon
                        )
                }

                Text {
                    visible:
                        root.cachedAppIcon.length === 0

                    anchors.centerIn:
                        parent

                    text:
						root.cachedCritical
							? ""
							: "󰋽"

                    font.family:
                        "Symbols Nerd Font"

                    font.pixelSize:
                        Appearance.iconSize + 1

                    color:
                        root.effectiveAccent
                }
            }

            // ─────────────────────────────────
            // Text
            // ─────────────────────────────────

            Column {
                id: contentColumn

                width:
                    parent.width
                    - 38 * Appearance.scale
                    - dismissButton.width
                    - parent.spacing * 2

                spacing:
                    5 * Appearance.scale

                Text {
                    width:
                        parent.width

                    text:
                        root.cachedAppName

                    color:
                        root.effectiveAccent

                    font.pixelSize:
                        Appearance.textSize - 2

                    font.bold:
                        true

                    elide:
                        Text.ElideRight

                    maximumLineCount:
                        1
                }

                Text {
                    width:
                        parent.width

                    visible:
                        root.cachedSummary.length > 0

                    text:
                        root.cachedSummary

                    color:
                        Colors.text

                    font.pixelSize:
                        Appearance.textSize

                    font.bold:
                        true

                    wrapMode:
                        Text.Wrap

                    maximumLineCount:
                        2

                    elide:
                        Text.ElideRight
                }

                Text {
                    width:
                        parent.width

                    visible:
                        root.cachedBody.length > 0

                    text:
                        root.cachedBody

                    textFormat:
                        Text.PlainText

                    color:
                        Colors.subtext0

                    font.pixelSize:
                        Appearance.textSize - 1

                    wrapMode:
                        Text.Wrap

                    maximumLineCount:
                        3

                    elide:
                        Text.ElideRight
                }
            }

            // ─────────────────────────────────
            // Dismiss
            // ─────────────────────────────────

            Item {
                id: dismissButton

                z:
                    2

                width:
                    28 * Appearance.scale

                height:
                    28 * Appearance.scale

                Text {
                    anchors.centerIn:
                        parent

                    text:
                        "󰅖"

                    font.family:
                        "Symbols Nerd Font"

                    font.pixelSize:
                        Appearance.iconSize - 2

                    color:
                        dismissMouse.containsMouse
                            ? root.effectiveAccent
                            : Colors.subtext0

                    scale:
                        dismissMouse.containsMouse
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
                    id: dismissMouse

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {
                        if (root.closing)
                            return

                        root.beginClose()

                        if (root.notification)
                            root.notification.dismiss()
                    }
                }
            }
        }
    }

    // ═════════════════════════════════════════
    // Lifetime
    // ═════════════════════════════════════════

    Timer {
        id: expiryTimer

        interval:
            5000

        repeat:
            false

        onTriggered:
            root.beginClose()
    }

    // ═════════════════════════════════════════
    // Enter — individual bounce
    //
    // 0.82 → 1.08 → 0.97 → 1.00
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: enterAnimation

        ParallelAnimation {
            NumberAnimation {
                target:
                    popupCard

                property:
                    "opacity"

                from:
                    0.0

                to:
                    1.0

                duration:
                    130

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    popupScale

                property:
                    "xScale"

                from:
                    0.82

                to:
                    1.08

                duration:
                    180

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    popupScale

                property:
                    "yScale"

                from:
                    0.82

                to:
                    1.08

                duration:
                    180

                easing.type:
                    Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target:
                    popupScale

                property:
                    "xScale"

                to:
                    0.97

                duration:
                    90

                easing.type:
                    Easing.InOutCubic
            }

            NumberAnimation {
                target:
                    popupScale

                property:
                    "yScale"

                to:
                    0.97

                duration:
                    90

                easing.type:
                    Easing.InOutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target:
                    popupScale

                property:
                    "xScale"

                to:
                    1.0

                duration:
                    110

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    popupScale

                property:
                    "yScale"

                to:
                    1.0

                duration:
                    110

                easing.type:
                    Easing.OutCubic
            }
        }
    }

    // ═════════════════════════════════════════
    // Exit — bounce to nothing
    // ═════════════════════════════════════════

    SequentialAnimation {
        id: exitAnimation

        ParallelAnimation {
            NumberAnimation {
                target:
                    popupScale

                property:
                    "xScale"

                to:
                    1.07

                duration:
                    90

                easing.type:
                    Easing.OutCubic
            }

            NumberAnimation {
                target:
                    popupScale

                property:
                    "yScale"

                to:
                    1.07

                duration:
                    90

                easing.type:
                    Easing.OutCubic
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target:
                    popupScale

                property:
                    "xScale"

                to:
                    0.0

                duration:
                    230

                easing.type:
                    Easing.InBack

                easing.overshoot:
                    1.1
            }

            NumberAnimation {
                target:
                    popupScale

                property:
                    "yScale"

                to:
                    0.0

                duration:
                    230

                easing.type:
                    Easing.InBack

                easing.overshoot:
                    1.1
            }

            SequentialAnimation {
                PauseAnimation {
                    duration:
                        60
                }

                NumberAnimation {
                    target:
                        popupCard

                    property:
                        "opacity"

                    to:
                        0.0

                    duration:
                        170

                    easing.type:
                        Easing.InCubic
                }
            }
        }

        ScriptAction {
            script:
                root.removalRequested(
                    root.notificationId
                )
        }
    }

    // ═════════════════════════════════════════
    // Startup / snapshot
    // ═════════════════════════════════════════

    Component.onCompleted: {
        if (root.notification) {
            root.cachedAppName =
                root.notification.appName
                && root.notification.appName.length > 0
                    ? root.notification.appName
                    : "Notification"

            root.cachedSummary =
                root.notification.summary
                    ? root.notification.summary
                    : ""

            root.cachedBody =
                root.notification.body
                    ? root.notification.body
                    : ""

            root.cachedAppIcon =
                root.notification.appIcon
                    ? root.notification.appIcon
                    : ""
            

            /*
             * Snapshot urgency while the live
             * Notification object still exists.
             */
            root.cachedCritical =
                root.notification.urgency
                === NotificationUrgency.Critical
        }

        popupCard.opacity =
            0.0

        popupScale.xScale =
            0.82

        popupScale.yScale =
            0.82

        root.closing =
            false

        enterAnimation.restart()
        expiryTimer.restart()
    }
}
