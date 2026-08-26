import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../Config"

Item {
    id: root

    property bool hovered:
        trayMouse.containsMouse

    // ─────────────────────────────────────────
    // Geometry
    // ─────────────────────────────────────────

    property real horizontalPadding:
        12 * Appearance.scale

    property real itemSize:
        24 * Appearance.scale

    property real itemSpacing:
        8 * Appearance.scale

    property int itemCount:
        SystemTray.items.values.length

    width:
        root.itemCount > 0
            ? trayRow.implicitWidth
                + root.horizontalPadding * 2
            : 0

    height:
        Appearance.moduleHeight

    visible:
        root.itemCount > 0

    Behavior on width {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    // ─────────────────────────────────────────
    // Background
    // ─────────────────────────────────────────

    Rectangle {
        id: background

        anchors.fill:
            parent

        radius:
            Appearance.moduleRadius

        color:
            Colors.base

        border.width:
            Appearance.borderWidth

        border.color:
            Colors.mauve

        scale:
            root.hovered
                ? 1.06
                : 1.0

        transformOrigin:
            Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
                easing.overshoot: 1.9
            }
        }
    }

    // ─────────────────────────────────────────
    // Tray items
    // ─────────────────────────────────────────

    Row {
        id: trayRow

        anchors.centerIn:
            parent

        spacing:
            root.itemSpacing

        Repeater {
            model:
                SystemTray.items

            delegate: Item {
                id: trayItem

                required property var modelData

                width:
                    root.itemSize

                height:
                    root.itemSize

                property bool hovered:
                    itemMouse.containsMouse

                // ─────────────────────────────
                // Icon
                // ─────────────────────────────

                Image {
                    id: icon

                    anchors.centerIn:
                        parent

                    width:
                        20 * Appearance.scale

                    height:
                        20 * Appearance.scale

                    source:
                        trayItem.modelData.icon

                    fillMode:
                        Image.PreserveAspectFit

                    smooth:
                        true

                    mipmap:
                        true

                    scale:
                        trayItem.hovered
                            ? 1.15
                            : 1.0

                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.4
                        }
                    }
                }

                // ─────────────────────────────
                // Interaction
                // ─────────────────────────────

                MouseArea {
                    id: itemMouse

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    acceptedButtons:
                        Qt.LeftButton
                        | Qt.RightButton
                        | Qt.MiddleButton

                    onClicked: mouse => {
                        if (!trayItem.modelData)
                            return

                        // ─────────────────────
                        // Right click
                        // ─────────────────────

                        if (
                            mouse.button === Qt.RightButton
                            && trayItem.modelData.hasMenu
                        ) {
                            /*
                             * The mouse coordinates are
                             * local to this tiny tray item.
                             *
                             * Convert them to coordinates
                             * relative to the PanelWindow.
                             */
                            const pos =
                                root.QsWindow.mapFromItem(
                                    trayItem,
                                    mouse.x,
                                    mouse.y
                                )

                            trayItem.modelData.display(
                                root.QsWindow.window,
                                pos.x,
                                pos.y
                            )

                            return
                        }

                        // ─────────────────────
                        // Middle click
                        // ─────────────────────

                        if (
                            mouse.button === Qt.MiddleButton
                        ) {
                            trayItem.modelData
                                .secondaryActivate()

                            return
                        }

                        // ─────────────────────
                        // Menu-only tray items
                        // ─────────────────────

                        if (
                            trayItem.modelData.onlyMenu
                            && trayItem.modelData.hasMenu
                        ) {
                            const pos =
                                root.QsWindow.mapFromItem(
                                    trayItem,
                                    mouse.x,
                                    mouse.y
                                )

                            trayItem.modelData.display(
                                root.QsWindow.window,
                                pos.x,
                                pos.y
                            )

                            return
                        }

                        // ─────────────────────
                        // Normal left click
                        // ─────────────────────

                        trayItem.modelData.activate()
                    }

                    // ─────────────────────────
                    // Scroll
                    // ─────────────────────────

                    onWheel: wheel => {
                        if (!trayItem.modelData)
                            return

                        /*
                         * Vertical tray-item scroll.
                         *
                         * Some applications ignore this,
                         * which is perfectly normal.
                         */
                        trayItem.modelData.scroll(
                            wheel.angleDelta.y,
                            false
                        )
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // Whole-module hover detection
    // ─────────────────────────────────────────

    MouseArea {
        id: trayMouse

        anchors.fill:
            parent

        hoverEnabled:
            true

        acceptedButtons:
            Qt.NoButton

        z:
            -1
    }
}
