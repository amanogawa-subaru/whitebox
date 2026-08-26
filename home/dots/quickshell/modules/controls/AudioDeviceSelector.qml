import QtQuick
import Quickshell
import Quickshell.Io

import "../../Config"

Item {
    id: root

    property string deviceType: "sink"
    property color accentColor: Colors.pink

    property var devices: []
    property int selectedId: -1

    property string selectedName:
        root.deviceType === "source"
            ? "No input device"
            : "No output device"

    property bool expanded: false

    // ─────────────────────────────────────────
    // Animated dropdown geometry
    // ─────────────────────────────────────────

    /*
     * Full natural height of the device list.
     */
    readonly property real targetDropdownHeight:
        root.expanded
            ? deviceList.implicitHeight
                + 8 * Appearance.scale
            : 0

    /*
     * This is the ACTUAL animated height.
     *
     * PowerModule sees implicitHeight changing
     * continuously during this animation instead
     * of receiving one giant instantaneous jump.
     */
    property real dropdownHeight: 0

    Behavior on dropdownHeight {
        NumberAnimation {
            duration: 220
            easing.type: Easing.OutCubic
        }
    }

    onTargetDropdownHeightChanged: {
        root.dropdownHeight =
            root.targetDropdownHeight
    }

    signal deviceSelected(int id, string name)
    signal aboutToOpen()

    implicitWidth:
        280 * Appearance.scale

    implicitHeight:
        selectorButton.height
        + root.dropdownHeight

    // ─────────────────────────────────────────
    // Functions
    // ─────────────────────────────────────────

    function refresh() {
        if (!statusProcess.running)
            statusProcess.running = true
    }

    function close() {
        root.expanded = false
    }

    function toggleDropdown() {
        if (!root.expanded) {
            root.aboutToOpen()
            root.refresh()
        }

        root.expanded = !root.expanded
    }

    function selectDevice(id, name) {
        if (selectProcess.running)
            return

        selectProcess.command = [
            "/run/current-system/sw/bin/wpctl",
            "set-default",
            id.toString()
        ]

        selectProcess.running = true

        root.selectedId = id
        root.selectedName = name
        root.expanded = false

        root.deviceSelected(id, name)
    }

    // ─────────────────────────────────────────
    // Read PipeWire devices
    // ─────────────────────────────────────────

    Process {
        id: statusProcess

        command: [
            "/run/current-system/sw/bin/wpctl",
            "status"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n")

                const wantedSection =
                    root.deviceType === "source"
                        ? "Sources:"
                        : "Sinks:"

                let insideSection = false
                let foundDevices = []

                let currentId = -1
                let currentName = ""

                for (let i = 0; i < lines.length; i++) {
                    const line = lines[i]

                    if (
                        line.indexOf(wantedSection)
                        !== -1
                    ) {
                        insideSection = true
                        continue
                    }

                    if (!insideSection)
                        continue

                    if (
                        line.indexOf("Sources:")
                            !== -1
                        || line.indexOf("Sinks:")
                            !== -1
                        || line.indexOf("Filters:")
                            !== -1
                        || line.indexOf("Streams:")
                            !== -1
                        || line.indexOf("Video")
                            !== -1
                    ) {
                        break
                    }

                    const match = line.match(
                        /(\*)?\s*(\d+)\.\s+(.+?)(?:\s+\[.*\])?$/
                    )

                    if (!match)
                        continue

                    const isDefault =
                        match[1] === "*"

                    const id =
                        parseInt(match[2])

                    const name =
                        match[3].trim()

                    if (isNaN(id))
                        continue

                    foundDevices.push({
                        id: id,
                        name: name,
                        isDefault: isDefault
                    })

                    if (isDefault) {
                        currentId = id
                        currentName = name
                    }
                }

                root.devices = foundDevices

                if (currentId !== -1) {
                    root.selectedId = currentId
                    root.selectedName = currentName
                } else if (
                    foundDevices.length > 0
                ) {
                    root.selectedId =
                        foundDevices[0].id

                    root.selectedName =
                        foundDevices[0].name
                } else {
                    root.selectedId = -1

                    root.selectedName =
                        root.deviceType === "source"
                            ? "No input device"
                            : "No output device"
                }
            }
        }
    }

    Process {
        id: selectProcess

        onRunningChanged: {
            if (!running)
                refreshDelay.restart()
        }
    }

    Timer {
        id: refreshDelay

        interval: 150
        repeat: false

        onTriggered: {
            root.refresh()
        }
    }

    Component.onCompleted: {
        root.refresh()
    }

    // ─────────────────────────────────────────
    // Selector button
    // ─────────────────────────────────────────

    Rectangle {
        id: selectorButton

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
        }

        height:
            36 * Appearance.scale

        radius:
            Appearance.controlRadius

        color:
            selectorMouse.containsMouse
                ? Colors.surface1
                : Colors.surface0

        border.width:
            Appearance.borderWidth

        border.color:
            selectorMouse.containsMouse
                ? root.accentColor
                : Colors.surface1

        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }

        Behavior on border.color {
            ColorAnimation {
                duration: 150
            }
        }

        scale:
            selectorMouse.containsMouse
                ? 1.02
                : 1.0

        Behavior on scale {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            }
        }

        Text {
            anchors {
                left: parent.left
                right: arrow.left

                leftMargin:
                    12 * Appearance.scale

                rightMargin:
                    8 * Appearance.scale

                verticalCenter:
                    parent.verticalCenter
            }

            text:
                root.selectedName

            color:
                Colors.text

            font.pixelSize:
                Appearance.textSize

            elide:
                Text.ElideRight
        }

        Text {
            id: arrow

            anchors {
                right: parent.right

                rightMargin:
                    12 * Appearance.scale

                verticalCenter:
                    parent.verticalCenter
            }

            text:
                root.expanded
                    ? "▴"
                    : "▾"

            color:
                selectorMouse.containsMouse
                    ? root.accentColor
                    : Colors.subtext0

            font.pixelSize:
                Appearance.textSize

            Behavior on color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        MouseArea {
            id: selectorMouse

            anchors.fill:
                parent

            hoverEnabled:
                true

            onClicked: {
                root.toggleDropdown()
            }
        }
    }

    // ─────────────────────────────────────────
    // Animated dropdown viewport
    // ─────────────────────────────────────────

    Item {
        id: dropdownViewport

        anchors {
            left: parent.left
            right: parent.right
            top: selectorButton.bottom
        }

        height:
            root.dropdownHeight

        clip:
            true

        Column {
            id: deviceList

            anchors {
                left: parent.left
                right: parent.right

                top: parent.top

                topMargin:
                    8 * Appearance.scale
            }

            spacing:
                4 * Appearance.scale

            /*
             * Keep the list instantiated during
             * closing so it can slide smoothly
             * back into the viewport.
             */
            visible:
                root.dropdownHeight > 0

            opacity:
                root.expanded
                    ? 1.0
                    : 0.0

            Behavior on opacity {
                NumberAnimation {
                    duration: 160
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model:
                    root.devices

                delegate: Rectangle {
                    required property var modelData

                    width:
                        deviceList.width

                    height:
                        34 * Appearance.scale

                    radius:
                        Appearance.controlRadius

                    color:
                        deviceMouse.containsMouse
                            ? Colors.surface1
                            : Colors.surface0

                    border.width:
                        Appearance.borderWidth

                    border.color: {
                        if (
                            deviceMouse.containsMouse
                        ) {
                            return root.accentColor
                        }

                        if (
                            modelData.id
                            === root.selectedId
                        ) {
                            return root.accentColor
                        }

                        return Colors.surface1
                    }

                    scale:
                        deviceMouse.containsMouse
                            ? 1.02
                            : 1.0

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: 200
                            easing.type:
                                Easing.OutBack

                            easing.overshoot:
                                1.3
                        }
                    }

                    Text {
                        id: checkmark

                        anchors {
                            left: parent.left

                            leftMargin:
                                10 * Appearance.scale

                            verticalCenter:
                                parent.verticalCenter
                        }

                        text:
                            modelData.id
                                === root.selectedId
                                    ? "✓"
                                    : ""

                        color:
                            root.accentColor

                        font.pixelSize:
                            Appearance.textSize
                    }

                    Text {
                        anchors {
                            left:
                                checkmark.right

                            right:
                                parent.right

                            leftMargin:
                                8 * Appearance.scale

                            rightMargin:
                                10 * Appearance.scale

                            verticalCenter:
                                parent.verticalCenter
                        }

                        text:
                            modelData.name

                        color:
                            deviceMouse.containsMouse
                                ? root.accentColor
                                : Colors.text

                        font.pixelSize:
                            Appearance.textSize

                        elide:
                            Text.ElideRight

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    MouseArea {
                        id: deviceMouse

                        anchors.fill:
                            parent

                        hoverEnabled:
                            true

                        onClicked: {
                            root.selectDevice(
                                modelData.id,
                                modelData.name
                            )
                        }
                    }
                }
            }
        }
    }
}
