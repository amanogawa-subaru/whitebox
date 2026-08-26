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

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 1000

    exclusiveZone:
        Appearance.moduleHeight
        + Appearance.screenMargin
        + Appearance.panelBottomMargin

    focusable: true

    // ═════════════════════════════════════════
    // Shared notification backend
    // ═════════════════════════════════════════

    NotificationBackend {
        id: notificationBackend
    }

    // ═════════════════════════════════════════
    // Keyboard focus
    // ═════════════════════════════════════════

    WlrLayershell.keyboardFocus:
        searchModule.expanded
        || workspaceModule.expanded
        || timeModule.expanded
        || musicModule.expanded
        || notificationModule.expanded
        || powerModule.expanded
            ? WlrKeyboardFocus.OnDemand
            : WlrKeyboardFocus.None

    color:
        "transparent"

    // ═════════════════════════════════════════
    // Input mask
    // ═════════════════════════════════════════

    mask: Region {
        Region {
            x: leftModules.x
            y: leftModules.y
            width: leftModules.width
            height: leftModules.height
        }

        Region {
            x: timeModule.x
            y: timeModule.y
            width: timeModule.width
            height: timeModule.height
        }

        Region {
            x: rightModules.x
            y: rightModules.y
            width: rightModules.width
            height: rightModules.height
        }
    }

    // ═════════════════════════════════════════
    // LEFT MODULES
    // ═════════════════════════════════════════

    Row {
        id: leftModules

        anchors {
            left: parent.left
            top: parent.top

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
                    notificationModule.close()
                    powerModule.close()
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
                    notificationModule.close()
                    powerModule.close()
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
                notificationModule.close()
                powerModule.close()
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
                    notificationModule.close()
                    powerModule.close()
                }
            }
        }

        NotificationModule {
            id: notificationModule

            backend:
                notificationBackend

            onExpandedChanged: {
                if (expanded) {
                    searchModule.close()
                    workspaceModule.close()
                    timeModule.close()
                    musicModule.close()
                    powerModule.close()
                }
            }
        }

        SystrayModule {
            id: systrayModule
        }

        PowerModule {
            id: powerModule

            onExpandedChanged: {
                if (expanded) {
                    searchModule.close()
                    workspaceModule.close()
                    timeModule.close()
                    musicModule.close()
                    notificationModule.close()
                }
            }
        }
    }

    // ═════════════════════════════════════════
    // Notification popup layer
    //
    // This is a separate floating PopupWindow
    // anchored to NotificationModule.
    // ═════════════════════════════════════════

    NotificationPopupLayer {
        backend:
            notificationBackend

        anchorItem:
            notificationModule
    }

    // ═════════════════════════════════════════
    // Focus grabs
    // ═════════════════════════════════════════

    HyprlandFocusGrab {
        id: searchFocusGrab

        windows: [root]
        active: searchModule.expanded

        onCleared:
            searchModule.close()
    }

    HyprlandFocusGrab {
        id: workspaceFocusGrab

        windows: [root]
        active: workspaceModule.expanded

        onCleared:
            workspaceModule.close()
    }

    HyprlandFocusGrab {
        id: timeFocusGrab

        windows: [root]
        active: timeModule.expanded

        onCleared:
            timeModule.close()
    }

    HyprlandFocusGrab {
        id: musicFocusGrab

        windows: [root]
        active: musicModule.expanded

        onCleared:
            musicModule.close()
    }

    HyprlandFocusGrab {
        id: notificationFocusGrab

        windows: [root]
        active: notificationModule.expanded

        onCleared:
            notificationModule.close()
    }

    HyprlandFocusGrab {
        id: powerFocusGrab

        windows: [root]
        active: powerModule.expanded

        onCleared:
            powerModule.close()
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
}
