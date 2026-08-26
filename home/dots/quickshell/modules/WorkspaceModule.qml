import QtQuick
import Quickshell.Hyprland

import "../Config"

Rectangle {
    id: root

    property bool hovered:
        moduleHover.hovered

    property int workspaceCount: 5

    property real workspaceItemSize:
        20 * Appearance.scale

    property real indicatorSize:
        10 * Appearance.scale

    property real workspaceSpacing:
        Appearance.moduleSpacing

    property int activeWorkspaceId:
        Hyprland.focusedWorkspace
            ? Hyprland.focusedWorkspace.id
            : 1

    property int activeIndex:
        Math.max(
            0,
            Math.min(
                root.workspaceCount - 1,
                root.activeWorkspaceId - 1
            )
        )

    width:
        Appearance.workspaceWidth

    height:
        Appearance.moduleHeight

    radius:
        Appearance.moduleRadius

    color:
        Colors.base

    border.width:
        Appearance.borderWidth

    border.color:
        Colors.peach

    // ─────────────────────────────────────────
    // Whole-module hover swell
    // ─────────────────────────────────────────

    scale:
        root.hovered
            ? 1.09
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

    HoverHandler {
        id: moduleHover
    }

    // ─────────────────────────────────────────
    // Workspace strip
    // ─────────────────────────────────────────

    Item {
        id: workspaceStrip

        width:
            root.workspaceCount
                * root.workspaceItemSize
            + (root.workspaceCount - 1)
                * root.workspaceSpacing

        height:
            root.workspaceItemSize

        anchors.centerIn:
            parent

        // ─────────────────────────────────────
        // Sliding active indicator
        // ─────────────────────────────────────

        Rectangle {
            id: activeIndicator

            z: 2

            visible:
                root.activeWorkspaceId >= 1
                && root.activeWorkspaceId
                    <= root.workspaceCount

            width:
                root.indicatorSize

            height:
                root.indicatorSize

            radius:
                width / 2

            color:
                Colors.peach

            y:
                (
                    workspaceStrip.height
                    - height
                ) / 2

            x:
                root.activeIndex
                * (
                    root.workspaceItemSize
                    + root.workspaceSpacing
                )
                + (
                    root.workspaceItemSize
                    - width
                ) / 2

            Behavior on x {
                NumberAnimation {
                    duration: 220
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.25
                }
            }

            /*
             * Tiny pulse when hovering the
             * currently active workspace.
             */
            scale:
                activeWorkspaceMouseHover.hovered
                    ? 1.25
                    : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 180
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.35
                }
            }

            HoverHandler {
                id: activeWorkspaceMouseHover
            }
        }

        // ─────────────────────────────────────
        // Workspace slots
        // ─────────────────────────────────────

        Repeater {
            model:
                root.workspaceCount

            delegate: Item {
                id: workspaceItem

                required property int index

                property int workspaceId:
                    index + 1

                property bool active:
                    root.activeWorkspaceId
                        === workspaceId

                property bool occupied: {
                    for (
                        let i = 0;
                        i < Hyprland.workspaces.values.length;
                        i++
                    ) {
                        if (
                            Hyprland.workspaces.values[i].id
                            === workspaceId
                        ) {
                            return true
                        }
                    }

                    return false
                }

                x:
                    index
                    * (
                        root.workspaceItemSize
                        + root.workspaceSpacing
                    )

                width:
                    root.workspaceItemSize

                height:
                    root.workspaceItemSize

                // ─────────────────────────────
                // Inactive workspace dot
                // ─────────────────────────────

                Rectangle {
                    id: indicator

                    anchors.centerIn:
                        parent

                    width:
                        root.indicatorSize

                    height:
                        root.indicatorSize

                    radius:
                        width / 2

                    /*
                     * The active workspace is drawn
                     * by activeIndicator instead.
                     */
                    visible:
                        !workspaceItem.active

                    color: {
                        if (workspaceMouse.containsMouse)
                            return Colors.text

                        if (workspaceItem.occupied)
                            return Colors.lavender

                        return Colors.surface0
                    }

                    scale:
                        workspaceMouse.containsMouse
                            ? 1.25
                            : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 180
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.35
                        }
                    }
                }

                // ─────────────────────────────
                // Workspace interaction
                // ─────────────────────────────

                MouseArea {
                    id: workspaceMouse

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {
						Hyprland.dispatch(
							'hl.dsp.focus({ workspace = "'
							+ workspaceItem.workspaceId
							+ '" })'
						)
					}
                }
            }
        }
    }
}
