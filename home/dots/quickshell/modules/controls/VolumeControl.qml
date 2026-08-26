import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

import "../../Config"

Item {
    id: root

    implicitWidth: 280 * Appearance.scale
    implicitHeight: 32 * Appearance.scale

    property var sink: Pipewire.defaultAudioSink

    property real volume:
        sink && sink.audio
            ? sink.audio.volume
            : 0

    property bool muted:
        sink && sink.audio
            ? sink.audio.muted
            : false

    PwObjectTracker {
        objects: [
            Pipewire.defaultAudioSink
        ]
    }

    function setVolume(newValue) {
        if (!root.sink || !root.sink.audio)
            return

        const clamped = Math.max(
            0,
            Math.min(1, newValue)
        )

        root.sink.audio.volume = clamped
    }

    function toggleMute() {
        if (!root.sink || !root.sink.audio)
            return

        root.sink.audio.muted =
            !root.sink.audio.muted
    }

    Row {
        anchors.fill: parent
        spacing: 14 * Appearance.scale

        Item {
            id: iconContainer

            width: 28 * Appearance.scale
            height: parent.height

            Text {
                id: volumeIcon

                anchors.centerIn: parent

                text: {
                    if (root.muted || root.volume <= 0)
                        return "󰖁"

                    if (root.volume < 0.5)
                        return "󰕿"

                    return "󰕾"
                }

                font.family: "Symbols Nerd Font"
                font.pixelSize: Appearance.iconSize

                color: {
                    if (iconMouse.containsMouse)
                        return Colors.pink

                    if (root.muted)
                        return Colors.overlay0

                    return Colors.text
                }

                scale: iconMouse.containsMouse
                    ? 1.15
                    : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }
            }

            MouseArea {
                id: iconMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: {
                    root.toggleMute()
                }
            }
        }

        Item {
            id: slider

            width: parent.width
                - iconContainer.width
                - parent.spacing
                - 28 * Appearance.scale

            height: parent.height

            Rectangle {
                id: track

                anchors.verticalCenter: parent.verticalCenter

                width: parent.width
                height: 6 * Appearance.scale

                radius: height / 2
                color: Colors.surface1
            }

            Rectangle {
                anchors {
                    left: track.left
                    verticalCenter: track.verticalCenter
                }

                width:
                    track.width
                    * Math.min(root.volume, 1)

                height: track.height
                radius: height / 2

                color: root.muted
                    ? Colors.overlay0
                    : Colors.pink
            }

            Rectangle {
                anchors.verticalCenter:
                    track.verticalCenter

                x: (
                    track.width
                    * Math.min(root.volume, 1)
                ) - width / 2

                width: 16 * Appearance.scale
                height: width
                radius: width / 2

                color: sliderMouse.containsMouse
                    ? Colors.pink
                    : Colors.text

                scale: sliderMouse.containsMouse
                    ? 1.15
                    : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: 200
                        easing.type: Easing.OutBack
                        easing.overshoot: 1.4
                    }
                }
            }

            MouseArea {
                id: sliderMouse

                anchors.fill: parent
                hoverEnabled: true

                onPressed: mouse => {
                    root.setVolume(
                        mouse.x / width
                    )
                }

                onPositionChanged: mouse => {
                    if (pressed) {
                        root.setVolume(
                            mouse.x / width
                        )
                    }
                }
            }
        }
    }
}
