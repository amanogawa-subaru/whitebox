//@ pragma UseQApplication
//@ pragma IconTheme Papirus-Dark

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

import "Config"
import "modules"
import "modules/notifications"
import "modules/wallpaper"

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight:
        1000

    exclusiveZone:
        Appearance.moduleHeight
        + Appearance.screenMargin
        + Appearance.panelBottomMargin

    focusable:
        true

    // ═════════════════════════════════════════
    // Shared notification backend
    // ═════════════════════════════════════════

    NotificationBackend {
        id: notificationBackend
    }

    // ═════════════════════════════════════════
    // Wallpaper backend + summoned picker
    // ═════════════════════════════════════════

    WallpaperBackend {
        id: wallpaperBackend
    }

    WallpaperPicker {
        id: wallpaperPicker

        backend:
            wallpaperBackend

        screen:
            root.screen
    }

    // ═════════════════════════════════════════
    // Keyboard focus
    // ═════════════════════════════════════════

    WlrLayershell.keyboardFocus:
        searchModule.expanded
        || workspaceModule.expanded
        || timeModule.expanded
        || musicModule.expanded
        || utilityModule.expanded
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

    color:
        "transparent"

    // ═════════════════════════════════════════
    // Input mask
    // ═════════════════════════════════════════

    mask: Region {
        Region {
            x:
                leftModules.x

            y:
                leftModules.y

            width:
                leftModules.width

            height:
                leftModules.height
        }

        Region {
            x:
                timeModule.x

            y:
                timeModule.y

            width:
                timeModule.width

            height:
                timeModule.height
        }

        Region {
            x:
                rightModules.x

            y:
                rightModules.y

            width:
                rightModules.width

            height:
                rightModules.height
        }
    }

    // ═════════════════════════════════════════
    // LEFT MODULES
    // ═════════════════════════════════════════

    Row {
        id: leftModules

        anchors {
            left:
                parent.left

            top:
                parent.top

            leftMargin:
                Appearance.screenMargin

            topMargin:
                Appearance.screenMargin
        }

        spacing:
            Appearance.moduleSpacing

        SearchModule {
            id: searchModule

            onExpandedChanged: {
                if (expanded) {
                    workspaceModule.close()
                    timeModule.close()
                    musicModule.close()
                    utilityModule.close()
                }
            }
        }

        WorkspaceModule {
            id: workspaceModule

            onExpandedChanged: {
                if (expanded) {
                    searchModule.close()
                    timeModule.close()
                    musicModule.close()
                    utilityModule.close()
                }
            }
        }
    }

    // ═════════════════════════════════════════
    // CENTER MODULE
    // ═════════════════════════════════════════

    TimeModule {
        id: timeModule

        anchors {
            horizontalCenter:
                parent.horizontalCenter

            top:
                parent.top

            topMargin:
                Appearance.screenMargin
        }

        onExpandedChanged: {
            if (expanded) {
                searchModule.close()
                workspaceModule.close()
                musicModule.close()
                utilityModule.close()
            }
        }
    }

    // ═════════════════════════════════════════
    // RIGHT MODULES
    // ═════════════════════════════════════════

    Row {
        id: rightModules

        anchors {
            right:
                parent.right

            top:
                parent.top

            rightMargin:
                Appearance.screenMargin

            topMargin:
                Appearance.screenMargin
        }

        spacing:
            Appearance.moduleSpacing

        MusicModule {
            id: musicModule

            onExpandedChanged: {
                if (expanded) {
                    searchModule.close()
                    workspaceModule.close()
                    timeModule.close()
                    utilityModule.close()
                }
            }
        }

        UtilityModule {
            id: utilityModule

            backend:
                notificationBackend
        }
    }

    // Coordinate UtilityModule expansion with other modules.

    Connections {
        target:
            utilityModule

        function onExpandedChanged() {
            if (utilityModule.expanded) {
                searchModule.close()
                workspaceModule.close()
                timeModule.close()
                musicModule.close()
            }
        }
    }

    // ═════════════════════════════════════════
    // Notification popup layer
    // ═════════════════════════════════════════

    NotificationPopupLayer {
        backend:
            notificationBackend

        anchorItem:
            utilityModule.notificationAnchor
    }

    // ═════════════════════════════════════════
    // Focus grabs
    // ═════════════════════════════════════════

    HyprlandFocusGrab {
        id: searchFocusGrab

        windows:
            [root]

        active:
            searchModule.expanded

        onCleared:
            searchModule.close()
    }

    HyprlandFocusGrab {
        id: workspaceFocusGrab

        windows:
            [root]

        active:
            workspaceModule.expanded

        onCleared:
            workspaceModule.close()
    }

    HyprlandFocusGrab {
        id: timeFocusGrab

        windows:
            [root]

        active:
            timeModule.expanded

        onCleared:
            timeModule.close()
    }

    HyprlandFocusGrab {
        id: musicFocusGrab

        windows:
            [root]

        active:
            musicModule.expanded

        onCleared:
            musicModule.close()
    }

    HyprlandFocusGrab {
        id: utilityFocusGrab

        windows:
            [root]

        active:
            utilityModule.expanded

        onCleared: {
            /*
             * Native systray context menus temporarily steal focus.
             * SystrayModule raises systrayMenuGrace before display(),
             * so this clear must not be interpreted as an outside click.
             */
            if (utilityModule.systrayMenuGrace) {
                Qt.callLater(function() {
                    if (utilityModule.expanded)
                        utilityModule.forceActiveFocus()
                })

                return
            }

            utilityModule.close()
        }
    }

    // ═════════════════════════════════════════
    // IPC
    // ═════════════════════════════════════════

    IpcHandler {
        target:
            "search"

        function toggle(): void {
            searchModule.toggle()
        }
    }

    IpcHandler {
        target:
            "clipboard"

        function toggle(): void {
            if (
                utilityModule.expanded
                && utilityModule.activeTab
                    === "clipboard"
            ) {
                utilityModule.close()
            } else {
                utilityModule.openClipboard()
            }
        }
    }

    /*
     * Wallpaper is intentionally not a bar module.
     * The picker is summoned externally, e.g.
     * from a Hyprland keybind.
     */
    IpcHandler {
        target:
            "wallpaper"

        function toggle(): void {
            wallpaperPicker.toggle()
        }

        function open(): void {
            wallpaperPicker.open()
        }

        function close(): void {
            wallpaperPicker.close()
        }

        function set(path: string): void {
            wallpaperBackend.setWallpaper(path)
        }

        function restore(): void {
            wallpaperBackend.restore()
        }
    }
}
