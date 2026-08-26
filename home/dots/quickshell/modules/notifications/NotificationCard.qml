import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import "../../Config"

Rectangle {
    id: root

    required property var notification

    property color accentColor:
        Colors.sapphire

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
                        return Quickshell.iconPath(
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

            Text {
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
                    3

                elide:
                    Text.ElideRight
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
