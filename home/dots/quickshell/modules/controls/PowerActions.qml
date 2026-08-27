import QtQuick
import Quickshell
import Quickshell.Io

import "../../Config"

Item {
    id: root

    signal closeRequested()
    signal lockRequested()

    implicitHeight:
        82 * Appearance.scale

    function run(command) {
        actionProcess.command = [
            "sh",
            "-c",
            command
        ]

        actionProcess.running =
            true
    }

    Process {
        id: actionProcess
    }

    Row {
        anchors.fill:
            parent

        spacing:
            8 * Appearance.scale

        Repeater {
            model: [
                {
                    label: "Lock",
                    icon: "󰌾",
                    accent: Colors.blue,
                    command: ""
                },
                {
                    label: "Sleep",
                    icon: "󰒲",
                    accent: Colors.green,
                    command: "systemctl suspend"
                },
                {
                    label: "Logout",
                    icon: "󰍃",
                    accent: Colors.mauve,
                    command: "hyprctl dispatch exit"
                },
                {
                    label: "Restart",
                    icon: "󰜉",
                    accent: Colors.yellow,
                    command: "systemctl reboot"
                },
                {
                    label: "Off",
                    icon: "󰐥",
                    accent: Colors.red,
                    command: "systemctl poweroff"
                }
            ]

            delegate: Rectangle {
                required property var modelData

                width:
                    (
                        parent.width
                        - parent.spacing * 4
                    ) / 5

                height:
                    parent.height

                radius:
                    Appearance.controlRadius

                color:
                    actionMouse.containsMouse
                        ? modelData.accent
                        : Colors.surface0

                border.width:
                    Appearance.borderWidth / 2

                border.color:
                    actionMouse.containsMouse
                        ? modelData.accent
                        : Colors.surface1

                scale:
                    actionMouse.containsMouse
                        ? 1.06
                        : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration:
                            150
                    }
                }

                Behavior on border.color {
                    ColorAnimation {
                        duration:
                            150
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration:
                            220

                        easing.type:
                            Easing.OutBack

                        easing.overshoot:
                            1.4
                    }
                }

                Text {
                    anchors.centerIn:
                        parent

                    text:
                        modelData.icon

                    font.family:
                        "Symbols Nerd Font"

                    font.pixelSize:
                        Appearance.iconSize + 2

                    color:
                        actionMouse.containsMouse
                            ? Colors.base
                            : modelData.accent

                    Behavior on color {
                        ColorAnimation {
                            duration:
                                150
                        }
                    }
                }

                MouseArea {
                    id: actionMouse

                    anchors.fill:
                        parent

                    hoverEnabled:
                        true

                    onClicked: {
                        /*
                         * Lock is special:
                         *
                         * PowerModule handles the
                         * collapse first, then starts
                         * Hyprlock after the animation
                         * has finished.
                         */
                        if (modelData.label === "Lock") {
                            root.lockRequested()
                            return
                        }

                        /*
                         * Everything else preserves
                         * the existing behavior:
                         *
                         * close the Control Center,
                         * then execute the action.
                         */
                        root.closeRequested()
                        root.run(
                            modelData.command
                        )
                    }
                }
            }
        }
    }
}
