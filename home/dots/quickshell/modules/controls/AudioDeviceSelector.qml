import QtQuick
import Quickshell
import Quickshell.Io

import "../../Config"

Item {
    id: root

    property string deviceType:
        "sink"

    property color accentColor:
        Colors.pink

    property var devices: []

    property int selectedId:
        -1

    property bool expanded:
        false

    property bool animating:
        heightAnimation.running

    signal deviceSelected(
        int id,
        string name
    )

    // ═════════════════════════════════════════
    // Geometry
    // ═════════════════════════════════════════

    readonly property real targetHeight:
        root.expanded
            ? deviceList.implicitHeight
                + 8 * Appearance.scale
            : 0

    property real animatedHeight:
        0

    implicitWidth:
        280 * Appearance.scale

    implicitHeight:
        root.animatedHeight

    height:
        root.animatedHeight

    clip:
        true

    Behavior on animatedHeight {
        NumberAnimation {
            id: heightAnimation

            duration:
                280

            easing.type:
                Easing.InOutCubic
        }
    }

    onTargetHeightChanged: {
        root.animatedHeight =
            root.targetHeight
    }

    // ═════════════════════════════════════════
    // Public API
    // ═════════════════════════════════════════

    function refresh() {
        if (!statusProcess.running) {
            statusProcess.running =
                true
        }
    }

    function open() {
        root.refresh()

        root.expanded =
            true
    }

    function close() {
        root.expanded =
            false
    }

    function selectDevice(
        id,
        name
    ) {
        if (selectProcess.running)
            return

        selectProcess.command = [
            "/run/current-system/sw/bin/wpctl",
            "set-default",
            id.toString()
        ]

        selectProcess.running =
            true

        root.selectedId =
            id

        root.expanded =
            false

        root.deviceSelected(
            id,
            name
        )
    }

    // ═════════════════════════════════════════
    // wpctl
    // ═════════════════════════════════════════

    Process {
        id: statusProcess

        command: [
            "/run/current-system/sw/bin/wpctl",
            "status"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines =
                    text.split("\n")

                const wantedSection =
                    root.deviceType === "source"
                        ? "Sources:"
                        : "Sinks:"

                let insideSection =
                    false

                let foundDevices =
                    []

                let currentId =
                    -1

                for (
                    let i = 0;
                    i < lines.length;
                    ++i
                ) {
                    const line =
                        lines[i]

                    if (
                        line.indexOf(
                            wantedSection
                        ) !== -1
                    ) {
                        insideSection =
                            true

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

                    const match =
                        line.match(
                            /(\*)?\s*(\d+)\.\s+(.+?)(?:\s+\[.*\])?$/
                        )

                    if (!match)
                        continue

                    const id =
                        parseInt(match[2])

                    if (isNaN(id))
                        continue

                    const isDefault =
                        match[1] === "*"

                    foundDevices.push({
                        id: id,
                        name: match[3].trim(),
                        isDefault: isDefault
                    })

                    if (isDefault)
                        currentId = id
                }

                root.devices =
                    foundDevices

                if (currentId !== -1) {
                    root.selectedId =
                        currentId
                } else if (
                    foundDevices.length > 0
                ) {
                    root.selectedId =
                        foundDevices[0].id
                } else {
                    root.selectedId =
                        -1
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

        interval:
            150

        repeat:
            false

        onTriggered:
            root.refresh()
    }

    Component.onCompleted:
        root.refresh()

    // ═════════════════════════════════════════
    // Device list
    // ═════════════════════════════════════════

    Column {
        id: deviceList

        width:
            parent.width

        spacing:
            4 * Appearance.scale

        opacity:
            root.expanded
                ? 1.0
                : 0.0

        transform: Translate {
            y:
                root.expanded
                    ? 0
                    : -4 * Appearance.scale

            Behavior on y {
                NumberAnimation {
                    duration:
                        220

                    easing.type:
                        Easing.OutCubic
                }
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration:
                    root.expanded
                        ? 220
                        : 120

                easing.type:
                    Easing.OutCubic
            }
        }

        Rectangle {
            width:
                parent.width

            height:
                1 * Appearance.scale

            color:
                Colors.surface1
        }

        Repeater {
            model:
                root.devices

            delegate: Rectangle {
                id: deviceRow

                required property var modelData

                readonly property bool active:
                    modelData.id
                    === root.selectedId

                width:
                    deviceList.width

                height:
                    34 * Appearance.scale

                radius:
                    Appearance.controlRadius

                /*
                 * IMPORTANT:
                 *
                 * No ColorAnimation here.
                 *
                 * Going from transparent to
                 * surface1 through interpolation
                 * produced the dark intermediate
                 * flash you were seeing.
                 */
                color: {
                    if (deviceRow.active)
                        return root.accentColor

                    if (deviceMouse.containsMouse)
                        return Colors.surface1

                    return "transparent"
                }

                border.width:
                    0

                Text {
                    anchors {
                        left:
                            parent.left

                        right:
                            parent.right

                        leftMargin:
                            12 * Appearance.scale

                        rightMargin:
                            12 * Appearance.scale

                        verticalCenter:
                            parent.verticalCenter
                    }

                    text:
                        modelData.name

                    color: {
                        if (deviceRow.active)
                            return Colors.base

                        if (deviceMouse.containsMouse)
                            return root.accentColor

                        return Colors.text
                    }

                    font.pixelSize:
                        Appearance.textSize

                    elide:
                        Text.ElideRight

                    Behavior on color {
                        ColorAnimation {
                            duration:
                                130
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
