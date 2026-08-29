import QtQuick
import Quickshell

import "../Config"
import "notifications"

FocusScope {
    id: root

    required property var backend

    property color accentColor:
        Colors.sapphire

    signal closeRequested()

    Connections {
        target:
            root.backend

        function onNotificationActivated() {
            root.closeRequested()
        }
    }

    readonly property int notificationCount:
        root.backend
            ? root.backend.count
            : 0

    property real contentMargin:
        14 * Appearance.scale

    readonly property real emptyBodyHeight:
        170 * Appearance.scale

    readonly property real listBodyHeight:
        Math.min(
            430 * Appearance.scale,
            notificationColumn.implicitHeight
            + root.contentMargin * 2
        )

    readonly property real bodyHeight:
        root.notificationCount > 0
            ? root.listBodyHeight
            : root.emptyBodyHeight

    readonly property real headerHeight:
        46 * Appearance.scale

    implicitHeight:
        root.headerHeight
        + root.bodyHeight

    height:
        implicitHeight

    // ═════════════════════════════════════════
    // Header
    // ═════════════════════════════════════════

    Item {
        id: notificationHeader

        width:
            parent.width

        height:
            root.headerHeight

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

            // DND

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
                        ? root.accentColor
                        : (
                            dndMouse.containsMouse
                                ? Colors.surface0
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
                            ? Colors.base
                            : root.accentColor
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

            // Clear all

            Rectangle {
                width:
                    32 * Appearance.scale

                height:
                    32 * Appearance.scale

                radius:
                    Appearance.controlRadius

                color:
                    clearMouse.containsMouse
                        ? Colors.surface0
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
                        root.accentColor
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

    // ═════════════════════════════════════════
    // Body
    // ═════════════════════════════════════════

    Item {
        anchors {
            left:
                parent.left

            right:
                parent.right

            top:
                notificationHeader.bottom
        }

        height:
            root.bodyHeight

        // Empty state

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

        // Notification history

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

                        property var activationBackend:
                            root.backend

                        onActivated: {
                            if (activationBackend)
                                activationBackend.activate(
                                    modelData
                                )
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
