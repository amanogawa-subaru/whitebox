import QtQuick
import Quickshell
import Quickshell.Io

import "../Config"
import "controls"

FocusScope {
    id: root

    property color accentColor:
        Colors.red

    signal closeRequested()
    signal lockRequested()

    property string userName:
        "User"

    property string hostName:
        "host"

    property string uptimeText:
        "Up"

    property bool hasBattery:
        false

    property string batteryText:
        ""

    /*
     * Exposed to UtilityModule so the outer container
     * can follow the selector's animatedHeight directly
     * instead of applying a second, lagging height
     * animation on top of it.
     */
    readonly property bool deviceSelectorAnimating:
        outputSelector.expanded
        || outputSelector.animatedHeight > 0
        || inputSelector.expanded
        || inputSelector.animatedHeight > 0

    function collapseDeviceSelectors() {
        outputSelector.expanded =
            false

        inputSelector.expanded =
            false
    }

    onVisibleChanged: {
        if (!visible)
            root.collapseDeviceSelectors()
    }

    property real contentMargin:
        14 * Appearance.scale

    property real contentSpacing:
        12 * Appearance.scale

    property real controlCardPadding:
        14 * Appearance.scale

    property real controlRowHeight:
        34 * Appearance.scale

    readonly property real identityHeight:
        72 * Appearance.scale

    readonly property real implicitContentHeight:
        identityHeight
        + controlColumn.implicitHeight
        + root.contentMargin * 2

    implicitHeight:
        implicitContentHeight

    height:
        implicitHeight

    // ═════════════════════════════════════════
    // Device selectors
    // ═════════════════════════════════════════

    function toggleOutputDevices() {
        if (outputSelector.expanded) {
            outputSelector.close()
            return
        }

        inputSelector.close()
        outputSelector.open()
    }

    function toggleInputDevices() {
        if (inputSelector.expanded) {
            inputSelector.close()
            return
        }

        outputSelector.close()
        inputSelector.open()
    }

    // ═════════════════════════════════════════
    // Identity
    // ═════════════════════════════════════════

    Process {
        id: identityProcess

        command: [
            "sh",
            "-c",
            "printf '%s\\n%s' \"$USER\" \"$(hostname)\""
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts =
                    text.trim().split("\n")

                if (
                    parts.length > 0
                    && parts[0].length > 0
                ) {
                    root.userName =
                        parts[0]
                }

                if (
                    parts.length > 1
                    && parts[1].length > 0
                ) {
                    root.hostName =
                        parts[1]
                }
            }
        }
    }

    Process {
        id: batteryProcess

        command: [
            "sh",
            "-c",
            "bat=$(find /sys/class/power_supply -maxdepth 1 -type l -name 'BAT*' 2>/dev/null | head -n1); "
            + "if [ -n \"$bat\" ]; then "
            + "cap=$(cat \"$bat/capacity\" 2>/dev/null); "
            + "status=$(cat \"$bat/status\" 2>/dev/null); "
            + "printf '%s\\n%s' \"$cap\" \"$status\"; fi"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const parts =
                    text.trim().split("\n")

                if (
                    parts.length >= 2
                    && parts[0].length > 0
                ) {
                    root.hasBattery =
                        true

                    const capacity =
                        parts[0]

                    const status =
                        parts[1]

                    let icon =
                        "󰁹"

                    if (status === "Charging")
                        icon = "󰂄"
                    else if (capacity <= 10)
                        icon = "󰁺"
                    else if (capacity <= 25)
                        icon = "󰁻"
                    else if (capacity <= 50)
                        icon = "󰁾"
                    else if (capacity <= 75)
                        icon = "󰂀"
                    else if (capacity <= 90)
                        icon = "󰂂"

                    root.batteryText =
                        icon
                        + " "
                        + capacity
                } else {
                    root.hasBattery =
                        false

                    root.batteryText =
                        ""
                }
            }
        }
    }

    Process {
        id: uptimeProcess

        command: [
            "sh",
            "-c",
            "awk '{s=int($1); d=int(s/86400); h=int((s%86400)/3600); m=int((s%3600)/60); if (d>0) printf \"Up %dd, %dh\", d, h; else if (h>0) printf \"Up %dh, %dm\", h, m; else printf \"Up %dm\", m}' /proc/uptime"
        ]

        stdout: StdioCollector {
            onStreamFinished: {
                const value =
                    text.trim()

                if (value.length > 0) {
                    root.uptimeText =
                        value
                }
            }
        }
    }

    Timer {
        interval:
            60000

        running:
            true

        repeat:
            true

        onTriggered: {
            uptimeProcess.running = true
            batteryProcess.running = true
        }
    }

    Component.onCompleted: {
        identityProcess.running = true
        uptimeProcess.running = true
        batteryProcess.running = true
    }

    // ═════════════════════════════════════════
    // Identity header
    // ═════════════════════════════════════════

    Item {
        id: identityHeader

        width:
            parent.width

        height:
            root.identityHeight

        Row {
            anchors {
                left:
                    parent.left

                right:
                    parent.right

                leftMargin:
                    root.contentMargin
                    + 4 * Appearance.scale

                rightMargin:
                    root.contentMargin
                    + 4 * Appearance.scale

                verticalCenter:
                    parent.verticalCenter
            }

            Column {
                width:
                    parent.width
                    - systemInfo.width

                spacing:
                    3 * Appearance.scale

                Text {
                    text:
                        root.userName

                    color:
                        Colors.text

                    font.pixelSize:
                        Appearance.textSize + 2

                    font.bold:
                        true
                }

                Text {
                    text:
                        root.hostName

                    color:
                        Colors.subtext0

                    font.pixelSize:
                        Appearance.textSize - 2
                }
            }

            Column {
                id: systemInfo

                width:
                    Math.max(
                        uptimeLabel.implicitWidth,
                        batteryLabel.visible
                            ? batteryLabel.implicitWidth
                            : 0
                    )

                spacing:
                    3 * Appearance.scale

                Text {
                    id: batteryLabel

                    visible:
                        root.hasBattery

                    text:
                        root.batteryText

                    color:
                        Colors.subtext0

                    font.family:
                        "Symbols Nerd Font, sans-serif"

                    font.pixelSize:
                        Appearance.textSize - 2

                    width:
                        systemInfo.width

                    horizontalAlignment:
                        Text.AlignRight
                }

                Text {
                    id: uptimeLabel

                    text:
                        root.uptimeText

                    color:
                        Colors.subtext0

                    font.pixelSize:
                        Appearance.textSize - 2
                }
            }
        }
    }


    // ═════════════════════════════════════════
    // Controls
    // ═════════════════════════════════════════

    Column {
        id: controlColumn

        anchors {
            left:
                parent.left

            right:
                parent.right

            top:
                identityHeader.bottom

            leftMargin:
                root.contentMargin

            rightMargin:
                root.contentMargin

            topMargin:
                root.contentMargin
        }

        spacing:
            root.contentSpacing

        // Brightness

        Rectangle {
            width:
                parent.width

            height:
                64 * Appearance.scale

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            BrightnessSlider {
                anchors {
                    left:
                        parent.left

                    right:
                        parent.right

                    verticalCenter:
                        parent.verticalCenter

                    leftMargin:
                        root.controlCardPadding

                    rightMargin:
                        root.controlCardPadding
                }

                height:
                    root.controlRowHeight
            }
        }

        // Audio output

        Rectangle {
            width:
                parent.width

            height:
                root.controlCardPadding * 2
                + root.controlRowHeight
                + Math.min(
                    8 * Appearance.scale,
                    outputSelector.animatedHeight
                )
                + outputSelector.animatedHeight

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            Column {
                anchors {
                    left:
                        parent.left

                    right:
                        parent.right

                    top:
                        parent.top

                    margins:
                        root.controlCardPadding
                }

                spacing:
                    8 * Appearance.scale

                Row {
                    width:
                        parent.width

                    height:
                        root.controlRowHeight

                    spacing:
                        8 * Appearance.scale

                    VolumeControl {
                        width:
                            parent.width
                            - outputArrowButton.width
                            - parent.spacing

                        height:
                            parent.height
                    }

                    Item {
                        id: outputArrowButton

                        width:
                            30 * Appearance.scale

                        height:
                            parent.height

                        Text {
                            anchors.centerIn:
                                parent

                            text:
                                outputSelector.expanded
                                    ? "▴"
                                    : "▾"

                            color:
                                outputArrowMouse.containsMouse
                                    ? Colors.pink
                                    : Colors.subtext0

                            font.pixelSize:
                                Appearance.textSize + 1

                            scale:
                                outputArrowMouse.containsMouse
                                    ? 1.15
                                    : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 130
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.3
                                }
                            }
                        }

                        MouseArea {
                            id: outputArrowMouse

                            anchors.fill:
                                parent

                            hoverEnabled:
                                true

                            onClicked:
                                root.toggleOutputDevices()
                        }
                    }
                }

                AudioDeviceSelector {
                    id: outputSelector

                    width:
                        parent.width

                    deviceType:
                        "sink"

                    accentColor:
                        Colors.pink
                }
            }
        }

        // Microphone

        Rectangle {
            width:
                parent.width

            height:
                root.controlCardPadding * 2
                + root.controlRowHeight
                + Math.min(
                    8 * Appearance.scale,
                    inputSelector.animatedHeight
                )
                + inputSelector.animatedHeight

            radius:
                Appearance.controlRadius

            color:
                Colors.surface0

            Column {
                anchors {
                    left:
                        parent.left

                    right:
                        parent.right

                    top:
                        parent.top

                    margins:
                        root.controlCardPadding
                }

                spacing:
                    8 * Appearance.scale

                Row {
                    width:
                        parent.width

                    height:
                        root.controlRowHeight

                    spacing:
                        8 * Appearance.scale

                    MicControl {
                        width:
                            parent.width
                            - inputArrowButton.width
                            - parent.spacing

                        height:
                            parent.height
                    }

                    Item {
                        id: inputArrowButton

                        width:
                            30 * Appearance.scale

                        height:
                            parent.height

                        Text {
                            anchors.centerIn:
                                parent

                            text:
                                inputSelector.expanded
                                    ? "▴"
                                    : "▾"

                            color:
                                inputArrowMouse.containsMouse
                                    ? Colors.mauve
                                    : Colors.subtext0

                            font.pixelSize:
                                Appearance.textSize + 1

                            scale:
                                inputArrowMouse.containsMouse
                                    ? 1.15
                                    : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 130
                                }
                            }

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 180
                                    easing.type: Easing.OutBack
                                    easing.overshoot: 1.3
                                }
                            }
                        }

                        MouseArea {
                            id: inputArrowMouse

                            anchors.fill:
                                parent

                            hoverEnabled:
                                true

                            onClicked:
                                root.toggleInputDevices()
                        }
                    }
                }

                AudioDeviceSelector {
                    id: inputSelector

                    width:
                        parent.width

                    deviceType:
                        "source"

                    accentColor:
                        Colors.mauve
                }
            }
        }

        // Power actions

        PowerActions {
            width:
                parent.width

            onLockRequested:
                root.lockRequested()

            onCloseRequested:
                root.closeRequested()
        }
    }
}
