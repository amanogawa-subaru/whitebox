import QtQuick
import Quickshell
import Quickshell.Io

import "../../Config"

Rectangle {
    id: root

    property url avatarSource: ""

    property string userName: "User"
    property string uptimeText: "Up"

    implicitHeight: 76 * Appearance.scale

    radius: Appearance.controlRadius
    color: Colors.surface0

    Process {
        id: userProcess

        command: [
            "sh",
            "-c",
            "printf '%s' \"$USER\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()

                if (value.length > 0)
                    root.userName = value
            }
        }
    }

    Process {
        id: uptimeProcess

        command: [
            "sh",
            "-c",
            "awk '{"
                + "s=int($1); "
                + "d=int(s/86400); "
                + "h=int((s%86400)/3600); "
                + "m=int((s%3600)/60); "
                + "if (d>0) "
                    + "printf \"Up %dd, %dh\", d, h; "
                + "else if (h>0) "
                    + "printf \"Up %dh, %dm\", h, m; "
                + "else "
                    + "printf \"Up %dm\", m"
                + "}' /proc/uptime"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim()

                if (value.length > 0)
                    root.uptimeText = value
            }
        }
    }

    Timer {
        interval: 60000
        running: true
        repeat: true

        onTriggered: {
            uptimeProcess.running = true
        }
    }

    Component.onCompleted: {
        userProcess.running = true
        uptimeProcess.running = true
    }

    Rectangle {
        id: avatar

        width: 50 * Appearance.scale
        height: width

        radius: width / 2
        clip: true

        color: Colors.surface1

        anchors {
            left: parent.left
            leftMargin: 14 * Appearance.scale
            verticalCenter: parent.verticalCenter
        }

        Image {
            anchors.fill: parent

            visible: root.avatarSource.toString().length > 0

            source: root.avatarSource
            fillMode: Image.PreserveAspectCrop
        }

        Text {
            anchors.centerIn: parent

            visible:
                root.avatarSource.toString().length === 0

            text: "󰀄"

            font.family: "Symbols Nerd Font"
            font.pixelSize: 26 * Appearance.scale

            color: Colors.mauve
        }
    }

    Column {
        anchors {
            left: avatar.right
            leftMargin: 14 * Appearance.scale
            verticalCenter: parent.verticalCenter
        }

        spacing: 3 * Appearance.scale

        Text {
            text: root.userName

            color: Colors.text
            font.pixelSize: Appearance.textSize + 2
        }

        Text {
            text: root.uptimeText

            color: Colors.subtext0
            font.pixelSize: Appearance.textSize - 2
        }
    }
}
