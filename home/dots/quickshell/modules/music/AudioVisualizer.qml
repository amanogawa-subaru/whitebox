import QtQuick
import Quickshell.Io

import "../../Config"

Item {
    id: root

    property bool active: false
    property int barCount: 16
    property color barColor: Colors.base
    property real barSpacing: 4 * Appearance.scale

    property var values: [
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0
    ]

    function reset() {
        root.values = [
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0
        ]
    }

    onActiveChanged: {
        if (!root.active)
            root.reset()
    }

    Process {
        id: cavaProcess

        running: root.active

		command: [
			"bash",
			"-c",

			"cfg=$(mktemp); "
			+ "trap 'rm -f \"$cfg\"' EXIT; "
			+ "printf '%s\\n' "
			+ "'[general]' "
			+ "'bars = 16' "
			+ "'framerate = 60' "
			+ "'[input]' "
			+ "'method = pipewire' "
			+ "'source = auto' "
			+ "'[output]' "
			+ "'method = raw' "
			+ "'raw_target = /dev/stdout' "
			+ "'data_format = ascii' "
			+ "'ascii_max_range = 1000' "
			+ "'bar_delimiter = 59' "
			+ "'frame_delimiter = 10' "
			+ "'channels = mono' "
			+ "'[smoothing]' "
			+ "'noise_reduction = 55' "
			+ "> \"$cfg\"; "
			+ "exec cava -p \"$cfg\""
		]

        stdout: SplitParser {
            splitMarker: "\n"

            onRead: data => {
                const line = data.trim()
                if (!line)
                    return

                const parts = line.split(";")
                if (parts.length < root.barCount)
                    return

                let newValues = []

                for (let i = 0; i < root.barCount; ++i) {
                    const value = Number(parts[i])
                    newValues.push(
                        isNaN(value)
                            ? 0
                            : Math.max(0, Math.min(1000, value))
                    )
                }

                root.values = newValues
            }
        }
    }

    Row {
        id: bars

        anchors.fill: parent
        spacing: root.barSpacing

        Repeater {
            model: root.barCount

            Rectangle {
                required property int index

                width:
                    (
                        bars.width
                        - bars.spacing * (root.barCount - 1)
                    ) / root.barCount

                height:
                    Math.max(
                        2 * Appearance.scale,
                        bars.height * (root.values[index] / 1000.0)
                    )

                anchors.verticalCenter: parent.verticalCenter

                radius: width / 2
                color: root.barColor
            }
        }
    }
}
