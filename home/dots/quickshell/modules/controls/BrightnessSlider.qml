import QtQuick
import Quickshell
import Quickshell.Io

import "../../Config"

Item {
    id: root

    property real value: 50
    property int pendingValue: 50
    property string backend: "detecting"

    implicitWidth: 280 * Appearance.scale
    implicitHeight: 32 * Appearance.scale

    function setBrightness(newValue) {
        if (root.backend === "none"
                || root.backend === "detecting")
            return

        const clamped = Math.max(
            1,
            Math.min(100, newValue)
        )

        root.value = clamped
        root.pendingValue = Math.round(clamped)

        writeDelay.restart()
    }

    function readBrightness() {
        if (readProcess.running)
            return

        if (root.backend === "backlight") {
            readProcess.command = [
                "sh",
                "-c",
                "/run/current-system/sw/bin/brightnessctl "
                    + "--class=backlight -m "
                    + "| head -n1 "
                    + "| cut -d, -f4 "
                    + "| tr -d '%'"
            ]
        } else if (root.backend === "ddc") {
            readProcess.command = [
                "sh",
                "-c",
                "/run/current-system/sw/bin/ddcutil "
                    + "getvcp 10 --brief "
                    + "| awk '{print $4}'"
            ]
        } else {
            return
        }

        readProcess.running = true
    }

    function writeBrightness() {
        if (setProcess.running)
            return

        if (root.backend === "backlight") {
            setProcess.command = [
                "/run/current-system/sw/bin/brightnessctl",
                "--class=backlight",
                "set",
                root.pendingValue.toString() + "%"
            ]
        } else if (root.backend === "ddc") {
            setProcess.command = [
                "/run/current-system/sw/bin/ddcutil",
                "setvcp",
                "10",
                root.pendingValue.toString()
            ]
        } else {
            return
        }

        setProcess.running = true
    }

    Process {
        id: detectBacklightProcess

        command: [
            "sh",
            "-c",
            "/run/current-system/sw/bin/brightnessctl "
                + "--class=backlight -l >/dev/null 2>&1"
        ]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.backend = "backlight"
                root.readBrightness()
            } else {
                detectDdcProcess.running = true
            }
        }
    }

    Process {
        id: detectDdcProcess

        command: [
            "sh",
            "-c",
            "/run/current-system/sw/bin/ddcutil "
                + "getvcp 10 --brief >/dev/null 2>&1"
        ]

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.backend = "ddc"
                root.readBrightness()
            } else {
                root.backend = "none"
            }
        }
    }

    Process {
        id: readProcess

        stdout: StdioCollector {
            onStreamFinished: {
                const parsed = parseFloat(text.trim())

                if (!isNaN(parsed)) {
                    root.value = parsed
                    root.pendingValue = Math.round(parsed)
                }
            }
        }
    }

    Process {
        id: setProcess
    }

    Timer {
        id: writeDelay

        interval: 100
        repeat: false

        onTriggered: {
            root.writeBrightness()
        }
    }

    Component.onCompleted: {
        detectBacklightProcess.running = true
    }

    Row {
        anchors.fill: parent
        spacing: 14 * Appearance.scale

        Item {
            id: iconContainer

            width: 28 * Appearance.scale
            height: parent.height

            Text {
                anchors.centerIn: parent

                text: "☀"

                color: root.backend === "none"
                    ? Colors.overlay0
                    : Colors.yellow

                font.pixelSize: Appearance.iconSize
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

                width: root.backend === "none"
                    ? 0
                    : track.width * root.value / 100

                height: track.height
                radius: height / 2

                color: root.backend === "none"
                    ? Colors.overlay0
                    : Colors.yellow
            }

            Rectangle {
                visible:
                    root.backend !== "none"
                    && root.backend !== "detecting"

                anchors.verticalCenter: track.verticalCenter

                x: (
                    track.width
                    * root.value
                    / 100
                ) - width / 2

                width: 16 * Appearance.scale
                height: width
                radius: width / 2

                color: sliderMouse.containsMouse
                    ? Colors.yellow
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

                enabled:
                    root.backend !== "none"
                    && root.backend !== "detecting"

                onPressed: mouse => {
                    root.setBrightness(
                        mouse.x / width * 100
                    )
                }

                onPositionChanged: mouse => {
                    if (pressed) {
                        root.setBrightness(
                            mouse.x / width * 100
                        )
                    }
                }

                onReleased: {
                    writeDelay.stop()
                    root.writeBrightness()
                }
            }
        }
    }
}
