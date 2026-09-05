import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import "../../Config"


Rectangle {
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


    required property var notification

    property color accentColor:
        Colors.sapphire

    /*
     * Whether the notification body is currently
     * showing its complete contents.
     */
    property bool expanded:
        false

    /*
     * Critical notifications override the normal
     * sapphire notification accent.
     */
    property bool critical:
        root.notification
        && root.notification.urgency
            === NotificationUrgency.Critical

    property color effectiveAccent:
        root.critical
            ? Colors.red
            : root.accentColor

    signal activated()
    signal dismissRequested()

    width:
        parent ? parent.width : implicitWidth

    implicitHeight:
        contentColumn.implicitHeight
        + 24 * Appearance.scale

    height:
        implicitHeight

    radius:
        Appearance.controlRadius

    color:
        cardMouse.containsMouse
            ? Colors.surface1
            : Colors.surface0

    Behavior on color {
        ColorAnimation {
            duration:
                130
        }
    }

    // ═════════════════════════════════════════
    // Card interaction
    // ═════════════════════════════════════════

    MouseArea {
        id: cardMouse

        anchors.fill:
            parent

        z:
            0

        hoverEnabled:
            true

        cursorShape:
            Qt.PointingHandCursor

        onClicked:
            root.activated()
    }

    // ═════════════════════════════════════════
    // Content
    // ═════════════════════════════════════════

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
                12 * Appearance.scale

            rightMargin:
                10 * Appearance.scale

            topMargin:
                12 * Appearance.scale
        }

        spacing:
            10 * Appearance.scale

        // ─────────────────────────────────────
        // App icon
        // ─────────────────────────────────────

        Rectangle {
            width:
                34 * Appearance.scale

            height:
                width

            radius:
                Appearance.controlRadius

            color:
                Colors.surface1

            IconImage {
                anchors.centerIn:
                    parent

                implicitSize:
                    22 * Appearance.scale

                source: {
                    if (
                        root.notification.appIcon
                        && root.notification.appIcon.length > 0
                    ) {
                        return root.resolveAppIcon(
                            root.notification.appIcon
                        )
                    }

                    return ""
                }
            }

            Text {
                visible:
                    !root.notification.appIcon
                    || root.notification.appIcon.length === 0

                anchors.centerIn:
                    parent

                text:
                    root.critical
                        ? ""
                        : "󰋽"

                font.family:
                    "Symbols Nerd Font"

                font.pixelSize:
                    Appearance.iconSize

                color:
                    root.effectiveAccent
            }
        }

        // ─────────────────────────────────────
        // Notification content
        // ─────────────────────────────────────

        Column {
            id: contentColumn

            width:
                parent.width
                - 34 * Appearance.scale
                - dismissButton.width
                - parent.spacing * 2

            spacing:
                5 * Appearance.scale

            Text {
                width:
                    parent.width

                text:
                    root.notification.appName
                    && root.notification.appName.length > 0
                        ? root.notification.appName
                        : "Notification"

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
                    root.notification.summary
                    && root.notification.summary.length > 0

                text:
                    root.notification.summary

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

            // ─────────────────────────────────
            // Notification body
            // ─────────────────────────────────

            Text {
                id: bodyText

                width:
                    parent.width

                visible:
                    root.notification.body
                    && root.notification.body.length > 0

                text:
                    root.notification.body

                textFormat:
                    Text.PlainText

                color:
                    Colors.subtext0

                font.pixelSize:
                    Appearance.textSize - 1

                wrapMode:
                    Text.Wrap

                maximumLineCount:
                    root.expanded
                        ? 2147483647
                        : 3

                elide:
                    root.expanded
                        ? Text.ElideNone
                        : Text.ElideRight
            }

            /*
             * Invisible measurement copy.
             *
             * bodyText itself is capped at three lines while
             * collapsed, so its implicitHeight cannot tell us
             * whether additional text exists.
             *
             * This copy renders the same text with no line
             * limit and lets us compare the full height with
             * the collapsed body's height.
             */
            Text {
                id: bodyMeasurement

                width:
                    bodyText.width

                visible:
                    false

                text:
                    root.notification.body
                        ? root.notification.body
                        : ""

                textFormat:
                    Text.PlainText

                font.pixelSize:
                    Appearance.textSize - 1

                wrapMode:
                    Text.Wrap
            }

            // ─────────────────────────────────
            // Expand / collapse
            // ─────────────────────────────────

            Item {
                id: expandButton

                width:
                    parent.width

                height:
                    22 * Appearance.scale

                /*
                 * Show the control only when the complete
                 * body requires more space than the
                 * three-line collapsed body.
                 */
                visible:
                    bodyText.visible
                    && (
                        root.expanded
                        || bodyMeasurement.implicitHeight
                            > bodyText.implicitHeight + 0.5
                    )

                z:
                    2

                Row {
                    anchors.right:
                        parent.right

                    anchors.verticalCenter:
                        parent.verticalCenter

                    spacing:
                        5 * Appearance.scale

                    Text {
                        text:
                            root.expanded
                                ? "Less"
                                : "More"

                        color:
                            expandMouse.containsMouse
                                ? root.effectiveAccent
                                : Colors.subtext0

                        font.pixelSize:
                            Appearance.textSize - 2

                        font.bold:
                            true

                        Behavior on color {
                            ColorAnimation {
                                duration:
                                    130
                            }
                        }
                    }

                    Text {
                        text:
                            root.expanded
                                ? "󰅃"
                                : "󰅀"

                        font.family:
                            "Symbols Nerd Font"

                        font.pixelSize:
                            Appearance.iconSize - 4

                        color:
                            expandMouse.containsMouse
                                ? root.effectiveAccent
                                : Colors.subtext0

                        Behavior on color {
                            ColorAnimation {
                                duration:
                                    130
                            }
                        }
                    }
                }

                MouseArea {
                    id: expandMouse

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    cursorShape:
                        Qt.PointingHandCursor

                    onClicked: {
                        root.expanded =
                            !root.expanded
                    }
                }
            }
        }

        // ─────────────────────────────────────
        // Dismiss button
        // ─────────────────────────────────────

        Item {
            id: dismissButton

            width:
                28 * Appearance.scale

            height:
                28 * Appearance.scale

            z:
                2

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
                    root.dismissRequested()
                }
            }
        }
    }
}
