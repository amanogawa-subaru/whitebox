import QtQuick
import Quickshell
import Quickshell.Services.SystemTray

import "../Config"

Item {
    id: root

    property bool embedded:
        false

    property bool hovered:
        trayMouse.containsMouse

    /*
     * True briefly when we intentionally launch
     * a systray context menu.
     */
    property bool menuGraceActive:
        false

    signal menuRequested()

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
            duration:
                280

            easing.type:
                Easing.OutCubic
        }
    }


    // ═════════════════════════════════════════
    // Standalone background
    // ═════════════════════════════════════════

    Rectangle {
        anchors.fill:
            parent

        visible:
            !root.embedded

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
    // Menu grace
    // ═════════════════════════════════════════

    function beginMenuGrace() {
        root.menuGraceActive =
            true

        root.menuRequested()

        menuGraceTimer.restart()
    }

    Timer {
        id: menuGraceTimer

        /*
         * Native tray menus can steal focus slightly
         * after display() returns. Keep the grace
         * window alive long enough for that delayed
         * FocusGrab clear to be ignored by shell.qml.
         */
        interval:
            2000

        repeat:
            false

        onTriggered:
            root.menuGraceActive = false
    }


    // ═════════════════════════════════════════
    // Tray items
    // ═════════════════════════════════════════

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


                Image {
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
                            duration:
                                200

                            easing.type:
                                Easing.OutBack

                            easing.overshoot:
                                1.4
                        }
                    }
                }


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
                             * IMPORTANT:
                             *
                             * Opening this native menu can
                             * temporarily clear our panel's
                             * HyprlandFocusGrab.
                             *
                             * Tell UtilityModule/shell first.
                             */
                            root.beginMenuGrace()

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
                        // Menu-only item
                        // ─────────────────────

                        if (
                            trayItem.modelData.onlyMenu
                            && trayItem.modelData.hasMenu
                        ) {
                            root.beginMenuGrace()

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


                    onWheel: wheel => {
                        if (!trayItem.modelData)
                            return

                        trayItem.modelData.scroll(
                            wheel.angleDelta.y,
                            false
                        )
                    }
                }
            }
        }
    }


    // ═════════════════════════════════════════
    // Whole tray hover
    // ═════════════════════════════════════════

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
